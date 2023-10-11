//
//  Created.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-16.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import iOSClientExposure
import UIKit

extension Playback {
    /// This event is sent when the player is instantiated, or invoked for the first time during the playback session.
    internal struct Created {
        internal let timestamp: Int64
        
        /// Id string of the player/sdk.
        /// Example: EMP.tvOS2, EMP.iOS2
        internal var player: String {
            return "EMP." + UIDevice.mergedSystemName + "2"
        }
        
        /// Release version and build revision of ExposurePlayback
        /// Example: 1.34.0
        internal let version: String
        
        /// Exposure framework version information
        internal let exposureVersion: String?
        
        /// Version of the tech
        internal let techVersion: String
        
        /// If true, the player will start playing as soon as possible. If false, player does not start playing, and will be initialized at a later time. If this field is missing, it is assumed to have the value "true".
        internal let autoPlay: Bool?
        
        /// `X-Request-Id` header specified in the ExposureResponse delivered when requesting an entitlement.
        internal var requestId: String?
        
        internal let analyticsInfo: AnalyticsFromEntitlement?
        
        /// One of the following: vod, live, offline
        internal var playMode: String {
            switch requiredAssetData {
            case .vod(assetId: _): return "vod"
            case .live(channelId: _): return "live"
            case .program(programId: _, channelId: _): return "vod"
            case .offline(assetId: _): return "offline"
            case .download(assetId: _): return "vod"
            }
        }
        
        internal var assetData: PlaybackIdentifier? {
            return requiredAssetData
        }
        internal let requiredAssetData: PlaybackIdentifier
        
        internal init(timestamp: Int64, version: String, exposureVersion: String? = nil, techVersion: String, assetData: PlaybackIdentifier, autoPlay: Bool? = nil, analyticsInfo: AnalyticsFromEntitlement? = nil ) {
            self.timestamp = timestamp
            self.version = version
            self.exposureVersion = exposureVersion
            self.requiredAssetData = assetData
            self.autoPlay = autoPlay
            self.analyticsInfo = analyticsInfo
            self.techVersion = techVersion
        }
    }
}

extension Playback.Created: AssetIdentifier { }

extension Playback.Created: AnalyticsEvent {
    internal var eventType: String {
        return "Playback.Created"
    }
    
    var bufferLimit: Int64 {
        return 3000
    }
    
    internal var jsonPayload: [String : Any] {
        
        let device: Device = Device()
        
        var params: [String: Any] = [
            JSONKeys.eventType.rawValue: eventType,
            JSONKeys.timestamp.rawValue: timestamp,
            JSONKeys.player.rawValue: player,
            JSONKeys.version.rawValue: version,
            JSONKeys.techVersion.rawValue: techVersion,
            JSONKeys.deviceId.rawValue: device.deviceId,
            JSONKeys.deviceModel.rawValue: device.model,
            JSONKeys.os.rawValue: device.os,
            JSONKeys.appType.rawValue: device.os,
            JSONKeys.osVersion.rawValue: device.osVersion,
            JSONKeys.manufacturer.rawValue: device.manufacturer,
            JSONKeys.height.rawValue: device.height,
            JSONKeys.width.rawValue: device.width
            
        ]
        
        if let exposureVersion = exposureVersion {
            params[JSONKeys.exposureVersion.rawValue] = exposureVersion
        }
        
        if let autoPlay = autoPlay {
            params[JSONKeys.autoPlay.rawValue] = autoPlay
        }
        
        if let assetId = assetId {
            params[JSONKeys.assetId.rawValue] = assetId
        }
        
        if let channelId = channelId {
            params[JSONKeys.channelId.rawValue] = channelId
        }
        
        if let programId = programId {
            params[JSONKeys.programId.rawValue] = programId
        }
        
        if let value = requestId {
            params[JSONKeys.requestId.rawValue] = value
        }
        
        if let analyticsInfo = analyticsInfo {
            params[JSONKeys.bucket.rawValue] = analyticsInfo.bucket
            params[JSONKeys.postInterval.rawValue] = analyticsInfo.postInterval
            params[JSONKeys.tag.rawValue] = analyticsInfo.tag
        }
        
        return params
    }
    
    internal enum JSONKeys: String {
        case eventType = "EventType"
        case timestamp = "Timestamp"
        case player = "Player"
        case version = "Version"
        case exposureVersion = "ExposureVersion"
        case autoPlay = "AutoPlay"
        case playMode = "PlayMode"
        case assetId = "AssetId"
        case channelId = "ChannelId"
        case programId = "ProgramId"
        case requestId = "RequestId"
        
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
        
        case connection = "Connection"
        
        case tech = "Technology"
        case techVersion = "TechVersion"
        case userAgent = "UserAgent"
        
        
        case bucket = "AnalyticsBucket"
        case postInterval = "AnalyticsPostInterval"
        case tag = "AnalyticsTag"
    }
}

