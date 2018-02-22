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
    
    
    public let language: LanguagePreferences
    
    /// The desired limit, in bits per second, of network bandwidth consumption for this item.
    ///
    /// Setting a non-zero value will indicate the player should attempt to limit playback to that bitrate. If network bandwidth consumption cannot be lowered to meet the preferredPeakBitRate, it will be reduced as much as possible while continuing to play the item.
    ///
    /// `nil` indicates no restrictions should be applied.
    public let maxBitrate: Int64?
    
    
    public init(autoplay: Bool = true, playFrom: PlayFrom = .defaultBehaviour, language: LanguagePreferences = .userLocale, maxBitrate: Int64? = nil) {
        self.autoplay = autoplay
        self.playFrom = playFrom
        self.language = language
        self.maxBitrate = maxBitrate
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
        
        /// Specify a custom 0 based offset.
        case customPosition(position: Int64)
        
        /// Specify a custom  *wallclock unix time stamp* offset
        case customTime(timestamp: Int64)
    }
    
    public enum LanguagePreferences {
        case defaultBehaviour
        case userLocale
        case custom(text: String?, audio: String?)
    }
}
