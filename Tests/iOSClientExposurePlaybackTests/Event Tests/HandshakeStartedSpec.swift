//
//  HandshakeStartedSpec.swift
//  AnalyticsTests
//
//  Created by Fredrik Sjöberg on 2017-12-13.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation

import Quick
import Nimble
import iOSClientExposure

@testable import iOSClientExposurePlayback

class HandshakeStartedSpec: QuickSpec {
    override func spec() {
        describe("HandshakeStarted") {
            let timeStamp: Int64 = 10
            let type = "Playback.HandshakeStarted"
            let vodId = PlaybackIdentifier.vod(assetId: "vodAsset")
            let liveId = PlaybackIdentifier.live(channelId: "liveAsset")
            let programId = PlaybackIdentifier.program(programId: "programAsset", channelId: "liveAsset")
            let offlineId = PlaybackIdentifier.offline(assetId: "offlineAsset")
            let downloadId = PlaybackIdentifier.download(assetId: "downloadAsset")
            
            
            it("Should init and record complete structure") {
                let event = Playback.HandshakeStarted(timestamp: timeStamp, assetData: vodId)
                
                expect(event.timestamp).to(equal(timeStamp))
                expect(event.eventType).to(equal(type))
                expect(event.bufferLimit).to(equal(3000))
            }
            
            it("Should record correct assetData") {
                let vod = Playback.HandshakeStarted(timestamp: timeStamp, assetData: vodId)
                expect(vod.assetId).to(equal("vodAsset"))
                expect(vod.programId).to(beNil())
                expect(vod.channelId).to(beNil())
                
                let live = Playback.HandshakeStarted(timestamp: timeStamp, assetData: liveId)
                expect(live.assetId).to(beNil())
                expect(live.programId).to(beNil())
                expect(live.channelId).to(equal("liveAsset"))
                
                let program = Playback.HandshakeStarted(timestamp: timeStamp, assetData: programId)
                expect(program.assetId).to(beNil())
                expect(program.programId).to(equal("programAsset"))
                expect(program.channelId).to(equal("liveAsset"))
                
                let offline = Playback.HandshakeStarted(timestamp: timeStamp, assetData: offlineId)
                expect(offline.assetId).to(equal("offlineAsset"))
                expect(offline.programId).to(beNil())
                expect(offline.channelId).to(beNil())
                
                let download = Playback.HandshakeStarted(timestamp: timeStamp, assetData: downloadId)
                expect(download.assetId).to(equal("downloadAsset"))
                expect(download.programId).to(beNil())
                expect(download.channelId).to(beNil())
            }
            
            it("Should have no asset identifier if not set") {
                let noAssetId = Playback.HandshakeStarted(timestamp: timeStamp)
                expect(noAssetId.assetId).to(beNil())
                expect(noAssetId.programId).to(beNil())
                expect(noAssetId.channelId).to(beNil())
            }
            
            it("Should produce correct Vod jsonPayload") {
                let json = Playback.HandshakeStarted(timestamp: timeStamp, assetData: vodId).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["AssetId"] as? String).to(equal("vodAsset"))
                expect(json["ChannelId"] as? String).to(beNil())
                expect(json["ProgramId"] as? String).to(beNil())
                expect(json.count).to(equal(16))
            }
            
            it("Should produce correct Live jsonPayload") {
                let json = Playback.HandshakeStarted(timestamp: timeStamp, assetData: liveId).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["AssetId"] as? String).to(beNil())
                expect(json["ChannelId"] as? String).to(equal("liveAsset"))
                expect(json["ProgramId"] as? String).to(beNil())
                expect(json.count).to(equal(16))
            }
            
            it("Should produce correct Program jsonPayload") {
                let json = Playback.HandshakeStarted(timestamp: timeStamp, assetData: programId).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["AssetId"] as? String).to(beNil())
                expect(json["ChannelId"] as? String).to(equal("liveAsset"))
                expect(json["ProgramId"] as? String).to(equal("programAsset"))
                expect(json.count).to(equal(17))
            }
            
            it("Should produce correct Offline jsonPayload") {
                let json = Playback.HandshakeStarted(timestamp: timeStamp, assetData: offlineId).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["AssetId"] as? String).to(equal("offlineAsset"))
                expect(json["ChannelId"] as? String).to(beNil())
                expect(json["ProgramId"] as? String).to(beNil())
                expect(json.count).to(equal(16))
            }
            
            it("Should produce correct Download jsonPayload") {
                let json = Playback.HandshakeStarted(timestamp: timeStamp, assetData: downloadId).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["AssetId"] as? String).to(equal("downloadAsset"))
                expect(json["ChannelId"] as? String).to(beNil())
                expect(json["ProgramId"] as? String).to(beNil())
                expect(json.count).to(equal(16))
            }
        }
    }
}
