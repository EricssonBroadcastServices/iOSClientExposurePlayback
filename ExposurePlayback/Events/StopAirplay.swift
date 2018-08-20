//
//  StopAirplay.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-08-16.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Exposure

extension Playback {
    /// Player started ChromeCasting.
    internal struct StopAirplay {
        internal let timestamp: Int64
        
        /// Offset in the video sequence where the playback was started at in milliseconds.
        internal let offsetTime: Int64?
        
        internal init(timestamp: Int64, offsetTime: Int64?) {
            self.timestamp = timestamp
            self.offsetTime = offsetTime
        }
    }
}

extension Playback.StopAirplay: AnalyticsEvent {
    var eventType: String {
        return "Playback.StopAirplay"
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

