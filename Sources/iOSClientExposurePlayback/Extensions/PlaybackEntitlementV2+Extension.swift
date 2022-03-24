//
//  PlaybackEntitlementV2+Extension.swift
//  ExposurePlayback-iOS
//
//  Created by Udaya Sri Senarathne on 2019-04-09.
//  Copyright © 2019 emp. All rights reserved.
//

import Foundation
import iOSClientExposure

extension PlayBackEntitlementV2 {
    /// Checks if the manifest comes from the *Unified Packager*
    internal var isUnifiedPackager: Bool {
        
        guard let mediaLocator = formats?.first?.mediaLocator else {
            return false
        }
        return mediaLocator
            .pathComponents
            .reduce(false) { $0 || $1.contains(".isml") || $1.contains(".ism") }
    }
}

