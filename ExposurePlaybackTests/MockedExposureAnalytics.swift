//
//  MockedExposureAnalytics.swift
//  ExposurePlaybackTests
//
//  Created by Fredrik Sjöberg on 2018-02-13.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Exposure
import Player

@testable import ExposurePlayback

class MockedExposureAnalytics: ExposureStreamingAnalyticsProvider {
    
    
    
    required init(environment: Environment, sessionToken: SessionToken, cdn: CDNInfoFromEntitlement?, analytics: AnalyticsFromEntitlement?) {
        self.environment = environment
        self.sessionToken = sessionToken
    }
    
    let environment: Environment
    
    let sessionToken: SessionToken
    
    func onEntitlementRequested<Tech>(tech: Tech, playable: Playable) where Tech : PlaybackTech {
        
    }
    
    func onHandshakeStarted<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        
    }
    
    func finalizePreparation<Tech, Source>(tech: Tech, source: Source, playSessionId: String, heartbeatsProvider: @escaping () -> AnalyticsEvent?) where Tech : PlaybackTech, Source : MediaSource {
        
    }
    
    func onProgramChanged<Tech, Source>(tech: Tech, source: Source, program: Program?) where Tech : PlaybackTech, Source : MediaSource {
        
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
