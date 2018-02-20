//
//  HLSNative+ExposureContext+Seek.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-17.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Player
import Exposure
import AVFoundation

// MARK: - Playhead Time
extension Player where Tech == HLSNative<ExposureContext> {
    
    public var timeBehindLive: Int64? {
        if let last = seekableTimeRanges.last?.end.milliseconds, let serverTime = serverTime {
            print("timeBehindLive",(serverTime-last)/1000)
            return serverTime-last
        }
        return 0
    }
    
    public func seekToLive() {
        guard let source = tech.currentSource else { return }
        if let source = source as? ContextGoLive {
            source.handleGoLive(player: self, in: context)
        }
    }
    
    /// For playback content that is associated with a range of dates, move the playhead to point within that range.
    ///
    /// Will make another entitlement request and reload the stream if `timeInterval` falls outside the range or if the content is not associated with a range of dates.
    ///
    /// - parameter timeInterval: target timestamp in unix epoch time (milliseconds)
    public func seek(toTime timeInterval: Int64) {
        guard let source = tech.currentSource else { return }
        guard let currentTimestamp = playheadTime else { return }
        let seekDisabled = context.contractRestrictionsService.canSeek(from: currentTimestamp, to: timeInterval, using: source.entitlement)
        guard seekDisabled == nil else {
            // Seeking is disabled. Trigger warning and ignore the seek atempt
            let warning = PlayerWarning<HLSNative<ExposureContext>,ExposureContext>.context(warning: seekDisabled!)
            tech.eventDispatcher.onWarning(tech, source, warning)
            return
        }
        
        if let contextSeekable = source as? ContextTimeSeekable {
            contextSeekable.handleSeek(toTime: timeInterval, for: self, in: context)
        }
        else {
            tech.seek(toTime: timeInterval)
        }
    }
    
    /// Moves the playhead position to the specified offset in the players buffer
    ///
    /// Will make another entitlement request and reload the stream if `position` falls outside the seekable range
    ///
    /// - parameter position: target offset in milliseconds
    public func seek(toPosition position: Int64) {
        guard let source = tech.currentSource else { return }
        let seekDisabled = context.contractRestrictionsService.canSeek(from: playheadPosition, to: position, using: source.entitlement)
        guard seekDisabled == nil else {
            // Seeking is disabled. Trigger warning and ignore the seek atempt
            let warning = PlayerWarning<HLSNative<ExposureContext>,ExposureContext>.context(warning: seekDisabled!)
            tech.eventDispatcher.onWarning(tech, source, warning)
            return
        }
        
        if let contextSeekable = source as? ContextPositionSeekable {
            contextSeekable.handleSeek(toPosition: position, for: self, in: context)
        }
        else {
            tech.seek(toPosition: position)
        }
    }
    
    internal func handleProgramServiceBasedSeek(timestamp: Int64) {
        guard let programService = context.programService else {
            // TODO: WARNING
//            tech.eventDispatcher.onWarning(tech, tech.currentSource, <#T##PlayerWarning<HLSNative<ExposureContext>, ExposureContext>#>)
            return
        }
        
        programService.currentProgram(for: timestamp) { [weak self] program, error in
            guard let `self` = self else { return }
            guard let program = program else {
                // Unable to fetch the program required for the `timestamp`
                if let error = error {
                    // Error fetching EPG, ignoring the seek
                    let warning = ExposureContext.Warning.programService(reason: .fetchingCurrentProgramFailed(timestamp: timestamp, channelId: programService.channelId, error: error))
                    let contextWarning = PlayerWarning<HLSNative<ExposureContext>,ExposureContext>.context(warning: warning)
                    self.tech.eventDispatcher.onWarning(self.tech, self.tech.currentSource, contextWarning)
                }
                else {
                    // Gap in EPG, ignoring the seek
                    let warning = ExposureContext.Warning.programService(reason: .gapInEpg(timestamp: timestamp, channelId: programService.channelId))
                    let contextWarning = PlayerWarning<HLSNative<ExposureContext>,ExposureContext>.context(warning: warning)
                    self.tech.eventDispatcher.onWarning(self.tech, self.tech.currentSource, contextWarning)
                }
                return
            }
            
            self.stop()
            let properties = PlaybackProperties(autoplay: self.context.playbackProperties.autoplay, playFrom: PlaybackProperties.PlayFrom.customTime(timestamp: timestamp))
            
            /// Generating the playable through the `ExposureContext` instead of directly from the `Program` allows us to inject specialized `ProgramEntitlementProvider`s which will simplify testing.
            let playable = self.context.programPlayableGenerator(program)
            self.startPlayback(playable: playable, properties: properties)
        }
    }
}


extension Player where Tech == HLSNative<ExposureContext> {
    internal func checkBounds(timestamp: Int64, ifBefore: @escaping () -> Void, ifWithin: @escaping () -> Void, ifAfter: @escaping (Int64) -> Void) {
        print("checkBounds")
        let ranges = seekableTimeRanges
        guard !ranges.isEmpty, let first = ranges.first?.start.milliseconds, let last = ranges.last?.end.milliseconds else {
            let warning = PlayerWarning<HLSNative<ExposureContext>, ExposureContext>.tech(warning: .seekableRangesEmpty)
            tech.eventDispatcher.onWarning(tech, tech.currentSource, warning)
            return
        }
        
        if ranges.count > 1 {
            let warning = PlayerWarning<HLSNative<ExposureContext>, ExposureContext>.tech(warning: .discontinuousSeekableRanges(seekableRanges: ranges))
            tech.eventDispatcher.onWarning(tech, tech.currentSource, warning)
        }
        
        if timestamp < first {
            // Before seekable range
            ifBefore()
        }
        else if timestamp > (last) {
            // After seekable range.
            ifAfter(last)
        }
        else {
            // Within bounds
            ifWithin()
        }
    }
}
