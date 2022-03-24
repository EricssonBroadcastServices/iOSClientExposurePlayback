//
//  CMTime+Extensions.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-02-07.
//  Copyright © 2018 emp. All rights reserved.
//

import AVFoundation

extension CMTime {
    public var milliseconds: Int64? {
        guard !isIndefinite && isValid else {
            return nil
        }
        return Int64(seconds*1000)
    }
    
    public init(milliseconds: Int64) {
        self.init(value: milliseconds, timescale: 1000)
    }
}
