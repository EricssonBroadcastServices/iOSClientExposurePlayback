//
//  Playable.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-26.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Exposure

// MARK: Playable
public protocol Playable {
    /// The unique identifier for this asset.
    var assetId: String { get }
    
    
    /// Helper method producing an `ExposureSoure` for playback using the supplied `environment` and `sessionToken`
    ///
    /// - parameter environment: `Environment` to request the Source from
    /// - parameter sessionToken: `SessionToken` validating the user
    /// - parameter callback: Closure called on request completion
    func prepareSource(environment: Environment, sessionToken: SessionToken, callback: @escaping (ExposureSource?, ExposureError?) -> Void)
    
    /// Helper method producing an `ExposureSoure` for playback using the supplied `environment` and `sessionToken`
    ///
    /// - parameter environment: `Environment` to request the Source from
    /// - parameter sessionToken: `SessionToken` validating the user
    /// - parameter callback: Closure called on request completion
    func prepareSourceWithResponse(environment: Environment, sessionToken: SessionToken, callback: @escaping (ExposureSource?, ExposureError?, HTTPURLResponse?) -> Void)
}

extension Playable {
    /// Helper method producing an `ExposureSoure` for playback using the supplied `environment` and `sessionToken`
    ///
    /// - parameter environment: `Environment` to request the Source from
    /// - parameter sessionToken: `SessionToken` validating the user
    /// - parameter callback: Closure called on request completion
    func prepareSourceWithResponse(environment: Environment, sessionToken: SessionToken, callback: @escaping (ExposureSource?, ExposureError?, HTTPURLResponse?) -> Void) {
        prepareSource(environment: environment, sessionToken: sessionToken) { source, error in
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
