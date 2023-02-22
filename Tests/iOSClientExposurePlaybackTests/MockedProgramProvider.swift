//
//  MockedProgramProvider.swift
//  ExposurePlaybackTests
//
//  Created by Fredrik Sjöberg on 2018-02-13.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import iOSClientExposure

@testable import iOSClientExposurePlayback

class MockedProgramProvider: ProgramProvider {
    public init() { }
    
    var mockedFetchProgram: (String, Int64, Environment, ([Program]?, ExposureError?) -> Void) -> Void = { _,_,_,_ in }
    func fetchPrograms(on channelId: String, timestamp: Int64, using environment: Environment, callback: @escaping ([Program]?, ExposureError?) -> Void) {
        mockedFetchProgram(channelId, timestamp, environment, callback)
    }
    
    var mockedValidate: (String, Environment, SessionToken, (EntitlementValidation?, ExposureError?) -> Void) -> Void = { _,_,_,_ in }
    func validate(entitlementFor assetId: String, environment: Environment, sessionToken: SessionToken, programStartTime: String?,callback: @escaping (EntitlementValidation?, ExposureError?) -> Void) {
        mockedValidate(assetId, environment, sessionToken, callback)
    }
    
    var mockedNextProgram: (Program, Environment, (Program?, ExposureError?) -> Void) -> Void = { _,_,_ in }
    func fetchNextProgram(on program: Program, using environment: Environment, callback: @escaping (Program?, ExposureError?) -> Void) {
        mockedNextProgram(program, environment, callback)
    }
    var mockedPreviousProgram: (Program, Environment, (Program?, ExposureError?) -> Void) -> Void = { _,_,_ in }
    func fetchPreviousProgram(on program: Program, using environment: Environment, callback: @escaping (Program?, ExposureError?) -> Void) {
        mockedPreviousProgram(program, environment, callback)
    }
}

