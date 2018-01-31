//
//  AssetIdentifier.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-17.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Exposure

internal enum PlaybackIdentifier: Codable {
    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let asset = try container.decode(String.self, forKey: .asset)
        let type = try container.decode(Types.self, forKey: .type)
        switch type {
        case .vod: self = .vod(assetId: asset)
        case .live: self = .live(channelId: asset)
        case .program:
            let channel = try container.decode(String.self, forKey: .channel)
            self = .program(programId: asset, channelId: channel)
        case .offline: self = .offline(assetId: asset)
        case .download: self = .download(assetId: asset)
        }
        
    }
    
    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .vod(assetId: let asset):
            try container.encode(asset, forKey: .asset)
            try container.encode(Types.vod, forKey: .type)
        case .live(channelId: let asset):
            try container.encode(asset, forKey: .asset)
            try container.encode(Types.live, forKey: .type)
        case .program(programId: let asset, channelId: let channel):
            try container.encode(asset, forKey: .asset)
            try container.encode(Types.program, forKey: .type)
            try container.encode(channel, forKey: .channel)
        case .offline(assetId: let asset):
            try container.encode(asset, forKey: .asset)
            try container.encode(Types.offline, forKey: .type)
        case .download(assetId: let asset):
            try container.encode(asset, forKey: .asset)
            try container.encode(Types.download, forKey: .type)
        }
    }
    
    case vod(assetId: String)
    case live(channelId: String)
    case program(programId: String, channelId: String)
    case offline(assetId: String)
    case download(assetId: String)
    
    static func from(source: ExposureSource) -> PlaybackIdentifier {
        if let source = source as? AssetSource {
            return .vod(assetId: source.assetId)
        }
        else if let source = source as? ProgramSource {
            return .program(programId: source.assetId, channelId: source.channelId)
        }
        else if let source = source as? ChannelSource {
            return .live(channelId: source.assetId)
        }
        return .vod(assetId: source.assetId)
    }
    
    static func from(playable: Playable) -> PlaybackIdentifier {
        if let playable = playable as? AssetPlayable {
            return .vod(assetId: playable.assetId)
        }
        else if let playable = playable as? ProgramPlayable {
            return .program(programId: playable.assetId, channelId: playable.channelId)
        }
        else if let playable = playable as? ChannelPlayable {
            return .live(channelId: playable.assetId)
        }
        return .vod(assetId: playable.assetId)
    }
    
    internal enum CodingKeys: CodingKey {
        case asset
        case channel
        case type
    }
    
    internal enum Types: String, Codable {
        case vod
        case live
        case program
        case offline
        case download
    }
}

internal protocol AssetIdentifier {
    /// For vod or offline playback, contains the EMP AssetId of the video being played.
    ///
    /// For live playback, contains the EMP ChannelID of the video being played.
    /// 
    /// For live playback, contains the program initially being played. If the program changes during the session, a Playback.ProgramChanged event should be issued to signal this.
    ///
    /// Example: 1458209835_IkCMxd
    var assetData: PlaybackIdentifier? { get }
}

extension AssetIdentifier {
    /// EMP assetId if mode is *vod* or *offline*
    var assetId: String? {
        guard let data = assetData else { return nil }
        switch data {
        case .vod(assetId: let id): return id
        case .offline(assetId: let id): return id
        case .download(assetId: let id): return id
        default: return nil
        }
    }
    
    /// EMP channelId if mode is *live* or *catchup*
    var channelId: String? {
        guard let data = assetData else { return nil }
        switch data {
        case .live(channelId: let id): return id
        case .program(programId: _, channelId: let id): return id
        default: return nil
        }
    }
    
    /// EMP programId if mode *catchup*
    var programId: String? {
        guard let data = assetData else { return nil }
        switch data {
        case .program(programId: let id, channelId: _): return id
        default: return nil
        }
    }
}
