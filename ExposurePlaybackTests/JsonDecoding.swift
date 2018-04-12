//
//  JsonDecoding.swift
//  ExposurePlaybackTests
//
//  Created by Fredrik Sjöberg on 2018-01-30.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation


extension Dictionary where Key == String, Value == Any {
    func decode<T>(_ type: T.Type) -> T? where T : Decodable {
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    func decodeWrap<T>(_ type: T.Type) -> [T]? where T : Decodable {
        return [decode(type)].flatMap{$0}
    }
}

extension Dictionary where Key == String, Value == Any {
    func throwingDecode<T>(_ type: T.Type) throws -> T where T : Decodable {
        let data = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
