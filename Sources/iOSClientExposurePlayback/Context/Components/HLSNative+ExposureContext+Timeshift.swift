//
//  HLSNative+ExposureContext+Timeshift.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-10.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import iOSClientPlayer

extension Player where Tech == HLSNative<ExposureContext> {
    // MARK: Timeshift
    
    /// Pause playback if currently active
    ///
    /// - note: Will perform a check against contract restrictions to decide if pausing is allowed or not.
    public func pause() {
        guard let source = tech.currentSource else { return }
        guard source.contractRestrictionsService.canPause(at: tech.playheadPosition) else {
            let warning = PlayerWarning<HLSNative<ExposureContext>,ExposureContext>.context(warning: ExposureContext.Warning.contractRestrictions(reason: .timeshiftDisabled))
            tech.eventDispatcher.onWarning(tech, source, warning)
            source.adService?.playbackPaused()
            source.analyticsConnector.onWarning(tech: self.tech, source: source, warning: warning)
            return
        }
        tech.pause()
    }
}
