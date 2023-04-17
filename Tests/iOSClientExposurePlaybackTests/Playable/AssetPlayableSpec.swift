//
//  PlayableSpec.swift
//  ExposurePlaybackTests
//
//  Created by Fredrik Sjöberg on 2018-02-09.
//  Copyright © 2018 emp. All rights reserved.
//

import Quick
import Nimble
import iOSClientExposure
import Foundation

@testable import iOSClientExposurePlayback

internal class MockedAssetEntitlementProvider: AssetEntitlementProvider {

    var mockedRequestEntitlement: (String, SessionToken, Environment, AdsOptions?, String?, String?, [String:Any]?, String?, String?, (PlaybackEntitlement?, ExposureError?, HTTPURLResponse?) -> Void) -> Void = { _,_,_,_,_,_,_,_,_,_   in }
    
    var mockedRequestEntitlementV2: (String, SessionToken, Environment, AdsOptions?, String?, String?, [String:Any]?, String?, String?, (PlaybackEntitlement?, PlayBackEntitlementV2?, ExposureError?, HTTPURLResponse?) -> Void) -> Void = { _,_,_,_,_,_,_,_,_,_   in }
    
    func requestEntitlement(assetId: String, using sessionToken: SessionToken, in environment: Environment, include adsOptions: AdsOptions?, adobePrimetimeMediaToken: String?, materialProfile: String?, customAdParams: [String: Any]?, deviceMake:String?, deviceModel: String?, callback: @escaping (PlaybackEntitlement?, ExposureError?, HTTPURLResponse?) -> Void) {
        mockedRequestEntitlement(assetId, sessionToken, environment,adsOptions, adobePrimetimeMediaToken, materialProfile, customAdParams, deviceMake, deviceModel, callback)
    }
    
    func requestEntitlementV2(assetId: String, using sessionToken: SessionToken, in environment: Environment, include adsOptions: AdsOptions?, adobePrimetimeMediaToken: String?, materialProfile:String?, customAdParams: [String: Any]?, deviceMake:String?, deviceModel: String?, callback: @escaping (PlaybackEntitlement?, PlayBackEntitlementV2?, ExposureError?, HTTPURLResponse?) -> Void) {
  
        mockedRequestEntitlementV2(assetId, sessionToken, environment,adsOptions, adobePrimetimeMediaToken, materialProfile, customAdParams, deviceMake, deviceModel, callback)
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
        let adobePrimetimeMediaToken = "adobePrimetimeMediaToken: String?"
        let materialProfile = "TRAILER"
        let customAdParams: [String: Any] = ["TestKey": 1 , "TestKey2": "test", "TestKey3": true]
        
        describe("AssetPlayble") {
            
            it("Should prepare source with valid entitlement response") {
                let provider = MockedAssetEntitlementProvider()
                provider.mockedRequestEntitlementV2 = { _,_,_,_,_,_,_,_,_ callback in
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
                playable.prepareSource(environment: environment, sessionToken: sessionToken, adsOptions: nil, adobePrimetimeMediaToken: adobePrimetimeMediaToken, materialProfile: materialProfile, customAdParams: customAdParams, metadataIdentifiers: nil, deviceMake: nil, deviceModel: nil) { src, err in
                    source = src
                    error = err
                }
                
                expect(source).toEventuallyNot(beNil())
                expect(error).toEventually(beNil())
            }
            
            it("Should fail to prepare source when encountering error") {
                let provider = MockedAssetEntitlementProvider()
                provider.mockedRequestEntitlementV2 = { _,_,_,_,_,_,_,_,_ callback in
                    callback(nil,nil,ExposureError.generalError(error: MockedError.generalError), nil)
                }
                let playable = AssetPlayable(assetId: "assetId", assetType: nil, entitlementProvider: provider)
                var source: ExposureSource? = nil
                var error: ExposureError? = nil
                playable.prepareSource(environment: environment, sessionToken: sessionToken, adsOptions: nil, adobePrimetimeMediaToken: adobePrimetimeMediaToken, materialProfile: materialProfile, customAdParams: customAdParams, metadataIdentifiers: nil, deviceMake: nil, deviceModel: nil) { src, err in
                    source = src
                    error = err
                }
                
                expect(source).toEventually(beNil())
                expect(error).toEventuallyNot(beNil())
            }
        }
    }
}
