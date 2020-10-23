//
//  BitrateRestrictionsSpec.swift
//  ExposurePlaybackTests
//
//  Created by Fredrik Sjöberg on 2018-02-22.
//  Copyright © 2018 emp. All rights reserved.
//

import Quick
import Nimble
import AVFoundation
import Exposure
import Player

@testable import ExposurePlayback

class BitrateRestrictionSpec: QuickSpec {
    
    override func spec() {
        super.spec()
        
        let currentDate = Date().unixEpoch
        let hour: Int64 = 60 * 60 * 1000
        
        let env = Environment(baseUrl: "http://www.example.com", customer: "customer", businessUnit: "businessUnit")
        let token = SessionToken(value: "token")
        
        context("Bitrate Restrictions") {
            it("should apply PlaybackProperties preferredMaxBitrate") {
                let env = TestEnv(environment: env, sessionToken: token)
                
                let preferredBitRate: Int64 = 300000
                env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour/2))
                
                
                // Mock the ProgramService
                env.mockProgramService{ environment, sessionToken, channelId in
                    let provider = MockedProgramProvider()
                    provider.mockedFetchProgram = { _,timestamp,_, callback in
                        if timestamp > currentDate + hour/2 {
                            let program = Program
                                .validJson(programId: "program2", channelId: "channelId", assetId: "asset0")
                                .timestamp(starting: currentDate + hour / 2, ending: currentDate+hour)
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
                
                // Configure the playable
                let provider = MockedProgramEntitlementProvider()
                provider.mockedRequestEntitlementV2 = { _,_,_, callback in
                    var json = PlaybackEntitlement.requiedJson
                    json["mediaLocator"] = "file://play/.isml"
                    json["playSessionId"] = "BitrateSession"
                    
                    let streamInfo: [String: Any] = [
                        "live" : false,
                        "static" : false,
                        "event" : false,
                        "start" : 0,
                        "channelId" : "channelId",
                        "programId" : "programId"
                    ]
                    
                    var entitlementVersion2Json = PlayBackEntitlementV2.requiedJson
                    entitlementVersion2Json["streamInfo"] = streamInfo
                    entitlementVersion2Json["playSessionId"] = "BitrateSession"
                    callback(json.decode(PlaybackEntitlement.self),entitlementVersion2Json.decode(PlayBackEntitlementV2.self), nil, nil)
                }
                let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                let properties = PlaybackProperties(maxBitrate: preferredBitRate)
                
                env.player.startPlayback(playable: playable, properties: properties)
                
                expect(env.player.tech.preferredMaxBitrate).toEventually(equal(preferredBitRate), timeout: .seconds(5))
            }
        }
    }
}


