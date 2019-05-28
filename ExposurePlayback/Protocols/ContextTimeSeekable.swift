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
        player.check(bounds: player.seekableTimeRanges, offset: timeInterval, ifBefore: {
            // Before seekable range, new entitlement request required
            player.handleProgramServiceBasedSeek(timestamp: timeInterval)
        }, ifWithin: {
            // Within bounds
            if let service = context.programService {
                service.isEntitled(toPlay: timeInterval) { program in
                    // NOTE: If `callback` is NOT fired:
                    //      * Playback is not entitled
                    //      * `onError` will be dispatched with message
                    //      * playback will be stopped and unloaded
                    player.tech.seek(toTime: timeInterval) { [weak service] success in
                        // We should not send programChanged event until we have actually arrived at the target timestamp
                        if success { service?.handleProgramChanged(program: program, isExtendedProgram: false) }
                    }
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


extension ContextTimeSeekable where Self: ContextPositionSeekable {
    /// Seeking with a zero-based offset in a `ContextTimeSeekable` `Source`.
    ///
    /// If the specified target offset occurs before or after the actual start or end of the stream, ie beyond the seekable range, seeking may still be possible if the player can handle ProgramService based seeking.
    ///
    /// The `ProgramService` based seeking does however require a unix timestamp to work correctly.
    ///
    /// - parameters:
    ///     - position: the requested target position (may possibly be outside of the seekable range)
    ///     - player: player used to seek
    ///     - context: stores the program service
    internal func handleSeek(toPosition position: Int64, for player: Player<HLSNative<ExposureContext>>, in context: ExposureContext, onAfter: @escaping (Int64, Int64) -> Void) {
        guard let timeInterval = position.timestampFrom(referenceTime: player.playheadTime, referencePosition: player.playheadPosition) else {
            /// TODO: Do we fail gracefully or simply seek by position? Throw a warning?
            return
        }
        player.check(bounds: player.seekableRanges, offset: position, ifBefore: {
            // Before seekable range, new entitlement request required
            player.handleProgramServiceBasedSeek(timestamp: timeInterval)
        }, ifWithin: {
            // Within bounds
            if let service = context.programService {
                service.isEntitled(toPlay: timeInterval) { program in
                    // NOTE: If `callback` is NOT fired:
                    //      * Playback is not entitled
                    //      * `onError` will be dispatched with message
                    //      * playback will be stopped and unloaded
                    player.tech.seek(toPosition: position) { [weak service] success in
                        // We should not send programChanged event until we have actually arrived at the target timestamp
                        if success { service?.handleProgramChanged(program: program, isExtendedProgram: false) }
                    }
                }
                
            }
            else {
                player.tech.seek(toPosition: position)
            }
        }) { lastPosition in
            // After seekable range.
            onAfter(timeInterval, lastPosition)
        }
    }
}
