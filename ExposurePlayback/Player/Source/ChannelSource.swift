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
    internal override func handleStartTime(for tech: HLSNative<ExposureContext>, in context: ExposureContext) {
        
        switch context.playbackProperties.playFrom {
        case .defaultBehaviour:
            defaultStartTime(for: tech, in: context)
        case .beginning:
            if isUnifiedPackager {
                // Start from  program start (using a t-param with stream start at program start)
                tech.startOffset(atPosition: 0 + ExposureSource.segmentLength)
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
        case .custom(offset: let offset):
            // Use the custom supplied offset
            if isUnifiedPackager {
                // Wallclock timestamp
                tech.startOffset(atTime: offset)
            }
            else {
                // 0 based offset
                tech.startOffset(atPosition: offset)
            }
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

extension ChannelSource: ProgramServiceEnabled {
    public var programServiceChannelId: String {
        return assetId
    }
}
