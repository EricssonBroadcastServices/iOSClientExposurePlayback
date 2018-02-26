//
//  ProgramService.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-10.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Exposure

internal protocol ProgramProvider {
    func fetchProgram(on channelId: String, timestamp: Int64, using environment: Environment, callback: @escaping (Program?, ExposureError?) -> Void)
    func validate(entitlementFor assetId: String, environment: Environment, sessionToken: SessionToken, callback: @escaping (EntitlementValidation?, ExposureError?) -> Void)
}

public protocol ProgramServiceEnabled {
    var programServiceChannelId: String { get }
}

public class ProgramService {
    /// `Environment` to use when requesting program data
    fileprivate var environment: Environment
    
    fileprivate var sessionToken: SessionToken
    
    /// The channel to monitor
    internal let channelId: String
    
    /// Queue where `timer` runs
    fileprivate let queue: DispatchQueue
    
    fileprivate var timer: DispatchSourceTimer?
    fileprivate var fuzzyFetchTimer: DispatchSourceTimer?
    
    /// Applies a fuzzy factor to the validation logic in order ease backend load.
    ///
    /// Values in milliseconds.
    ///
    /// - important: A minimum value of `30000` is enforced
    public var fuzzyFactor: Int {
        get {
            return privateFuzzyFactor
        }
        set {
            let acceptableValue = newValue > ProgramService.minimumFuzzyFactor ? newValue : ProgramService.minimumFuzzyFactor
            privateFuzzyFactor = acceptableValue
        }
    }
    internal var privateFuzzyFactor: Int = ProgramService.minimumFuzzyFactor
    internal static let minimumFuzzyFactor: Int = 30 * 1000
    
    internal var currentPlayheadTime: () -> Int64? = { return nil }
    internal var onNotEntitled: (String) -> Void = { _ in }
    internal var onWarning: (ExposureContext.Warning.ProgramService) -> Void = { _ in }
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
        self.privateFuzzyFactor = fuzzyFactor
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
                .validate()
                .response{ callback($0.value?.programs?.last, $0.error) }
        }
        
        func validate(entitlementFor assetId: String, environment: Environment, sessionToken: SessionToken, callback: @escaping (EntitlementValidation?, ExposureError?) -> Void) {
            Entitlement(environment: environment, sessionToken: sessionToken)
                .validate(assetId: assetId)
                .request()
                .validate()
                .response{ callback($0.value, $0.error) }
        }
    }
}

extension ProgramService {
    fileprivate func validate(timestamp: Int64, callback: @escaping (Program?, String?) -> Void) {
        if let current = activeProgram, let start = current.startDate?.millisecondsSince1970, let end = current.endDate?.millisecondsSince1970 {
            if timestamp > start && timestamp < end {
                startValidationTimer(onTimestamp: timestamp, for: current)
                callback(current, nil)
                return
            }
        }
        
        // We do not have a current program or the timestamp in question is outside the program bounds
        provider.fetchProgram(on: channelId, timestamp: timestamp, using: environment) { [weak self] newProgram, error in
            guard let `self` = self else { return }
            guard error == nil else {
                // There was an error fetching the program. Be permissive and allow playback
                self.onWarning(.fetchingCurrentProgramFailed(timestamp: timestamp, channelId: self.channelId, error: error))
                callback(nil, nil)
                return
            }
            
            if let program = newProgram {
                DispatchQueue.main.async { [weak self] in
                    self?.startValidationTimer(onTimestamp: timestamp, for: program)
                }
                
                self.provider.validate(entitlementFor: program.assetId, environment: self.environment, sessionToken: self.sessionToken) { [weak self] validation, error in
                    guard let `self` = self else { return }
                    guard let expirationReason = validation?.status else {
                        // We are permissive on validation errors, allow playback to continue.
                        DispatchQueue.main.async { [weak self] in
                            guard let `self` = self else { return }
                            self.onWarning(.entitlementValidationFailed(programId: program.assetId, channelId: self.channelId, error: error))
                        }
                        callback(program, nil)
                        return
                    }
                    
                    guard expirationReason == "SUCCESS" else {
                        /// Failure, playback is no longer allowed
                        callback(program, expirationReason)
                        return
                    }
                    
                    /// Success, playback is validated
                    callback(program, nil)
                }
            }
            else {
                /// Validation on program level requires the channel has Epg attached.
                ///
                /// If we are missing Epg, playback is allowed to continue.
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }
                    callback(nil, nil)
                    self.onWarning(.gapInEpg(timestamp: timestamp, channelId: self.channelId))
                }
            }
        }
    }
    
    internal func handleProgramChanged(program: Program?) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            let current = self.activeProgram
            self.activeProgram = program
            if current?.programId != program?.programId {
                self.onProgramChanged(program)
            }
        }
    }
}

extension ProgramService {
    fileprivate func stopTimer() {
        timer?.setEventHandler{}
        timer?.cancel()
    }
    
    internal func isEntitled(toPlay timestamp: Int64, onSuccess: @escaping (Program?) -> Void) {
        validate(timestamp: timestamp) { [weak self] program, message in
            DispatchQueue.main.async { [weak self] in
                if let notEntitledMessage = message {
                    self?.onNotEntitled(notEntitledMessage)
                }
                else {
                    onSuccess(program)
                }
            }
        }
    }
    
    internal func startMonitoring(epgOffset: Int64) {
        guard let timestamp =  currentPlayheadTime() else {
            /// Retry untill we receive a current playhead time. This is only possible when playback has started
            stopTimer()
            timer = DispatchSource.makeTimerSource(queue: queue)
            timer?.schedule(deadline: .now() + .milliseconds(2000))
            timer?.setEventHandler { [weak self] in
                DispatchQueue.main.async { [weak self] in
                    self?.startMonitoring(epgOffset: epgOffset)
                }
            }
            timer?.resume()
            return
        }
        
        stopTimer()
        provider.fetchProgram(on: channelId, timestamp: timestamp + epgOffset, using: environment) { [weak self] program, error in
            guard let `self` = self else { return }
            guard error == nil else {
                // We are permissive on errors, allow playback
                
                self.onWarning(.fetchingCurrentProgramFailed(timestamp: timestamp, channelId: self.channelId, error: error))
                return
            }
            self.handleProgramChanged(program: program)
            self.startValidationTimer(onTimestamp: timestamp, for: program)
        }
    }
    
    fileprivate func startValidationTimer(onTimestamp timestamp: Int64, for program: Program?) {
        guard let end = program?.endDate?.millisecondsSince1970 else {
            // There is no program, validation can not occur, allow playback
            onWarning(.gapInEpg(timestamp: timestamp, channelId: channelId))
            return
        }
        
        
        
        let delta = Int(end - timestamp)
        stopTimer()
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now() + .milliseconds(delta))
        timer?.setEventHandler { [weak self] in
            guard let `self` = self else { return }
            guard let timestamp = self.currentPlayheadTime() else { return }
            self.validate(timestamp: timestamp) { program, invalidMessage in
                DispatchQueue.main.async { [weak self] in
                    if let invalidMessage = invalidMessage {
                        // The user is not entitled to play this program
                        self?.onNotEntitled(invalidMessage)
                    }
                    self?.handleProgramChanged(program: program)
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
