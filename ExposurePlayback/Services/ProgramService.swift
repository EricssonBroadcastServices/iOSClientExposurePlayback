//
//  ProgramService.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-10.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import iOSClientExposure
import Player

internal protocol ProgramProvider {
    func fetchPrograms(on channelId: String, timestamp: Int64, using environment: Environment, callback: @escaping ([Program]?, ExposureError?) -> Void)
    func fetchNextProgram(on program: Program, using environment: Environment, callback: @escaping (Program?, ExposureError?) -> Void)
    func fetchPreviousProgram(on program: Program, using environment: Environment, callback: @escaping (Program?, ExposureError?) -> Void)
    func validate(entitlementFor assetId: String, environment: Environment, sessionToken: SessionToken, callback: @escaping (EntitlementValidation?, ExposureError?) -> Void)
}

internal protocol ProgramServiceEnabled {
    var programServiceChannelId: String { get }
}

/// `ProgramService` provides automatic tracking of the currently playing program including continuous entitlement validation during playback.
public class ProgramService {
    /// `Environment` to use when requesting program data
    fileprivate var environment: Environment
    
    fileprivate var sessionToken: SessionToken
    
    /// The channel to monitor
    internal let channelId: String
    
    /// Queue where `timer` runs
    fileprivate let queue: DispatchQueue
    
    fileprivate var fetchTimer: DispatchSourceTimer?
    fileprivate var programChangeTimer: DispatchSourceTimer?
    fileprivate var validateTimer: DispatchSourceTimer?
    
    internal var playbackRateObserver: RateObserver?
    
    /// Applies a fuzzy factor to the validation logic in order ease backend load.
    ///
    /// Values in milliseconds.
    ///
    /// - note: A minimum value of `30000` is enforced
    public var fuzzyFactor: UInt32 {
        get {
            return fuzzyConfiguration.fuzzyFactor
        }
        set {
            let acceptableValue = newValue > ProgramService.FuzzyFactor.minimumFuzzyFactor ? newValue : ProgramService.FuzzyFactor.minimumFuzzyFactor
            fuzzyConfiguration.fuzzyFactor = acceptableValue
        }
    }
    
    internal var fuzzyConfiguration: FuzzyFactor = FuzzyFactor()
    internal struct FuzzyFactor {
        internal static let minimumFuzzyFactor: UInt32 = 30 * 1000
        
        internal var fuzzyFactor: UInt32 = ProgramService.FuzzyFactor.minimumFuzzyFactor
        
        internal func fuzzyOffset(for timestamp: Int64, end: Int64) -> (Int, Int, Int) {
            let programDistance = UInt32(end - timestamp)
            let availablePco = programDistance > fuzzyFactor ? fuzzyFactor : programDistance
            /// ---t----+----------+----------->  Alt  -----+--t-----------+----------->
            ///    |    |          |          |             |  |           |          |
            ///    |    a....+.....p.....+....b             a..+.....+.....p.....+....b
            ///    |         |     |     |                     |     |     |     |
            ///    +---ffo---+     |     |                     +-ffo-+     |     |
            ///              +-pco-+     |                           +-pco-+     |
            ///                    +-fvo-+                                 +-fvo-+
            ///
            /// t:   timestamp
            /// a:   begining of fuzzy window
            /// ffo: fuzzy offset for program fetch
            /// p:   program change event
            /// pco: program change offset
            /// fvo: fuzzy offset for program validation
            /// b:   end of fuzzy window
            let pco = arc4random_uniform(availablePco)
            let ffo = programDistance - pco
            let fvo = fuzzyFactor - arc4random_uniform(fuzzyFactor)
            return (Int(ffo), Int(pco), Int(fvo))
        }
    }
    
    internal var currentPlayheadTime: () -> Int64? = { return nil }
    internal var isPlaying: () -> Bool = { return false }
    internal var onNotEntitled: (String) -> Void = { _ in }
    internal var onWarning: (ExposureContext.Warning.ProgramService) -> Void = { _ in }
    internal var onProgramChanged: (Program?) -> Void = { _ in }
    
    fileprivate var activeProgram: Program?
    fileprivate var started: Bool = false
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
        stopFetchTimer()
        stopProgramChangeTimer()
        stopValidateTimer()
        playbackRateObserver?.cancel()
    }
    
    internal var provider: ProgramProvider
    internal struct ExposureProgramProvider: ProgramProvider {
        
        
        /// Fetch next program
        ///
        /// - Parameters:
        ///   - program: current program
        ///   - environment: exposure environment 
        ///   - callback: callback to fire once the event is fired.
        func fetchNextProgram(on program: Program, using environment: Environment, callback: @escaping (Program?, ExposureError?) -> Void) {
            FetchEpg(environment: environment)
                .next(programId: program.programId)
                .request()
                .validate()
                .response {
                    callback($0.value, $0.error)
            }
        }
        
        
        /// Fetch the previous program
        ///
        /// - Parameters:
        ///   - program: current program
        ///   - environment: exposure enviornment
        ///   - callback: callback to fire once the event is fired.
        func fetchPreviousProgram(on program: Program, using environment: Environment, callback: @escaping (Program?, ExposureError?) -> Void) {
            FetchEpg(environment: environment)
                .previous(programId: program.programId)
                .request()
                .validate()
                .response {
                    callback($0.value, $0.error)
            }
        }
        
        func fetchPrograms(on channelId: String, timestamp: Int64, using environment: Environment, callback: @escaping ([Program]?, ExposureError?) -> Void) {
            FetchEpg(environment: environment)
                .channel(id: channelId)
                .filter(starting: timestamp, ending: timestamp)
                .filter(onlyPublished: true)
                .request()
                .validate()
                .response{
                    callback($0.value?.programs, $0.error)
            }
        }
        
        
        func validate(entitlementFor assetId: String, environment: Environment, sessionToken: SessionToken, callback: @escaping (EntitlementValidation?, ExposureError?) -> Void) {
            
            print(" Func VaLIDATE ")
            
            Entitlement(environment: environment, sessionToken: sessionToken)
                .validate(assetId: assetId)
                .request()
                .validate()
                .response{
                    
                    print(" VALIDATE CALL BACK " , $0.request?.url )
                    print(" VALIDATE CALL URL " , $0.request?.allHTTPHeaderFields )
                    print(" VALIDATE CALL URL " , $0.value )
                    print(" VALIDATE CALL URL " , $0.error )
                    callback($0.value, $0.error)
                    
                }
        }
    }
}

extension ProgramService {
    fileprivate func requestedProgram(for timestamp: Int64, fromCandidates candidates: [Program]) -> Program? {
        guard !candidates.isEmpty else { return nil }
        if candidates.count == 1 {
            guard let end = candidates.first?.endDate?.millisecondsSince1970, end != timestamp else {
                // If the only program available also has an end time equal to the requested timestamp, the program is considered over.
                return nil
            }
            return candidates.first
        }
        else {
            return candidates.last
        }
    }
    
    fileprivate func fetchProgram(timestamp: Int64, callback: @escaping (Program?, ExposureContext.Warning.ProgramService?) -> Void) {
        
        self.currentProgram(for: timestamp, callback: { program , error in
            
            if let currentlyPlayingProgram = program {
                
                // If the currenet program end time & the fetched program endtime is different :=>
                // Current program has extended
                if currentlyPlayingProgram.endDate?.millisecondsSince1970 != self.currentProgram?.endDate?.millisecondsSince1970 {
                    callback(program, nil)
                } else {
                    //// Using new NextProgram endpoint to get the next Protram
                    self.provider.fetchNextProgram(on: currentlyPlayingProgram, using: self.environment, callback: { [weak self ] nextProgram, error in
                        guard let `self` = self else { return }
                        guard error == nil else {
                            // There was an error fetching the program. Be permissive and allow playback
                            callback(nil, .fetchingCurrentProgramFailed(timestamp: timestamp, channelId: self.channelId, error: error))
                            return
                        }
                        if nextProgram != nil {
                            if nextProgram?.startDate?.millisecondsSince1970 != currentlyPlayingProgram.endDate?.millisecondsSince1970 {
                                // EPG HAS A GAP (nextprogram start time is not equal to the current program's end time )
                                callback(nil, .gapInEpg(timestamp: timestamp, channelId: self.channelId))
                            } else {
                                callback(nextProgram, nil)
                            }
                        }
                        else {
                            // GAP in EPG
                            callback(nil, .gapInEpg(timestamp: timestamp, channelId: self.channelId))
                        }
                    })
                    
                    // PRevious implementation using timestamps
                    /* self.provider.fetchPrograms(on: self.channelId, timestamp: timestamp, using: self.environment) { [weak self] newPrograms, error in
                        guard let `self` = self else { return }
                        guard error == nil else {
                            // There was an error fetching the program. Be permissive and allow playback
                            callback(nil, .fetchingCurrentProgramFailed(timestamp: timestamp, channelId: self.channelId, error: error))
                            return
                        }
                        
                        if let programs = newPrograms, let program = self.requestedProgram(for: timestamp, fromCandidates: programs) {
                            callback(program, nil)
                        }
                        else {
                            /// Validation on program level requires the channel has Epg attached.
                            ///
                            /// If we are missing Epg, playback is allowed to continue.
                            callback(nil, .gapInEpg(timestamp: timestamp, channelId: self.channelId))
                        }
                    } */
                    
                }
            } else {
                // When running the unit tests current program can be nil
                guard error == nil else {
                    // There was an error fetching the program. Be permissive and allow playback
                    callback(nil, .fetchingCurrentProgramFailed(timestamp: timestamp, channelId: self.channelId, error: error))
                    return
                }
                callback(nil, .gapInEpg(timestamp: timestamp, channelId: self.channelId))
            }
        })
    }
    
    
    fileprivate func validate(program: Program, callback: @escaping (ExposureContext.Warning.ProgramService?, String?) -> Void) {
        self.provider.validate(entitlementFor: program.assetId, environment: self.environment, sessionToken: self.sessionToken) { [weak self] validation, error in
            
            print(" Provider validae ")
            
            guard let `self` = self else { return }
            guard let expirationReason = validation?.status else {
                // We are permissive on validation errors, allow playback to continue.
                callback(.entitlementValidationFailed(programId: program.assetId, channelId: self.channelId, error: error), nil)
                return
            }
            
            guard expirationReason == "SUCCESS" else {
                /// Failure, playback is no longer allowed
                callback(nil, expirationReason)
                return
            }
            
            /// Success, playback is validated
            callback(nil, nil)
        }
    }
    
    internal func handleProgramChanged(program: Program?, isExtendedProgram: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            let current = self.activeProgram
            self.activeProgram = program
            if current?.programId != program?.programId && isExtendedProgram == false {
                self.onProgramChanged(program)
            }
            
            // The current program has extended, call program changed even if it's the same program
            else if ( current?.programId == program?.programId && isExtendedProgram == true ) {
                self.onProgramChanged(program)
            }
            
            else {
                // Do nothing
            }
        }
    }
}

extension ProgramService {
    fileprivate func stopFetchTimer() {
        fetchTimer?.setEventHandler{}
        fetchTimer?.cancel()
    }
    fileprivate func stopProgramChangeTimer() {
        programChangeTimer?.setEventHandler{}
        programChangeTimer?.cancel()
    }
    fileprivate func stopValidateTimer() {
        validateTimer?.setEventHandler{}
        validateTimer?.cancel()
    }
    
    internal func isEntitled(toPlay timestamp: Int64, onSuccess: @escaping (Program?) -> Void) {
        if let current = activeProgram, let start = current.startDate?.millisecondsSince1970, let end = current.endDate?.millisecondsSince1970 {
            if timestamp > start && timestamp < end {
                startValidationTimer(onTimestamp: timestamp, for: current)
                onSuccess(current)
                return
            }
        }
        
        fetchProgram(timestamp: timestamp) { [weak self] program, warning in
            // There was an error fetching the program. Be permissive and allow playback
            if let warning = warning {
                DispatchQueue.main.async { [weak self] in
                    self?.onWarning(warning)
                    onSuccess(program)
                }
            }
            else if let program = program {
                self?.validate(program: program) { [weak self] warning, notEntitledMessage in
                    DispatchQueue.main.async { [weak self] in
                        if let warning = warning {
                            /// Forward any warnings
                            self?.onWarning(warning)
                        }
                        if let notEntitledMessage = notEntitledMessage {
                            self?.onNotEntitled(notEntitledMessage)
                        }
                        else {
                            self?.startValidationTimer(onTimestamp: timestamp, for: program)
                            onSuccess(program)
                        }
                    }
                }
            }
        }
    }
    
    internal func pause() {
        stopFetchTimer()
        stopProgramChangeTimer()
        // IMPORTANT: We do not stop the validation timer. It will only act on its result IF the playheadTime is still within the program bounds it is validating
    }
    
    private func monitoringOffset() -> Int64 {
        return 0
    }
    
    internal func startMonitoring() {
        stopFetchTimer()
        stopProgramChangeTimer()
        
        guard let timestamp =  currentPlayheadTime() else { return }
        
        provider.fetchPrograms(on: channelId, timestamp: timestamp + monitoringOffset(), using: environment) { [weak self] newPrograms, error in
            guard let `self` = self else { return }
            guard error == nil else {
                // We are permissive on errors, allow playback
                self.handleProgramChanged(program: nil, isExtendedProgram: false)
                self.onWarning(.fetchingCurrentProgramFailed(timestamp: timestamp, channelId: self.channelId, error: error))
                return
            }
            
            guard let programs = newPrograms, let program = self.requestedProgram(for: timestamp, fromCandidates: programs) else {
                // There is no program, validation can not occur, allow playback
                self.handleProgramChanged(program: nil, isExtendedProgram: false)
                self.onWarning(.gapInEpg(timestamp: timestamp, channelId: self.channelId))
                return
            }
            self.handleProgramChanged(program: program, isExtendedProgram: false)
            self.startValidationTimer(onTimestamp: timestamp, for: program)
        }
    }
    
    
    fileprivate func startValidationTimer(onTimestamp timestamp: Int64, for program: Program) {
        guard isPlaying() else { return }
        
        guard let ending = program.endDate?.millisecondsSince1970 else {
            // TODO: Activate retry trigger
            return
        }
        
        guard ending - timestamp > 0 else { return }
        
        let fuzzyOffset = fuzzyConfiguration.fuzzyOffset(for: timestamp, end: ending)
        stopFetchTimer()
        stopProgramChangeTimer()
        
        fetchTimer = DispatchSource.makeTimerSource(queue: queue)
        fetchTimer?.schedule(deadline: .now() + .milliseconds(fuzzyOffset.0), leeway: .milliseconds(1000))
        fetchTimer?.setEventHandler { [weak self] in
            guard let `self` = self else { return }
            self.fetchProgram(timestamp: ending) { [weak self] program, warning in
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }
                    self.stopProgramChangeTimer()
                    self.programChangeTimer = DispatchSource.makeTimerSource(queue: self.queue)
                    self.programChangeTimer?.schedule(deadline: .now() + .milliseconds(fuzzyOffset.1), leeway: .milliseconds(1000))
                    self.programChangeTimer?.setEventHandler { [weak self] in
                        DispatchQueue.main.async { [weak self] in
                            guard let `self` = self else { return }
                            if let warning = warning {
                                // There was an error fetching the program. Be permissive and allow playback
                                self.onWarning(warning)
                            }
                            // Trigger the program change no matter what
                            // If the program has extended, it needs to be handled : isExtendedProgram => true
                            let isextended = program?.programId == self.currentProgram?.programId ? true : false
                            
                            self.handleProgramChanged(program: program, isExtendedProgram: isextended)
                            
                            if let program = program {
                                // If we received a program, validate that
                                self.validateTimer = DispatchSource.makeTimerSource(queue: self.queue)
                                self.validateTimer?.schedule(deadline: .now() + .milliseconds(fuzzyOffset.2), leeway: .milliseconds(1000))
                                self.validateTimer?.setEventHandler { [weak self] in
                                    guard let `self` = self else { return }
                                    self.validate(program: program) { [weak self] warning, notEntitledMessage in
                                        DispatchQueue.main.async { [weak self] in
                                            guard let `self` = self else { return }
                                            /// NOTE: Validation data is ONLY relevant if the current playheadTime is still within program bounds
                                            guard let currentTimeStamp = self.currentPlayheadTime() else { return }
                                            guard let start = program.startDate?.millisecondsSince1970, let end = program.endDate?.millisecondsSince1970 else { return }
                                            guard start <= currentTimeStamp && currentTimeStamp < end else { return }
                                            
                                            if let warning = warning {
                                                /// Forward any warnings
                                                self.onWarning(warning)
                                            }
                                            
                                            if let notEntitledMessage = notEntitledMessage {
                                                self.onNotEntitled(notEntitledMessage)
                                            }
                                            else {
                                                self.startValidationTimer(onTimestamp: currentTimeStamp, for: program)
                                            }
                                            
                                        }
                                    }
                                }
                                self.validateTimer?.resume()
                            }
                        }
                    }
                    self.programChangeTimer?.resume()
                }
            }
        }
        fetchTimer?.resume()
    }
}

extension ProgramService {
    internal var currentProgram: Program? {
        return activeProgram
    }

    internal func currentProgram(for timestamp: Int64, callback: @escaping (Program?, ExposureError?) -> Void) {
        provider.fetchPrograms(on: channelId, timestamp: timestamp, using: environment) { newPrograms, error in
            guard error == nil else {
                callback(nil, error)
                return
            }
            
            guard let programs = newPrograms, let program = self.requestedProgram(for: timestamp, fromCandidates: programs) else {
                callback(nil, error)
                return
            }
            
            callback(program, nil)
        }
    }
}

// MARK: - Next & Previous Program
extension ProgramService {
    
    /// Call the provider for next program
    ///
    /// - Parameters:
    ///   - program: current program
    ///   - callback: callback: callback to fire once the event is fired.
    func nextProgram(program: Program, callback: @escaping (Program?, ExposureError?) -> Void) {
        
        let currentTimeStamp = Date().millisecondsSince1970
        guard let start = currentProgram?.startDate?.millisecondsSince1970, let end = currentProgram?.endDate?.millisecondsSince1970 else { return }
        if start <= currentTimeStamp && currentTimeStamp < end {
            let error = NSError(domain: "This is a live Program, navigating to the next program is not allowed", code: 40, userInfo: nil)
            self.onWarning(.navigateToNextProgramFailed(programId: program.programId, channelId: channelId, error: ExposureError.generalError(error: error)))
            callback(nil, nil)
        }
        else {
            provider.fetchNextProgram(on: program, using: environment, callback: { nextProgram, error in
                callback(nextProgram, error)
            })
        }
    }
    
    
    /// Call the provider for previous program
    ///
    /// - Parameters:
    ///   - program: current program
    ///   - callback: callback: callback to fire once the event is fired.
    func previousProgram(program: Program, callback: @escaping (Program?, ExposureError?) -> Void) {
        provider.fetchPreviousProgram(on: program, using: environment, callback: { previousProgram, error in
            callback(previousProgram, error)
        })
    }
}
