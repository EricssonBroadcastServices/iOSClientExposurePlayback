//
//  HLSNative+ExposureContext+ServerTime.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-10.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import iOSClientPlayer

extension Player where Tech == HLSNative<ExposureContext> {
    // MARK: Server Time
    
    /// Returns the cached, *server wallclock timestamp* in unix epoch (milliseconds)
    ///
    /// Will return `nil` if no server time has been synched yet.
    public var serverTime: Int64? {
        return context.monotonicTimeService.serverTime
    }
    
    /// Fetches the latest *server wallclock timestamp* in unix epoch time (milliseconds).
    ///
    /// Will perform server time synchronization before returning any cached results unless `forceRefresh` is set to `false`.
    ///
    /// - parameter forceRefresh: Specifying `true` will force a server request fetching an up to date `MonotonicTime` if the service is running. `false` will return the cached `MonotonicTime`.
    public func serverTime(forceRefresh: Bool = true, callback: @escaping (Int64?) -> Void) {
        context.monotonicTimeService.serverTime(forceRefresh: forceRefresh) { serverTime, error in
            callback(serverTime)
        }
    }
}
