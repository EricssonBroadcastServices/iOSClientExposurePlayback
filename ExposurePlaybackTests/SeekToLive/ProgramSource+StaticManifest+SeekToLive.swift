//
//  ProgramSource+StaticManifest+SeekToLive.swift
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

class StaticProgramSourceSeekToLiveSpec: QuickSpec {
    override func spec() {
        super.spec()
        
        describe("SeekToLive Static ProgramSource") {
            let currentDate = Date().unixEpoch
            let hour: Int64 = 60 * 60 * 1000
            
            let env = Environment(baseUrl: "http://www.example.com", customer: "customer", businessUnit: "businessUnit")
            let token = SessionToken(value: "token")
            
            // Seekable range is defined by the manifest
            // MARK: After seekableTimeRange
            ///  |---+-------|.....> live
            ///  p1  |       p2    |
            ///  r1  |       r2    |
            ///      s1 --------> s2
            
            // MARK: + Error making playcall
            context("Error making playcall") {
                it("should stop playback with error") {
                    let env = SeekToTimeEnv(environment: env, sessionToken: token)
                    env.player.context.isDynamicManifest = { _,_ in return false }
                    env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour/2))

                    // Mock the ProgramService
                    env.mockProgramService{ environment, sessionToken, channelId in
                        let provider = SeekToTimeProgramProvider()
                        provider.mockedFetchProgram = { _,_,_, callback in
                            let program = Program
                                .validJson(programId: "program1", channelId: "channelId", assetId: "asset1")
                                .timestamp(starting: currentDate, ending: currentDate+hour/2)
                                .decode(Program.self)
                            callback(program,nil)
                        }
                        let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
                        service.provider = provider
                        return service
                    }

                    // Mock the ChannelPlayable used in SeekToLive
                    env.mockSeekToLiveChannelPlayable{ channelId in
                        let provider = MockedChannelEntitlementProvider()
                        provider.mockedRequestEntitlement = { _,_,_, callback in
                            callback(nil, ExposureError.exposureResponse(reason: ExposureResponseMessage(httpCode: 404, message: "SOME_ERROR")))
                        }
                        return ChannelPlayable(assetId: channelId, entitlementProvider: provider)
                    }

                    // Configure the playable
                    let provider = MockedProgramEntitlementProvider()
                    provider.mockedRequestEntitlement = { _,_,_,_, callback in
                        var json = PlaybackEntitlement.requiedJson
                        json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                        json["playSessionId"] = "SeekToLiveTrigger"
                        json["ffEnabled"] = false
                        json["rwEnabled"] = false
                        json["timeshiftEnabled"] = false
                        callback(json.decode(PlaybackEntitlement.self), nil)
                    }
                    let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                    let properties = PlaybackProperties(playFrom: .defaultBehaviour)

                    // Initiate test
                    env.player.startPlayback(playable: playable, properties: properties)
                    var error: PlayerError<HLSNative<ExposureContext>,ExposureContext>? = nil
                    env.player
                        .onProgramChanged { player, source, program in
                            if source.entitlement.playSessionId == "SeekToLiveTrigger" {
                                player.seekToLive()
                            }
                        }
                        .onError{ player, source, err in
                            error = err
                    }

                    expect(error).toEventuallyNot(beNil(), timeout: 3)
                    expect(error?.message).toEventually(equal("SOME_ERROR"), timeout: 3)
                    expect(error?.code).toEventually(equal(404), timeout: 3)
                }
            }
            
            // MARK: + ENTITLED
            context("ENTITLED") {
                it("should allow playback") {
                    let env = SeekToTimeEnv(environment: env, sessionToken: token)
                    env.player.context.isDynamicManifest = { _,_ in return false }
                    env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour))
                    
                    // Mock the ProgramService
                    env.mockProgramService{ environment, sessionToken, channelId in
                        let provider = SeekToTimeProgramProvider()
                        provider.mockedFetchProgram = { _,timestamp,_, callback in
                            if timestamp > currentDate + hour/2 {
                                let program = Program
                                    .validJson(programId: "program2", channelId: "channelId", assetId: "asset0")
                                    .timestamp(starting: currentDate + hour / 2, ending: currentDate+hour)
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
                    
                    // Mock the ChannelPlayable used in SeekToLive
                    env.mockSeekToLiveChannelPlayable{ channelId in
                        let provider = MockedChannelEntitlementProvider()
                        provider.mockedRequestEntitlement = { _,_,_, callback in
                            var json = PlaybackEntitlement.requiedJson
                            json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                            json["playSessionId"] = "SeekToLiveFetchedEntitlement"
                            callback(json.decode(PlaybackEntitlement.self), nil)
                        }
                        return ChannelPlayable(assetId: channelId, entitlementProvider: provider)
                    }
                    
                    // Configure the playable
                    let provider = MockedProgramEntitlementProvider()
                    provider.mockedRequestEntitlement = { _,_,_,_, callback in
                        var json = PlaybackEntitlement.requiedJson
                        json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                        json["playSessionId"] = "SeekToLiveTrigger"
                        json["ffEnabled"] = false
                        json["rwEnabled"] = false
                        json["timeshiftEnabled"] = false
                        callback(json.decode(PlaybackEntitlement.self), nil)
                    }
                    let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                    let properties = PlaybackProperties(playFrom: .defaultBehaviour)
                    
                    // Initiate test
                    env.player.startPlayback(playable: playable, properties: properties)
                    env.player
                        .onEntitlementResponse{ player, source, entitlement in
                            if entitlement.playSessionId == "SeekToLiveFetchedEntitlement" {
                                // Fake the playheadTime to match "live point"
                                let item = player.tech.currentAsset?.playerItem as? MockedAVPlayerItem
                                item?.mockedCurrentDate = Date(unixEpoch: currentDate + hour * 3/4)
                            }
                        }
                        .onProgramChanged { player, source, program in
                            if source.entitlement.playSessionId == "SeekToLiveTrigger" {
                                player.seekToLive()
                            }
                        }
                    
                    
                    expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 3)
                    expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 3)
                    expect(env.player.tech.currentSource?.entitlement.playSessionId).toEventually(equal("SeekToLiveFetchedEntitlement"), timeout: 3)
                }
            }
        }
    }

}