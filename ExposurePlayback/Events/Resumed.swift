//
//  Resumed.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-17.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Exposure

extension Playback {
    /// Player has resumed playing the asset that was paused.
    internal struct Resumed: AnalyticsEvent {
        internal let eventType: String = "Playback.Resumed"
        internal let bufferLimit: Int64 = 3000
        internal let timestamp: Int64
        
        /// Offset in the video sequence (in milliseconds) where video started playing again. For vod or offline viewing, this is the offset from the start of the asset, and for live, this is measured from the start of the program according to the EPG.
        internal let offsetTime: Int64
        
        internal init(timestamp: Int64, offsetTime: Int64) {
            self.timestamp = timestamp
            self.offsetTime = offsetTime
        }
    }
}

extension Playback.Resumed: PlaybackOffset { }
extension Playback.Resumed {
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

