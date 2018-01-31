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
    internal struct Heartbeat: AnalyticsEvent {
        internal let eventType: String = "Playback.Heartbeat"
        internal let bufferLimit: Int64 = 3000
        internal let timestamp: Int64
        
        /// Offset in the video sequence where the playback was started at in milliseconds.
        internal let offsetTime: Int64
        
        internal init(timestamp: Int64, offsetTime: Int64) {
            self.timestamp = timestamp
            self.offsetTime = offsetTime
        }
    }
}

extension Playback.Heartbeat: PlaybackOffset { }
extension Playback.Heartbeat {
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
