//
//  ProgramPlayable.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-26.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Exposure

internal protocol ProgramEntitlementProvider {
    func requestEntitlement(programId: String, channelId: String, using sessionToken: SessionToken, in environment: Environment, callback: @escaping (PlaybackEntitlement?, ExposureError?, HTTPURLResponse?) -> Void)
}

/// Defines a `Playable` for the specific program
public struct ProgramPlayable: Playable {
    /// The program Id for the program
    public let assetId: String
    
    /// The channel id
    public let channelId: String
    
    internal var entitlementProvider: ProgramEntitlementProvider = ExposureEntitlementProvider()
    
    internal struct ExposureEntitlementProvider: ProgramEntitlementProvider {
        func requestEntitlement(programId: String, channelId: String, using sessionToken: SessionToken, in environment: Environment, callback: @escaping (PlaybackEntitlement?, ExposureError?, HTTPURLResponse?) -> Void) {
            let entitlement = Entitlement(environment: environment,
                                          sessionToken: sessionToken)
                .program(programId: programId,
                         channelId: channelId)
            
            entitlement
                .request()
                .validate()
                .response{
                    if let error = $0.error {
                        // Workaround until EMP-10023 is fixed
                        if case let .exposureResponse(reason: reason) = error, (reason.httpCode == 403 && reason.message == "NO_MEDIA_FOR_PROGRAM") {
                            entitlement
                                .use(drm: "UNENCRYPTED")
                                .request()
                                .validate()
                                .response{ callback($0.value, $0.error, $0.response) }
                        }
                        else {
                            callback($0.value, $0.error, $0.response)
                        }
                    }
                    else {
                        callback($0.value, $0.error, $0.response)
                    }
                }
        }
    }
}

extension ProgramPlayable {
    public init(assetId: String, channelId: String) {
        self.assetId = assetId
        self.channelId = channelId
    }
}

extension ProgramPlayable {
    /// Helper method producing an `ProgramSource` for *program* playback using the supplied `environment` and `sessionToken`
    ///
    /// - parameter environment: `Environment` to request the Source from
    /// - parameter sessionToken: `SessionToken` validating the user
    /// - parameter callback: Closure called on request completion
    public func prepareSource(environment: Environment, sessionToken: SessionToken, callback: @escaping (ExposureSource?, ExposureError?) -> Void) {
        entitlementProvider.requestEntitlement(programId: assetId, channelId: channelId, using: sessionToken, in: environment) { entitlement, error, response in
            if let value = entitlement {
                let source = ProgramSource(entitlement: value, assetId: self.assetId, channelId: self.channelId)
                source.response = response
                callback(source, nil)
            }
            else if let error = error {
                callback(nil,error)
            }
        }
    }
}

extension ProgramPlayable {
    public func prepareSourceWithResponse(environment: Environment, sessionToken: SessionToken, callback: @escaping (ExposureSource?, ExposureError?, HTTPURLResponse?) -> Void) {
        entitlementProvider.requestEntitlement(programId: assetId, channelId: channelId, using: sessionToken, in: environment) { entitlement, error, response in
            if let value = entitlement {
                let source = ProgramSource(entitlement: value, assetId: self.assetId, channelId: self.channelId)
                source.response = response
                callback(source, nil, response)
            }
            else if let error = error {
                callback(nil,error,response)
            }
        }
    }
}

