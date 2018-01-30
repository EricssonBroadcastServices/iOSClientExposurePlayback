//
//  ExposureStreamFairplayRequester.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-10-02.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import AVFoundation
import Player

/// *Exposure* specific implementation of the `FairplayRequester` protocol for streaming purposes.
///
/// This class handles any *Exposure* related `DRM` validation with regards to *Fairplay*. It is designed to be *plug-and-play* and should require no configuration to use.
internal class ExposureStreamFairplayRequester: NSObject, ExposureFairplayRequester, FairplayRequester {
    
    init(entitlement: PlaybackEntitlement) {
        self.entitlement = entitlement
    }
    
    internal let entitlement: PlaybackEntitlement
    internal let resourceLoadingRequestQueue = DispatchQueue(label: "com.emp.exposure.streaming.fairplay.requests")
    internal let customScheme = "skd"
    internal let resourceLoadingRequestOptions: [String : AnyObject]? = nil
    
    internal func onSuccessfulRetrieval(of ckc: Data, for resourceLoadingRequest: AVAssetResourceLoadingRequest) throws -> Data {
        return ckc
    }
    
    /// Streaming requests normally always contact the remote for license and certificates.
    internal func shouldContactRemote(for resourceLoadingRequest: AVAssetResourceLoadingRequest) throws -> Bool {
        return true
    }
}

// MARK: - AVAssetResourceLoaderDelegate
extension ExposureStreamFairplayRequester {
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        return canHandle(resourceLoadingRequest: loadingRequest)
    }
    
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
        return canHandle(resourceLoadingRequest: renewalRequest)
    }
}
