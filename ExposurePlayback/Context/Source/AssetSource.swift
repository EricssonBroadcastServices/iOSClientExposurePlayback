//
//  AssetSource.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-26.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Player

/// Specialized `MediaSource` used for playback of *Vod* assets
///
/// Start time `PlayFrom` behavior:
/// * `.beginning` : Playback starts from the beginning of asset
/// * `.bookmark` : Playback starts from the bookmarked position if available and fallbacks to `.defaultBehavior`
/// * `.customPosition(position:)` : Playback starts from the specified buffer position (in milliseconds) . Will ignore positions outside the `seekableRange`.
/// * `.customTime(time:)` : Starting from a unix timestamp is undefined for Vod assets. Will use `.defaultBehavior`
/// * `.defaultBehavior` Playback starts from the beginning of the asset
open class AssetSource: ExposureSource {
    public override func prepareSourceUrl(callback: @escaping (URL?) -> Void) {
        if let adService = adService {
            let sourceUrl = entitlement.adMediaLocator ?? entitlement.mediaLocator
            adService.prepareAsset(source: sourceUrl) {
                callback($0)
            }
        }
        else {
            callback(nil)
        }
    }
}

extension AssetSource: ContextPositionSeekable {
    internal func handleSeek(toPosition position: Int64, for player: Player<HLSNative<ExposureContext>>, in context: ExposureContext) {
        player.tech.seek(toPosition: position)
    }
}

extension AssetSource: ContextStartTime {
    internal func handleStartTime(for tech: HLSNative<ExposureContext>, in context: ExposureContext) -> StartOffset {
        switch context.playbackProperties.playFrom {
        case .defaultBehaviour:
            return defaultStartTime(for: tech, in: context)
        case .beginning:
            // Start from offset 0
            return .startPosition(position: 0)
        case .bookmark:
            // Use *EMP* supplied bookmark, else default behaviour (ie nil bookmark)
            guard let offset = entitlement.lastViewedOffset else { return defaultStartTime(for: tech, in: context) }
            
            guard !tech.isExternalPlaybackActive else {
                // EMP-11129 We cant check for invalidStartTime on Airplay events since the seekable ranges are not loaded yet.
                return .startPosition(position: Int64(offset))
            }
            
            if check(offset: Int64(offset), inRanges: tech.seekableRanges) {
                return .startPosition(position: Int64(offset))
            }
            else {
                return defaultStartTime(for: tech, in: context)
            }
        case .customPosition(position: let offset):
            guard !tech.isExternalPlaybackActive else {
                // EMP-11129 We cant check for invalidStartTime on Airplay events since the seekable ranges are not loaded yet.
                return .startPosition(position: offset)
            }
            
            // Use the custom supplied offset
            if check(offset: offset, inRanges: tech.seekableRanges) {
                return .startPosition(position: offset)
            }
            else {
                triggerInvalidStartTime(offset: offset, ranges: tech.seekableRanges, source: self, tech: tech)
                return defaultStartTime(for: tech, in: context)
            }
        case .customTime(timestamp: _):
            // Use the custom supplied offset
            return defaultStartTime(for: tech, in: context)
        }
    }
    
    private func defaultStartTime(for tech: HLSNative<ExposureContext>, in context: ExposureContext) -> StartOffset {
        // Default is to start from the beginning
        return .defaultStartTime
    }
}

extension AssetSource: HeartbeatsProvider {
    internal func heartbeat(for tech: HLSNative<ExposureContext>, in context: ExposureContext) -> Playback.Heartbeat {
        return Playback.Heartbeat(timestamp: Date().millisecondsSince1970, offsetTime: tech.playheadPosition)
    }
}

