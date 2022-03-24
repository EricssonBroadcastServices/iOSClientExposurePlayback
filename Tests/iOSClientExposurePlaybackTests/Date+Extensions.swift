//
//  Date+Extensions.swift
//  ExposurePlaybackTests
//
//  Created by Fredrik Sjöberg on 2018-02-13.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation

// Avoid namespace collision between @testable Player and @testable Exposure
extension Date {
    internal var unixEpoch: Int64 {
        return Int64((timeIntervalSince1970 * 1000.0).rounded())
    }
    
    internal init(unixEpoch: Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(unixEpoch / 1000))
    }
}
