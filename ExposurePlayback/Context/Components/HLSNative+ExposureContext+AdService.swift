//
//  HLSNative+ExposureContext+AdService.swift
//  ExposurePlayback-iOS
//
//  Created by Fredrik Sjöberg on 2018-10-02.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Player
import Exposure

extension Player where Tech == HLSNative<ExposureContext> {
    /// Sets the callback to fire once an entitlement response is received
    ///
    /// Once the callback fires, client application developers should supply a custom `AdService` if required.
    ///
    /// Upon returning the library will perform the following tasks if an `AdService` is provided:
    ///
    /// - Assign the `AdService` to the `Source`
    /// - Create and hook up the `AdPlayerProxy` so the `AdService` can interact with playback
    /// - Create and hook up the `AdServiceEventProvider` to feed the `AdService`
    /// - Optionally hook up the `AdService` provided `ContractRestrictionsService` if one is available.
    /// - If the `AdService` provides a contract restrictions service, and it has no default `ContractRestrictionsPolicy` assigned, the framework will create one based of the `Source`s `PlaybackEntitlement`
    ///
    /// - parameter callback: callback to fire once the event is fired.
    /// - returns: `Self`
    @discardableResult
    public func onAdServiceRequested(callback: @escaping (Player<Tech>, ExposureContext.Source) -> AdService?) -> Self {
        context.onAdServiceRequested = { [weak self] source in
            guard let `self` = self else { return }
            if let adService = callback(self,source) {
                source.adService = adService
                source.adService?.playerProxy = AdTechWrapper(tech: self.tech)
                
                
                /// Optionally hook up the `AdService` provided `ContractRestrictionsService` if one is available.
                if let contractRestrictionsService = adService.contractRestrictionsService {
                    source.contractRestrictionsService = AdServiceContractRestrictionsProvider(delegate: contractRestrictionsService)
                    /// If the `AdService` provides a contract restrictions service, and it has no default `ContractRestrictionsPolicy` assigned, the framework will create one based of the `Source`s `PlaybackEntitlement`
                    if source.contractRestrictionsService.contractRestrictionsPolicy == nil {
                        let policy = ContractRestrictionsPolicy()
                        policy.fastForwardEnabled = source.entitlement.ffEnabled
                        policy.rewindEnabled = source.entitlement.rwEnabled
                        policy.timeshiftEnabled = source.entitlement.timeshiftEnabled
                        source.contractRestrictionsService.contractRestrictionsPolicy = policy
                    }
                }
                
                let eventProvider = AdServiceEventProvider(adService: adService)
                source.analyticsConnector.providers.append(eventProvider)
            }
        }
        return self
    }
}

extension Player where Tech == HLSNative<ExposureContext> {
    
    /// Notify the player that an `Ad` will start playing
    /// - Parameter callback: ContractRestriction ( FF / RW enabled etc) & clickThroughUrl , adTrackingUrls if available , ad clip duration
    /// - Returns: self
    @discardableResult
    public func onWillPresentInterstitial(callback: @escaping (ContractRestrictionsService, String?, [String]?, Int64 ) -> Void) -> Self {
        context.onWillPresentInterstitial = { [weak self] contractRestrictionService, clickThroughUrl, adTrackingUrls, adClipDuration  in
            callback(contractRestrictionService, clickThroughUrl, adTrackingUrls , adClipDuration)
        }
        return self
    }
    
    
    /// Notify the player that an `Ad` did finish playing
    /// - Parameter callback: ContractRestriction ( FF / RW enabled etc)
    /// - Returns: self
    @discardableResult
    public func onDidPresentInterstitial(callback: @escaping (ContractRestrictionsService) -> Void) -> Self {
        context.onDidPresentInterstitial = { contractRestrictionService  in
            callback(contractRestrictionService)
        }
        return self
    }
    
    @discardableResult
    public func onServerSideAdShouldSkip(callback: @escaping (Int64) -> Void) -> Self {
        context.onServerSideAdShouldSkip = { skipTime  in
            callback(skipTime)
        }
        return self
    }
    
    
    @discardableResult
    public func onClipStarted(callback: @escaping (Int64, Int64) -> Void) -> Self {
        context.onClipStarted = { startTime, endTime  in
            callback(startTime, endTime)
        }
        return self
    }
    
    @discardableResult
    public func oncClipEnded(callback: @escaping (Int64, Int64) -> Void) -> Self {
        context.onClipEnded = { startTime, endTime  in
            callback(startTime, endTime)
        }
        return self
    }
    
    
    /// Player will start playing with / without Ads
    /// - Parameter callback: vodDuration, adDuration,  totalDurationInMs, adMarkerPoints
    /// - Returns: self
    @discardableResult
    public func onPlaybackStartWithAds(callback: @escaping (Int64, Int64, Int64, [MarkerPoint]) -> Void) -> Self {
        context.onPlaybackStartWithAds = { vodDuration, adDuration,  totalDurationInMs, adMarkerPoints  in
            callback(vodDuration, adDuration, totalDurationInMs, adMarkerPoints)
        }
        
        return self
    }
}


extension Player where Tech == HLSNative<ExposureContext> {
    
    
    @discardableResult
    /// Notify the player that there will be server side enabled for the current playing asset
    /// - Parameter callback: Source & Ads
    /// - Returns: self
    public func onServerSideAd(callback: @escaping (ExposureContext.Source,Ads?) -> Void) -> Self {
        context.onServerSideAd = { [weak self] source, ads in
            callback(source, ads)
        }
        return self
    }
}


extension Player where Tech == HLSNative<ExposureContext> {
    public func trackClickedAd( adTrackingUrls: [String]) {
        let group = DispatchGroup()
        
        for url in adTrackingUrls {
            group.enter()
            if let adTrackingUrl = URL(string: url) {
                let task = URLSession.shared.dataTask(with: adTrackingUrl) { data, response, error in
                    if let _ = response as? HTTPURLResponse {
                        print(" Ad tracking was success" )
                    }
                    group.leave()
                }
                task.resume()
            } else {
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            // print(" All the ad tracking beacons were sent to backend")
        }
    }
}
