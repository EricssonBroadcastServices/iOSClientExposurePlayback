//
//  HLSNative+ExposureContext+Timeshift.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-10.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Player

// MARK: - Timeshift
extension Player where Tech == HLSNative<ExposureContext> {
    public func pause() {
        guard let source = tech.currentSource else { return }
        guard context.contractRestrictionsService.canPause(entitlement: source.entitlement) else { return }
        tech.pause()
    }
    
    #if DEBUG
    /// Specifies the timeshift delay *in seconds* associated with the current `MediaSource` (if available).
    ///
    /// - note: Requires a *Unified Packager* sourced stream.
    public var timeshiftDelay: Int64? {
        return tech.currentSource?.timeshiftDelay
    }
    
    public var dvrWindowLength: Int64? {
        return tech.currentSource?.dvrWindowLength
    }
    #endif
    
    public var tParameter: (Int64, Int64?)? {
        return tech.currentSource?.tParameter
    }
}
