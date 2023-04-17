//
//  ChannelPlayable.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-26.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import iOSClientExposure

internal protocol ChannelEntitlementProvider {
    
    func requestEntitlement(channelId: String, using sessionToken: SessionToken, in environment: Environment, callback: @escaping (PlaybackEntitlement?, ExposureError?, HTTPURLResponse?) -> Void)
    
    func requestEntitlementV2(channelId: String, using sessionToken: SessionToken, in environment: Environment, callback: @escaping (PlaybackEntitlement?, PlayBackEntitlementV2?, ExposureError?, HTTPURLResponse?) -> Void)
}

@available(*, deprecated, message: "You can use AssetPlayable & pass assetType if needed")
/// Defines a `Playable` for the specific channel. Will play the currently live program
public struct ChannelPlayable: Playable {
    /// The channel id
    public let assetId: String
    
    internal var entitlementProvider: ChannelEntitlementProvider = ExposureEntitlementProvider()
    
    internal struct ExposureEntitlementProvider: ChannelEntitlementProvider {
        func requestEntitlement(channelId: String, using sessionToken: SessionToken, in environment: Environment, callback: @escaping (PlaybackEntitlement?, ExposureError?, HTTPURLResponse?) -> Void) {
            
            self.requestEntitlementV2(channelId: channelId, using: sessionToken, in: environment, callback: { entitlementV1, entitlementV2, error, response in
                
                guard let entitlementV2 = entitlementV2 else { return
                    callback(nil, error, response)
                }
                let (convertedEntitlement, error ) = EnigmaPlayable.convertV2EntitlementToV1(entitlementV2: entitlementV2)
                
                guard let playbackEntitlement = convertedEntitlement else {
                    callback(nil, error, response)
                    return
                }
                
                callback(playbackEntitlement, error, response )
                
            })
            
        }
        
        
        
        /// Request entitlement V2 & convert it to playback entitlement v1
        ///
        /// - Parameters:
        ///   - channelId: channel Id
        ///   - sessionToken: session token
        ///   - environment: exposure enviornment
        ///   - callback: callback
        func requestEntitlementV2(channelId: String, using sessionToken: SessionToken, in environment: Environment, callback: @escaping (PlaybackEntitlement?, PlayBackEntitlementV2?, ExposureError?, HTTPURLResponse?) -> Void) {
            
            Entitlement(environment: environment,
                        sessionToken: sessionToken)
                .enigmaAsset(assetId: channelId)
                .request()
                .validate()
                .response{
                    guard let enetitlementV2Response =  $0.value else {
                        callback(nil,nil, $0.error, $0.response)
                        return
                    }
                    
                    let (convertedEntitlement, error) = EnigmaPlayable.convertV2EntitlementToV1(entitlementV2: enetitlementV2Response)
                    guard let playbackEntitlement = convertedEntitlement else {
                        callback(nil,nil, error, $0.response)
                        return
                    }
                    
                    
                    callback(playbackEntitlement, enetitlementV2Response, $0.error, $0.response)
            }
        }
    }
}

extension ChannelPlayable {
    public init(assetId: String) {
        self.assetId = assetId
    }
}

extension ChannelPlayable {
    /// Helper method producing an `ChannelSource` for *live* playback using the supplied assetId.
    ///
    /// - parameter environment: `Environment` to request the Source from
    /// - parameter sessionToken: `SessionToken` validating the user
    /// - parameter callback: Closure called on request completion
    public func prepareSource(environment: Environment, sessionToken: SessionToken, adsOptions: AdsOptions?,adobePrimetimeMediaToken: String?, materialProfile: String?, customAdParams:[String: Any]?, metadataIdentifiers: [String]?, deviceMake:String?, deviceModel: String?, callback: @escaping (ExposureSource?, ExposureError?) -> Void) {
        prepareChannelSource(environment: environment, sessionToken: sessionToken, callback: callback)
    }
    
    internal func prepareChannelSource(environment: Environment, sessionToken: SessionToken, callback: @escaping (ExposureSource?, ExposureError?) -> Void) {
        entitlementProvider.requestEntitlementV2(channelId: assetId, using: sessionToken, in: environment) { entitlementV1, entitlementV2, error, response in
            if let value = entitlementV2 {
                
                guard let playbackEntitlement = entitlementV1 else {
                    callback(nil, error)
                    return
                }
                
                let source = ChannelSource(entitlement: playbackEntitlement, assetId: self.assetId, streamingInfo: value.streamInfo)
                source.response = response
                callback(source, nil)
            }
            else if let error = error {
                callback(nil,error)
            }
            else {
                print("Some unkown error occured while prepareChannelSource in ChannelPlayable")
                callback(nil,nil)
            }
        }
    }
}

extension ChannelPlayable {
    public func prepareSourceWithResponse(environment: Environment, sessionToken: SessionToken, callback: @escaping (ExposureSource?, ExposureError?, HTTPURLResponse?) -> Void) {
        entitlementProvider.requestEntitlementV2(channelId: assetId, using: sessionToken, in: environment) { entitlementV1, entitlementV2, error, response in
            if let value = entitlementV2 {
                
                guard let playbackEntitlement = entitlementV1 else {
                    callback(nil, error, response)
                    return
                }
                
                let source = ChannelSource(entitlement: playbackEntitlement, assetId: self.assetId, streamingInfo: value.streamInfo)
                source.response = response
                callback(source, nil, response)
            }
            else if let error = error {
                callback(nil,error,response)
            }
            else {
                print("Some unkown error occured while prepareSourceWithResponse in ChannelPlayable")
                callback(nil,nil,response)
            }
        }
    }
}
