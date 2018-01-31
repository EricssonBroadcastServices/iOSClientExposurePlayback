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
internal struct DeviceInfo: AnalyticsEvent {
    internal let eventType: String = "Device.Info"
    internal let bufferLimit: Int64 = 3000
    internal let timestamp: Int64
    
}

extension DeviceInfo {
    /// String identifier to recognize the device. This should be the same Id as was sent during the login request to the exposure API.
    ///
    /// NOTE: Implementation details for "identifierForVendor" states this:
    /// "If the value is nil, wait and get the value again later. This happens, for example, after the device has been restarted but before the user has unlocked the device."
    /// 
    /// This implementation ignores the above scenario with the expressed reasoning such a rare event is not worth the complexity of a possible workaround.
    internal var deviceId: String {
        return UIDevice.current.identifierForVendor!.uuidString
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
    
    /// String identifying the CPU of the device playing the media	armeabi-v7a
    internal var cpuType: String? {
        // TODO: Not implemented yet
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
//        let components = UIDevice.current.systemVersion.components(separatedBy: ".")
//        switch components.count {
//        case 0: return nil
//        case 1: return components.first! + ".0"
//        case 2: return components.joined(separator: ".")
//        default: return components[0] + "." + components[1]
//        }
    }
    
    /// Company that built/created/marketed the device
    internal var manufacturer: String {
        return "Apple"
    }
}

extension DeviceInfo {
    internal var jsonPayload: [String : Any] {
        var params: [String: Any] = [
            JSONKeys.eventType.rawValue: eventType,
            JSONKeys.timestamp.rawValue: timestamp,
            JSONKeys.deviceId.rawValue: deviceId,
            JSONKeys.deviceModel.rawValue: deviceModel,
            JSONKeys.os.rawValue: os,
            JSONKeys.osVersion.rawValue: osVersion,
            JSONKeys.manufacturer.rawValue: manufacturer
        ]
        
        if let cpuType = cpuType {
            params[JSONKeys.cpuType.rawValue] = cpuType
        }
        
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
    }
}
