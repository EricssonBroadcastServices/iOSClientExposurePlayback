//
//  AbortedSpec.swift
//  AnalyticsTests
//
//  Created by Fredrik Sjöberg on 2017-12-13.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation

import Quick
import Nimble

@testable import ExposurePlayback

class AbortedSpec: QuickSpec {
    override func spec() {
        describe("Aborted") {
            let timeStamp: Int64 = 10
            let offset: Int64 = 10
            let type = "Playback.Aborted"
            
            it("Should init and record complete structure") {
                let event = Playback.Aborted(timestamp: timeStamp, offsetTime: offset)
                
                expect(event.timestamp).to(equal(timeStamp))
                expect(event.eventType).to(equal(type))
                expect(event.offsetTime).to(equal(offset))
                expect(event.bufferLimit).to(equal(3000))
            }
            
            it("Should produce correct jsonPayload") {
                let json = Playback.Aborted(timestamp: timeStamp, offsetTime: offset).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["OffsetTime"] as? Int64).to(equal(offset))
                expect(json.count).to(equal(3))
            }
        }
    }
}
