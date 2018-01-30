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
    var assetId: String { get }
    
    func prepareSource(environment: Environment, sessionToken: SessionToken, callback: @escaping (ExposureSource?, ExposureError?) -> Void)
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
        return ProgramPlayable(assetId: assetId, channelId: channelId)
    }
}
