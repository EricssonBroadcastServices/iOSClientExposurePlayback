//
//  BufferingStopped.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-17.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation

extension Playback {
    /// Playback resumed after the player has enough data buffered. 
    internal struct BufferingStopped {
        internal let timestamp: Int64
        
        /// Offset in the video sequence where the playback resumed after a buffering event.
        internal let offsetTime: Int64
        
        internal init(timestamp: Int64, offsetTime: Int64) {
            self.timestamp = timestamp
            self.offsetTime = offsetTime
        }
    }
}

extension Playback.BufferingStopped: PlaybackOffset { }
extension Playback.BufferingStopped: AnalyticsEvent {
    var eventType: String {
        return "Playback.BufferingStopped"
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

