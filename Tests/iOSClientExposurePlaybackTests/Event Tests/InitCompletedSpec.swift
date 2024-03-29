//
//  InitCompletedSpec.swift
//  AnalyticsTests
//
//  Created by Fredrik Sjöberg on 2017-12-13.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation

import Quick
import Nimble

@testable import iOSClientExposurePlayback

class InitCompletedSpec: QuickSpec {
    override func spec() {
        describe("InitCompleted") {
            let timeStamp: Int64 = 10
            let type = "Playback.InitCompleted"
            
            it("Should init and record complete structure") {
                let event = Playback.InitCompleted(timestamp: timeStamp)
                
                expect(event.timestamp).to(equal(timeStamp))
                expect(event.eventType).to(equal(type))
                expect(event.bufferLimit).to(equal(3000))
            }
            
            it("Should produce correct jsonPayload") {
                let json = Playback.InitCompleted(timestamp: timeStamp).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json.count).to(equal(4))
            }
        }
    }
}
