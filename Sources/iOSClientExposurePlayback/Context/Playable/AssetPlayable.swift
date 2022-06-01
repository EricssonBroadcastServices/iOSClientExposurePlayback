//
//  AssetPlayable.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-26.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import iOSClientExposure

internal protocol AssetEntitlementProvider {
    func requestEntitlement(assetId: String, using sessionToken: SessionToken, in environment: Environment,  include adsOptions: AdsOptions?, adobePrimetimeMediaToken: String?, materialProfile: String?, customAdParams:[String:Any]?, callback: @escaping (PlaybackEntitlement?, ExposureError?, HTTPURLResponse?) -> Void)
    
    func requestEntitlementV2(assetId: String, using sessionToken: SessionToken, in environment: Environment, include adsOptions: AdsOptions?, adobePrimetimeMediaToken: String?, materialProfile: String?, customAdParams: [String: Any]?, callback: @escaping (PlaybackEntitlement?, PlayBackEntitlementV2?, ExposureError?, HTTPURLResponse?) -> Void)
}

/// Defines a `Playable` for the specific vod asset
public struct AssetPlayable: Playable {
    
    /// The asset id
    public let assetId: String
    public let assetType: AssetType?
    
    internal var entitlementProvider: AssetEntitlementProvider = ExposureEntitlementProvider()
    
    internal struct ExposureEntitlementProvider: AssetEntitlementProvider {
        func requestEntitlement(assetId: String, using sessionToken: SessionToken, in environment: Environment, include adsOptions: AdsOptions?, adobePrimetimeMediaToken: String?, materialProfile: String?, customAdParams: [String: Any]?, callback: @escaping (PlaybackEntitlement?, ExposureError?, HTTPURLResponse?) -> Void) {
            
            self.requestEntitlementV2(assetId: assetId, using: sessionToken, in: environment, include: adsOptions, adobePrimetimeMediaToken: adobePrimetimeMediaToken, materialProfile: materialProfile, customAdParams: customAdParams, callback: { entitlementV1, entitlementV2, error, response in
                
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
        
        /// Request playback entitlement version 2
        /// - Parameters:
        ///   - assetId: assetId
        ///   - sessionToken: session token
        ///   - environment: exposure enviornment
        ///   - adsOptions: Server side Ad options
        ///   - adobePrimetimeMediaToken: adobePrimetimeMediaToken
        ///   - materialProfile:used to play a specific material variant.
        ///   - customAdParams: Custom Ad Params
        ///   - callback: callbacks
        func requestEntitlementV2(assetId: String, using sessionToken: SessionToken, in environment: Environment, include adsOptions: AdsOptions?, adobePrimetimeMediaToken: String?, materialProfile: String?, customAdParams: [String: Any]?, callback: @escaping (PlaybackEntitlement?, PlayBackEntitlementV2?, ExposureError?, HTTPURLResponse?) -> Void) {
            
            // Check if whether the app developer has pass AdsOptions to target ads
            if let adsOptions = adsOptions {
                Entitlement(environment: environment,
                            sessionToken: sessionToken)
                    .enigmaAsset(assetId: assetId, includeAds: adsOptions, with: adobePrimetimeMediaToken, use: materialProfile, add: customAdParams)
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
                        callback( playbackEntitlement ,enetitlementV2Response, $0.error, $0.response)
                    }
            } else {
                Entitlement(environment: environment,
                            sessionToken: sessionToken)
                    .enigmaAsset(assetId: assetId, with: adobePrimetimeMediaToken, use: materialProfile)
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
                        callback( playbackEntitlement ,enetitlementV2Response, $0.error, $0.response)
                    }
            }
            
        }
    }
}

extension AssetPlayable {
    public init(assetId: String, assetType: AssetType? = nil ) {
        self.assetId = assetId
        self.assetType = assetType
    }
}

extension AssetPlayable {
    /// Helper method producing an `AssetSource` for *vod* playback using the supplied assetId.
    ///
    /// - parameter environment: `Environment` to request the Source from
    /// - parameter sessionToken: `SessionToken` validating the user
    /// - parameter callback: Closure called on request completion
    public func prepareSource(environment: Environment, sessionToken: SessionToken, adsOptions:AdsOptions?, adobePrimetimeMediaToken: String?, materialProfile: String?,  customAdParams:[String:Any]?, callback: @escaping (ExposureSource?, ExposureError?) -> Void) {
        prepareAssetSource(environment: environment, sessionToken: sessionToken, adsOptions:adsOptions, adobePrimetimeMediaToken: adobePrimetimeMediaToken, materialProfile: materialProfile, customAdParams: customAdParams, callback: callback)
    }
    
    internal func prepareAssetSource(environment: Environment, sessionToken: SessionToken, adsOptions:AdsOptions?, adobePrimetimeMediaToken: String?, materialProfile: String?, customAdParams: [String:Any]?, callback: @escaping (ExposureSource?, ExposureError?) -> Void) {
        
        
        // Remove any sprites from UserDefaults if available
        UserDefaults.standard.removeObject(forKey: "sprites")
        
        
        entitlementProvider.requestEntitlementV2(assetId: assetId, using: sessionToken, in: environment, include: adsOptions, adobePrimetimeMediaToken: adobePrimetimeMediaToken, materialProfile: materialProfile, customAdParams: customAdParams) { entitlementV1, entitlementV2, error, response in
 
            if let value = entitlementV2 {
                guard let playbackEntitlement = entitlementV1 else {
                    callback(nil, error)
                    return
                }
                
                // Live event
                if value.streamInfo?.event == true {
                    let source = ProgramSource(entitlement: playbackEntitlement, assetId: self.assetId, channelId: value.streamInfo?.channelId ?? "", streamingInfo: value.streamInfo, durationInMs: value.durationInMs)
                    source.response = response
                    callback(source, nil)
                }
                
                // This is a live program
                if value.streamInfo?.live == true && value.streamInfo?.staticProgram == false {
                    let source = ProgramSource(entitlement: playbackEntitlement, assetId: self.assetId, channelId: value.streamInfo?.channelId ?? "", streamingInfo: value.streamInfo, durationInMs: value.durationInMs)
                    source.response = response
                    callback(source, nil)
                    
                }
                
                // Dynamic catchup as live
                else if value.streamInfo?.staticProgram == false && value.streamInfo?.start != nil {

                    // Add Sprites to userdefaults , so the sdk can use the cached sprites when user pass only the width
                    UserDefaults.standard.set(try? PropertyListEncoder().encode(value.sprites), forKey:"sprites")
                    let source = ProgramSource(entitlement: playbackEntitlement, assetId: self.assetId, channelId: value.streamInfo?.channelId ?? "", streamingInfo: value.streamInfo, sprites: value.sprites, durationInMs: value.durationInMs)
                    source.response = response
                    callback(source, nil)
                }
                
                // Static catch up as live
                else if value.streamInfo?.staticProgram == true && value.streamInfo?.end != nil {

                    // Add Sprites to userdefaults , so the sdk can use the cached sprites when user pass only the width
                    UserDefaults.standard.set(try? PropertyListEncoder().encode(value.sprites), forKey:"sprites")
                    let source = ProgramSource(entitlement: playbackEntitlement, assetId: self.assetId, channelId: value.streamInfo?.channelId ?? "", streamingInfo: value.streamInfo, sprites: value.sprites, durationInMs: value.durationInMs)
                    source.response = response
                    callback(source, nil)
                }
                
                
                // Catchup
                else if value.streamInfo?.live == false && value.streamInfo?.staticProgram == false {
                    // Add Sprites to userdefaults , so the sdk can use the cached sprites when user pass only the width
                    UserDefaults.standard.set(try? PropertyListEncoder().encode(value.sprites), forKey:"sprites")
                    let source = ProgramSource(entitlement: playbackEntitlement, assetId: self.assetId, channelId: value.streamInfo?.channelId ?? "", streamingInfo: value.streamInfo, sprites: value.sprites, durationInMs: value.durationInMs)
                    source.response = response
                    callback(source, nil)
                }
                // VOD Asset
                else if value.streamInfo?.staticProgram == true {
                    let source = AssetSource(entitlement: playbackEntitlement, assetId: self.assetId, streamingInfo: value.streamInfo, sprites: value.sprites, ads: value.ads, durationInMs: value.durationInMs)
                    
                    // Add Sprites to userdefaults , so the sdk can use the cached sprites when user pass only the width
                    UserDefaults.standard.set(try? PropertyListEncoder().encode(value.sprites), forKey:"sprites")
                    source.response = response
                    callback(source, nil)

                }
                
                // Some other assettype: Trying to use AssetPlay
                else {
                    let source = AssetSource(entitlement: playbackEntitlement, assetId: self.assetId, streamingInfo: value.streamInfo, sprites: value.sprites, ads: value.ads, durationInMs: value.durationInMs)
                    source.response = response
                    callback(source, nil)
                }
                
               
            }
            // Entitlment V2 has empty value : Error in prepareSource
            else if let error = error {
                callback(nil,error)
            }
            // Unknown error has occured
            else {
                print("Some unkown error occured while prepareAssetSource in AssetPlayable")
                callback(nil,nil)
            }
        }
    }
}

extension AssetPlayable {
    public func prepareSourceWithResponse(environment: Environment, sessionToken: SessionToken, adsOptions: AdsOptions?, adobePrimetimeMediaToken:String?, materialProfile: String?, customAdParams: [String:Any]?, activateSprite callback: @escaping (ExposureSource?, ExposureError?, HTTPURLResponse?) -> Void) {
        
        // Remove any sprites from UserDefaults if available
        UserDefaults.standard.removeObject(forKey: "sprites")
        
        entitlementProvider.requestEntitlementV2(assetId: assetId, using: sessionToken, in: environment, include: adsOptions, adobePrimetimeMediaToken: adobePrimetimeMediaToken, materialProfile: materialProfile, customAdParams: customAdParams) { entitlementV1, entitlementV2, error, response in
            
            if let value = entitlementV2 {
                
                guard let playbackEntitlement = entitlementV1 else {
                    callback(nil, error, response)
                    return
                }
                
                // Live event 
                if value.streamInfo?.event == true {
                    let source = ProgramSource(entitlement: playbackEntitlement, assetId: self.assetId, channelId: value.streamInfo?.channelId ?? "", streamingInfo: value.streamInfo)
                    source.response = response
                    callback(source, nil, response)
                }
                
                // Dynamic catchup as live
                else if value.streamInfo?.staticProgram == false && value.streamInfo?.start != nil {
                    let source = ProgramSource(entitlement: playbackEntitlement, assetId: self.assetId, channelId: value.streamInfo?.channelId ?? "", streamingInfo: value.streamInfo, sprites: value.sprites)
                    
                    // Add Sprites to userdefaults , so the sdk can use the cached sprites when user pass only the width
                    UserDefaults.standard.set(try? PropertyListEncoder().encode(value.sprites), forKey:"sprites")
                    
                    source.response = response
                    callback(source, nil, response)
                }
                
                // Static catchup as live
                else if value.streamInfo?.staticProgram == true && value.streamInfo?.end != nil {
                    let source = ProgramSource(entitlement: playbackEntitlement, assetId: self.assetId, channelId: value.streamInfo?.channelId ?? "", streamingInfo: value.streamInfo, sprites: value.sprites)
                    
                    // Add Sprites to userdefaults , so the sdk can use the cached sprites when user pass only the width
                    UserDefaults.standard.set(try? PropertyListEncoder().encode(value.sprites), forKey:"sprites")
                    
                    source.response = response
                    callback(source, nil, response)
                }
                
                // This is a live program
                else if value.streamInfo?.live == true && value.streamInfo?.staticProgram == false {
                    let source = ProgramSource(entitlement: playbackEntitlement, assetId: self.assetId, channelId: value.streamInfo?.channelId ?? "", streamingInfo: value.streamInfo)
                    source.response = response
                    callback(source, nil, response)
                    
                }
                
                // Catchup program
                else if value.streamInfo?.live == false && value.streamInfo?.staticProgram == false {
                    let source = ProgramSource(entitlement: playbackEntitlement, assetId: self.assetId, channelId: value.streamInfo?.channelId ?? "", streamingInfo: value.streamInfo, sprites: value.sprites)
                    
                    // Add Sprites to userdefaults , so the sdk can use the cached sprites when user pass only the width
                    UserDefaults.standard.set(try? PropertyListEncoder().encode(value.sprites), forKey:"sprites")
                    
                    source.response = response
                    callback(source, nil, response)
                }
                
                // This is a vod asset
                else if value.streamInfo?.staticProgram == true {
                    let source = AssetSource(entitlement: playbackEntitlement, assetId: self.assetId, streamingInfo: value.streamInfo, sprites: value.sprites)

                    // Add Sprites to userdefaults , so the sdk can use the cached sprites when user pass only the width
                    UserDefaults.standard.set(try? PropertyListEncoder().encode(value.sprites), forKey:"sprites")
                    
                    source.response = response
                    callback(source, nil, response)
                }
                
                // Something else -> Trying to play as an asset
                else {
                    let source = AssetSource(entitlement: playbackEntitlement, assetId: self.assetId, streamingInfo: nil, sprites: nil)
                    source.response = response
                    callback(source, nil, response)
                }
            }
            // Error in prepareSourceWithResponse
            else if let error = error {
                callback(nil,error,response)
            }
            
            // Unknown error has occured
            else {
                print("Some unkown error occured while prepareSourceWithResponse in AssetPlayable")
                callback(nil,nil,nil)
            }
        }
    }
}
