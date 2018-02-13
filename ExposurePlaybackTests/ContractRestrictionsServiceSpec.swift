//
//  ContractRestrictionsServiceSpec.swift
//  ExposureTests
//
//  Created by Fredrik Sjöberg on 2018-01-29.
//  Copyright © 2018 emp. All rights reserved.
//

import Quick
import Nimble
import Player
import Exposure
import Foundation

@testable import ExposurePlayback

class ContractRestrictionsServiceSpec: QuickSpec {
    override func spec() {
        super.spec()
        
        describe("ContractRestrictionsService") {
            let service = ContractRestrictionsService()
            
            context("All disabled") {
                it("should convey restrictions from entitlement") {
                    let noneEnabled = self.buildEntitlement(ffEnabled: false, rwEnabled: false, timeshiftEnabled: false)
                    
                    let ff = service.canSeek(from: 0, to: 10, using: noneEnabled)
                    let rw = service.canSeek(from: 10, to: 0, using: noneEnabled)
                    let pause = service.canPause(entitlement: noneEnabled)
                    
                    expect(ff).toNot(beNil())
                    expect(rw).toNot(beNil())
                    expect(pause).toNot(beNil())
                    
                    expect(ff?.message).to(equal("Contract restrictions disables fast forwarding"))
                    expect(rw?.message).to(equal("Contract restrictions disabled rewinding"))
                    expect(pause?.message).to(equal("Contract restrictions disabled timeshifting"))
                }
            }
            
            context("ff enabled") {
                it("should convey restrictions from entitlement") {
                    let noneEnabled = self.buildEntitlement(ffEnabled: true, rwEnabled: false, timeshiftEnabled: false)
                    
                    let ff = service.canSeek(from: 0, to: 10, using: noneEnabled)
                    let rw = service.canSeek(from: 10, to: 0, using: noneEnabled)
                    let pause = service.canPause(entitlement: noneEnabled)
                    
                    expect(ff).to(beNil())
                    expect(rw).toNot(beNil())
                    expect(pause).toNot(beNil())
                    
                    expect(rw?.message).to(equal("Contract restrictions disabled rewinding"))
                    expect(pause?.message).to(equal("Contract restrictions disabled timeshifting"))
                }
            }
            
            context("rw enabled") {
                it("should convey restrictions from entitlement") {
                    let noneEnabled = self.buildEntitlement(ffEnabled: false, rwEnabled: true, timeshiftEnabled: false)
                    
                    let ff = service.canSeek(from: 0, to: 10, using: noneEnabled)
                    let rw = service.canSeek(from: 10, to: 0, using: noneEnabled)
                    let pause = service.canPause(entitlement: noneEnabled)
                    
                    expect(ff).toNot(beNil())
                    expect(rw).to(beNil())
                    expect(pause).toNot(beNil())
                    
                    expect(ff?.message).to(equal("Contract restrictions disables fast forwarding"))
                    expect(pause?.message).to(equal("Contract restrictions disabled timeshifting"))
                }
            }
            
            context("pause enabled") {
                it("should convey restrictions from entitlement") {
                    let noneEnabled = self.buildEntitlement(ffEnabled: false, rwEnabled: false, timeshiftEnabled: true)
                    
                    let ff = service.canSeek(from: 0, to: 10, using: noneEnabled)
                    let rw = service.canSeek(from: 10, to: 0, using: noneEnabled)
                    let pause = service.canPause(entitlement: noneEnabled)
                    
                    expect(ff).toNot(beNil())
                    expect(rw).toNot(beNil())
                    expect(pause).to(beNil())
                    
                    expect(ff?.message).to(equal("Contract restrictions disables fast forwarding"))
                    expect(rw?.message).to(equal("Contract restrictions disabled rewinding"))
                }
            }
            
            context("ff and rw enabled") {
                it("should convey restrictions from entitlement") {
                    let noneEnabled = self.buildEntitlement(ffEnabled: true, rwEnabled: true, timeshiftEnabled: false)
                    
                    let ff = service.canSeek(from: 0, to: 10, using: noneEnabled)
                    let rw = service.canSeek(from: 10, to: 0, using: noneEnabled)
                    let pause = service.canPause(entitlement: noneEnabled)
                    
                    expect(ff).to(beNil())
                    expect(rw).to(beNil())
                    expect(pause).toNot(beNil())
                    
                    expect(pause?.message).to(equal("Contract restrictions disabled timeshifting"))
                }
            }
            
            context("all enabled") {
                it("should convey restrictions from entitlement") {
                    let noneEnabled = self.buildEntitlement(ffEnabled: true, rwEnabled: true, timeshiftEnabled: true)
                    
                    let ff = service.canSeek(from: 0, to: 10, using: noneEnabled)
                    let rw = service.canSeek(from: 10, to: 0, using: noneEnabled)
                    let pause = service.canPause(entitlement: noneEnabled)
                    
                    expect(ff).to(beNil())
                    expect(rw).to(beNil())
                    expect(pause).to(beNil())
                }
            }
        }
    }
    
    
    func buildEntitlement(ffEnabled: Bool = true, rwEnabled: Bool = true, timeshiftEnabled: Bool = true) -> PlaybackEntitlement {
        
        var json = PlaybackEntitlement.validJson
        json["ffEnabled"] = ffEnabled
        json["timeshiftEnabled"] = timeshiftEnabled
        json["rwEnabled"] = rwEnabled
        
        return json.decode(PlaybackEntitlement.self)!
    }
}
