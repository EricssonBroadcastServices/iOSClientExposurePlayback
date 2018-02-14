//
//  ChannelSource.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-26.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Player

public class ChannelSource: ExposureSource {
    
}

extension ChannelSource: ContextTimeSeekable {
    internal func handleSeek(toTime timeInterval: Int64, for player: Player<HLSNative<ExposureContext>>, in context: ExposureContext) {
        // NOTE: ChannelSource playback is by definition done with a *live manifest*, ie dynamic and growing.
        handleSeek(toTime: timeInterval, for: player, in: context) { [weak self] lastTimestamp in
            // After seekable range.
            //
            // ChannelSource is always considered to be live which means seeking beyond the last seekable range would be impossible.
            //
            // We should give some "lee-way": ie if the `timeInterval` is `delta` more than the seekable range, we consider this a seek to the live point.
            //
            // Note: `delta` in this aspect is the *time behind live*
            let delta = player.timeBehindLive ?? 0
            if (timeInterval - delta) <= lastTimestamp {
                self?.handleGoLive(player: player, in: context)
//                if let programService = player.context.programService {
//                    programService.isEntitled(toPlay: lastTimestamp) {
//                        // NOTE: If `callback` is NOT fired:
//                        //      * Playback is not entitled
//                        //      * `onError` will be dispatched with message
//                        //      * playback will be stopped and unloaded
//                        player.tech.seek(toTime: lastTimestamp)
//                    }
//                }
//                else {
//                    player.tech.seek(toTime: lastTimestamp)
//                }
            }
            else {
                let warning = PlayerWarning<HLSNative<ExposureContext>, ExposureContext>.tech(warning: .seekTimeBeyondLivePoint(timestamp: timeInterval, livePoint: lastTimestamp))
                player.tech.eventDispatcher.onWarning(player.tech, player.tech.currentSource, warning)
            }
        }
    }
}

extension ChannelSource: ContextPositionSeekable {
    func handleSeek(toPosition position: Int64, for player: Player<HLSNative<ExposureContext>>, in context: ExposureContext) {
        if let playheadTime = player.playheadTime {
            let timeInterval = position.timestampFrom(referenceTime: playheadTime, referencePosition: player.playheadPosition)
            handleSeek(toTime: timeInterval, for: player, in: context)
        }
    }
}

extension ChannelSource: ContextStartTime {
    internal func handleStartTime(for tech: HLSNative<ExposureContext>, in context: ExposureContext) {
        switch context.playbackProperties.playFrom {
        case .defaultBehaviour:
            defaultStartTime(for: tech, in: context)
        case .beginning:
            if isUnifiedPackager {
                // Start from  program start (using a t-param with stream start at program start)
                tech.startOffset(atPosition: 0)
            }
            else {
                // Relies on traditional vod manifest
                tech.startOffset(atPosition: nil)
            }
        case .bookmark:
            // Use *EMP* supplied bookmark
            if let offset = entitlement.lastViewedOffset {
                if isUnifiedPackager {
                    // Wallclock timestamp
                    tech.startOffset(atTime: Int64(offset))
                }
                else {
                    // 0 based offset
                    tech.startOffset(atPosition: Int64(offset))
                }
            }
            else {
                defaultStartTime(for: tech, in: context)
            }
        case .customPosition(position: let offset):
            // Use the custom supplied offset
            tech.startOffset(atPosition: offset)
        case .customTime(timestamp: let offset):
            // Use the custom supplied offset
            tech.startOffset(atTime: offset)
        }
    }
    
    private func defaultStartTime(for tech: HLSNative<ExposureContext>, in context: ExposureContext) {
        if isUnifiedPackager {
            // Start from the live edge (relying on live manifest)
            tech.startOffset(atTime: nil)
        }
        else {
            // Default is to start from  live edge (relying on live manifest)
            tech.startOffset(atPosition: nil)
        }
    }
    
}

extension ChannelSource: ContextGoLive {
    internal func handleGoLive(player: Player<HLSNative<ExposureContext>>, in context: ExposureContext) {
        goToLiveDynamicManifest(player: player, in: context)
    }
}

extension ChannelSource: ProgramServiceEnabled {
    public var programServiceChannelId: String {
        return assetId
    }
}
