//
//  PlayableSpec.swift
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

internal class MockedAssetEntitlementProvider: AssetEntitlementProvider {
    func requestEntitlement(assetId: String, using sessionToken: SessionToken, in environment: Environment, callback: @escaping (PlaybackEntitlement?, ExposureError?, HTTPURLResponse?) -> Void) {
    }
    
    
    var mockedRequestEntitlement: (String, SessionToken, Environment, (PlaybackEntitlement?, ExposureError?, HTTPURLResponse?) -> Void) -> Void = { _,_,_,_ in }
    
    var mockedRequestEntitlementV2: (String, SessionToken, Environment, (PlaybackEntitlement?, PlayBackEntitlementV2?, ExposureError?, HTTPURLResponse?) -> Void) -> Void = { _,_,_,_ in }
    
    func requestEntitlementV2(assetId: String, using sessionToken: SessionToken, in environment: Environment, callback: @escaping (PlaybackEntitlement?, PlayBackEntitlementV2?, ExposureError?, HTTPURLResponse?) -> Void) {
  
        mockedRequestEntitlementV2(assetId, sessionToken, environment, callback)
    }

}


class AssetPlayableSpec: QuickSpec {
    
    enum MockedError: Error {
        case generalError
    }
    
    override func spec() {
        super.spec()
        
        let environment = Environment(baseUrl: "http://mocked.example.com", customer: "Customer", businessUnit: "BusinessUnit")
        let sessionToken = SessionToken(value: "token")
        describe("AssetPlayble") {
            
            it("Should prepare source with valid entitlement response") {
                let provider = MockedAssetEntitlementProvider()
                provider.mockedRequestEntitlementV2 = { _,_,_, callback in
                    // EntitlementV2
                    guard let entitlementV2 = PlayBackEntitlementV2.validJson.decode(PlayBackEntitlementV2.self) else {
                        callback(nil, nil,ExposureError.generalError(error: MockedError.generalError), nil)
                        return
                    }
                    
                    // ENtitlement V1
                    guard let entitlementV1 = PlaybackEntitlement.validJson.decode(PlaybackEntitlement.self) else {
                        callback(nil,nil,ExposureError.generalError(error: MockedError.generalError), nil)
                        return
                    }
                    callback(entitlementV1, entitlementV2, nil, nil)
                }
                
                
                let playable = AssetPlayable(assetId: "channelId", assetType: nil, entitlementProvider: provider)
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
                let provider = MockedAssetEntitlementProvider()
                provider.mockedRequestEntitlementV2 = { _,_,_, callback in
                    callback(nil,nil,ExposureError.generalError(error: MockedError.generalError), nil)
                }
                let playable = AssetPlayable(assetId: "assetId", assetType: nil, entitlementProvider: provider)
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
