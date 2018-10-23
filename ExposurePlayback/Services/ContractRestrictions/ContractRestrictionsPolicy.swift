//
//  ContractRestrictionsPolicy.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-10-17.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation

@objc public class ContractRestrictionsPolicy: NSObject {
    @objc public var timeshiftEnabled: Bool
    @objc public var fastForwardEnabled: Bool
    @objc public var rewindEnabled: Bool
    
    @objc public override init() {
        self.timeshiftEnabled = false
        self.fastForwardEnabled = false
        self.rewindEnabled = false
        super.init()
    }
}
