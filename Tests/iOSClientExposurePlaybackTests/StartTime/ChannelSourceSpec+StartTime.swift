//
//  ChannelSourceSpec+StartTime.swift
//  ExposureTests
//
//  Created by Fredrik Sjöberg on 2018-01-26.
//  Copyright © 2018 emp. All rights reserved.
//

import Quick
import Nimble
import iOSClientPlayer
import iOSClientExposure
import Foundation

@testable import iOSClientPlayer
@testable import iOSClientExposurePlayback

class ChannelSourceStartTimeSpec: QuickSpec {
    override func spec() {
        super.spec()
        describe("ChannelSource") {
            let currentDate = Date().unixEpoch
            let hour: Int64 = 60 * 60 * 1000
            let environment = Environment(baseUrl: "url", customer: "customer", businessUnit: "businessUnit")
            let sessionToken = SessionToken(value: "token")
            
            func generateEnv() -> TestEnv {
                let env = TestEnv(environment: environment, sessionToken: sessionToken)
                env.player.context.isDynamicManifest = { _,_ in return false }
                env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour/2))
                return env
            }
            
            func generatePlayable(pipe: String = "file://play/.isml", lastViewedOffset: Int? = nil, lastViewedTime: Int64? = nil) -> ChannelPlayable {
                // Configure the playable
                let provider = MockedChannelEntitlementProvider()
                provider.mockedRequestEntitlementV2 = { _,_,_, callback in
                    var json = PlaybackEntitlement.requiedJson
                    json["mediaLocator"] = pipe
                    
                    //PlayBack Entitlement V2 Booksmarks
                    var bookmarks: [String : Any] = [
                        "liveTime" : 10,
                        "lastViewedOffset" : 10,
                        "lastViewedTime" : 10
                    ]
                    
                    if let offset = lastViewedOffset {
                        json["lastViewedOffset"] = offset
                        bookmarks["lastViewedOffset"] = offset
                    }
                    if let offset = lastViewedTime {
                        json["lastViewedTime"] = offset
                        bookmarks["lastViewedTime"] = offset
                    }
                    
                    // Live will be true for a channel
                    let streamInfo: [String: Any] = [
                        "live" : true,
                        "static" : false,
                        "event" : false,
                        "start" : 0,
                        "channelId" : "channelId",
                        "programId" : "programId"
                    ]
                    var entitlementVersion2Json = PlayBackEntitlementV2.requiedJson
                    entitlementVersion2Json["streamInfo"] = streamInfo
                    entitlementVersion2Json["bookmarks"] = bookmarks
                    
                    callback(json.decode(PlaybackEntitlement.self), entitlementVersion2Json.decode(PlayBackEntitlementV2.self), nil, nil)
                }
                return ChannelPlayable(assetId: "assetId", entitlementProvider: provider)
            }
            
            context(".defaultBehaviour") {
                let properties = PlaybackProperties(playFrom: .defaultBehaviour)
                context("USP") {
                    it("should use default behavior with lastViewedOffset specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(lastViewedOffset: 100)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(beNil())
                    }
                    
                    it("should use default behavior with lastViewedTime specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(lastViewedTime: 100)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(beNil())
                    }
                    
                    it("should use default behavior with no bookmarks specified") {
                        let env = generateEnv()
                        let playable = generatePlayable()
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(beNil())
                    }
                }
                
                context("old pipe") {
                    it("should use default behavior with lastViewedOffset specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(pipe: "file://old/pipe", lastViewedOffset: 100)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(beNil())
                    }
                    
                    it("should use default behavior with lastViewedTime specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(pipe: "file://old/pipe", lastViewedTime: 100)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(beNil())
                    }
                    
                    it("should use default behavior with no bookmarks specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(pipe: "file://old/pipe")
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(beNil())
                    }
                }
            }
            
            context(".beginning") {
                let properties = PlaybackProperties(playFrom: .beginning)
                let segmentLength: Int64 = 6000
                context("USP") {
                    it("should start from zero with lastViewedOffset specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(lastViewedOffset: 100)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(equal(segmentLength))
                    }
                    
                    it("should start from zero with lastViewedTime specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(lastViewedTime: 100)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(equal(segmentLength))
                    }
                    
                    it("should start from zero with no bookmarks specified") {
                        let env = generateEnv()
                        let playable = generatePlayable()
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(equal(segmentLength))
                    }
                }
                
                context("old pipe") {
                    it("should rely on vod manifest to start from 0 with lastViewedOffset specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(pipe: "file://old/pipe", lastViewedOffset: 100)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(beNil())
                    }
                    
                    it("should rely on vod manifest to start from 0 with lastViewedTime specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(pipe: "file://old/pipe", lastViewedTime: 100)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(beNil())
                    }
                    
                    it("should rely on vod manifest to start from 0 with no bookmarks specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(pipe: "file://old/pipe")
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(beNil())
                    }
                }
            }
            
            context(".bookmark") {
                let properties = PlaybackProperties(playFrom: .bookmark)
                context("USP") {
                    it("should pick up lastViewedOffset if specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(lastViewedOffset: 100)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(equal(100))
                    }
                    
                    it("should use default behavior with lastViewedTime specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(lastViewedTime: 100)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(beNil())
                    }
                    
                    it("should use default behavior with no bookmarks specified") {
                        let env = generateEnv()
                        let playable = generatePlayable()
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(beNil())
                    }
                }
                
                context("old pipe") {
                    it("should pick up lastViewedOffset if specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(pipe: "file://old/pipe", lastViewedOffset: 100)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(equal(100))
                    }
                    
                    it("should use default behavior with lastViewedTime specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(pipe: "file://old/pipe", lastViewedTime: 100)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(beNil())
                    }
                    
                    it("should use default behavior with no bookmarks specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(pipe: "file://old/pipe")
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(beNil())
                    }
                }
            }
            
            context(".customTime") {
                let lastViewedTime = currentDate + 1000
                let customOffset = currentDate + 300
                let illegalOffset = currentDate - 1000
                let properties = PlaybackProperties(playFrom: .customTime(timestamp: customOffset))
                context("USP") {
                    it("should use custom value if lastViewedOffset if specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(lastViewedOffset: 100)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(equal(customOffset))
                        expect(env.player.startPosition).to(beNil())
                    }
                    
                    it("should use custom value if lastViewedTime specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(lastViewedTime: lastViewedTime)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(equal(customOffset))
                        expect(env.player.startPosition).to(beNil())
                    }
                    
                    it("should use custom value if no bookmarks specified") {
                        let env = generateEnv()
                        let playable = generatePlayable()
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(equal(customOffset))
                        expect(env.player.startPosition).to(beNil())
                    }
                    
                    it("should use default behavior with illegal startTime") {
                        let properties = PlaybackProperties(playFrom: .customTime(timestamp: illegalOffset))
                        let env = generateEnv()
                        let playable = generatePlayable(lastViewedTime: lastViewedTime)
                        
                        env.player.onWarning{ [weak env] player, source, warn in
                            env?.warning = warn
                        }
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(beNil())
                        expect(env.warning).toEventuallyNot(beNil(), timeout: .seconds(5))
                        expect(env.warning?.message).toEventually(contain("Invalid start time"), timeout: .seconds(5))
                    }
                }
                
                context("old pipe") {
                    it("should use custom value if lastViewedOffset if specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(pipe: "file://old/pipe", lastViewedOffset: 100)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(equal(customOffset))
                        expect(env.player.startPosition).to(beNil())
                    }
                    
                    it("should use custom value if lastViewedTime specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(pipe: "file://old/pipe", lastViewedTime: lastViewedTime)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(equal(customOffset))
                        expect(env.player.startPosition).to(beNil())
                    }
                    
                    it("should use custom value if no bookmarks specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(pipe: "file://old/pipe")
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(equal(customOffset))
                        expect(env.player.startPosition).to(beNil())
                    }
                    
                    it("should use default behavior with illegal startTime") {
                        let properties = PlaybackProperties(playFrom: .customTime(timestamp: illegalOffset))
                        let env = generateEnv()
                        let playable = generatePlayable(pipe: "file://old/pipe", lastViewedTime: lastViewedTime)
                        
                        env.player.onWarning{ [weak env] player, source, warn in
                            env?.warning = warn
                        }
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(beNil())
                        expect(env.warning).toEventuallyNot(beNil(), timeout: .seconds(5))
                        expect(env.warning?.message).toEventually(contain("Invalid start time"), timeout: .seconds(5))
                    }
                }
            }
            
            context(".customPosition") {
                let properties = PlaybackProperties(playFrom: .customPosition(position: 300))
                context("USP") {
                    it("should use custom value if lastViewedOffset if specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(lastViewedOffset: 100)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(equal(300))
                    }
                    
                    it("should use custom value if lastViewedTime specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(lastViewedTime: 100)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(equal(300))
                    }
                    
                    it("should use custom value if no bookmarks specified") {
                        let env = generateEnv()
                        let playable = generatePlayable()
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(equal(300))
                    }
                }
                
                context("old pipe") {
                    it("should use custom value if lastViewedOffset if specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(pipe: "file://old/pipe", lastViewedOffset: 100)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(equal(300))
                    }
                    
                    it("should use custom value if lastViewedTime specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(pipe: "file://old/pipe", lastViewedTime: 100)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(equal(300))
                    }
                    
                    it("should use custom value if no bookmarks specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(pipe: "file://old/pipe")
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(equal(300))
                    }
                }
            }
        }
    }
}

