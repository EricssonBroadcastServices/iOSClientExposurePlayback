//
//  ServerTimeProvider.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-09.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation

/// Internal protocol defining a provider supplying `ServerTime`.
internal protocol ServerTimeProvider {
    /// Fetches `ServerTime` using the specified `Environment`
    ///
    /// - parameter environment: The `Environment` in which to fetch the `ServerTime`
    /// - parameter callback: Returning either `ServerTime` on success or `ExposureError` on failure.
    func fetchServerTime(using environment: Environment, callback: @escaping (ServerTime?, ExposureError?) -> Void)
}
