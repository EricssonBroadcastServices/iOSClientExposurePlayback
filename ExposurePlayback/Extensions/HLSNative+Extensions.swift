//
//  HLSNative+Extensions.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-02-08.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Player

extension HLSNative {
    internal var dynamicManifest: Bool {
        guard let type = playbackType else { return false }
        return (type == "LIVE" || type == "Live")
    }
}
