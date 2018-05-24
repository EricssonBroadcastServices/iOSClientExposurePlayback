//
//  StartCasting.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-12-12.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Exposure

extension Playback {
    /// Player started ChromeCasting.
    internal struct StartCasting {
        internal let timestamp: Int64
        
        /// Offset in the video sequence where the playback was started at in milliseconds.
        internal let offsetTime: Int64?
        
        internal init(timestamp: Int64, offsetTime: Int64?) {
            self.timestamp = timestamp
            self.offsetTime = offsetTime
        }
    }
}

extension Playback.StartCasting: AnalyticsEvent {
    var eventType: String {
        return "Playback.StartCasting"
    }
    
    var bufferLimit: Int64 {
        return 3000
    }
    
    internal var jsonPayload: [String : Any] {
        var json: [String: Any] = [
            JSONKeys.eventType.rawValue: eventType,
            JSONKeys.timestamp.rawValue: timestamp
        ]
        
        if let value = offsetTime {
            json[JSONKeys.offsetTime.rawValue] = value
        }
        
        return json
    }
    
    internal enum JSONKeys: String {
        case eventType = "EventType"
        case timestamp = "Timestamp"
        case offsetTime = "OffsetTime"
    }
}

