//
//  HLSNative+ExposureContext+AdService.swift
//  ExposurePlayback-iOS
//
//  Created by Fredrik Sjöberg on 2018-10-02.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Player

extension Player where Tech == HLSNative<ExposureContext> {
    // MARK: Entitlement Response
    
    /// Sets the callback to fire once an entitlement response is received
    ///
    /// - parameter callback: callback to fire once the event is fired.
    /// - returns: `Self`
    @discardableResult
    public func onAdServiceRequested(callback: @escaping (Player<Tech>, ExposureContext.Source) -> AdService?) -> Self {
        context.onAdServiceRequested = { [weak self] source in
            guard let `self` = self else { return }
            if let adService = callback(self,source) {
                source.adService = adService
                
                let eventProvider = AdServiceEventProvider(adService: adService)
                source.analyticsConnector.providers.append(eventProvider)
            }
        }
        return self
    }
}
