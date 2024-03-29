//
//  TestEnv.swift
//  ExposurePlaybackTests
//
//  Created by Fredrik Sjöberg on 2018-02-13.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import iOSClientExposure
import AVFoundation

@testable import iOSClientPlayer
@testable import iOSClientExposurePlayback

class TestEnv {
    enum MockedError: Error {
        case generalError
    }
    
    var error: PlayerError<HLSNative<ExposureContext>,ExposureContext>?
    var warning: PlayerWarning<HLSNative<ExposureContext>,ExposureContext>?
    
    let environment: Environment
    let sessionToken: SessionToken
    let player: Player<HLSNative<ExposureContext>>
    
    public var eventDispatcher: EventDispatcher<ExposureContext, HLSNative<ExposureContext>> = EventDispatcher()
    
    init(environment: Environment, sessionToken: SessionToken) {
        

        self.environment = environment
        self.sessionToken = sessionToken
        self.player = Player<HLSNative<ExposureContext>>(environment: environment, sessionToken: sessionToken, analytics: MockedExposureAnalytics.self, appName: "Test App Name", appVersion: "3.0.0")
        
        // Mock the AVPlayer
        let mockedPlayer = MockedAVPlayer()
        mockedPlayer.mockedReplaceCurrentItem = { [weak mockedPlayer] item in
            print("mockedReplaceCurrentItem")
            if let mockedItem = item as? MockedAVPlayerItem {
                // We try to fake the loading scheme by dispatching KVO notifications when replace is called. This should trigger .readyToPlay
                mockedItem.associatedWithPlayer = mockedPlayer
                mockedItem.mockedStatus = .readyToPlay
            }
        }
        player.tech.avPlayer = mockedPlayer
    }
    
    func mockServerTime(callback: @escaping () -> ServerTimeProvider) {
        player.context.monotonicTimeService.serverTimeProvider = callback()
    }
    
    func mockAsset(callback: @escaping (ExposureSource, HLSNativeConfiguration, EventDispatcher<ExposureContext, HLSNative<ExposureContext>>? , [String]? ) -> HLSNative<ExposureContext>.MediaAsset<ExposureSource>) {
        player.tech.assetGenerator = callback
    }
    
    func defaultAssetMock(currentDate: Int64, bufferDuration: Int64, callback: @escaping (MockedAVURLAsset, MockedAVPlayerItem) -> Void = { _,_ in }) -> (ExposureSource, HLSNativeConfiguration, EventDispatcher<ExposureContext, HLSNative<ExposureContext>>?, [String]?) -> HLSNative<ExposureContext>.MediaAsset<ExposureSource> {
        return { source, configuration, eventDispatcher, metadataGroup in
            // MediaAsset
            let media = HLSNative<ExposureContext>.MediaAsset<ExposureSource>(source: source, configuration: configuration)
            
            // AVURLAsset
            let urlAsset = MockedAVURLAsset(url: source.entitlement.mediaLocator)
            urlAsset.mockedLoadValuesAsynchronously = { keys, handler in
                handler?()
            }
            urlAsset.mockedStatusOfValue = { key, outError in
                return .loaded
            }
            media.urlAsset = urlAsset
            
            // AVPlayerItem
            let item = MockedAVPlayerItem(mockedAVAsset: urlAsset)
            item.mockedCurrentTime = CMTime(milliseconds: 0)
            item.mockedCurrentDate = Date(unixEpoch: currentDate)
            let start = CMTime(milliseconds: 0)
            let end = CMTime(milliseconds: bufferDuration)
            item.mockedSeekableTimeRanges = [NSValue(timeRange: CMTimeRange(start: start, duration: end))]
            item.mockedSeekToDate = { [unowned item] date, callback in
                if let current = item.mockedCurrentDate {
                    let diff = date.unixEpoch - current.unixEpoch
                    item.mockedCurrentTime = CMTime(milliseconds: Int64(item.mockedCurrentTime.seconds*1000) + diff)
                    item.mockedCurrentDate = date
                    callback?(true)
                    return true
                }
                else {
                    callback?(false)
                    return false
                }
            }
            item.mockedSeekToTime = { _, callback in
                callback?(true)
            }
            // Transfer the bitrate settings from the real object to the mocked object
            let realPlayerItem = media.playerItem
            item.preferredPeakBitRate = realPlayerItem.preferredPeakBitRate
            media.playerItem = item
            
            
            callback(urlAsset, item)
            
            return media
        }
    }
    
    // Mocks the ProgramPlayable generation for ProgramService based seeking outside the manifest bounds.
    func mockProgramServicePlayable(callback: @escaping (Program) -> ProgramPlayable) {
        player.context.programPlayableGenerator = callback
    }
    
    func mockSeekToLiveChannelPlayable(callback: @escaping (String) -> ChannelPlayable) {
        player.context.channelPlayableGenerator = callback
    }
    
    func mockProgramService(callback: @escaping (Environment, SessionToken, EPG?, String?) -> ProgramService) {
        player.context.programServiceGenerator = callback
    }
}
