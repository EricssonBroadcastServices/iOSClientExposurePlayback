//
//  BasicContractRestrictions.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-10-17.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import iOSClientExposure

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
    
    internal func canSeek(fromPosition origin: Int64, toPosition destination: Int64) -> Bool {
        if destination < origin && !rwEnabled {
            return false
        }
        
        if destination > origin && !ffEnabled {
            return false
        }
        return true
    }
    
    func willSeek(fromPosition origin: Int64, toPosition destination: Int64) -> Int64 {
        return destination
    }
    
    internal func canPause(at position: Int64) -> Bool {
        return timeshiftEnabled
    }
}
