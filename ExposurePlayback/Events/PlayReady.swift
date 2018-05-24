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
        internal let offsetTime: Int64
        
        internal let tech: String
        
        internal let techVersion: String
        
        internal init(timestamp: Int64, offsetTime: Int64, tech: String, techVersion: String) {
            self.timestamp = timestamp
            self.offsetTime = offsetTime
            self.tech = tech
            self.techVersion = techVersion
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
        return [
            JSONKeys.eventType.rawValue: eventType,
            JSONKeys.timestamp.rawValue: timestamp,
            JSONKeys.offsetTime.rawValue: offsetTime,
            JSONKeys.tech.rawValue: tech,
            JSONKeys.techVersion.rawValue: techVersion
        ]
    }
    
    internal enum JSONKeys: String {
        case eventType = "EventType"
        case timestamp = "Timestamp"
        case offsetTime = "OffsetTime"
        case tech = "Technology"
        case techVersion = "TechVersion"
    }
}
