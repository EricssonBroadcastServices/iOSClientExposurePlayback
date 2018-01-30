//
//  AnalyticsEvent.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-16.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Exposure

/// Extends the basic `AnalyticsPayload` with *EMP* specific data.
internal protocol AnalyticsEvent: AnalyticsPayload {
    /// The type of event
    /// Example: Playback.Created
    var eventType: String { get }
    
    /// Unix timestamp according to device clock when the event was trigged in milliseconds
    var timestamp: Int64 { get }
    
    /// Max time in milliseconds the event is kept in the batch before it should be flushed.
    var bufferLimit: Int64 { get }
}

extension AnalyticsEvent {
    /// Defines how long an event can be kept in a batch before it has to be dispatched. This relates to the *realtime* aspect of the analytics engine.
    var bufferLimit: Int64 {
        return 3000
    }
}
