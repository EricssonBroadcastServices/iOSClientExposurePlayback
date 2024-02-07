//
//  DrmEvent.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-08-02.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import iOSClientExposure
import UIKit

extension Playback {
    /// Trace information data
    internal struct DRM {
        
        /// Id string of the player/sdk.
        /// Example: EMP.tvOS2, EMP.iOS2
        internal var player: String {
            return "EMP." + UIDevice.mergedSystemName + "2"
        }
        
        internal let timestamp: Int64
        
        /// Human readable error message
        internal let message: Message
        
        /// Optional code desrcibing the message
        internal let code: Int?
        
        /// Additional detailed information
        internal let info: String?
        
        internal var cdnInfo: CDNInfoFromEntitlement?
        
        internal var analyticsInfo: AnalyticsFromEntitlement?
        
        internal init(timestamp: Int64, message: Message, code: Int? = nil, info: String? = nil, cdnInfo: CDNInfoFromEntitlement? = nil , analyticsInfo: AnalyticsFromEntitlement? = nil) {
            self.timestamp = timestamp
            self.message = message
            self.code = code
            self.info = info
            
            self.cdnInfo = cdnInfo
            self.analyticsInfo = analyticsInfo
        }
        
        internal enum Message: String {
            case certificateRequest = "FAIRPLAY_CERTIFICATE_REQUEST"
            case certificateResponse = "FAIRPLAY_CERTIFICATE_RESPONSE"
            case certificateError = "FAIRPLAY_CERTIFICATE_ERROR"
            case licenseRequest = "FAIRPLAY_LICENSE_REQUEST"
            case licenseResponse = "FAIRPLAY_LICENSE_RESPONSE"
            case licenseError = "FAIRPLAY_LICENSE_ERROR"
        }
    }
}

extension Playback.DRM: AnalyticsEvent {
    var eventType: String {
        return "Playback.DRM"
    }
    
    var bufferLimit: Int64 {
        return 3000
    }
    
    internal var jsonPayload: [String : Any] {
        
        let device: Device = Device()
        var json: [String: Any] = [
            JSONKeys.eventType.rawValue: eventType,
            JSONKeys.timestamp.rawValue: timestamp,
            JSONKeys.message.rawValue: message.rawValue,
            JSONKeys.player.rawValue: player,
            
            JSONKeys.deviceId.rawValue: device.deviceId,
            JSONKeys.deviceModel.rawValue: device.model,
            JSONKeys.os.rawValue: device.os,
            JSONKeys.appType.rawValue: "app",
            JSONKeys.osVersion.rawValue: device.osVersion,
            JSONKeys.manufacturer.rawValue: device.manufacturer,
            JSONKeys.height.rawValue: device.height,
            JSONKeys.width.rawValue: device.width
        ]
        
        if let value = code {
            json[JSONKeys.code.rawValue] = value
        }
        
        if let value = info {
            json[JSONKeys.info.rawValue] = value
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
        case message = "Message"
        case code = "Code"
        case info = "Info"
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
