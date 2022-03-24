//
//  ContextGoLive.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-02-07.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import iOSClientPlayer

internal protocol ContextGoLive {
    func handleGoLive(player: Player<HLSNative<ExposureContext>>, in context: ExposureContext)
}

extension ContextGoLive {
    internal func goToLiveDynamicManifest(player: Player<HLSNative<ExposureContext>>, in context: ExposureContext) {
        let ranges = player.seekableTimeRanges
        

        guard !ranges.isEmpty, let last = ranges.last?.end.milliseconds else {
            let warning = PlayerWarning<HLSNative<ExposureContext>, ExposureContext>.tech(warning: .seekableRangesEmpty)
            player.tech.eventDispatcher.onWarning(player.tech, player.tech.currentSource, warning)
            if let source = player.tech.currentSource {
                source.analyticsConnector.onWarning(tech: player.tech, source: source, warning: warning)
            }
            return
        }
        
        if ranges.count > 1 {
            let warning = PlayerWarning<HLSNative<ExposureContext>, ExposureContext>.tech(warning: .discontinuousSeekableRanges(seekableRanges: ranges))
            player.tech.eventDispatcher.onWarning(player.tech, player.tech.currentSource, warning)
            if let source = player.tech.currentSource {
                source.analyticsConnector.onWarning(tech: player.tech, source: source, warning: warning)
            }
        }
        
        // Check if we have any live delay value from the entitlement request
        if  let liveDelay = player.tech.currentSource?.entitlement.liveDelay {
            let liveTime = last - liveDelay
            if let programService = player.context.programService {
                programService.isEntitled(toPlay: liveTime) { program in
                    // NOTE: If `callback` is NOT fired:
                    //      * Playback is not entitled
                    //      * `onError` will be dispatched with message
                    //      * playback will be stopped and unloaded
                    player.tech.seek(toTime: liveTime) { [weak programService] success in
                        // We should not send programChanged event until we have actually arrived at the target timestamp
                        if success { programService?.handleProgramChanged(program: program, isExtendedProgram: false) }
                    }
                }
            }
            else {
                player.tech.seek(toTime: last)
            }
        } else {
            
            // No liveDelay value was found
            if let serverTime = player.serverTime, last > serverTime {
                /// It is impossible to search beyond the actual live point
                let warning = PlayerWarning<HLSNative<ExposureContext>, ExposureContext>.tech(warning: .seekTimeBeyondLivePoint(timestamp: last, livePoint: serverTime))
                player.tech.eventDispatcher.onWarning(player.tech, player.tech.currentSource, warning)
                player.tech.currentSource?.analyticsConnector.onWarning(tech: player.tech, source: player.tech.currentSource, warning: warning)
                return
            }
            
            if let programService = player.context.programService {
                programService.isEntitled(toPlay: last) { program in
                    // NOTE: If `callback` is NOT fired:
                    //      * Playback is not entitled
                    //      * `onError` will be dispatched with message
                    //      * playback will be stopped and unloaded
                    player.tech.seek(toTime: last) { [weak programService] success in
                        // We should not send programChanged event until we have actually arrived at the target timestamp
                        if success { programService?.handleProgramChanged(program: program, isExtendedProgram: false) }
                    }
                }
            }
            else {
                player.tech.seek(toTime: last)
            }
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
