//
//  ExposureAnalytics.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-17.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Player
import Exposure

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
    
    /// `Dispatcher` takes care of delivering analytics payload.
    fileprivate(set) internal var dispatcher: Dispatcher?
    
    public required init(environment: Environment, sessionToken: SessionToken) {
        self.environment = environment
        self.sessionToken = sessionToken
    }
    
    deinit {
        print("ExposureAnalytics.deinit")
        dispatcher?.flushTrigger(enabled: false)
        dispatcher?.terminate()
    }
    
    /// Tracks if chromecasting was started
    internal var startedChromeCasting = false
    
    /// ProgramChanged events are sent as soon as an Epg has been detected. We should not send `Playback.ProgramChanged` for this initial "onProgramChanged` event since the request was made for that program.
    internal var lastKnownProgramId: String? = nil
    
    /// Instruct the player is transitioning from local playback to `ChromeCasting`
    public func startedCasting() {
        startedChromeCasting = true
    }
}

fileprivate func version(for identifier: String) -> String {
    guard let bundleInfo = Bundle(identifier: identifier)?.infoDictionary else { return "Not found" }
    
    let version = (bundleInfo["CFBundleShortVersionString"] as? String) ?? ""
    guard let build = bundleInfo["CFBundleVersion"] as? String else {
        return version
    }
    return version + "." + build
}

extension ExposureAnalytics {
    fileprivate func offsetTime<Source: MediaSource, Tech : PlaybackTech>(for source: Source?, using tech: Tech?) -> Int64 {
        guard let tech = tech, let source = source else { return 0 }
        guard let exposureSource = source as? ExposureSource else {
            // Default to playheadPosition
            return tech.playheadPosition
        }
        
        if exposureSource.isUnifiedPackager {
            if exposureSource is ChannelSource {
                return tech.playheadTime ?? 0 // TODO: How do we handle when there is no playheadTime available?
            }
            else if exposureSource is ProgramSource {
                return tech.playheadTime ?? 0 // TODO: How do we handle when there is no playheadTime available?
            }
            else if exposureSource is AssetSource {
                return tech.playheadPosition
            }
        }
        return tech.playheadPosition
    }
}

extension ExposureAnalytics: ExposureStreamingAnalyticsProvider {
    private func autoplay<Tech>(tech: Tech) -> Bool {
        if let tech = tech as? MediaPlayback {
            return tech.autoplay
        }
        return false
    }
    
    public func onEntitlementRequested<Tech>(tech: Tech, playable: Playable) where Tech : PlaybackTech {
        /// 1. Created
        let created = Playback.Created(timestamp: Date().millisecondsSince1970,
                                       version: version(for: "com.emp.ExposurePlayback"),
                                       revision: version(for: "com.emp.Player"),
                                       assetData: PlaybackIdentifier.from(playable: playable),
                                       autoPlay: autoplay(tech: tech))
        
        /// 2. DeviceInfo
        let deviceInfo = DeviceInfo(timestamp: Date().millisecondsSince1970)
        
        /// 3. Store startup events
        var current = startupEvents
        current.append(created)
        current.append(deviceInfo)
        startup = .notStarted(events: current)
    }
    
    public func onHandshakeStarted<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        if let source = source as? ExposureSource {
            let event = Playback.HandshakeStarted(timestamp: Date().millisecondsSince1970,
                                                  assetData: PlaybackIdentifier.from(source: source),
                                                  mediaId: source.url.path)
            
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
        let events = startupEvents
        
        dispatcher = Dispatcher(environment: environment,
                                sessionToken: sessionToken,
                                playSessionId: playSessionId,
                                startupEvents: events,
                                heartbeatsProvider: heartbeatsProvider)
        dispatcher?.flushTrigger(enabled: true)
    }
    
    
    public func onProgramChanged<Tech, Source>(tech: Tech, source: Source, program: Program?) where Tech: PlaybackTech, Source: MediaSource {
        if let programId = program?.programId, lastKnownProgramId != nil {
            let event = Playback.ProgramChanged(timestamp: Date().millisecondsSince1970,
                                                offsetTime: offsetTime(for: source, using: tech),
                                                programId: programId,
                                                videoLength: tech.duration)
            dispatcher?.enqueue(event: event)
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
extension ExposureAnalytics: AnalyticsProvider {
    public func onCreated<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        /// Created/DeviceInfo/Handshake will be sent before entitlement request
    }

    public func onPrepared<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        /// InitCompleted
        let event = Playback.InitCompleted(timestamp: Date().millisecondsSince1970)
        dispatcher?.enqueue(event: event)
    }
    
    public func onReady<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        /// PlayReady
        let event = Playback.PlayReady(timestamp: Date().millisecondsSince1970,
                                       offsetTime: offsetTime(for: source, using: tech))
        dispatcher?.enqueue(event: event)
    }
    
    public func onStarted<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        if let source = source as? ExposureSource {
            let referenceTime:Int64? = source.isUnifiedPackager ? 0 : nil
            let event = Playback.Started(timestamp: Date().millisecondsSince1970,
                                         assetData: PlaybackIdentifier.from(source: source),
                                         mediaId: source.url.cleanQuery() ?? source.url.path,
                                         offsetTime: offsetTime(for: source, using: tech),
                                         videoLength: tech.duration,
                                         bitrate: tech.currentBitrate != nil ? Int64(tech.currentBitrate!/1000) : nil,
                                         referenceTime: referenceTime)
            dispatcher?.enqueue(event: event)
            dispatcher?.heartbeat(enabled: true)
        }
    }
    
    public func onPaused<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        let event = Playback.Paused(timestamp: Date().millisecondsSince1970,
                                    offsetTime: offsetTime(for: source, using: tech))
        dispatcher?.enqueue(event: event)
    }
    
    public func onResumed<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        let event = Playback.Resumed(timestamp: Date().millisecondsSince1970,
                                     offsetTime: offsetTime(for: source, using: tech))
        dispatcher?.enqueue(event: event)
    }
    
    public func onAborted<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        defer {
            dispatcher?.heartbeat(enabled: false)
            dispatcher?.flushTrigger(enabled: false)
            dispatcher = nil
        }
        
        if startedChromeCasting {
            let event = Playback.StartCasting(timestamp: Date().millisecondsSince1970,
                                              offsetTime: offsetTime(for: source, using: tech))
            
            dispatcher?.enqueue(event: event)
        }
        else {
            let event = Playback.Aborted(timestamp: Date().millisecondsSince1970,
                                         offsetTime: offsetTime(for: source, using: tech))
            dispatcher?.enqueue(event: event)
        }
    }
    
    public func onCompleted<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        let event = Playback.Completed(timestamp: Date().millisecondsSince1970,
                                       offsetTime: offsetTime(for: source, using: tech))
        dispatcher?.enqueue(event: event)
        dispatcher?.heartbeat(enabled: false)
    }
    
    public func onError<Tech, Source, Context>(tech: Tech?, source: Source?, error: PlayerError<Tech, Context>) where Tech : PlaybackTech, Source : MediaSource, Context : MediaContext {
        guard let dispatcher = dispatcher else {
            finalizeWithError(tech: tech, source: source, error: error)
            return
        }
        let offset = source != nil ? offsetTime(for: source, using: tech) : nil
        let event = Playback.Error(timestamp: Date().millisecondsSince1970,
                                   offsetTime: offset,
                                   message: error.message,
                                   code: error.code)
        dispatcher.enqueue(event: event)
        dispatcher.heartbeat(enabled: false)
    }
    
    /// Delivers errors received while trying to finalize a session.
    ///
    /// - parameter error: The encountered error.
    /// - parameter startupEvents: Events `ExposureAnalytics` should deliver as the initial payload related to the error in question.
    fileprivate func finalizeWithError<Tech, Source, Context>(tech: Tech?, source: Source?, error: PlayerError<Tech, Context>) where Tech : PlaybackTech, Source : MediaSource, Context : MediaContext {
        var events = startupEvents
        
        let errorPayload = Playback.Error(timestamp: Date().millisecondsSince1970,
                                          offsetTime: 0,
                                          message: error.message,
                                          code: error.code)
        
        events.append(errorPayload)
        
        let batch = AnalyticsBatch(sessionToken: sessionToken,
                                   environment: environment,
                                   playToken: UUID().uuidString,
                                   payload: events)
        
        EventSink()
            .send(analytics: batch,
                  clockOffset: nil)
            .request()
            .validate()
            .response{
                // NOTE: Capture of self needs to be strong. Else we can not ensure saving will work properly. Reference will be cleaned up after block finishes.
                if let error = $0.error {
                    // These events need to be stored to disk
                    print("🚨 Failed to deliver error events.", error.message)
                    
                    do {
                        try AnalyticsPersister().persist(analytics: batch)
                        print("💾 Analytics data saved to disk")
                    }
                    catch {
                        print("🚨 AnalyticsPersister failed to persist error data",error)
                    }
                }
                else {
                    print("Delivered Error payload: \(batch.payload.count)")
                    batch.payload
                        .flatMap{ $0 as? AnalyticsEvent }
                        .forEach{
                            print(" ✅ ",$0.eventType)
                    }
                }
        }
    }
    
    public func onBitrateChanged<Tech, Source>(tech: Tech, source: Source, bitrate: Double) where Tech : PlaybackTech, Source : MediaSource {
        let analyticsEvent = Playback.BitrateChanged(timestamp: Date().millisecondsSince1970,
                                                     offsetTime: offsetTime(for: source, using: tech),
                                                     bitrate: Int64(bitrate/1000))
        dispatcher?.enqueue(event: analyticsEvent)
    }
    
    public func onBufferingStarted<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        let event = Playback.BufferingStarted(timestamp: Date().millisecondsSince1970,
                                              offsetTime: offsetTime(for: source, using: tech))
        dispatcher?.enqueue(event: event)
    }
    
    public func onBufferingStopped<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        let event = Playback.BufferingStopped(timestamp: Date().millisecondsSince1970,
                                              offsetTime: offsetTime(for: source, using: tech))
        dispatcher?.enqueue(event: event)
    }
    
    public func onScrubbedTo<Tech, Source>(tech: Tech, source: Source, offset: Int64) where Tech : PlaybackTech, Source : MediaSource {
        let event = Playback.ScrubbedTo(timestamp: Date().millisecondsSince1970,
                                        offsetTime: offset)
        dispatcher?.enqueue(event: event)
    }
    
    public func onDurationChanged<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        
    }
    
    public func onWarning<Tech, Source, Context>(tech: Tech, source: Source?, warning: PlayerWarning<Tech, Context>) where Tech : PlaybackTech, Source : MediaSource, Context : MediaContext {
        
    }
}
