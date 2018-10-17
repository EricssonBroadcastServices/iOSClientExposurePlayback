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

extension Player where Tech == HLSNative<ExposureContext> {
    // MARK: Seeking
    
    /// Indicates the drift from the actual live point as defined by the `ServerTime Wallclock` (milliseconds).
    ///
    /// May be `nil` if no server time has been synched or if the seekable ranges are empty.
    public var liveDelay: Int64? {
        let isDynamicManifest = context.isDynamicManifest(tech, tech.currentSource)
        guard isDynamicManifest else { return nil }
        if let last = seekableTimeRanges.last?.end.milliseconds, let serverTime = serverTime {
            return serverTime-last
        }
        return nil
    }
    
    
    /// Indicates the how far behind the live point playback is.
    ///
    /// This is effectively the difference between live point and the playhead.
    ///
    /// May be `nil` if seekable ranges are empty or the current playback is not timestamp related.
    public var timeBehindLive: Int64? {
        let isDynamicManifest = context.isDynamicManifest(tech, tech.currentSource)
        guard isDynamicManifest else { return nil }
        if let last = seekableTimeRanges.last?.end.milliseconds, let playheadTime = playheadTime {
            return playheadTime-last
        }
        return nil
    }
    
    /// Moves the `playheadTime` to the live point and performs the necessary entitlement checks.
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
        
        let destination = source.contractRestrictionsService.canSeek(fromTime: currentTimestamp, toTime: timeInterval)
        
        guard destination > 0 else {
            // Seeking is disabled. Trigger warning and ignore the seek atempt
            let reason: ExposureContext.Warning.ContractRestrictions = currentTimestamp < timeInterval ? .fastForwardDisabled : .rewindDisabled
            let warning = PlayerWarning<HLSNative<ExposureContext>,ExposureContext>.context(warning: ExposureContext.Warning.contractRestrictions(reason: reason))
            tech.eventDispatcher.onWarning(tech, source, warning)
            source.analyticsConnector.onWarning(tech: tech, source: source, warning: warning)
            return
        }
        
        if destination != timeInterval {
            // Contract restriction service modified the target offset
            let reason = ExposureContext.Warning.ContractRestrictions.policyChangedTargetSeekOffset(requested: timeInterval, allowed: destination)
            let warning = PlayerWarning<HLSNative<ExposureContext>,ExposureContext>.context(warning: ExposureContext.Warning.contractRestrictions(reason: reason))
            tech.eventDispatcher.onWarning(tech, source, warning)
            source.analyticsConnector.onWarning(tech: tech, source: source, warning: warning)
        }
        
        if let contextSeekable = source as? ContextTimeSeekable {
            contextSeekable.handleSeek(toTime: destination, for: self, in: context)
        }
        else {
            tech.seek(toTime: destination)
        }
    }
    
    /// Moves the playhead position to the specified offset in the players buffer
    ///
    /// Will make another entitlement request and reload the stream if `position` falls outside the seekable range
    ///
    /// - parameter position: target offset in milliseconds
    public func seek(toPosition position: Int64) {
        guard let source = tech.currentSource else { return }
        let destination = source.contractRestrictionsService.canSeek(fromPosition: playheadPosition, toPosition: position)
        
        guard destination > 0 else {
            // Seeking is disabled. Trigger warning and ignore the seek atempt
            let reason: ExposureContext.Warning.ContractRestrictions = playheadPosition < position ? .fastForwardDisabled : .rewindDisabled
            let warning = PlayerWarning<HLSNative<ExposureContext>,ExposureContext>.context(warning: ExposureContext.Warning.contractRestrictions(reason: reason))
            tech.eventDispatcher.onWarning(tech, source, warning)
            source.analyticsConnector.onWarning(tech: tech, source: source, warning: warning)
            return
        }
        
        if destination != position {
            // Contract restriction service modified the target offset
            let reason = ExposureContext.Warning.ContractRestrictions.policyChangedTargetSeekOffset(requested: position, allowed: destination)
            let warning = PlayerWarning<HLSNative<ExposureContext>,ExposureContext>.context(warning: ExposureContext.Warning.contractRestrictions(reason: reason))
            tech.eventDispatcher.onWarning(tech, source, warning)
            source.analyticsConnector.onWarning(tech: tech, source: source, warning: warning)
        }
        
        if let contextSeekable = source as? ContextPositionSeekable {
            contextSeekable.handleSeek(toPosition: destination, for: self, in: context)
        }
        else {
            tech.seek(toPosition: destination)
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
                    if let source = self.tech.currentSource {
                        source.analyticsConnector.onWarning(tech: self.tech, source: source, warning: contextWarning)
                    }
                }
                else {
                    // Gap in EPG, ignoring the seek
                    let warning = ExposureContext.Warning.programService(reason: .gapInEpg(timestamp: timestamp, channelId: programService.channelId))
                    let contextWarning = PlayerWarning<HLSNative<ExposureContext>,ExposureContext>.context(warning: warning)
                    self.tech.eventDispatcher.onWarning(self.tech, self.tech.currentSource, contextWarning)
                    if let source = self.tech.currentSource {
                        source.analyticsConnector.onWarning(tech: self.tech, source: source, warning: contextWarning)
                    }
                }
                return
            }
            
            self.stop()
            let properties = PlaybackProperties(old: self.context.playbackProperties, playFrom: PlaybackProperties.PlayFrom.customTime(timestamp: timestamp))
            
            /// Generating the playable through the `ExposureContext` instead of directly from the `Program` allows us to inject specialized `ProgramEntitlementProvider`s which will simplify testing.
            let playable = self.context.programPlayableGenerator(program)
            self.startPlayback(playable: playable, properties: properties)
        }
    }
}


extension Player where Tech == HLSNative<ExposureContext> {
    internal func checkBounds(timestamp: Int64, ifBefore: @escaping () -> Void, ifWithin: @escaping () -> Void, ifAfter: @escaping (Int64) -> Void) {
        let ranges = seekableTimeRanges
        guard !ranges.isEmpty, let first = ranges.first?.start.milliseconds, let last = ranges.last?.end.milliseconds else {
            let warning = PlayerWarning<HLSNative<ExposureContext>, ExposureContext>.tech(warning: .seekableRangesEmpty)
            tech.eventDispatcher.onWarning(tech, tech.currentSource, warning)
            if let source = self.tech.currentSource {
                source.analyticsConnector.onWarning(tech: self.tech, source: source, warning: warning)
            }
            return
        }
        
        if ranges.count > 1 {
            let warning = PlayerWarning<HLSNative<ExposureContext>, ExposureContext>.tech(warning: .discontinuousSeekableRanges(seekableRanges: ranges))
            tech.eventDispatcher.onWarning(tech, tech.currentSource, warning)
            if let source = self.tech.currentSource {
                source.analyticsConnector.onWarning(tech: self.tech, source: source, warning: warning)
            }
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
