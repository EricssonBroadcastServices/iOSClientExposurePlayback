//
//  BitrateChangedSpec.swift
//  AnalyticsTests
//
//  Created by Fredrik Sjöberg on 2017-12-13.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation

import Quick
import Nimble

@testable import ExposurePlayback

class BitrateChangedSpec: QuickSpec {
    override func spec() {
        describe("BitrateChanged") {
            let timeStamp: Int64 = 10
            let offset: Int64 = 10
            let type = "Playback.BitrateChanged"
            let bitrate: Int64 = 128
            
            it("Should init and record complete structure") {
                let event = Playback.BitrateChanged(timestamp: timeStamp, offsetTime: offset, bitrate: bitrate)
                
                expect(event.timestamp).to(equal(timeStamp))
                expect(event.eventType).to(equal(type))
                expect(event.offsetTime).to(equal(offset))
                expect(event.bitrate).to(equal(bitrate))
                expect(event.bufferLimit).to(equal(3000))
            }
            
            it("Should produce correct jsonPayload") {
                let json = Playback.BitrateChanged(timestamp: timeStamp, offsetTime: offset, bitrate: bitrate).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["OffsetTime"] as? Int64).to(equal(offset))
                expect(json["Bitrate"] as? Int64).to(equal(bitrate))
                expect(json.count).to(equal(4))
            }
        }
    }
}
