//
//  PlayReady.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-21.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Exposure

extension Playback {
    /// AV player is ready to play the asset
    internal struct PlayReady {
        internal let timestamp: Int64
        
        /// Offset in the video sequence where the playback was started at in milliseconds.
        internal let offsetTime: Int64?
        
        /// Playback technology used
        internal let tech: String
        
        /// Version of the tech
        internal let techVersion: String
        
        /// `X-Playback-Session-Id` used to track segment and manifest requests
        internal let segmentRequestId: String?
        
        internal let cdnInfo: CDNInfoFromEntitlement?
        
        internal let analyticsInfo: AnalyticsFromEntitlement?
        
        internal init(timestamp: Int64, offsetTime: Int64?, tech: String, techVersion: String, segmentRequestId: String? = nil, cdnInfo: CDNInfoFromEntitlement? = nil , analyticsInfo: AnalyticsFromEntitlement? = nil) {
            self.timestamp = timestamp
            self.offsetTime = offsetTime
            self.tech = tech
            self.techVersion = techVersion
            self.segmentRequestId = segmentRequestId
            self.cdnInfo = cdnInfo
            self.analyticsInfo = analyticsInfo
        }
    }
}

extension Playback.PlayReady: AnalyticsEvent {
    var eventType: String {
        return "Playback.PlayerReady"
    }
    
    var bufferLimit: Int64 {
        return 3000
    }
    
    internal var jsonPayload: [String : Any] {
        var json: [String: Any] = [
            JSONKeys.eventType.rawValue: eventType,
            JSONKeys.timestamp.rawValue: timestamp,
            JSONKeys.tech.rawValue: tech,
            JSONKeys.techVersion.rawValue: techVersion
        ]
        
        if let value = offsetTime {
            json[JSONKeys.offsetTime.rawValue] = value
        }
        
        if let value = segmentRequestId {
            json[JSONKeys.segmentRequestId.rawValue] = value
        }
        
        if let cdnInfo = cdnInfo {
            json[JSONKeys.profile.rawValue] = cdnInfo.profile
            json[JSONKeys.host.rawValue] = cdnInfo.host
            json[JSONKeys.provider.rawValue] = cdnInfo.provider
        }
        
        if let analyticsInfo = analyticsInfo {
            json[JSONKeys.bucket.rawValue] = analyticsInfo.bucket
            json[JSONKeys.postInterval.rawValue] = analyticsInfo.postInterval
            json[JSONKeys.tag.rawValue] = analyticsInfo.tag
        }
        
        json[JSONKeys.StreamingTechnology.rawValue] = "HLS"
        
        return json
    }
    
    internal enum JSONKeys: String {
        case eventType = "EventType"
        case timestamp = "Timestamp"
        case offsetTime = "OffsetTime"
        case tech = "Technology"
        case techVersion = "TechVersion"
        case segmentRequestId = "X-Playback-Session-Id"
        
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
