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
        // TODO: Handle assert source seek to position
    }
}

extension AssetSource: ContextStartTime {
    internal func handleStartTime(for tech: HLSNative<ExposureContext>, in context: ExposureContext) {
        switch context.playbackProperties.playFrom {
        case .defaultBehaviour:
            defaultStartTime(for: tech, in: context)
        case .beginning:
            // Start from offset 0
            tech.startOffset(atPosition: 0)
        case .bookmark:
            // Use *EMP* supplied bookmark, else default behaviour (ie nil bookmark)
            if let offset = entitlement.lastViewedOffset {
                tech.startOffset(atPosition: Int64(offset))
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
        // Default is to start from the beginning
        tech.startOffset(atPosition: nil)
    }
}
