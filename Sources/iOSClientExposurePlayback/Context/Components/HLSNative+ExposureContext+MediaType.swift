//
//  HLSNative+ExposureContext+MediaType.swift
//  ExposurePlayback
//
//  Created by Udaya Sri Senarathne on 2022-01-11.
//  Copyright © 2022 emp. All rights reserved.
//

import Foundation
import iOSClientPlayer


extension Player where Tech == HLSNative<ExposureContext> {
    // MARK: Media Type
    
    /// Sets the callback to fire asset's mediaType once an entitlement response is received
    ///
    /// - parameter callback: callback to fire once the event is fired.
    /// - returns: `Self`
    @discardableResult
    public func onMediaType(callback: @escaping (MediaType) -> Void) -> Self {
        context.onMediaType = { [weak self] mediaType in
            guard let `self` = self else { return }
            callback(mediaType)
        }
        return self
    }
}
