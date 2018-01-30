//
//  ExposureContext.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-11-27.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Player

/// Defines the `MediaContext` to be used when contacting *Exposure*.
///
/// Allows retrieval and processing of `PlaybackEntitlement`s through designated extensions on `Player`.
public class ExposureContext: MediaContext {
    /// *Exposure* related errors
    public typealias ContextError = ExposureError
    
    /// Source object encapsulating a fetched `PlaybackEntitlement`
    public typealias Source = ExposureSource
    
    /// Generators used to produce the relevant `AnalyticsProvider`
    public var analyticsGenerators: [(Source?) -> AnalyticsProvider] = []
    
    /// Exposure environment used for the active session.
    public let environment: Environment
    
    /// Token identifying the active session.
    public let sessionToken: SessionToken
    
    /// Service that handles synchronization of local device time with server time
    public let monotonicTimeService: MonotonicTimeService
    
    /// Service that manages entitlement validation on currently active program
    internal var programService: ProgramService?
    
    /// Service that manages contract restrictions
    internal let contractRestrictionsService: ContractRestrictionsService
    
    /// Tracks the internal programChanged callback
    internal var onProgramChanged: (Program?, Source) -> Void = { _,_ in }
    
    /// Tracks the internal entitlementResponse callback
    internal var onEntitlementResponse: (PlaybackEntitlement, Source) -> Void = { _,_ in }
    
    internal var playbackProperties: PlaybackProperties = PlaybackProperties()
    
    public init(environment: Environment, sessionToken: SessionToken) {
        self.environment = environment
        self.sessionToken = sessionToken
        self.monotonicTimeService = MonotonicTimeService(environment: environment)
        self.contractRestrictionsService = ContractRestrictionsService()
    }
    
    deinit {
        print("ExposureContext deinit")
    }
}
