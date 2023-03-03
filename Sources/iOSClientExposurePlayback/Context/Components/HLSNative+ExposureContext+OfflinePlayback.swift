    //
    //  HLSNative+ExposureContext+OfflinePlayback.swift
    //  ExposurePlayback
    //
    //  Created by Udaya Sri Senarathne on 2020-07-30.
    //  Copyright © 2020 emp. All rights reserved.
    //
    
    import Foundation
    import iOSClientPlayer
    import iOSClientExposure
    import AVFoundation
    
    extension Player where Tech == HLSNative<ExposureContext> {
        
        public func startPlayback(offlineMediaPlayable: OfflineMediaPlayable, properties: PlaybackProperties = PlaybackProperties()) {
            context.startOfflineMediaPlayback(offlineMediaPlayable: offlineMediaPlayable, properties: properties, tech: tech)
        }
    }
    
    extension ExposureContext {
        
        
        /// Initiates a playback session with the supplied `OfflineMediaPlayable`
        /// - Parameters:
        ///   - offlineMediaPlayable: EMP `OfflineMediaPlayable` for which to downloaded asset to be play.
        ///   - properties: Properties specifying additional configuration for the playback
        ///   - tech: Tech to do the playback on
        internal func startOfflineMediaPlayback(offlineMediaPlayable: OfflineMediaPlayable, properties: PlaybackProperties, tech: HLSNative<ExposureContext>) {

            playbackProperties = properties
            
            let entitlementResponse = EnigmaPlayable.convertV2EntitlementToV1(entitlementV2: offlineMediaPlayable.entitlement, offlineMediaPlayable)

            
            if let entitlement = entitlementResponse.0 {
                
                let source = ExposureSource(entitlement: entitlement, assetId: offlineMediaPlayable.assetId, response: nil, streamingInfo: offlineMediaPlayable.entitlement.streamInfo)
                
                // onEntitlementResponse(source.entitlement, source)
                
                /// Assign the providers : TODO
                // source.analyticsConnector.providers = providers4
                
                /// Make sure StartTime is configured if specified by user
                tech.startTime(byDelegate: self)
                
                /// Update tech autoplay settings from PlaybackProperties
                tech.autoplay = playbackProperties.autoplay

                /// Assign language preferences
                switch playbackProperties.language {
                case .defaultBehaviour:
                   //  print("context.playbackProperties.language.defaultBehaviour", tech.preferredTextLanguage, tech.preferredAudioLanguage)
                    break
                case .userLocale:
                    let locale = Locale.current.languageCode
                    tech.preferredTextLanguage = locale
                    tech.preferredAudioLanguage = locale
                    
                    // Keep the selected subtitle in the userdefaults for downloaded assets
                    // This is required for fast seeking as AVFoundation can loose the subtitle track sometimes.
                    UserDefaults.standard.set(locale , forKey: "prefferedMediaSelection")
                    
                case let .custom(text: text, audio: audio):
                    tech.preferredAudioLanguage = audio
                    tech.preferredTextLanguage = text
                    
                    // Keep the selected subtitle in the userdefaults for downloaded assets
                    // This is required for fast seeking as AVFoundation can loose the subtitle track sometimes.
                    UserDefaults.standard.set(text , forKey: "prefferedMediaSelection")
                    
                }
                
                /// Create HLS configuration
                let configuration = HLSNativeConfiguration(drm: source.fairplayRequester)
                
                source.prepareSourceUrl{ _ in

                    source.proxyUrl = offlineMediaPlayable.urlAsset.url
                    
                    /// Load tech
                    tech.loadOffline(source: source, configuration: configuration) { [weak self, weak source, weak tech] in
                        
                        guard let `self` = self, let tech = tech, let source = source else {
                            return
                            
                        }
                        /// Start ProgramService
                        self.prepareProgramService(source: source, tech: tech)
                    }
                }
                
                
                // TODO : Analytics
                     /* source.analyticsConnector.providers.forEach{
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

                     } */

                     /// Hook connection changed analytics events
                     /* reachability?.onReachabilityChanged = { [weak tech, weak source] connection in
                         source?.analyticsConnector.providers.forEach{
                             if let exposureAnalytics = $0 as? ExposureAnalytics {
                                 exposureAnalytics.onConnectionChanged(tech: tech, source: source, type: connection)
                             }
                         }
                     } */
                
            }
            
        }
    }
