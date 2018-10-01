//
//  ConnectionChanged.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-09-28.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Exposure

extension Playback {
    /// Connecton changed event
    internal struct ConnectionChanged {
        internal let timestamp: Int64
        
        /// The connection type
        internal let connection: String
        
        /// Offset in the video sequence where the playback stopped due to buffer underrun.
        internal let offsetTime: Int64?
        
        internal init(timestamp: Int64, connection: String, offsetTime: Int64?) {
            self.timestamp = timestamp
            self.connection = connection
            self.offsetTime = offsetTime
        }
    }
}

extension Playback.ConnectionChanged: AnalyticsEvent {
    var eventType: String {
        return "Playback.ConnectionChanged"
    }
    
    var bufferLimit: Int64 {
        return 3000
    }
    
    internal var jsonPayload: [String : Any] {
        var json: [String: Any] = [
            JSONKeys.eventType.rawValue: eventType,
            JSONKeys.timestamp.rawValue: timestamp,
            JSONKeys.connection.rawValue: connection
        ]
        
        if let value = offsetTime {
            json[JSONKeys.offsetTime.rawValue] = value
        }
        
        return json
    }
    
    internal enum JSONKeys: String {
        case eventType = "EventType"
        case timestamp = "Timestamp"
        case connection = "Connection"
        case offsetTime = "OffsetTime"
    }
}
