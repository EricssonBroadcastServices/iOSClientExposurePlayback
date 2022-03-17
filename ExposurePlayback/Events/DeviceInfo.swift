//
//  DeviceInfo.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-16.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Exposure

/// The device info object should be sent once per playback session, preferably at the start of the session.
internal struct DeviceInfo {
    
    internal let timestamp: Int64
    
    /// Id string of the player/sdk.
    /// Example: EMP.tvOS2, EMP.iOS2
    internal var player: String {
        return "EMP." + UIDevice.mergedSystemName + "2"
    }
    
    /// Optional string indicating the nature of playback from this device
    ///
    /// Can be used to indicate this is an `Airplay` session
    internal let type: String?
    
    /// Indicates the connection type
    internal let connection: String
    
    /// Playback technology used
    internal let tech: String
    
    /// Version of the tech
    internal let techVersion: String
    
    internal var cdnInfo: CDNInfoFromEntitlement?
    
    internal var analyticsInfo: AnalyticsFromEntitlement?
    
    internal init(timestamp: Int64, connection: String, type: String? = nil, tech: String, techVersion: String,  cdnInfo: CDNInfoFromEntitlement? = nil , analyticsInfo: AnalyticsFromEntitlement? = nil) {
        self.timestamp = timestamp
        self.connection = connection
        self.type = type
        
        self.tech = tech
        self.techVersion = techVersion
        
        self.cdnInfo = cdnInfo
        self.analyticsInfo = analyticsInfo
    }
}

extension DeviceInfo: AnalyticsEvent {
    internal var eventType: String {
        return "Device.Info"
    }
    
    var bufferLimit: Int64 {
        return 3000
    }

    
    internal var jsonPayload: [String : Any] {
        
        let device: Device = Device()
        
        var params: [String: Any] = [
            JSONKeys.eventType.rawValue: eventType,
            JSONKeys.timestamp.rawValue: timestamp,
            
            JSONKeys.deviceId.rawValue: device.deviceId,
            JSONKeys.deviceModel.rawValue: device.model,
            JSONKeys.os.rawValue: device.os,
            JSONKeys.appType.rawValue: device.os,
            JSONKeys.osVersion.rawValue: device.osVersion,
            JSONKeys.manufacturer.rawValue: device.manufacturer,
            JSONKeys.connection.rawValue: connection,
            JSONKeys.tech.rawValue: tech,
            JSONKeys.techVersion.rawValue: techVersion,
            JSONKeys.player.rawValue: player,
        ]
        
        if let cpuType = device.cpuType {
            params[JSONKeys.cpuType.rawValue] = cpuType
        }
        
        if let value = type {
            params[JSONKeys.type.rawValue] = value
        }
        
        if let cdnInfo = cdnInfo {
            params[JSONKeys.CDNVendor.rawValue] = cdnInfo.provider
        }
        
        if let analyticsInfo = analyticsInfo {
            params[JSONKeys.bucket.rawValue] = analyticsInfo.bucket
            params[JSONKeys.postInterval.rawValue] = analyticsInfo.postInterval
            params[JSONKeys.tag.rawValue] = analyticsInfo.tag
        }
        
        params[JSONKeys.StreamingTechnology.rawValue] = "HLS"
        params[JSONKeys.userAgent.rawValue] = ""
        
       
        params[JSONKeys.height.rawValue] = device.height
        params[JSONKeys.width.rawValue] = device.width
        
        return params
    }
    
    internal enum JSONKeys: String {
        case eventType = "EventType"
        case timestamp = "Timestamp"
        case deviceId = "DeviceId"
        case deviceModel = "DeviceModel"
        case cpuType = "CPUType"
        case appType = "AppType"
        case os = "OS"
        case osVersion = "OSVersion"
        case manufacturer = "Manufacturer"
        case type = "Type"
        case connection = "Connection"
        case player = "Player"
        
        case tech = "Technology"
        case techVersion = "TechVersion"
        case userAgent = "UserAgent"
        
        case height = "Height"
        case width = "Width"
        
        // CDN
        case CDNVendor = "CDNVendor"
        
        // Analytics info from entitlement
        case bucket = "AnalyticsBucket"
        case postInterval = "AnalyticsPostInterval"
        case tag = "AnalyticsTag"
        
        case StreamingTechnology = "StreamingTechnology"
        
    }
}
