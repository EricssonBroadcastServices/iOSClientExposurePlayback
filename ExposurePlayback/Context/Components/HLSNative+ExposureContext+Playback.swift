//
//  Player+ExposurePlayback.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-07-22.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Player
import Exposure
import AVFoundation

extension Player where Tech == HLSNative<ExposureContext> {
    /// Initiates a playback session with the supplied `Playable`
    ///
    /// Calling this method during an active playback session will terminate that session and dispatch the appropriate *Aborted* events.
    ///
    /// - parameter assetId: EMP `Playable` for which to request playback.
    /// - parameter properties: Properties specifying additional configuration for the playback
    public func startPlayback(playable: Playable, properties: PlaybackProperties = PlaybackProperties()) {
        context.startPlayback(playable: playable, properties: properties, tech: tech)
    }
    
    /// Initiates a playback session by requesting a *vod* entitlement and preparing the player.
    ///
    /// Calling this method during an active playback session will terminate that session and dispatch the appropriate *Aborted* events.
    ///
    /// - parameter assetId: EMP asset id for which to request playback.
    /// - parameter properties: Properties specifying additional configuration for the playback
    public func startPlayback(assetId: String, properties: PlaybackProperties = PlaybackProperties()) {
        let playable = AssetPlayable(assetId: assetId)
        startPlayback(playable: playable, properties: properties)
    }
    
    /// Initiates a playback session by requesting an entitlement for `channelId` will start live playback. Optionally, users can specify a `programId` as well, which will request program playback.
    ///
    /// Calling this method during an active playback session will terminate that session and dispatch the appropriate *Aborted* events.
    ///
    /// - parameter channelId: EMP channel id for which to request playback.
    /// - parameter programId: EMP program id for which to request playback.
    /// - parameter properties: Properties specifying additional configuration for the playback
    public func startPlayback(channelId: String, programId: String? = nil, properties: PlaybackProperties = PlaybackProperties()) {
        let playable: Playable = programId != nil ? ProgramPlayable(assetId: programId!, channelId: channelId) : ChannelPlayable(assetId: channelId)
        startPlayback(playable: playable, properties: properties)
    }
}

extension ExposureContext {
    /// Initiates a playback session with the supplied `Playable`
    ///
    /// Calling this method during an active playback session will terminate that session and dispatch the appropriate *Aborted* events.
    ///
    /// - parameter assetId: EMP `Playable` for which to request playback.
    /// - parameter properties: Properties specifying additional configuration for the playback
    /// - parameter tech: Tech to do the playback on
    internal func startPlayback(playable: Playable, properties: PlaybackProperties, tech: HLSNative<ExposureContext>) {
        /// A monotonic time is required for delivering analytics. As such, we should make sure that is available before playback starts
        monotonicTimeService.serverTime(forceRefresh: false) { [weak self, weak tech] _, error in
            guard let `self` = self, let tech = tech else {
                /// This will occur when the player dissapears after servertime sync returns. It is considered a *lost cause*
                return
            }
            self.playbackProperties = properties
            
            guard error == nil else {
                // TODO: Do we trigger a warning?
                // TODO: Do we trigger an error? Do we allow playback anyway? Do we add a trace message?
                
                /// An error here basicly means a user CAN NOT play. Is this desired behavior
                
                return
            }
            
            // Generate the analytics providers
            let providers = self.analyticsProviders(for: nil)
            
            // Initial analytics
            providers.forEach{
                if let exposureProvider = $0 as? ExposureStreamingAnalyticsProvider {
                    exposureProvider.onEntitlementRequested(tech: tech, playable: playable)
                }
            }
            
            playable.prepareSource(environment: self.environment, sessionToken: self.sessionToken) { [weak self, weak tech] source, error in
                guard let `self` = self, let tech = tech else {
                    // TODO: Add trace?
                    return
                    
                }
                self.handle(source: source, error: error, providers: providers, tech: tech)
            }
        }
        
    }
    
    fileprivate func handle(source: ExposureSource?, error: ExposureError?, providers: [AnalyticsProvider], tech: HLSNative<ExposureContext>) {
        if let source = source {
            onEntitlementResponse(source.entitlement, source)
            
            /// Make sure StartTime is configured if specified by user
            tech.startTime(byDelegate: self)
            
            /// Update tech autoplay settings from PlaybackProperties
            tech.autoplay = playbackProperties.autoplay
            
            /// Assign language preferences
            switch playbackProperties.language {
            case .defaultBehaviour:
                print("context.playbackProperties.language.defaultBehaviour", tech.preferredTextLanguage, tech.preferredAudioLanguage)
            case .userLocale:
                let locale = Locale.current.languageCode
                tech.preferredTextLanguage = locale
                tech.preferredAudioLanguage = locale
            case let .custom(text: text, audio: audio):
                tech.preferredTextLanguage = text
                tech.preferredAudioLanguage = audio
            }
            
            /// Create HLS configuration
            let configuration = HLSNativeConfiguration(drm: source.fairplayRequester,
                                                       preferredMaxBitrate: playbackProperties.maxBitrate)
            
            /// Load tech
            tech.load(source: source, configuration: configuration) { [weak self, weak source, weak tech] in
                guard let `self` = self, let tech = tech, let source = source else { return }
                /// Start ProgramService
                self.prepareProgramService(source: source, tech: tech)
            }
            
            source.analyticsConnector.providers = providers
            source.analyticsConnector.providers.forEach{
                if let exposureProvider = $0 as? ExposureStreamingAnalyticsProvider {
                    exposureProvider.onHandshakeStarted(tech: tech, source: source)
                    exposureProvider.finalizePreparation(tech: tech, source: source, playSessionId: source.entitlement.playSessionId) { [weak self, weak tech] in
                        guard let `self` = self, let tech = tech else { return nil }
                        guard let heartbeatsProvider = source as? HeartbeatsProvider else { return nil }
                        return heartbeatsProvider.heartbeat(for: tech, in: self)
                    }
                }
            }
        }
        
        if let error = error {
            /// Deliver error
            let contextError = PlayerError<HLSNative<ExposureContext>, ExposureContext>.context(error: .exposure(reason: error))
            let nilSource: ExposureSource? = nil
            providers.forEach{ $0.onError(tech: tech, source: nilSource, error: contextError) }
            tech.stop()
            tech.eventDispatcher.onError(tech, nilSource, contextError)
        }
    }
    
    private func prepareProgramService(source: ExposureSource, tech: HLSNative<ExposureContext>) {
        guard let serviceEnabled = source as? ProgramServiceEnabled else { return }
        let service = programServiceGenerator(environment, sessionToken, serviceEnabled.programServiceChannelId)
        
        programService = service
        
        service.currentPlayheadTime = { [weak tech] in return tech?.playheadTime }
        
        service.isPlaying = { [weak tech] in return tech?.isPlaying ?? false }
        
        service.playbackRateObserver = tech.observeRateChanges { [weak service] tech, source, rate in
            if tech.isPlaying {
                service?.startMonitoring()
            }
            else {
                service?.pause()
            }
        }
        
        service.onProgramChanged = { [weak self, weak tech, weak source] program in
            guard let `self` = self, let tech = tech, let source = source else { return }
            source.analyticsConnector.providers.forEach{
                if let exposureProvider = $0 as? ExposureStreamingAnalyticsProvider {
                    exposureProvider.onProgramChanged(tech: tech, source: source, program: program)
                }
            }
            self.onProgramChanged(program, source)
        }
        
        service.onNotEntitled = { [weak tech, weak source] message in
            guard let tech = tech, let source = source else { return }
            let error = ExposureError.exposureResponse(reason: ExposureResponseMessage(httpCode: 403, message: message))
            let contextError = PlayerError<HLSNative<ExposureContext>, ExposureContext>.context(error: .exposure(reason: error))
            
            tech.eventDispatcher.onError(tech, source, contextError)
            source.analyticsConnector.onError(tech: tech, source: source, error: contextError)
            tech.stop()
        }
        
        service.onWarning = { [weak tech, weak source] warning in
            guard let tech = tech, let source = source else { return }
            let contextWarning = PlayerWarning<HLSNative<ExposureContext>, ExposureContext>.context(warning: ExposureContext.Warning.programService(reason: warning))
            tech.eventDispatcher.onWarning(tech, source, contextWarning)
            source.analyticsConnector.onWarning(tech: tech, source: source, warning: contextWarning)
        }
    }
}

