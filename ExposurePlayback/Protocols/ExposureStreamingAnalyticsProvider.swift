//
//  ExposureAnalyticsProvider.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-10-26.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Player
import Exposure

/// Extends the `Player` built in protocol defining analytics events with *Exposure* specific analytics
public protocol ExposureStreamingAnalyticsProvider: AnalyticsProvider {
    init(environment: Environment, sessionToken: SessionToken, cdn:CDNInfoFromEntitlement? , analytics: AnalyticsFromEntitlement?, analyticsBaseUrl: String? )
    
    /// Exposure environment used for the active session.
    ///
    /// - Important: should match the `environment` used to authenticate the user.
    var environment: Environment { get }
    
    /// Token identifying the active session.
    ///
    /// - Important: should match the `environment` used to authenticate the user.
    var sessionToken: SessionToken { get }
    
    
    var analyticsBaseUrl: String? { get }
    
    /// Sent when the player is about to make an entitlement request
    ///
    /// - parameter tech: `PlaybackTech` to be used for playback
    /// - parameter request: *EMP* playable
    func onEntitlementRequested<Tech, Source>(tech: Tech, source: Source,playable: Playable) where Tech: PlaybackTech, Source : MediaSource 
    
    /// Sent when the entitlement has been granted, right after loading of media sources has been initiated.
    ///
    /// - parameter tech: `PlaybackTech` to be used for playback
    /// - parameter source: `MediaSource` used to load the request
    func onHandshakeStarted<Tech, Source>(tech: Tech, source: Source) where Tech: PlaybackTech, Source: MediaSource
    
    /// Should prepare and configure the remaining parts of the Analytics environment.
    /// This step is required because we are dependant on the response from Exposure with regards to the playSessionId.
    ///
    /// Once this is called, a Dispatcher should be associated with the session.
    ///
    /// - parameter tech: `PlaybackTech` to be used for playback
    /// - parameter source: `MediaSource` used to load the request
    /// - parameter playSessionId: Unique identifier for the current playback session.
    /// - parameter heartbeatsProvider: Will deliver heartbeats metadata during the session
    func finalizePreparation<Tech, Source>(tech: Tech, source: Source, playSessionId: String, heartbeatsProvider: @escaping () -> AnalyticsEvent?) where Tech: PlaybackTech, Source: MediaSource
    
    /// Sent if the current program changes during the session.
    ///
    /// `program` may be nil if there is for example a gap in the *Epg*
    ///
    /// - parameter tech: `PlaybackTech` to be used for playback
    /// - parameter source: `MediaSource` used to load the request
    /// - parameter playSessionId: Unique identifier for the current playback session.
    func onProgramChanged<Tech, Source>(tech: Tech, source: Source, program: Program?) where Tech: PlaybackTech, Source: MediaSource
}

