//
//  ProgramSource.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-26.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Player
import Exposure

/// Specialized `MediaSource` used for starting playback of a specific program on a channel
///
/// Start time `PlayFrom` behavior:
/// * `.beginning` : Playback starts from the beginning of the program
/// * `.bookmark` : Playback starts from the bookmarked position if available and fallbacks to `.defaultBehavior`
/// * `.customPosition(position:)` : Playback starts from the specified buffer position (in milliseconds) . Will ignore positions outside the `seekableRange` and present the application with an `invalidStartTime(startTime:seekableRanges:)` warning
/// * `.customTime(time:)` : Playback starts from the specified unix timestamp (in milliseconds). Will ignore timestamps not within the `seekableTimeRange` and present the application with an `invalidStartTime(startTime:seekableRanges:)` warning.
/// * `.defaultBehavior` If the program is currently *live*, playback will start from the live edge., otherwise playback starts from the beginning of the program
open class ProgramSource: ExposureSource {
    /// The channel Id on which the program plays
    public let channelId: String
    
    /// Creates a new `ProgramSource`
    ///
    /// - parameter entitlement: `PlaybackEntitlement` used to play the program
    /// - parameter assetId: The id for the program
    /// - parameter channelId: The channel Id on which the program plays
    public init(entitlement: PlaybackEntitlement, assetId: String, channelId: String, streamingInfo: StreamInfo?, sprites: [Sprites]? = nil ) {
        self.channelId = channelId
        super.init(entitlement: entitlement, assetId: assetId, streamingInfo: streamingInfo, sprites: sprites)
    }
    
    /// Creates a new `ProgramSource`
    ///
    /// - parameter entitlement: `PlaybackEntitlement` used to play the program
    /// - parameter assetId: The id for the program
    /// - parameter channelId: The channel Id on which the program plays
    /// - parameter response: HTTP response received when requesting the entitlement
    public init(entitlement: PlaybackEntitlement, assetId: String, channelId: String, response: HTTPURLResponse? = nil, streamingInfo: StreamInfo?, sprites: [Sprites]? = nil) {
        self.channelId = channelId
        super.init(entitlement: entitlement, assetId: assetId, response: response, streamingInfo: streamingInfo, sprites: sprites)
    }
    
    public override func prepareSourceUrl(callback: @escaping (URL?) -> Void) {
        if let adService = adService, let adMediaLocator = entitlement.adMediaLocator {
            adService.prepareProgram(source: adMediaLocator) {
                callback($0)
            }
        }
        else {
            callback(nil)
        }
    }
}

extension ProgramSource: ContextTimeSeekable {
    internal func handleSeek(toTime timeInterval: Int64, for player: Player<HLSNative<ExposureContext>>, in context: ExposureContext) {
        // NOTE: ProgramSource playback can be either *dynamic catchup*, ie a growing manifest, or *static catchup*, ie a vod manifest
        handleSeek(toTime: timeInterval, for: player, in: context) { [weak self] lastTimestamp in
            guard let `self` = self else { return }
            // After seekable range.
            self.handleSeekBeyondLivePoint(lastOffset: lastTimestamp, targetTime: timeInterval, timeInterval: timeInterval, for: player, in: context)
        }
    }
    
    /// Handles seeking beyond the live edge.
    ///
    /// This can be done both through zero-based offset and unix timestamp. Program based seek for static catchup requires a unix timestamp to work, and this should be supplied as the `timeInterval`. If the seek is done with zero-based offset the supplied `timeInterval` should mark the relative timestamp in unix time.
    ///
    /// - parameters:
    ///     - lastOffset: the last buffer offset (either zero based or unix timestamp), ie the live point.
    ///     - targetTime: the target offset, either zero based or unix timestamp, but it must match the scale supplied by `lastOffset`
    ///     - timeInterval: the target offset as a unix timestamp. This is needed to handle `ProgramService` based seek.
    ///     - player: The player
    ///     - context: The playback context
    fileprivate func handleSeekBeyondLivePoint(lastOffset: Int64, targetTime: Int64, timeInterval: Int64, for player: Player<HLSNative<ExposureContext>>, in context: ExposureContext) {
        // TODO: Check fragility of checking for `playbackType`
        if context.isDynamicManifest(player.tech, self) {
            // ProgreamSource is considered to be live which means seeking beyond the last seekable range would be impossible.
            //
            // We should give some "lee-way": ie if the `timeInterval` is `delta` more than the seekable range, we consider this a seek to the live point.
            //
            // Note: `delta` in this aspect is the *time behind live*
            let delta = player.liveDelay ?? 0
            if (targetTime - delta) <= lastOffset {
                self.handleGoLive(player: player, in: context)
            }
            else {
                let warning = PlayerWarning<HLSNative<ExposureContext>, ExposureContext>.tech(warning: .seekTimeBeyondLivePoint(timestamp: targetTime, livePoint: lastOffset))
                player.tech.eventDispatcher.onWarning(player.tech, player.tech.currentSource, warning)
                self.analyticsConnector.onWarning(tech: player.tech, source: self, warning: warning)
            }
        }
        else {
            // ProgramSource is considered static catchup.
            //
            // Seeking beyond the manifest should trigger an entitlement request
            player.handleProgramServiceBasedSeek(timestamp: timeInterval)
        }
    }
}

extension ProgramSource: ContextPositionSeekable {
    internal func handleSeek(toPosition position: Int64, for player: Player<HLSNative<ExposureContext>>, in context: ExposureContext) {
        // NOTE: ProgramSource playback can be either *dynamic catchup*, ie a growing manifest, or *static catchup*, ie a vod manifest
        handleSeek(toPosition: position, for: player, in: context) { [weak self] timeInterval, lastPosition in
            guard let `self` = self else { return }
            // After seekable range.
            self.handleSeekBeyondLivePoint(lastOffset: lastPosition, targetTime: position, timeInterval: timeInterval, for: player, in: context)
            
        }
    }
}

extension ProgramSource: ContextStartTime {
    func handleStartTime(for tech: HLSNative<ExposureContext>, in context: ExposureContext) -> StartOffset {
        switch context.playbackProperties.playFrom {
        case .defaultBehaviour:
            return defaultStartTime(for: tech, in: context)
        case .beginning:
            if isUnifiedPackager {
                // Start from  program start (using a t-param with stream start at program start)
                return .startPosition(position: ExposureSource.segmentLength)
            }
            else {
                // Relies on traditional vod manifest
                return .defaultStartTime
            }
        case .bookmark:
            // Use *EMP* supplied bookmark
            guard let offset = entitlement.lastViewedOffset else { return defaultStartTime(for: tech, in: context) }
            
            guard !tech.isExternalPlaybackActive else {
                // EMP-11129 We cant check for invalidStartTime on Airplay events since the seekable ranges are not loaded yet.
                return .startPosition(position: Int64(offset))
            }
            
            if check(offset: Int64(offset), inRanges: tech.seekableRanges) {
                // 0 based offset
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
            
            if check(offset: offset, inRanges: tech.seekableRanges) {
                return .startPosition(position: offset)
            }
            else {
                triggerInvalidStartTime(offset: offset, ranges: tech.seekableRanges, source: self, tech: tech)
                return defaultStartTime(for: tech, in: context)
            }
        case .customTime(timestamp: let offset):
            guard !tech.isExternalPlaybackActive else {
                // EMP-11129 We cant check for invalidStartTime on Airplay events since the seekable ranges are not loaded yet.
                return .startTime(time: offset)
            }
            
            // Use the custom supplied offset
            if check(offset: offset, inRanges: tech.seekableTimeRanges) {
                return .startTime(time: offset)
            }
            else {
                triggerInvalidStartTime(offset: offset, ranges: tech.seekableTimeRanges, source: self, tech: tech)
                return defaultStartTime(for: tech, in: context)
            }
        }
    }
    
    private func defaultStartTime(for tech: HLSNative<ExposureContext>, in context: ExposureContext) -> StartOffset {
        if isUnifiedPackager {
            if entitlement.live {
                // Start from the live edge (relying on live manifest)
                return .defaultStartTime
            }
            else {
                // Start from program start (using a t-param with stream start at program start)
                return .startPosition(position: ExposureSource.segmentLength)
            }
        }
        else {
            // Default is to start from program start (relying on traditional vod manifest)
            return .defaultStartTime
        }
    }
}

extension ProgramSource: ContextGoLive {
    internal func handleGoLive(player: Player<HLSNative<ExposureContext>>, in context: ExposureContext) {
        if context.isDynamicManifest(player.tech, self) {
            goToLiveDynamicManifest(player: player, in: context)
        }
        else {
            goToLiveStaticManifest(player: player, in: context)
        }
    }
}

extension ProgramSource: ProgramServiceEnabled {
    internal var programServiceChannelId: String {
        return channelId
    }
}

extension ProgramSource: HeartbeatsProvider {
    internal func heartbeat(for tech: HLSNative<ExposureContext>, in context: ExposureContext) -> Playback.Heartbeat {
        if isUnifiedPackager {
            return Playback.Heartbeat(timestamp: Date().millisecondsSince1970, offsetTime: tech.playheadTime ?? tech.playheadPosition)
        }
        else {
            return Playback.Heartbeat(timestamp: Date().millisecondsSince1970, offsetTime: tech.playheadPosition)
        }
    }
}
