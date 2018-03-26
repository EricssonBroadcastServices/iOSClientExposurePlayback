//
//  HLSNative+ExposureContext+Entitlements.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-02-07.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Player
import Exposure

extension Player where Tech == HLSNative<ExposureContext> {
    // MARK: Entitlement Response
    
    /// Sets the callback to fire once an entitlement response is received
    ///
    /// - parameter callback: callback to fire once the event is fired.
    /// - returns: `Self`
    @discardableResult
    public func onEntitlementResponse(callback: @escaping (Player<Tech>, ExposureContext.Source, PlaybackEntitlement) -> Void) -> Self {
        context.onEntitlementResponse = { [weak self] entitlement, source in
            guard let `self` = self else { return }
            callback(self,source,entitlement)
        }
        return self
    }
}
