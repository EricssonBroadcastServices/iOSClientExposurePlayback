//
//  Error.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-17.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import iOSClientExposure
import UIKit

extension Playback {
    /// Playback stopped because of an error.
    internal struct Error {
        
        /// Id string of the player/sdk.
        /// Example: EMP.tvOS2, EMP.iOS2
        internal var player: String {
            return "EMP." + UIDevice.mergedSystemName + "2"
        }
        
        internal let timestamp: Int64
        
        /// Offset in the video sequence where the playback was aborted.
        internal let offsetTime: Int64?
        
        /// Human readable error message
        /// Example: "NOT_ENTITLED"
        internal let message: String
        
        /// Platform-dependent error code
        internal let code: Int
        
        /// Additional detailed error information
        internal let info: String?
        
        /// Error Details, such as stack trace or expanded error info
        internal let details: String?
        
        /// Playback technology used
        internal let tech: String?
        
        /// Version of the tech
        internal let techVersion: String?
        
        internal var cdnInfo: CDNInfoFromEntitlement?
        
        internal var analyticsInfo: AnalyticsFromEntitlement?
        
        internal init(timestamp: Int64, offsetTime: Int64?, message: String, code: Int, info: String? = nil, details: String? = nil, tech: String? = nil , techVersion: String? = nil ,  cdnInfo: CDNInfoFromEntitlement? = nil , analyticsInfo: AnalyticsFromEntitlement? = nil) {
            self.timestamp = timestamp
            self.offsetTime = offsetTime
            self.message = message
            self.code = code
            self.info = info
            self.details = details
            
            self.tech = tech
            self.techVersion = techVersion
            
            self.cdnInfo = cdnInfo
            self.analyticsInfo = analyticsInfo
        }
    }
}

extension Playback.Error: AnalyticsEvent {
    
    
    var eventType: String {
        return "Playback.Error"
    }
    
    var bufferLimit: Int64 {
        return 3000
    }
    
    /// String identifier to recognize the device. This should be the same Id as was sent during the login request to the exposure API.
    ///
    /// NOTE: Implementation details for "identifierForVendor" states this:
    /// "If the value is nil, wait and get the value again later. This happens, for example, after the device has been restarted but before the user has unlocked the device."
    ///
    /// This implementation ignores the above scenario with the expressed reasoning such a rare event is not worth the complexity of a possible workaround. "UNKNOWN_DEVICE_ID" will be sent in the event this occurs.
    internal var deviceId: String {
        return UIDevice.current.identifierForVendor?.uuidString ?? "UNKNOWN_DEVICE_ID"
    }
    
    /// Model of the device
    /// Example: iPhone8,1
    internal var deviceModel: String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0,  count: Int(size))
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
    }
    
    /// String identifying the CPU of the device playing the media    armeabi-v7a
    internal var cpuType: String? {
        return nil
    }
    
    /// Operating system of the device.
    /// Example: iOS, tvOS
    internal var os: String {
        return UIDevice.mergedSystemName
    }
    
    /// Version number of the operating system
    /// Example: 8.1
    internal var osVersion: String {
        return UIDevice.current.systemVersion
    }
    
    /// Company that built/created/marketed the device
    internal var manufacturer: String {
        return "Apple"
    }
    
    
    internal var jsonPayload: [String : Any] {
        var json: [String: Any] = [
            JSONKeys.eventType.rawValue: eventType,
            JSONKeys.timestamp.rawValue: timestamp,
            JSONKeys.message.rawValue: message,
            JSONKeys.code.rawValue: code,
            JSONKeys.deviceId.rawValue: deviceId,
            JSONKeys.deviceModel.rawValue: deviceModel,
            JSONKeys.os.rawValue: os,
            JSONKeys.appType.rawValue: "app",
            JSONKeys.osVersion.rawValue: osVersion,
            JSONKeys.manufacturer.rawValue: manufacturer,
            JSONKeys.player.rawValue: player,
            JSONKeys.tech.rawValue: tech,
            JSONKeys.techVersion.rawValue: techVersion
        ]
        
        if let offset = offsetTime {
            json[JSONKeys.offsetTime.rawValue] = offset
        }
        
        if let info = info {
            json[JSONKeys.info.rawValue] = info
        }
        
        if let details = details {
            json[JSONKeys.details.rawValue] = details
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
        case message = "Message"
        case code = "Code"
        case info = "Info"
        case details = "Details"
        
        
        case deviceId = "DeviceId"
        case deviceModel = "DeviceModel"
        case cpuType = "CPUType"
        case appType = "AppType"
        case os = "OS"
        case osVersion = "OSVersion"
        case manufacturer = "Manufacturer"
        case player = "Player"
        
        // CDN
        case CDNVendor = "CDNVendor"
        
        // Analytics info from entitlement
        case bucket = "AnalyticsBucket"
        case postInterval = "AnalyticsPostInterval"
        case tag = "AnalyticsTag"
        
        case StreamingTechnology = "StreamingTechnology"
        
        case tech = "Technology"
        case techVersion = "TechVersion"
        case userAgent = "UserAgent"
        
        case height = "Height"
        case width = "Width"
    }
}

