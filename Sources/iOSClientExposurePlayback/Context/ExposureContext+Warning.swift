//
//  ExposureContext+Warning.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-01-30.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import iOSClientPlayer
import iOSClientExposure

extension ExposureContext {
    public enum Warning: WarningMessage {
        case timeBasedSeekRequestInNonTimeBasedSource(timestamp: Int64)
        
        case programService(reason: ExposureContext.Warning.ProgramService)
        
        case contractRestrictions(reason: ExposureContext.Warning.ContractRestrictions)
    }
}

extension ExposureContext.Warning {
    public var message: String {
        switch self {
        case .timeBasedSeekRequestInNonTimeBasedSource(timestamp: let timestamp): return "Seeking by unix timestamp \(timestamp) in a non-timebased source."
        case .programService(reason: let service): return service.message
        case .contractRestrictions(reason: let restriction): return restriction.message
        }
    }
}

extension ExposureContext.Warning {
    public enum ProgramService: WarningMessage {
        case fetchingCurrentProgramFailed(timestamp: Int64, channelId: String, error: ExposureError?)
        case gapInEpg(timestamp: Int64, channelId: String)
        case entitlementValidationFailed(programId: String, channelId: String, error: ExposureError?)
        case navigateToNextProgramFailed(programId: String, channelId: String, error: ExposureError?)
        case navigateToPreviousProgramFailed(programId: String, channelId: String, error: ExposureError?)
    }
}

extension ExposureContext.Warning.ProgramService {
    public var message: String {
        switch self {
        case .fetchingCurrentProgramFailed(timestamp: let timestamp, channelId: let channelId, error: let error): return "Program Service failed to fetch the current program at timestamp \(timestamp) on \(channelId). errorCode: \(error?.code) message: \(error?.message)"
        case .gapInEpg(timestamp: let timestamp, channelId: let channelId): return "Program Service encountered a gap in the Epg at timestamp \(timestamp) on \(channelId)"
        case .entitlementValidationFailed(programId: let programId, channelId: let channelId, error: let error): return "Program Service failed to validate program \(programId) on \(channelId). errorCode: \(error?.code) message: \(error?.message)"
        case .navigateToNextProgramFailed(programId: let programId, channelId: let channelId, error: let error): return "Navigating to next program is not allowed \(programId) on \(channelId). errorCode: \(error?.code) message: \(error?.message)"
        case .navigateToPreviousProgramFailed(programId: let programId, channelId: let channelId, error: let error): return "Navigating to previous program is not allowed \(programId) on \(channelId). errorCode: \(error?.code) message: \(error?.message)"
        }
    }
}

extension ExposureContext.Warning {
    public enum ContractRestrictions: WarningMessage {
        case fastForwardDisabled
        case rewindDisabled
        case timeshiftDisabled
        case policyChangedTargetSeekOffset(requested: Int64, allowed: Int64)
        case epgHasDisabled
    }
}


extension ExposureContext.Warning.ContractRestrictions {
    public var message: String {
        switch self {
        case .fastForwardDisabled: return "Contract restrictions disables fast forwarding"
        case .rewindDisabled: return "Contract restrictions disabled rewinding"
        case .timeshiftDisabled: return "Contract restrictions disabled timeshifting"
        case .policyChangedTargetSeekOffset(requested: let request, allowed: let allowed): return "Contract restrictions changed target seek offset from \(request) to \(allowed)"
        case .epgHasDisabled: return "EPG has disabled for the next program"
        }
    }
}
