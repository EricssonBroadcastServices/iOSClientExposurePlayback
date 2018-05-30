//
//  InitCompleted.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-21.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Exposure

extension Playback {
    /// Player has resumed playing the asset that was paused.
    internal struct InitCompleted {
        internal let timestamp: Int64
        
        internal init(timestamp: Int64) {
            self.timestamp = timestamp
        }
    }
}

extension Playback.InitCompleted: AnalyticsEvent {
    var eventType: String {
        return "Playback.InitCompleted"
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
        
        return json
    }
    
    internal enum JSONKeys: String {
        case eventType = "EventType"
        case timestamp = "Timestamp"
    }
}

