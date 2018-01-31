//
//  ProgramChanged.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-17.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Exposure

extension Playback {
    internal struct ProgramChanged {
        internal let timestamp: Int64
        
        /// Offset in the video sequence where the player was at the time the event was emitted
        internal let offsetTime: Int64
        
        /// Identifier of the new program that just started, as specified in the EPG.
        /// Example: 1458835_IkCMxd
        let programId: String
        
        /// Length in milliseconds of this program, according to the EPG
        let videoLength: Int64?
        
        internal init(timestamp: Int64, offsetTime: Int64, programId: String, videoLength: Int64? = nil) {
            self.timestamp = timestamp
            self.offsetTime = offsetTime
            self.programId = programId
            self.videoLength = videoLength
        }
    }
}

extension Playback.ProgramChanged: AnalyticsEvent {
    var eventType: String {
        return "Playback.ProgramChanged"
    }
    
    internal var jsonPayload: [String : Any] {
        var params: [String: Any] = [
            JSONKeys.eventType.rawValue: eventType,
            JSONKeys.timestamp.rawValue: timestamp,
            JSONKeys.offsetTime.rawValue: offsetTime,
            JSONKeys.programId.rawValue: programId
        ]
        
        if let videoLength = videoLength {
            params[JSONKeys.videoLength.rawValue] = videoLength
        }
        
        return params
    }
    
    internal enum JSONKeys: String {
        case eventType = "EventType"
        case timestamp = "Timestamp"
        case offsetTime = "OffsetTime"
        case programId = "ProgramId"
        case videoLength = "VideoLength"
    }
}

extension Playback.ProgramChanged: PlaybackOffset { }

