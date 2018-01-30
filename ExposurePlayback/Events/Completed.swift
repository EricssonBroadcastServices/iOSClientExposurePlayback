//
//  Completed.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-17.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation

extension Playback {
    /// Playback stopped because it reached the end of the asset. If playback stopped due to user intervention or errors, a Playback.Aborted or Playback.Error should be sent instead.
    internal struct Completed {
        internal let timestamp: Int64
        
        /// Offset in the video sequence where the playback was stopped. This would typically be equal to the length of the asset in milliseconds.
        internal let offsetTime: Int64
        
        internal init(timestamp: Int64, offsetTime: Int64) {
            self.timestamp = timestamp
            self.offsetTime = offsetTime
        }
    }
}

extension Playback.Completed: PlaybackOffset { }
extension Playback.Completed: AnalyticsEvent {
    var eventType: String {
        return "Playback.Completed"
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

