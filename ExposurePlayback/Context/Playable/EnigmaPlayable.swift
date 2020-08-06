//
//  Playable.swift
//  ExposurePlayback-iOS
//
//  Created by Udaya Sri Senarathne on 2019-04-10.
//  Copyright © 2019 emp. All rights reserved.
//

import Foundation
import Exposure

public struct EnigmaPlayable {
    /// Convert EntitlementPlay V2 response to EntitlementPlayV1
    ///
    /// - Parameter entitlementV2: response from play V2
    /// - Returns: Entitlement & error
    internal static func convertV2EntitlementToV1(entitlementV2: PlayBackEntitlementV2 ) -> (PlaybackEntitlement?, ExposureError? ) {
        
        guard let format = entitlementV2.formats?.first else {
            let noSupportedMediaFormatsError = NSError(domain: "Could not find a media format supported by the current player implementation.", code: 38, userInfo: nil)
            
            return (nil, ExposureError.generalError(error: noSupportedMediaFormatsError))
        }
        
//        guard let certificateUrl = format.fairplay.first?.certificateUrl, let licenseServerUrl = format.fairplay.first?.licenseServerUrl else {
//            let noSupportedMediaFormatsError = NSError(domain: "Can not find certificate url or licenseAcquisition url", code: 38, userInfo: nil)
//            return (nil, ExposureError.generalError(error: noSupportedMediaFormatsError))
//        }
        
        let certificateUrl = format.fairplay.first?.certificateUrl
        let licenseServerUrl = format.fairplay.first?.licenseServerUrl
        
        let fairplay = FairplayConfiguration(secondaryMediaLocator: nil, certificateUrl: certificateUrl, licenseAcquisitionUrl: licenseServerUrl, licenseServerUrl: licenseServerUrl)
        
        let playbackEntitlement = PlaybackEntitlement(
            playTokenExpiration: String(entitlementV2.playTokenExpiration),
            mediaLocator: (format.mediaLocator),
            playSessionId: entitlementV2.playSessionId,
            live: entitlementV2.streamInfo?.live ?? false,
            ffEnabled: entitlementV2.contractRestrictions?.ffEnabled ?? true,
            timeshiftEnabled: entitlementV2.contractRestrictions?.timeshiftEnabled ?? true,
            rwEnabled: entitlementV2.contractRestrictions?.rwEnabled ?? true,
            airplayBlocked: entitlementV2.contractRestrictions?.airplayEnabled ?? true,
            playToken: entitlementV2.playToken,
            fairplay: fairplay,
            licenseExpiration: nil,
            licenseExpirationReason: nil,
            licenseActivation: nil, entitlementType: entitlementV2.entitlementType,
            minBitrate: entitlementV2.contractRestrictions?.minBitrate ?? 0,
            maxBitrate: entitlementV2.contractRestrictions?.maxBitrate ?? 0,
            maxResHeight: entitlementV2.contractRestrictions?.maxResHeight ?? 0,
            mdnRequestRouterUrl: nil,
            lastViewedOffset: entitlementV2.bookmarks?.lastViewedOffset ?? nil ,
            lastViewedTime: entitlementV2.bookmarks?.lastViewedTime ?? nil,
            liveTime: entitlementV2.bookmarks?.liveTime ?? nil ,
            productId: entitlementV2.productId,
            adMediaLocator: nil)
        
        return (playbackEntitlement, nil)
    }
    
    
    /*
    /// Convert json data to String json :- Testing purposes
    ///
    /// - Parameters:
    ///   - json: <#json description#>
    ///   - prettyPrinted: <#prettyPrinted description#>
    /// - Returns: <#return value description#>
    static func stringify(json: Any, prettyPrinted: Bool = false) -> String {
        var options: JSONSerialization.WritingOptions = []
        if prettyPrinted {
            options = JSONSerialization.WritingOptions.prettyPrinted
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: options)
            if let string = String(data: data, encoding: String.Encoding.utf8) {
                return string
            }
        } catch {
            print(error)
        }
        
        return ""
    } */
}
