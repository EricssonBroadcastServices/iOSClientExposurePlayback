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
    var mockedRequestEntitlement: (String, SessionToken, Environment, (PlaybackEntitlement?, ExposureError?) -> Void) -> Void = { _,_,_,_ in }
    func requestEntitlement(channelId: String, using sessionToken: SessionToken, in environment: Environment, callback: @escaping (PlaybackEntitlement?, ExposureError?) -> Void) {
        mockedRequestEntitlement(channelId, sessionToken, environment, callback)
    }
}


class ChannelPlayableSpec: QuickSpec {
    
    enum MockedError: Error {
        case generalError
    }
    
    override func spec() {
        super.spec()
        
        let environment = Environment(baseUrl: "http://mocked.example.com", customer: "Customer", businessUnit: "BusinessUnit")
        let sessionToken = SessionToken(value: "token")
        
        describe("ChannelPlayble") {
            
            it("Should prepare source with valid entitlement response") {
                let provider = MockedChannelEntitlementProvider()
                provider.mockedRequestEntitlement = { _,_,_, callback in
                    guard let result = PlaybackEntitlement.validJson.decode(PlaybackEntitlement.self) else {
                        callback(nil,ExposureError.generalError(error: MockedError.generalError))
                        return
                    }
                    callback(result,nil)
                }
                let playable = ChannelPlayable(assetId: "channelId", entitlementProvider: provider)
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
                provider.mockedRequestEntitlement = { _,_,_, callback in
                    callback(nil,ExposureError.generalError(error: MockedError.generalError))
                }
                let playable = ChannelPlayable(assetId: "channelId", entitlementProvider: provider)
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
