//
//  Heartbeat.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-17.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Exposure

extension Playback {
    /// Sent to tell the server that the client is still around, and the playback session is active. In case the server, based on lack of heartbeats, detects that a client has disappeared, it should issue a Playback.Aborted message to signal that the playback is not ongoing anymore. If there are other recent events sent by the player, there is no need to send the heartbeat in addition to them.
    internal struct Heartbeat {
        internal let timestamp: Int64
        
        /// Offset in the video sequence where the playback was started at in milliseconds.
        internal let offsetTime: Int64?
        
        internal init(timestamp: Int64, offsetTime: Int64?) {
            self.timestamp = timestamp
            self.offsetTime = offsetTime
        }
        
        /// There is no need to store Heartbeats on dispatch failure
        internal var storeOnDispatchFailure: Bool {
            return false
        }
    }
}

extension Playback.Heartbeat: AnalyticsEvent {
    var eventType: String {
        return "Playback.Heartbeat"
    }
    
    var bufferLimit: Int64 {
        return 3000
    }
    
    internal var jsonPayload: [String : Any] {
        var json: [String: Any] = [
            JSONKeys.eventType.rawValue: eventType
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
    }
}
