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
    func requestEntitlement(assetId: String, using sessionToken: SessionToken, in environment: Environment, callback: @escaping (ExposureResponse<PlaybackEntitlement>) -> Void)
}

/// Defines a `Playable` for the specific vod asset
public struct AssetPlayable: Playable {
    /// The asset id
    public let assetId: String
    
    internal var entitlementProvider: AssetEntitlementProvider = ExposureEntitlementProvider()
    
    internal struct ExposureEntitlementProvider: AssetEntitlementProvider {
        func requestEntitlement(assetId: String, using sessionToken: SessionToken, in environment: Environment, callback: @escaping (ExposureResponse<PlaybackEntitlement>) -> Void) {
            Entitlement(environment: environment,
                        sessionToken: sessionToken)
                .vod(assetId: assetId)
                .request()
                .validate()
                .response{ callback($0) }
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
        entitlementProvider.requestEntitlement(assetId: assetId, using: sessionToken, in: environment) {
            if let value = $0.value {
                let source = AssetSource(entitlement: value, assetId: self.assetId)
                source.response = $0.response
                callback(source, nil)
            }
            else if let error = $0.error {
                callback(nil,error)
            }
        }
    }
}

extension AssetPlayable {
    public func prepareSourceWithResponse(environment: Environment, sessionToken: SessionToken, callback: @escaping (ExposureSource?, ExposureError?, HTTPURLResponse?) -> Void) {
        entitlementProvider.requestEntitlement(assetId: assetId, using: sessionToken, in: environment) {
            if let value = $0.value {
                let source = AssetSource(entitlement: value, assetId: self.assetId)
                source.response = $0.response
                callback(source, nil, $0.response)
            }
            else if let error = $0.error {
                callback(nil,error,$0.response)
            }
        }
    }
}
