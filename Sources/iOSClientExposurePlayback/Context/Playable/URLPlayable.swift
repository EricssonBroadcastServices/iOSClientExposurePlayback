//
//  URLPlayable.swift
//
//
//  Created by Robert Pelka on 14/02/2024.
//

import Foundation
import iOSClientExposure
import iOSClientPlayer

public struct URLPlayable {
    let url: URL
    var player: Player<HLSNative<ManifestContext>>
    
    public init(
        url: URL,
        player: Player<HLSNative<ManifestContext>>
    ) {
        self.url = url
        self.player = player
    }
}
