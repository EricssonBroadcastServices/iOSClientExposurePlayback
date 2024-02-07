//
//  BitrateChanged.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-17.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import iOSClientExposure
import UIKit

extension Playback {
    /// Playback switched to a different bitrate.
    internal struct BitrateChanged {
        
        /// Id string of the player/sdk.
        /// Example: EMP.tvOS2, EMP.iOS2
        internal var player: String {
            return "EMP." + UIDevice.mergedSystemName + "2"
        }
        
        internal let timestamp: Int64
        
        /// Offset in the video sequence where the playback switched to a different bitrate
        internal let offsetTime: Int64?
        
        /// New bitrate, in kilobit/s
        internal let bitrate: Int64
        
        internal var cdnInfo: CDNInfoFromEntitlement?
        
        internal var analyticsInfo: AnalyticsFromEntitlement?
        
        internal init(timestamp: Int64, offsetTime: Int64?, bitrate: Int64, cdnInfo: CDNInfoFromEntitlement? = nil , analyticsInfo: AnalyticsFromEntitlement? = nil) {
            self.timestamp = timestamp
            self.offsetTime = offsetTime
            self.bitrate = bitrate
            self.cdnInfo = cdnInfo
            self.analyticsInfo = analyticsInfo
        }
    }
}

extension Playback.BitrateChanged: AnalyticsEvent {
    var eventType: String {
        return "Playback.BitrateChanged"
    }
    
    var bufferLimit: Int64 {
        return 3000
    }
    
    internal var jsonPayload: [String : Any] {
        
        let device: Device = Device()
        
        var json: [String: Any] = [
            JSONKeys.eventType.rawValue: eventType,
            JSONKeys.timestamp.rawValue: timestamp,
            JSONKeys.bitrate.rawValue: bitrate,
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
        
        return json
    }
    
    internal enum JSONKeys: String {
        case eventType = "EventType"
        case timestamp = "Timestamp"
        case offsetTime = "OffsetTime"
        case bitrate = "Bitrate"
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
    }
}
