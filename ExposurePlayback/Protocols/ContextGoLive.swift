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
    internal func goToLiveDynamicManifest(player: Player<HLSNative<ExposureContext>>, in context: ExposureContext) {
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
            programService.isEntitled(toPlay: last) { program in
                // NOTE: If `callback` is NOT fired:
                //      * Playback is not entitled
                //      * `onError` will be dispatched with message
                //      * playback will be stopped and unloaded
                player.tech.seek(toTime: last) { [weak programService] success in
                    // We should not send programChanged event until we have actually arrived at the target timestamp
                    if success { programService?.handleProgramChanged(program: program) }
                }
            }
        }
        else {
            player.tech.seek(toTime: last)
        }
    }
    
    internal func goToLiveStaticManifest(player: Player<HLSNative<ExposureContext>>, in context: ExposureContext) {
        // Default is to do a channel play call. Easiest
        guard let channelId = context.programService?.channelId else {
            return
        }
        let playable = context.channelPlayableGenerator(channelId)
        player.startPlayback(playable: playable)
    }
}
