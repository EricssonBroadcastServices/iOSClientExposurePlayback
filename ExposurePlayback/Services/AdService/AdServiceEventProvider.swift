//
//  AdServiceEventProvider.swift
//  ExposurePlayback-iOS
//
//  Created by Fredrik Sjöberg on 2018-10-11.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Player
import AVFoundation

internal class AdServiceEventProvider: AnalyticsProvider, TimedMetadataProvider, SourceAbandonedEventProvider {
    internal unowned let adService: AdService
    
    internal init(adService: AdService) {
        self.adService = adService
    }
    
    func onCreated<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        // print(" AdServiceEventProvider onCreated ")
    }
    
    func onPrepared<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        // print(" AdServiceEventProvider onPrepared ")
    }
    
    func onReady<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        // print(" AdServiceEventProvider onReady ")
        adService.playbackReady()
    }
    
    func onStarted<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        adService.playbackStarted()
    }
    
    func onPaused<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        // print(" AdServiceEventProvider onPaused ")
        adService.playbackPaused()
    }
    
    func onResumed<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        // print(" AdServiceEventProvider onResumed ")
        adService.playbackResumed()
    }
    
    func onAborted<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        // print(" AdServiceEventProvider onAborted ")
        adService.playbackEnded()
    }
    
    func onCompleted<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        // print(" AdServiceEventProvider onCompleted ")
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
        // print(" AdServiceEventProvider onBufferingStarted ")
        adService.playbackBufferingStarted()
    }
    
    func onBufferingStopped<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        // print(" AdServiceEventProvider onBufferingStopped ")
        adService.playbackBufferingEnded()
    }
    
    func onScrubbedTo<Tech, Source>(tech: Tech, source: Source, offset: Int64) where Tech : PlaybackTech, Source : MediaSource {
        // adService.seekRequestTriggered(withTargetPosition: offset)
    }
    
    func onDurationChanged<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        // print(" AdServiceEventProvider onDurationChanged ")
    }
    
    func onWarning<Tech, Source, Context>(tech: Tech, source: Source?, warning: PlayerWarning<Tech, Context>) where Tech : PlaybackTech, Source : MediaSource, Context : MediaContext {
        
    }
    
    func onTimedMetadataChanged<Tech, Source>(source: Source?, tech: Tech, metadata: [AVMetadataItem]?) where Tech : PlaybackTech, Source : MediaSource {
        // print(" AdServiceEventProvider onTimedMetadataChanged ")
        
        /* if let timeMedata = metadata {
            for item in timeMedata {
                        switch item.commonKey {

                        case .commonKeyAlbumName?:
                            print("AlbumName: \(item.value!)")
                        case .commonKeyArtist?:
                            print("Artist: \(item.value!)")
                        case .commonKeyArtwork?:
                            print("Artwork: \(item.value!)")
                        case .commonKeyAuthor?:
                            print("Author: \(item.value!)")
                        case .commonKeyContributor?:
                            print("Contributor: \(item.value!)")
                        case .commonKeyCopyrights?:
                            print("Copyrights: \(item.value!)")
                        case .commonKeyCreationDate?:
                            print("CreationDate: \(item.value!)")
                        case .commonKeyCreator?:
                            print("creator: \(item.value!)")
                        case .commonKeyDescription?:
                            print("Description: \(item.value!)")
                        case .commonKeyFormat?:
                            print("Format: \(item.value!)")
                        case .commonKeyIdentifier?:
                            print("Identifier: \(item.value!)")
                        case .commonKeyLanguage?:
                            print("Language: \(item.value!)")
                        case .commonKeyMake?:
                            print("Make: \(item.value!)")
                        case .commonKeyModel?:
                            print("Model: \(item.value!)")
                        case .commonKeyPublisher?:
                            print("Publisher: \(item.value!)")
                        case .commonKeyRelation?:
                            print("Relation: \(item.value!)")
                        case .commonKeySoftware?:
                            print("Software: \(item.value!)")
                        case .commonKeySubject?:
                            print("Subject: \(item.value!)")
                        case .commonKeyTitle?:
                            print("Title: \(item.value!)")
                        case .commonKeyType?:
                            print("Type: \(item.value!)")

                        case .id3MetadataKeyAlbumTitle?:
                            print("id3MetadataKeyAlbumTitle: \(item.value!)")

                        default:
                            print("other data: \(item.value!)")
                        }
                    }
        } */

        
        
        
        adService.playbackTimedMetadata(metaData: metadata)
    }
    
    func onSourcePreparationAbandoned<Tech, Source>(ofSource mediaSource: Source, byTech tech: Tech) where Tech : PlaybackTech, Source : MediaSource {
        // print(" AdServiceEventProvider onSourcePreparationAbandoned ")
        adService.playbackEnded()
    }
}
