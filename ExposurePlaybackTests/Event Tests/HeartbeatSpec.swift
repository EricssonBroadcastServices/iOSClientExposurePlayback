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
import iOSClientExposure
import Player

@testable import ExposurePlayback

class HeartbeatSpec: QuickSpec {
    override func spec() {
        describe("Heartbeat") {
            let timeStamp: Int64 = 10
            let type = "Playback.Heartbeat"
            
            it("Should init and record complete structure") {
                let event = Playback.Heartbeat(timestamp: timeStamp, offsetTime: 10)
                
                expect(event.timestamp).to(equal(timeStamp))
                expect(event.eventType).to(equal(type))
                expect(event.offsetTime).to(equal(10))
                expect(event.bufferLimit).to(equal(3000))
            }
            
            it("Should produce correct jsonPayload") {
                let json = Playback.Heartbeat(timestamp: timeStamp, offsetTime: 10).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["OffsetTime"] as? Int64).to(equal(10))
            }
        }
    }
}
