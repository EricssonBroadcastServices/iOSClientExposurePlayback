//
//  PlaybackProperties.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-23.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation

/// `PlaybackProperties` offer additonal control over playback configuration when using `ExposureContext`
///
/// - note: Please note that specifying `PlayFrom` functionality may override any settings to `StartTime` done through the underlying `Tech`.
public struct PlaybackProperties {
    
    /// When autoplay is enabled, playback will resume as soon as the stream is loaded and prepared.
    public let autoplay: Bool
    
    /// Defines where playback will start. The exact behaviour depends on the stream type and playback method.
    ///
    /// Please see the `startPlayback(...)` methods for more in depth information
    public let playFrom: PlayFrom
    
    
    public init(autoplay: Bool = true, playFrom: PlayFrom = .bookmark) {
        self.autoplay = autoplay
        self.playFrom = playFrom
    }
    
    /// Governs where the playback should start from.
    ///
    /// - note: Please note that specifying `PlayFrom` functionality may override any settings to `StartTime` done through the underlying `Tech`.
    public enum PlayFrom {
        /// Uses playback defaults (ie live edge for live manifests)
        case defaultBehaviour
        
        /// Starts from the beginning (ie from program start for a program or at 0 offset for a vod)
        case beginning
        
        /// Use *EMP* bookmarking functionality as returned in `PlaybackEntitlement`
        case bookmark
        
        /// Specify a custom offset as either a *wallclock unix time stamp* or a 0 based offset.
        case custom(offset: Int64)
    }
}
