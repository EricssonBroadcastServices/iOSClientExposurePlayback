//
//  HeartbeatsProvider.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-02-20.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import iOSClientPlayer

internal protocol HeartbeatsProvider {
    func heartbeat(for tech: HLSNative<ExposureContext>, in context: ExposureContext) -> Playback.Heartbeat
}
