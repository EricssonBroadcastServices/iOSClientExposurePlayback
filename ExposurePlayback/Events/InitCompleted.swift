//
//  InitCompleted.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-21.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import iOSClientExposure

extension Playback {
    /// Player has resumed playing the asset that was paused.
    internal struct InitCompleted {
        
        /// Id string of the player/sdk.
        /// Example: EMP.tvOS2, EMP.iOS2
        internal var player: String {
            return "EMP." + UIDevice.mergedSystemName + "2"
        }
        
        internal let timestamp: Int64
        
        internal let cdnInfo: CDNInfoFromEntitlement?
        
        internal let analyticsInfo: AnalyticsFromEntitlement?
        
        internal init(timestamp: Int64, cdnInfo: CDNInfoFromEntitlement? = nil , analyticsInfo: AnalyticsFromEntitlement? = nil) {
            self.timestamp = timestamp
            self.cdnInfo = cdnInfo
            self.analyticsInfo = analyticsInfo
        }
    }
}

extension Playback.InitCompleted: AnalyticsEvent {
    var eventType: String {
        return "Playback.InitCompleted"
    }
    
    var bufferLimit: Int64 {
        return 3000
    }
    
    internal var jsonPayload: [String : Any] {
        
        var json: [String: Any] = [
            JSONKeys.eventType.rawValue: eventType,
            JSONKeys.timestamp.rawValue: timestamp,
            JSONKeys.player.rawValue: player
        ]
        
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
        case player = "Player"
        
        // CDN
        case CDNVendor = "CDNVendor"
        
        // Analytics info from entitlement
        case bucket = "AnalyticsBucket"
        case postInterval = "AnalyticsPostInterval"
        case tag = "AnalyticsTag"
        
        case StreamingTechnology = "StreamingTechnology"
    }
}

