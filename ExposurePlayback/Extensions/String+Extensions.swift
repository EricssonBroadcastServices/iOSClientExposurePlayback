//
//  String+Extensions.swift
//  ExposurePlayback
//
//  Created by Udaya Sri Senarathne on 2021-01-29.
//  Copyright © 2021 emp. All rights reserved.
//

import Foundation

extension String {
    func convertToTimeInterval() -> TimeInterval {
        guard self != "" else {
            return 0
        }

        var interval:Double = 0

        let parts = self.components(separatedBy: ":")
        for (index, part) in parts.reversed().enumerated() {
            interval += (Double(part) ?? 0) * pow(Double(60), Double(index))
        }

        return interval
    }
}
