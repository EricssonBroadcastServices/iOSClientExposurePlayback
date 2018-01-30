//
//  PlaybackOffset.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-17.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation

/// Defines an offset into the playback session.
internal protocol PlaybackOffset {
    /// Offset in the video sequence (in milliseconds) where the event occured.
    var offsetTime: Int64 { get }
}
