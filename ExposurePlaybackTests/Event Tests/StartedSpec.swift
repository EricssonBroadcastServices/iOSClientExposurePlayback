//
//  StartedSpec.swift
//  AnalyticsTests
//
//  Created by Fredrik Sjöberg on 2017-12-13.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation

import Quick
import Nimble
import Exposure

@testable import ExposurePlayback

class StartedSpec: QuickSpec {
    override func spec() {
        describe("Started") {
            let timeStamp: Int64 = 10
            let offset: Int64 = 10
            let bitrate: Int64 = 10
            let videoLength: Int64 = 10
            let type = "Playback.Started"
            let vodId = PlaybackIdentifier.vod(assetId: "vodAsset")
            let liveId = PlaybackIdentifier.live(channelId: "liveAsset")
            let programId = PlaybackIdentifier.program(programId: "programAsset", channelId: "liveAsset")
            let offlineId = PlaybackIdentifier.offline(assetId: "offlineAsset")
            let downloadId = PlaybackIdentifier.download(assetId: "downloadAsset")
            let mediaId = "mediaId"
            
            
            it("Should init and record complete structure") {
                let event = Playback.Started(timestamp: timeStamp, assetData: vodId, mediaId: mediaId, offsetTime: offset, videoLength: videoLength, bitrate: bitrate)
                
                expect(event.timestamp).to(equal(timeStamp))
                expect(event.eventType).to(equal(type))
                expect(event.offsetTime).to(equal(offset))
                expect(event.videoLength).to(equal(videoLength))
                expect(event.bitrate).to(equal(bitrate))
                expect(event.mediaId).to(equal(mediaId))
                expect(event.bufferLimit).to(equal(3000))
            }
            
            it("Should record correct playMode") {
                let vod = Playback.Started(timestamp: timeStamp, assetData: vodId, mediaId: mediaId, offsetTime: offset)
                expect(vod.playMode).to(equal("vod"))
                expect(vod.assetId).to(equal("vodAsset"))
                expect(vod.programId).to(beNil())
                expect(vod.channelId).to(beNil())
                
                let live = Playback.Started(timestamp: timeStamp, assetData: liveId, mediaId: mediaId, offsetTime: offset)
                expect(live.playMode).to(equal("live"))
                expect(live.assetId).to(beNil())
                expect(live.programId).to(beNil())
                expect(live.channelId).to(equal("liveAsset"))
                
                let program = Playback.Started(timestamp: timeStamp, assetData: programId, mediaId: mediaId, offsetTime: offset)
                expect(program.playMode).to(equal("vod"))
                expect(program.assetId).to(beNil())
                expect(program.programId).to(equal("programAsset"))
                expect(program.channelId).to(equal("liveAsset"))
                
                let offline = Playback.Started(timestamp: timeStamp, assetData: offlineId, mediaId: mediaId, offsetTime: offset)
                expect(offline.playMode).to(equal("offline"))
                expect(offline.assetId).to(equal("offlineAsset"))
                expect(offline.programId).to(beNil())
                expect(offline.channelId).to(beNil())
                
                let download = Playback.Started(timestamp: timeStamp, assetData: downloadId, mediaId: mediaId, offsetTime: offset)
                expect(download.playMode).to(equal("vod"))
                expect(download.assetId).to(equal("downloadAsset"))
                expect(download.programId).to(beNil())
                expect(download.channelId).to(beNil())
            }
            
            it("Should produce correct Vod jsonPayload") {
                let json = Playback.Started(timestamp: timeStamp, assetData: vodId, mediaId: mediaId, offsetTime: offset, videoLength: videoLength, bitrate: bitrate).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["PlayMode"] as? String).to(equal("vod"))
                expect(json["AssetId"] as? String).to(equal("vodAsset"))
                expect(json["ChannelId"] as? String).to(beNil())
                expect(json["ProgramId"] as? String).to(beNil())
                expect(json["MediaId"] as? String).to(equal("mediaId"))
                expect(json["OffsetTime"] as? Int64).to(equal(offset))
                expect(json["VideoLength"] as? Int64).to(equal(videoLength))
                expect(json["Bitrate"] as? Int64).to(equal(bitrate))
                expect(json.count).to(equal(8))
            }
            
            it("Should produce correct Live jsonPayload") {
                let json = Playback.Started(timestamp: timeStamp, assetData: liveId, mediaId: mediaId, offsetTime: offset, videoLength: videoLength, bitrate: bitrate).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["PlayMode"] as? String).to(equal("live"))
                expect(json["AssetId"] as? String).to(beNil())
                expect(json["ChannelId"] as? String).to(equal("liveAsset"))
                expect(json["ProgramId"] as? String).to(beNil())
                expect(json["MediaId"] as? String).to(equal("mediaId"))
                expect(json["OffsetTime"] as? Int64).to(equal(offset))
                expect(json["VideoLength"] as? Int64).to(equal(videoLength))
                expect(json["Bitrate"] as? Int64).to(equal(bitrate))
                expect(json.count).to(equal(8))
            }
            
            it("Should produce correct Program jsonPayload") {
                let json = Playback.Started(timestamp: timeStamp, assetData: programId, mediaId: mediaId, offsetTime: offset, videoLength: videoLength, bitrate: bitrate).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["PlayMode"] as? String).to(equal("vod"))
                expect(json["AssetId"] as? String).to(beNil())
                expect(json["ChannelId"] as? String).to(equal("liveAsset"))
                expect(json["ProgramId"] as? String).to(equal("programAsset"))
                expect(json["MediaId"] as? String).to(equal("mediaId"))
                expect(json["OffsetTime"] as? Int64).to(equal(offset))
                expect(json["VideoLength"] as? Int64).to(equal(videoLength))
                expect(json["Bitrate"] as? Int64).to(equal(bitrate))
                expect(json.count).to(equal(9))
            }
            
            it("Should produce correct Offline jsonPayload") {
                let json = Playback.Started(timestamp: timeStamp, assetData: offlineId, mediaId: mediaId, offsetTime: offset, videoLength: videoLength, bitrate: bitrate).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["PlayMode"] as? String).to(equal("offline"))
                expect(json["AssetId"] as? String).to(equal("offlineAsset"))
                expect(json["ChannelId"] as? String).to(beNil())
                expect(json["ProgramId"] as? String).to(beNil())
                expect(json["MediaId"] as? String).to(equal("mediaId"))
                expect(json["OffsetTime"] as? Int64).to(equal(offset))
                expect(json["VideoLength"] as? Int64).to(equal(videoLength))
                expect(json["Bitrate"] as? Int64).to(equal(bitrate))
                expect(json.count).to(equal(8))
            }
            
            it("Should produce correct Download jsonPayload") {
                let json = Playback.Started(timestamp: timeStamp, assetData: downloadId, mediaId: mediaId, offsetTime: offset, videoLength: videoLength, bitrate: bitrate).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["PlayMode"] as? String).to(equal("vod"))
                expect(json["AssetId"] as? String).to(equal("downloadAsset"))
                expect(json["ChannelId"] as? String).to(beNil())
                expect(json["ProgramId"] as? String).to(beNil())
                expect(json["MediaId"] as? String).to(equal("mediaId"))
                expect(json["OffsetTime"] as? Int64).to(equal(offset))
                expect(json["VideoLength"] as? Int64).to(equal(videoLength))
                expect(json["Bitrate"] as? Int64).to(equal(bitrate))
                expect(json.count).to(equal(8))
            }
        }
    }
}
