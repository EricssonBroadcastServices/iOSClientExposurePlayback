//
//  ChannelPlayable.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-26.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation

public struct ChannelPlayable: Playable {
    public var assetId: String
}

extension ChannelPlayable {
    /// Helper method producing an `ChannelSource` for *live* playback using the supplied assetId.
    ///
    /// - parameter environment: `Environment` to request the Source from
    /// - parameter sessionToken: `SessionToken` validating the user
    /// - parameter callback: Closure called on request completion
    public func prepareSource(environment: Environment, sessionToken: SessionToken, callback: @escaping (ExposureSource?, ExposureError?) -> Void) {
        prepareChannelSource(environment: environment, sessionToken: sessionToken, callback: callback)
    }
    
    internal func prepareChannelSource(environment: Environment, sessionToken: SessionToken, callback: @escaping (ExposureSource?, ExposureError?) -> Void) {
        let entitlement = Entitlement(environment: environment,
                                      sessionToken: sessionToken)
            .live(channelId: assetId)
        
        entitlement
            .request()
            .response{
                if let error = $0.error {
                    // Workaround until EMP-10023 is fixed
                    if case let .exposureResponse(reason: reason) = error, (reason.httpCode == 403 && reason.message == "NO_MEDIA_ON_CHANNEL") {
                        entitlement
                            .use(drm: .unencrypted)
                            .request()
                            .response{
                                if let entitlement = $0.value {
                                    callback(ChannelSource(entitlement: entitlement, assetId: self.assetId), nil)
                                }
                                else {
                                    callback(nil,$0.error!)
                                }
                        }
                    }
                    else {
                        callback(nil,error)
                    }
                }
                else if let entitlement = $0.value {
                    callback(ChannelSource(entitlement: entitlement, assetId: self.assetId), nil)
                }
        }
    }
}
