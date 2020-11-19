//
//  AssetSourceSpec+StartTime.swift
//  ExposureTests
//
//  Created by Fredrik Sjöberg on 2018-01-26.
//  Copyright © 2018 emp. All rights reserved.
//

import Quick
import Nimble
import Player
import Exposure

@testable import Player
@testable import ExposurePlayback

class AssetSourceStartTimeSpec: QuickSpec {
    override func spec() {
        super.spec()
        
        describe("AssetSource") {
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
            
            func generatePlayable(pipe: String = "file://play/.isml", lastViewedOffset: Int? = nil, lastViewedTime: Int? = nil) -> AssetPlayable {
                // Configure the playable
                let provider = MockedAssetEntitlementProvider()
                
                provider.mockedRequestEntitlementV2 = { _,_,_,_,callback in
                    
                    
                    var json = PlaybackEntitlement.requiedJson
                    json["mediaLocator"] = pipe
                    
                    /* var bookmarks: [String : Any] = [
                        "liveTime" : 10,
                        "lastViewedOffset" : 10,
                        "lastViewedTime" : 10
                    ] */
                    
                    if let offset = lastViewedOffset {
                        json["lastViewedOffset"] = offset
                        //bookmarks["lastViewedOffset"] = offset
                    }
                    if let offset = lastViewedTime {
                        json["lastViewedTime"] = offset
                        //bookmarks["lastViewedTime"] = offset
                    }

                    callback(json.decode(PlaybackEntitlement.self), PlayBackEntitlementV2.requiedJson.decode(PlayBackEntitlementV2.self),nil, nil)
                }
                
                return AssetPlayable(assetId: "assetId", assetType: nil, entitlementProvider: provider)
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
                context("USP") {
                    it("should start from 0 with lastViewedOffset specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(lastViewedOffset: 100)

                        env.player.startPlayback(playable: playable, properties: properties)

                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(equal(0))
                    }

                    it("should start from 0 with lastViewedTime specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(lastViewedTime: 100)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(equal(0))
                    }

                    it("should start from 0 with no bookmarks specified") {
                        let env = generateEnv()
                        let playable = generatePlayable()
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(equal(0))
                    }
                }
                
                context("old pipe") {
                    it("should start from 0 with  lastViewedOffset specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(pipe: "file://old/pipe", lastViewedOffset: 100)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(equal(0))
                    }

                    it("should start from 0 with lastViewedTime specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(pipe: "file://old/pipe", lastViewedTime: 100)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(equal(0))
                    }

                    it("should start from 0 with no bookmarks specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(pipe: "file://old/pipe")
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(equal(0))
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
                let properties = PlaybackProperties(playFrom: .customTime(timestamp: 300))
                context("USP") {
                    it("should use custom value if lastViewedOffset if specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(lastViewedOffset: 100)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(beNil())
                    }

                    it("should use custom value if lastViewedTime specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(lastViewedTime: 100)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(beNil())
                    }

                    it("should use custom value if no bookmarks specified") {
                        let env = generateEnv()
                        let playable = generatePlayable()
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(beNil())
                    }
                }

                context("old pipe") {
                    it("should use custom value if lastViewedOffset if specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(pipe: "file://old/pipe", lastViewedOffset: 100)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(beNil())
                    }

                    it("should use custom value if lastViewedTime specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(pipe: "file://old/pipe", lastViewedTime: 100)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(beNil())
                    }

                    it("should use custom value if no bookmarks specified") {
                        let env = generateEnv()
                        let playable = generatePlayable(lastViewedOffset: 100)
                        
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil())
                        expect(env.player.startTime).to(beNil())
                        expect(env.player.startPosition).to(beNil())
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

