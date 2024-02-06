//
//  HandshakeStarted.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-17.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import iOSClientExposure
import UIKit

extension Playback {
    /// If the player was created but not supposed to automatically play the asset as soon as possible, the HandshakeStarted event indicates that the player is preparing for playback now.
    internal struct HandshakeStarted {
        internal let timestamp: Int64
        
        internal let assetData: PlaybackIdentifier?
        
        internal let cdnInfo: CDNInfoFromEntitlement?
        
        internal let analyticsInfo: AnalyticsFromEntitlement?
        
        internal init(timestamp: Int64, assetData: PlaybackIdentifier? = nil, cdnInfo: CDNInfoFromEntitlement? = nil , analyticsInfo: AnalyticsFromEntitlement? = nil) {
            self.timestamp = timestamp
            self.assetData = assetData
            
            self.cdnInfo = cdnInfo
            self.analyticsInfo = analyticsInfo
        }
    }
}

extension Playback.HandshakeStarted: AssetIdentifier {
    
}

extension Playback.HandshakeStarted: AnalyticsEvent {
    var eventType: String {
        return "Playback.HandshakeStarted"
    }
    
    /// Id string of the player/sdk.
    /// Example: EMP.tvOS2, EMP.iOS2
    internal var player: String {
        return "EMP." + UIDevice.mergedSystemName + "2"
    }
    
    var bufferLimit: Int64 {
        return 3000
    }
    
    
    internal var jsonPayload: [String : Any] {
        
        let device: Device = Device()
        
        var params: [String: Any] = [
            JSONKeys.player.rawValue: player,
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
        
        if let assetId = assetId {
            params[JSONKeys.assetId.rawValue] = assetId
        }
        
        if let channelId = channelId {
            params[JSONKeys.channelId.rawValue] = channelId
        }
        
        if let programId = programId {
            params[JSONKeys.programId.rawValue] = programId
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
        
        params[JSONKeys.technology.rawValue] = "HLS"
        params[JSONKeys.techVersion.rawValue] = ""
        params[JSONKeys.userAgent.rawValue] = ""
        
        return params
    }
    
    internal enum JSONKeys: String {
        case player = "Player"
        case eventType = "EventType"
        case timestamp = "Timestamp"
        case assetId = "AssetId"
        case channelId = "ChannelId"
        case programId = "ProgramId"
       
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

