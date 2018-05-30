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
        internal let offsetTime: Int64?
        
        /// New bitrate, in kilobit/s
        internal let bitrate: Int64
        
        internal init(timestamp: Int64, offsetTime: Int64?, bitrate: Int64) {
            self.timestamp = timestamp
            self.offsetTime = offsetTime
            self.bitrate = bitrate
        }
    }
}

extension Playback.BitrateChanged: AnalyticsEvent {
    var eventType: String {
        return "Playback.BitrateChanged"
    }
    
    var bufferLimit: Int64 {
        return 3000
    }
    
    internal var jsonPayload: [String : Any] {
        var json: [String: Any] = [
            JSONKeys.eventType.rawValue: eventType,
            JSONKeys.bitrate.rawValue: bitrate
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
        case bitrate = "Bitrate"
    }
}
