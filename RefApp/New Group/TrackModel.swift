//
//  TrackModel.swift
//  iOSReferenceApp
//
//  Created by Fredrik Sjöberg on 2018-03-12.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Player

protocol TrackModel {
    var displayName: String { get }
    var extendedLanguageTag: String? { get }
}



extension MediaTrack: TrackModel {
    var displayName: String { return name }
}
