//
//  ProgramServiceSpec.swift
//  ExposureTests
//
//  Created by Fredrik Sjöberg on 2018-01-22.
//  Copyright © 2018 emp. All rights reserved.
//

import Quick
import Nimble
import Player
import Exposure
import Foundation

@testable import ExposurePlayback

class MockedProgramServiceProvider: ProgramProvider {
    func program(for channelId: String, start: Int64, end: Int64, programId: String, assetId: String = "anAssetId") -> Program {
        return Program
            .validJson(programId: programId, channelId: channelId, assetId: assetId)
            .timestamp(starting: start, ending: end)
            .decode(Program.self)!
    }
    
    var fetchNumber: Int = 0
    func fetchProgram(on channelId: String, timestamp: Int64, using environment: Environment, callback: @escaping (Program?, ExposureError?) -> Void) {
        if channelId == "retryStartMonitoring" {
            callback(program(for: channelId, start: timestamp - 30*60*1000, end: timestamp + 30*60*1000, programId: "aProgramId"),nil)
        }
        else if channelId == "validationTrigger" {
            if fetchNumber == 0 {
                fetchNumber += 1
                callback(program(for: channelId, start: timestamp - 30*60*1000, end: timestamp + 1000, programId: "programId1" ,assetId: "validationTriggerFirstProgram"),nil)
            }
            else {
                callback(program(for: channelId, start: timestamp - 30*60*1000, end: timestamp + 1000, programId: "programId2", assetId: "validationTriggerSecondProgram"),nil)
            }
        }
        else if channelId == "validationTriggerNotEntitled" {
            callback(program(for: channelId, start: timestamp - 30*60*1000, end: timestamp + 1000, programId: "programId", assetId: "notEntitledProgram"),nil)
        }
        else if channelId == "noEpgChannel" {
            callback(nil, nil)
        }
        else if channelId == "errorOnProgramFetch" {
            callback(nil,ExposureError.generalError(error: MockedError.sampleError))
        }
        else if channelId == "errorOnProgramValidation" {
            if fetchNumber == 0 {
                fetchNumber += 1
                callback(program(for: channelId, start: timestamp - 30*60*1000, end: timestamp + 1000, programId: "errorOnProgramValidationFirstProgram", assetId: "errorOnProgramValidationFirstProgram"),nil)
            }
            else {
                callback(program(for: channelId, start: timestamp - 30*60*1000, end: timestamp + 1000, programId: "errorOnProgramValidationSecondProgram", assetId: "errorOnProgramValidationSecondProgram"),nil)
            }
        }
        else if channelId == "timestampWithinActiveProgram" {
            callback(program(for: channelId, start: timestamp - 30*60*1000, end: timestamp + 30*60*1000, programId: "programId", assetId: "timestampWithinActiveProgram"),nil)
        }
        else if channelId == "isEntitledNotEntitled" {
            callback(program(for: channelId, start: timestamp - 30*60*1000, end: timestamp + 60 * 1000, programId: "programId", assetId: "isEntitledNotEntitledProgram"),nil)
        }
    }
    
    func validate(entitlementFor assetId: String, environment: Environment, sessionToken: SessionToken, callback: @escaping (EntitlementValidation?, ExposureError?) -> Void) {
        if assetId == "validationTriggerSecondProgram" {
            if let result = validation(status: "SUCCESS") {
                callback(result,nil)
            }
            else {
                callback(nil, ExposureError.generalError(error: MockedError.sampleError))
            }
        }
        else if assetId == "notEntitledProgram" {
            if let result = validation(status: "NOT_ENTITLED") {
                callback(result,nil)
            }
            else {
                callback(nil, ExposureError.generalError(error: MockedError.sampleError))
            }
        }
        else if assetId == "errorOnProgramValidationSecondProgram" {
            callback(nil, ExposureError.generalError(error: MockedError.sampleError))
        }
        else if assetId == "isEntitledNotEntitledProgram" {
            if let result = validation(status: "NOT_ENTITLED") {
                callback(result,nil)
            }
            else {
                callback(nil, ExposureError.generalError(error: MockedError.sampleError))
            }
        }
        else {
            callback(nil, ExposureError.generalError(error: MockedError.sampleError))
        }
    }
    
    func validation(status: String) -> EntitlementValidation? {
        let json: [String: Codable] = [
            "status":status,
            "paymentDone":false
        ]
        
        return json.decode(EntitlementValidation.self)
    }
    
    enum MockedError: Error {
        case sampleError
    }
}


class ProgramServiceSpec: QuickSpec {
    
    override func spec() {
        super.spec()
        
        let environment = Environment(baseUrl: "someUrl", customer: "Customer", businessUnit: "BusinessUnit")
        let sessionToken = SessionToken(value: "someToken")
        
        describe("ProgramServiceSpec") {

//            it("Should retry start monitoring if no playheadTime exists") {
//                let channelId = "retryStartMonitoring"
//                var counter = 0
//                let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
//                let provider = MockedProgramServiceProvider()
//                service.provider = provider
//
//                service.currentPlayheadTime = {
//                    if counter < 1 {
//                        counter = counter + 1
//                        return nil
//                    }
//                    else {
//                        return Date().millisecondsSince1970
//                    }
//                }
//
//                var newProgram: Program? = nil
//                service.onProgramChanged = { program in
//                    newProgram = program
//                }
//
//                service.startMonitoring(epgOffset: 10 * 1000)
//
//                expect(newProgram).toEventuallyNot(beNil(), timeout: 20)
//            }

            context("Validation timer on program end timestamp") {
                it("Should continue while entitled") {
                    let channelId = "validationTrigger"
                    let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
                    let provider = MockedProgramServiceProvider()
                    service.provider = provider

                    service.currentPlayheadTime = { return Date().millisecondsSince1970 }

                    var programs: [Program] = []
                    service.onProgramChanged = { program in
                        if let program = program {
                            programs.append(program)
                        }
                    }

                    var notEntitledMessage: String? = nil
                    service.onNotEntitled = { message in
                        notEntitledMessage = message
                    }

                    service.startMonitoring(epgOffset: 0)
                    expect(service.currentProgram?.assetId).toEventually(equal("validationTriggerSecondProgram"), timeout: 5)
                    expect(notEntitledMessage).toEventually(beNil())
                    expect(programs.count).toEventually(equal(2))
                    expect(programs.last?.assetId).toEventually(equal(service.currentProgram?.assetId))
                }

                it("Should send message when not entitled") {
                    let channelId = "validationTriggerNotEntitled"
                    let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
                    let provider = MockedProgramServiceProvider()
                    service.provider = provider

                    service.currentPlayheadTime = { return Date().millisecondsSince1970 }

                    var programs: [Program] = []
                    service.onProgramChanged = { program in
                        if let program = program {
                            programs.append(program)
                        }
                    }

                    var notEntitledMessage: String? = nil
                    service.onNotEntitled = { message in
                        notEntitledMessage = message
                    }

                    service.startMonitoring(epgOffset: 0)
                    expect(service.currentProgram?.assetId).toEventually(equal("notEntitledProgram"), timeout: 1)
                    expect(notEntitledMessage).toEventually(equal("NOT_ENTITLED"), timeout: 2)
                    expect(programs.count).toEventually(equal(1))
                    expect(programs.last?.assetId).toEventually(equal(service.currentProgram?.assetId))
                }
            }

            context("Should allow playback") {
                it("if EPG is missing") {
                    let channelId = "noEpgChannel"
                    let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
                    let provider = MockedProgramServiceProvider()
                    service.provider = provider

                    service.currentPlayheadTime = { return Date().millisecondsSince1970 }

                    var newProgram: Program? = nil
                    service.onProgramChanged = { program in
                        newProgram = program
                    }

                    var notEntitledMessage: String? = nil
                    service.onNotEntitled = { message in
                        notEntitledMessage = message
                    }

                    service.startMonitoring(epgOffset: 10 * 1000)

                    expect(notEntitledMessage).toEventually(beNil(), timeout: 1)
                    expect(newProgram).toEventually(beNil(), timeout: 1)
                }

                it("if error on program fetch at startup") {
                    let channelId = "errorOnProgramFetch"
                    let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
                    let provider = MockedProgramServiceProvider()
                    service.provider = provider

                    service.currentPlayheadTime = { return Date().millisecondsSince1970 }

                    var newProgram: Program? = nil
                    service.onProgramChanged = { program in
                        newProgram = program
                    }

                    var notEntitledMessage: String? = nil
                    service.onNotEntitled = { message in
                        notEntitledMessage = message
                    }

                    service.startMonitoring(epgOffset: 10 * 1000)

                    expect(notEntitledMessage).toEventually(beNil(), timeout: 1)
                    expect(newProgram).toEventually(beNil(), timeout: 1)
                }

                it("if error on program validation") {
                    let channelId = "errorOnProgramValidation"
                    let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
                    let provider = MockedProgramServiceProvider()
                    service.provider = provider

                    service.currentPlayheadTime = { return Date().millisecondsSince1970 }

                    var programs: [Program] = []
                    service.onProgramChanged = { program in
                        if let program = program {
                            programs.append(program)
                        }
                    }

                    var notEntitledMessage: String? = nil
                    service.onNotEntitled = { message in
                        notEntitledMessage = message
                    }

                    service.startMonitoring(epgOffset: 0)

                    expect(notEntitledMessage).toEventually(beNil(), timeout: 5)
                    expect(programs.count).toEventually(equal(2), timeout: 5)
                }
            }

            context("Should not validate again") {
                it("if timestamp is within active program bounds") {
                    let channelId = "timestampWithinActiveProgram"
                    let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
                    let provider = MockedProgramServiceProvider()
                    service.provider = provider

                    service.currentPlayheadTime = { return Date().millisecondsSince1970 }

                    var programs: [Program] = []
                    service.onProgramChanged = { program in
                        if let program = program {
                            programs.append(program)
                        }
                    }

                    var notEntitledMessage: String? = nil
                    service.onNotEntitled = { message in
                        notEntitledMessage = message
                    }

                    service.startMonitoring(epgOffset: 10 * 1000)

                    var successCalled = false
                    service.isEntitled(toPlay: Date().millisecondsSince1970 + 4000) { program in
                        successCalled = true
                    }

                    expect(notEntitledMessage).toEventually(beNil(), timeout: 5)
                    expect(successCalled).toEventually(beTrue(), timeout: 5)
                    expect(programs.count).toEventually(equal(1), timeout: 5)
                }
            }

            it("Should message if isEntitled returns not entitled") {
                let channelId = "isEntitledNotEntitled"
                let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
                let provider = MockedProgramServiceProvider()
                service.provider = provider

                service.currentPlayheadTime = { return Date().millisecondsSince1970 }

                var programs: [Program] = []
                service.onProgramChanged = { program in
                    if let program = program {
                        programs.append(program)
                    }
                }

                var notEntitledMessage: String? = nil
                service.onNotEntitled = { message in
                    notEntitledMessage = message
                }

                service.startMonitoring(epgOffset: 10 * 1000)

                var successCalled = false
                service.isEntitled(toPlay: Date().millisecondsSince1970 + 120 * 1000) { program in
                    successCalled = true
                }

                expect(notEntitledMessage).toEventually(equal("NOT_ENTITLED"), timeout: 5)
                expect(successCalled).toEventually(beFalse(), timeout: 5)
                expect(programs.count).toEventually(equal(1), timeout: 5)
            }
        }
    }
}
