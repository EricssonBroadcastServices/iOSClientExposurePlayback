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
    /// Player has resumed playing the asset that was paused.
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
        
        internal init(timestamp: Int64, offsetTime: Int64?, tech: String, techVersion: String, segmentRequestId: String? = nil) {
            self.timestamp = timestamp
            self.offsetTime = offsetTime
            self.tech = tech
            self.techVersion = techVersion
            self.segmentRequestId = segmentRequestId
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
        
        return json
    }
    
    internal enum JSONKeys: String {
        case eventType = "EventType"
        case timestamp = "Timestamp"
        case offsetTime = "OffsetTime"
        case tech = "Technology"
        case techVersion = "TechVersion"
        case segmentRequestId = "X-Playback-Session-Id"
    }
}
