//
//  MockedExposureAnalytics.swift
//  ExposurePlaybackTests
//
//  Created by Fredrik Sjöberg on 2018-02-13.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import iOSClientExposure
import iOSClientPlayer

@testable import iOSClientExposurePlayback

class MockedExposureAnalytics: ExposureStreamingAnalyticsProvider {
    
    
    
    required init(environment: Environment, sessionToken: SessionToken, cdn: CDNInfoFromEntitlement?, analytics: AnalyticsFromEntitlement?, appName: String? = nil  ) {
        self.environment = environment
        self.sessionToken = sessionToken
        self.appName = appName
        self.analytics = analytics
    }
    
    let environment: Environment
    
    let sessionToken: SessionToken
    
    let analytics: AnalyticsFromEntitlement?
    
    let appName: String?
    
    func onEntitlementRequested<Tech, Source>(tech: Tech, source: Source,playable: Playable) where Tech: PlaybackTech, Source : MediaSource {
        
    }
    
    func onHandshakeStarted<Tech, Source>(tech: Tech, source: Source, analytics: AnalyticsFromEntitlement?, isOfflinePlayable: Bool) where Tech : PlaybackTech, Source : MediaSource {
        
    }
    
    func finalizePreparation<Tech, Source>(tech: Tech, source: Source, playSessionId: String, analytics: AnalyticsFromEntitlement?, heartbeatsProvider: @escaping () -> AnalyticsEvent?) where Tech : PlaybackTech, Source : MediaSource {
        
    }
    
    func onProgramChanged<Tech, Source>(tech: Tech, source: Source, program: Program?, analytics: AnalyticsFromEntitlement?) where Tech : PlaybackTech, Source : MediaSource {
        
    }
    
    func onCreated<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        
    }
    
    func onPrepared<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        
    }
    
    func onReady<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        
    }
    
    func onStarted<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        
    }
    
    func onPaused<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        
    }
    
    func onResumed<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        
    }
    
    func onAborted<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        
    }
    
    func onCompleted<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        
    }
    
    func onError<Tech, Source, Context>(tech: Tech?, source: Source?, error: PlayerError<Tech, Context>) where Tech : PlaybackTech, Source : MediaSource, Context : MediaContext {
        
    }
    
    func onBitrateChanged<Tech, Source>(tech: Tech, source: Source, bitrate: Double) where Tech : PlaybackTech, Source : MediaSource {
        
    }
    
    func onBufferingStarted<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        
    }
    
    func onBufferingStopped<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        
    }
    
    func onScrubbedTo<Tech, Source>(tech: Tech, source: Source, offset: Int64) where Tech : PlaybackTech, Source : MediaSource {
        
    }
    
    func onDurationChanged<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        
    }
    
    func onWarning<Tech, Source, Context>(tech: Tech, source: Source?, warning: PlayerWarning<Tech, Context>) where Tech : PlaybackTech, Source : MediaSource, Context : MediaContext {
        
    }
}
