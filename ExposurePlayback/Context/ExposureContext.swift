//
//  ExposureContext.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-11-27.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Player
import iOSClientExposure

/// Defines the `MediaContext` to be used when contacting *Exposure*.
///
/// Allows retrieval and processing of `PlaybackEntitlement`s through designated extensions on `Player`.
public class ExposureContext: MediaContext {
    /// `ExposureContext` related errors
    public typealias ContextError = Error
    
    /// `ExposureContext` related warning messages
    public typealias ContextWarning = Warning
    
    /// Source object encapsulating a fetched `PlaybackEntitlement`
    public typealias Source = ExposureSource
    
    /// Generators used to produce the relevant `AnalyticsProvider`
    public var analyticsGenerators: [(Source?) -> AnalyticsProvider] = []
    
    /// Exposure environment used for the active session.
    public let environment: Environment
    
    /// Token identifying the active session.
    public let sessionToken: SessionToken
    
    public let analyticsBaseUrl: String?
    
    /// Service that handles synchronization of local device time with server time
    public let monotonicTimeService: MonotonicTimeService
    
    /// Service that manages entitlement validation on currently active program
    public var programService: ProgramService?
    
    /// Service that listens to changes in network connection
    internal var reachability: Reachability?
    
    /// Tracks the internal programChanged callback
    internal var onProgramChanged: (Program?, Source) -> Void = { _,_ in }
    
    /// Tracks the internal entitlementResponse callback
    internal var onEntitlementResponse: (PlaybackEntitlement, Source) -> Void = { _,_ in }
    
    /// Tracks the media Type of the asset : audio / video
    internal var onMediaType: (MediaType) -> Void = { _ in }
    
    /// Tracks the internal adService callback
    internal var onAdServiceRequested: (Source) -> Void = { _ in }
    
    /// Tracks the internal adService callback
    internal var onServerSideAd: (Source, Ads?) -> Void = { _,_  in }
    
    /// Tracks the internal adService ad end
    internal var onPlaybackStartWithAds: (Int64, Int64,  Int64, [MarkerPoint]) -> Void = { _, _, _, _ in }
    
    /// Tracks the internal adService ad start 
    internal var onWillPresentInterstitial: (ContractRestrictionsService, String?, [String]?, Int64 ) -> Void = { _, _, _, _ in }
    
    /// Tracks the internal adService ad end
    internal var onDidPresentInterstitial: (ContractRestrictionsService) -> Void = { _ in }
    
    /// Tracks the internal adService ad start
    internal var onServerSideAdShouldSkip: (Int64) -> Void = { _ in }
    
    /// Tracks the clip start event
    internal var onClipStarted: (Int64, Int64) -> Void = { _, _ in }
    
    /// Tracks the clip end event
    internal var onClipEnded: (Int64, Int64) -> Void = { _, _ in }
    
    /// Send back the played / clicked Ads's tracking urls back to the ad server
    /// - Parameter adTrackingUrls: adTrackingUrls descriptionadTrackingUrls
    internal func trackAds( adTrackingUrls: [String]) {
        trackPlayedAds(adTrackingUrls: adTrackingUrls)
    }
    
    /// Specifies playback related behaviour
    internal(set) public var playbackProperties: PlaybackProperties = PlaybackProperties()
    
    /// Used to generate a fresh `ProgramPlayable` from the specified program.
    ///
    /// Generating the playable instead of converting it directly from the `Program` allows us to inject specialized `ProgramEntitlementProvider`s which will simplify testing.
    internal var programPlayableGenerator: (Program) -> ProgramPlayable = { return $0.programPlayable }
    
    /// Used to generate a fresh `ChannelPlayable` from the specfied `channelId`.
    ///
    /// Generating the playable instead of converting it directly from the `channelId` allows us to inject specialized `ChannelEntitlementProvider`s which will simplify testing.
    internal var channelPlayableGenerator: (String) -> ChannelPlayable = { return ChannelPlayable(assetId: $0) }
    
    /// Used to generate a fresh `ProgramService` for a channel-based source.
    internal var programServiceGenerator: (Environment, SessionToken, String) -> ProgramService = { environment, sessionToken, channelId in
        return ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
    }
    
    internal var isDynamicManifest: (HLSNative<ExposureContext>, ExposureSource?) -> Bool = { tech, source in
        guard let type = tech.playbackType else { return false }
        return (type == "LIVE" || type == "Live")
    }
    
    /// Creates a new `ExposureContext`
    ///
    /// - parameter environment: Exposure `Environment` to use
    /// - parameter sessionToken: Exposure `SessionToken` to use
    public init(environment: Environment, sessionToken: SessionToken, analyticsBaseUrl: String? = nil ) {
        self.environment = environment
        self.sessionToken = sessionToken
        self.analyticsBaseUrl = analyticsBaseUrl
        self.monotonicTimeService = MonotonicTimeService(environment: environment)
        
        reachability = Reachability()
        do {
            try reachability?.startNotifier()
        }
        catch{
            print("could not start reachability notifier")
        }
    }
    
    deinit {
        reachability?.stopNotifier()
    }
}


extension ExposureContext: StartTimeDelegate {
    // MARK: Start Time
    
    /// `ExposureContext` will only handle start time for `MediaSource`s which are explicit subclasses of `ExposureSource` defined in `ExposurePlayback`. Unsupported sources will use `.defaultStartTime`.
    ///
    /// The actual start time for valid `MediaSource`s depends on what options `PlaybackProperties` specifies and the exact behaviour for that source.
    ///
    /// - parameter source: The `MediaSource` for which this start time request concerns.
    /// - parameter tech: Tech which will apply the start time.
    /// - returns: relevant `StartOffset` for the `MediaSource`
    public func startTime<Context>(for source: MediaSource, tech: HLSNative<Context>) -> StartOffset {
        if let startTimeSource = source as? ContextStartTime, let hls = tech as? HLSNative<ExposureContext> {
            return startTimeSource.handleStartTime(for: hls, in: self)
        }
        return .defaultStartTime
    }
}


extension ExposureContext {
    /// Send back the played / clicked Ads's tracking urls back to the ad server
    /// - Parameter adTrackingUrls: adTrackingUrls
    public func trackPlayedAds( adTrackingUrls: [String]) {
        let queue = DispatchQueue.global(qos: .background)
        let group = DispatchGroup()
        
        for url in adTrackingUrls {
            group.enter()
            queue.async {
                if let adTrackingUrl = URL(string: url) {
                    let task = URLSession.shared.dataTask(with: adTrackingUrl) { data, response, error in
                        if let _ = response as? HTTPURLResponse {
                            // success
                        }
                        group.leave()
                    }
                    task.resume()
                } else {
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            // print(" All the ad tracking beacons were sent to backend")
        }
    }
}
