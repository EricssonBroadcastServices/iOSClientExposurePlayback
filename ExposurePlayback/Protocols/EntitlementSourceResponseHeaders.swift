//
//  EntitlementSourceResponseHeaders.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-09-11.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation


/// `MediaSource`s created by interaction with Exposure should adopt this protocol.
public protocol EntitlementSourceResponseHeaders {
    /// HTTP response headers returned from an an Exposure entitlement request.
    var entitlementSourceResponseHeaders: [String: String] { get }
}
