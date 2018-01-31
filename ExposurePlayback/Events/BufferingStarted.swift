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
        internal let offsetTime: Int64
        
        internal init(timestamp: Int64, offsetTime: Int64) {
            self.timestamp = timestamp
            self.offsetTime = offsetTime
        }
    }
}


extension Playback.BufferingStarted: PlaybackOffset { }
extension Playback.BufferingStarted: AnalyticsEvent {
    var eventType: String {
        return "Playback.BufferingStarted"
    }
    
    var bufferLimit: Int64 {
        return 3000
    }
    
    internal var jsonPayload: [String : Any] {
        return [
            JSONKeys.eventType.rawValue: eventType,
            JSONKeys.timestamp.rawValue: timestamp,
            JSONKeys.offsetTime.rawValue: offsetTime
        ]
    }
    
    internal enum JSONKeys: String {
        case eventType = "EventType"
        case timestamp = "Timestamp"
        case offsetTime = "OffsetTime"
    }
}

