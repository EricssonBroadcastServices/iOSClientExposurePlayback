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
import Exposure

@testable import ExposurePlayback

class CreatedSpec: QuickSpec {
    override func spec() {
        describe("Created") {
            let timeStamp: Int64 = 10
            let type = "Playback.Created"
            let player = "EMP.iOS2"
            let version = "1.0.3"
            let revision = "0.1.3"
            let vodId = PlaybackIdentifier.vod(assetId: "vodAsset")
            let liveId = PlaybackIdentifier.live(channelId: "liveAsset")
            let programId = PlaybackIdentifier.program(programId: "programAsset", channelId: "liveAsset")
            let offlineId = PlaybackIdentifier.offline(assetId: "offlineAsset")
            let downloadId = PlaybackIdentifier.download(assetId: "downloadAsset")
            let mediaId = "mediaId"
            let autoPlay = true
            
            
            it("Should init and record complete structure") {
                let event = Playback.Created(timestamp: timeStamp, version: version, revision: revision, assetData: vodId, mediaId: mediaId, autoPlay: autoPlay)
                
                expect(event.timestamp).to(equal(timeStamp))
                expect(event.eventType).to(equal(type))
                expect(event.player).to(equal(player))
                expect(event.version).to(equal(version))
                
                expect(event.revision).to(equal(revision))
                expect(event.autoPlay).to(equal(autoPlay))
                expect(event.mediaId).to(equal(mediaId))
                expect(event.bufferLimit).to(equal(3000))
            }
            
            it("Should record correct playMode") {
                let vod = Playback.Created(timestamp: timeStamp, version: version, assetData: vodId)
                expect(vod.playMode).to(equal("vod"))
                expect(vod.assetId).to(equal("vodAsset"))
                expect(vod.programId).to(beNil())
                expect(vod.channelId).to(beNil())
                
                let live = Playback.Created(timestamp: timeStamp, version: version, assetData: liveId)
                expect(live.playMode).to(equal("live"))
                expect(live.assetId).to(beNil())
                expect(live.programId).to(beNil())
                expect(live.channelId).to(equal("liveAsset"))
                
                let program = Playback.Created(timestamp: timeStamp, version: version, assetData: programId)
                expect(program.playMode).to(equal("vod"))
                expect(program.assetId).to(beNil())
                expect(program.programId).to(equal("programAsset"))
                expect(program.channelId).to(equal("liveAsset"))
                
                let offline = Playback.Created(timestamp: timeStamp, version: version, assetData: offlineId)
                expect(offline.playMode).to(equal("offline"))
                expect(offline.assetId).to(equal("offlineAsset"))
                expect(offline.programId).to(beNil())
                expect(offline.channelId).to(beNil())
                
                let download = Playback.Created(timestamp: timeStamp, version: version, assetData: downloadId)
                expect(download.playMode).to(equal("vod"))
                expect(download.assetId).to(equal("downloadAsset"))
                expect(download.programId).to(beNil())
                expect(download.channelId).to(beNil())
            }
            
            it("Should have no asset identifier if not set") {
                let noAssetId = Playback.Created(timestamp: timeStamp, version: version)
                expect(noAssetId.playMode).to(beNil())
                expect(noAssetId.assetId).to(beNil())
                expect(noAssetId.programId).to(beNil())
                expect(noAssetId.channelId).to(beNil())
            }
            
            it("Should produce correct Vod jsonPayload") {
                let json = Playback.Created(timestamp: timeStamp, version: version, revision: revision, assetData: vodId, mediaId: mediaId, autoPlay: autoPlay).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["Player"] as? String).to(equal(player))
                expect(json["Version"] as? String).to(equal(version))
                expect(json["Revision"] as? String).to(equal(revision))
                expect(json["AutoPlay"] as? Bool).to(equal(autoPlay))
                expect(json["PlayMode"] as? String).to(equal("vod"))
                expect(json["AssetId"] as? String).to(equal("vodAsset"))
                expect(json["ChannelId"] as? String).to(beNil())
                expect(json["ProgramId"] as? String).to(beNil())
                expect(json["MediaId"] as? String).to(equal("mediaId"))
                expect(json.count).to(equal(9))
            }
            
            it("Should produce correct Live jsonPayload") {
                let json = Playback.Created(timestamp: timeStamp, version: version, revision: revision, assetData: liveId, mediaId: mediaId, autoPlay: autoPlay).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["Player"] as? String).to(equal(player))
                expect(json["Version"] as? String).to(equal(version))
                expect(json["Revision"] as? String).to(equal(revision))
                expect(json["AutoPlay"] as? Bool).to(equal(autoPlay))
                expect(json["PlayMode"] as? String).to(equal("live"))
                expect(json["AssetId"] as? String).to(beNil())
                expect(json["ChannelId"] as? String).to(equal("liveAsset"))
                expect(json["ProgramId"] as? String).to(beNil())
                expect(json["MediaId"] as? String).to(equal("mediaId"))
            }
            
            it("Should produce correct Program jsonPayload") {
                let json = Playback.Created(timestamp: timeStamp, version: version, revision: revision, assetData: programId, mediaId: mediaId, autoPlay: autoPlay).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["Player"] as? String).to(equal(player))
                expect(json["Version"] as? String).to(equal(version))
                expect(json["Revision"] as? String).to(equal(revision))
                expect(json["AutoPlay"] as? Bool).to(equal(autoPlay))
                expect(json["PlayMode"] as? String).to(equal("vod"))
                expect(json["AssetId"] as? String).to(beNil())
                expect(json["ChannelId"] as? String).to(equal("liveAsset"))
                expect(json["ProgramId"] as? String).to(equal("programAsset"))
                expect(json["MediaId"] as? String).to(equal("mediaId"))
            }
            
            it("Should produce correct Offline jsonPayload") {
                let json = Playback.Created(timestamp: timeStamp, version: version, revision: revision, assetData: offlineId, mediaId: mediaId, autoPlay: autoPlay).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["Player"] as? String).to(equal(player))
                expect(json["Version"] as? String).to(equal(version))
                expect(json["Revision"] as? String).to(equal(revision))
                expect(json["AutoPlay"] as? Bool).to(equal(autoPlay))
                expect(json["PlayMode"] as? String).to(equal("offline"))
                expect(json["AssetId"] as? String).to(equal("offlineAsset"))
                expect(json["ChannelId"] as? String).to(beNil())
                expect(json["ProgramId"] as? String).to(beNil())
                expect(json["MediaId"] as? String).to(equal("mediaId"))
            }
            
            it("Should produce correct Download jsonPayload") {
                let json = Playback.Created(timestamp: timeStamp, version: version, revision: revision, assetData: downloadId, mediaId: mediaId, autoPlay: autoPlay).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["Player"] as? String).to(equal(player))
                expect(json["Version"] as? String).to(equal(version))
                expect(json["Revision"] as? String).to(equal(revision))
                expect(json["AutoPlay"] as? Bool).to(equal(autoPlay))
                expect(json["PlayMode"] as? String).to(equal("vod"))
                expect(json["AssetId"] as? String).to(equal("downloadAsset"))
                expect(json["ChannelId"] as? String).to(beNil())
                expect(json["ProgramId"] as? String).to(beNil())
                expect(json["MediaId"] as? String).to(equal("mediaId"))
            }
        }
    }
}
