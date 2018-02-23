//
//  LanguagePreferencesSpec.swift
//  ExposurePlaybackTests
//
//  Created by Fredrik Sjöberg on 2018-02-23.
//  Copyright © 2018 emp. All rights reserved.
//

import Quick
import Nimble
import AVFoundation
import Exposure

@testable import Player
@testable import ExposurePlayback

class LanguagePreferencesSpec: QuickSpec {
    
    override func spec() {
        super.spec()
        
        context("HLSNative Language Preferences") {
            let currentDate = Date().unixEpoch
            let hour: Int64 = 60 * 60 * 1000
            
            let env = Environment(baseUrl: "http://www.example.com", customer: "customer", businessUnit: "businessUnit")
            let token = SessionToken(value: "token")
            
            let options: (String, String, String) -> [MockedAVMediaSelectionOption] = {
                let sel = MockedAVMediaSelectionOption()
                sel.mockedDisplayName = $0
                sel.mockedExtendedLanguageTag = $1
                sel.mockedMediaType = $2
                
                let other = MockedAVMediaSelectionOption()
                other.mockedDisplayName = "FAKE LANG"
                other.mockedExtendedLanguageTag = "fakeLang"
                other.mockedMediaType = $2
                
                return [sel, other]
            }
            
            context("Audio") {
                context(".defaultBehavior") {
                    it("should adhere to preferred language") {
                        let env = TestEnv(environment: env, sessionToken: token)
                        
                        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour/2) { urlAsset, playerItem in
                            let audibleGroup = MockedAVMediaSelectionGroup()
                            let audibleOptions = options("Swedish", "sv", "audio")
                            audibleGroup.mockedAllowsEmptySelection = false
                            audibleGroup.mockedOptions = audibleOptions
                            audibleGroup.mockedDefaultOption = audibleOptions.first
                            
                            urlAsset.mockedMediaSelectionGroup[AVMediaCharacteristic.audible] = audibleGroup
                            
                            playerItem.mockedSelectedMediaOption[audibleGroup] = audibleOptions.first
                        })
                        
                        env.player.tech.preferredAudioLanguage = "sv"
                        
                        // Configure the playable
                        let provider = MockedProgramEntitlementProvider()
                        provider.mockedRequestEntitlement = { _,_,_,_, callback in
                            var json = PlaybackEntitlement.requiedJson
                            json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                            json["playSessionId"] = "playSessionId"
                            callback(json.decode(PlaybackEntitlement.self), nil)
                        }
                        let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                        let properties = PlaybackProperties(language: .defaultBehaviour)
                        
                        // Initiate test
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 5)
                        expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 5)
                        
                        expect(env.player.tech.selectedAudioTrack?.name).toEventually(equal("Swedish"), timeout: 5)
                        expect(env.player.tech.selectedAudioTrack?.extendedLanguageTag).toEventually(equal("sv"), timeout: 5)
                        expect(env.player.tech.selectedAudioTrack?.type).toEventually(equal("audio"), timeout: 5)
                    }
                }
                
                context(".userLocale") {
                    let locale = Locale.current.languageCode ?? "FAKE_LOCALE"
                    it("should adhere to preferred language") {
                        let env = TestEnv(environment: env, sessionToken: token)
                        
                        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour/2) { urlAsset, playerItem in
                            let audibleGroup = MockedAVMediaSelectionGroup()
                            let audibleOptions = options("DISPLAY_"+locale, locale, "audio")
                            audibleGroup.mockedAllowsEmptySelection = false
                            audibleGroup.mockedOptions = audibleOptions
                            audibleGroup.mockedDefaultOption = audibleOptions.last
                            
                            urlAsset.mockedMediaSelectionGroup[AVMediaCharacteristic.audible] = audibleGroup
                            
                            playerItem.mockedSelectedMediaOption[audibleGroup] = audibleOptions.last
                        })
                        
                        env.player.tech.preferredAudioLanguage = "sv"
                        
                        // Configure the playable
                        let provider = MockedProgramEntitlementProvider()
                        provider.mockedRequestEntitlement = { _,_,_,_, callback in
                            var json = PlaybackEntitlement.requiedJson
                            json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                            json["playSessionId"] = "playSessionId"
                            callback(json.decode(PlaybackEntitlement.self), nil)
                        }
                        let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                        let properties = PlaybackProperties(language: .userLocale)
                        
                        // Initiate test
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 5)
                        expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 5)
                        
                        expect(env.player.tech.selectedAudioTrack?.name).toEventually(equal("DISPLAY_"+locale), timeout: 5)
                        expect(env.player.tech.selectedAudioTrack?.extendedLanguageTag).toEventually(equal(locale), timeout: 5)
                        expect(env.player.tech.selectedAudioTrack?.type).toEventually(equal("audio"), timeout: 5)
                    }
                }
                
                context(".custom") {
                    it("should adhere to preferred language") {
                        let custom = "custom"
                        let env = TestEnv(environment: env, sessionToken: token)
                        
                        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour/2) { urlAsset, playerItem in
                            let audibleGroup = MockedAVMediaSelectionGroup()
                            let audibleOptions = options("DISPLAY_"+custom, custom, "audio")
                            audibleGroup.mockedAllowsEmptySelection = false
                            audibleGroup.mockedOptions = audibleOptions
                            audibleGroup.mockedDefaultOption = audibleOptions.last
                            
                            urlAsset.mockedMediaSelectionGroup[AVMediaCharacteristic.audible] = audibleGroup
                            
                            playerItem.mockedSelectedMediaOption[audibleGroup] = audibleOptions.last
                        })
                        
                        env.player.tech.preferredAudioLanguage = "sv"
                        
                        // Configure the playable
                        let provider = MockedProgramEntitlementProvider()
                        provider.mockedRequestEntitlement = { _,_,_,_, callback in
                            var json = PlaybackEntitlement.requiedJson
                            json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                            json["playSessionId"] = "playSessionId"
                            callback(json.decode(PlaybackEntitlement.self), nil)
                        }
                        let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                        let properties = PlaybackProperties(language: .custom(text: nil, audio: "custom"))
                        
                        // Initiate test
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 5)
                        expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 5)
                        
                        expect(env.player.tech.selectedAudioTrack?.name).toEventually(equal("DISPLAY_"+custom), timeout: 5)
                        expect(env.player.tech.selectedAudioTrack?.extendedLanguageTag).toEventually(equal(custom), timeout: 5)
                        expect(env.player.tech.selectedAudioTrack?.type).toEventually(equal("audio"), timeout: 5)
                    }
                }
            }
            context("Text") {
                context(".defaultBehavior") {
                    it("should adhere to preferred language") {
                        let env = TestEnv(environment: env, sessionToken: token)
                        
                        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour/2) { urlAsset, playerItem in
                            let audibleGroup = MockedAVMediaSelectionGroup()
                            let audibleOptions = options("Swedish", "sv", "subtitle")
                            audibleGroup.mockedAllowsEmptySelection = false
                            audibleGroup.mockedOptions = audibleOptions
                            audibleGroup.mockedDefaultOption = audibleOptions.first
                            
                            urlAsset.mockedMediaSelectionGroup[AVMediaCharacteristic.legible] = audibleGroup
                            
                            playerItem.mockedSelectedMediaOption[audibleGroup] = audibleOptions.first
                        })
                        
                        env.player.tech.preferredAudioLanguage = "sv"
                        
                        // Configure the playable
                        let provider = MockedProgramEntitlementProvider()
                        provider.mockedRequestEntitlement = { _,_,_,_, callback in
                            var json = PlaybackEntitlement.requiedJson
                            json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                            json["playSessionId"] = "playSessionId"
                            callback(json.decode(PlaybackEntitlement.self), nil)
                        }
                        let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                        let properties = PlaybackProperties(language: .defaultBehaviour)
                        
                        // Initiate test
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 5)
                        expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 5)
                        
                        expect(env.player.tech.selectedTextTrack?.name).toEventually(equal("Swedish"), timeout: 5)
                        expect(env.player.tech.selectedTextTrack?.extendedLanguageTag).toEventually(equal("sv"), timeout: 5)
                        expect(env.player.tech.selectedTextTrack?.type).toEventually(equal("subtitle"), timeout: 5)
                    }
                }
                
                context(".userLocale") {
                    let locale = Locale.current.languageCode ?? "FAKE_LOCALE"
                    it("should adhere to preferred language") {
                        let env = TestEnv(environment: env, sessionToken: token)
                        
                        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour/2) { urlAsset, playerItem in
                            let audibleGroup = MockedAVMediaSelectionGroup()
                            let audibleOptions = options("DISPLAY_"+locale, locale, "subtitle")
                            audibleGroup.mockedAllowsEmptySelection = false
                            audibleGroup.mockedOptions = audibleOptions
                            audibleGroup.mockedDefaultOption = audibleOptions.last
                            
                            urlAsset.mockedMediaSelectionGroup[AVMediaCharacteristic.legible] = audibleGroup
                            
                            playerItem.mockedSelectedMediaOption[audibleGroup] = audibleOptions.last
                        })
                        
                        env.player.tech.preferredAudioLanguage = "sv"
                        
                        // Configure the playable
                        let provider = MockedProgramEntitlementProvider()
                        provider.mockedRequestEntitlement = { _,_,_,_, callback in
                            var json = PlaybackEntitlement.requiedJson
                            json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                            json["playSessionId"] = "playSessionId"
                            callback(json.decode(PlaybackEntitlement.self), nil)
                        }
                        let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                        let properties = PlaybackProperties(language: .userLocale)
                        
                        // Initiate test
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 5)
                        expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 5)
                        
                        expect(env.player.tech.selectedTextTrack?.name).toEventually(equal("DISPLAY_"+locale), timeout: 5)
                        expect(env.player.tech.selectedTextTrack?.extendedLanguageTag).toEventually(equal(locale), timeout: 5)
                        expect(env.player.tech.selectedTextTrack?.type).toEventually(equal("subtitle"), timeout: 5)
                    }
                }
                
                context(".custom") {
                    let custom = "custom"
                    it("should adhere to preferred language") {
                        let env = TestEnv(environment: env, sessionToken: token)
                        
                        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour/2) { urlAsset, playerItem in
                            let audibleGroup = MockedAVMediaSelectionGroup()
                            let audibleOptions = options("DISPLAY_"+custom, custom, "subtitle")
                            audibleGroup.mockedAllowsEmptySelection = false
                            audibleGroup.mockedOptions = audibleOptions
                            audibleGroup.mockedDefaultOption = audibleOptions.last
                            
                            urlAsset.mockedMediaSelectionGroup[AVMediaCharacteristic.legible] = audibleGroup
                            
                            playerItem.mockedSelectedMediaOption[audibleGroup] = audibleOptions.last
                        })
                        
                        env.player.tech.preferredAudioLanguage = "sv"
                        
                        // Configure the playable
                        let provider = MockedProgramEntitlementProvider()
                        provider.mockedRequestEntitlement = { _,_,_,_, callback in
                            var json = PlaybackEntitlement.requiedJson
                            json["mediaLocator"] = "http://www.newPipe.com/play/.isml"
                            json["playSessionId"] = "playSessionId"
                            callback(json.decode(PlaybackEntitlement.self), nil)
                        }
                        let playable = ProgramPlayable(assetId: "program1", channelId: "channelId", entitlementProvider: provider)
                        let properties = PlaybackProperties(language: .custom(text: custom, audio: nil))
                        
                        // Initiate test
                        env.player.startPlayback(playable: playable, properties: properties)
                        
                        
                        expect(env.player.tech.currentAsset).toEventuallyNot(beNil(), timeout: 5)
                        expect(env.player.playheadTime).toEventuallyNot(beNil(), timeout: 5)
                        
                        expect(env.player.tech.selectedTextTrack?.name).toEventually(equal("DISPLAY_"+custom), timeout: 5)
                        expect(env.player.tech.selectedTextTrack?.extendedLanguageTag).toEventually(equal(custom), timeout: 5)
                        expect(env.player.tech.selectedTextTrack?.type).toEventually(equal("subtitle"), timeout: 5)
                    }
                }
            }
        }
    }
}
