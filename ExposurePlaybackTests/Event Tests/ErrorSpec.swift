//
//  ErrorSpec.swift
//  AnalyticsTests
//
//  Created by Fredrik Sjöberg on 2017-12-13.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExposurePlayback

class ErrorSpec: QuickSpec {
    override func spec() {
        describe("Error") {
            let timeStamp: Int64 = 10
            let offset: Int64 = 10
            let type = "Playback.Error"
            let code: Int = 101
            let message = "Some error"
            
            it("Should init and record complete structure") {
                let event = Playback.Error(timestamp: timeStamp, offsetTime: offset, message: message, code: code)
                
                expect(event.timestamp).to(equal(timeStamp))
                expect(event.eventType).to(equal(type))
                expect(event.offsetTime).to(equal(offset))
                expect(event.message).to(equal(message))
                expect(event.code).to(equal(code))
                expect(event.bufferLimit).to(equal(3000))
            }
            
            it("Should produce correct jsonPayload") {
                let json = Playback.Error(timestamp: timeStamp, offsetTime: offset, message: message, code: code).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["OffsetTime"] as? Int64).to(equal(offset))
                expect(json["Message"] as? String).to(equal(message))
                expect(json["Code"] as? Int).to(equal(code))
                expect(json.count).to(equal(5))
            }
        }
    }
}
