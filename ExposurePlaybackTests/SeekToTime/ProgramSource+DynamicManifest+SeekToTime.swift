//
//  ProgramSource+DynamicManifest+SeekToTime.swift
//  ExposurePlaybackTests
//
//  Created by Fredrik Sjöberg on 2018-02-13.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation

import Quick
import Nimble
import Exposure
import AVFoundation

@testable import Player
@testable import ExposurePlayback

class DynamicProgramSourceSeekToTimeSpec: QuickSpec {
    override func spec() {
        super.spec()
        
        describe("ProgramSource") {
            let currentDate = Date().unixEpoch
            let hour: Int64 = 60 * 60 * 1000
            
            let env = Environment(baseUrl: "http://www.example.com", customer: "customer", businessUnit: "businessUnit")
            let token = SessionToken(value: "token")
            
            // Seekable range is defined by the manifest
            // MARK: Within seekableTimeRange
            context("Within seekableTimeRange") {
                // MARK: + Within program bounds
                context("Within program bounds") {
                    ///  |---------+---|------->.....x
                    ///  p1        |   p2      |     p3
                    ///  r1        |           r2
                    ///  s1 -----> s2
                    it("should allow seek") {
                        let env = SeekToTimeEnv(environment: env, sessionToken: token)
                        env.player.context.isDynamicManifest = { _,_ in return true }
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
                        let provider = MockedProgramEntitlementProvider()
                        provider.mockedRequestEntitlement = { _,_,_,_, callback in
                            var json = PlaybackEntitlement.requiedJson
                            json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                            json["ffEnabled"] = true
                            callback(json.decode(PlaybackEntitlement.self), nil)
                        }
                        let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                        let properties = PlaybackProperties(playFrom: .defaultBehaviour)

                        // Initiate test
                        env.player.startPlayback(playable: playable, properties: properties)
                        let seekTarget = currentDate + 10 * 60 * 1000
                        env.player.onProgramChanged { player, source, program in
                            player.seek(toTime: seekTarget)
                        }

                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 3)
                        expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 3)
                        expect{ env.player.playheadTime != nil ? abs(env.player.playheadTime! - seekTarget) : nil }.toEventually(beLessThan(1000), timeout: 3)
                    }
                }


                // MARK: + After program bounds
                context("After program bounds") {
                    ///  |-----------|----+--->.....x
                    ///  p1          p2   |   |     p3
                    ///  r1               |   r2
                    ///  s1 ------------> s2

                    // MARK: ++ ENTITLED
                    context("ENTITLED") {
                        it("should allow seek if entitled") {
                            let env = SeekToTimeEnv(environment: env, sessionToken: token)
                            env.player.context.isDynamicManifest = { _,_ in return true }
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
                            let provider = MockedProgramEntitlementProvider()
                            provider.mockedRequestEntitlement = { _,_,_,_, callback in
                                var json = PlaybackEntitlement.requiedJson
                                json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                                json["ffEnabled"] = true
                                callback(json.decode(PlaybackEntitlement.self), nil)
                            }
                            let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                            let properties = PlaybackProperties(playFrom: .defaultBehaviour)

                            // Initiate test
                            env.player.startPlayback(playable: playable, properties: properties)
                            let seekTarget = currentDate + hour * 3/4
                            env.player.onProgramChanged { player, source, program in
                                player.seek(toTime: seekTarget)
                            }

                            expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 3)
                            expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 3)
                            expect{ return env.player.playheadTime != nil ? abs(env.player.playheadTime! - seekTarget) : nil }.toEventually(beLessThan(1000), timeout: 4)
                        }
                    }

                    // MARK: ++ Error fetching EPG
                    context("Error fetching EPG") {
                        it("should allow seek with warning message") {
                            let env = SeekToTimeEnv(environment: env, sessionToken: token)
                            env.player.context.isDynamicManifest = { _,_ in return true }
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
                                        callback(nil, ExposureError.exposureResponse(reason: ExposureResponseMessage(httpCode: 401, message: "SOME_ERROR")))
                                    }
                                }

                                let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
                                service.provider = provider
                                return service
                            }

                            // Configure the playable
                            let provider = MockedProgramEntitlementProvider()
                            provider.mockedRequestEntitlement = { _,_,_,_, callback in
                                var json = PlaybackEntitlement.requiedJson
                                json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                                json["ffEnabled"] = true
                                callback(json.decode(PlaybackEntitlement.self), nil)
                            }
                            let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                            let properties = PlaybackProperties(playFrom: .defaultBehaviour)

                            // Initiate test
                            env.player.startPlayback(playable: playable, properties: properties)
                            let seekTarget = currentDate + hour * 3/4
                            var warning: PlayerWarning<HLSNative<ExposureContext>,ExposureContext>? = nil
                            env.player.onProgramChanged { player, source, program in
                                player.seek(toTime: seekTarget)
                                }
                                .onWarning{ player, source, warn in
                                    warning = warn
                            }

                            expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 3)
                            expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 3)
                            expect(warning).toEventuallyNot(beNil(), timeout: 3)
                            expect(warning?.message).toEventually(contain("Program Service failed to fetch the current program at timestamp"), timeout: 3)
                            expect{ return env.player.playheadTime != nil ? abs(env.player.playheadTime! - seekTarget) : nil }.toEventually(beLessThan(1000), timeout: 4)
                        }
                    }

                    // MARK: ++ Error validating entitlement
                    context("Error validating entitlement") {
                        it("should allow seek with warning message") {
                            let env = SeekToTimeEnv(environment: env, sessionToken: token)
                            env.player.context.isDynamicManifest = { _,_ in return true }
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
                                provider.mockedValidate = { _,_,_, callback in
                                    callback(nil, ExposureError.exposureResponse(reason: ExposureResponseMessage(httpCode: 401, message: "SOME_ERROR")))
                                }
                                let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
                                service.provider = provider
                                return service
                            }

                            // Configure the playable
                            let provider = MockedProgramEntitlementProvider()
                            provider.mockedRequestEntitlement = { _,_,_,_, callback in
                                var json = PlaybackEntitlement.requiedJson
                                json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                                json["ffEnabled"] = true
                                callback(json.decode(PlaybackEntitlement.self), nil)
                            }
                            let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                            let properties = PlaybackProperties(playFrom: .defaultBehaviour)

                            // Initiate test
                            env.player.startPlayback(playable: playable, properties: properties)
                            let seekTarget = currentDate + hour * 3/4
                            var warning: PlayerWarning<HLSNative<ExposureContext>,ExposureContext>? = nil
                            env.player.onProgramChanged { player, source, program in
                                player.seek(toTime: seekTarget)
                                }
                                .onWarning{ player, source, warn in
                                    warning = warn
                            }

                            expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 3)
                            expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 3)
                            expect(warning).toEventuallyNot(beNil(), timeout: 3)
                            expect(warning?.message).toEventually(contain("Program Service failed to validate program"), timeout: 3)
                            expect{ return env.player.playheadTime != nil ? abs(env.player.playheadTime! - seekTarget) : nil }.toEventually(beLessThan(1000), timeout: 4)
                        }
                    }

                    // MARK: ++ Gap in EPG
                    context("Gap in EPG"){
                        it("should allow seek if encountering epg gap") {
                            let env = SeekToTimeEnv(environment: env, sessionToken: token)
                            env.player.context.isDynamicManifest = { _,_ in return true }
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
                                        // GAP IN EPG
                                        callback(nil,nil)
                                    }
                                }
                                let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
                                service.provider = provider
                                return service
                            }

                            // Configure the playable
                            let provider = MockedProgramEntitlementProvider()
                            provider.mockedRequestEntitlement = { _,_,_,_, callback in
                                var json = PlaybackEntitlement.requiedJson
                                json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                                json["ffEnabled"] = true
                                callback(json.decode(PlaybackEntitlement.self), nil)
                            }
                            let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                            let properties = PlaybackProperties(playFrom: .defaultBehaviour)

                            // Initiate test
                            env.player.startPlayback(playable: playable, properties: properties)
                            let seekTarget = currentDate + hour * 3/4
                            var warning: PlayerWarning<HLSNative<ExposureContext>,ExposureContext>? = nil
                            env.player
                                .onProgramChanged { player, source, program in
                                    player.seek(toTime: seekTarget)
                                }
                                .onWarning{ player, source, warn in
                                    warning = warn
                            }

                            expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 3)
                            expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 3)
                            expect(warning).toEventuallyNot(beNil(), timeout: 3)
                            expect(warning?.message).toEventually(contain("Program Service encountered a gap in the Epg at timestamp"), timeout: 3)
                            expect{ return env.player.playheadTime != nil ? abs(env.player.playheadTime! - seekTarget) : nil }.toEventually(beLessThan(1000), timeout: 4)
                        }
                    }

                    // MARK: ++ NOT_ENTITLED
                    context("NOT_ENTITLED") {
                        it("should stop with error if not entitled") {
                            let env = SeekToTimeEnv(environment: env, sessionToken: token)
                            env.player.context.isDynamicManifest = { _,_ in return true }
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
                            let provider = MockedProgramEntitlementProvider()
                            provider.mockedRequestEntitlement = { _,_,_,_, callback in
                                var json = PlaybackEntitlement.requiedJson
                                json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                                json["ffEnabled"] = true
                                callback(json.decode(PlaybackEntitlement.self), nil)
                            }
                            let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                            let properties = PlaybackProperties(playFrom: .defaultBehaviour)

                            // Initiate test
                            env.player.startPlayback(playable: playable, properties: properties)
                            let seekTarget = currentDate + hour * 3/4
                            var error: PlayerError<HLSNative<ExposureContext>,ExposureContext>? = nil
                            env.player.onProgramChanged { player, source, program in
                                player.seek(toTime: seekTarget)
                                }
                                .onError{ tech, source, err in
                                    error = err
                            }

                            expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 3)
                            expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 3)
                            expect(error).toEventuallyNot(beNil(), timeout: 3)
                            expect(error?.code).toEventually(equal(403))
                            expect(error?.message).toEventually(equal("NOT_ENTITLED"))
                        }
                    }
                }
            }
            
            // Seekable range is defined by the manifest
            // MARK: After seekableTimeRange
            context("After seekableTimeRange") {
                let livePointOffet = hour/2
                let livePointDelay: Int64 = 25 * 1000
                // MARK: + Close to live point
                context("Close to live point") {
                    ///  |----------->.........x
                    ///  p1          |  |      p2
                    ///  r1          r2 |
                    ///  s1 ----------> s2
                    let closeToLivePoint: Int64 = 10 * 1000
                    it("should seek to live point") {
                        let env = SeekToTimeEnv(environment: env, sessionToken: token)
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
                        let provider = MockedProgramEntitlementProvider()
                        provider.mockedRequestEntitlement = { _,_,_,_, callback in
                            var json = PlaybackEntitlement.requiedJson
                            json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                            json["ffEnabled"] = true
                            callback(json.decode(PlaybackEntitlement.self), nil)
                        }
                        let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                        let properties = PlaybackProperties(playFrom: .defaultBehaviour)
                        
                        // ServerTime is required for LiveDelay to work properly
                        _ = env.player.serverTime

                        // Initiate test
                        env.player.startPlayback(playable: playable, properties: properties)
                        let seekTarget = currentDate + livePointOffet + closeToLivePoint
                        env.player.onProgramChanged { player, source, program in
                            player.seek(toTime: seekTarget)
                        }

                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 3)
                        expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 3)
                        expect{ env.player.playheadTime != nil ? abs(env.player.playheadTime! - (currentDate + livePointOffet)) : nil }.toEventually(beLessThan(1000), timeout: 3)
                    }
                }

                // MARK: + Far ahead of live point
                context("Far ahead of live point") {
                    ///  |-------------->.............x
                    ///  p1             |         |   p2
                    ///  r1             r2        |
                    ///  s1 --------------------> s2
                    let farAheadOfLivePoint: Int64 = 100 * 1000
                    it("should ignore seek and deliver warning") {
                        let env = SeekToTimeEnv(environment: env, sessionToken: token)
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
                        let provider = MockedProgramEntitlementProvider()
                        provider.mockedRequestEntitlement = { _,_,_,_, callback in
                            var json = PlaybackEntitlement.requiedJson
                            json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                            json["ffEnabled"] = true
                            callback(json.decode(PlaybackEntitlement.self), nil)
                        }
                        let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)

                        // ServerTime is required for LiveDelay to work properly
                        _ = env.player.serverTime

                        // Initiate test
                        env.player.startPlayback(playable: playable)
                        let seekTarget = currentDate + livePointOffet + farAheadOfLivePoint
                        var warning: PlayerWarning<HLSNative<ExposureContext>,ExposureContext>? = nil
                        env.player.onProgramChanged { player, source, program in
                            player.seek(toTime: seekTarget)
                            }
                            .onWarning{ player, source, warn in
                                warning = warn
                        }

                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 3)
                        expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 3)
                        expect(warning).toEventuallyNot(beNil(), timeout: 3)
                        expect(warning?.message).toEventually(contain("Requested seek time"), timeout: 3)
                        expect{ env.player.playheadTime != nil ? abs(env.player.playheadTime! - currentDate) : nil }.toEventually(beLessThan(1000), timeout: 3)
                    }
                }
            }


            // Seekable range is defined by the manifest
            // MARK: Before seekableTimeRange
            context("Before seekableTimeRange") {
                ///  x---+-------|-----+-------->.........x
                ///  p0  |       p1    |        |         p2
                ///      |       r1    |        r2
                ///      s2 <--------- s1

                // MARK: + Error fetching EPG
                context("Error fetching EPG") {
                    it("should ignore seek with warning message") {
                        let env = SeekToTimeEnv(environment: env, sessionToken: token)
                        env.player.context.isDynamicManifest = { _,_ in return true }
                        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour))

                        // Mock the ProgramService
                        env.mockProgramService{ environment, sessionToken, channelId in
                            let provider = SeekToTimeProgramProvider()
                            provider.mockedFetchProgram = { _,timestamp,_, callback in
                                if timestamp < currentDate {
                                    callback(nil, ExposureError.exposureResponse(reason: ExposureResponseMessage(httpCode: 401, message: "SOME_ERROR")))
                                }
                                else {
                                    let program = Program
                                        .validJson(programId: "program1", channelId: "channelId", assetId: "asset1")
                                        .timestamp(starting: currentDate, ending: currentDate+hour/2)
                                        .decode(Program.self)
                                    callback(program,nil)
                                }
                            }

                            let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
                            service.provider = provider
                            return service
                        }

                        // Configure the playable
                        let provider = MockedProgramEntitlementProvider()
                        provider.mockedRequestEntitlement = { _,_,_,_, callback in
                            var json = PlaybackEntitlement.requiedJson
                            json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                            json["rwEnabled"] = true
                            callback(json.decode(PlaybackEntitlement.self), nil)
                        }
                        let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                        let properties = PlaybackProperties(playFrom: .defaultBehaviour)
                        
                        // Initiate test
                        env.player.startPlayback(playable: playable, properties: properties)
                        let seekTarget = currentDate - hour * 1/4
                        var warning: PlayerWarning<HLSNative<ExposureContext>,ExposureContext>? = nil
                        env.player.onProgramChanged { player, source, program in
                            player.seek(toTime: seekTarget)
                            }
                            .onWarning{ player, source, warn in
                                warning = warn
                        }

                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 3)
                        expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 3)
                        expect(warning).toEventuallyNot(beNil(), timeout: 3)
                        expect(warning?.message).toEventually(contain("Program Service failed to fetch the current program at timestamp"), timeout: 3)
                        expect{ return env.player.playheadTime != nil ? abs(env.player.playheadTime! - currentDate) : nil }.toEventually(beLessThan(1000), timeout: 4)
                    }
                }

                // MARK: + Gap in EPG
                context("Gap in EPG"){
                    it("should ignore seek if encountering epg gap") {
                        let env = SeekToTimeEnv(environment: env, sessionToken: token)
                        env.player.context.isDynamicManifest = { _,_ in return true }
                        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour))

                        // Mock the ProgramService
                        env.mockProgramService{ environment, sessionToken, channelId in
                            let provider = SeekToTimeProgramProvider()
                            provider.mockedFetchProgram = { _,timestamp,_, callback in
                                if timestamp < currentDate {
                                    // GAP IN EPG
                                    callback(nil,nil)
                                }
                                else {
                                    let program = Program
                                        .validJson(programId: "program1", channelId: "channelId", assetId: "asset1")
                                        .timestamp(starting: currentDate, ending: currentDate+hour/2)
                                        .decode(Program.self)
                                    callback(program,nil)
                                }
                            }
                            let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
                            service.provider = provider
                            return service
                        }

                        // Configure the playable
                        let provider = MockedProgramEntitlementProvider()
                        provider.mockedRequestEntitlement = { _,_,_,_, callback in
                            var json = PlaybackEntitlement.requiedJson
                            json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                            json["rwEnabled"] = true
                            callback(json.decode(PlaybackEntitlement.self), nil)
                        }
                        let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                        let properties = PlaybackProperties(playFrom: .defaultBehaviour)
                        
                        // Initiate test
                        env.player.startPlayback(playable: playable, properties: properties)
                        let seekTarget = currentDate - hour * 1/4
                        var warning: PlayerWarning<HLSNative<ExposureContext>,ExposureContext>? = nil
                        env.player
                            .onProgramChanged { player, source, program in
                                player.seek(toTime: seekTarget)
                            }
                            .onWarning{ player, source, warn in

                                warning = warn
                        }

                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 3)
                        expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 3)
                        expect(warning).toEventuallyNot(beNil(), timeout: 3)
                        expect(warning?.message).toEventually(contain("Program Service encountered a gap in the Epg at timestamp"), timeout: 3)
                        expect{ return env.player.playheadTime != nil ? abs(env.player.playheadTime! - currentDate) : nil }.toEventually(beLessThan(1000), timeout: 4)
                    }
                }

                // MARK: + ProgramService based seek
                context("ProgramService based seek") {
                    // MARK: ++ Error making playcall
                    context("Error making playcall") {
                        it("should stop playback with warning") {
                            let env = SeekToTimeEnv(environment: env, sessionToken: token)
                            env.player.context.isDynamicManifest = { _,_ in return true }
                            env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour))

                            // Mock the ProgramService
                            env.mockProgramService{ environment, sessionToken, channelId in
                                let provider = SeekToTimeProgramProvider()
                                provider.mockedFetchProgram = { _,timestamp,_, callback in
                                    if timestamp < currentDate {
                                        let program = Program
                                            .validJson(programId: "program0", channelId: "channelId", assetId: "asset0")
                                            .timestamp(starting: currentDate, ending: currentDate+hour/2)
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
                                let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
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

                            // Configure the playable
                            let provider = MockedProgramEntitlementProvider()
                            provider.mockedRequestEntitlement = { _,_,_,_, callback in
                                var json = PlaybackEntitlement.requiedJson
                                json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                                json["rwEnabled"] = true
                                callback(json.decode(PlaybackEntitlement.self), nil)
                            }
                            let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                            let properties = PlaybackProperties(playFrom: .defaultBehaviour)
                            
                            // Initiate test
                            env.player.startPlayback(playable: playable, properties: properties)
                            let seekTarget = currentDate - hour * 1/4
                            var error: PlayerError<HLSNative<ExposureContext>,ExposureContext>? = nil
                            env.player
                                .onProgramChanged { player, source, program in
                                    player.seek(toTime: seekTarget)
                                }
                                .onError{ player, source, err in
                                    error = err
                            }

                            expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 3)
                            expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 3)
                            expect(error).toEventuallyNot(beNil(), timeout: 3)
                            expect(error?.message).toEventually(equal("SOME_ERROR"), timeout: 3)
                            expect(error?.code).toEventually(equal(404), timeout: 3)
                        }
                    }

                    // MARK: ++ ENTITLED
                    context("ENTITLED") {
                        it("should allow playback") {
                            let env = SeekToTimeEnv(environment: env, sessionToken: token)
                            env.player.context.isDynamicManifest = { _,_ in return true }
                            env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour))

                            // Mock the ProgramService
                            env.mockProgramService{ environment, sessionToken, channelId in
                                let provider = SeekToTimeProgramProvider()
                                provider.mockedFetchProgram = { _,timestamp,_, callback in
                                    if timestamp < currentDate {
                                        let program = Program
                                            .validJson(programId: "program0", channelId: "channelId", assetId: "asset0")
                                            .timestamp(starting: currentDate, ending: currentDate+hour/2)
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
                                let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
                                service.provider = provider
                                return service
                            }

                            // Mock the ProgramService playable generator
                            env.mockProgramServicePlayable{ program in
                                let provider = MockedProgramEntitlementProvider()
                                provider.mockedRequestEntitlement = { _,_,_,_, callback in
                                    var json = PlaybackEntitlement.requiedJson
                                    json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                                    json["playToken"] = "ProgramSevicedFetchedEntitlement"
                                    callback(json.decode(PlaybackEntitlement.self), nil)
                                }
                                return ProgramPlayable(assetId: program.programId, channelId: program.channelId, entitlementProvider: provider)
                            }

                            // Configure the playable
                            let provider = MockedProgramEntitlementProvider()
                            provider.mockedRequestEntitlement = { _,_,_,_, callback in
                                var json = PlaybackEntitlement.requiedJson
                                json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                                json["rwEnabled"] = true
                                callback(json.decode(PlaybackEntitlement.self), nil)
                            }
                            let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                            let properties = PlaybackProperties(playFrom: .defaultBehaviour)
                            
                            // Initiate test
                            env.player.startPlayback(playable: playable, properties: properties)
                            let seekTarget = currentDate - hour * 1/4
                            env.player
                                .onProgramChanged { player, source, program in
                                    player.seek(toTime: seekTarget)
                            }


                            expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 3)
                            expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 3)
                            expect(env.player.tech.currentSource?.entitlement.playToken).toEventually(equal("ProgramSevicedFetchedEntitlement"), timeout: 3)
                            expect{ return self.playFrom(player: env.player, target: seekTarget) }.toEventually(beLessThan(1000), timeout: 3)
                        }
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

