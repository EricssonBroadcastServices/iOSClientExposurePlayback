//
//  StartCasting.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-12-12.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Exposure

extension Playback {
    /// Player started ChromeCasting.
    internal struct StartCasting {
        internal let timestamp: Int64
        
        /// Offset in the video sequence where the playback was started at in milliseconds.
        internal let offsetTime: Int64?
        
        internal var cdnInfo: CDNInfoFromEntitlement?
        
        internal var analyticsInfo: AnalyticsFromEntitlement?
        
        internal init(timestamp: Int64, offsetTime: Int64?, cdnInfo: CDNInfoFromEntitlement? = nil , analyticsInfo: AnalyticsFromEntitlement? = nil) {
            self.timestamp = timestamp
            self.offsetTime = offsetTime
            
            self.cdnInfo = cdnInfo
            self.analyticsInfo = analyticsInfo
        }
    }
}

extension Playback.StartCasting: AnalyticsEvent {
    var eventType: String {
        return "Playback.StartCasting"
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
        
        if let cdnInfo = cdnInfo {
            json[JSONKeys.CDNVendor.rawValue] = cdnInfo.provider
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
        case offsetTime = "OffsetTime"
        
        // CDN
        case CDNVendor = "CDNVendor"
        
        // Analytics info from entitlement
        case bucket = "AnalyticsBucket"
        case postInterval = "AnalyticsPostInterval"
        case tag = "AnalyticsTag"
        
        case StreamingTechnology = "StreamingTechnology"
        
        case technology = "Technology"
        case techVersion = "TechVersion"
        case userAgent = "UserAgent"
        
        case height = "Height"
        case width = "Width"
    }
}

