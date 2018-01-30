//
//  Player+HeartbeatsProvider.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-11-08.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Player


extension HLSNative: HeartbeatsProvider {
    internal struct PlayerHeartbeatData: HeartbeatData {
        let timestamp: Int64
        let payload: [String: Any]
    }
    
    /// Configure a `Heartbeat` with associated data.
    public func requestHeatbeat() -> HeartbeatData {
        return PlayerHeartbeatData(timestamp: Date().millisecondsSince1970, payload: ["OffsetTime": self.playheadPosition])
    }
}

