//
//  Created.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-16.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Exposure

extension Playback {
    /// This event is sent when the player is instantiated, or invoked for the first time during the playback session.
    internal struct Created {
        internal let timestamp: Int64
        
        /// Id string of the player/sdk.
        /// Example: EMP.tvOS2, EMP.iOS2
        internal var player: String {
            return "EMP." + UIDevice.mergedSystemName + "2"
        }
        
        /// Release version and build revision of ExposurePlayback
        /// Example: 1.34.0
        internal let version: String
        
        /// Exposure framework version information
        internal let exposureVersion: String?
        
        /// If true, the player will start playing as soon as possible. If false, player does not start playing, and will be initialized at a later time. If this field is missing, it is assumed to have the value "true".
        internal let autoPlay: Bool?
        
        /// One of the following: vod, live, offline
        internal var playMode: String? {
            guard let data = assetData else { return nil }
            switch data {
            case .vod(assetId: _): return "vod"
            case .live(channelId: _): return "live"
            case .program(programId: _, channelId: _): return "vod"
            case .offline(assetId: _): return "offline"
            case .download(assetId: _): return "vod"
            }
        }
        
        internal let assetData: PlaybackIdentifier?
        
        /// Identity of the media the player should play. This should be the media locator as received from the call to the entitlement service. This is a string of proprietary format that corresponds to the MRR Media ID if applicable, but can contain implementation specific strings for other streaming formats.
        /// Example: 1458209835_fai-hls_IkCMxd
        internal let mediaId: String?
        
        internal init(timestamp: Int64, version: String, exposureVersion: String? = nil, assetData: PlaybackIdentifier? = nil, mediaId: String? = nil, autoPlay: Bool? = nil) {
            self.timestamp = timestamp
            self.version = version
            self.exposureVersion = exposureVersion
            self.assetData = assetData
            self.mediaId = mediaId
            self.autoPlay = autoPlay
        }
    }
}

extension Playback.Created: AssetIdentifier { }

extension Playback.Created: AnalyticsEvent {
    internal var eventType: String {
        return "Playback.Created"
    }
    
    var bufferLimit: Int64 {
        return 3000
    }
    
    internal var jsonPayload: [String : Any] {
        var params: [String: Any] = [
            JSONKeys.eventType.rawValue: eventType,
            JSONKeys.player.rawValue: player,
            JSONKeys.version.rawValue: version
        ]
        
        if timestamp > 0 {
            params[JSONKeys.timestamp.rawValue] = timestamp
        }
        
        if let exposureVersion = exposureVersion {
            params[JSONKeys.exposureVersion.rawValue] = exposureVersion
        }
        
        if let autoPlay = autoPlay {
            params[JSONKeys.autoPlay.rawValue] = autoPlay
        }
        
        if let playMode = playMode {
            params[JSONKeys.playMode.rawValue] = playMode
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
        
        if let mediaId = mediaId {
            params[JSONKeys.mediaId.rawValue] = mediaId
        }
        
        return params
    }
    
    internal enum JSONKeys: String {
        case eventType = "EventType"
        case timestamp = "Timestamp"
        case player = "Player"
        case version = "Version"
        case exposureVersion = "ExposureVersion"
        case autoPlay = "AutoPlay"
        case playMode = "PlayMode"
        case assetId = "AssetId"
        case channelId = "ChannelId"
        case programId = "ProgramId"
        case mediaId = "MediaId"
    }
}

