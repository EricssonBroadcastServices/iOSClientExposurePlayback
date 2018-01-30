//
//  ContractRestrictionsService.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-29.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation

internal class ContractRestrictionsService {
    
}

extension ContractRestrictionsService {
    internal func canSeek(from origin: Int64, to destination: Int64, using entitlement: PlaybackEntitlement) -> Bool {
        if destination < origin {
            return entitlement.rwEnabled
        }
        
        if destination > origin {
            return entitlement.ffEnabled
        }
        return true
    }
    
    internal func canPause(entitlement: PlaybackEntitlement) -> Bool {
        return entitlement.timeshiftEnabled
    }
}
