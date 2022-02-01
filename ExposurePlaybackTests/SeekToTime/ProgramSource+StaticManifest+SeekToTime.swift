//
//  ProgramSource+StaticManifest+SeekToTime.swift
//  ExposurePlaybackTests
//
//  Created by Fredrik Sjöberg on 2018-02-13.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation

import Quick
import Nimble
import Exposure
//import AVFoundation

@testable import Player
@testable import ExposurePlayback

class StaticProgramSourceSeekToTimeSpec: QuickSpec {
    override func spec() {
        super.spec()
        
        describe("SeekToTime Static ProgramSource") {
            let currentDate = Date().unixEpoch
            let hour: Int64 = 60 * 60 * 1000
            
            let env = Environment(baseUrl: "http://www.example.com", customer: "customer", businessUnit: "businessUnit")
            let token = SessionToken(value: "token")

            // Seekable range is defined by the manifest
            // MARK: After seekableTimeRange
            context("After seekableTimeRange") {
                ///  |---+-------|.....+.......x
                ///  p1  |       p2    |       p3
                ///  r1  |       r2    |
                ///      s1 --------> s2
                
                // MARK: + Error fetching EPG
                context("Error fetching EPG") {
                    it("should ignore seek with warning message") {
                        let env = TestEnv(environment: env, sessionToken: token)
                        env.player.context.isDynamicManifest = { _,_ in return false }
                        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour/2))

                        // Mock the ProgramService
                        env.mockProgramService{ environment, sessionToken, channelId in
                            let provider = MockedProgramProvider()
                            provider.mockedFetchProgram = { _,timestamp,_, callback in
                                if timestamp > currentDate + hour / 2 {
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
                            service.provider = provider
                            return service
                        }

                        // Configure the playable
                        let provider = MockedProgramEntitlementProvider()
                        provider.mockedRequestEntitlementV2 = { _,_,_, callback in
                            var json = PlaybackEntitlement.requiedJson
                            json["mediaLocator"] = "file://play/.isml"
                            json["ffEnabled"] = true
                            
                            let contractRestrictions: [String: Any] = [
                                "airplayEnabled" : true,
                                "ffEnabled" : true,
                                "maxBitrate" : 20,
                                "maxResHeight" : 30,
                                "minBitrate": 10,
                                "rwEnabled": false,
                                "timeshiftEnabled" : false
                            ]
                            
                            var entitlementVersion2Json = PlayBackEntitlementV2.requiedJson
                            entitlementVersion2Json["contractRestrictions"] = contractRestrictions
                            
                            callback(json.decode(PlaybackEntitlement.self), entitlementVersion2Json.decode(PlayBackEntitlementV2.self), nil, nil)
                        }
                        let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                        let properties = PlaybackProperties(playFrom: .defaultBehaviour)

                        // Initiate test
                        let seekTarget = currentDate + hour * 3/4
                        var warning: PlayerWarning<HLSNative<ExposureContext>,ExposureContext>? = nil
                        env.player
                            .onProgramChanged { player, source, program in
                                player.seek(toTime: seekTarget)
                            }
                            .onPlaybackReady { player, source in
                                if let avPlayer = player.tech.avPlayer as? MockedAVPlayer {
                                    avPlayer.mockedRate = 1
                                }
                            }
                            .onWarning{ player, source, warn in
                                warning = warn
                        }
                        env.player.startPlayback(playable: playable, properties: properties)

                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: .seconds(5))
                        expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: .seconds(5))
                        expect(warning).toEventuallyNot(beNil(), timeout: .seconds(5))
                        expect(warning?.message).toEventually(contain("Program Service failed to fetch the current program at timestamp"), timeout: .seconds(5))
                        // expect{ return env.player.playheadTime != nil ? abs(env.player.playheadTime! - currentDate) : nil }.toEventually(beLessThan(1000), timeout: .seconds(5))
                    }
                }

                // MARK: + Gap in EPG
                context("Gap in EPG"){
                    it("should ignore seek if encountering epg gap") {
                        let env = TestEnv(environment: env, sessionToken: token)
                        env.player.context.isDynamicManifest = { _,_ in return false }
                        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour/2))

                        // Mock the ProgramService
                        env.mockProgramService{ environment, sessionToken, channelId in
                            let provider = MockedProgramProvider()
                            provider.mockedFetchProgram = { _,timestamp,_, callback in
                                if timestamp > currentDate + hour / 2 {
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
                            service.provider = provider
                            return service
                        }

                        // Configure the playable
                        let provider = MockedProgramEntitlementProvider()
                        provider.mockedRequestEntitlementV2 = { _,_,_, callback in
                            var json = PlaybackEntitlement.requiedJson
                            json["mediaLocator"] = "file://play/.isml"
                            json["ffEnabled"] = true
                            
                            let contractRestrictions: [String: Any] = [
                                "airplayEnabled" : true,
                                "ffEnabled" : true,
                                "maxBitrate" : 20,
                                "maxResHeight" : 30,
                                "minBitrate": 10,
                                "rwEnabled": false,
                                "timeshiftEnabled" : false
                            ]
                            
                            var entitlementVersion2Json = PlayBackEntitlementV2.requiedJson
                            entitlementVersion2Json["contractRestrictions"] = contractRestrictions
                            
                            callback(json.decode(PlaybackEntitlement.self), entitlementVersion2Json.decode(PlayBackEntitlementV2.self), nil, nil)
                        }
                        let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                        let properties = PlaybackProperties(playFrom: .defaultBehaviour)

                        // Initiate test
                        let seekTarget = currentDate + hour * 3/4
                        var warning: PlayerWarning<HLSNative<ExposureContext>,ExposureContext>? = nil
                        env.player
                            .onProgramChanged { player, source, program in
                                player.seek(toTime: seekTarget)
                            }
                            .onWarning{ player, source, warn in
                                print(warn.message)
                                warning = warn
                            }
                            .onPlaybackReady { player, source in
                                if let avPlayer = player.tech.avPlayer as? MockedAVPlayer {
                                    avPlayer.mockedRate = 1
                                }
                        }
                        env.player.startPlayback(playable: playable, properties: properties)

                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: .seconds(5))
                        expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: .seconds(5))
                        expect(warning).toEventuallyNot(beNil(), timeout: .seconds(5))
                        expect(warning?.message).toEventually(contain("Program Service encountered a gap in the Epg at timestamp"), timeout: .seconds(5))
                        // expect{ return env.player.playheadTime != nil ? abs(env.player.playheadTime! - currentDate) : nil }.toEventually(beLessThan(1000), timeout: .seconds(5))
                    }
                }

                // MARK: + ProgramService based seek
                context("ProgramService based seek") {
                    // MARK: ++ Error making playcall
                    context("Error making playcall") {
                        it("should stop playback with warning") {
                            let env = TestEnv(environment: env, sessionToken: token)
                            env.player.context.isDynamicManifest = { _,_ in return false }
                            env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour/2))

                            // Mock the ProgramService
                            env.mockProgramService{ environment, sessionToken, channelId in
                                let provider = MockedProgramProvider()
                                provider.mockedFetchProgram = { _,timestamp,_, callback in
                                    if timestamp > currentDate + hour / 2 {
                                        let program = Program
                                            .validJson(programId: "program0", channelId: "channelId", assetId: "asset0")
                                            .timestamp(starting: currentDate + hour/2, ending: currentDate+hour)
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
                                service.provider = provider
                                return service
                            }

                            // Mock the ProgramService playable generator
                            env.mockProgramServicePlayable{ program in
                                let provider = MockedProgramEntitlementProvider()
                                provider.mockedRequestEntitlementV2 = { _,_,_, callback in
                                    callback(nil, nil, ExposureError.exposureResponse(reason: ExposureResponseMessage(httpCode: 404, message: "SOME_ERROR")), nil)
                                }
                                return ProgramPlayable(assetId: program.programId, channelId: program.channelId, entitlementProvider: provider)
                            }

                            // Configure the playable
                            let provider = MockedProgramEntitlementProvider()
                            provider.mockedRequestEntitlementV2 = { _,_,_, callback in
                                var json = PlaybackEntitlement.requiedJson
                                json["mediaLocator"] = "file://play/.isml"
                                json["ffEnabled"] = true
                                
                                let contractRestrictions: [String: Any] = [
                                    "airplayEnabled" : true,
                                    "ffEnabled" : true,
                                    "maxBitrate" : 20,
                                    "maxResHeight" : 30,
                                    "minBitrate": 10,
                                    "rwEnabled": false,
                                    "timeshiftEnabled" : false
                                ]
                                
                                var entitlementVersion2Json = PlayBackEntitlementV2.requiedJson
                                entitlementVersion2Json["contractRestrictions"] = contractRestrictions
                                
                                callback(json.decode(PlaybackEntitlement.self), entitlementVersion2Json.decode(PlayBackEntitlementV2.self), nil, nil)
                            }
                            let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                            let properties = PlaybackProperties(playFrom: .defaultBehaviour)

                            // Initiate test
                            let seekTarget = currentDate + hour * 3/4
                            var error: PlayerError<HLSNative<ExposureContext>,ExposureContext>? = nil
                            env.player
                                .onProgramChanged { player, source, program in
                                    player.seek(toTime: seekTarget)
                                }
                                .onError{ player, source, err in
                                    error = err
                                }
                                .onPlaybackReady { player, source in
                                    if let avPlayer = player.tech.avPlayer as? MockedAVPlayer {
                                        avPlayer.mockedRate = 1
                                    }
                            }
                            env.player.startPlayback(playable: playable, properties: properties)

                            expect(error).toEventuallyNot(beNil(), timeout: .seconds(5))
                            expect(error?.message).toEventually(equal("SOME_ERROR"), timeout: .seconds(5))
                            expect(error?.code).toEventually(equal(404), timeout: .seconds(5))
                        }
                    }
                
                    // MARK: ++ ENTITLED
                    context("ENTITLED") {
                        it("should allow playback") {
                            let env = TestEnv(environment: env, sessionToken: token)
                            env.player.context.isDynamicManifest = { _,_ in return false }
                            env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour/2))
                            
                            // Mock the ProgramService
                            env.mockProgramService{ environment, sessionToken, channelId in
                                let provider = MockedProgramProvider()
                                provider.mockedFetchProgram = { _,timestamp,_, callback in
                                    if timestamp > currentDate + hour/2 {
                                        let program = Program
                                            .validJson(programId: "ProgramSevicedFetchedEntitlement", channelId: "channelId", assetId: "asset1")
                                            .timestamp(starting: currentDate + hour / 2, ending: currentDate+hour)
                                            .decodeWrap(Program.self)
                                        callback(program,nil)
                                    }
                                    else {
                                        let program = Program
                                            .validJson(programId: "program0", channelId: "channelId", assetId: "asset0")
                                            .timestamp(starting: currentDate, ending: currentDate+hour/2)
                                            .decodeWrap(Program.self)
                                        callback(program,nil)
                                    }
                                }
                                let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
                                service.provider = provider
                                return service
                            }
                            
                            // Mock the ProgramService playable generator
                            env.mockProgramServicePlayable{ program in
                                let provider = MockedProgramEntitlementProvider()
                                provider.mockedRequestEntitlementV2 = { _,_,_, callback in
                                    var json = PlaybackEntitlement.requiedJson
                                    json["mediaLocator"] = "file://play/.isml"
                                    json["playToken"] = "ProgramSevicedFetchedEntitlement"
                                    json["ffEnabled"] = false
                                    json["rwEnabled"] = false
                                    json["timeshiftEnabled"] = false
                                    
                                    let contractRestrictions: [String: Any] = [
                                        "airplayEnabled" : true,
                                        "ffEnabled" : false,
                                        "maxBitrate" : 20,
                                        "maxResHeight" : 30,
                                        "minBitrate": 10,
                                        "rwEnabled": false,
                                        "timeshiftEnabled" : false
                                    ]
                                    
                                    var entitlementVersion2Json = PlayBackEntitlementV2.requiedJson
                                    entitlementVersion2Json["contractRestrictions"] = contractRestrictions
                                    
                                    callback(json.decode(PlaybackEntitlement.self), entitlementVersion2Json.decode(PlayBackEntitlementV2.self), nil, nil)
                                }
                                return ProgramPlayable(assetId: program.programId, channelId: program.channelId, entitlementProvider: provider)
                            }
                            
                            // Configure the playable
                            let provider = MockedProgramEntitlementProvider()
                            provider.mockedRequestEntitlementV2 = { _,_,_, callback in
                                var json = PlaybackEntitlement.requiedJson
                                json["mediaLocator"] = "file://play/.isml"
                                json["ffEnabled"] = true
                                json["rwEnabled"] = true
                                json["timeshiftEnabled"] = true
                                
                                let contractRestrictions: [String: Any] = [
                                    "airplayEnabled" : true,
                                    "ffEnabled" : true,
                                    "maxBitrate" : 20,
                                    "maxResHeight" : 30,
                                    "minBitrate": 10,
                                    "rwEnabled": true,
                                    "timeshiftEnabled" : true
                                ]
                                
                                var entitlementVersion2Json = PlayBackEntitlementV2.requiedJson
                                entitlementVersion2Json["contractRestrictions"] = contractRestrictions
                                
                                callback(json.decode(PlaybackEntitlement.self), entitlementVersion2Json.decode(PlayBackEntitlementV2.self), nil, nil)
                            }
                            let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                            let properties = PlaybackProperties(playFrom: .defaultBehaviour)
                            
                            // Initiate test
                            let seekTarget = currentDate + hour * 3/4
                            env.player
                                .onEntitlementResponse{ player, source, entitlement in
                                    print("onEntitlementResponse",entitlement.playToken)
                                }
                                .onProgramChanged { player, source, program in
                                    if program?.programId == "program0" {
                                        player.seek(toTime: seekTarget)
                                    }
                                }
                                .onPlaybackReady { player, source in
                                    if let avPlayer = player.tech.avPlayer as? MockedAVPlayer {
                                        avPlayer.mockedRate = 1
                                    }
                            }
                            env.player.startPlayback(playable: playable, properties: properties)
                            
                           
                            expect(env.player.tech.currentSource?.entitlement.playToken).toEventually(equal("ProgramSevicedFetchedEntitlement"), timeout: .seconds(5))
                            // expect{ return self.playFrom(player: env.player, target: seekTarget) }.toEventually(beLessThan(1000), timeout: .seconds(5))
                        }
                    }
                }
            }
        
            
            context("Contract Restrictions") {
                context("Enforce FastForward") {
                    it("should restrict seeking forward") {
                        let env = TestEnv(environment: env, sessionToken: token)
                        env.player.context.isDynamicManifest = { _,_ in return false }
                        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour/2))

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
                            service.provider = provider
                            return service
                        }

                        // Configure the playable
                        let provider = MockedProgramEntitlementProvider()
                        provider.mockedRequestEntitlementV2 = { _,_,_, callback in
                            var json = PlaybackEntitlement.requiedJson
                            json["mediaLocator"] = "file://play/.isml"
                            json["ffEnabled"] = false
                            json["rwEnabled"] = false
                            json["timeshiftEnabled"] = false
                            
                            let contractRestrictions: [String: Any] = [
                                "airplayEnabled" : true,
                                "ffEnabled" : false,
                                "maxBitrate" : 20,
                                "maxResHeight" : 30,
                                "minBitrate": 10,
                                "rwEnabled": false,
                                "timeshiftEnabled" : false
                            ]
                            
                            var entitlementVersion2Json = PlayBackEntitlementV2.requiedJson
                            entitlementVersion2Json["contractRestrictions"] = contractRestrictions
                            
                            callback(json.decode(PlaybackEntitlement.self), entitlementVersion2Json.decode(PlayBackEntitlementV2.self), nil, nil)
                        }
                        let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                        let properties = PlaybackProperties(playFrom: .defaultBehaviour)

                        // Initiate test
                        let seekTarget = currentDate + hour * 3/4
                        var warning: PlayerWarning<HLSNative<ExposureContext>,ExposureContext>? = nil
                        env.player
                            .onProgramChanged { player, source, program in
                                if program?.programId == "program1" {
                                    player.seek(toTime: seekTarget)
                                }
                            }
                            .onWarning{ player, source, warn in
                                warning = warn
                            }
                            .onPlaybackReady { player, source in
                                if let avPlayer = player.tech.avPlayer as? MockedAVPlayer {
                                    avPlayer.mockedRate = 1
                                }
                        }
                        env.player.startPlayback(playable: playable, properties: properties)

                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: .seconds(5))
                        expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: .seconds(5))
                        expect(warning).toEventuallyNot(beNil(), timeout: .seconds(5))
                        expect(warning?.message).toEventually(contain("Contract restrictions disables fast forwarding"), timeout: .seconds(5))
                    }
                }

                context("Enforce Rewind") {
                    it("should restrict seeking back") {
                        let env = TestEnv(environment: env, sessionToken: token)
                        env.player.context.isDynamicManifest = { _,_ in return false }
                        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour/2))

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
                            service.provider = provider
                            return service
                        }

                        // Configure the playable
                        let provider = MockedProgramEntitlementProvider()
                        provider.mockedRequestEntitlementV2 = { _,_,_, callback in
                            var json = PlaybackEntitlement.requiedJson
                            json["mediaLocator"] = "file://play/.isml"
                            json["ffEnabled"] = false
                            json["rwEnabled"] = false
                            json["timeshiftEnabled"] = false
                            
                            let contractRestrictions: [String: Any] = [
                                "airplayEnabled" : true,
                                "ffEnabled" : false,
                                "maxBitrate" : 20,
                                "maxResHeight" : 30,
                                "minBitrate": 10,
                                "rwEnabled": false,
                                "timeshiftEnabled" : false
                            ]
                            
                            var entitlementVersion2Json = PlayBackEntitlementV2.requiedJson
                            entitlementVersion2Json["contractRestrictions"] = contractRestrictions
                            
                            callback(json.decode(PlaybackEntitlement.self), entitlementVersion2Json.decode(PlayBackEntitlementV2.self), nil, nil)
                        }
                        let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                        let properties = PlaybackProperties(playFrom: .defaultBehaviour)

                        // Initiate test
                        let seekTarget = currentDate - hour * 3/4
                        var warning: PlayerWarning<HLSNative<ExposureContext>,ExposureContext>? = nil
                        env.player
                            .onProgramChanged { player, source, program in
                                if program?.programId == "program1" {
                                    player.seek(toTime: seekTarget)
                                }
                            }
                            .onWarning { player, source, warn in
                                warning = warn
                            }
                            .onPlaybackReady { player, source in
                                if let avPlayer = player.tech.avPlayer as? MockedAVPlayer {
                                    avPlayer.mockedRate = 1
                                }
                        }
                        env.player.startPlayback(playable: playable, properties: properties)

                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: .seconds(5))
                        expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: .seconds(5))
                        expect(warning).toEventuallyNot(beNil(), timeout: .seconds(5))
                        expect(warning?.message).toEventually(contain("Contract restrictions disabled rewinding"), timeout: .seconds(5))
                    }
                }
            }
        }
    }
    
    func playFrom(player: Player<HLSNative<ExposureContext>>, target: Int64) -> Int64? {
        if case let PlaybackProperties.PlayFrom.customTime(timestamp: time) = player.context.playbackProperties.playFrom {
            return (time - target)
        }
        return nil
    }
}
