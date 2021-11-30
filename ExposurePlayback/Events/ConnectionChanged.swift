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
        
        internal var cdnInfo: CDNInfoFromEntitlement?
        internal var analyticsInfo: AnalyticsFromEntitlement?
        
        internal init(timestamp: Int64, connection: String, offsetTime: Int64?, cdnInfo: CDNInfoFromEntitlement? = nil , analyticsInfo: AnalyticsFromEntitlement? = nil) {
            self.timestamp = timestamp
            self.connection = connection
            self.offsetTime = offsetTime
            
            self.cdnInfo = cdnInfo
            self.analyticsInfo = analyticsInfo
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
        
        if let cdnInfo = cdnInfo {
            json[JSONKeys.profile.rawValue] = cdnInfo.profile
            json[JSONKeys.host.rawValue] = cdnInfo.host
            json[JSONKeys.provider.rawValue] = cdnInfo.provider
        }
        
        if let analyticsInfo = analyticsInfo {
            json[JSONKeys.bucket.rawValue] = analyticsInfo.bucket
            json[JSONKeys.postInterval.rawValue] = analyticsInfo.postInterval
            json[JSONKeys.tag.rawValue] = analyticsInfo.tag
        }
        
        json[JSONKeys.StreamingTechnology.rawValue] = "HLS"
        
        json[JSONKeys.technology.rawValue] = "HLS"
        json[JSONKeys.techVersion.rawValue] = ""
        json[JSONKeys.userAgent.rawValue] = ""
        
        let device: Device = Device()
        json[JSONKeys.height.rawValue] = device.height
        json[JSONKeys.width.rawValue] = device.width
        
        return json
    }
    
    internal enum JSONKeys: String {
        case eventType = "EventType"
        case timestamp = "Timestamp"
        case connection = "Connection"
        case offsetTime = "OffsetTime"
        
        // CDN
        case profile = "profile"
        case host = "host"
        case provider = "provider"
        
        // Analytics info from entitlement
        case bucket = "bucket"
        case postInterval = "postInterval"
        case tag = "tag"
        
        case StreamingTechnology = "StreamingTechnology"
        
        case technology = "Technology"
        case techVersion = "TechVersion"
        case userAgent = "UserAgent"
        
        case height = "Height"
        case width = "Width"
    }
}
