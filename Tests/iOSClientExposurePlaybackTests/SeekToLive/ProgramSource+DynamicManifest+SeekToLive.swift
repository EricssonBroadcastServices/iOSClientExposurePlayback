//
//  ProgramSource+DynamicManifest+SeekToLive.swift
//  ExposurePlaybackTests
//
//  Created by Fredrik Sjöberg on 2018-02-14.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation

import Quick
import Nimble
import iOSClientExposure
import AVFoundation

@testable import iOSClientPlayer
@testable import iOSClientExposurePlayback

class DynamicProgramSourceSeekToLiveSpec: QuickSpec {
    override func spec() {
        super.spec()
        
        describe("SeekToLive Dynamic ProgramSource") {
            // Seekable range is defined by the manifest
            // MARK: After seekableTimeRange
            ///  |---+-------|-----> live
            ///  p1  |       p2    |
            ///  r1  |             r2
            ///      s1 ---------> s2
            
            // MARK: + ENTITLED
            context("ENTITLED") {
                it("should allow playback") {
                    // Configure the playable
                    let provider = MockedProgramEntitlementProvider()
                    provider.mockedRequestEntitlementV2 = { _,_,_, callback in
                        var json = PlaybackEntitlement.requiedJson
                        json["mediaLocator"] = "file://play/.isml"
                        json["playSessionId"] = "SeekToLiveTrigger"
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
                        entitlementVersion2Json["playSessionId"] = "SeekToLiveTrigger"
                        entitlementVersion2Json["contractRestrictions"] = contractRestrictions
                        
                        callback(json.decode(PlaybackEntitlement.self), entitlementVersion2Json.decode(PlayBackEntitlementV2.self), nil, nil)
                    }
                    let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                    let properties = PlaybackProperties(playFrom: .defaultBehaviour)
                    
                    let env = SeekToLiveMock().runEntitledTest(playable: playable, properties: properties)
                    
                    expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: .seconds(5))
                    expect(env.player.currentProgram?.programId).toEventually(equal("program2"))
                }
            }
            
            // MARK: + Error fetching EPG
            context("Error fetching EPG") {
                it("should allow seek to live with warning message") {
                    // Configure the playable
                    let provider = MockedProgramEntitlementProvider()
                    provider.mockedRequestEntitlementV2 = { _,_,_, callback in
                        var json = PlaybackEntitlement.requiedJson
                        json["mediaLocator"] = "file://play/.isml"
                        json["playSessionId"] = "SeekToLiveTrigger"
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
                        entitlementVersion2Json["playSessionId"] = "SeekToLiveTrigger"
                        entitlementVersion2Json["contractRestrictions"] = contractRestrictions
                        
                        callback(json.decode(PlaybackEntitlement.self), entitlementVersion2Json.decode(PlayBackEntitlementV2.self), nil, nil)
                    }
                    let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                    let properties = PlaybackProperties(playFrom: .defaultBehaviour)
                    
                    let env = SeekToLiveMock().runErrorFetchingEpgTest(playable: playable, properties: properties)
                    
                    expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: .seconds(5))
                    expect(env.warning).toEventuallyNot(beNil(), timeout: .seconds(5))
                    expect(env.warning?.message).toEventually(contain("Program Service failed to fetch the current program at timestamp"), timeout: .seconds(5))
                }
            }
            
            // MARK: + Error validating entitlement
            context("Error validating entitlement") {
                it("should allow seek to live with warning message") {
                    // Configure the playable
                    let provider = MockedProgramEntitlementProvider()
                    provider.mockedRequestEntitlementV2 = { _,_,_, callback in
                        var json = PlaybackEntitlement.requiedJson
                        json["mediaLocator"] = "file://play/.isml"
                        json["playSessionId"] = "SeekToLiveTrigger"
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
                        entitlementVersion2Json["playSessionId"] = "SeekToLiveTrigger"
                        entitlementVersion2Json["contractRestrictions"] = contractRestrictions
                        
                        callback(json.decode(PlaybackEntitlement.self), entitlementVersion2Json.decode(PlayBackEntitlementV2.self), nil, nil)
                    }
                    let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                    let properties = PlaybackProperties(playFrom: .defaultBehaviour)
                    
                    let env = SeekToLiveMock().runErrorValidatingEntitlementTest(playable: playable, properties: properties)
                    
                    expect(env.player.currentProgram?.programId).toEventually(equal("program2"))
                    expect(env.warning).toEventuallyNot(beNil(), timeout: .seconds(5))
                    expect(env.warning?.message).toEventually(contain("Program Service failed to validate program"), timeout: .seconds(5))
                }
            }
            
            // MARK: + Gap in EPG
            context("Gap in EPG"){
                it("should allow seek to live if encountering epg gap") {
                    // Configure the playable
                    let provider = MockedProgramEntitlementProvider()
                    provider.mockedRequestEntitlementV2 = { _,_,_, callback in
                        var json = PlaybackEntitlement.requiedJson
                        json["mediaLocator"] = "file://play/.isml"
                        json["playSessionId"] = "SeekToLiveTrigger"
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
                        entitlementVersion2Json["playSessionId"] = "SeekToLiveTrigger"
                        entitlementVersion2Json["contractRestrictions"] = contractRestrictions
                        
                        callback(json.decode(PlaybackEntitlement.self), entitlementVersion2Json.decode(PlayBackEntitlementV2.self), nil, nil)
                    }
                    let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                    let properties = PlaybackProperties(playFrom: .defaultBehaviour)
                    
                    let env = SeekToLiveMock().runGapInEpgTest(playable: playable, properties: properties)
                    
                    expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: .seconds(5))
                    expect(env.warning).toEventuallyNot(beNil(), timeout: .seconds(5))
                    expect(env.warning?.message).toEventually(contain("Program Service encountered a gap in the Epg at timestamp"), timeout: .seconds(5))
                }
            }
            
            // MARK: + NOT_ENTITLED
            context("NOT_ENTITLED") {
                it("should stop with error if not entitled") {
                    // Configure the playable
                    let provider = MockedProgramEntitlementProvider()
                    provider.mockedRequestEntitlementV2 = { _,_,_, callback in
                        var json = PlaybackEntitlement.requiedJson
                        json["mediaLocator"] = "file://play/.isml"
                        json["playSessionId"] = "SeekToLiveTrigger"
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
                        entitlementVersion2Json["playSessionId"] = "SeekToLiveTrigger"
                        entitlementVersion2Json["contractRestrictions"] = contractRestrictions
                        
                        callback(json.decode(PlaybackEntitlement.self), entitlementVersion2Json.decode(PlayBackEntitlementV2.self), nil, nil)
                    }
                    let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                    let properties = PlaybackProperties(playFrom: .defaultBehaviour)
                    
                    let env = SeekToLiveMock().runNotEntitledTest(playable: playable, properties: properties)
                    
                    expect(env.error).toEventuallyNot(beNil(), timeout: .seconds(5))
                    expect(env.error?.code).toEventually(equal(403))
                    expect(env.error?.message).toEventually(equal("NOT_ENTITLED"))
                }
            }
        }
    }
}
