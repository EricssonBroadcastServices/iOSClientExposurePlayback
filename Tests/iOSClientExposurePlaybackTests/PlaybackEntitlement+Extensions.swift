//
//  PlaybackEntitlement+Extensions.swift
//  ExposurePlaybackTests
//
//  Created by Fredrik Sjöberg on 2018-02-11.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import iOSClientExposure

extension PlaybackEntitlement {
    static var validJson: [String: Any] {
        let fairplayJson:[String: Any] = [
            "secondaryMediaLocator":"secondaryMediaLocator",
            "certificateUrl":"certificateUrl",
            "licenseAcquisitionUrl":"licenseAcquisitionUrl",
            "licenseServerUrl": "licenseServerUrl"
        ]
        let json:[String: Any] = [
            "playToken":"playToken",
            "fairplayConfig":fairplayJson,
            "mediaLocator":"mediaLocator",
            "licenseExpiration":"licenseExpiration",
            "licenseExpirationReason":"NOT_ENTITLED",
            "licenseActivation":"licenseActivation",
            "playTokenExpiration":"playTokenExpiration",
            "entitlementType":"TVOD",
            "live":false,
            "playSessionId":"playSessionId",
            "ffEnabled":false,
            "timeshiftEnabled":false,
            "rwEnabled":false,
            "minBitrate":10,
            "maxBitrate":20,
            "maxResHeight":30,
            "airplayBlocked":false,
            "mdnRequestRouterUrl":"mdnRequestRouterUrl",
            "lastViewedOffset":10,
            "lastViewedTime":10,
            "liveTime":10,
            "productId":"productId"
        ]
        
        return json
    }
    
    static var requiedJson: [String: Any] {
        return [
            "mediaLocator":"mediaLocator",
            "playTokenExpiration":"playTokenExpiration",
            "playSessionId":"playSessionId",
            "live":false,
            "ffEnabled":false,
            "timeshiftEnabled":false,
            "rwEnabled":false,
            "airplayBlocked":false
        ]
    }
}
