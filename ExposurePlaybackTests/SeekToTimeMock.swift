//
//  SeekToTimeMock.swift
//  ExposurePlaybackTests
//
//  Created by Fredrik Sjöberg on 2018-03-05.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Exposure

@testable import Player
@testable import ExposurePlayback

class SeekToTimeMock {
    let environment = Environment(baseUrl: "http://www.example.com", customer: "customer", businessUnit: "businessUnit")
    let token = SessionToken(value: "token")
    
    func runWithinBoundsTest(playable: Playable, properties: PlaybackProperties = PlaybackProperties(), seekTarget: Int64) -> TestEnv {
        let seekOffset: Int64 = 10 * 60 * 1000
        let currentDate = seekTarget - seekOffset
        let hour: Int64 = 60 * 60 * 1000
        
        let env = TestEnv(environment: environment, sessionToken: token)
        env.player.context.isDynamicManifest = { _,_ in return true }
        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour))
        
        // Mock the ProgramService
        env.mockProgramService{ environment, sessionToken, channelId in
            let provider = MockedProgramProvider()
            provider.mockedFetchProgram = { _,_,_, callback in
                let program = Program
                    .validJson(programId: "program1", channelId: "channelId", assetId: "assetId")
                    .timestamp(starting: currentDate, ending: currentDate+hour)
                    .decodeWrap(Program.self)
                callback(program,nil)
            }
            let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
            service.fuzzyConfiguration.fuzzyFactor = 1000
            service.provider = provider
            return service
        }
        
        // Initiate test
        env.player
            .onProgramChanged { player, source, program in
                player.seek(toTime: seekTarget)
            }
            .onPlaybackReady { player, source in
                if let avPlayer = player.tech.avPlayer as? MockedAVPlayer {
                    avPlayer.mockedRate = 1
                }
        }
        
        env.player.startPlayback(playable: playable)

        return env
    }
    
    func runAfterBoundsEntitledTest(playable: Playable, properties: PlaybackProperties = PlaybackProperties(), seekTarget: Int64) -> TestEnv {
        let hour: Int64 = 60 * 60 * 1000
        let seekOffset: Int64 = hour * 3/4
        let currentDate = seekTarget - seekOffset
        
        let env = TestEnv(environment: environment, sessionToken: token)
        env.player.context.isDynamicManifest = { _,_ in return true }
        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour))
        
        // Mock the ProgramService
        env.mockProgramService{ environment, sessionToken, channelId in
            let provider = MockedProgramProvider()
            provider.mockedFetchProgram = { _,timestamp,_, callback in
                if timestamp < currentDate + hour / 2 {
                    let program = Program
                        .validJson(programId: "program1", channelId: "channelId", assetId: "asset1")
                        .timestamp(starting: currentDate, ending: currentDate+hour/2)
                        .decodeWrap(Program.self)
                    callback(program,nil)
                }
                else {
                    let program = Program
                        .validJson(programId: "program2", channelId: "channelId", assetId: "asset2_entitled")
                        .timestamp(starting: currentDate+hour/2, ending: currentDate+hour)
                        .decodeWrap(Program.self)
                    callback(program,nil)
                }
            }
            provider.mockedValidate = { programId, environment, sessionToken, callback in
                callback(EntitlementValidation.validJson(status: "SUCCESS").decode(EntitlementValidation.self),nil)
            }
            let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
            service.fuzzyConfiguration.fuzzyFactor = 1000
            service.provider = provider
            return service
        }
        
        env.player
            .onProgramChanged { player, source, program in
                player.seek(toTime: seekTarget)
            }
            .onPlaybackReady { player, source in
                if let avPlayer = player.tech.avPlayer as? MockedAVPlayer {
                    avPlayer.mockedRate = 1
                }
        }
        env.player.startPlayback(playable: playable)

        return env
    }
    
    func runAfterBoundsErrorFetchingEpg(playable: Playable, properties: PlaybackProperties = PlaybackProperties(), seekTarget: Int64) -> TestEnv {
        let hour: Int64 = 60 * 60 * 1000
        let seekOffset: Int64 = hour * 3/4
        let currentDate = seekTarget - seekOffset
        
        let env = TestEnv(environment: environment, sessionToken: token)
        env.player.context.isDynamicManifest = { _,_ in return true }
        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour))
        
        // Mock the ProgramService
        env.mockProgramService{ environment, sessionToken, channelId in
            let provider = MockedProgramProvider()
            provider.mockedFetchProgram = { _,timestamp,_, callback in
                if timestamp < currentDate + hour / 2 {
                    let program = Program
                        .validJson(programId: "program1", channelId: "channelId", assetId: "asset1")
                        .timestamp(starting: currentDate, ending: currentDate+hour/2)
                        .decodeWrap(Program.self)
                    callback(program,nil)
                }
                else {
                    callback(nil, ExposureError.exposureResponse(reason: ExposureResponseMessage(httpCode: 401, message: "SOME_ERROR")))
                }
            }
            
            let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
            service.fuzzyConfiguration.fuzzyFactor = 1000
            service.provider = provider
            return service
        }
        
        
        env.player
            .onProgramChanged { player, source, program in
                player.seek(toTime: seekTarget)
            }
            .onWarning{ [weak env] player, source, warn in
                env?.warning = warn
            }
            .onPlaybackReady { player, source in
                if let avPlayer = player.tech.avPlayer as? MockedAVPlayer {
                    avPlayer.mockedRate = 1
                }
        }
        env.player.startPlayback(playable: playable)

        return env
    }
    
    func runAfterBoundsErrorValidating(playable: Playable, properties: PlaybackProperties = PlaybackProperties(), seekTarget: Int64) -> TestEnv {
        let hour: Int64 = 60 * 60 * 1000
        let seekOffset: Int64 = hour * 3/4
        let currentDate = seekTarget - seekOffset
        
        let env = TestEnv(environment: environment, sessionToken: token)
        env.player.context.isDynamicManifest = { _,_ in return true }
        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour))
        
        // Mock the ProgramService
        env.mockProgramService{ environment, sessionToken, channelId in
            let provider = MockedProgramProvider()
            provider.mockedFetchProgram = { _,timestamp,_, callback in
                if timestamp < currentDate + hour / 2 {
                    let program = Program
                        .validJson(programId: "program1", channelId: "channelId", assetId: "asset1")
                        .timestamp(starting: currentDate, ending: currentDate+hour/2)
                        .decodeWrap(Program.self)
                    callback(program,nil)
                }
                else {
                    let program = Program
                        .validJson(programId: "program2", channelId: "channelId", assetId: "asset2_error_validating")
                        .timestamp(starting: currentDate+hour/2, ending: currentDate+hour)
                        .decodeWrap(Program.self)
                    callback(program,nil)
                }
            }
            provider.mockedValidate = { _,_,_, callback in
                callback(nil, ExposureError.exposureResponse(reason: ExposureResponseMessage(httpCode: 401, message: "SOME_ERROR")))
            }
            let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
            service.fuzzyConfiguration.fuzzyFactor = 1000
            service.provider = provider
            return service
        }
        
        
        env.player
            .onProgramChanged { player, source, program in
                player.seek(toTime: seekTarget)
            }
            .onWarning{ [weak env] player, source, warn in
                env?.warning = warn
            }
            .onPlaybackReady { player, source in
                if let avPlayer = player.tech.avPlayer as? MockedAVPlayer {
                    avPlayer.mockedRate = 1
                }
            }
        env.player.startPlayback(playable: playable)

        
        return env
    }
    
    func runAfterBoundsGapInEpg(playable: Playable, properties: PlaybackProperties = PlaybackProperties(), seekTarget: Int64) -> TestEnv {
        let hour: Int64 = 60 * 60 * 1000
        let seekOffset: Int64 = hour * 3/4
        let currentDate = seekTarget - seekOffset
        
        let env = TestEnv(environment: environment, sessionToken: token)
        env.player.context.isDynamicManifest = { _,_ in return true }
        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour))
        
        // Mock the ProgramService
        env.mockProgramService{ environment, sessionToken, channelId in
            let provider = MockedProgramProvider()
            provider.mockedFetchProgram = { _,timestamp,_, callback in
                if timestamp < currentDate + hour / 2 {
                    let program = Program
                        .validJson(programId: "program1", channelId: "channelId", assetId: "asset1")
                        .timestamp(starting: currentDate, ending: currentDate+hour/2)
                        .decodeWrap(Program.self)
                    callback(program,nil)
                }
                else {
                    // GAP IN EPG
                    callback(nil,nil)
                }
            }
            let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
            service.fuzzyConfiguration.fuzzyFactor = 1000
            service.provider = provider
            return service
        }
        
        env.player
            .onProgramChanged { player, source, program in
                player.seek(toTime: seekTarget)
            }
            .onWarning{ [weak env] player, source, warn in
                env?.warning = warn
            }
            .onPlaybackReady { player, source in
                if let avPlayer = player.tech.avPlayer as? MockedAVPlayer {
                    avPlayer.mockedRate = 1
                }
        }
        env.player.startPlayback(playable: playable)

        return env
    }
    
    func runAfterBoundsNotEntitled(playable: Playable, properties: PlaybackProperties = PlaybackProperties(), seekTarget: Int64) -> TestEnv {
        let hour: Int64 = 60 * 60 * 1000
        let seekOffset: Int64 = hour * 3/4
        let currentDate = seekTarget - seekOffset
        
        let env = TestEnv(environment: environment, sessionToken: token)
        env.player.context.isDynamicManifest = { _,_ in return true }
        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour))
        
        // Mock the ProgramService
        env.mockProgramService{ environment, sessionToken, channelId in
            let provider = MockedProgramProvider()
            provider.mockedFetchProgram = { _,timestamp,_, callback in
                if timestamp < currentDate + hour / 2 {
                    let program = Program
                        .validJson(programId: "program1", channelId: "channelId", assetId: "asset1")
                        .timestamp(starting: currentDate, ending: currentDate+hour/2)
                        .decodeWrap(Program.self)
                    callback(program,nil)
                }
                else {
                    let program = Program
                        .validJson(programId: "program2", channelId: "channelId", assetId: "asset2_not_entitled")
                        .timestamp(starting: currentDate+hour/2, ending: currentDate+hour)
                        .decodeWrap(Program.self)
                    callback(program,nil)
                }
            }
            provider.mockedValidate = { assetId, environment, sessionToken, callback in
                if assetId == "asset2_not_entitled" {
                    callback(EntitlementValidation.validJson(status: "NOT_ENTITLED").decode(EntitlementValidation.self),nil)
                }
                else {
                    callback(EntitlementValidation.validJson(status: "SUCCESS").decode(EntitlementValidation.self),nil)
                }
            }
            let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
            service.fuzzyConfiguration.fuzzyFactor = 1000
            service.provider = provider
            return service
        }
        
        env.player
            .onProgramChanged { player, source, program in
                player.seek(toTime: seekTarget)
            }
            .onError{ [weak env] tech, source, err in
                env?.error = err
            }
            .onPlaybackReady { player, source in
                if let avPlayer = player.tech.avPlayer as? MockedAVPlayer {
                    avPlayer.mockedRate = 1
                }
        }
        env.player.startPlayback(playable: playable)

        return env
    }
    
    func runAfterSeekableRangeBeyondLive(playable: Playable, properties: PlaybackProperties = PlaybackProperties(), seekTarget: Int64, overshot: Int64) -> TestEnv {
        let hour: Int64 = 60 * 60 * 1000
        let livePointOffet = hour/2
        let livePointDelay: Int64 = 25 * 1000
        
        let currentDate = seekTarget - livePointOffet - overshot
        
        let env = TestEnv(environment: environment, sessionToken: token)
        env.player.context.isDynamicManifest = { _,_ in return true }
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
        
        // ServerTime is required for LiveDelay to work properly
        _ = env.player.serverTime
        
        // Mock the ProgramService
        env.mockProgramService{ environment, sessionToken, channelId in
            let provider = MockedProgramProvider()
            provider.mockedFetchProgram = { _,_,_, callback in
                let program = Program
                    .validJson(programId: "program1", channelId: "channelId", assetId: "assetId")
                    .timestamp(starting: currentDate, ending: currentDate+hour)
                    .decodeWrap(Program.self)
                callback(program,nil)
            }
            let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
            service.fuzzyConfiguration.fuzzyFactor = 1000
            service.provider = provider
            return service
        }
        
        env.player
            .onProgramChanged { player, source, program in
                player.seek(toTime: seekTarget)
            }
            .onPlaybackReady { player, source in
                if let avPlayer = player.tech.avPlayer as? MockedAVPlayer {
                    avPlayer.mockedRate = 1
                }
            }
            .onWarning{ [weak env] player, source, warn in
                env?.warning = warn
        }
        
        env.player.startPlayback(playable: playable)

        
        return env
    }
    
    func runBeforeSeekableRangeErrorFetchingEpg(playable: Playable, properties: PlaybackProperties = PlaybackProperties(), currentDate: Int64, seekOffset: Int64) -> TestEnv {
        let hour: Int64 = 60 * 60 * 1000
        let seekTarget = currentDate - seekOffset
        
        let env = TestEnv(environment: environment, sessionToken: token)
        env.player.context.isDynamicManifest = { _,_ in return true }
        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour))
        
        // Mock the ProgramService
        env.mockProgramService{ environment, sessionToken, channelId in
            let provider = MockedProgramProvider()
            provider.mockedFetchProgram = { _,timestamp,_, callback in
                if timestamp < currentDate {
                    callback(nil, ExposureError.exposureResponse(reason: ExposureResponseMessage(httpCode: 401, message: "SOME_ERROR")))
                }
                else {
                    let program = Program
                        .validJson(programId: "program1", channelId: "channelId", assetId: "asset1")
                        .timestamp(starting: currentDate, ending: currentDate+hour/2)
                        .decodeWrap(Program.self)
                    callback(program,nil)
                }
            }
            
            let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
            service.fuzzyConfiguration.fuzzyFactor = 1000
            service.provider = provider
            return service
        }
        
        env.player
            .onProgramChanged { player, source, program in
                player.seek(toTime: seekTarget)
            }
            .onWarning{ [weak env] player, source, warn in
                env?.warning = warn
            }
            .onPlaybackReady { player, source in
                if let avPlayer = player.tech.avPlayer as? MockedAVPlayer {
                    avPlayer.mockedRate = 1
                }
        }
        env.player.startPlayback(playable: playable)

        return env
    }
    
    func runBeforeSeekableRangeGapInEpg(playable: Playable, properties: PlaybackProperties = PlaybackProperties(), currentDate: Int64, seekOffset: Int64) -> TestEnv {
        let hour: Int64 = 60 * 60 * 1000
        let seekTarget = currentDate - seekOffset
        
        let env = TestEnv(environment: environment, sessionToken: token)
        env.player.context.isDynamicManifest = { _,_ in return true }
        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour))
        
        // Mock the ProgramService
        env.mockProgramService{ environment, sessionToken, channelId in
            let provider = MockedProgramProvider()
            provider.mockedFetchProgram = { _,timestamp,_, callback in
                if timestamp < currentDate {
                    // GAP IN EPG
                    callback(nil,nil)
                }
                else {
                    let program = Program
                        .validJson(programId: "program1", channelId: "channelId", assetId: "asset1")
                        .timestamp(starting: currentDate, ending: currentDate+hour/2)
                        .decodeWrap(Program.self)
                    callback(program,nil)
                }
            }
            let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
            service.fuzzyConfiguration.fuzzyFactor = 1000
            service.provider = provider
            return service
        }
        
        env.player
            .onProgramChanged { player, source, program in
                player.seek(toTime: seekTarget)
            }
            .onWarning{ [weak env] player, source, warn in
                env?.warning = warn
            }
            .onPlaybackReady { player, source in
                if let avPlayer = player.tech.avPlayer as? MockedAVPlayer {
                    avPlayer.mockedRate = 1
                }
        }
        env.player.startPlayback(playable: playable)

        return env
    }
    
    func runBeforeSeekableRangeProgramServiceSeekErrorPlaycall(playable: Playable, properties: PlaybackProperties = PlaybackProperties(), currentDate: Int64, seekOffset: Int64) -> TestEnv {
        let hour: Int64 = 60 * 60 * 1000
        let seekTarget = currentDate - seekOffset
        
        let env = TestEnv(environment: environment, sessionToken: token)
        env.player.context.isDynamicManifest = { _,_ in return true }
        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour))
        
        // Mock the ProgramService
        env.mockProgramService{ environment, sessionToken, channelId in
            let provider = MockedProgramProvider()
            provider.mockedFetchProgram = { _,timestamp,_, callback in
                if timestamp < currentDate {
                    let program = Program
                        .validJson(programId: "program0", channelId: "channelId", assetId: "asset0")
                        .timestamp(starting: currentDate, ending: currentDate+hour/2)
                        .decodeWrap(Program.self)
                    callback(program,nil)
                }
                else {
                    let program = Program
                        .validJson(programId: "program1", channelId: "channelId", assetId: "asset1")
                        .timestamp(starting: currentDate, ending: currentDate+hour/2)
                        .decodeWrap(Program.self)
                    callback(program,nil)
                }
            }
            let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
            service.fuzzyConfiguration.fuzzyFactor = 1000
            service.provider = provider
            return service
        }
        
        // Mock the ProgramService playable generator
        env.mockProgramServicePlayable{ program in
            let provider = MockedProgramEntitlementProvider()
            provider.mockedRequestEntitlement = { _,_,_,_, callback in
                callback(nil, ExposureError.exposureResponse(reason: ExposureResponseMessage(httpCode: 404, message: "SOME_ERROR")))
            }
            return ProgramPlayable(assetId: program.programId, channelId: program.channelId, entitlementProvider: provider)
        }
        
        env.player
            .onProgramChanged { player, source, program in
                player.seek(toTime: seekTarget)
            }
            .onError{ [weak env] player, source, err in
                env?.error = err
            }
            .onPlaybackReady { player, source in
                if let avPlayer = player.tech.avPlayer as? MockedAVPlayer {
                    avPlayer.mockedRate = 1
                }
        }
        env.player.startPlayback(playable: playable)

        return env
    }
    
    
    
    func runBeforeSeekableRangeProgramServiceSeekEntitled(playable: Playable, properties: PlaybackProperties = PlaybackProperties(), currentDate: Int64, seekOffset: Int64) -> TestEnv {
        let hour: Int64 = 60 * 60 * 1000
        let seekTarget = currentDate - seekOffset
        
        let env = TestEnv(environment: environment, sessionToken: token)
        env.player.context.isDynamicManifest = { _,_ in return true }
        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour))
        
        // Mock the ProgramService
        env.mockProgramService{ environment, sessionToken, channelId in
            let provider = MockedProgramProvider()
            provider.mockedFetchProgram = { _,timestamp,_, callback in
                if timestamp < currentDate {
                    let program = Program
                        .validJson(programId: "program0", channelId: "channelId", assetId: "asset0")
                        .timestamp(starting: currentDate, ending: currentDate+hour/2)
                        .decodeWrap(Program.self)
                    callback(program,nil)
                }
                else {
                    let program = Program
                        .validJson(programId: "program1", channelId: "channelId", assetId: "asset1")
                        .timestamp(starting: currentDate, ending: currentDate+hour/2)
                        .decodeWrap(Program.self)
                    callback(program,nil)
                }
            }
            let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
            service.fuzzyConfiguration.fuzzyFactor = 1000
            service.fuzzyConfiguration.fuzzyFactor = 1000
            service.provider = provider
            return service
        }
        
        // Mock the ProgramService playable generator
        env.mockProgramServicePlayable{ program in
            let provider = MockedProgramEntitlementProvider()
            provider.mockedRequestEntitlement = { _,_,_,_, callback in
                var json = PlaybackEntitlement.requiedJson
                json["mediaLocator"] = "file://play/.isml"
                json["playToken"] = "ProgramSevicedFetchedEntitlement"
                json["ffEnabled"] = false
                json["rwEnabled"] = false
                json["timeshiftEnabled"] = false
                callback(json.decode(PlaybackEntitlement.self), nil)
            }
            return ProgramPlayable(assetId: program.programId, channelId: program.channelId, entitlementProvider: provider)
        }
        
        
        env.player
            .onProgramChanged { player, source, program in
                player.seek(toTime: seekTarget)
            }
            .onPlaybackReady { player, source in
                if let avPlayer = player.tech.avPlayer as? MockedAVPlayer {
                    avPlayer.mockedRate = 1
                }
        }
        env.player.startPlayback(playable: playable)
        
        return env
    }
    
    func runEnforceContractRestrictions(playable: Playable, properties: PlaybackProperties = PlaybackProperties(), currentDate: Int64, seekOffset: Int64) -> TestEnv {
        let hour: Int64 = 60 * 60 * 1000
        let seekTarget = currentDate + seekOffset
        
        let env = TestEnv(environment: environment, sessionToken: token)
        env.player.context.isDynamicManifest = { _,_ in return true }
        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour))
        
        // Mock the ProgramService
        env.mockProgramService{ environment, sessionToken, channelId in
            let provider = MockedProgramProvider()
            provider.mockedFetchProgram = { _,timestamp,_, callback in
                let program = Program
                    .validJson(programId: "program1", channelId: "channelId", assetId: "asset1")
                    .timestamp(starting: currentDate, ending: currentDate+hour/2)
                    .decodeWrap(Program.self)
                callback(program,nil)
            }
            let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
            service.fuzzyConfiguration.fuzzyFactor = 1000
            service.provider = provider
            return service
        }
        
        
        env.player
            .onProgramChanged { player, source, program in
                player.seek(toTime: seekTarget)
            }
            .onWarning{ [weak env] player, source, warn in
                env?.warning = warn
            }
            .onPlaybackReady { player, source in
                if let avPlayer = player.tech.avPlayer as? MockedAVPlayer {
                    avPlayer.mockedRate = 1
                }
        }
        env.player.startPlayback(playable: playable)
        
        return env
    }
}
