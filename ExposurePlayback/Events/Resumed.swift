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
    internal struct Resumed {
        internal let timestamp: Int64
        
        /// Offset in the video sequence (in milliseconds) where video started playing again. For vod or offline viewing, this is the offset from the start of the asset, and for live, this is measured from the start of the program according to the EPG.
        internal let offsetTime: Int64?
        
        internal init(timestamp: Int64, offsetTime: Int64?) {
            self.timestamp = timestamp
            self.offsetTime = offsetTime
        }
    }
}

extension Playback.Resumed: AnalyticsEvent {
    var eventType: String {
        return "Playback.Resumed"
    }
    
    var bufferLimit: Int64 {
        return 3000
    }
    
    internal var jsonPayload: [String : Any] {
        var json: [String: Any] = [
            JSONKeys.eventType.rawValue: eventType,
            JSONKeys.timestamp.rawValue: timestamp
        ]
        
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

