//
//  HLSNative+ExposureContext+Seek.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-17.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Player
import AVFoundation

extension CMTime {
    public var milliseconds: Int64 {
        return Int64(seconds*1000)
    }
    
    public init(milliseconds: Int64) {
        self.init(value: milliseconds, timescale: 1000)
    }
}
// MARK: - Playhead Time
extension Player where Tech == HLSNative<ExposureContext> {
    
    public var timeBehindLive: Int64? {
        if let last = seekableTimeRanges.last?.end.milliseconds, let serverTime = serverTime {
            print("timeBehindLive",(last-serverTime)/1000)
            return last-serverTime
        }
        return 0
    }
    
    /// For playback content that is associated with a range of dates, move the playhead to point within that range.
    ///
    /// Will make another entitlement request and reload the stream if `timeInterval` falls outside the range or if the content is not associated with a range of dates.
    ///
    /// - parameter timeInterval: target timestamp in unix epoch time (milliseconds)
    public func seek(toTime timeInterval: Int64) {
        /// Check Seekable Range
        let ranges = seekableTimeRanges
        guard !ranges.isEmpty else { return }
        if ranges.count == 1 {
            let first = ranges.first!.start.milliseconds
            let last = ranges.first!.end.milliseconds
            if timeInterval < first {
                // Before seekable range, new entitlement request required
                handleProgramServiceBasedSeek(timestamp: timeInterval)
            }
            else if timeInterval > last {
                // After seekable range. If this is a live manifest, we asume the intention is to find the livepoint. Ignore other seeks
                if let programService = context.programService {
                    // TODO: Should always be possible to "GO-LIVE"
                    programService.isEntitled(toPlay: last) { [weak self] in
                        self?.tech.seek(toTime: last)
                    }
                }
            }
            else {
                // Within bounds
                guard let source = tech.currentSource else { return }
                guard context.contractRestrictionsService.canSeek(from: playheadPosition, to: timeInterval, using: source.entitlement) else { return }
                
                if let programService = context.programService {
                    programService.isEntitled(toPlay: timeInterval) { [weak self] in
                        self?.tech.seek(toTime: timeInterval)
                    }
                }
                else {
                    self.seek(toTime: timeInterval)
                }
            }
        }
        else {
            // TODO: How do we handle discontinuous time ranges?
        }
    }
    
    /// Moves the playhead position to the specified offset in the players buffer
    ///
    /// Will make another entitlement request and reload the stream if `position` falls outside the seekable range
    ///
    /// - parameter position: target offset in milliseconds
    public func seek(toPosition position: Int64) {
        /// Check Seekable Range
        let ranges = seekableRanges
        guard !ranges.isEmpty else { return }
        if ranges.count == 1 {
            let first = ranges.first!.start.milliseconds
            let last = ranges.first!.end.milliseconds
            
            if position < first || position > last {
                if let timeInterval = timestamp(relatedTo: position) {
                    seek(toTime: timeInterval)
                }
            }
            else {
                // Within bounds
                guard let source = tech.currentSource else { return }
                guard context.contractRestrictionsService.canSeek(from: playheadPosition, to: position, using: source.entitlement) else { return }
                
                if let programService = context.programService, let timeInterval = timestamp(relatedTo: position) {
                    programService.isEntitled(toPlay: timeInterval) { [weak self] in
                        self?.tech.seek(toTime: timeInterval)
                    }
                }
                else {
                    self.seek(toPosition: position)
                }
            }
        }
        else {
            // TODO: How do we handle discontinuous time ranges?
        }
    }
    
    internal func handleProgramServiceBasedSeek(timestamp: Int64) {
        guard let programService = context.programService else {
            // TODO: What happens then?
            return
        }
        
        programService.currentProgram(for: timestamp) { [weak self] program, error in
            guard let `self` = self else { return }
            if let program = program {
                let properties = PlaybackProperties(autoplay: self.context.playbackProperties.autoplay, playFrom: PlaybackProperties.PlayFrom.custom(offset: timestamp))
                self.startPlayback(channelId: programService.channelId, programId: program.assetId, properties: properties)
            }
            
            // TODO: Do we ignore seek if no program is found or do we stop playback?
            // Do we send Playback.WARNING?
//            if let error = error {
//                let playerError = PlayerError<Tech, Tech.Context>.context(error: error)
//                guard let currentSource = self.tech.currentSource else { return }
//                self.tech.eventDispatcher.onError(self.tech, currentSource, playerError)
//                currentSource.analyticsConnector.onError(tech: self.tech, source: currentSource, error: playerError)
//                self.tech.stop()
//            }
        }
    }
    
    fileprivate func timestamp(relatedTo position: Int64) -> Int64? {
        guard let time = playheadTime else { return nil }
        return time - playheadPosition + position
    }
}

