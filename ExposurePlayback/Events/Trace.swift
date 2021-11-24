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
        
        internal var cdnInfo: CDNInfoFromEntitlement?
        
        internal var analyticsInfo: AnalyticsFromEntitlement?
        
        
        internal init(timestamp: Int64, offsetTime: Int64? = nil, data: [String: Any], cdnInfo: CDNInfoFromEntitlement? = nil , analyticsInfo: AnalyticsFromEntitlement? = nil) {
            self.timestamp = timestamp
            self.offsetTime = offsetTime
            self.data = data
            
            self.cdnInfo = cdnInfo
            self.analyticsInfo = analyticsInfo
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
