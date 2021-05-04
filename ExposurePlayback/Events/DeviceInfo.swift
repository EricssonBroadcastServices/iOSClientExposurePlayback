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
    
    /// Optional string indicating the nature of playback from this device
    ///
    /// Can be used to indicate this is an `Airplay` session
    internal let type: String?
    
    /// Indicates the connection type
    internal let connection: String
    
    internal var cdnInfo: CDNInfoFromEntitlement?
    
    internal var analyticsInfo: AnalyticsFromEntitlement?
    
    internal init(timestamp: Int64, connection: String, type: String? = nil, cdnInfo: CDNInfoFromEntitlement? = nil , analyticsInfo: AnalyticsFromEntitlement? = nil) {
        self.timestamp = timestamp
        self.connection = connection
        self.type = type
        
        self.cdnInfo = cdnInfo
        self.analyticsInfo = analyticsInfo
    }
}

extension DeviceInfo {
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
}

extension DeviceInfo: AnalyticsEvent {
    internal var eventType: String {
        return "Device.Info"
    }
    
    var bufferLimit: Int64 {
        return 3000
    }
    
    internal var jsonPayload: [String : Any] {
        var params: [String: Any] = [
            JSONKeys.eventType.rawValue: eventType,
            JSONKeys.timestamp.rawValue: timestamp,
            JSONKeys.deviceId.rawValue: deviceId,
            JSONKeys.deviceModel.rawValue: deviceModel,
            JSONKeys.os.rawValue: os,
            JSONKeys.osVersion.rawValue: osVersion,
            JSONKeys.manufacturer.rawValue: manufacturer,
            JSONKeys.connection.rawValue: connection
        ]
        
        if let cpuType = cpuType {
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
        
        return params
    }
    
    internal enum JSONKeys: String {
        case eventType = "EventType"
        case timestamp = "Timestamp"
        case deviceId = "DeviceId"
        case deviceModel = "DeviceModel"
        case cpuType = "CPUType"
        case os = "OS"
        case osVersion = "OSVersion"
        case manufacturer = "Manufacturer"
        case type = "Type"
        case connection = "Connection"
        
        // CDN
        case CDNVendor = "CDNVendor"
        
        // Analytics info from entitlement
        case bucket = "AnalyticsBucket"
        case postInterval = "AnalyticsPostInterval"
        case tag = "AnalyticsTag"
        
        case StreamingTechnology = "StreamingTechnology"
    }
}
