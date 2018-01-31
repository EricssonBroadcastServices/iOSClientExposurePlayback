//
//  DownloadStartedSpec.swift
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

class DownloadStartedSpec: QuickSpec {
    override func spec() {
        describe("DownloadStarted") {
            let timeStamp: Int64 = 10
            let type = "Playback.DownloadStarted"
            let downloadId = PlaybackIdentifier.download(assetId: "downloadAsset")
            let downloadedSize: Int64 = 11
            let mediaSize: Int64 = 12
            let videoLength: Int64 = 13
            
            it("Should init and record complete structure") {
                let event = Playback.DownloadStarted(timestamp: timeStamp, assetData: downloadId, downloadedSize: downloadedSize, mediaSize: mediaSize, videoLength: videoLength)
                
                expect(event.timestamp).to(equal(timeStamp))
                expect(event.eventType).to(equal(type))
                expect(event.assetId).to(equal("downloadAsset"))
                expect(event.downloadedSize).to(equal(downloadedSize))
                expect(event.mediaSize).to(equal(mediaSize))
                expect(event.videoLength).to(equal(videoLength))
                expect(event.bufferLimit).to(equal(3000))
            }
            
            it("Should produce correct jsonPayload") {
                let json = Playback.DownloadStarted(timestamp: timeStamp, assetData: downloadId, downloadedSize: downloadedSize, mediaSize: mediaSize, videoLength: videoLength).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["AssetId"] as? String).to(equal("downloadAsset"))
                expect(json["DownloadedSize"] as? Int64).to(equal(downloadedSize))
                expect(json["MediaSize"] as? Int64).to(equal(mediaSize))
                expect(json["VideoLength"] as? Int64).to(equal(videoLength))
                expect(json.count).to(equal(6))
            }
        }
    }
}
