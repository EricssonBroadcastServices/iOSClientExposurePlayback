//
//  ContextTimeSeekable.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-02-07.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Player

internal protocol ContextTimeSeekable {
    func handleSeek(toTime timeInterval: Int64, for player: Player<HLSNative<ExposureContext>>, in context: ExposureContext)
}

extension ContextTimeSeekable {
    internal func handleSeek(toTime timeInterval: Int64, for player: Player<HLSNative<ExposureContext>>, in context: ExposureContext, onAfter: @escaping (Int64) -> Void) {
        player.checkBounds(timestamp: timeInterval, ifBefore: {
            // Before seekable range, new entitlement request required
            player.handleProgramServiceBasedSeek(timestamp: timeInterval)
        }, ifWithin: {
            // Within bounds
            if let service = context.programService {
                service.isEntitled(toPlay: timeInterval) {
                    // NOTE: If `callback` is NOT fired:
                    //      * Playback is not entitled
                    //      * `onError` will be dispatched with message
                    //      * playback will be stopped and unloaded
                    player.tech.seek(toTime: timeInterval)
                }
                
            }
            else {
                player.tech.seek(toTime: timeInterval)
            }
        }) { lastTimestamp in
            // After seekable range.
            onAfter(lastTimestamp)
        }
    }
}
