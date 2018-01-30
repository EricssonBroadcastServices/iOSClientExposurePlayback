//
//  BitrateChanged.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-17.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Exposure

extension Playback {
    /// Playback switched to a different bitrate.
    internal struct BitrateChanged {
        internal let timestamp: Int64
        
        /// Offset in the video sequence where the playback switched to a different bitrate
        internal let offsetTime: Int64
        
        /// New bitrate, in kilobit/s
        internal let bitrate: Int64
        
        internal init(timestamp: Int64, offsetTime: Int64, bitrate: Int64) {
            self.timestamp = timestamp
            self.offsetTime = offsetTime
            self.bitrate = bitrate
        }
    }
}


extension Playback.BitrateChanged: PlaybackOffset { }
extension Playback.BitrateChanged: AnalyticsEvent {
    var eventType: String {
        return "Playback.BitrateChanged"
    }
    
    internal var jsonPayload: [String : Any] {
        return [
            JSONKeys.eventType.rawValue: eventType,
            JSONKeys.timestamp.rawValue: timestamp,
            JSONKeys.offsetTime.rawValue: offsetTime,
            JSONKeys.bitrate.rawValue: bitrate
        ]
    }
    
    internal enum JSONKeys: String {
        case eventType = "EventType"
        case timestamp = "Timestamp"
        case offsetTime = "OffsetTime"
        case bitrate = "Bitrate"
    }
}
