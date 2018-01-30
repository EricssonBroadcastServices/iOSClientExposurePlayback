//
//  AnalyticsBatch+Extensions.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-25.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Exposure

/// MARK: - Buffer Limits
extension AnalyticsBatch {
    /// Returns the timestamp in milliseconds (unix epoch time) by which the batch should be sent, or nil if no payload is found
    internal func bufferLimit() -> Int64? {
        return payload
            .flatMap{ $0 as? AnalyticsEvent }
            .map{ $0.timestamp + $0.bufferLimit }
            .sorted{ $0 < $1 }
            .first
    }
}