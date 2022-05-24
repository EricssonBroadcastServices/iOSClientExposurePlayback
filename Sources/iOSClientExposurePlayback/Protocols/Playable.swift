//
//  Playable.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-26.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import iOSClientExposure

// MARK: Playable
public protocol Playable {
    /// The unique identifier for this asset.
    var assetId: String { get }
    
    /// Helper method producing an `ExposureSoure` for playback using the supplied `environment` and `sessionToken`
    /// - Parameters:
    ///   - environment: `Environment` to request the Source from
    ///   - sessionToken: `SessionToken` validating the user
    ///   - adsOptions: `Ads Options` server side ad insertion options
    ///   - adobePrimetimeMediaToken: `X-Adobe-Primetime-MediaToken` adobePrimetimeMediaToken
    ///   - materialProfile: used to play a specific material variant.
    ///   - customAdParams: Custom Ad params
    ///   - callback: Closure called on request completion
    func prepareSource(environment: Environment, sessionToken: SessionToken, adsOptions:AdsOptions?, adobePrimetimeMediaToken: String?, materialProfile: String?, customAdParams: [String: Any]?, callback: @escaping (ExposureSource?, ExposureError?) -> Void)
    
    /// Helper method producing an `ExposureSoure` for playback using the supplied `environment` and `sessionToken`
    /// - Parameters:
    ///   - environment: Environment` to request the Source from
    ///   - sessionToken: `SessionToken` validating the user
    ///   - adsOptions: `Ads Options` server side ad insertion options
    ///   - adobePrimetimeMediaToken: `X-Adobe-Primetime-MediaToken` adobePrimetimeMediaToken
    ///   - materialProfile: used to play a specific material variant.
    ///   - customAdParams: Custom Ad params
    ///   - callback: Closure called on request completion
    func prepareSourceWithResponse(environment: Environment, sessionToken: SessionToken, adsOptions:AdsOptions?, adobePrimetimeMediaToken: String?, materialProfile: String?, customAdParams: [String: Any]?, callback: @escaping (ExposureSource?, ExposureError?, HTTPURLResponse?) -> Void)
}

extension Playable {
    /// Helper method producing an `ExposureSoure` for playback using the supplied `environment` and `sessionToken`
    /// - Parameters:
    ///   - environment: `Environment` to request the Source from
    ///   - sessionToken: `SessionToken` validating the user
    ///   - adsOptions: `Ads Options` server side ad insertion options
    ///   - adobePrimetimeMediaToken: `X-Adobe-Primetime-MediaToken` adobePrimetimeMediaToken
    ///   - materialProfile: used to play a specific material variant.
    ///   - customAdParams: Custom Ad params
    ///   - callback: Closure called on request completion
    public func prepareSourceWithResponse(environment: Environment, sessionToken: SessionToken, adsOptions:AdsOptions? = nil, adobePrimetimeMediaToken: String? = nil , materialProfile: String? = nil, customAdParams: [String: Any]? = nil , callback: @escaping (ExposureSource?, ExposureError?, HTTPURLResponse?) -> Void) {
        prepareSource(environment: environment, sessionToken: sessionToken, adsOptions: adsOptions, adobePrimetimeMediaToken: adobePrimetimeMediaToken, materialProfile: materialProfile, customAdParams: customAdParams) { source, error in
            callback(source,error,nil)
        }
    }
}

// MARK: ChannelPlayConvertible
public protocol ChannelPlayConvertible {
    var channelPlayable: ChannelPlayable { get }
}

extension Asset: ChannelPlayConvertible {
    public var channelPlayable: ChannelPlayable {
        return ChannelPlayable(assetId: assetId)
    }
}

// MARK: AssetPlayConvertible
public protocol AssetPlayConvertible {
    var assetPlayable: AssetPlayable { get }
}

extension Asset: AssetPlayConvertible {
    public var assetPlayable: AssetPlayable {
        return AssetPlayable(assetId: assetId)
    }
}


// MARK: ProgramPlayConvertible
public protocol ProgramPlayConvertible {
    var programPlayable: ProgramPlayable { get }
}

extension Program: ProgramPlayConvertible {
    public var programPlayable: ProgramPlayable {
        return ProgramPlayable(assetId: programId, channelId: channelId)
    }
}
