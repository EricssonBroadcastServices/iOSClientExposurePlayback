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
            
            context("All disabled") {
                it("should convey restrictions from entitlement") {
                    let entitlement = self.buildEntitlement(ffEnabled: false, rwEnabled: false, timeshiftEnabled: false)
                    
                    let service = BasicContractRestrictions(entitlement: entitlement)
                    let ff = service.canSeek(fromPosition: 0, toPosition: 10)
                    let rw = service.canSeek(fromPosition: 10, toPosition: 0)
                    let pause = service.canPause(at: 10)
                    
                    expect(ff).to(equal(false))
                    expect(rw).to(equal(false))
                    expect(pause).to(equal(false))
                }
            }
            
            context("ff enabled") {
                it("should convey restrictions from entitlement") {
                    let entitlement = self.buildEntitlement(ffEnabled: true, rwEnabled: false, timeshiftEnabled: false)
                    let service = BasicContractRestrictions(entitlement: entitlement)
                    
                    let ff = service.canSeek(fromPosition: 0, toPosition: 10)
                    let rw = service.canSeek(fromPosition: 10, toPosition: 0)
                    let pause = service.canPause(at: 10)
                    
                    expect(ff).to(equal(true))
                    expect(rw).to(equal(false))
                    expect(pause).to(equal(false))
                }
            }
            
            context("rw enabled") {
                it("should convey restrictions from entitlement") {
                    let entitlement = self.buildEntitlement(ffEnabled: false, rwEnabled: true, timeshiftEnabled: false)
                    let service = BasicContractRestrictions(entitlement: entitlement)
                    
                    let ff = service.canSeek(fromPosition: 0, toPosition: 10)
                    let rw = service.canSeek(fromPosition: 10, toPosition: 0)
                    let pause = service.canPause(at: 10)
                    
                    expect(ff).to(equal(false))
                    expect(rw).to(equal(true))
                    expect(pause).to(equal(false))
                }
            }
            
            context("pause enabled") {
                it("should convey restrictions from entitlement") {
                    let entitlement = self.buildEntitlement(ffEnabled: false, rwEnabled: false, timeshiftEnabled: true)
                    
                    let service = BasicContractRestrictions(entitlement: entitlement)
                    
                    let ff = service.canSeek(fromPosition: 0, toPosition: 10)
                    let rw = service.canSeek(fromPosition: 10, toPosition: 0)
                    let pause = service.canPause(at: 10)
                    
                    expect(ff).to(equal(false))
                    expect(rw).to(equal(false))
                    expect(pause).to(equal(true))
                }
            }
            
            context("ff and rw enabled") {
                it("should convey restrictions from entitlement") {
                    let entitlement = self.buildEntitlement(ffEnabled: true, rwEnabled: true, timeshiftEnabled: false)
                    
                    let service = BasicContractRestrictions(entitlement: entitlement)
                    
                    let ff = service.canSeek(fromPosition: 0, toPosition: 10)
                    let rw = service.canSeek(fromPosition: 10, toPosition: 0)
                    let pause = service.canPause(at: 10)
                    
                    expect(ff).to(equal(true))
                    expect(rw).to(equal(true))
                    expect(pause).to(equal(false))
                }
            }
            
            context("all enabled") {
                it("should convey restrictions from entitlement") {
                    let entitlement = self.buildEntitlement(ffEnabled: true, rwEnabled: true, timeshiftEnabled: true)
                    
                    let service = BasicContractRestrictions(entitlement: entitlement)
                    
                    let ff = service.canSeek(fromPosition: 0, toPosition: 10)
                    let rw = service.canSeek(fromPosition: 10, toPosition: 0)
                    let pause = service.canPause(at: 10)
                    
                    expect(ff).to(equal(true))
                    expect(rw).to(equal(true))
                    expect(pause).to(equal(true))
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
