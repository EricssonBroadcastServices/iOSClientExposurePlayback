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
    
    /// Specifies language preferences to use.
    public let language: LanguagePreferences
    
    /// The desired limit, in bits per second, of network bandwidth consumption for this item.
    ///
    /// Setting a non-zero value will indicate the player should attempt to limit playback to that bitrate. If network bandwidth consumption cannot be lowered to meet the preferredPeakBitRate, it will be reduced as much as possible while continuing to play the item.
    ///
    /// `nil` indicates no restrictions should be applied.
    ///
    /// Bitrate should be specified in bits per second
    public let maxBitrate: Int64?
    
    /// Specifies custom playback options
    ///
    /// - parameter autoplay: Should playback start immediately when ready
    /// - parameter playFrom: Specifies the desired start time behavior.
    /// - parameter language: Specifies the preferred language
    /// - parameter maxBitrate: Assigns a preferred max bitrate (in bits per second)
    public init(autoplay: Bool = true, playFrom: PlayFrom = .defaultBehaviour, language: LanguagePreferences = .defaultBehaviour, maxBitrate: Int64? = nil) {
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
        /// Subtitle and audio selection defaults to `Tech` behavior.
        case defaultBehaviour
        
        /// Attempts to apply device specified `UserLocale` settings
        case userLocale
        
        /// Applies a custom default selection for `text` and `audio`.
        ///
        /// The supplied language definitions should be *RFC 4646* compliant
        case custom(text: String?, audio: String?)
    }
}
