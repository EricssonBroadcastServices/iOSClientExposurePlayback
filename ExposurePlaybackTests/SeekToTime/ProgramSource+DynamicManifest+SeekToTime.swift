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
        
        describe("SeekToTime Dyanmic ProgramSource") {
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
                        
                        let seekTarget = Date().unixEpoch
                        let env = SeekToTimeMock().runWithinBoundsTest(playable: playable, seekTarget: seekTarget)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 5)
                        expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 5)
                        expect{ env.player.playheadTime != nil ? abs(env.player.playheadTime! - seekTarget) : nil }.toEventually(beLessThan(1000), timeout: 5)
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
                            
                            // Initiate test
                            let seekTarget = Date().unixEpoch
                            
                            let env = SeekToTimeMock().runAfterBoundsEntitledTest(playable: playable, seekTarget: seekTarget)
                            
                            expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 5)
                            expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 5)
                            expect{ return env.player.playheadTime != nil ? abs(env.player.playheadTime! - seekTarget) : nil }.toEventually(beLessThan(1000), timeout: 5)
                        }
                    }

                    // MARK: ++ Error fetching EPG
                    context("Error fetching EPG") {
                        it("should allow seek with warning message") {
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
                            
                            // Initiate test
                            let seekTarget = Date().unixEpoch
                            
                            let env = SeekToTimeMock().runAfterBoundsErrorFetchingEpg(playable: playable, seekTarget: seekTarget)
                            
                            
                            expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 5)
                            expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 5)
                            expect(env.warning).toEventuallyNot(beNil(), timeout: 5)
                            expect(env.warning?.message).toEventually(contain("Program Service failed to fetch the current program at timestamp"), timeout: 5)
                            expect{ return env.player.playheadTime != nil ? abs(env.player.playheadTime! - seekTarget) : nil }.toEventually(beLessThan(1000), timeout: 5)
                        }
                    }

                    // MARK: ++ Error validating entitlement
                    context("Error validating entitlement") {
                        it("should allow seek with warning message") {
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
                            
                            // Initiate test
                            let seekTarget = Date().unixEpoch
                            
                            let env = SeekToTimeMock().runAfterBoundsErrorValidating(playable: playable, seekTarget: seekTarget)
                            
                            expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 5)
                            expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 5)
                            expect(env.warning).toEventuallyNot(beNil(), timeout: 5)
                            expect(env.warning?.message).toEventually(contain("Program Service failed to validate program"), timeout: 5)
                            expect{ return env.player.playheadTime != nil ? abs(env.player.playheadTime! - seekTarget) : nil }.toEventually(beLessThan(1000), timeout: 5)
                        }
                    }

                    // MARK: ++ Gap in EPG
                    context("Gap in EPG"){
                        it("should allow seek if encountering epg gap") {
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
                            
                            // Initiate test
                            let seekTarget = Date().unixEpoch
                            
                            let env = SeekToTimeMock().runAfterBoundsGapInEpg(playable: playable, seekTarget: seekTarget)
                            
                            expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 5)
                            expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 5)
                            expect(env.warning).toEventuallyNot(beNil(), timeout: 5)
                            expect(env.warning?.message).toEventually(contain("Program Service encountered a gap in the Epg at timestamp"), timeout: 5)
                            expect{ return env.player.playheadTime != nil ? abs(env.player.playheadTime! - seekTarget) : nil }.toEventually(beLessThan(1000), timeout: 5)
                        }
                    }

                    // MARK: ++ NOT_ENTITLED
                    context("NOT_ENTITLED") {
                        it("should stop with error if not entitled") {
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
                            
                            // Initiate test
                            let seekTarget = Date().unixEpoch
                            
                            let env = SeekToTimeMock().runAfterBoundsNotEntitled(playable: playable, seekTarget: seekTarget)
                            
                            expect(env.error).toEventuallyNot(beNil(), timeout: 5)
                            expect(env.error?.code).toEventually(equal(403))
                            expect(env.error?.message).toEventually(equal("NOT_ENTITLED"))
                        }
                    }
                }
            }
            
            // Seekable range is defined by the manifest
            // MARK: After seekableTimeRange
            context("After seekableTimeRange") {
                // MARK: + Close to live point
                context("Close to live point") {
                    ///  |----------->.........x
                    ///  p1          |  |      p2
                    ///  r1          r2 |
                    ///  s1 ----------> s2
                    it("should seek to live point") {
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
                        
                        // Initiate test
                        let seekTarget = Date().unixEpoch
                        let overshot: Int64 = 10 * 1000
                        
                        let env = SeekToTimeMock().runAfterSeekableRangeBeyondLive(playable: playable, seekTarget: seekTarget, overshot: overshot)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 5)
                        expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 5)
                        expect{ return env.player.playheadTime != nil ? abs(env.player.playheadTime! - (seekTarget - overshot)) : nil }.toEventually(beLessThan(1000), timeout: 5)
                    }
                }

                // MARK: + Far ahead of live point
                context("Far ahead of live point") {
                    ///  |-------------->.............x
                    ///  p1             |         |   p2
                    ///  r1             r2        |
                    ///  s1 --------------------> s2
                    it("should ignore seek and deliver warning") {
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

                        // Initiate test
                        let seekTarget = Date().unixEpoch
                        let overshot: Int64 = 100 * 1000
                        
                        let env = SeekToTimeMock().runAfterSeekableRangeBeyondLive(playable: playable, seekTarget: seekTarget, overshot: overshot)
                        
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 5)
                        expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 5)
                        expect(env.warning).toEventuallyNot(beNil(), timeout: 5)
                        expect(env.warning?.message).toEventually(contain("Requested seek time"), timeout: 5)
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
                        // Configure the playable
                        let provider = MockedProgramEntitlementProvider()
                        provider.mockedRequestEntitlementV2 = { _,_,_, callback in
                            var json = PlaybackEntitlement.requiedJson
                            json["mediaLocator"] = "file://play/.isml"
                            json["rwEnabled"] = true
                            
                            let contractRestrictions: [String: Any] = [
                                "airplayEnabled" : true,
                                "ffEnabled" : false,
                                "maxBitrate" : 20,
                                "maxResHeight" : 30,
                                "minBitrate": 10,
                                "rwEnabled": true,
                                "timeshiftEnabled" : false
                            ]
                            
                            var entitlementVersion2Json = PlayBackEntitlementV2.requiedJson
                            entitlementVersion2Json["contractRestrictions"] = contractRestrictions
                            
                            callback(json.decode(PlaybackEntitlement.self), entitlementVersion2Json.decode(PlayBackEntitlementV2.self), nil, nil)
                        }
                        let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                        
                        // Initiate test
                        let currentDate = Date().unixEpoch
                        let seekOffset: Int64 = 60 * 60 * 1000 / 4
                        let env = SeekToTimeMock().runBeforeSeekableRangeErrorFetchingEpg(playable: playable, currentDate: currentDate, seekOffset: seekOffset)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 5)
                        expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 5)
                        expect(env.warning).toEventuallyNot(beNil(), timeout: 5)
                        expect(env.warning?.message).toEventually(contain("Program Service failed to fetch the current program at timestamp"), timeout: 5)
                        expect{ return env.player.playheadTime != nil ? abs(env.player.playheadTime! - currentDate) : nil }.toEventually(beLessThan(1000), timeout: 5)
                    }
                }

                // MARK: + Gap in EPG
                context("Gap in EPG"){
                    it("should ignore seek if encountering epg gap") {
                        // Configure the playable
                        let provider = MockedProgramEntitlementProvider()
                        provider.mockedRequestEntitlementV2 = { _,_,_, callback in
                            var json = PlaybackEntitlement.requiedJson
                            json["mediaLocator"] = "file://play/.isml"
                            json["rwEnabled"] = true
                            
                            let contractRestrictions: [String: Any] = [
                                "airplayEnabled" : true,
                                "ffEnabled" : false,
                                "maxBitrate" : 20,
                                "maxResHeight" : 30,
                                "minBitrate": 10,
                                "rwEnabled": true,
                                "timeshiftEnabled" : false
                            ]
                            
                            var entitlementVersion2Json = PlayBackEntitlementV2.requiedJson
                            entitlementVersion2Json["contractRestrictions"] = contractRestrictions
                            
                            callback(json.decode(PlaybackEntitlement.self), entitlementVersion2Json.decode(PlayBackEntitlementV2.self), nil, nil)
                        }
                        let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                        
                        // Initiate test
                        let currentDate = Date().unixEpoch
                        let seekOffset: Int64 = 60 * 60 * 1000 / 4
                        let env = SeekToTimeMock().runBeforeSeekableRangeGapInEpg(playable: playable, currentDate: currentDate, seekOffset: seekOffset)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 5)
                        expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 5)
                        expect(env.warning).toEventuallyNot(beNil(), timeout: 5)
                        expect(env.warning?.message).toEventually(contain("Program Service encountered a gap in the Epg at timestamp"), timeout: 5)
                        expect{ return env.player.playheadTime != nil ? abs(env.player.playheadTime! - currentDate) : nil }.toEventually(beLessThan(1000), timeout: 5)
                    }
                }

                // MARK: + ProgramService based seek
                context("ProgramService based seek") {
                    // MARK: ++ Error making playcall
                    context("Error making playcall") {
                        it("should stop playback with error") {
                            // Configure the playable
                            let provider = MockedProgramEntitlementProvider()
                            provider.mockedRequestEntitlementV2 = { _,_,_, callback in
                                var json = PlaybackEntitlement.requiedJson
                                json["mediaLocator"] = "file://play/.isml"
                                json["rwEnabled"] = true
                                
                                let contractRestrictions: [String: Any] = [
                                    "airplayEnabled" : true,
                                    "ffEnabled" : false,
                                    "maxBitrate" : 20,
                                    "maxResHeight" : 30,
                                    "minBitrate": 10,
                                    "rwEnabled": true,
                                    "timeshiftEnabled" : false
                                ]
                                
                                var entitlementVersion2Json = PlayBackEntitlementV2.requiedJson
                                entitlementVersion2Json["contractRestrictions"] = contractRestrictions
                                
                                callback(json.decode(PlaybackEntitlement.self), entitlementVersion2Json.decode(PlayBackEntitlementV2.self), nil, nil)
                            }
                            let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                            
                            // Initiate test
                            let currentDate = Date().unixEpoch
                            let seekOffset: Int64 = 60 * 60 * 1000 / 4
                            let env = SeekToTimeMock().runBeforeSeekableRangeProgramServiceSeekErrorPlaycall(playable: playable, currentDate: currentDate, seekOffset: seekOffset)
                            
                            expect(env.error).toEventuallyNot(beNil(), timeout: 5)
                            expect(env.error?.message).toEventually(equal("SOME_ERROR"), timeout: 5)
                            expect(env.error?.code).toEventually(equal(404), timeout: 5)
                        }
                    }

                    // MARK: ++ ENTITLED
                    context("ENTITLED") {
                        it("should allow playback") {
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
                            
                            // Initiate test
                            let currentDate = Date().unixEpoch
                            let seekOffset: Int64 = 60 * 60 * 1000 / 4
                            let env = SeekToTimeMock().runBeforeSeekableRangeProgramServiceSeekEntitled(playable: playable, currentDate: currentDate, seekOffset: seekOffset)
                            
                            
                            expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 5)
                            expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 5)
                            expect(env.player.tech.currentSource?.entitlement.playToken).toEventually(equal("ProgramSevicedFetchedEntitlement"), timeout: 5)
                            expect{ return self.playFrom(player: env.player, target: currentDate - seekOffset) }.toEventually(beLessThan(1000), timeout: 5)
                        }
                    }
                }
            }
            
            context("Contract Restrictions") {
                context("Enforce FastForward") {
                    it("should restrict seeking forward") {
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
                        
                        // Initiate test
                        let currentDate = Date().unixEpoch
                        let seekOffset: Int64 = 60 * 60 * 1000 / 4
                        let env = SeekToTimeMock().runEnforceContractRestrictions(playable: playable, currentDate: currentDate, seekOffset: seekOffset)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 5)
                        expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 5)
                        expect(env.warning).toEventuallyNot(beNil(), timeout: 5)
                        expect(env.warning?.message).toEventually(contain("Contract restrictions disables fast forwarding"), timeout: 5)
                    }
                }
                
                context("Enforce Rewind") {
                    it("should restrict seeking back") {
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
                        
                        
                        // Initiate test
                        let currentDate = Date().unixEpoch
                        let seekOffset: Int64 = 60 * 60 * 1000 / 4
                        let env = SeekToTimeMock().runEnforceContractRestrictions(playable: playable, currentDate: currentDate, seekOffset: -seekOffset)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 5)
                        expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 5)
                        expect(env.warning).toEventuallyNot(beNil(), timeout: 5)
                        expect(env.warning?.message).toEventually(contain("Contract restrictions disabled rewinding"), timeout: 5)
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

