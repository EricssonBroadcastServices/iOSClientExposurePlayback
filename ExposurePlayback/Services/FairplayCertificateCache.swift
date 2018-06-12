//
//  FairplayCertificateCache.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-06-11.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation

/// Caches Fairplay Certificates by request url.
internal class FairplayCertificateCache {
    /// Singleton with the `shared` certificate cache
    internal static let shared = FairplayCertificateCache()
    
    fileprivate init() { }
    
    /// The cached certificates
    internal var cache: [URL: Data] = [:]
}
