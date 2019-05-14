//
//  PlayBackEntitlementV2+Extensions.swift
//  ExposurePlayback
//
//  Created by Udaya Sri Senarathne on 2019-04-15.
//  Copyright © 2019 emp. All rights reserved.
//

import Foundation
import Exposure

extension PlayBackEntitlementV2 {
    static var validJson: [String: Any] {
        
        let formats: [String: Any] = [
            "format": "HLS",
            "drm" : [
                "com.apple.fps" : [
                    "licenseServerUrl" : "licenseServerUrl",
                    "certificateUrl" : "certificateUrl"
                ]
            ],
        "mediaLocator": "https://cache-dev.cdn.ebsd.ericsson.net/L23/000079/000079_enigma.isml/live.mpd?t=2019-04-15T12%3A00%3A00.000"
        ]
        
        let streamInfo: [String: Any] = [
            "live" : false,
            "static" : true,
            "event" : false,
            "start" : 1555329600,
            "channelId" : "channelId",
            "programId" : "programId"
        ]
        
        let bookmarks: [String : Any] = [
            "liveTime" : 10,
            "lastViewedOffset" : 10,
            "lastViewedTime" : 10
        ]
        
        let contractRestrictions: [String: Any] = [
            "airplayEnabled" : true,
            "ffEnabled" : true,
            "maxBitrate" : 20,
            "maxResHeight" : 30,
            "minBitrate": 10,
            "rwEnabled": true,
            "timeshiftEnabled" : true
        ]
        
        
        let json:[String: Any] = [
            "productId":"productId",
            "publicationId":"publicationId",
            "playSessionId":"playSessionId",
            "playToken":"playToken",
            "playTokenExpiration": 10,
            "formats":[formats],
            "streamInfo":streamInfo,
            "bookmarks":bookmarks,
            "requestId":"requestId",
            "contractRestrictions" : contractRestrictions
        ]
        
        return json
    }
    
    static var requiedJson: [String: Any] {
        
        let formats: [String: Any] = [
            "format": "HLS",
            "drm" : [
                "com.apple.fps" : [
                    "licenseServerUrl" : "licenseServerUrl",
                    "certificateUrl" : "certificateUrl"
                ]
            ],
            "mediaLocator": "https://cache-dev.cdn.ebsd.ericsson.net/L23/000079/000079_enigma.isml/live.mpd?t=2019-04-15T12%3A00%3A00.000"
        ]
        
        let streamInfo: [String: Any] = [
            "live" : false,
            "static" : true,
            "event" : false,
            "start" : 0,
            "channelId" : "channelId",
            "programId" : "programId"
        ]
        
        let bookmarks: [String : Any] = [
            "liveTime" : 10,
            "lastViewedOffset" : 10,
            "lastViewedTime" : 10
        ]
        
        let contractRestrictions: [String: Any] = [
            "airplayEnabled" : true,
            "ffEnabled" : true,
            "maxBitrate" : 20,
            "maxResHeight" : 30,
            "minBitrate": 10,
            "rwEnabled": true,
            "timeshiftEnabled" : true
        ]
        
        return [
            "formats":[formats],
            "playSessionId":"playSessionId",
            "playToken": "playToken",
            "playTokenExpiration" : 10,
            "streamInfo" : streamInfo,
            "productId": "productId",
            "bookmarks":bookmarks,
            "contractRestrictions": contractRestrictions,
        ]
    }
}
