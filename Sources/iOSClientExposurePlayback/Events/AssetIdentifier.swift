//
//  AssetIdentifier.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-17.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import iOSClientExposure

internal enum PlaybackIdentifier {
    case vod(assetId: String)
    case live(channelId: String)
    case program(programId: String, channelId: String)
    case offline(assetId: String)
    case download(assetId: String)
    
    static func from(source: ExposureSource, offline: Bool = false) -> PlaybackIdentifier {
        if let source = source as? AssetSource {
            return .vod(assetId: source.assetId)
        }
        else if let source = source as? ProgramSource {
            return .program(programId: source.assetId, channelId: source.channelId)
        }
        else if let source = source as? ChannelSource {
            return .live(channelId: source.assetId)
        }
        else if offline == true {
            return .offline(assetId: source.assetId)
        }
        return .vod(assetId: source.assetId)
    }
    
    static func from(playable: Playable, offline: Bool = false ) -> PlaybackIdentifier {
        if let playable = playable as? AssetPlayable {
            return .vod(assetId: playable.assetId)
        }
        else if let playable = playable as? ProgramPlayable {
            return .program(programId: playable.assetId, channelId: playable.channelId)
        }
        else if let playable = playable as? ChannelPlayable {
            return .live(channelId: playable.assetId)
        }
        else if offline == true {
            return .offline(assetId: playable.assetId)
        }
        return .vod(assetId: playable.assetId)
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
