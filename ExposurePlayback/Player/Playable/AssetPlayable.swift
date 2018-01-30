//
//  AssetPlayable.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-26.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation

public struct AssetPlayable: Playable {
    public var assetId: String
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
        Entitlement(environment: environment,
                    sessionToken: sessionToken)
            .vod(assetId: assetId)
            .request()
            .validate()
            .response{
                if let entitlement = $0.value {
                    callback(AssetSource(entitlement: entitlement, assetId: self.assetId), nil)
                }
                else {
                    callback(nil,$0.error!)
                }
        }
    }
}
