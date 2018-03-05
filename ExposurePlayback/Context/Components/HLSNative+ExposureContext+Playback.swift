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

extension Player where Tech == HLSNative<ExposureContext> {
    /// Initiates a playback session with the supplied `Playable`
    ///
    /// Calling this method during an active playback session will terminate that session and dispatch the appropriate *Aborted* events.
    ///
    /// - parameter assetId: EMP `Playable` for which to request playback.
    /// - parameter properties: Properties specifying additional configuration for the playback
    public func startPlayback(playable: Playable, properties: PlaybackProperties = PlaybackProperties()) {
        context.playbackProperties = properties
        
        // Generate the analytics providers
        let providers = context.analyticsProviders(for: nil)
        
        // Initial analytics
        providers.forEach{
            if let exposureProvider = $0 as? ExposureStreamingAnalyticsProvider {
                exposureProvider.onEntitlementRequested(tech: tech, playable: playable)
            }
        }
        
        playable.prepareSource(environment: context.environment, sessionToken: context.sessionToken) { [weak self] source, error in
            guard let `self` = self else { return }
            self.handle(source: source, error: error, providers: providers)
        }
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
    
    /// Initiating a playback session by requesting an entitlement for `channelId` will start live playback. Optionally, users can specify a `programId` as well, which will request program playback.
    ///
    /// Calling this method during an active playback session will terminate that session and dispatch the appropriate *Aborted* events.
    ///
    /// - parameter programId: EMP program id for which to request playback.
    //    /// - parameter programId: EMP program id for which to request playback.
    /// - parameter properties: Properties specifying additional configuration for the playback
    public func startPlayback(channelId: String, programId: String? = nil, properties: PlaybackProperties = PlaybackProperties()) {
        let playable: Playable = programId != nil ? ProgramPlayable(assetId: programId!, channelId: channelId) : ChannelPlayable(assetId: channelId)
        startPlayback(playable: playable, properties: properties)
    }
    
    private func handle(source: ExposureSource?, error: ExposureError?, providers: [AnalyticsProvider]) {
        if let source = source {
            context.onEntitlementResponse(source.entitlement, source)
            
            /// Make sure StartTime is configured if specified by user
            if let source = source as? ContextStartTime {
                source.handleStartTime(for: tech, in: context)
            }
            
            /// Update tech autoplay settings from PlaybackProperties
            tech.autoplay = context.playbackProperties.autoplay
            
            /// Assign language preferences
            switch context.playbackProperties.language {
            case .defaultBehaviour:
                print("context.playbackProperties.language.defaultBehaviour", tech.preferredTextLanguage, tech.preferredAudioLanguage)
            case .userLocale:
                print("context.playbackProperties.language.userLocale",Locale.current.languageCode)
                let locale = Locale.current.languageCode
                tech.preferredTextLanguage = locale
                tech.preferredAudioLanguage = locale
            case let .custom(text: text, audio: audio):
                tech.preferredTextLanguage = text
                tech.preferredAudioLanguage = audio
            }
            
            /// Create HLS configuration
            let configuration = HLSNativeConfiguration(drm: source.fairplayRequester,
                                                       preferredMaxBitrate: context.playbackProperties.maxBitrate)
            /// Load tech
            tech.load(source: source, configuration: configuration) { [weak self] in
                /// Start ProgramService
                self?.prepareProgramService(source: source)
            }
            
            
            source.analyticsConnector.providers = providers
            source.analyticsConnector.providers.forEach{
                if let exposureProvider = $0 as? ExposureStreamingAnalyticsProvider {
                    exposureProvider.onHandshakeStarted(tech: tech, source: source)
                    exposureProvider.finalizePreparation(tech: tech, source: source, playSessionId: source.entitlement.playSessionId) { [weak self, weak source] in
                        guard let `self` = self else { return nil }
                        guard let heartbeatsProvider = source as? HeartbeatsProvider else { return nil }
                        return heartbeatsProvider.heartbeat(for: self.tech, in: self.context)
                    }
                }
            }
        }
        
        if let error = error {
            /// Deliver error
            let contextError = PlayerError<Tech, ExposureContext>.context(error: .exposure(reason: error))
            let nilSource: ExposureSource? = nil
            providers.forEach{ $0.onError(tech: tech, source: nilSource, error: contextError) }
            tech.stop()
            tech.eventDispatcher.onError(tech, nilSource, contextError)
        }
    }
    
    private func prepareProgramService(source: ExposureSource) {
        guard let serviceEnabled = source as? ProgramServiceEnabled else { return }
        let service = context.programServiceGenerator(context.environment, context.sessionToken, serviceEnabled.programServiceChannelId)
        
        context.programService = service
        
        service.currentPlayheadTime = { [weak self] in return self?.playheadTime }
        
        service.isPlaying = { [weak self] in return self?.isPlaying ?? false }
        
        service.playbackRateObserver = tech.observeRateChanges { [weak service] tech, source, rate in
            if tech.isPlaying {
                service?.startMonitoring()
            }
            else {
                service?.pause()
            }
        }
        
        service.onProgramChanged = { [weak self] program in
            guard let `self` = self else { return }
            source.analyticsConnector.providers.forEach{
                if let exposureProvider = $0 as? ExposureStreamingAnalyticsProvider {
                    exposureProvider.onProgramChanged(tech: self.tech, source: source, program: program)
                }
            }
            self.context.onProgramChanged(program, source)
        }
        
        service.onNotEntitled = { [weak self] message in
            guard let `self` = self else { return }
            let error = ExposureError.exposureResponse(reason: ExposureResponseMessage(httpCode: 403, message: message))
            let contextError = PlayerError<HLSNative<ExposureContext>, ExposureContext>.context(error: .exposure(reason: error))
            
            self.tech.eventDispatcher.onError(self.tech, source, contextError)
            source.analyticsConnector.onError(tech: self.tech, source: source, error: contextError)
            self.tech.stop()
        }
        
        service.onWarning = { [weak self] warning in
            guard let `self` = self else { return }
            let contextWarning = PlayerWarning<HLSNative<ExposureContext>, ExposureContext>.context(warning: ExposureContext.Warning.programService(reason: warning))
            self.tech.eventDispatcher.onWarning(self.tech, source, contextWarning)
            source.analyticsConnector.onWarning(tech: self.tech, source: source, warning: contextWarning)
        }
    }
}

