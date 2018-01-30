//
//  Heartbeat.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-17.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation

extension Playback {
    /// Sent to tell the server that the client is still around, and the playback session is active. In case the server, based on lack of heartbeats, detects that a client has disappeared, it should issue a Playback.Aborted message to signal that the playback is not ongoing anymore. If there are other recent events sent by the player, there is no need to send the heartbeat in addition to them.
    internal struct Heartbeat {
        internal let timestamp: Int64
        
        internal let data: [String: Any]
        
        internal init(timestamp: Int64, data: [String: Any]) {
            self.timestamp = timestamp
            self.data = data
        }
    }
}

//extension Playback.Heartbeat: PlaybackOffset { }
extension Playback.Heartbeat: AnalyticsEvent {
    var eventType: String {
        return "Playback.Heartbeat"
    }
    
    internal var jsonPayload: [String : Any] {
        var payload = data
        payload[JSONKeys.eventType.rawValue] = eventType
        payload[JSONKeys.timestamp.rawValue] = timestamp
        return payload
    }
    
    internal enum JSONKeys: String {
        case eventType = "EventType"
        case timestamp = "Timestamp"
    }
}
