//
//  DeviceInfoSpec.swift
//  AnalyticsTests
//
//  Created by Fredrik Sjöberg on 2017-12-12.
//  Copyright © 2017 emp. All rights reserved.
//

import Quick
import Nimble

@testable import ExposurePlayback

class DeviceInfoSpec: QuickSpec {
    override func spec() {
        describe("DeviceInfo") {
            let timeStamp: Int64 = 10
            let type = "Device.Info"
            let simulatorModel = "x86_64"
            let os = "iOS"
            let manufacturer = "Apple"
            let event = DeviceInfo(timestamp: timeStamp)
            
            it("Should init with correct data") {
                expect(event.timestamp).to(equal(timeStamp))
                expect(event.eventType).to(equal(type))
                expect(event.deviceId).to(equal(UIDevice.current.identifierForVendor!.uuidString))
                expect(event.deviceModel).to(equal(simulatorModel))
                expect(event.cpuType).to(beNil())
                expect(event.os).to(equal(os))
                expect(event.osVersion).to(equal(UIDevice.current.systemVersion))
                expect(event.manufacturer).to(equal(manufacturer))
                expect(event.bufferLimit).to(equal(3000))
            }
            
            it("Should produce correct jsonPayload") {
                let json = event.jsonPayload
                expect(json["Timestamp"] as? Int64).to(equal(timeStamp))
                expect(json["EventType"] as? String).to(equal(type))
                expect(json["DeviceId"] as? String).to(equal(UIDevice.current.identifierForVendor!.uuidString))
                expect(json["DeviceModel"] as? String).to(equal(simulatorModel))
                expect(json["CPUType"] as? String).to(beNil())
                expect(json["OS"] as? String).to(equal(os))
                expect(json["OSVersion"] as? String).to(equal(UIDevice.current.systemVersion))
                expect(json["Manufacturer"] as? String).to(equal(manufacturer))
                expect(json.count).to(equal(7))
            }
            
        }
    }
}

