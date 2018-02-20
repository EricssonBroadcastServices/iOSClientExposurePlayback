//
//  ProgramSource.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-26.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Player
import Exposure

public class ProgramSource: ExposureSource {
    public let channelId: String
    public init(entitlement: PlaybackEntitlement, assetId: String, channelId: String) {
        self.channelId = channelId
        super.init(entitlement: entitlement, assetId: assetId)
    }
}

extension ProgramSource: ContextTimeSeekable {
    internal func handleSeek(toTime timeInterval: Int64, for player: Player<HLSNative<ExposureContext>>, in context: ExposureContext) {
        // NOTE: ProgramSource playback can be either *dynamic catchup*, ie a growing manifest, or *static catchup*, ie a vod manifest
        handleSeek(toTime: timeInterval, for: player, in: context) { [weak self] lastTimestamp in
            guard let `self` = self else { return }
            // After seekable range.
            
            // TODO: Check fragility of checking for `playbackType`
            if context.isDynamicManifest(player.tech, self) {
                // ProgreamSource is considered to be live which means seeking beyond the last seekable range would be impossible.
                //
                // We should give some "lee-way": ie if the `timeInterval` is `delta` more than the seekable range, we consider this a seek to the live point.
                //
                // Note: `delta` in this aspect is the *time behind live*
                let delta = player.timeBehindLive ?? 0
                if (timeInterval - delta) <= lastTimestamp {
                    self.handleGoLive(player: player, in: context)
                }
                else {
                    let warning = PlayerWarning<HLSNative<ExposureContext>, ExposureContext>.tech(warning: .seekTimeBeyondLivePoint(timestamp: timeInterval, livePoint: lastTimestamp))
                    player.tech.eventDispatcher.onWarning(player.tech, player.tech.currentSource, warning)
                }
            }
            else {
                // ProgramSource is considered static catchup.
                //
                // Seeking beyond the manifest should trigger an entitlement request
                player.handleProgramServiceBasedSeek(timestamp: timeInterval)
            }
        }
    }
}

extension ProgramSource: ContextPositionSeekable {
    func handleSeek(toPosition position: Int64, for player: Player<HLSNative<ExposureContext>>, in context: ExposureContext) {
        if let playheadTime = player.playheadTime {
            let timeInterval = position.timestampFrom(referenceTime: playheadTime, referencePosition: player.playheadPosition)
            handleSeek(toTime: timeInterval, for: player, in: context)
        }
    }
}

extension ProgramSource: ContextStartTime {
    internal func handleStartTime(for tech: HLSNative<ExposureContext>, in context: ExposureContext) {
        switch context.playbackProperties.playFrom {
        case .defaultBehaviour:
            defaultStartTime(for: tech, in: context)
        case .beginning:
            if isUnifiedPackager {
                // Start from  program start (using a t-param with stream start at program start)
                tech.startOffset(atPosition: ExposureSource.segmentLength)
            }
            else {
                // Relies on traditional vod manifest
                tech.startOffset(atPosition: nil)
            }
        case .bookmark:
            // Use *EMP* supplied bookmark
            if let offset = entitlement.lastViewedOffset {
                if isUnifiedPackager {
                    // 0 based offset
                    tech.startOffset(atPosition: Int64(offset))
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
            if entitlement.live {
                // Start from the live edge (relying on live manifest)
                tech.startOffset(atTime: nil)
            }
            else {
                // Start from program start (using a t-param with stream start at program start)
                tech.startOffset(atPosition: ExposureSource.segmentLength)
            }
        }
        else {
            // Default is to start from program start (relying on traditional vod manifest)
            tech.startOffset(atPosition: nil)
        }
    }
}

extension ProgramSource: ContextGoLive {
    internal func handleGoLive(player: Player<HLSNative<ExposureContext>>, in context: ExposureContext) {
        if context.isDynamicManifest(player.tech, self) {
            goToLiveDynamicManifest(player: player, in: context)
        }
        else {
            goToLiveStaticManifest(player: player, in: context)
        }
    }
}

extension ProgramSource: ProgramServiceEnabled {
    public var programServiceChannelId: String {
        return channelId
    }
}

extension ProgramSource: HeartbeatsProvider {
    internal func heartbeat(for tech: HLSNative<ExposureContext>, in context: ExposureContext) -> Playback.Heartbeat {
        if isUnifiedPackager {
            return Playback.Heartbeat(timestamp: Date().millisecondsSince1970, offsetTime: tech.playheadTime ?? tech.playheadPosition)
        }
        else {
            return Playback.Heartbeat(timestamp: Date().millisecondsSince1970, offsetTime: tech.playheadPosition)
        }
    }
}
