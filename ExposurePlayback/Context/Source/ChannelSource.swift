//
//  ChannelSource.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-26.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Player

/// Specialized `MediaSource` used for starting live playback of channels
///
/// Start time `PlayFrom` behavior:
/// * `.beginning` : Playback starts from the beginning of the currently live program.
/// * `.bookmark` : Playback starts from the bookmarked position if available and fallbacks to `.defaultBehavior`
/// * `.customPosition(position:)` : Playback starts from the specified buffer position (in milliseconds) . Will ignore positions outside the `seekableRange` and present the application with an `invalidStartTime(startTime:seekableRanges:)` warning
/// * `.customTime(time:)` : Playback starts from the specified unix timestamp (in milliseconds). Will ignore timestamps not within the `seekableTimeRange` and present the application with an `invalidStartTime(startTime:seekableRanges:)` warning.
/// * `.defaultBehavior` Playback starts from the live edge
open class ChannelSource: ExposureSource { }

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
            let delta = player.liveDelay ?? 0
            if (timeInterval - delta) <= lastTimestamp {
                self?.handleGoLive(player: player, in: context)
            }
            else {
                let warning = PlayerWarning<HLSNative<ExposureContext>, ExposureContext>.tech(warning: .seekTimeBeyondLivePoint(timestamp: timeInterval, livePoint: lastTimestamp))
                player.tech.eventDispatcher.onWarning(player.tech, player.tech.currentSource, warning)
                guard let `self` = self else { return }
                self.analyticsConnector.onWarning(tech: player.tech, source: self, warning: warning)
            }
        }
    }
}

extension ChannelSource: ContextPositionSeekable {
    internal func handleSeek(toPosition position: Int64, for player: Player<HLSNative<ExposureContext>>, in context: ExposureContext) {
        if let playheadTime = player.playheadTime {
            let timeInterval = position.timestampFrom(referenceTime: playheadTime, referencePosition: player.playheadPosition)
            handleSeek(toTime: timeInterval, for: player, in: context)
        }
    }
}

extension ChannelSource: ContextStartTime {
    internal func handleStartTime(for tech: HLSNative<ExposureContext>, in context: ExposureContext) -> StartOffset {
        switch context.playbackProperties.playFrom {
        case .defaultBehaviour:
            return defaultStartTime(for: tech, in: context)
        case .beginning:
            if isUnifiedPackager {
                // Start from  program start (using a t-param with stream start at program start)
                return .startPosition(position: ExposureSource.segmentLength)
            }
            else {
                // Relies on traditional vod manifest
                return .defaultStartTime
            }
        case .bookmark:
            // Use *EMP* supplied bookmark
            guard let offset = entitlement.lastViewedOffset else { return defaultStartTime(for: tech, in: context) }
            
            guard !tech.isExternalPlaybackActive else {
                // EMP-11129 We cant check for invalidStartTime on Airplay events since the seekable ranges are not loaded yet.
                return .startPosition(position: Int64(offset))
            }
            
            if check(offset: Int64(offset), inRanges: tech.seekableRanges) {
                // 0 based offset
                return .startPosition(position: Int64(offset))
            }
            else {
                return defaultStartTime(for: tech, in: context)
            }
        case .customPosition(position: let offset):
            // Use the custom supplied offset
            guard !tech.isExternalPlaybackActive else {
                // EMP-11129 We cant check for invalidStartTime on Airplay events since the seekable ranges are not loaded yet.
                return .startPosition(position: offset)
            }
            
            if check(offset: offset, inRanges: tech.seekableRanges) {
                return .startPosition(position: offset)
            }
            else {
                triggerInvalidStartTime(offset: offset, ranges: tech.seekableRanges, source: self, tech: tech)
                return defaultStartTime(for: tech, in: context)
            }
        case .customTime(timestamp: let offset):
            guard !tech.isExternalPlaybackActive else {
                // EMP-11129 We cant check for invalidStartTime on Airplay events since the seekable ranges are not loaded yet.
                return .startTime(time: offset)
            }
            
            // Use the custom supplied offset
            if check(offset: offset, inRanges: tech.seekableTimeRanges) {
                return .startTime(time: offset)
            }
            else {
                triggerInvalidStartTime(offset: offset, ranges: tech.seekableTimeRanges, source: self, tech: tech)
                return defaultStartTime(for: tech, in: context)
            }
        }
    }
    
    private func defaultStartTime(for tech: HLSNative<ExposureContext>, in context: ExposureContext) -> StartOffset {
        if isUnifiedPackager {
            // Start from the live edge (relying on live manifest)
            return .defaultStartTime
        }
        else {
            // Default is to start from  live edge (relying on live manifest)
            return .defaultStartTime
        }
    }
    
}

extension ChannelSource: ContextGoLive {
    internal func handleGoLive(player: Player<HLSNative<ExposureContext>>, in context: ExposureContext) {
        goToLiveDynamicManifest(player: player, in: context)
    }
}

extension ChannelSource: ProgramServiceEnabled {
    internal var programServiceChannelId: String {
        return assetId
    }
}

extension ChannelSource: HeartbeatsProvider {
    internal func heartbeat(for tech: HLSNative<ExposureContext>, in context: ExposureContext) -> Playback.Heartbeat {
        if isUnifiedPackager {
            return Playback.Heartbeat(timestamp: Date().millisecondsSince1970, offsetTime: tech.playheadTime ?? tech.playheadPosition)
        }
        else {
            return Playback.Heartbeat(timestamp: Date().millisecondsSince1970, offsetTime: tech.playheadPosition)
        }
    }
}
