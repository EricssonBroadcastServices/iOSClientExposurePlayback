//
//  Started.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-17.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Exposure

extension Playback {
    /// Signals that the player has successfully started playback of the asset/channel.
    internal struct Started {
        let timestamp: Int64
        
        /// One of the following: vod, live, offline
        internal var playMode: String {
            switch requiredAssetData {
            case .vod(assetId: _): return "vod"
            case .live(channelId: _): return "live"
            case .program(programId: _, channelId: _): return "vod"
            case .offline(assetId: _): return "offline"
            case .download(assetId: _): return "vod"
            }
        }
        
        internal var assetData: PlaybackIdentifier? {
            return requiredAssetData
        }
        internal let requiredAssetData: PlaybackIdentifier
        
        /// This should be the media locator as received from the call to the entitlement service.
        internal let mediaLocator: String
        
        /// Offset in the video sequence (in milliseconds) where playback started. For playback of live streams, this is the offset from the start of the current program. Even if the player does not support millisecond precision, the offset should still be reported in milliseconds (rather than seconds).
        internal let offsetTime: Int64?
        
        /// Length of the vod asset or the live TV show. In milliseconds.
        internal let videoLength: Int64?
        
        /// Initial playback bitrate, measured in kbit/s.
        internal let bitrate: Int64?
        
        internal let referenceTime: Int64?
        
        internal init(timestamp: Int64, assetData: PlaybackIdentifier, mediaLocator: String, offsetTime: Int64?, videoLength: Int64? = nil, bitrate: Int64? = nil, referenceTime: Int64? = nil) {
            self.timestamp = timestamp
            self.requiredAssetData = assetData
            self.mediaLocator = mediaLocator
            self.offsetTime = offsetTime
            self.videoLength = videoLength
            self.bitrate = bitrate
            self.referenceTime = referenceTime
        }
    }
}

extension Playback.Started: AssetIdentifier { }
extension Playback.Started: AnalyticsEvent {
    var eventType: String {
        return "Playback.Started"
    }
    
    var bufferLimit: Int64 {
        return 3000
    }
    
    internal var jsonPayload: [String : Any] {
        var params: [String: Any] = [
            JSONKeys.eventType.rawValue: eventType,
            JSONKeys.timestamp.rawValue: timestamp,
            JSONKeys.playMode.rawValue: playMode,
            JSONKeys.mediaLocator.rawValue: mediaLocator
        ]
        
        if let value = offsetTime {
            params[JSONKeys.offsetTime.rawValue] = value
        }
        
        if let assetId = assetId {
            params[JSONKeys.assetId.rawValue] = assetId
        }
        
        if let channelId = channelId {
            params[JSONKeys.channelId.rawValue] = channelId
        }
        
        if let programId = programId {
            params[JSONKeys.programId.rawValue] = programId
        }
        
        if let videoLength = videoLength {
            params[JSONKeys.videoLength.rawValue] = videoLength
        }
        
        if let bitrate = bitrate {
            params[JSONKeys.bitrate.rawValue] = bitrate
        }
        
        if let referenceTime = referenceTime {
            params[JSONKeys.referenceTime.rawValue] = referenceTime
        }
        
        return params
    }
    
    internal enum JSONKeys: String {
        case eventType = "EventType"
        case timestamp = "Timestamp"
        case playMode = "PlayMode"
        case mediaLocator = "MediaLocator"
        case assetId = "AssetId"
        case channelId = "ChannelId"
        case programId = "ProgramId"
        case offsetTime = "OffsetTime"
        case videoLength = "VideoLength"
        case bitrate = "Bitrate"
        case referenceTime = "ReferenceTime"
    }
}

