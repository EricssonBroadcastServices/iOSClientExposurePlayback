//
//  Paused.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-17.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation

extension Playback {
    /// Playback has temporarily stopped, but the playback session is still active. It is assumed that the video was paused due to user intervention. If the pausing was caused by a buffer underrun, the Playback.BufferingStarted event should be used instead.
    internal struct Paused {
        internal let timestamp: Int64
        
        /// Offset in the video sequence (in milliseconds) where playback paused. For vod or offline viewing, this is the offset from the start of the asset, and for live, this is measured from the start of the program according to the EPG.
        internal let offsetTime: Int64
        
        internal init(timestamp: Int64, offsetTime: Int64) {
            self.timestamp = timestamp
            self.offsetTime = offsetTime
        }
    }
}

extension Playback.Paused: PlaybackOffset { }
extension Playback.Paused: AnalyticsEvent {
    var eventType: String {
        return "Playback.Paused"
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

