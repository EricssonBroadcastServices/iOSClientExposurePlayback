//
//  PlaybackEntitlement+Extensions.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-02-19.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import iOSClientExposure

extension PlaybackEntitlement {
    /// Checks if the manifest comes from the *Unified Packager*
    internal var isUnifiedPackager: Bool {
        return mediaLocator
            .pathComponents
            .reduce(false) { $0 || $1.contains(".isml") || $1.contains(".ism") }
    }
}
