//
//  ContextStartTime.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-02-07.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import iOSClientPlayer
import AVFoundation

internal protocol ContextStartTime: class {
    func handleStartTime(for tech: HLSNative<ExposureContext>, in context: ExposureContext) -> StartOffset
}

extension ContextStartTime {
    internal func check(offset: Int64, inRanges ranges: [CMTimeRange]) -> Bool {
        let cmTime = CMTime(value: offset, timescale: 1000)
        return ranges.reduce(false) { $0 || $1.containsTime(cmTime) }
    }
    
    internal func triggerInvalidStartTime(offset: Int64, ranges: [CMTimeRange], source: ExposureSource, tech: HLSNative<ExposureContext>) {
        let warning = PlayerWarning<HLSNative<ExposureContext>,ExposureContext>.tech(warning: .invalidStartTime(startTime: offset, seekableRanges: tech.seekableRanges))
        tech.eventDispatcher.onWarning(tech, source, warning)
        source.analyticsConnector.onWarning(tech: tech, source: source, warning: warning)
    }
}
