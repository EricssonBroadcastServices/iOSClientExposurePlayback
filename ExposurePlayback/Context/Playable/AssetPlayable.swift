//
//  AssetPlayable.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-26.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Exposure

internal protocol AssetEntitlementProvider {
    func requestEntitlement(assetId: String, using sessionToken: SessionToken, in environment: Environment, callback: @escaping (PlaybackEntitlement?, ExposureError?) -> Void)
}

public struct AssetPlayable: Playable {
    public let assetId: String
    
    internal var entitlementProvider: AssetEntitlementProvider = AlamofireEntitlementProvider()
    
    internal struct AlamofireEntitlementProvider: AssetEntitlementProvider {
        func requestEntitlement(assetId: String, using sessionToken: SessionToken, in environment: Environment, callback: @escaping (PlaybackEntitlement?, ExposureError?) -> Void) {
            Entitlement(environment: environment,
                        sessionToken: sessionToken)
                .vod(assetId: assetId)
                .request()
                .validate()
                .response{ callback($0.value, $0.error) }
        }
    }
}

extension AssetPlayable {
    public init(assetId: String) {
        self.assetId = assetId
    }
}

extension AssetPlayable {
    /// Helper method producing an `AssetSource` for *vod* playback using the supplied assetId.
    ///
    /// - parameter environment: `Environment` to request the Source from
    /// - parameter sessionToken: `SessionToken` validating the user
    /// - parameter callback: Closure called on request completion
    public func prepareSource(environment: Environment, sessionToken: SessionToken, callback: @escaping (ExposureSource?, ExposureError?) -> Void) {
        prepareAssetSource(environment: environment, sessionToken: sessionToken, callback: callback)
    }
    
    internal func prepareAssetSource(environment: Environment, sessionToken: SessionToken, callback: @escaping (ExposureSource?, ExposureError?) -> Void) {
        entitlementProvider.requestEntitlement(assetId: assetId, using: sessionToken, in: environment) { entitlement, error in
            if let entitlement = entitlement {
                callback(AssetSource(entitlement: entitlement, assetId: self.assetId), nil)
            }
            else {
                callback(nil,error!)
            }
        }
    }
}
