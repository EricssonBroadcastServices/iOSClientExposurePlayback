//
//  Trace.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-05-21.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Exposure

extension Playback {
    /// Trace information data
    internal struct Trace {
        internal let timestamp: Int64
        
        /// Offset in the video sequence where the trace was generated
        internal let offsetTime: Int64?
        
        /// JSON formatted data to deliver
        internal let data: [String: Any]
        
        
        internal init(timestamp: Int64, offsetTime: Int64?, data: [String: Any]) {
            self.timestamp = timestamp
            self.offsetTime = offsetTime
            self.data = data
        }
    }
}

extension Playback.Trace: AnalyticsEvent {
    var eventType: String {
        return "Playback.Trace"
    }
    
    var bufferLimit: Int64 {
        return 3000
    }
    
    internal var jsonPayload: [String : Any] {
        var json: [String: Any] = data
        
        json[JSONKeys.eventType.rawValue] = eventType
        json[JSONKeys.timestamp.rawValue] = timestamp
        
        if let offset = offsetTime {
            json[JSONKeys.offsetTime.rawValue] = offset
        }
        
        return json
    }
    
    internal enum JSONKeys: String {
        case eventType = "EventType"
        case timestamp = "Timestamp"
        case offsetTime = "OffsetTime"
    }
}
