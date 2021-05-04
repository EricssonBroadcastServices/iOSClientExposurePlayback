//
//  HandshakeStarted.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-17.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Exposure

extension Playback {
    /// If the player was created but not supposed to automatically play the asset as soon as possible, the HandshakeStarted event indicates that the player is preparing for playback now.
    internal struct HandshakeStarted {
        internal let timestamp: Int64
        
        internal let assetData: PlaybackIdentifier?
        
        internal let cdnInfo: CDNInfoFromEntitlement?
        
        internal let analyticsInfo: AnalyticsFromEntitlement?
        
        internal init(timestamp: Int64, assetData: PlaybackIdentifier? = nil, cdnInfo: CDNInfoFromEntitlement? = nil , analyticsInfo: AnalyticsFromEntitlement? = nil) {
            self.timestamp = timestamp
            self.assetData = assetData
            
            self.cdnInfo = cdnInfo
            self.analyticsInfo = analyticsInfo
        }
    }
}

extension Playback.HandshakeStarted: AssetIdentifier {
    
}

extension Playback.HandshakeStarted: AnalyticsEvent {
    var eventType: String {
        return "Playback.HandshakeStarted"
    }
    
    var bufferLimit: Int64 {
        return 3000
    }
    
    
    internal var jsonPayload: [String : Any] {
        var params: [String: Any] = [
            JSONKeys.eventType.rawValue: eventType,
            JSONKeys.timestamp.rawValue: timestamp
        ]
        
        if let assetId = assetId {
            params[JSONKeys.assetId.rawValue] = assetId
        }
        
        if let channelId = channelId {
            params[JSONKeys.channelId.rawValue] = channelId
        }
        
        if let programId = programId {
            params[JSONKeys.programId.rawValue] = programId
        }
        
        if let cdnInfo = cdnInfo {
            params[JSONKeys.profile.rawValue] = cdnInfo.profile
            params[JSONKeys.host.rawValue] = cdnInfo.host
            params[JSONKeys.provider.rawValue] = cdnInfo.provider
        }
        
        if let analyticsInfo = analyticsInfo {
            params[JSONKeys.bucket.rawValue] = analyticsInfo.bucket
            params[JSONKeys.postInterval.rawValue] = analyticsInfo.postInterval
            params[JSONKeys.tag.rawValue] = analyticsInfo.tag
        }
        
        params[JSONKeys.StreamingTechnology.rawValue] = "HLS"
        
        return params
    }
    
    internal enum JSONKeys: String {
        case eventType = "EventType"
        case timestamp = "Timestamp"
        case assetId = "AssetId"
        case channelId = "ChannelId"
        case programId = "ProgramId"
        
        // CDN
        case profile = "profile"
        case host = "host"
        case provider = "provider"
        
        // Analytics info from entitlement
        case bucket = "bucket"
        case postInterval = "postInterval"
        case tag = "tag"
        
        case StreamingTechnology = "StreamingTechnology"
    }
}

