//
//  HLSNative+ExposureContext+Creation.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-11-27.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Player
import Exposure

/// Extends `Player` using `HLSNative` tech in an `ExposureContext` with a convenience initializer
extension Player where Tech == HLSNative<ExposureContext> {
    // MARK: Creation
    
    /// Convenience initializer that creates and configures `Player` for use with `HLSNative`, `ExposureContext`.
    ///
    /// Attaches `ExposureAnalytics` to deal with *Exposure* relaed analytics dispatch.
    ///
    /// - parameter environment: The *Exposure* environment
    /// - parameter sessionToken: Token identifying this session
    public convenience init(environment: Environment, sessionToken: SessionToken, analyticsBaseUrl: String) {
        self.init(environment: environment, sessionToken: sessionToken, analytics: ExposureAnalytics.self, analyticsBaseUrl:analyticsBaseUrl)

    }
    
    /// Creates and configures `Player` for use with `HLSNative` and `ExposureContext`.
    ///
    /// - parameter environment: The *Exposure* environment
    /// - parameter sessionToken: Token identifying this session
    /// - parameter analytics: The *Exposure* related `AnalyticsProvider` tasked with delivering analytics to the *EMP* backend.
    public convenience init<Analytics: ExposureStreamingAnalyticsProvider>(environment: Environment, sessionToken: SessionToken, analytics: Analytics.Type, cdn: CDNInfoFromEntitlement? = nil , analyticsFromPlayback: AnalyticsFromEntitlement? = nil , analyticsBaseUrl: String) {
        let generator: (Tech.Context.Source?) -> AnalyticsProvider = { _ in return analytics.init(environment: environment, sessionToken: sessionToken, cdn: cdn, analytics: analyticsFromPlayback, analyticsBaseUrl: analyticsBaseUrl) }
        let context = ExposureContext(environment: environment, sessionToken: sessionToken, analyticsBaseUrl: analyticsBaseUrl)
        let tech = HLSNative<ExposureContext>()
        tech.airplayHandler = context
        context.analyticsGenerators.append(generator)
        self.init(tech: tech, context: context)
    }
}
