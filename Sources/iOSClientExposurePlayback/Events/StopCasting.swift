//
//  StopCasting.swift
//  iOSClientExposurePlayback
//
//  Created by Udaya Sri Senarathne on 2022-05-11.
//  Copyright © 2022 emp. All rights reserved.
//

import Foundation
import iOSClientExposure
import UIKit

extension Playback {
    /// Player stopped ChromeCasting.
    internal struct StopCasting {
        
        /// Id string of the player/sdk.
        /// Example: EMP.tvOS2, EMP.iOS2
        internal var player: String {
            return "EMP." + UIDevice.mergedSystemName + "2"
        }
        
        internal let timestamp: Int64
        
        /// Offset in the video sequence where the playback was stopped casting at in milliseconds.
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

extension Playback.StopCasting: AnalyticsEvent {
    var eventType: String {
        return "Playback.StopCasting"
    }
    
    var bufferLimit: Int64 {
        return 3000
    }
    
    internal var jsonPayload: [String : Any] {
        
        let device: Device = Device()
        var json: [String: Any] = [
            JSONKeys.eventType.rawValue: eventType,
            JSONKeys.timestamp.rawValue: timestamp,
            
            JSONKeys.deviceId.rawValue: device.deviceId,
            JSONKeys.deviceModel.rawValue: device.model,
            JSONKeys.os.rawValue: device.os,
            JSONKeys.appType.rawValue: "app",
            JSONKeys.osVersion.rawValue: device.osVersion,
            JSONKeys.manufacturer.rawValue: device.manufacturer,
            JSONKeys.height.rawValue: device.height,
            JSONKeys.width.rawValue: device.width
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
        
        
        return json
    }
    
    internal enum JSONKeys: String {
        case eventType = "EventType"
        case timestamp = "Timestamp"
        case offsetTime = "OffsetTime"
        case player = "Player"
        
        // Device Info
        case deviceId = "DeviceId"
        case deviceModel = "DeviceModel"
        case cpuType = "CPUType"
        case appType = "AppType"
        case os = "OS"
        case osVersion = "OSVersion"
        case manufacturer = "Manufacturer"
        case type = "Type"
        case height = "Height"
        case width = "Width"
        
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
        
    }
}

