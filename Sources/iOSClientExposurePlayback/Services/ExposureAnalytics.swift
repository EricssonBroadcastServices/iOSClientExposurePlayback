//
//  ExposureAnalytics.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-17.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import iOSClientPlayer
import iOSClientExposure

#if os(iOS)
import CoreTelephony
#endif


/// `ExposureAnalytics` delivers a complete analytics manager fully integrated with the *EMP* system. It is an extension of the `Player` defined `AnalyticsProvider` protocol customized to fit EMP specifications.
///
/// Designed to work out of the box with `Player`, adopting and using `ExposureAnalytics` is very straight forward:
///
/// ```swift
/// player
///     .analytics(using: sessionToken,
///                in: environment)
///     .stream(vod: assetId) { entitlement, error in
///         // Handle success or error
///     }
/// ```
///
/// - important: *EMP Analytics* is not intended to be used in conjunction with manual requests of *entitlements* or manual initialization of playback. In order to ensure analytics data integrity and consistency, users should adopt the *framework* specific extension-points for initializing playback.
///
/// For further details, please see: `Player` functions `stream(vod: callback:)`, `stream(live: callback:)` and `stream(programId: channelId:)`.
public class ExposureAnalytics {
    /// Tracks the initialization state, optionally storing events created before entitlement request has been made
    fileprivate var startup: Startup = .notStarted(events: [])
    fileprivate enum Startup {
        case notStarted(events: [AnalyticsEvent])
        case started
    }
    
    fileprivate var startupEvents: [AnalyticsEvent] {
        switch startup {
        case .notStarted(events: let events): return events
        case .started: return []
        }
    }
    
    /// Exposure environment used for the active session.
    ///
    /// - Important: should match the `environment` used to authenticate the user.
    public let environment: Environment
    
    /// Token identifying the active session.
    ///
    /// - Important: should match the `environment` used to authenticate the user.
    public let sessionToken: SessionToken
    
    public let analyticsBaseUrl: String?
    
    // the official name of the app
    public let appName: String?
    
    /// `Dispatcher` takes care of delivering analytics payload.
    fileprivate(set) internal var dispatcher: Dispatcher?
    
    public let cdn:CDNInfoFromEntitlement?
    
    public let analytics: AnalyticsFromEntitlement?
    
    public required init(environment: Environment, sessionToken: SessionToken, cdn: CDNInfoFromEntitlement? = nil , analytics: AnalyticsFromEntitlement? = nil, analyticsBaseUrl: String?, appName: String? = nil ) {
        self.environment = environment
        self.sessionToken = sessionToken
        self.cdn = cdn
        self.analytics = analytics
        self.analyticsBaseUrl = analyticsBaseUrl
        self.appName = appName
    }
    
    public var onExposureResponseMessage: (ExposureResponseMessage) -> Void = { _ in }
    
    deinit {
        print("ExposureAnalytics.deinit")
        dispatcher?.flushTrigger(enabled: false)
        dispatcher?.terminate()
    }
    
    /// External playback mode
    internal enum ExternalPlayback {
        case none
        case chromecast
        case endedCasting
        case endedByActivatingAirplay
        case startedAsAirplay
    }
    /// Tracks if external playback was started
    internal var externalPlayback: ExternalPlayback = .none
    
    /// ProgramChanged events are sent as soon as an Epg has been detected. We should not send `Playback.ProgramChanged` for this initial "onProgramChanged` event since the request was made for that program.
    internal var lastKnownProgramId: String? = nil
    
    /// If the playback session failed with an error from Exposure (ie an ExposureResponseMessage, for example NOT_ENTITLED), no Source object is created. This means we need to set the `X-Request-Id` before we finalize the session.
    internal var exposureEntitlementHTTPURLResponse: HTTPURLResponse?
    
    /// Instruct the analytics engine that the player is transitioning from local playback to `ChromeCasting`
    public func startedCasting() {
        externalPlayback = .chromecast
    }
    
    public func StopCasting() {
        externalPlayback = .endedCasting
    }
    
    /// Instruct the analytics engine that the player is transitioning from local playback to `Airplay`
    public func startedAirplay() {
        externalPlayback = .endedByActivatingAirplay
    }
    
    
    
    /// Exposure Analytics related `Server Side Ads`
    /// - Parameters:
    ///   - tech: tech
    ///   - source: source
    ///   - adMediaId: adMediaId
    public func onAdStarted<Tech, Source>(tech: Tech, source: Source, adMediaId: String) where Tech : PlaybackTech, Source : MediaSource {
        if let source = source as? ExposureSource {
            let event = Playback.AdStarted(timestamp: Date().millisecondsSince1970,
                                           offsetTime: offsetTime(for: source, using: tech), adMediaId: adMediaId,
                                         cdnInfo: source.entitlement.cdn,
                                         analyticsInfo: source.entitlement.analytics)
            dispatcher?.enqueue(event: event)
        } else {
            let event = Playback.AdStarted(timestamp: Date().millisecondsSince1970,
                                          offsetTime: offsetTime(for: source, using: tech), adMediaId: adMediaId)
            dispatcher?.enqueue(event: event)
        }
    }
    
    public func onAdCompleted<Tech, Source>(tech: Tech, source: Source, adMediaId: String) where Tech : PlaybackTech, Source : MediaSource {
        if let source = source as? ExposureSource {
            let event = Playback.AdCompleted(timestamp: Date().millisecondsSince1970,
                                           offsetTime: offsetTime(for: source, using: tech), adMediaId: adMediaId,
                                         cdnInfo: source.entitlement.cdn,
                                         analyticsInfo: source.entitlement.analytics)
            dispatcher?.enqueue(event: event)
        } else {
            let event = Playback.AdCompleted(timestamp: Date().millisecondsSince1970,
                                          offsetTime: offsetTime(for: source, using: tech), adMediaId: adMediaId)
            dispatcher?.enqueue(event: event)
        }
    }
    
    public func onAdFailed<Tech, Source>(tech: Tech, source: Source, adMediaId: String) where Tech : PlaybackTech, Source : MediaSource {
        if let source = source as? ExposureSource {
            let event = Playback.AdFailed(timestamp: Date().millisecondsSince1970,
                                           offsetTime: offsetTime(for: source, using: tech), adMediaId: adMediaId,
                                         cdnInfo: source.entitlement.cdn,
                                         analyticsInfo: source.entitlement.analytics)
            dispatcher?.enqueue(event: event)
        } else {
            let event = Playback.AdFailed(timestamp: Date().millisecondsSince1970,
                                          offsetTime: offsetTime(for: source, using: tech), adMediaId: adMediaId)
            dispatcher?.enqueue(event: event)
        }
    }
}

fileprivate func version(for identifier: String?) -> String {
    guard let identifier = identifier else { return "MISSING_BUNDLE_IDENTIFIER" }
    guard let bundleInfo = Bundle(identifier: identifier)?.infoDictionary else { return "BUNDLE_NOT_FOUND" }
    let version = (bundleInfo["CFBundleShortVersionString"] as? String) ?? "UNKNOWN_VERSION"
    
    return version
}

extension ExposureAnalytics {
    fileprivate func offsetTime<Source: MediaSource, Tech : PlaybackTech>(for source: Source?, using tech: Tech?) -> Int64? {
        guard let tech = tech, let source = source else { return nil }
        guard let exposureSource = source as? ExposureSource else {
            // Default to playheadPosition
            return tech.playheadPosition
        }
        
        if exposureSource.isUnifiedPackager {
            if exposureSource is ChannelSource {
                return tech.playheadTime
            }
            else if exposureSource is ProgramSource {
                return tech.playheadTime
            }
            else if exposureSource is AssetSource {
                return tech.playheadPosition
            }
        }
        return tech.playheadPosition
    }
}

import AVFoundation
extension ExposureAnalytics: ExposureStreamingAnalyticsProvider {
    private func autoplay<Tech>(tech: Tech) -> Bool {
        if let tech = tech as? MediaPlayback {
            return tech.autoplay
        }
        return false
    }
    
    public func onEntitlementRequested<Tech, Source>(tech: Tech, source: Source, playable: Playable) where Tech : PlaybackTech, Source : MediaSource {
        
        if let source = source as? ExposureSource {
            /// 1. Created
            let created = Playback.Created(timestamp: Date().millisecondsSince1970,
                                           version: version(for: "com.emp.ExposurePlayback"),
                                           exposureVersion: version(for: "com.emp.Exposure"),
                                           assetData: PlaybackIdentifier.from(playable: playable),
                                           autoPlay: autoplay(tech: tech), analyticsInfo: source.entitlement.analytics)
            
            
            /// BUGFIX: EMP-11313
            /// `Bundle(for: aClass)`
            ///
            /// The NSBundle object that dynamically loaded aClass (a loadable bundle), the NSBundle object for the framework in which aClass is defined, or the main bundle object if aClass was not dynamically loaded or is not defined in a framework.
            ///
            /// TODO: Introduce a `version` property on `PlaybackTech` for a more robust solution
            let techBundle = (tech is HLSNative<ExposureContext>) ? "com.emp.Player" : Bundle(for: type(of: tech)).bundleIdentifier
        
            
            /// 2. DeviceInfo
            let connectionType = networkTech(connection: (Reachability()?.connection ?? Reachability.Connection.unknown))
            /// EMP-11647: If this is an Airplay session, set `Playback.Device.Info.type = AirPlay`
            let deviceInfo = DeviceInfo(timestamp: Date().millisecondsSince1970, connection: connectionType, type: isAirplaySession, tech: String(describing: type(of: tech)),techVersion: version(for: techBundle), analyticsInfo: source.entitlement.analytics, appName: appName)
            
            /// 3. Store startup events
            var current = startupEvents
            current.append(created)
            current.append(deviceInfo)
            startup = .notStarted(events: current)
        } else {
            /// 1. Created
            let created = Playback.Created(timestamp: Date().millisecondsSince1970,
                                           version: version(for: "com.emp.ExposurePlayback"),
                                           exposureVersion: version(for: "com.emp.Exposure"),
                                           assetData: PlaybackIdentifier.from(playable: playable),
                                           autoPlay: autoplay(tech: tech), analyticsInfo: nil)
            
            
            /// BUGFIX: EMP-11313
            /// `Bundle(for: aClass)`
            ///
            /// The NSBundle object that dynamically loaded aClass (a loadable bundle), the NSBundle object for the framework in which aClass is defined, or the main bundle object if aClass was not dynamically loaded or is not defined in a framework.
            ///
            /// TODO: Introduce a `version` property on `PlaybackTech` for a more robust solution
            let techBundle = (tech is HLSNative<ExposureContext>) ? "com.emp.Player" : Bundle(for: type(of: tech)).bundleIdentifier
        
            
            /// 2. DeviceInfo
            let connectionType = networkTech(connection: (Reachability()?.connection ?? Reachability.Connection.unknown))
            /// EMP-11647: If this is an Airplay session, set `Playback.Device.Info.type = AirPlay`
            let deviceInfo = DeviceInfo(timestamp: Date().millisecondsSince1970, connection: connectionType, type: isAirplaySession, tech: String(describing: type(of: tech)),techVersion: version(for: techBundle), analyticsInfo: nil, appName: appName)
            
            /// 3. Store startup events
            var current = startupEvents
            current.append(created)
            current.append(deviceInfo)
            startup = .notStarted(events: current)
        }

    }
    
    public func onHandshakeStarted<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        if let source = source as? ExposureSource {
            let event = Playback.HandshakeStarted(timestamp: Date().millisecondsSince1970,
                                                  assetData: PlaybackIdentifier.from(source: source), cdnInfo: source.entitlement.cdn, analyticsInfo: source.entitlement.analytics)
            
            /// 3. Store startup events
            var current = startupEvents
            current.append(event)
            startup = .notStarted(events: current)
        }
    }
    
    /// Prepares and configures the remaining parts of the Analytics environment.
    /// This step is required because we are dependant on the response from Exposure with regards to the playSessionId. Further more, some analytics events may need to be generated before hand. These are supplied as `startupEvents`.
    ///
    /// Once this is called, a Dispatcher is associated with the session.
    ///
    /// - parameter playSessionId: Unique identifier for the current playback session.
    /// - parameter asset: *EMP* asset identifiers.
    /// - parameter entitlement: The entitlement this session concerns
    /// - parameter heartbeatsProvider: Will deliver heartbeats metadata during the session
    public func finalizePreparation<Tech, Source>(tech: Tech, source: Source, playSessionId: String, heartbeatsProvider: @escaping () -> AnalyticsEvent?) where Tech : PlaybackTech, Source : MediaSource {
        let events = extractAndPrepareStartupEvents(source: source)
        
        if let tech = tech as? HLSNative<ExposureContext>, tech.isExternalPlaybackActive {
            /// Session was started with Airplay active. This session should be terminated with ´Playback.StopAirplay`
            externalPlayback = .startedAsAirplay
        }
        
        dispatcher = Dispatcher(environment: environment,
                                sessionToken: sessionToken,
                                playSessionId: playSessionId,
                                startupEvents: events,
                                heartbeatsProvider: heartbeatsProvider, analyticsBaseUrl: analyticsBaseUrl)
        dispatcher?.requestId = extractRequestId(source: source)
        dispatcher?.onExposureResponseMessage = { [weak self] message in
            self?.onExposureResponseMessage(message)
        }
        dispatcher?.flushTrigger(enabled: true)
    }
    
    
    public func onProgramChanged<Tech, Source>(tech: Tech, source: Source, program: Program?) where Tech: PlaybackTech, Source: MediaSource {
        if let programId = program?.programId, lastKnownProgramId != nil {
            
            if let source = source as? ExposureSource {
                let event = Playback.ProgramChanged(timestamp: Date().millisecondsSince1970,
                                                    offsetTime: offsetTime(for: source, using: tech),
                                                    programId: programId,
                                                    videoLength: tech.duration, cdnInfo: source.entitlement.cdn, analyticsInfo: source.entitlement.analytics)
                dispatcher?.enqueue(event: event)
            } else {
                let event = Playback.ProgramChanged(timestamp: Date().millisecondsSince1970,
                                                    offsetTime: offsetTime(for: source, using: tech),
                                                    programId: programId,
                                                    videoLength: tech.duration)
                dispatcher?.enqueue(event: event)
            }
            
        }
        lastKnownProgramId = program?.programId
    }
}
extension URL {
    func cleanQuery() -> String? {
        if var urlcomponents = URLComponents(url: self, resolvingAgainstBaseURL: false) {
            urlcomponents.query = nil
            return urlcomponents.string
        }
        return nil
    }
}

extension ExposureAnalytics {
    /// Returns the `X-Request-Id` associated with the response generated when requesting an entitlement.
    fileprivate func extractRequestId<Source>(source: Source?) -> String? where Source: MediaSource {
        /// First, try extracting from the source
        guard let exposureSource = source as? ExposureSource else {
            /// If no source is available this might be an error session. This means no Source was created. Check if we set the response headers from the Exposure request HTTPURLResponse previously.
            return exposureEntitlementHTTPURLResponse?.allHeaderFields["X-Request-Id"] as? String
        }
        return exposureSource.entitlementSourceResponseHeaders["X-Request-Id"]
    }
    
    /// Modify the existing startup events to include `X-Request-Id` in `Playback.Created` event.
    fileprivate func extractAndPrepareStartupEvents<Source>(source: Source?) -> [AnalyticsEvent] where Source: MediaSource {
        return startupEvents.map{ e -> AnalyticsEvent in
            if var event = e as? Playback.Created, let requestId = extractRequestId(source: source) {
                event.requestId = requestId
                return event
            }
            else {
                return e
            }
        }
    }
}

extension ExposureAnalytics {
    /// Returns an indcation if Airplay is active.
    fileprivate var isAirplaySession: String? {
        /// EMP-11647: If this is an Airplay session, return `AVAudioSessionPortAirPlay`
        let connectedAirplayPorts = AVAudioSession.sharedInstance().currentRoute.outputs.filter{ $0.portType == AVAudioSession.Port.airPlay }
        return !connectedAirplayPorts.isEmpty ? AVAudioSession.Port.airPlay.rawValue : nil
    }
}

extension ExposureAnalytics: AnalyticsProvider {
    public func onCreated<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        /// Created/DeviceInfo/Handshake will be sent before entitlement request
    }

    public func onPrepared<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        /// InitCompleted
        
        /// EMP-16272 : Remove player analytics init call
        /* let event = Playback.InitCompleted(timestamp: Date().millisecondsSince1970, cdnInfo: (source as? ExposureSource)?.entitlement.cdn, analyticsInfo: (source as? ExposureSource)?.entitlement.analytics)
        dispatcher?.enqueue(event: event) */
    }
    
    public func onReady<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        
        /// PlayReady
        /// EMP-11666: Send `X-Playback-Session-Id` as assigned by AVPlayer in order to track segment and manifest request
        let segmentRequestId = (source as? MediaSourceRequestHeaders)?.mediaSourceRequestHeaders["X-Playback-Session-Id"]
        
        /// BUGFIX: EMP-11313
        /// `Bundle(for: aClass)`
        ///
        /// The NSBundle object that dynamically loaded aClass (a loadable bundle), the NSBundle object for the framework in which aClass is defined, or the main bundle object if aClass was not dynamically loaded or is not defined in a framework.
        ///
        /// TODO: Introduce a `version` property on `PlaybackTech` for a more robust solution
        let techBundle = (tech is HLSNative<ExposureContext>) ? "com.emp.Player" : Bundle(for: type(of: tech)).bundleIdentifier
        
        if let source = source as? ExposureSource {
            let event = Playback.PlayReady(timestamp: Date().millisecondsSince1970,
                                           offsetTime: offsetTime(for: source, using: tech),
                                           tech: String(describing: type(of: tech)),
                                           techVersion: version(for: techBundle),
                                           segmentRequestId: segmentRequestId,
                                           cdnInfo: source.entitlement.cdn,
                                           analyticsInfo: source.entitlement.analytics)
            dispatcher?.enqueue(event: event)
        } else {
            let event = Playback.PlayReady(timestamp: Date().millisecondsSince1970,
                                           offsetTime: offsetTime(for: source, using: tech),
                                           tech: String(describing: type(of: tech)),
                                           techVersion: version(for: techBundle),
                                           segmentRequestId: segmentRequestId)
            dispatcher?.enqueue(event: event)
        }
        
    }
    
    public func onStarted<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        if let source = source as? ExposureSource {
            /// EMP-11666: Send `X-Playback-Session-Id` as assigned by AVPlayer in order to track segment and manifest request
            let segmentRequestId = source.mediaSourceRequestHeaders["X-Playback-Session-Id"]
            
            let referenceTime:Int64? = source.isUnifiedPackager ? 0 : nil
            let event = Playback.Started(timestamp: Date().millisecondsSince1970,
                                         assetData: PlaybackIdentifier.from(source: source),
                                         mediaLocator: source.entitlement.mediaLocator.absoluteString,
                                         offsetTime: offsetTime(for: source, using: tech),
                                         videoLength: tech.duration,
                                         bitrate: tech.currentBitrate != nil ? Int64(tech.currentBitrate!/1000) : nil,
                                         referenceTime: referenceTime,
                                         segmentRequestId: segmentRequestId,
                                         cdnInfo: source.entitlement.cdn,
                                         analyticsInfo: source.entitlement.analytics)
            dispatcher?.enqueue(event: event)
            dispatcher?.heartbeat(enabled: true)
        }
    }
    
    public func onPaused<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        if let source = source as? ExposureSource {
            let event = Playback.Paused(timestamp: Date().millisecondsSince1970,
                                        offsetTime: offsetTime(for: source, using: tech), cdnInfo: source.entitlement.cdn, analyticsInfo: source.entitlement.analytics)
            dispatcher?.enqueue(event: event)
        } else {
            let event = Playback.Paused(timestamp: Date().millisecondsSince1970,
                                        offsetTime: offsetTime(for: source, using: tech))
            dispatcher?.enqueue(event: event)
        }
        
    }
    
    public func onResumed<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        if let source = source as? ExposureSource {
            let event = Playback.Resumed(timestamp: Date().millisecondsSince1970,
                                         offsetTime: offsetTime(for: source, using: tech), cdnInfo: source.entitlement.cdn, analyticsInfo: source.entitlement.analytics)
            dispatcher?.enqueue(event: event)
        } else {
            let event = Playback.Resumed(timestamp: Date().millisecondsSince1970,
                                         offsetTime: offsetTime(for: source, using: tech))
            dispatcher?.enqueue(event: event)
        }
        
    }
    
    public func onAborted<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        defer {
            dispatcher?.heartbeat(enabled: false)
            dispatcher?.flushTrigger(enabled: false)
            dispatcher = nil
        }
        
        switch externalPlayback {
        case .endedByActivatingAirplay:
            if let source = source as? ExposureSource {
                let event = Playback.StartAirplay(timestamp: Date().millisecondsSince1970,
                                                  offsetTime: offsetTime(for: source, using: tech), cdnInfo: source.entitlement.cdn, analyticsInfo: source.entitlement.analytics)
                dispatcher?.enqueue(event: event)
            } else {
                let event = Playback.StartAirplay(timestamp: Date().millisecondsSince1970,
                                                  offsetTime: offsetTime(for: source, using: tech))
                dispatcher?.enqueue(event: event)
            }
        case .startedAsAirplay:
            if let source = source as? ExposureSource {
                let event = Playback.StopAirplay(timestamp: Date().millisecondsSince1970,
                                                 offsetTime: offsetTime(for: source, using: tech), cdnInfo: source.entitlement.cdn, analyticsInfo: source.entitlement.analytics)
                dispatcher?.enqueue(event: event)
            } else {
                let event = Playback.StopAirplay(timestamp: Date().millisecondsSince1970,
                                                 offsetTime: offsetTime(for: source, using: tech))
                dispatcher?.enqueue(event: event)
            }
            
        case .chromecast:
            if let source = source as? ExposureSource {
                let event = Playback.StartCasting(timestamp: Date().millisecondsSince1970,
                                                  offsetTime: offsetTime(for: source, using: tech), cdnInfo: source.entitlement.cdn, analyticsInfo: source.entitlement.analytics)
                dispatcher?.enqueue(event: event)
            } else {
                let event = Playback.StartCasting(timestamp: Date().millisecondsSince1970,
                                                  offsetTime: offsetTime(for: source, using: tech))
                dispatcher?.enqueue(event: event)
            }
        case .endedCasting:
            if let source = source as? ExposureSource {
                let event = Playback.StopCasting(timestamp: Date().millisecondsSince1970,
                                                  offsetTime: offsetTime(for: source, using: tech), cdnInfo: source.entitlement.cdn, analyticsInfo: source.entitlement.analytics)
                dispatcher?.enqueue(event: event)
            } else {
                let event = Playback.StopCasting(timestamp: Date().millisecondsSince1970,
                                                  offsetTime: offsetTime(for: source, using: tech))
                dispatcher?.enqueue(event: event)
            }
        case .none:
            if let source = source as? ExposureSource {
                let event = Playback.Aborted(timestamp: Date().millisecondsSince1970,
                                             offsetTime: offsetTime(for: source, using: tech), cdnInfo: source.entitlement.cdn , analyticsInfo: source.entitlement.analytics)
                dispatcher?.enqueue(event: event)
            } else {
                let event = Playback.Aborted(timestamp: Date().millisecondsSince1970,
                                             offsetTime: offsetTime(for: source, using: tech))
                dispatcher?.enqueue(event: event)
            }
            
        
        }
    }
    
    public func onCompleted<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        if let source = source as? ExposureSource {
            let event = Playback.Completed(timestamp: Date().millisecondsSince1970,
                                           offsetTime: offsetTime(for: source, using: tech), cdnInfo: source.entitlement.cdn, analyticsInfo: source.entitlement.analytics)
            dispatcher?.enqueue(event: event)
            dispatcher?.flushTrigger(enabled: false)
            dispatcher?.heartbeat(enabled: false)
            dispatcher = nil
            (tech as? HLSNative<ExposureContext>)?.stop()
        } else {
            let event = Playback.Completed(timestamp: Date().millisecondsSince1970,
                                           offsetTime: offsetTime(for: source, using: tech))
            dispatcher?.enqueue(event: event)
            dispatcher?.flushTrigger(enabled: false)
            dispatcher?.heartbeat(enabled: false)
            dispatcher = nil
            (tech as? HLSNative<ExposureContext>)?.stop()
        }
    }
    
    public func onError<Tech, Source, Context>(tech: Tech?, source: Source?, error: PlayerError<Tech, Context>) where Tech : PlaybackTech, Source : MediaSource, Context : MediaContext {
        guard let dispatcher = dispatcher else {
            finalizeWithError(tech: tech, source: source, error: error)
            return
        }
        
        let event = buildPlaybackErrorEvent(tech: tech, source: source, error: error)
        dispatcher.enqueue(event: event)
        dispatcher.heartbeat(enabled: false)
        dispatcher.flushTrigger(enabled: false)
        // Terminate the Dispatcher. This will cause no more events to be sent on this playback session.
        self.dispatcher = nil
    }
    
    private func buildPlaybackErrorEvent<Tech, Source, Context>(tech: Tech?, source: Source?, error: PlayerError<Tech, Context>) -> Playback.Error where Tech : PlaybackTech, Source : MediaSource, Context : MediaContext {
        let timestamp = Date().millisecondsSince1970
        let offset = offsetTime(for: source, using: tech)
        
        let structure = buildErrorStructure(hierarchy: [], nextError: error)
        
        var techBundle = ""
        if let technology = tech {
            techBundle = ((technology is HLSNative<ExposureContext>) ? "com.emp.Player" : Bundle(for: type(of: technology)).bundleIdentifier) ?? ""
        }
        
        guard let rootError = structure.0.last else {
            return Playback.Error(timestamp: timestamp,
                                  offsetTime: offset,
                                  message: error.message,
                                  code: error.code,
                                  info: nil,
                                  details: error.info,
                                  tech: String(describing: type(of: tech)),
                                  techVersion: version(for: techBundle),
                                  cdnInfo: (source as? ExposureSource)?.entitlement.cdn, analyticsInfo: (source as? ExposureSource)?.entitlement.analytics)
        }
        
        let hierarchy = structure.0.map{ "\($0):" + $1 }.joined(separator: " << ")
        
        return Playback.Error(timestamp: timestamp,
                              offsetTime: offset,
                              message: structure.1,
                              code: rootError.0,
                              info: hierarchy,
                              details: error.info,
                              tech: String(describing: type(of: tech)),
                              techVersion: version(for: techBundle),
                              cdnInfo: (source as? ExposureSource)?.entitlement.cdn, analyticsInfo: (source as? ExposureSource)?.entitlement.analytics)
    }
    
    private func buildErrorStructure(hierarchy: [(Int, String)], nextError error: Error) -> ([(Int, String)], String) {
        var result = hierarchy
        if let exposureError = error as? ExposureError {
            result.append((exposureError.code, exposureError.domain))
            if let underlyingError = exposureError.underlyingError {
                return buildErrorStructure(hierarchy: result, nextError: underlyingError)
            }
            return (result, exposureError.message)
        }
        else if let expanded = error as? ExpandedError {
            result.append((expanded.code, expanded.domain))
            if let underlyingError = expanded.underlyingError {
                return buildErrorStructure(hierarchy: result, nextError: underlyingError)
            }
            return (result, expanded.message)
        }
        else if let expanded = error as? iOSClientExposure.Request.Networking {
            result.append((expanded.code, expanded.domain))
            return (result, expanded.message)
        }
        else if let nsError = error as? NSError {
            result.append((nsError.code, nsError.domain))
            if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
                return buildErrorStructure(hierarchy: result, nextError: underlyingError)
            }
            return (result, nsError.domain)
        }
        else {
            result.append((-999, "UNKNOWN_DOMAIN"))
            return (result, "UNKNOWN_ERROR")
        }
    }
    
    
    /// Delivers errors received while trying to finalize a session.
    ///
    /// - parameter error: The encountered error.
    /// - parameter startupEvents: Events `ExposureAnalytics` should deliver as the initial payload related to the error in question.
    fileprivate func finalizeWithError<Tech, Source, Context>(tech: Tech?, source: Source?, error: PlayerError<Tech, Context>) where Tech : PlaybackTech, Source : MediaSource, Context : MediaContext {
        var events = extractAndPrepareStartupEvents(source: source)
        
        let errorPayload = buildPlaybackErrorEvent(tech: tech, source: source, error: error)
        
        events.append(errorPayload)
        
        dispatcher = Dispatcher(environment: environment,
                                sessionToken: sessionToken,
                                playSessionId: UUID().uuidString,
                                startupEvents: events,
                                heartbeatsProvider: { return nil },
                                analyticsBaseUrl: analyticsBaseUrl)
        dispatcher?.requestId = extractRequestId(source: source)
        
        dispatcher?.flushTrigger(enabled: false)
        dispatcher?.heartbeat(enabled: false)
        dispatcher = nil
    }
    
    public func onBitrateChanged<Tech, Source>(tech: Tech, source: Source, bitrate: Double) where Tech : PlaybackTech, Source : MediaSource {
        if let source = source as? ExposureSource {
            let analyticsEvent = Playback.BitrateChanged(timestamp: Date().millisecondsSince1970,
                                                         offsetTime: offsetTime(for: source, using: tech),
                                                         bitrate: Int64(bitrate/1000), cdnInfo: source.entitlement.cdn, analyticsInfo: source.entitlement.analytics)
            dispatcher?.enqueue(event: analyticsEvent)
        } else {
            let analyticsEvent = Playback.BitrateChanged(timestamp: Date().millisecondsSince1970,
                                                         offsetTime: offsetTime(for: source, using: tech),
                                                         bitrate: Int64(bitrate/1000))
            dispatcher?.enqueue(event: analyticsEvent)
        }
        
    }
    
    public func onBufferingStarted<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        if let source = source as? ExposureSource {
            let event = Playback.BufferingStarted(timestamp: Date().millisecondsSince1970,
                                                  offsetTime: offsetTime(for: source, using: tech), cdnInfo: source.entitlement.cdn, analyticsInfo: source.entitlement.analytics)
            dispatcher?.enqueue(event: event)
        } else {
            let event = Playback.BufferingStarted(timestamp: Date().millisecondsSince1970,
                                                  offsetTime: offsetTime(for: source, using: tech))
            dispatcher?.enqueue(event: event)
        }
        
    }
    
    public func onBufferingStopped<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        if let source = source as? ExposureSource {
            let event = Playback.BufferingStopped(timestamp: Date().millisecondsSince1970,
                                                  offsetTime: offsetTime(for: source, using: tech), cdnInfo: source.entitlement.cdn, analyticsInfo: source.entitlement.analytics)
            dispatcher?.enqueue(event: event)
        } else {
            let event = Playback.BufferingStopped(timestamp: Date().millisecondsSince1970,
                                                  offsetTime: offsetTime(for: source, using: tech))
            dispatcher?.enqueue(event: event)
        }
        
    }
    
    public func onScrubbedTo<Tech, Source>(tech: Tech, source: Source, offset: Int64) where Tech : PlaybackTech, Source : MediaSource {
        /// BUGFIX: EMP-11909: `ProgramSource`s and `ChannelSource`s are seekable with zero-based buffer position offset. This causes the related callback to be fired with that zero based target which is not what we want to deliver to analytics.
        ///
        /// In order to fix this we simply disregard the supplied `offset` as this might be delivered as a zero-based buffer position for `ProgramSource` and `ChannelSource` playback. Instead, we try to extract the current offsetTime (based on the Source type ie playheadTime for ProgramSource and ChannelSource) which should be close to or equal to the requested offset.
        ///
        /// If no such offset is available, we dispatch no offset
        
        if let source = source as? ExposureSource {
            let usedOffset = offsetTime(for: source, using: tech)
            let event = Playback.ScrubbedTo(timestamp: Date().millisecondsSince1970,
                                            offsetTime: usedOffset, cdnInfo: source.entitlement.cdn, analyticsInfo: source.entitlement.analytics)
            dispatcher?.enqueue(event: event)
        } else {
            let usedOffset = offsetTime(for: source, using: tech)
            let event = Playback.ScrubbedTo(timestamp: Date().millisecondsSince1970,
                                            offsetTime: usedOffset)
            dispatcher?.enqueue(event: event)
        }
        
    }
    
    public func onDurationChanged<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        
    }
    
    public func onWarning<Tech, Source, Context>(tech: Tech, source: Source?, warning: PlayerWarning<Tech, Context>) where Tech : PlaybackTech, Source : MediaSource, Context : MediaContext {
        
    }
}

/// MARK: TraceProvider
extension ExposureAnalytics: TraceProvider {
    public func onTrace<Tech, Source>(tech: Tech?, source: Source?, data: [String: Any]) where Tech : PlaybackTech, Source : MediaSource {
        if let source = source as? ExposureSource {
            let event = Playback.Trace(timestamp: Date().millisecondsSince1970,
                                       offsetTime: offsetTime(for: source, using: tech),
                                       data: data, cdnInfo: source.entitlement.cdn, analyticsInfo: source.entitlement.analytics)
            dispatcher?.enqueue(event: event)
        } else {
            let event = Playback.Trace(timestamp: Date().millisecondsSince1970,
                                       offsetTime: offsetTime(for: source, using: tech),
                                       data: data)
            dispatcher?.enqueue(event: event)
        }
        
       
    }
}


/// MARK: TechDeallocationEventProvider
extension ExposureAnalytics: TechDeallocationEventProvider {
    public func onTechDeallocated<Source>(beforeMediaPreparationFinalizedOf mediaSource: Source) where Source : MediaSource {
        let data = ["Message":"TECH_DEALLOCATED_BEFORE_MEDIA_PREPARATION_FINISHED"]
        let trace = Playback.Trace(timestamp: Date().millisecondsSince1970,
                                   data: data)
        if let source = mediaSource as? ExposureSource {
            let aborted = Playback.Aborted(timestamp: Date().millisecondsSince1970, cdnInfo: source.entitlement.cdn, analyticsInfo: source.entitlement.analytics)
            dispatcher?.enqueue(event: trace)
            dispatcher?.enqueue(event: aborted)
            dispatcher?.heartbeat(enabled: false)
            dispatcher?.flushTrigger(enabled: false)
            dispatcher = nil
        } else {
            let aborted = Playback.Aborted(timestamp: Date().millisecondsSince1970)
            
            dispatcher?.enqueue(event: trace)
            dispatcher?.enqueue(event: aborted)
            dispatcher?.heartbeat(enabled: false)
            dispatcher?.flushTrigger(enabled: false)
            dispatcher = nil
        }
       
    }
}

/// MARK: DrmAnalyticsProvider
extension ExposureAnalytics: DrmAnalyticsProvider {
    func onCertificateRequest<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        if let source = source as? ExposureSource {
            let event = Playback.DRM(timestamp: Date().millisecondsSince1970, message: .certificateRequest, info: source.entitlement.fairplay?.certificateUrl, cdnInfo: source.entitlement.cdn, analyticsInfo: source.entitlement.analytics)
            dispatcher?.enqueue(event: event)
        } else {
            let event = Playback.DRM(timestamp: Date().millisecondsSince1970, message: .certificateRequest, info: (source as? ExposureSource)?.entitlement.fairplay?.certificateUrl)
            dispatcher?.enqueue(event: event)
        }
        
    }
    
    func onCertificateResponse<Tech, Source>(tech: Tech, source: Source, error: ExposureContext.Error?) where Tech : PlaybackTech, Source : MediaSource {
        
        if let error = error {
            let event = Playback.DRM(timestamp: Date().millisecondsSince1970, message: .certificateError, code: error.code, info: error.info, cdnInfo: (source as? ExposureSource)?.entitlement.cdn, analyticsInfo: (source as? ExposureSource)?.entitlement.analytics)
            dispatcher?.enqueue(event: event)
        }
        else {
            let event = Playback.DRM(timestamp: Date().millisecondsSince1970, message: .certificateResponse, cdnInfo: (source as? ExposureSource)?.entitlement.cdn, analyticsInfo: (source as? ExposureSource)?.entitlement.analytics)
            dispatcher?.enqueue(event: event)
        }
    }
    
    func onLicenseRequest<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        let event = Playback.DRM(timestamp: Date().millisecondsSince1970, message: .licenseRequest, info: (source as? ExposureSource)?.entitlement.fairplay?.licenseAcquisitionUrl, cdnInfo: (source as? ExposureSource)?.entitlement.cdn, analyticsInfo: (source as? ExposureSource)?.entitlement.analytics)
        dispatcher?.enqueue(event: event)
    }
    
    func onLicenseResponse<Tech, Source>(tech: Tech, source: Source, error: ExposureContext.Error?) where Tech : PlaybackTech, Source : MediaSource {
        if let error = error {
            let event = Playback.DRM(timestamp: Date().millisecondsSince1970, message: .licenseError, code: error.code, info: error.info, cdnInfo: (source as? ExposureSource)?.entitlement.cdn, analyticsInfo: (source as? ExposureSource)?.entitlement.analytics)
            dispatcher?.enqueue(event: event)
        }
        else {
            let event = Playback.DRM(timestamp: Date().millisecondsSince1970, message: .licenseResponse, cdnInfo: (source as? ExposureSource)?.entitlement.cdn, analyticsInfo: (source as? ExposureSource)?.entitlement.analytics)
            dispatcher?.enqueue(event: event)
        }
    }
}


extension ExposureAnalytics: SourceAbandonedEventProvider {
    public func onSourcePreparationAbandoned<Tech, Source>(ofSource mediaSource: Source, byTech tech: Tech) where Tech : PlaybackTech, Source : MediaSource {
        let data = ["Message":"SOURCE_PREPARATION_ABANDONED"]
        let trace = Playback.Trace(timestamp: Date().millisecondsSince1970,
                                   data: data, cdnInfo: (mediaSource as? ExposureSource)?.entitlement.cdn, analyticsInfo: (mediaSource as? ExposureSource)?.entitlement.analytics)
        
        dispatcher?.enqueue(event: trace)
        onAborted(tech: tech, source: mediaSource)
    }
}

extension ExposureAnalytics {
    /// Should be called whenever changes in the connection status is detected
    ///
    /// - parameters:
    ///     - tech: the tech currently playing `source`
    ///     - source: the source under playback when the connection change occured
    ///     - type: connection type changed to
    internal func onConnectionChanged<Tech, Source>(tech: Tech?, source: Source?, type: Reachability.Connection) where Tech : PlaybackTech, Source : MediaSource {
        let event = Playback.ConnectionChanged(timestamp: Date().millisecondsSince1970, connection: networkTech(connection: type), offsetTime: offsetTime(for: source, using: tech), cdnInfo: (source as? ExposureSource)?.entitlement.cdn, analyticsInfo: (source as? ExposureSource)?.entitlement.analytics)
        dispatcher?.enqueue(event: event)
    }
    
    internal func networkTech(connection: Reachability.Connection) -> String {
        switch connection {
        case .cellular:
            #if os(iOS)
            return CTTelephonyNetworkInfo().currentRadioAccessTechnology ?? connection.description
            #elseif os(tvOS)
            return connection.description
            #endif
        case .none: return connection.description
        case .unknown: return connection.description
        case .wifi: return connection.description
        }
    }
}
