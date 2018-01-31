//
//  HeartbeatSpec.swift
//  AnalyticsTests
//
//  Created by Fredrik Sjöberg on 2017-12-13.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation

import Quick
import Nimble
import Exposure
import Player

@testable import ExposurePlayback

class HeartbeatSpec: QuickSpec {
    override func spec() {
        describe("Heartbeat") {
            let timeStamp: Int64 = 10
            let type = "Playback.Heartbeat"
            let data = ["Some":10]
            
            it("Should init and record complete structure") {
                let event = Playback.Heartbeat(timestamp: timeStamp, data: data)
                
                expect(event.timestamp).to(equal(timeStamp))
                expect(event.eventType).to(equal(type))
                let recorded = event.data as? [String: Int]
                expect(recorded).to(equal(data))
                expect(event.bufferLimit).to(equal(3000))
            }
            
            it("Should produce correct jsonPayload") {
                let json = Playback.Heartbeat(timestamp: timeStamp, data: data).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["Some"] as? Int).to(equal(10))
            }
            
            let assetId = "assetId"
            let sessionToken = SessionToken(value: "token")
            let environment = Environment(baseUrl: "anUrl", customer: "customer", businessUnit: "businessUnit")
            
            it("Should deliver correct metaData for DownloadTasks") {
                let downloadTask = SessionManager<ExposureDownloadTask>().download(assetId: assetId, using: sessionToken, in: environment)
                let heartBeat = downloadTask.requestHeatbeat()
                let payload = heartBeat.payload
                expect(payload.count).to(equal(0))
            }
            
            it("Should deliver correct metaData for HLSNative") {
                let player = Player<HLSNative<ExposureContext>>(environment: environment, sessionToken: sessionToken, analytics: ExposureAnalytics.self)
                let heartbeat = player.tech.requestHeatbeat()
                expect(heartbeat.payload.count).to(equal(1))
                expect(heartbeat.payload["OffsetTime"] as? Int64).to(equal(0))
            }
        }
    }
}
