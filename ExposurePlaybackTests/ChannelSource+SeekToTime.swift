//
//  ChannelSource+SeekToTime.swift
//  ExposurePlaybackTests
//
//  Created by Fredrik Sjöberg on 2018-02-09.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation

import Quick
import Nimble
import Exposure
import AVFoundation

@testable import Player
@testable import ExposurePlayback


extension Date {
    internal var unixEpoch: Int64 {
        return Int64((timeIntervalSince1970 * 1000.0).rounded())
    }
    
    internal init(unixEpoch: Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(unixEpoch / 1000))
    }
}
class ChannelSourceSeekToTimeSpec: QuickSpec {
    
    
    override func spec() {
        super.spec()
        
        describe("ChannelSource") {
            let currentDate = Date().unixEpoch
            let hour: Int64 = 60 * 60 * 1000
            
            let env = Environment(baseUrl: "http://www.example.com", customer: "customer", businessUnit: "businessUnit")
            let token = SessionToken(value: "token")
            
            // Seekable range is defined by the manifest
            context("Within seekableTimeRange") {
                context("Within program bounds") {
                    ///  |---------+---|-------> live
                    ///  p1        |   p2      |
                    ///  r1        |           r2
                    ///  s1 -----> s2
                    it("should allow seek") {
                        let env = SeekToTimeEnv(environment: env, sessionToken: token)
                        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour))
                        
                        // Mock the ProgramService
                        env.mockProgramService{ environment, sessionToken, channelId in
                            let provider = SeekToTimeProgramProvider()
                            provider.mockedFetchProgram = { _,_,_, callback in
                                let program = Program
                                    .validJson(programId: "program1", channelId: "channelId", assetId: "assetId")
                                    .timestamp(starting: currentDate, ending: currentDate+hour)
                                    .decode(Program.self)
                                callback(program,nil)
                            }
                            let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
                            service.provider = provider
                            return service
                        }
                        
                        // Configure the playable
                        let provider = MockedChannelEntitlementProvider()
                        provider.mockedRequestEntitlement = { _,_,_, callback in
                            var json = PlaybackEntitlement.requiedJson
                            json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                            json["ffEnabled"] = true
                            callback(json.decode(PlaybackEntitlement.self), nil)
                        }
                        let playable = ChannelPlayable(assetId: "channelId", entitlementProvider: provider)
                        
                        // Initiate test
                        env.player.startPlayback(playable: playable)
                        let seekTarget = currentDate + 10 * 60 * 1000
                        env.player.onProgramChanged { player, source, program in
                            player.seek(toTime: seekTarget)
                        }
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 2)
                        expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 2)
                        expect{ env.player.playheadTime != nil ? abs(env.player.playheadTime! - seekTarget) : nil }.toEventually(beLessThan(1000), timeout: 2)
                    }
                }
                
                context("After program bounds") {
                    ///  |-----------|----+---> live
                    ///  p1          p2   |   |
                    ///  r1               |   r2
                    ///  s1 ------------> s2
                    it("should allow seek if entitled") {
                        let env = SeekToTimeEnv(environment: env, sessionToken: token)
                        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour))
                        
                        // Mock the ProgramService
                        env.mockProgramService{ environment, sessionToken, channelId in
                            let provider = SeekToTimeProgramProvider()
                            provider.mockedFetchProgram = { _,timestamp,_, callback in
                                if timestamp < currentDate + hour / 2 {
                                    let program = Program
                                        .validJson(programId: "program1", channelId: "channelId", assetId: "asset1")
                                        .timestamp(starting: currentDate, ending: currentDate+hour/2)
                                        .decode(Program.self)
                                    callback(program,nil)
                                }
                                else {
                                    let program = Program
                                        .validJson(programId: "program2", channelId: "channelId", assetId: "asset2")
                                        .timestamp(starting: currentDate+hour/2, ending: currentDate+hour)
                                        .decode(Program.self)
                                    callback(program,nil)
                                }
                            }
                            provider.mockedValidate = { programId, environment, sessionToken, callback in
                                callback(EntitlementValidation.validJson(status: "SUCCESS").decode(EntitlementValidation.self),nil)
                            }
                            let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
                            service.provider = provider
                            return service
                        }
                        
                        // Configure the playable
                        let provider = MockedChannelEntitlementProvider()
                        provider.mockedRequestEntitlement = { _,_,_, callback in
                            var json = PlaybackEntitlement.requiedJson
                            json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                            json["ffEnabled"] = true
                            callback(json.decode(PlaybackEntitlement.self), nil)
                        }
                        let playable = ChannelPlayable(assetId: "channelId", entitlementProvider: provider)
                        
                        // Initiate test
                        env.player.startPlayback(playable: playable)
                        let seekTarget = currentDate + hour * 3/4
                        env.player.onProgramChanged { player, source, program in
                            player.seek(toTime: seekTarget)
                        }
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 2)
                        expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 2)
                        expect{ return env.player.playheadTime != nil ? abs(env.player.playheadTime! - seekTarget) : nil }.toEventually(beLessThan(1000), timeout: 4)
                    }
                    
                    it("should stop with error if not entitled") {
                        let env = SeekToTimeEnv(environment: env, sessionToken: token)
                        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour))
                        
                        // Mock the ProgramService
                        env.mockProgramService{ environment, sessionToken, channelId in
                            let provider = SeekToTimeProgramProvider()
                            provider.mockedFetchProgram = { _,timestamp,_, callback in
                                if timestamp < currentDate + hour / 2 {
                                    let program = Program
                                        .validJson(programId: "program1", channelId: "channelId", assetId: "asset1")
                                        .timestamp(starting: currentDate, ending: currentDate+hour/2)
                                        .decode(Program.self)
                                    callback(program,nil)
                                }
                                else {
                                    let program = Program
                                        .validJson(programId: "program2", channelId: "channelId", assetId: "asset2")
                                        .timestamp(starting: currentDate+hour/2, ending: currentDate+hour)
                                        .decode(Program.self)
                                    callback(program,nil)
                                }
                            }
                            provider.mockedValidate = { assetId, environment, sessionToken, callback in
                                if assetId == "asset2" {
                                    callback(EntitlementValidation.validJson(status: "NOT_ENTITLED").decode(EntitlementValidation.self),nil)
                                }
                                else {
                                    callback(EntitlementValidation.validJson(status: "SUCCESS").decode(EntitlementValidation.self),nil)
                                }
                            }
                            let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
                            service.provider = provider
                            return service
                        }
                        
                        // Configure the playable
                        let provider = MockedChannelEntitlementProvider()
                        provider.mockedRequestEntitlement = { _,_,_, callback in
                            var json = PlaybackEntitlement.requiedJson
                            json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                            json["ffEnabled"] = true
                            callback(json.decode(PlaybackEntitlement.self), nil)
                        }
                        let playable = ChannelPlayable(assetId: "channelId", entitlementProvider: provider)
                        
                        // Initiate test
                        env.player.startPlayback(playable: playable)
                        let seekTarget = currentDate + hour * 3/4
                        var error: PlayerError<HLSNative<ExposureContext>,ExposureContext>? = nil
                        env.player.onProgramChanged { player, source, program in
                                player.seek(toTime: seekTarget)
                            }
                            .onError{ tech, source, err in
                                error = err
                        }
                        env.player.tech
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 2)
                        expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 2)
                        expect(error).toEventuallyNot(beNil(), timeout: 3)
                        expect(error?.code).toEventually(equal(403))
                        expect(error?.message).toEventually(equal("NOT_ENTITLED"))
                    }
                }
            }
            
            // Seekable range is defined by the manifest
            context("After seekableTimeRange") {
                context("Close to live point") {
                    ///  |----------->.........x
                    ///  p1          |  |      p2
                    ///  r1          r2 |
                    ///  s1 ----------> s2
                    let livePointOffet = hour/2
                    let closeToLivePoint: Int64 = 10 * 1000
                    let livePointDelay: Int64 = 25 * 1000
                    it("should seek to live point") {
                        let env = SeekToTimeEnv(environment: env, sessionToken: token)
                        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: livePointOffet))
                        
                        // Mock the MonotonicTimeService
                        env.mockServerTime {
                            let provider = MockedServerTimeProvider()
                            provider.mockedFetchServerTime = { _, callback in
                                let livePoint = Date(unixEpoch: currentDate + livePointOffet + livePointDelay)
                                callback(ServerTime.validJson(date: livePoint).decode(ServerTime.self), nil)
                            }
                            return provider
                        }
                        
                        // Mock the ProgramService
                        env.mockProgramService{ environment, sessionToken, channelId in
                            let provider = SeekToTimeProgramProvider()
                            provider.mockedFetchProgram = { _,_,_, callback in
                                let program = Program
                                    .validJson(programId: "program1", channelId: "channelId", assetId: "assetId")
                                    .timestamp(starting: currentDate, ending: currentDate+hour)
                                    .decode(Program.self)
                                callback(program,nil)
                            }
                            let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
                            service.provider = provider
                            return service
                        }
                        
                        // Configure the playable
                        let provider = MockedChannelEntitlementProvider()
                        provider.mockedRequestEntitlement = { _,_,_, callback in
                            var json = PlaybackEntitlement.requiedJson
                            json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                            json["ffEnabled"] = true
                            callback(json.decode(PlaybackEntitlement.self), nil)
                        }
                        let playable = ChannelPlayable(assetId: "channelId", entitlementProvider: provider)
                        
                        _ = env.player.serverTime
                        
                        // Initiate test
                        env.player.startPlayback(playable: playable)
                        let seekTarget = currentDate + livePointOffet + closeToLivePoint
                        env.player.onProgramChanged { player, source, program in
                            player.seek(toTime: seekTarget)
                        }
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 2)
                        expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 2)
                        expect{ env.player.playheadTime != nil ? abs(env.player.playheadTime! - (currentDate + livePointOffet)) : nil }.toEventually(beLessThan(1000), timeout: 3)
                    }
                }
                
                context("Far ahead of live point") {
                    ///  |-------------->.............x
                    ///  p1             |         |   p2
                    ///  r1             r2        |
                    ///  s1 --------------------> s2
                    it("should ignore seek and deliver warning") {
                        
                    }
                }
            }
        }
    }
    //                        env.mockProgramServicePlayable{ program in
    //                            let provider = MockedProgramEntitlementProvider()
    //                            provider.mockedRequestEntitlement = { _,_,_,_, callback in
    //                                guard let result = PlaybackEntitlement.validJson.decode(PlaybackEntitlement.self) else {
    //                                    callback(nil,ExposureError.generalError(error: SeekToTimeEnv.MockedError.generalError))
    //                                    return
    //                                }
    //                                callback(result,nil)
    //                            }
    //                            return ProgramPlayable(assetId: program.programId, channelId: program.channelId, entitlementProvider: provider)
    //                        }
}

class SeekToTimeEnv {
    enum MockedError: Error {
        case generalError
    }
    
    let environment: Environment
    let sessionToken: SessionToken
    let player: Player<HLSNative<ExposureContext>>
    init(environment: Environment, sessionToken: SessionToken) {
        self.environment = environment
        self.sessionToken = sessionToken
        self.player = Player<HLSNative<ExposureContext>>(environment: environment, sessionToken: sessionToken)
        
        // Mock the AVPlayer
        let mockedPlayer = MockedAVPlayer()
        mockedPlayer.mockedReplaceCurrentItem = { [weak mockedPlayer] item in
            if let mockedItem = item as? MockedAVPlayerItem {
                // We try to fake the loading scheme by dispatching KVO notifications when replace is called. This should trigger .readyToPlay
                mockedItem.associatedWithPlayer = mockedPlayer
                mockedItem.willChangeValue(for: \MockedAVPlayerItem.status)
                mockedItem.didChangeValue(for: \MockedAVPlayerItem.status)
            }
        }
        player.tech.avPlayer = mockedPlayer
    }
    
    func mockServerTime(callback: @escaping () -> ServerTimeProvider) {
        player.context.monotonicTimeService.serverTimeProvider = callback()
    }
    
    func mockAsset(callback: @escaping (ExposureSource, HLSNativeConfiguration) -> HLSNative<ExposureContext>.MediaAsset<ExposureSource>) {
        player.tech.assetGenerator = callback
    }
    
    func defaultAssetMock(currentDate: Int64, bufferDuration: Int64) -> (ExposureSource, HLSNativeConfiguration) -> HLSNative<ExposureContext>.MediaAsset<ExposureSource> {
        return { source, configuration in
            // MediaAsset
            let media = HLSNative<ExposureContext>.MediaAsset<ExposureSource>(source: source, configuration: configuration)
            
            // AVPlayerItem
            let item = MockedAVPlayerItem(mockedUrl: source.entitlement.mediaLocator)
            item.mockedStatus = { [unowned item] in
                if item.associatedWithPlayer == nil {
                    return .unknown
                }
                else {
                    return .readyToPlay
                }
            }
            item.mockedCurrentTime = CMTime(milliseconds: 0)
            item.mockedCurrentDate = Date(unixEpoch: currentDate)
            let start = CMTime(milliseconds: 0)
            let end = CMTime(milliseconds: bufferDuration)
            item.mockedSeekableTimeRanges = [NSValue(timeRange: CMTimeRange(start: start, duration: end))]
            item.mockedSeekToDate = { [unowned item] date, callback in
                if let current = item.mockedCurrentDate {
                    let diff = date.unixEpoch - current.unixEpoch
                    print(">>>> DIFF",diff,item.mockedCurrentTime.seconds)
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
            media.playerItem = item
            
            // AVURLAsset
            let urlAsset = MockedAVURLAsset(url: source.entitlement.mediaLocator)
            urlAsset.mockedLoadValuesAsynchronously = { keys, handler in
                handler?()
            }
            urlAsset.mockedStatusOfValue = { key, outError in
                return .loaded
            }
            media.urlAsset = urlAsset
            
            return media
        }
    }
    
    // Mocks the ProgramPlayable generation for ProgramService based seeking outside the manifest bounds.
    func mockProgramServicePlayable(callback: @escaping (Program) -> ProgramPlayable) {
        player.context.programPlayableGenerator = callback
    }
    
    func mockProgramService(callback: @escaping (Environment, SessionToken, String) -> ProgramService) {
        player.context.programServiceGenerator = callback
    }
}

class SeekToTimeProgramProvider: ProgramProvider {
    public init() { }
    
    var mockedFetchProgram: (String, Int64, Environment, (Program?, ExposureError?) -> Void) -> Void = { _,_,_,_ in }
    func fetchProgram(on channelId: String, timestamp: Int64, using environment: Environment, callback: @escaping (Program?, ExposureError?) -> Void) {
        mockedFetchProgram(channelId, timestamp, environment, callback)
    }
    
    var mockedValidate: (String, Environment, SessionToken, (EntitlementValidation?, ExposureError?) -> Void) -> Void = { _,_,_,_ in }
    func validate(entitlementFor assetId: String, environment: Environment, sessionToken: SessionToken, callback: @escaping (EntitlementValidation?, ExposureError?) -> Void) {
        mockedValidate(assetId, environment, sessionToken, callback)
    }
    
    
}
