//
//  AdServiceContractRestrictionsProvider.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-10-17.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation

internal class AdServiceContractRestrictionsProvider: ContractRestrictionsService {
    var contractRestrictionsPolicy: ContractRestrictionsPolicy? {
        get {
            return delegate.contractRestrictionsPolicy
        }
        set {
            delegate.contractRestrictionsPolicy = newValue
        }
    }
    
    
    internal unowned let delegate: ContractRestrictionsService
    internal init(delegate: ContractRestrictionsService) {
        self.delegate = delegate
    }
    
    
    func canSeek(fromPosition origin: Int64, toPosition destination: Int64) -> Int64 {
        return delegate.canSeek(fromPosition: origin, toPosition: destination)
    }
    
    func canSeek(fromTime origin: Int64, toTime destination: Int64) -> Int64 {
        return delegate.canSeek(fromTime: origin, toTime: destination)
    }
    
    func canPause(at position: Int64) -> Bool {
        return delegate.canPause(at: position)
    }
}
