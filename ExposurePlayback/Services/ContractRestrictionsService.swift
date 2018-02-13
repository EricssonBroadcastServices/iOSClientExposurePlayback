//
//  ContractRestrictionsService.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-29.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Exposure

internal class ContractRestrictionsService {
    
}

extension ContractRestrictionsService {
    internal func canSeek(from origin: Int64, to destination: Int64, using entitlement: PlaybackEntitlement) -> ExposureContext.Warning? {
        if destination < origin && !entitlement.rwEnabled {
            return ExposureContext.Warning.contractRestrictions(reason: .rewindDisabled)
        }
        
        if destination > origin && !entitlement.ffEnabled {
            return ExposureContext.Warning.contractRestrictions(reason: .fastForwardDisabled)
        }
        return nil
    }
    
    internal func canPause(entitlement: PlaybackEntitlement) -> ExposureContext.Warning? {
        return entitlement.timeshiftEnabled ? nil : ExposureContext.Warning.contractRestrictions(reason: .timeshiftDisabled)
    }
}
