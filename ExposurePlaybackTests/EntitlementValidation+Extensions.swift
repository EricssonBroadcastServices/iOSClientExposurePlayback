//
//  EntitlementValidation+Extensions.swift
//  ExposurePlaybackTests
//
//  Created by Fredrik Sjöberg on 2018-02-12.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Exposure

extension EntitlementValidation {
    static func validJson(status: String) -> [String: Codable] {
        return [
            "status": status,
        ]
    }
}
