//
//  ContextGoLive.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-02-07.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Player

internal protocol ContextGoLive {
    func handleGoLive(player: Player<HLSNative<ExposureContext>>, in context: ExposureContext)
}

extension ContextGoLive {
    internal func handleGoLive(player: Player<HLSNative<ExposureContext>>, in context: ExposureContext) {
        let ranges = player.seekableTimeRanges
        guard !ranges.isEmpty, let last = ranges.last?.end.milliseconds else {
            let warning = PlayerWarning<HLSNative<ExposureContext>, ExposureContext>.tech(warning: .seekableRangesEmpty)
            player.tech.eventDispatcher.onWarning(player.tech, player.tech.currentSource, warning)
            return
        }
        
        if ranges.count > 1 {
            let warning = PlayerWarning<HLSNative<ExposureContext>, ExposureContext>.tech(warning: .discontinuousSeekableRanges(seekableRanges: ranges))
            player.tech.eventDispatcher.onWarning(player.tech, player.tech.currentSource, warning)
        }
        
        if let programService = player.context.programService {
            programService.isEntitled(toPlay: last) {
                player.tech.seek(toTime: last)
            }
        }
        else {
            player.tech.seek(toTime: last)
        }
    }
}
