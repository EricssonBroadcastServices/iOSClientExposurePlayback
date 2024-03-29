//
//  CreatedSpec.swift
//  AnalyticsTests
//
//  Created by Fredrik Sjöberg on 2017-12-12.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Quick
import Nimble
import iOSClientExposure
import UIKit

@testable import iOSClientExposurePlayback

class CreatedSpec: QuickSpec {
    override func spec() {
        func deviceName() -> String {
            let name = UIDevice.current.systemName
            if name == "iPhone OS" {
                return "iOS"
            }
            return name
        }
        
        describe("Created") {
            let timeStamp: Int64 = 10
            let type = "Playback.Created"
            let player = "EMP."+deviceName()+"2"
            let version = "1.0.3"
            let exposureVersion = "0.1.3"
            let techVersion = "0.1.3"
            let vodId = PlaybackIdentifier.vod(assetId: "vodAsset")
            let liveId = PlaybackIdentifier.live(channelId: "liveAsset")
            let programId = PlaybackIdentifier.program(programId: "programAsset", channelId: "liveAsset")
            let offlineId = PlaybackIdentifier.offline(assetId: "offlineAsset")
            let downloadId = PlaybackIdentifier.download(assetId: "downloadAsset")
            let autoPlay = true
            
            
            it("Should init and record complete structure") {
                let event = Playback.Created(timestamp: timeStamp, version: version, exposureVersion: exposureVersion, techVersion: techVersion, assetData: vodId, autoPlay: autoPlay)
                
                expect(event.timestamp).to(equal(timeStamp))
                expect(event.eventType).to(equal(type))
                expect(event.player).to(equal(player))
                expect(event.version).to(equal(version))
                
                expect(event.exposureVersion).to(equal(exposureVersion))
                expect(event.autoPlay).to(equal(autoPlay))
                expect(event.bufferLimit).to(equal(3000))
            }
            
            it("Should record correct playMode") {
                let vod = Playback.Created(timestamp: timeStamp, version: version, techVersion: techVersion, assetData: vodId)
                expect(vod.playMode).to(equal("vod"))
                expect(vod.assetId).to(equal("vodAsset"))
                expect(vod.programId).to(beNil())
                expect(vod.channelId).to(beNil())
                
                let live = Playback.Created(timestamp: timeStamp, version: version, techVersion: techVersion, assetData: liveId)
                expect(live.playMode).to(equal("live"))
                expect(live.assetId).to(beNil())
                expect(live.programId).to(beNil())
                expect(live.channelId).to(equal("liveAsset"))
                
                let program = Playback.Created(timestamp: timeStamp, version: version, techVersion: techVersion, assetData: programId)
                expect(program.playMode).to(equal("vod"))
                expect(program.assetId).to(beNil())
                expect(program.programId).to(equal("programAsset"))
                expect(program.channelId).to(equal("liveAsset"))
                
                let offline = Playback.Created(timestamp: timeStamp, version: version, techVersion: techVersion, assetData: offlineId)
                expect(offline.playMode).to(equal("offline"))
                expect(offline.assetId).to(equal("offlineAsset"))
                expect(offline.programId).to(beNil())
                expect(offline.channelId).to(beNil())
                
                let download = Playback.Created(timestamp: timeStamp, version: version, techVersion: techVersion, assetData: downloadId)
                expect(download.playMode).to(equal("vod"))
                expect(download.assetId).to(equal("downloadAsset"))
                expect(download.programId).to(beNil())
                expect(download.channelId).to(beNil())
            }
            
            it("Should have no asset identifier if not set") {
                let noAssetId = Playback.Created(timestamp: timeStamp, version: version, techVersion: techVersion, assetData: downloadId )
                expect(noAssetId.playMode).to(equal("vod"))
                expect(noAssetId.assetId).to(equal("downloadAsset"))
                expect(noAssetId.programId).to(beNil())
                expect(noAssetId.channelId).to(beNil())
            }
            
            it("Should produce correct Vod jsonPayload") {
                let json = Playback.Created(timestamp: timeStamp, version: version, exposureVersion: exposureVersion, techVersion: techVersion, assetData: vodId, autoPlay: autoPlay).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["Player"] as? String).to(equal(player))
                expect(json["Version"] as? String).to(equal(version))
                expect(json["ExposureVersion"] as? String).to(equal(exposureVersion))
                expect(json["AutoPlay"] as? Bool).to(equal(autoPlay))
                expect(json["PlayMode"] as? String).to(equal("vod"))
                expect(json["AssetId"] as? String).to(equal("vodAsset"))
                expect(json["ChannelId"] as? String).to(beNil())
                expect(json["ProgramId"] as? String).to(beNil())
                expect(json.count).to(equal(17))
            }
            
            it("Should produce correct Live jsonPayload") {
                let json = Playback.Created(timestamp: timeStamp, version: version, exposureVersion: exposureVersion, techVersion: techVersion, assetData: liveId, autoPlay: autoPlay).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["Player"] as? String).to(equal(player))
                expect(json["Version"] as? String).to(equal(version))
                expect(json["ExposureVersion"] as? String).to(equal(exposureVersion))
                expect(json["AutoPlay"] as? Bool).to(equal(autoPlay))
                expect(json["PlayMode"] as? String).to(equal("live"))
                expect(json["AssetId"] as? String).to(beNil())
                expect(json["ChannelId"] as? String).to(equal("liveAsset"))
                expect(json["ProgramId"] as? String).to(beNil())
            }
            
            it("Should produce correct Program jsonPayload") {
                let json = Playback.Created(timestamp: timeStamp, version: version, exposureVersion: exposureVersion, techVersion: techVersion, assetData: programId, autoPlay: autoPlay).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["Player"] as? String).to(equal(player))
                expect(json["Version"] as? String).to(equal(version))
                expect(json["ExposureVersion"] as? String).to(equal(exposureVersion))
                expect(json["AutoPlay"] as? Bool).to(equal(autoPlay))
                expect(json["PlayMode"] as? String).to(equal("vod"))
                expect(json["AssetId"] as? String).to(beNil())
                expect(json["ChannelId"] as? String).to(equal("liveAsset"))
                expect(json["ProgramId"] as? String).to(equal("programAsset"))
            }
            
            it("Should produce correct Offline jsonPayload") {
                let json = Playback.Created(timestamp: timeStamp, version: version, exposureVersion: exposureVersion, techVersion: techVersion, assetData: offlineId, autoPlay: autoPlay).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["Player"] as? String).to(equal(player))
                expect(json["Version"] as? String).to(equal(version))
                expect(json["ExposureVersion"] as? String).to(equal(exposureVersion))
                expect(json["AutoPlay"] as? Bool).to(equal(autoPlay))
                expect(json["PlayMode"] as? String).to(equal("offline"))
                expect(json["AssetId"] as? String).to(equal("offlineAsset"))
                expect(json["ChannelId"] as? String).to(beNil())
                expect(json["ProgramId"] as? String).to(beNil())
            }
            
            it("Should produce correct Download jsonPayload") {
                let json = Playback.Created(timestamp: timeStamp, version: version, exposureVersion: exposureVersion, techVersion: techVersion, assetData: downloadId, autoPlay: autoPlay).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["Player"] as? String).to(equal(player))
                expect(json["Version"] as? String).to(equal(version))
                expect(json["ExposureVersion"] as? String).to(equal(exposureVersion))
                expect(json["AutoPlay"] as? Bool).to(equal(autoPlay))
                expect(json["PlayMode"] as? String).to(equal("vod"))
                expect(json["AssetId"] as? String).to(equal("downloadAsset"))
                expect(json["ChannelId"] as? String).to(beNil())
                expect(json["ProgramId"] as? String).to(beNil())
            }
        }
    }
}
