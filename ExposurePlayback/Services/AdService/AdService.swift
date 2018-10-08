//
//  AdServiceProvider.swift
//  ExposurePlayback-iOS
//
//  Created by Fredrik Sjöberg on 2018-10-01.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation

@objc public protocol AdPlayerProxy: class {
    var playheadPosition: Int64 { get }
    var isMuted: Bool { get set }
    var duration: Int64 { get }
    var rate: Float { get set }
    
    func play()
    func pause()
    func stop()
    func seek(toTime timeInterval: Int64, callback: @escaping (Bool) -> Void)
}

import Player
internal class AdTechWrapper: AdPlayerProxy {
    internal weak var tech: HLSNative<ExposureContext>?
    internal init(tech: HLSNative<ExposureContext>) {
        self.tech = tech
    }
    
    var playheadPosition: Int64 {
        return (tech?.playheadPosition ?? -1)
    }
    
    var isMuted: Bool {
        get {
            print(#function,tech?.isMuted)
            return tech?.isMuted ?? false
        }
        set {
            print(#function,newValue)
            tech?.isMuted = newValue
        }
    }
    
    var duration: Int64 {
        print(#function,tech?.duration)
        return tech?.duration ?? -1
    }
    
    var rate: Float {
        get {
            print(#function,tech?.rate)
            return tech?.rate ?? 0
        }
        set {
            print(#function,newValue)
            tech?.rate = newValue
        }
    }
    
    func play() {
        print(#function)
        tech?.play()
    }
    
    func pause() {
        print(#function)
        tech?.pause()
    }
    
    func stop() {
        print(#function)
        tech?.stop()
    }
    
    func seek(toTime timeInterval: Int64, callback: @escaping (Bool) -> Void) {
        print(#function,timeInterval)
        tech?.seek(toPosition: timeInterval, callback: callback)
    }
}

@objc public protocol AdInteractionPolicy {
    func requiredAttentionBeforeSkipping(fromPosition: Int64) -> Int64
    func allowedTargetSeek(forRequest: Int64) -> Int64
    func canPause(atPosition: Int64) -> Bool
}

@objc public protocol AdService {
    func playbackReady(tech: AdPlayerProxy)
    func playbackStarted(tech: AdPlayerProxy)
    func playbackEnded(tech: AdPlayerProxy)
    func playbackPaused(tech: AdPlayerProxy)
    func playbackResumed(tech: AdPlayerProxy)
    func playbackFailed(error: NSError, tech: AdPlayerProxy)
    func playbackBufferingStarted(tech: AdPlayerProxy)
    func playbackBufferingEnded(tech: AdPlayerProxy)
    func playbackTimedMetadata(metaData: Any?, tech: AdPlayerProxy)
    
    func prepareAsset(source: URL, callback: @escaping (URL) -> AdPlayerProxy?)
    func prepareProgram(source: URL, callback: @escaping (URL) -> AdPlayerProxy?)
    func prepareChannel(source: URL, callback: @escaping (URL) -> AdPlayerProxy?)
}


import AVFoundation
internal class AdServiceEventProvider: AnalyticsProvider, TimedMetadataProvider {
    internal unowned let adService: AdService
    
    internal init(adService: AdService) {
        self.adService = adService
    }
    
    func onCreated<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        
    }
    
    func onPrepared<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        
    }
    
    func onReady<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        if let tech = tech as? HLSNative<ExposureContext> {
            adService.playbackReady(tech: AdTechWrapper(tech: tech))
        }
    }
    
    func onStarted<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        if let tech = tech as? HLSNative<ExposureContext> {
            adService.playbackStarted(tech: AdTechWrapper(tech: tech))
        }
    }
    
    func onPaused<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        if let tech = tech as? HLSNative<ExposureContext> {
            adService.playbackPaused(tech: AdTechWrapper(tech: tech))
        }
    }
    
    func onResumed<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        if let tech = tech as? HLSNative<ExposureContext> {
            adService.playbackResumed(tech: AdTechWrapper(tech: tech))
        }
    }
    
    func onAborted<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        if let tech = tech as? HLSNative<ExposureContext> {
            adService.playbackEnded(tech: AdTechWrapper(tech: tech))
        }
    }
    
    func onCompleted<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        if let tech = tech as? HLSNative<ExposureContext> {
            adService.playbackEnded(tech: AdTechWrapper(tech: tech))
        }
    }
    
    func onError<Tech, Source, Context>(tech: Tech?, source: Source?, error: PlayerError<Tech, Context>) where Tech : PlaybackTech, Source : MediaSource, Context : MediaContext {
        // TODO:
    }
    
    func onBitrateChanged<Tech, Source>(tech: Tech, source: Source, bitrate: Double) where Tech : PlaybackTech, Source : MediaSource {
        
    }
    
    func onBufferingStarted<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        if let tech = tech as? HLSNative<ExposureContext> {
            adService.playbackBufferingStarted(tech: AdTechWrapper(tech: tech))
        }
    }
    
    func onBufferingStopped<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        if let tech = tech as? HLSNative<ExposureContext> {
            adService.playbackBufferingEnded(tech: AdTechWrapper(tech: tech))
        }
    }
    
    func onScrubbedTo<Tech, Source>(tech: Tech, source: Source, offset: Int64) where Tech : PlaybackTech, Source : MediaSource {
        
    }
    
    func onDurationChanged<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        
    }
    
    func onWarning<Tech, Source, Context>(tech: Tech, source: Source?, warning: PlayerWarning<Tech, Context>) where Tech : PlaybackTech, Source : MediaSource, Context : MediaContext {
        
    }
    
    func onTimedMetadataChanged<Tech, Source>(source: Source?, tech: Tech, metadata: [AVMetadataItem]?) where Tech : PlaybackTech, Source : MediaSource {
        if let tech = tech as? HLSNative<ExposureContext> {
            adService.playbackTimedMetadata(metaData: metadata, tech: AdTechWrapper(tech: tech))
        }
    }
}
