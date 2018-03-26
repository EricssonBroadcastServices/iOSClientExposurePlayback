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
    // MARK: Airplay
    
    /// Sets the callback to fire once Airplay status changes
    ///
    /// The third parameter in the callback specifies if *Airplay* was turned on or off.
    ///
    /// - parameter callback: callback to fire once the event is fired.
    /// - returns: `Self`
    public func onAirplayStatusChanged(callback: @escaping (Player<HLSNative<ExposureContext>>, ExposureSource?, Bool) -> Void) -> Self {
        tech.onAirplayStatusChanged = { [weak self] tech, source, airplaying in
            guard let `self` = self else { return }
            callback(self, source, airplaying)
        }
        return self
    }
}

extension ExposureContext: AirplayHandler {
    public func handleAirplayEvent<Tech, Source>(active: Bool, tech: Tech, source: Source?) where Tech : PlaybackTech, Source : MediaSource {
        guard let tech = tech as? HLSNative<ExposureContext> else { return }
        
        if active {
            source?.analyticsConnector.providers.forEach {
                if let exposureProvider = $0 as? ExposureAnalytics {
                    exposureProvider.startedAirplay()
                }
            }
        }
        
        let position = tech.playheadPosition
        let playFrom = active ? PlaybackProperties.PlayFrom.customPosition(position: position) : .bookmark
        let properties = PlaybackProperties(old: playbackProperties, playFrom: playFrom)
        tech.stop()
        
        if let source = source as? AssetSource {
            let playable = AssetPlayable(assetId: source.assetId)
            startPlayback(playable: playable, properties: properties, tech: tech)
        }
        else if let source = source as? ChannelSource {
            let playable = ChannelPlayable(assetId: source.assetId)
            startPlayback(playable: playable, properties: properties, tech: tech)
        }
        else if let source = source as? ProgramSource {
            let playable = ProgramPlayable(assetId: source.assetId, channelId: source.channelId)
            startPlayback(playable: playable, properties: properties, tech: tech)
        }
    }
}
