//
//  HLSNative+ExposureContext+URLPlayback.swift
//
//
//  Created by Udaya Sri Senarathne on 2024-02-15.
//

import Foundation
import iOSClientPlayer
import iOSClientExposure

extension Player where Tech == HLSNative<ExposureContext> {
    public func startPlayback(urlPlayable: URLPlayable) {
        urlPlayable.player.stream(url: urlPlayable.url)
    }
}
