//
//  HeartbeatsProvider.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-11-08.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation

/// Simple protocol responsible for configuring *heartbeats* for the `AnalyticsProvider`.
public protocol HeartbeatsProvider: class {
    /// Should return a *heartbeat* configured for the current environment
    ///
    /// - returns: `AnalyticsPayload` specifying the heartbeat
    func requestHeatbeat() -> HeartbeatData
}

public protocol HeartbeatData {
    /// Timestamp defining when the heartbeat took place
    var timestamp: Int64 { get }
    
    /// Analytics related payload as `json`
    var payload: [String: Any]  { get }
}
