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
    /// - parameter AdsOptions: Client / device specific information that can be used for ad targeting
    /// - parameter adobePrimetimeMediaToken:  X-Adobe-Primetime-MediaToken
    public func startPlayback(playable: Playable, properties: PlaybackProperties = PlaybackProperties(), adsOptions:AdsOptions? = nil, adobePrimetimeMediaToken: String? = nil, enableAnalytics: Bool = true ) {
        context.startPlayback(playable: playable, properties: properties, tech: tech, adsOptions: adsOptions, adobePrimetimeMediaToken: adobePrimetimeMediaToken, enableAnalytics: enableAnalytics)
    }
    
    /// Initiates a playback session by requesting a *vod* entitlement and preparing the player.
    ///
    /// Calling this method during an active playback session will terminate that session and dispatch the appropriate *Aborted* events.
    ///
    /// - parameter assetId: EMP asset id for which to request playback.
    /// - parameter properties: Properties specifying additional configuration for the playback
    /// - parameter adobePrimetimeMediaToken: X-Adobe-Primetime-MediaToken
    public func startPlayback(assetId: String, properties: PlaybackProperties = PlaybackProperties(), adobePrimetimeMediaToken: String? = nil, enableAnalytics: Bool = true) {
        let playable = AssetPlayable(assetId: assetId)
        startPlayback(playable: playable, properties: properties, enableAnalytics : enableAnalytics)
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
    /// Calling this method during an active playback session will terminate that session and dispatch the appropriate *Aborted* events.
    ///
    /// - Parameters:
    ///   - playable: EMP `Playable` for which to request playback.
    ///   - properties: Properties specifying additional configuration for the playback
    ///   - tech: Tech to do the playback on
    ///   - adsOptions: Client / device specific information that can be used for ad targeting
    ///   - adobePrimetimeMediaToken: X-Adobe-Primetime-MediaToken
    internal func startPlayback(playable: Playable, properties: PlaybackProperties, tech: HLSNative<ExposureContext>, adsOptions:AdsOptions? = nil,  adobePrimetimeMediaToken: String? = nil, enableAnalytics: Bool = true ) {
        playbackProperties = properties
        
        // Generate the analytics providers
        let providers = analyticsProviders(for: nil)
        
        // Initial analytics
        providers.forEach{
            if let exposureProvider = $0 as? ExposureStreamingAnalyticsProvider {
                exposureProvider.onEntitlementRequested(tech: tech, playable: playable)
            }
        }
        
        playable.prepareSourceWithResponse(environment: environment, sessionToken: sessionToken, adsOptions: adsOptions, adobePrimetimeMediaToken: adobePrimetimeMediaToken) { [weak self, weak tech] source, error, response in
            guard let `self` = self, let tech = tech else { return }
            if enableAnalytics == true {
                self.handle(source: source, error: error, providers: providers, tech: tech, exposureResponse: response)
            } else {
                self.handle(source: source, error: error, providers: nil, tech: tech, exposureResponse: response)
            }
            
        }
    }
    
    fileprivate func handle(source: ExposureSource?, error: ExposureError?, providers: [AnalyticsProvider]? = nil , tech: HLSNative<ExposureContext>, exposureResponse: HTTPURLResponse?) {
        if let source = source {
            onEntitlementResponse(source.entitlement, source)
            
            /// Assign the providers
            if let providers = providers {
                source.analyticsConnector.providers = providers
            }
            
            
            /// Ask if an optional AdService is available
            onAdServiceRequested(source)
            
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
            
            source.prepareSourceUrl{ [weak self, weak tech, weak source] in
                guard let `self` = self, let tech = tech, let source = source else {
                    // TODO: Trigger warning?
                    return
                }
                source.proxyUrl = $0
                
                /// Load tech
                tech.load(source: source, configuration: configuration) { [weak self, weak source, weak tech] in
                    guard let `self` = self, let tech = tech, let source = source else { return }
                    /// Start ProgramService
                    self.prepareProgramService(source: source, tech: tech)
                }
            }
            
            /// Hook DRM analytics events
            if let fairplayRequester = source.fairplayRequester as? EMUPFairPlayRequester {
                fairplayRequester.onCertificateRequest = { [weak tech, weak source] in
                    guard let tech = tech, let source = source else { return }
                    source.analyticsConnector.providers.forEach{
                        if let drmProvider = $0 as? DrmAnalyticsProvider {
                            drmProvider.onCertificateRequest(tech: tech, source: source)
                        }
                    }
                }
                
                fairplayRequester.onCertificateResponse = { [weak tech, weak source] certError in
                    guard let tech = tech, let source = source else {
                        return
                        
                    }
                    source.analyticsConnector.providers.forEach{
                        if let drmProvider = $0 as? DrmAnalyticsProvider {
                            drmProvider.onCertificateResponse(tech: tech, source: source, error: certError)
                        }
                    }
                }
                /// Hook license request and response listener
                fairplayRequester.onLicenseRequest = { [weak tech, weak source] in
                    guard let tech = tech, let source = source else { return }
                    source.analyticsConnector.providers.forEach{
                        if let drmProvider = $0 as? DrmAnalyticsProvider {
                            drmProvider.onLicenseRequest(tech: tech, source: source)
                        }
                    }
                }
                
                fairplayRequester.onLicenseResponse = { [weak tech, weak source] licenseError in
                    guard let tech = tech, let source = source else { return }
                    source.analyticsConnector.providers.forEach{
                        if let drmProvider = $0 as? DrmAnalyticsProvider {
                            drmProvider.onLicenseResponse(tech: tech, source: source, error: licenseError)
                        }
                    }
                }
            }
            
            
            source.analyticsConnector.providers.forEach{
                /// Analytics Session Invalidation Detection
                if let exposureAnalytics = $0 as? ExposureAnalytics {
                    exposureAnalytics.onExposureResponseMessage = { [weak tech, weak source] reason in
                        guard let tech = tech, let source = source else { return }
                        switch (reason.httpCode, reason.message) {
                        case (401, "INVALID_SESSION_TOKEN"):
                            let contextError = PlayerError<HLSNative<ExposureContext>, ExposureContext>.context(error: .exposure(reason: ExposureError.exposureResponse(reason: reason)))
                            tech.eventDispatcher.onError(tech, source, contextError)
                            source.analyticsConnector.onError(tech: tech, source: source, error: contextError)
                            tech.stop()
                        default:
                            print("===",reason.httpCode,reason.message)
                        }
                    }
                }
                
                
                /// EMP related startup analytics
                if let exposureProvider = $0 as? ExposureStreamingAnalyticsProvider {
                    exposureProvider.onHandshakeStarted(tech: tech, source: source)
                    exposureProvider.finalizePreparation(tech: tech, source: source, playSessionId: source.entitlement.playSessionId) { [weak self, weak tech] in
                        guard let `self` = self, let tech = tech else { return nil }
                        
                        guard let heartbeatsProvider = source as? HeartbeatsProvider else { return nil }
                        return heartbeatsProvider.heartbeat(for: tech, in: self)
                    }
                }
                
            }
            
            /// Hook connection changed analytics events
            reachability?.onReachabilityChanged = { [weak tech, weak source] connection in
                source?.analyticsConnector.providers.forEach{
                    if let exposureAnalytics = $0 as? ExposureAnalytics {
                        exposureAnalytics.onConnectionChanged(tech: tech, source: source, type: connection)
                    }
                }
            }
        }
        
        if let error = error {
            /// Deliver error
            let contextError = PlayerError<HLSNative<ExposureContext>, ExposureContext>.context(error: .exposure(reason: error))
            let nilSource: ExposureSource? = nil
            
            if let providers = providers {
                providers.forEach{
                    /// EMP-11667: If Exposure returned an error, (ie an ExposureResponseMessage, for example NOT_ENTITLED), no Source object is created. This means we need to set the `X-Request-Id` before we finalize the session.
                    ($0 as? ExposureAnalytics)?.exposureEntitlementHTTPURLResponse = exposureResponse
                    $0.onError(tech: tech, source: nilSource, error: contextError)
                }
            }
            
            tech.stop()
            tech.eventDispatcher.onError(tech, nilSource, contextError)
        }
    }
    
    func prepareProgramService(source: ExposureSource, tech: HLSNative<ExposureContext>) {
        guard let serviceEnabled = source as? ProgramServiceEnabled else {
            return
            
        }
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
            
            // If the program is a live event & if there is EPG Gap player should stop playing : If the program has a gap, programId should be nil
            if source.streamingInfo?.event == true && program?.programId == nil {
                // Player should stop
                tech.stop()
            } else {
                // Do nothing: Allow continue playback
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
