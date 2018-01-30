//
//  ProgramService.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-10.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation

internal protocol ProgramProvider {
    func fetchProgram(on channelId: String, timestamp: Int64, using environment: Environment, callback: @escaping (Program?, ExposureError?) -> Void)
    func validate(entitlementFor assetId: String, environment: Environment, sessionToken: SessionToken, callback: @escaping (EntitlementValidation?, ExposureError?) -> Void)
}

public protocol ProgramServiceEnabled {
    var programServiceChannelId: String { get }
}

internal class ProgramService {
    /// `Environment` to use when requesting program data
    fileprivate var environment: Environment
    
    fileprivate var sessionToken: SessionToken
    
    /// The channel to monitor
    internal let channelId: String
    
    /// Queue where `timer` runs
    fileprivate let queue: DispatchQueue
    
    fileprivate var timer: DispatchSourceTimer?
    
    fileprivate let refreshInterval: Int = 1000 * 3
    
    internal var currentPlayheadTime: () -> Int64? = { _ in return nil }
    internal var onNotEntitled: (String) -> Void = { _ in}
    internal var onProgramChanged: (Program?) -> Void = { _ in }
    
    fileprivate var activeProgram: Program?
    internal init(environment: Environment, sessionToken: SessionToken, channelId: String) {
        self.environment = environment
        self.sessionToken = sessionToken
        self.channelId = channelId
        self.provider = ExposureProgramProvider()
        self.queue = DispatchQueue(label: "com.emp.exposure.programService",
                                   qos: DispatchQoS.background,
                                   attributes: DispatchQueue.Attributes.concurrent)
    }
    
    deinit {
        timer?.setEventHandler{}
        timer?.cancel()
    }
    
    internal var provider: ProgramProvider
    internal struct ExposureProgramProvider: ProgramProvider {
        func fetchProgram(on channelId: String, timestamp: Int64, using environment: Environment, callback: @escaping (Program?, ExposureError?) -> Void) {
            FetchEpg(environment: environment)
                .channel(id: channelId)
                .filter(starting: timestamp, ending: timestamp)
                .filter(onlyPublished: true)
                .request()
                .response{ callback($0.value?.programs?.first, $0.error) }
        }
        
        func validate(entitlementFor assetId: String, environment: Environment, sessionToken: SessionToken, callback: @escaping (EntitlementValidation?, ExposureError?) -> Void) {
            Entitlement(environment: environment, sessionToken: sessionToken)
                .validate(assetId: assetId)
                .request()
                .response{ callback($0.value, $0.error) }
        }
    }
}

extension ProgramService {
    fileprivate func validate(timestamp: Int64, callback: @escaping (String?) -> Void) {
        if let current = activeProgram, let start = current.startDate?.millisecondsSince1970, let end = current.endDate?.millisecondsSince1970 {
            if timestamp > start && timestamp < end {
                print("ProgramService: validate inBounds",start,timestamp,end)
                startValidationTimer(onTimestamp: timestamp, for: current)
                callback(nil)
                return
            }
        }
        
        // We do not have a current program or the timestamp in question is outside the program bounds
        provider.fetchProgram(on: channelId, timestamp: timestamp, using: environment) { [weak self] newProgram, error in
            guard let `self` = self else { return }
            print("ProgramService: fetchProgram",timestamp,self.channelId)
            guard error == nil else {
                // There was an error fetching the program. Be permissive and allow playback
                return
            }
            
            if let program = newProgram {
                DispatchQueue.main.async { [weak self] in
                    self?.handleProgramChanged(program: program)
                    self?.startValidationTimer(onTimestamp: timestamp, for: program)
                }
                
                self.provider.validate(entitlementFor: program.assetId, environment: self.environment, sessionToken: self.sessionToken) { validation, error in
                    print("ProgramService: validate",timestamp,validation?.status)
                    guard let expirationReason = validation?.status else {
                        // We are permissive on validation errors, allow playback to continue.
                        callback(nil)
                        return
                    }
                    
                    guard expirationReason == "SUCCESS" else {
                        /// Failure, playback is no longer allowed
                        callback(expirationReason)
                        return
                    }
                    
                    /// Success, playback is validated
                    print("ProgramService: VALID")
                    callback(nil)
                }
            }
            else {
                /// Validation on program level requires the channel has Epg attached.
                ///
                /// If we are missing Epg, playback is allowed to continue.
                
                DispatchQueue.main.async { [weak self] in
                    self?.handleProgramChanged(program: nil)
                    self?.startValidationTimer(onTimestamp: timestamp, for: nil)
                }
                callback(nil)
                
                /// TODO: How do we handle successful fetches of Epg that return no program for the current timestamp?
                /// No Epg means we allow playback to continue.
                /// But what about *gaps in epg*?
                /// Should we *retry* after a certain amount of time to check if Epg eventually exists for the channel?
            }
        }
    }
    
    fileprivate func handleProgramChanged(program: Program?) {
        let current = activeProgram
        print("ProgramService: handleProgramChanged",current?.assetId,"-->",program?.assetId)
        activeProgram = program
        if current?.assetId != program?.assetId {
            onProgramChanged(program)
        }
    }
}

extension ProgramService {
    fileprivate func stopTimer() {
        timer?.setEventHandler{}
        timer?.cancel()
    }
    
    internal func isEntitled(toPlay timestamp: Int64, onSuccess: @escaping () -> Void) {
        print("ProgramService: isEntitled",timestamp)
        validate(timestamp: timestamp) { message in
            print("ProgramService: isEntitled.validate",timestamp,message)
            DispatchQueue.main.async { [weak self] in
                if let notEntitledMessage = message {
                    self?.onNotEntitled(notEntitledMessage)
                }
                else {
                    onSuccess()
                }
            }
        }
    }
    
    internal func startMonitoring() {
        guard let timestamp = self.currentPlayheadTime() else {
            print("ProgramService: startMonitoring.retry",Date().millisecondsSince1970)
            /// Retry untill we receive a current playhead time. This is only possible when playback has started
            stopTimer()
            timer = DispatchSource.makeTimerSource(queue: queue)
            timer?.scheduleOneshot(deadline: .now() + .milliseconds(2000))
            timer?.setEventHandler { [weak self] in
                self?.startMonitoring()
            }
            timer?.resume()
            return
        }
        
        stopTimer()
        provider.fetchProgram(on: channelId, timestamp: timestamp, using: environment) { [weak self] program, error in
            print("ProgramService: timestamp",timestamp,program?.programId,error?.code,error?.localizedDescription)
            guard error == nil else {
                // We are permissive on errors, allow playback
                return
            }
            
            self?.handleProgramChanged(program: program)
            self?.startValidationTimer(onTimestamp: timestamp, for: program)
        }
    }
    
    fileprivate func startValidationTimer(onTimestamp timestamp: Int64, for program: Program?) {
        print("ProgramService: startValidationTimer.start",timestamp,program?.programId)
        guard let end = program?.endDate?.millisecondsSince1970 else {
            // There is no program, validation can not occur, allow playback
            return
        }
        let delta = Int(end - timestamp)
        stopTimer()
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.scheduleOneshot(deadline: .now() + .milliseconds(delta))
        print("ProgramService: startValidationTimer schedule")
        timer?.setEventHandler { [weak self] in
            print("ProgramService: startValidationTimer eventHandler")
            guard let `self` = self else { return }
            guard let timestamp = self.currentPlayheadTime() else { return }
            self.validate(timestamp: timestamp) { invalidMessage in
                print("ProgramService: startValidationTimer.validate",invalidMessage)
                if let invalidMessage = invalidMessage {
                    DispatchQueue.main.async { [weak self] in
                        // The user is not entitled to play this program
                        self?.onNotEntitled(invalidMessage)
                    }
                }
            }
        }
        timer?.resume()
    }
}

extension ProgramService {
    internal var currentProgram: Program? {
        return activeProgram
    }

    internal func currentProgram(for timestamp: Int64, callback: @escaping (Program?, ExposureError?) -> Void) {
        provider.fetchProgram(on: channelId, timestamp: timestamp, using: environment, callback: callback)
    }
}
