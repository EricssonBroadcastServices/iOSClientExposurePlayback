//
//  ContractRestrictionsPolicy.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-10-17.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation

@objc public class ContractRestrictionsPolicy: NSObject {
    public var timeshiftEnabled: Bool
    public var fastForwardEnabled: Bool
    public var rewindEnabled: Bool
    
    public override init() {
        self.timeshiftEnabled = false
        self.fastForwardEnabled = false
        self.rewindEnabled = false
        super.init()
    }
}
