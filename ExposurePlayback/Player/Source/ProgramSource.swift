//
//  ProgramSource.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-26.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Player

public class ProgramSource: ExposureSource {
    public let channelId: String
    public init(entitlement: PlaybackEntitlement, assetId: String, channelId: String) {
        self.channelId = channelId
        super.init(entitlement: entitlement, assetId: assetId)
    }
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
                    tech.startOffset(atPosition: Int64(offset))
                    // Wallclock timestamp
                    //                    tech.startOffset(atTime: Int64(offset))
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
            if entitlement.live {
                // Start from the live edge (relying on live manifest)
                tech.startOffset(atTime: nil)
            }
            else {
                // Start from program start (using a t-param with stream start at program start)
                tech.startOffset(atPosition: 0 + ExposureSource.segmentLength)
            }
        }
        else {
            // Default is to start from program start (relying on traditional vod manifest)
            tech.startOffset(atPosition: nil)
        }
    }
}

extension ProgramSource: ProgramServiceEnabled {
    public var programServiceChannelId: String {
        return channelId
    }
}
