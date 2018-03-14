//
//  AssetSource.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-26.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Player

public class AssetSource: ExposureSource {
    
}

extension AssetSource: ContextPositionSeekable {
    func handleSeek(toPosition position: Int64, for player: Player<HLSNative<ExposureContext>>, in context: ExposureContext) {
        player.tech.seek(toPosition: position)
    }
}

extension AssetSource: ContextStartTime {
    func handleStartTime(for tech: HLSNative<ExposureContext>, in context: ExposureContext) -> StartOffset {
        switch context.playbackProperties.playFrom {
        case .defaultBehaviour:
            return defaultStartTime(for: tech, in: context)
        case .beginning:
            // Start from offset 0
            return .startPosition(position: 0)
        case .bookmark:
            // Use *EMP* supplied bookmark, else default behaviour (ie nil bookmark)
            if let offset = entitlement.lastViewedOffset, check(offset: Int64(offset), inRanges: tech.seekableRanges) {
                return .startPosition(position: Int64(offset))
            }
            else {
                return defaultStartTime(for: tech, in: context)
            }
        case .customPosition(position: let offset):
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

