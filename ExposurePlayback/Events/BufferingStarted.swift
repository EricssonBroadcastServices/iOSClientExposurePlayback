//
//  BufferingStarted.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-17.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Exposure

extension Playback {
    /// Playback paused temporarily as the player ran out of data to show.
    internal struct BufferingStarted {
        internal let timestamp: Int64
        
        /// Offset in the video sequence where the playback stopped due to buffer underrun.
        internal let offsetTime: Int64?
        
        internal init(timestamp: Int64, offsetTime: Int64?) {
            self.timestamp = timestamp
            self.offsetTime = offsetTime
        }
    }
}

extension Playback.BufferingStarted: AnalyticsEvent {
    var eventType: String {
        return "Playback.BufferingStarted"
    }
    
    var bufferLimit: Int64 {
        return 3000
    }
    
    internal var jsonPayload: [String : Any] {
        var json: [String: Any] = [
            JSONKeys.eventType.rawValue: eventType
        ]
        
        if timestamp > 0 {
            json[JSONKeys.timestamp.rawValue] = timestamp
        }
        
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

