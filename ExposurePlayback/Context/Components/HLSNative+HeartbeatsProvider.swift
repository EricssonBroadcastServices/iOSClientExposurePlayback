//
//  Player+HeartbeatsProvider.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-11-08.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Player
import Exposure

extension HLSNative: HeartbeatsProvider {
    /// Configure a `Heartbeat` with associated data.
    public func requestHeatbeat() -> AnalyticsEvent {
        return Playback.Heartbeat(timestamp: Date().millisecondsSince1970, offsetTime: self.playheadPosition)
    }
}

