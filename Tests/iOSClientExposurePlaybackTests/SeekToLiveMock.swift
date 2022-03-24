//
//  SeekToLiveMock.swift
//  ExposurePlaybackTests
//
//  Created by Fredrik Sjöberg on 2018-03-05.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import iOSClientExposure

@testable import iOSClientPlayer
@testable import iOSClientExposurePlayback

class SeekToLiveMock {
    let environment = Environment(baseUrl: "http://www.example.com", customer: "customer", businessUnit: "businessUnit")
    let token = SessionToken(value: "token")
    
    func runEntitledTest(playable: Playable, properties: PlaybackProperties) -> TestEnv {
        let currentDate = Date().unixEpoch
        let hour: Int64 = 60 * 60 * 1000
        
        let env = TestEnv(environment: environment, sessionToken: token)
        env.player.context.isDynamicManifest = { _,_ in return true }
        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour) { urlAsset, playerItem in
            
        })
        
        // Mock the ProgramService
        env.mockProgramService{ environment, sessionToken, channelId in
            let provider = MockedProgramProvider()
            provider.mockedFetchProgram = { _,timestamp,_, callback in
                if timestamp > currentDate + hour/2 {
                    let program = Program
                        .validJson(programId: "program2", channelId: "channelId", assetId: "asset1")
                        .timestamp(starting: currentDate + hour / 2, ending: currentDate+2*hour)
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
            provider.mockedValidate = { _,_,_, callback in
                callback(EntitlementValidation.validJson(status: "SUCCESS").decode(EntitlementValidation.self),nil)
            }
            let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
            service.fuzzyConfiguration.fuzzyFactor = 1000
            service.provider = provider
            return service
        }
        
        // Initiate test
        env.player
            .onProgramChanged { player, source, program in
                if source.entitlement.playSessionId == "SeekToLiveTrigger" {
                    player.seekToLive()
                }
            }
            .onPlaybackReady{ player, source in
                if let avPlayer = player.tech.avPlayer as? MockedAVPlayer {
                    avPlayer.mockedRate = 1
                }
        }
        env.player.startPlayback(playable: playable, properties: properties)
        
        return env
    }
    
    func runErrorFetchingEpgTest(playable: Playable, properties: PlaybackProperties) -> TestEnv {
        let currentDate = Date().unixEpoch
        let hour: Int64 = 60 * 60 * 1000
        
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
            service.provider = provider
            return service
        }
        
        // Initiate test
        env.player
            .onProgramChanged { player, source, program in
                if source.entitlement.playSessionId == "SeekToLiveTrigger" {
                    player.seekToLive()
                }
            }
            .onWarning{ [weak env] player, source, warn in
                env?.warning = warn
            }
            .onPlaybackReady{ player, source in
                if let avPlayer = player.tech.avPlayer as? MockedAVPlayer {
                    avPlayer.mockedRate = 1
                }
        }
        env.player.startPlayback(playable: playable, properties: properties)
        return env
    }
    
    func runErrorValidatingEntitlementTest(playable: Playable, properties: PlaybackProperties) -> TestEnv {
        let currentDate = Date().unixEpoch
        let hour: Int64 = 60 * 60 * 1000
        
        let env = TestEnv(environment: environment, sessionToken: token)
        env.player.context.isDynamicManifest = { _,_ in return true }
        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour))
        
        // Mock the ProgramService
        env.mockProgramService{ environment, sessionToken, channelId in
            let provider = MockedProgramProvider()
            provider.mockedFetchProgram = { _,timestamp,_, callback in
                if timestamp < currentDate + hour / 2 {
                    let program = Program
                        .validJson(programId: "SeekToLiveTrigger", channelId: "channelId", assetId: "asset1")
                        .timestamp(starting: currentDate, ending: currentDate+hour/2)
                        .decodeWrap(Program.self)
                    callback(program,nil)
                }
                else {
                    let program = Program
                        .validJson(programId: "program2", channelId: "channelId", assetId: "asset2")
                        .timestamp(starting: currentDate+hour/2, ending: currentDate+2*hour)
                        .decodeWrap(Program.self)
                    callback(program,nil)
                }
            }
            provider.mockedValidate = { _,_,_, callback in
                callback(nil, ExposureError.exposureResponse(reason: ExposureResponseMessage(httpCode: 401, message: "SOME_ERROR")))
            }
            let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
            service.provider = provider
            return service
        }
        
        // Initiate test
        env.player
            .onProgramChanged { player, source, program in
                if program?.programId == "SeekToLiveTrigger" {
                    print("SeekingToLive",program?.programId)
                    player.seekToLive()
                }
            }
            .onWarning{ [weak env] player, source, warn in
                env?.warning = warn
            }
            .onPlaybackReady{ player, source in
                if let avPlayer = player.tech.avPlayer as? MockedAVPlayer {
                    avPlayer.mockedRate = 1
                }
        }
        env.player.startPlayback(playable: playable, properties: properties)
        
        return env
    }
    
    func runGapInEpgTest(playable: Playable, properties: PlaybackProperties) -> TestEnv {
        let currentDate = Date().unixEpoch
        let hour: Int64 = 60 * 60 * 1000
        
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
            service.provider = provider
            return service
        }
        
        
        // Initiate test
        env.player
            .onProgramChanged { player, source, program in
                if source.entitlement.playSessionId == "SeekToLiveTrigger" {
                    player.seekToLive()
                }
            }
            .onWarning{ [weak env] player, source, warn in
                env?.warning = warn
            }
            .onPlaybackReady{ player, source in
                if let avPlayer = player.tech.avPlayer as? MockedAVPlayer {
                    avPlayer.mockedRate = 1
                }
        }
        env.player.startPlayback(playable: playable, properties: properties)
        
        return env
    }
    
    func runNotEntitledTest(playable: Playable, properties: PlaybackProperties) -> TestEnv {
        let currentDate = Date().unixEpoch
        let hour: Int64 = 60 * 60 * 1000
        
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
                        .validJson(programId: "program2", channelId: "channelId", assetId: "asset2")
                        .timestamp(starting: currentDate+hour/2, ending: currentDate+2*hour)
                        .decodeWrap(Program.self)
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
        
        
        // Initiate test
        env.player
            .onProgramChanged { player, source, program in
                if source.entitlement.playSessionId == "SeekToLiveTrigger" {
                    player.seekToLive()
                }
            }
            .onError{ [weak env] tech, source, err in
                env?.error = err
            }
            .onPlaybackReady{ player, source in
                if let avPlayer = player.tech.avPlayer as? MockedAVPlayer {
                    avPlayer.mockedRate = 1
                }
        }
        env.player.startPlayback(playable: playable, properties: properties)
        
        return env
    }
}
