//
//  ProgramChangedSpec.swift
//  AnalyticsTests
//
//  Created by Fredrik Sjöberg on 2017-12-13.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExposurePlayback

class ProgramChangedSpec: QuickSpec {
    override func spec() {
        describe("ProgramChanged") {
            let timeStamp: Int64 = 10
            let offset: Int64 = 10
            let type = "Playback.ProgramChanged"
            let programId = "programAsset"
            let videoLength: Int64 = 10
            
            it("Should init and record complete structure") {
                let event = Playback.ProgramChanged(timestamp: timeStamp, offsetTime: offset, programId: programId, videoLength: videoLength)
                
                expect(event.timestamp).to(equal(timeStamp))
                expect(event.eventType).to(equal(type))
                expect(event.offsetTime).to(equal(offset))
                expect(event.programId).to(equal(programId))
                expect(event.videoLength).to(equal(videoLength))
                expect(event.bufferLimit).to(equal(3000))
            }
            
            it("Should produce correct jsonPayload") {
                let json = Playback.ProgramChanged(timestamp: timeStamp, offsetTime: offset, programId: programId, videoLength: videoLength).jsonPayload
                
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["OffsetTime"] as? Int64).to(equal(offset))
                expect(json["ProgramId"] as? String).to(equal(programId))
                expect(json["VideoLength"] as? Int64).to(equal(videoLength))
                expect(json.count).to(equal(5))
            }
        }
    }
}
