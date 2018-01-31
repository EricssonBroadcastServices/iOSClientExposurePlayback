//
//  PlayReadySpec.swift
//  AnalyticsTests
//
//  Created by Fredrik Sjöberg on 2017-12-13.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation

import Quick
import Nimble

@testable import ExposurePlayback

class PlayReadySpec: QuickSpec {
    override func spec() {
        describe("PlayReady") {
            let timeStamp: Int64 = 10
            let offset: Int64 = 10
            let type = "Playback.PlayReady"
            
            it("Should init and record complete structure") {
                let event = Playback.PlayReady(timestamp: timeStamp, offsetTime: offset)
                
                expect(event.timestamp).to(equal(timeStamp))
                expect(event.eventType).to(equal(type))
                expect(event.bufferLimit).to(equal(3000))
            }
            
            it("Should produce correct jsonPayload") {
                let json = Playback.PlayReady(timestamp: timeStamp, offsetTime: offset).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["OffsetTime"] as? Int64).to(equal(offset))
                expect(json.count).to(equal(3))
            }
        }
    }
}
