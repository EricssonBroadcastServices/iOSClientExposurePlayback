//
//  URLPlayable.swift
//
//
//  Created by Robert Pelka on 14/02/2024.
//

import Foundation
import iOSClientExposure

public struct URLPlayable: Playable {
    let url: URL
    public var assetId: String
    
    public init(url: URL) {
        self.url = url
        self.assetId = url.absoluteString
    }
    
    public func prepareSource(
        environment: iOSClientExposure.Environment,
        sessionToken: iOSClientExposure.SessionToken,
        adsOptions: iOSClientExposure.AdsOptions?,
        adobePrimetimeMediaToken: String?,
        materialProfile: String?,
        customAdParams: [String : Any]?,
        metadataIdentifiers: [String]?,
        deviceMake: String?,
        deviceModel: String?,
        callback: @escaping (ExposureSource?, iOSClientExposure.ExposureError?) -> Void
    ) {
        let ent = PlaybackEntitlement(
            assetId: nil,
            accountId: nil,
            audioOnly: nil,
            playTokenExpiration: "",
            mediaLocator: self.url,
            playSessionId: "",
            live: false,
            ffEnabled: true,
            timeshiftEnabled: true,
            rwEnabled: true,
            airplayBlocked: false,
            playToken: "",
            fairplay: nil,
            licenseExpiration: "",
            licenseExpirationReason: "",
            licenseActivation: "",
            entitlementType: "",
            minBitrate: nil,
            maxBitrate: nil,
            maxResHeight: nil,
            mdnRequestRouterUrl: nil,
            lastViewedOffset: nil,
            lastViewedTime: nil,
            liveTime: nil,
            productId: nil,
            adMediaLocator: nil
        )
        
        let urlSource = URLSource(entitlement: ent, assetId: self.assetId, streamingInfo: nil)
        callback(urlSource, nil)
    }
}
