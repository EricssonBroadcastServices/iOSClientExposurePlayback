//
//  ServerTime+Extensions.swift
//  ExposurePlaybackTests
//
//  Created by Fredrik Sjöberg on 2018-02-12.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Exposure

extension ServerTime {
    static func validJson(date: Date) -> [String: Codable] {
        return [
            "epochMillis": UInt64(date.millisecondsSince1970)
        ]
    }
}
