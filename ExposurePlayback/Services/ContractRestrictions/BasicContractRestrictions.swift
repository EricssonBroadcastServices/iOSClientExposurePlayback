//
//  BasicContractRestrictions.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-10-17.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation

/// Implements basic contract restrictions based the raw `PlaybackEntitlement`
internal class BasicContractRestrictions: ContractRestrictionsService {
    internal init(entitlement: PlaybackEntitlement) {
        let policy = ContractRestrictionsPolicy()
        policy.fastForwardEnabled = entitlement.ffEnabled
        policy.rewindEnabled = entitlement.rwEnabled
        policy.timeshiftEnabled = entitlement.timeshiftEnabled
        contractRestrictionsPolicy = policy
    }
    
    internal var contractRestrictionsPolicy: ContractRestrictionsPolicy?
    
    internal var rwEnabled: Bool {
        return contractRestrictionsPolicy?.rewindEnabled ?? true
    }
    
    internal var ffEnabled: Bool {
        return contractRestrictionsPolicy?.fastForwardEnabled ?? true
    }
    
    internal var timeshiftEnabled: Bool {
        return contractRestrictionsPolicy?.timeshiftEnabled ?? true
    }
    
    internal func canSeek(fromPosition origin: Int64, toPosition destination: Int64) -> Int64 {
        if destination < origin && !rwEnabled {
            return -1
        }
        
        if destination > origin && !ffEnabled {
            return -1
        }
        return destination
    }
    
    internal func canSeek(fromTime origin: Int64, toTime destination: Int64) -> Int64 {
        if destination < origin && !rwEnabled {
            return -1
        }
        
        if destination > origin && !ffEnabled {
            return -1
        }
        return destination
    }
    
    internal func canPause(at position: Int64) -> Bool {
        return timeshiftEnabled
    }
}
