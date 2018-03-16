//
//  HLSNative+ExposureContext+Airplay.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-03-15.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Player

extension Player where Tech == HLSNative<ExposureContext> {
    public func onAirplayStatusChanged(callback: @escaping (Player<HLSNative<ExposureContext>>, ExposureSource?, Bool) -> Void) -> Self {
        tech.onAirplayStatusChanged = { [weak self] tech, source, airplaying in
            guard let `self` = self else { return }
            callback(self, source, airplaying)
        }
        return self
    }
}

extension ExposureContext: AirplayHandler {
    public func handleAirplay<Tech, Source>(active: Bool, tech: Tech, source: Source?) where Tech : PlaybackTech, Source : MediaSource {
        guard let tech = tech as? HLSNative<ExposureContext> else { return }
        
        if let source = source as? AssetSource {
            let playable = AssetPlayable(assetId: source.assetId)
            let position = tech.playheadPosition
            let properties = PlaybackProperties(old: playbackProperties, playFrom: PlaybackProperties.PlayFrom.bookmark)
            startPlayback(playable: playable, properties: properties, tech: tech)
        }
        else if let source = source as? ChannelSource {
            let playable = ChannelPlayable(assetId: source.assetId)
            let timestamp = tech.playheadTime
            let playFrom = timestamp != nil ? PlaybackProperties.PlayFrom.customTime(timestamp: timestamp!) : PlaybackProperties.PlayFrom.bookmark
            let properties = PlaybackProperties(old: playbackProperties, playFrom: PlaybackProperties.PlayFrom.bookmark)
            startPlayback(playable: playable, properties: properties, tech: tech)
        }
        else if let source = source as? ProgramSource {
            let playable = ProgramPlayable(assetId: source.assetId, channelId: source.channelId)
            let timestamp = tech.playheadTime
            let playFrom = timestamp != nil ? PlaybackProperties.PlayFrom.customTime(timestamp: timestamp!) : PlaybackProperties.PlayFrom.bookmark
            let properties = PlaybackProperties(old: playbackProperties, playFrom: PlaybackProperties.PlayFrom.bookmark)
            startPlayback(playable: playable, properties: properties, tech: tech)
        }
    }
}
