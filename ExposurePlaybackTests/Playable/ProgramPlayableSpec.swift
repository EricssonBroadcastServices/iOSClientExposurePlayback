//
//  ProgramPlayableSpec.swift
//  ExposurePlaybackTests
//
//  Created by Fredrik Sjöberg on 2018-02-09.
//  Copyright © 2018 emp. All rights reserved.
//

import Quick
import Nimble
import Exposure
import Foundation

@testable import ExposurePlayback

internal class MockedProgramEntitlementProvider: ProgramEntitlementProvider {
    var shouldFail = false
    func requestEntitlement(programId: String, channelId: String, using sessionToken: SessionToken, in environment: Environment, callback: @escaping (PlaybackEntitlement?, ExposureError?) -> Void) {
        if !shouldFail {
            guard let result = entitlement() else {
                callback(nil,ExposureError.generalError(error: MockedError.generalError))
                return
            }
            callback(result,nil)
        }
        else {
            callback(nil,ExposureError.generalError(error: MockedError.generalError))
        }
    }
    
    enum MockedError: Error {
        case generalError
    }
    
    func entitlement() -> PlaybackEntitlement? {
        let requiredJson:[String: Codable] = [
            "mediaLocator":"mediaLocator",
            "playTokenExpiration":"playTokenExpiration",
            "playSessionId":"playSessionId",
            "live":false,
            "ffEnabled":false,
            "timeshiftEnabled":false,
            "rwEnabled":false,
            "airplayBlocked":false,
            ]
        return requiredJson.decode(PlaybackEntitlement.self)
    }
}

internal class MockedProgramPlayable: ProgramPlayConvertible {
    var programPlayable: ProgramPlayable {
        let provider = MockedProgramEntitlementProvider()
        return ProgramPlayable(assetId: "programId", channelId: "channelId", entitlementProvider: provider)
    }
}

class ProgramPlayableSpec: QuickSpec {
    
    override func spec() {
        super.spec()
        
        let environment = Environment(baseUrl: "http://mocked.example.com", customer: "Customer", businessUnit: "BusinessUnit")
        let sessionToken = SessionToken(value: "token")
        
        describe("ProgramPlayble") {
            
            it("Should prepare source with valid entitlement response") {
                let playable = MockedProgramPlayable().programPlayable
                var source: ExposureSource? = nil
                var error: ExposureError? = nil
                playable.prepareSource(environment: environment, sessionToken: sessionToken) { src, err in
                    source = src
                    error = err
                }
                
                expect(source).toEventuallyNot(beNil())
                expect(error).toEventually(beNil())
            }
            
            it("Should fail to prepare source when encountering error") {
                let provider = MockedProgramEntitlementProvider()
                var playable = ProgramPlayable(assetId: "programId", channelId: "channelId")
                playable.entitlementProvider = provider
                provider.shouldFail = true
                var source: ExposureSource? = nil
                var error: ExposureError? = nil
                playable.prepareSource(environment: environment, sessionToken: sessionToken) { src, err in
                    source = src
                    error = err
                }
                
                expect(source).toEventually(beNil())
                expect(error).toEventuallyNot(beNil())
            }
        }
    }
}
