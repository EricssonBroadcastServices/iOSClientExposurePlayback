//
//  AdServiceEventProvider.swift
//  ExposurePlayback-iOS
//
//  Created by Fredrik Sjöberg on 2018-10-11.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import iOSClientPlayer
import AVFoundation

internal class AdServiceEventProvider: AnalyticsProvider, TimedMetadataProvider, SourceAbandonedEventProvider {

    internal unowned let adService: AdService
    
    internal init(adService: AdService) {
        self.adService = adService
    }
    
    func onCreated<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
    }
    
    func onPrepared<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
    }
    
    func onReady<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        adService.playbackReady()
    }
    
    func onStarted<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        adService.playbackStarted()
    }
    
    func onPaused<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        adService.playbackPaused()
    }
    
    func onResumed<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        adService.playbackResumed()
    }
    
    func onAborted<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        adService.playbackEnded()
    }
    
    func onCompleted<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        adService.playbackEnded()
    }
    
    func onError<Tech, Source, Context>(tech: Tech?, source: Source?, error: PlayerError<Tech, Context>) where Tech : PlaybackTech, Source : MediaSource, Context : MediaContext {
        // TODO:
//        let nsError = error.nsError
//        adService.playbackFailed(error: <#T##NSError#>)
    }
    
    func onBitrateChanged<Tech, Source>(tech: Tech, source: Source, bitrate: Double) where Tech : PlaybackTech, Source : MediaSource {
        
    }
    
    func onBufferingStarted<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        adService.playbackBufferingStarted()
    }
    
    func onBufferingStopped<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        adService.playbackBufferingEnded()
    }
    
    func onScrubbedTo<Tech, Source>(tech: Tech, source: Source, offset: Int64) where Tech : PlaybackTech, Source : MediaSource {
        // adService.seekRequestTriggered(withTargetPosition: offset)
    }
    
    func onDurationChanged<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {

    }
    
    func onWarning<Tech, Source, Context>(tech: Tech, source: Source?, warning: PlayerWarning<Tech, Context>) where Tech : PlaybackTech, Source : MediaSource, Context : MediaContext {
        
    }
    
    func onTimedMetadataChanged<Tech, Source>(source: Source?, tech: Tech, metadata: [AVMetadataItem]?) where Tech : PlaybackTech, Source : MediaSource {
        adService.playbackTimedMetadata(metaData: metadata)
    }
    
    func onSourcePreparationAbandoned<Tech, Source>(ofSource mediaSource: Source, byTech tech: Tech) where Tech : PlaybackTech, Source : MediaSource {
        adService.playbackEnded()
    }
    
    func onAppDidEnterBackground<Tech, Source>(tech: Tech, source: Source?) where Tech : iOSClientPlayer.PlaybackTech, Source : iOSClientPlayer.MediaSource {}
    
    func onAppDidEnterForeground<Tech, Source>(tech: Tech, source: Source?) where Tech : iOSClientPlayer.PlaybackTech, Source : iOSClientPlayer.MediaSource {}
    
    func onGracePeriodStarted<Tech, Source>(tech: Tech, source: Source?) where Tech : iOSClientPlayer.PlaybackTech, Source : iOSClientPlayer.MediaSource {}
    
    func onGracePeriodEnded<Tech, Source>(tech: Tech, source: Source?) where Tech : iOSClientPlayer.PlaybackTech, Source : iOSClientPlayer.MediaSource {}
    
}
