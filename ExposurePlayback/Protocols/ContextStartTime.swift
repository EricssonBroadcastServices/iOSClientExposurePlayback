//
//  ContextStartTime.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-02-07.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Player

internal protocol ContextStartTime {
    func handleStartTime(for tech: HLSNative<ExposureContext>, in context: ExposureContext)
}
