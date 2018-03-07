//
//  ContextStartTime.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-02-07.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Player
import AVFoundation

internal protocol ContextStartTime: class {
    func handleStartTime(for tech: HLSNative<ExposureContext>, in context: ExposureContext) -> StartOffset
}

extension ContextStartTime {
    internal func check(offset: Int64, inRanges ranges: [CMTimeRange]) -> Bool {
        let cmTime = CMTime(value: offset, timescale: 1000)
        return ranges.reduce(false) { $0 || $1.containsTime(cmTime) }
    }
}
