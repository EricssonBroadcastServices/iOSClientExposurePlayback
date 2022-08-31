//
//  ProgramPlayable.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-26.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import iOSClientExposure

internal protocol ProgramEntitlementProvider {
    func requestEntitlement(programId: String, channelId: String, using sessionToken: SessionToken, in environment: Environment, callback: @escaping (PlaybackEntitlement?, ExposureError?, HTTPURLResponse?) -> Void)
    
    func requestEntitlementV2(programId: String, channelId: String, using sessionToken: SessionToken, in environment: Environment, callback: @escaping (PlaybackEntitlement?, PlayBackEntitlementV2?, ExposureError?, HTTPURLResponse?) -> Void)
}

@available(*, deprecated, message: "You can use AssetPlayable & pass assetType if needed")
/// Defines a `Playable` for the specific program
public struct ProgramPlayable: Playable {
    /// The program Id for the program
    public let assetId: String
    
    /// The channel id
    public let channelId: String
    
    internal var entitlementProvider: ProgramEntitlementProvider = ExposureEntitlementProvider()
    
    internal struct ExposureEntitlementProvider: ProgramEntitlementProvider {
        func requestEntitlement(programId: String, channelId: String, using sessionToken: SessionToken, in environment: Environment, callback: @escaping (PlaybackEntitlement?, ExposureError?, HTTPURLResponse?) -> Void) {
            
            /*
             When using Programplayable implementation in the frontEnd app developer will use programId & channel Id. But programId is not the same as assetId.
             To use the new V2/Play end point we have to use assetId. So to get the assetId we need to make an extra API call.
             */
            self.getAssetId(environment: environment, sessionToken: sessionToken, channelId: channelId, programId: programId, callback: { assetId, error, response in
                
                guard let assetId = assetId else {
                    callback(nil, error, response)
                    return
                }
                
                self.requestEntitlementV2(programId: assetId, channelId: channelId, using: sessionToken, in: environment, callback: { entitlementV1, entitlementV2, error, response in
                    
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
            })
            
        }
        
        
        /// Use `GET /v1/customer/{customerUnit}/businessunit/{businessUnit}/epg/{channelId}/program/{programId}` Endpoint to fetch the assetId through programId
        ///
        /// - Parameters:
        ///   - environment: enviornment
        ///   - sessionToken: session token
        ///   - channelId: channel id
        ///   - programId: program id
        ///   - callback: call back will return assetId, exposure error & response
        internal func getAssetId(environment: Environment, sessionToken: SessionToken, channelId: String, programId: String, callback: @escaping (String?, ExposureError?, HTTPURLResponse?) -> Void) {
            
            FetchEpg(environment: environment)
                .channel(id: channelId, programId: programId)
                .request()
                .validate()
                .response{
                    guard let asset =  $0.value?.asset else {
                        callback(nil, $0.error, $0.response )
                        return
                    }
                    callback(asset.assetId, nil, $0.response )

            }
        }
        
        
        /// Request entitlement play version two & create program playable
        ///
        /// - Parameters:
        ///   - programId: programId
        ///   - channelId: channelId
        ///   - sessionToken: session token
        ///   - environment: exposure enviornment
        ///   - callback: callback
        func requestEntitlementV2(programId: String, channelId: String, using sessionToken: SessionToken, in environment: Environment, callback: @escaping (PlaybackEntitlement?, PlayBackEntitlementV2?, ExposureError?, HTTPURLResponse?) -> Void) {
            
            self.getAssetId(environment: environment, sessionToken: sessionToken, channelId: channelId, programId: programId, callback: { assetId, error, response in
                
                guard let assetId = assetId else {
                    callback(nil, nil, error, response)
                    return
                }
                
                Entitlement(environment: environment,
                            sessionToken: sessionToken)
                    .enigmaAsset(assetId: assetId)
                    .request()
                    .validate()
                    .response{
                        guard let enetitlementV2Response =  $0.value else {
                            callback(nil, nil, $0.error, $0.response)
                            return
                        }
                        
                        let (convertedEntitlement, error) = EnigmaPlayable.convertV2EntitlementToV1(entitlementV2: enetitlementV2Response)
                        guard let playbackEntitlement = convertedEntitlement else {
                            callback(nil, nil ,error, $0.response )
                            return
                        }
                        callback(playbackEntitlement, enetitlementV2Response, $0.error, $0.response)
                }
            })
        }
        
    }
    
    /// EPG Response :- Only match asset from the response
    public struct EPGResponse: Decodable {
        /// Body of the document
        public let asset: Asset
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
    public func prepareSource(environment: Environment, sessionToken: SessionToken, adsOptions: AdsOptions?,adobePrimetimeMediaToken: String?, materialProfile: String?, customAdParams:[String:Any]?, metadataIdentifiers: [String]?, callback: @escaping (ExposureSource?, ExposureError?) -> Void) {
        entitlementProvider.requestEntitlementV2(programId: assetId, channelId: channelId, using: sessionToken, in: environment) { entitlementV1, entitlementV2, error, response in
            if let value = entitlementV2 {
                
                guard let playbackEntitlement = entitlementV1 else {
                    callback(nil, error)
                    return
                }
                
                let source = ProgramSource(entitlement: playbackEntitlement, assetId: self.assetId, channelId: value.streamInfo?.channelId ?? "", streamingInfo: value.streamInfo)
                source.response = response
                callback(source, nil)
                
            }
            else if let error = error {
                callback(nil,error)
            }
            else {
                print("Some unkown error occured while prepareSource in ProgramPlayable")
                callback(nil,nil)
            }
        }
    }
}

extension ProgramPlayable {
    public func prepareSourceWithResponse(environment: Environment, sessionToken: SessionToken, callback: @escaping (ExposureSource?, ExposureError?, HTTPURLResponse?) -> Void) {
        entitlementProvider.requestEntitlementV2(programId: assetId, channelId: channelId, using: sessionToken, in: environment) { entitlementV1, entitlementV2, error, response in
            if let value = entitlementV2 {
                guard let playbackEntitlement = entitlementV1 else {
                    callback(nil, error, response)
                    return
                }
                
                let source = ProgramSource(entitlement: playbackEntitlement, assetId: self.assetId, channelId: value.streamInfo?.channelId ?? "", streamingInfo: value.streamInfo)
                source.response = response
                callback(source, nil, response)
                
            }
            else if let error = error {
                callback(nil,error,response)
            }
            else {
                print("Some unkown error occured while prepareSourceWithResponse in ProgramPlayable")
                callback(nil,nil,response)
            }
        }
    }
}


