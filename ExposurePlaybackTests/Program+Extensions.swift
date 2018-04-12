//
//  Program+Extensions.swift
//  ExposurePlaybackTests
//
//  Created by Fredrik Sjöberg on 2018-02-11.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Exposure

extension Program {
    static func validJson(programId: String, channelId: String, assetId: String) -> [String: Any] {
        return [
            "programId": programId,
            "assetId": assetId,
            "channelId": channelId
            ]
    }
}

extension Dictionary where Key == String, Value == Any {
    func timestamp(starting: Int64, ending: Int64) -> Dictionary<String,Any> {
        var old = self
        
        let start = Date(milliseconds: starting)
        let end = Date(milliseconds: ending)
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        old["startTime"] = formatter.string(from: start)
        old["endTime"] = formatter.string(from: end)
        return old
    }
}
