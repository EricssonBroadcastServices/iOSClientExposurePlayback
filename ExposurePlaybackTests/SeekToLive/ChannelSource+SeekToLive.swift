//
//  ChannelSource+SeekToLive.swift
//  ExposurePlaybackTests
//
//  Created by Fredrik Sjöberg on 2018-02-14.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation

import Quick
import Nimble
import Exposure
import AVFoundation

@testable import Player
@testable import ExposurePlayback

class ChannelSourceSeekToLiveSpec: QuickSpec {
    override func spec() {
        super.spec()
        
        describe("SeekToLive ChannelSource") {
            let currentDate = Date().unixEpoch
            let hour: Int64 = 60 * 60 * 1000
            
            let env = Environment(baseUrl: "http://www.example.com", customer: "customer", businessUnit: "businessUnit")
            let token = SessionToken(value: "token")
            
            // Seekable range is defined by the manifest
            // MARK: After seekableTimeRange
            ///  |---+-------|-----> live
            ///  p1  |       p2    |
            ///  r1  |             r2
            ///      s1 ---------> s2
            
            // MARK: + ENTITLED
            context("ENTITLED") {
                it("should allow playback") {
                    let env = TestEnv(environment: env, sessionToken: token)
                    env.player.context.isDynamicManifest = { _,_ in return true }
                    env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour))
                    
                    // Mock the ProgramService
                    env.mockProgramService{ environment, sessionToken, channelId in
                        let provider = MockedProgramProvider()
                        provider.mockedFetchProgram = { _,timestamp,_, callback in
                            if timestamp > currentDate + hour/2 {
                                let program = Program
                                    .validJson(programId: "program2", channelId: "channelId", assetId: "asset0")
                                    .timestamp(starting: currentDate + hour / 2, ending: currentDate+2*hour)
                                    .decode(Program.self)
                                callback(program,nil)
                            }
                            else {
                                let program = Program
                                    .validJson(programId: "program1", channelId: "channelId", assetId: "asset1")
                                    .timestamp(starting: currentDate, ending: currentDate+hour/2)
                                    .decode(Program.self)
                                callback(program,nil)
                            }
                        }
                        provider.mockedValidate = { _,_,_, callback in
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
                        json["playSessionId"] = "SeekToLiveTrigger"
                        json["ffEnabled"] = false
                        json["rwEnabled"] = false
                        json["timeshiftEnabled"] = false
                        callback(json.decode(PlaybackEntitlement.self), nil)
                    }
                    let playable = ChannelPlayable(assetId: "channelId", entitlementProvider: provider)
                    let properties = PlaybackProperties(playFrom: .defaultBehaviour)
                    
                    // Initiate test
                    env.player
                        .onProgramChanged { player, source, program in
                            if source.entitlement.playSessionId == "SeekToLiveTrigger" {
                                player.seekToLive()
                            }
                    }
                    env.player.startPlayback(playable: playable, properties: properties)
                    
                    expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 3)
                    expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 3)
                    expect{ env.player.playheadTime != nil ? abs(env.player.playheadTime! - (currentDate + hour)) : nil }.toEventually(beLessThan(1000), timeout: 3)
                }
            }
            
            // MARK: + Error fetching EPG
            context("Error fetching EPG") {
                it("should allow seek to live with warning message") {
                    let env = TestEnv(environment: env, sessionToken: token)
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
                                    .decode(Program.self)
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
                    
                    // Configure the playable
                    let provider = MockedChannelEntitlementProvider()
                    provider.mockedRequestEntitlement = { _,_,_, callback in
                        var json = PlaybackEntitlement.requiedJson
                        json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                        json["playSessionId"] = "SeekToLiveTrigger"
                        json["ffEnabled"] = false
                        json["rwEnabled"] = false
                        json["timeshiftEnabled"] = false
                        callback(json.decode(PlaybackEntitlement.self), nil)
                    }
                    let playable = ChannelPlayable(assetId: "channelId", entitlementProvider: provider)
                    let properties = PlaybackProperties(playFrom: .defaultBehaviour)
                    
                    // Initiate test
                    var warning: PlayerWarning<HLSNative<ExposureContext>,ExposureContext>? = nil
                    env.player
                        .onProgramChanged { player, source, program in
                            if source.entitlement.playSessionId == "SeekToLiveTrigger" {
                                player.seekToLive()
                            }
                        }
                        .onWarning{ player, source, warn in
                            warning = warn
                    }
                    env.player.startPlayback(playable: playable, properties: properties)
                    
                    expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 3)
                    expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 3)
                    expect(warning).toEventuallyNot(beNil(), timeout: 3)
                    expect(warning?.message).toEventually(contain("Program Service failed to fetch the current program at timestamp"), timeout: 3)
                    expect{ env.player.playheadTime != nil ? abs(env.player.playheadTime! - (currentDate + hour)) : nil }.toEventually(beLessThan(1000), timeout: 3)
                }
            }

            // MARK: + Error validating entitlement
            context("Error validating entitlement") {
                it("should allow seek to live with warning message") {
                    let env = TestEnv(environment: env, sessionToken: token)
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
                        provider.mockedValidate = { _,_,_, callback in
                            callback(nil, ExposureError.exposureResponse(reason: ExposureResponseMessage(httpCode: 401, message: "SOME_ERROR")))
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
                        json["playSessionId"] = "SeekToLiveTrigger"
                        json["ffEnabled"] = false
                        json["rwEnabled"] = false
                        json["timeshiftEnabled"] = false
                        callback(json.decode(PlaybackEntitlement.self), nil)
                    }
                    let playable = ChannelPlayable(assetId: "channelId", entitlementProvider: provider)
                    let properties = PlaybackProperties(playFrom: .defaultBehaviour)
                    
                    // Initiate test
                    var warning: PlayerWarning<HLSNative<ExposureContext>,ExposureContext>? = nil
                    env.player
                        .onProgramChanged { player, source, program in
                            if source.entitlement.playSessionId == "SeekToLiveTrigger" {
                                player.seekToLive()
                            }
                        }
                        .onWarning{ player, source, warn in
                            warning = warn
                    }
                    env.player.startPlayback(playable: playable, properties: properties)
                    
                    expect(warning).toEventuallyNot(beNil(), timeout: 3)
                    expect(warning?.message).toEventually(contain("Program Service failed to validate program"), timeout: 3)
                }
            }
            
            // MARK: + Gap in EPG
            context("Gap in EPG"){
                it("should allow seek to live if encountering epg gap") {
                    let env = TestEnv(environment: env, sessionToken: token)
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
                                    .decode(Program.self)
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
                    
                    // Configure the playable
                    let provider = MockedChannelEntitlementProvider()
                    provider.mockedRequestEntitlement = { _,_,_, callback in
                        var json = PlaybackEntitlement.requiedJson
                        json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                        json["playSessionId"] = "SeekToLiveTrigger"
                        json["ffEnabled"] = false
                        json["rwEnabled"] = false
                        json["timeshiftEnabled"] = false
                        callback(json.decode(PlaybackEntitlement.self), nil)
                    }
                    let playable = ChannelPlayable(assetId: "channelId", entitlementProvider: provider)
                    let properties = PlaybackProperties(playFrom: .defaultBehaviour)
                    
                    // Initiate test
                    var warning: PlayerWarning<HLSNative<ExposureContext>,ExposureContext>? = nil
                    env.player
                        .onProgramChanged { player, source, program in
                            if source.entitlement.playSessionId == "SeekToLiveTrigger" {
                                player.seekToLive()
                            }
                        }
                        .onWarning{ player, source, warn in
                            warning = warn
                    }
                    env.player.startPlayback(playable: playable, properties: properties)
                    
                    expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 3)
                    expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 3)
                    expect(warning).toEventuallyNot(beNil(), timeout: 3)
                    expect(warning?.message).toEventually(contain("Program Service encountered a gap in the Epg at timestamp"), timeout: 3)
                    expect{ env.player.playheadTime != nil ? abs(env.player.playheadTime! - (currentDate + hour)) : nil }.toEventually(beLessThan(1000), timeout: 3)
                }
            }

            // MARK: + NOT_ENTITLED
            context("NOT_ENTITLED") {
                it("should stop with error if not entitled") {
                    let env = TestEnv(environment: env, sessionToken: token)
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
                        json["playSessionId"] = "SeekToLiveTrigger"
                        json["ffEnabled"] = false
                        json["rwEnabled"] = false
                        json["timeshiftEnabled"] = false
                        callback(json.decode(PlaybackEntitlement.self), nil)
                    }
                    let playable = ChannelPlayable(assetId: "channelId", entitlementProvider: provider)
                    let properties = PlaybackProperties(playFrom: .defaultBehaviour)
                    
                    // Initiate test
                    var error: PlayerError<HLSNative<ExposureContext>,ExposureContext>? = nil
                    env.player
                        .onProgramChanged { player, source, program in
                            if source.entitlement.playSessionId == "SeekToLiveTrigger" {
                                player.seekToLive()
                            }
                        }
                        .onError{ tech, source, err in
                            error = err
                    }
                    env.player.startPlayback(playable: playable, properties: properties)
                    
                    expect(error).toEventuallyNot(beNil(), timeout: 3)
                    expect(error?.code).toEventually(equal(403))
                    expect(error?.message).toEventually(equal("NOT_ENTITLED"))
                }
            }
        }
    }
}
