//
//  HLSNative+ExposureContext+Creation.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-11-27.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import iOSClientPlayer
import iOSClientExposure

/// Extends `Player` using `HLSNative` tech in an `ExposureContext` with a convenience initializer
extension Player where Tech == HLSNative<ExposureContext> {
    // MARK: Creation
    
    /// Convenience initializer that creates and configures `Player` for use with `HLSNative`, `ExposureContext`.
    ///
    /// Attaches `ExposureAnalytics` to deal with *Exposure* relaed analytics dispatch.
    ///
    /// - parameter environment: The *Exposure* environment
    /// - parameter sessionToken: Token identifying this session
    /// - parameter appName: App name
    /// - parameter appVersion: App version
    public convenience init(environment: Environment, sessionToken: SessionToken, appName: String? = nil, appVersion: String? = nil  ) {
        self.init(environment: environment, sessionToken: sessionToken, analytics: ExposureAnalytics.self, appName: appName, appVersion: appVersion)
    }
    
    /// Creates and configures `Player` for use with `HLSNative` and `ExposureContext`.
    ///
    /// - parameter environment: The *Exposure* environment
    /// - parameter sessionToken: Token identifying this session
    /// - parameter analytics: The *Exposure* related `AnalyticsProvider` tasked with delivering analytics to the *EMP* backend.
    public convenience init<Analytics: ExposureStreamingAnalyticsProvider>(environment: Environment, sessionToken: SessionToken, analytics: Analytics.Type, cdn: CDNInfoFromEntitlement? = nil , analyticsFromPlayback: AnalyticsFromEntitlement? = nil , appName: String? = nil, appVersion: String? = nil ) {
        let generator: (Tech.Context.Source?) -> AnalyticsProvider = { _ in return analytics.init(environment: environment, sessionToken: sessionToken, cdn: cdn, analytics: analyticsFromPlayback, appName: appName, appVersion: appVersion) }
        let context = ExposureContext(environment: environment, sessionToken: sessionToken, appName: appName, appVersion: appVersion)

        let tech = HLSNative<ExposureContext>()
        tech.airplayHandler = context
        context.analyticsGenerators.append(generator)
        self.init(tech: tech, context: context)
    }
}
