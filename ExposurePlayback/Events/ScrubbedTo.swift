//
//  ScrubbedTo.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-17.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Exposure

extension Playback {
    /// Player has been instructed to scrub to a new position in the stream.
    internal struct ScrubbedTo: AnalyticsEvent {
        internal let bufferLimit: Int64 = 3000
        internal let timestamp: Int64
        internal let eventType: String = "Playback.ScrubbedTo"
        
        /// Offset in the video sequence where the player should start playing
        internal let offsetTime: Int64
        
        internal init(timestamp: Int64, offsetTime: Int64) {
            self.timestamp = timestamp
            self.offsetTime = offsetTime
        }
    }
}

extension Playback.ScrubbedTo: PlaybackOffset { }
extension Playback.ScrubbedTo {
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

