//
//  ChannelPlayableSpec.swift
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

internal class MockedChannelEntitlementProvider: ChannelEntitlementProvider {
    var shouldFail = false
    func requestEntitlement(channelId: String, using sessionToken: SessionToken, in environment: Environment, callback: @escaping (PlaybackEntitlement?, ExposureError?) -> Void) {
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

internal class MockedChannelPlayable: ChannelPlayConvertible {
    var channelPlayable: ChannelPlayable {
        let provider = MockedChannelEntitlementProvider()
        return ChannelPlayable(assetId: "channelId", entitlementProvider: provider)
    }
}

class ChannelPlayableSpec: QuickSpec {
    
    override func spec() {
        super.spec()
        
        let environment = Environment(baseUrl: "http://mocked.example.com", customer: "Customer", businessUnit: "BusinessUnit")
        let sessionToken = SessionToken(value: "token")
        
        describe("ChannelPlayble") {
            
            it("Should prepare source with valid entitlement response") {
                let playable = MockedChannelPlayable().channelPlayable
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
                let provider = MockedChannelEntitlementProvider()
                var playable = ChannelPlayable(assetId: "channelId")
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
