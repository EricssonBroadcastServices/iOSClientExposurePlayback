//
//  SeekToTimeProvider.swift
//  ExposurePlaybackTests
//
//  Created by Fredrik Sjöberg on 2018-02-13.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Exposure

@testable import ExposurePlayback

class SeekToTimeProgramProvider: ProgramProvider {
    public init() { }
    
    var mockedFetchProgram: (String, Int64, Environment, (Program?, ExposureError?) -> Void) -> Void = { _,_,_,_ in }
    func fetchProgram(on channelId: String, timestamp: Int64, using environment: Environment, callback: @escaping (Program?, ExposureError?) -> Void) {
        mockedFetchProgram(channelId, timestamp, environment, callback)
    }
    
    var mockedValidate: (String, Environment, SessionToken, (EntitlementValidation?, ExposureError?) -> Void) -> Void = { _,_,_,_ in }
    func validate(entitlementFor assetId: String, environment: Environment, sessionToken: SessionToken, callback: @escaping (EntitlementValidation?, ExposureError?) -> Void) {
        mockedValidate(assetId, environment, sessionToken, callback)
    }
}
