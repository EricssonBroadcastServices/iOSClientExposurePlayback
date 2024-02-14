//
//  URLSource.swift
//
//
//  Created by Robert Pelka on 14/02/2024.
//

import Foundation

/// Specialized `MediaSource` used for playback of external URLs
open class URLSource: ExposureSource {
    public override func prepareSourceUrl(callback: @escaping (URL?) -> Void) {
        callback(self.url)
    }
}
