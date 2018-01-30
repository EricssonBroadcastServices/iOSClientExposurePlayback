//
//  HLSNative+ExposureContext+Creation.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-11-27.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Player

/// Extends `Player` using `HLSNative` tech in an `ExposureContext` with a convenience initializer
extension Player where Tech == HLSNative<ExposureContext> {
    /// Creates and configures `Player` for use with `HLSNative` and `ExposureContext`.
    ///
    /// - parameter environment: The *Exposure* environment
    /// - parameter sessionToken: Token identifying this session
    /// - analytics: The *Exposure* related `AnalyticsProvider` tasked with delivering analytics to the *EMP* backend.
    public convenience init<Analytics: ExposureStreamingAnalyticsProvider>(environment: Environment, sessionToken: SessionToken, analytics: Analytics.Type) {
        let generator: (Tech.Context.Source?) -> AnalyticsProvider = { _ in return analytics.init(environment: environment, sessionToken: sessionToken) }
        let context = ExposureContext(environment: environment,
                                      sessionToken: sessionToken)
        context.analyticsGenerators.append(generator)
        self.init(tech: HLSNative<ExposureContext>(),
                  context: context)
    }
}
