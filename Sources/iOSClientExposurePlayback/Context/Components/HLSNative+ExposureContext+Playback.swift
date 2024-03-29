//
//  Player+ExposurePlayback.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-07-22.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import iOSClientPlayer
import iOSClientExposure
import AVFoundation

extension Player where Tech == HLSNative<ExposureContext> {
    
    /// Initiates a playback session with the supplied `Playable`
    ///
    /// Calling this method during an active playback session will terminate that session and dispatch the appropriate *Aborted* events.
    ///
    /// - Parameters:
    ///   - playable: EMP `Playable` for which to request playback.
    ///   - properties: Properties specifying additional configuration for the playback
    ///   - adsOptions: Client / device specific information that can be used for ad targeting
    ///   - adobePrimetimeMediaToken: X-Adobe-Primetime-MediaToken
    ///   - enableAnalytics: should enable Analytics / Not
    ///   - materialProfile: used to play a specific material variant.
    ///   - customAdParams: Custom Ad Params
    ///   - metadataIdentifiers: metadataIdentifiers for filtering tags in `EXT-X-DATERANGE `
    public func startPlayback(playable: Playable, properties: PlaybackProperties = PlaybackProperties(), adsOptions:AdsOptions? = nil, adobePrimetimeMediaToken: String? = nil, enableAnalytics: Bool = true , materialProfile: String? = nil , customAdParams: [String: Any]? = nil, metadataIdentifiers: [String]? = nil, deviceMake:String? = nil, deviceModel: String? = nil ) {
        context.startPlayback(playable: playable, properties: properties, tech: tech, adsOptions: adsOptions, adobePrimetimeMediaToken: adobePrimetimeMediaToken, enableAnalytics: enableAnalytics, materialProfile:materialProfile, customAdParams: customAdParams, metadataidentifiers: metadataIdentifiers, deviceMake: deviceMake, deviceModel: deviceModel)
    }
    
    /// Initiates a playback session by requesting a *vod* entitlement and preparing the player.
    ///
    /// Calling this method during an active playback session will terminate that session and dispatch the appropriate *Aborted* events.
    ///
    /// - Parameters:
    ///   - assetId: EMP asset id for which to request playback.
    ///   - properties: Properties specifying additional configuration for the playback
    ///   - adobePrimetimeMediaToken: X-Adobe-Primetime-MediaToken
    ///   - enableAnalytics: should enable Analytics / Not
    ///   - materialProfile: used to play a specific material variant.
    ///   - customAdParams: Custom Ad Params
    ///   - metadataIdentifiers: metadataIdentifiers for filtering tags in `EXT-X-DATERANGE
    public func startPlayback(assetId: String, properties: PlaybackProperties = PlaybackProperties(), adobePrimetimeMediaToken: String? = nil, enableAnalytics: Bool = true, materialProfile: String? = nil , customAdParams: [String: Any]? = nil, metadataIdentifiers: [String]? = nil, deviceMake:String? = nil, deviceModel: String? = nil  ) {
        let playable = AssetPlayable(assetId: assetId)
        startPlayback(playable: playable, properties: properties, enableAnalytics : enableAnalytics, materialProfile: materialProfile, customAdParams: customAdParams, metadataIdentifiers: metadataIdentifiers, deviceMake: deviceMake, deviceModel: deviceModel)
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
    ///  -   materialProfile:  used to play a specific material variant.
    ///  -   customAdParams:  Custom Ad Params
    ///  -  metadataidentifiers:  metadataIdentifiers for filtering tags in `EXT-X-DATERANGE
    internal func startPlayback(playable: Playable, properties: PlaybackProperties, tech: HLSNative<ExposureContext>, adsOptions:AdsOptions? = nil,  adobePrimetimeMediaToken: String? = nil, enableAnalytics: Bool = true, materialProfile: String? = nil, customAdParams: [String: Any]? = nil, metadataidentifiers: [String]? = nil, deviceMake:String? = nil, deviceModel: String? = nil ) {
        playbackProperties = properties
        
        // Generate the analytics providers
        let providers = analyticsProviders(for: nil)
        
       
        playable.prepareSourceWithResponse(environment: environment, sessionToken: sessionToken, adsOptions: adsOptions, adobePrimetimeMediaToken: adobePrimetimeMediaToken, materialProfile: materialProfile, customAdParams: customAdParams, metadataIdentifiers: metadataidentifiers, deviceMake: deviceMake, deviceModel: deviceModel ) { [weak self, weak tech] source, error, response in
            guard let `self` = self, let tech = tech else { return }
            if enableAnalytics == true {
                self.handle(source: source, error: error, providers: providers, tech: tech, exposureResponse: response, playable: playable, metadataIdentifiers:metadataidentifiers)
            } else {
                self.handle(source: source, error: error, providers: nil, tech: tech, exposureResponse: response, playable: playable, metadataIdentifiers: metadataidentifiers)
            }
            
        }
    }
    
    fileprivate func handle(source: ExposureSource?, error: ExposureError?, providers: [AnalyticsProvider]? = nil , tech: HLSNative<ExposureContext>, exposureResponse: HTTPURLResponse?, playable: Playable, metadataIdentifiers: [String]? = nil ) {
        if let source = source {
            
            onEntitlementResponse(source.entitlement, source)
            
            // Initial analytics
            providers?.forEach{
                if let exposureProvider = $0 as? ExposureStreamingAnalyticsProvider {
                    exposureProvider.onEntitlementRequested(tech: tech, source: source, playable: playable, isOfflinePlayable: false)
                }
            }
            
            
            // Pass media type 
            let _ = source.entitlement.audioOnly == true ? onMediaType(MediaType.audio) : onMediaType(MediaType.video)
            
            /// Assign the providers
            if let providers = providers {
                source.analyticsConnector.providers = providers
            }
            
            /// Make sure StartTime is configured if specified by user
            tech.startTime(byDelegate: self)
            
            /// Update tech autoplay settings from PlaybackProperties
            tech.autoplay = playbackProperties.autoplay
            
            /// Assign language preferences
            switch playbackProperties.language {
            case .defaultBehaviour:
                // print("context.playbackProperties.language.defaultBehaviour", tech.preferredTextLanguage, tech.preferredAudioLanguage)
                tech.preferredTextLanguage = nil
                tech.preferredAudioLanguage = nil 
                break
            case .userLocale:
                let locale = Locale.current.languageCode
                tech.preferredTextLanguage = locale
                tech.preferredAudioLanguage = locale
            case let .custom(text: text, audio: audio):
                tech.preferredTextLanguage = text
                tech.preferredAudioLanguage = audio
            case .userPreference:
                tech.preferredAudioLanguage = UserDefaults.standard.string(forKey: "lastSelectedAudioTrackLanguageTag")
                tech.preferredTextLanguage = UserDefaults.standard.string(forKey: "lastSelectedTextTrackLanguageTag")
                tech.preferredTextType = AVMediaType(UserDefaults.standard.string(forKey: "lastSelectedTextTrackMediaType") ?? "")
                tech.isAudioDescriptionPreferred = UserDefaults.standard.bool(forKey: "doesLastSelectedAudioTrackDescribeVideo")
                tech.isDialogTranscribePreferred = UserDefaults.standard.bool(forKey: "doesLastSelectedTextTrackTranscribeDialog")
                tech.languageFallbackType = .localeThenStream
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
                tech.load(source: source, configuration: configuration, metadataIdentifiers: metadataIdentifiers) { [weak self, weak source, weak tech] in
                    guard let `self` = self, let tech = tech, let source = source else { return }
                    /// Start ProgramService
                    self.prepareProgramService(source: source, tech: tech)
                    
                    // Start Ad service if the ads.stitcher == "NOWTILUS"
                    if let streamingInfo = source.streamingInfo, let ads = source.ads, let clips = ads.clips {
                        if streamingInfo.live == false && streamingInfo.ssai == true && ads.stitcher == "NOWTILUS" {
                            let serverSideAd = ServerSideAdService(ads: ads, clips: clips, context: self, source: source, durationInMs : source.durationInMs ?? 0, tech: tech)
                            serverSideAd.playerProxy = AdTechWrapper(tech: tech)
                            
                            source.adService = serverSideAd
                            
                            let eventProvider = AdServiceEventProvider(adService: serverSideAd)
                            source.analyticsConnector.providers.append(eventProvider)
                            self.onServerSideAd(source, ads)
                        } else {
                            self.onServerSideAd(source, nil)
                            self.onPlaybackStartWithAds(Int64(source.durationInMs ?? 0), 0 , Int64(source.durationInMs ?? 0), [])
                        }
                    } else {
                        self.onServerSideAd(source, nil)
                        self.onPlaybackStartWithAds(Int64(source.durationInMs ?? 0), 0 , Int64(source.durationInMs ?? 0), [])
                    }
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
                            source.adService?.playbackEnded()
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
                    exposureProvider.onHandshakeStarted(tech: tech, source: source, analytics: source.entitlement.analytics, isOfflinePlayable: false)
                    exposureProvider.finalizePreparation(tech: tech, source: source, assetId: playable.assetId, playSessionId: source.entitlement.playSessionId, analytics: source.entitlement.analytics, isOfflinePlayable: false) { [weak self, weak tech] in
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
            source?.adService?.playbackEnded()
            tech.stop()
            tech.eventDispatcher.onError(tech, nilSource, contextError)
        }
    }
    
    func prepareProgramService(source: ExposureSource, tech: HLSNative<ExposureContext>) {
        guard let serviceEnabled = source as? ProgramServiceEnabled else {
            return
            
        }
        let service = programServiceGenerator(environment, sessionToken, source.entitlement.epg , serviceEnabled.programServiceChannelId)
        
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
                    exposureProvider.onProgramChanged(tech: tech, source: source, program: program, analytics: source.entitlement.analytics)
                }
            }
            
            // If the program is a live event & if there is EPG Gap player should stop playing : If the program has a gap, programId should be nil
            if source.streamingInfo?.event == true && program?.programId == nil {
                // Player should stop
                source.adService?.playbackEnded()
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
            
            source.adService?.playbackEnded()
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
