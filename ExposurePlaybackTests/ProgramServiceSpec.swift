//
//  ProgramServiceSpec.swift
//  ExposureTests
//
//  Created by Fredrik Sjöberg on 2018-01-22.
//  Copyright © 2018 emp. All rights reserved.
//

import Quick
import Nimble
import Exposure
import Foundation

@testable import Player
@testable import ExposurePlayback


class ProgramServiceSpec: QuickSpec {
    
    enum MockedError: Error {
        case sampleError
    }
    
    override func spec() {
        super.spec()
        
        let currentDate = Date().unixEpoch
        let second: Int64 = 1 * 1000
        let hour: Int64 = 60 * 60 * 1000
        
        let environment = Environment(baseUrl: "someUrl", customer: "Customer", businessUnit: "BusinessUnit")
        let sessionToken = SessionToken(value: "someToken")
        
        describe("ProgramServiceSpec") {

            context("Validation timer on program end timestamp") {
                it("Should continue while entitled") {
                    let channelId = "validationTrigger"
                    let provider = MockedProgramProvider()
                    provider.mockedFetchProgram = { _,timestamp,_, callback in
                        if timestamp > currentDate {
                            let program = Program
                                .validJson(programId: "program1", channelId: channelId, assetId: "validationTriggerSecondProgram")
                                .timestamp(starting: currentDate+second, ending: currentDate+hour)
                                .decode(Program.self)
                            callback(program,nil)
                        }
                        else {
                            let program = Program
                                .validJson(programId: "program1", channelId: channelId, assetId: "validationTriggerFirstProgram")
                                .timestamp(starting: currentDate, ending: currentDate+second)
                                .decode(Program.self)
                            callback(program,nil)
                        }
                    }
                    provider.mockedValidate = { programId, _,_, callback in
                        callback(EntitlementValidation.validJson(status: "SUCCESS").decode(EntitlementValidation.self),nil)
                    }
                    let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
                    service.provider = provider

                    var first = true
                    service.currentPlayheadTime = {
                        if first {
                            first = false
                            return currentDate
                        }
                        else {
                            return currentDate + second
                        }
                    }
                    service.isPlaying = { return true }

                    service.startMonitoring(epgOffset: 0)
                    expect(service.currentProgram?.assetId).toEventually(equal("validationTriggerSecondProgram"), timeout: 5)
                }

                it("Should send message when not entitled") {
                    let channelId = "validationTriggerNotEntitled"
                    let provider = MockedProgramProvider()
                    provider.mockedFetchProgram = { _,timestamp,_, callback in
                        if timestamp > currentDate {
                            let program = Program
                                .validJson(programId: "program1", channelId: channelId, assetId: "validationTriggerNotEntitledSecondProgram")
                                .timestamp(starting: currentDate+second, ending: currentDate+hour)
                                .decode(Program.self)
                            callback(program,nil)
                        }
                        else {
                            let program = Program
                                .validJson(programId: "program1", channelId: channelId, assetId: "validationTriggerNotEntitledFirstProgram")
                                .timestamp(starting: currentDate, ending: currentDate+second)
                                .decode(Program.self)
                            callback(program,nil)
                        }
                    }
                    provider.mockedValidate = { programId, _,_, callback in
                        if programId == "validationTriggerNotEntitledFirstProgram" {
                            callback(EntitlementValidation.validJson(status: "SUCCESS").decode(EntitlementValidation.self),nil)
                        }
                        else {
                            callback(EntitlementValidation.validJson(status: "NOT_ENTITLED").decode(EntitlementValidation.self),nil)
                        }
                    }
                    let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
                    service.provider = provider

                    var first = true
                    service.currentPlayheadTime = {
                        if first {
                            first = false
                            return currentDate
                        }
                        else {
                            return currentDate + second
                        }
                    }
                    service.isPlaying = { return true }

                    var notEntitledMessage: String? = nil
                    service.onNotEntitled = { message in
                        notEntitledMessage = message
                    }

                    service.startMonitoring(epgOffset: 0)
                    expect(service.currentProgram?.assetId).toEventually(equal("validationTriggerNotEntitledSecondProgram"), timeout: 1)
                    expect(notEntitledMessage).toEventually(equal("NOT_ENTITLED"), timeout: 2)
                }
            }

            context("Should allow playback") {
                it("if EPG is missing") {
                    let channelId = "noEpgChannel"
                    let provider = MockedProgramProvider()
                    provider.mockedFetchProgram = { _,timestamp,_, callback in
                        callback(nil,nil)
                    }
                    let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
                    service.provider = provider

                    service.currentPlayheadTime = { return currentDate }
                    service.isPlaying = { return true }

                    var warningMessage: ExposureContext.Warning.ProgramService? = nil
                    service.onWarning = { warning in
                        warningMessage = warning
                    }

                    service.startMonitoring(epgOffset: 10 * 1000)
                    expect(warningMessage?.message).toEventually(contain("Program Service encountered a gap in the Epg at timestamp"), timeout: 5)
                }

                it("if error on program fetch at startup") {
                    let channelId = "errorOnProgramFetch"
                    let provider = MockedProgramProvider()
                    provider.mockedFetchProgram = { _,timestamp,_, callback in
                        callback(nil,ExposureError.generalError(error: MockedError.sampleError))
                    }
                    let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
                    service.provider = provider

                    service.currentPlayheadTime = { return currentDate }
                    service.isPlaying = { return true }

                    var warningMessage: ExposureContext.Warning.ProgramService? = nil
                    service.onWarning = { warning in
                        warningMessage = warning
                    }

                    service.startMonitoring(epgOffset: 10 * 1000)
                    expect(warningMessage?.message).toEventually(contain("Program Service failed to fetch the current program at timestamp"), timeout: 5)
                }

                it("if error on program validation") {
                    let channelId = "errorOnProgramValidation"
                    let provider = MockedProgramProvider()
                    provider.mockedFetchProgram = { _,timestamp,_, callback in
                        let program = Program
                            .validJson(programId: "program1", channelId: channelId, assetId: "errorOnProgramValidation")
                            .timestamp(starting: currentDate, ending: currentDate+second)
                            .decode(Program.self)
                        callback(program,nil)
                    }
                    provider.mockedValidate = { _,_,_, callback in
                        callback(nil,ExposureError.generalError(error: MockedError.sampleError))
                    }
                    let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
                    service.provider = provider

                    service.currentPlayheadTime = { return currentDate }
                    service.isPlaying = { return true }

                    var warningMessage: ExposureContext.Warning.ProgramService? = nil
                    service.onWarning = { warning in
                        warningMessage = warning
                    }

                    service.startMonitoring(epgOffset: 0)
                    expect(warningMessage?.message).toEventually(contain("Program Service failed to validate program"), timeout: 5)
                }
            }

            context("Should not validate again") {
                it("if timestamp is within active program bounds") {
                    let channelId = "timestampWithinActiveProgram"
                    let provider = MockedProgramProvider()
                    provider.mockedFetchProgram = { _,timestamp,_, callback in
                        let program = Program
                            .validJson(programId: "program1", channelId: channelId, assetId: "timestampWithinActiveProgram")
                            .timestamp(starting: currentDate - hour, ending: currentDate+second)
                            .decode(Program.self)
                        callback(program,nil)
                    }
                    provider.mockedValidate = { _,_,_, callback in
                        callback(nil,ExposureError.generalError(error: MockedError.sampleError))
                    }
                    let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
                    service.provider = provider
                    
                    service.currentPlayheadTime = { return currentDate }
                    service.isPlaying = { return true }

                    var programs: [Program] = []
                    service.onProgramChanged = { program in
                        if let program = program {
                            print(program.assetId)
                            programs.append(program)
                        }
                    }

                    var notEntitledMessage: String? = nil
                    service.onNotEntitled = { message in
                        notEntitledMessage = message
                    }

                    service.startMonitoring(epgOffset: 0)

                    
                    var successCalled = false
                    service.isEntitled(toPlay: currentDate) { program in
                        service.isEntitled(toPlay: currentDate) { program in
                            // Trigger another check after currentProgram has been set
                            successCalled = true
                        }
                    }

                    expect(successCalled).toEventually(beTrue(), timeout: 5)
                    expect(notEntitledMessage).toEventually(beNil(), timeout: 5)
                    expect(programs.count).toEventually(equal(1), timeout: 5)
                    expect(service.currentProgram?.assetId).toEventually(equal("timestampWithinActiveProgram"), timeout: 5)
                }
            }

            it("Should message if isEntitled returns not entitled") {
                let channelId = "isEntitledNotEntitled"
                let provider = MockedProgramProvider()
                provider.mockedFetchProgram = { _,timestamp,_, callback in
                    let program = Program
                        .validJson(programId: "program1", channelId: channelId, assetId: "isEntitledNotEntitled")
                        .timestamp(starting: currentDate, ending: currentDate+second)
                        .decode(Program.self)
                    callback(program,nil)
                }
                provider.mockedValidate = { _,_,_, callback in
                    callback(EntitlementValidation.validJson(status: "NOT_ENTITLED").decode(EntitlementValidation.self),nil)
                }
                let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
                service.provider = provider

                service.currentPlayheadTime = { return currentDate }
                service.isPlaying = { return true }

                var notEntitledMessage: String? = nil
                service.onNotEntitled = { message in
                    notEntitledMessage = message
                }

                service.startMonitoring(epgOffset: 10 * 1000)

                var successCalled = false
                service.isEntitled(toPlay: currentDate) { program in
                    successCalled = true
                }


                expect(notEntitledMessage).toEventually(equal("NOT_ENTITLED"), timeout: 5)
                expect(successCalled).toEventually(beFalse(), timeout: 5)
            }
        }
    }
}
