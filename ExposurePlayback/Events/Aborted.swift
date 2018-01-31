//
//  Aborted.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-17.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Exposure

extension Playback {
    /// Playback stopped because of user intervention.
    internal struct Aborted: AnalyticsEvent {
        internal let eventType: String = "Playback.Aborted"
        internal let bufferLimit: Int64 = 3000
        internal let timestamp: Int64
        
        /// Offset in the video sequence where the playback was aborted.
        internal let offsetTime: Int64
        
        internal init(timestamp: Int64, offsetTime: Int64) {
            self.timestamp = timestamp
            self.offsetTime = offsetTime
        }
    }
}

extension Playback.Aborted: PlaybackOffset { }
extension Playback.Aborted {
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
