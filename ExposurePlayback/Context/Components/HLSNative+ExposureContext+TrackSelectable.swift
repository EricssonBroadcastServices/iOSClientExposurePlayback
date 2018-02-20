//
//  HLSNative+ExposureContext+TrackSelectable.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-02-20.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Exposure
import Player

extension Player where Tech == HLSNative<ExposureContext> {
    // MARK: Audio
    
    /// Returns the audio related `MediaGroup`
    public var audioGroup: MediaGroup? {
        return tech.audioGroup
    }
    
    /// Should fetch the default audio track, or `nil` if unavailable
    public var defaultAudioTrack: MediaTrack? {
        return tech.defaultAudioTrack
    }
    
    /// Should fetch all associated audio tracks
    public var audioTracks: [MediaTrack] {
        return tech.audioTracks
    }
    
    /// Should fetch the selected audio track if available, otherwise `nil`
    public var selectedAudioTrack: MediaTrack? {
        return tech.selectedAudioTrack
    }
    
    /// Should indicate if it is possible to select no audio track
    public var allowsEmptyAudioSelection: Bool {
        return tech.allowsEmptyAudioSelection
    }
    
    /// Should select the specified audio track or, if `allowsEmptyAudioSelection` == true, select no audio track
    ///
    /// - parameter track: The audio track to select
    public func selectAudio(track: MediaTrack?) {
        tech.selectAudio(track: track)
    }
    
    /// Should select the specified audio language if available or, if `allowsEmptyAudioSelection` == true, select no audio track
    ///
    /// - parameter language: The RFC 4646 language tag identifying the track
    public func selectAudio(language: String?) {
        tech.selectAudio(language: language)
    }
    
    
    // MARK: Text
    /// Returns the text related `MediaGroup`
    public var textGroup: MediaGroup? {
        return tech.textGroup
    }
    
    /// Should fetch the default text track, or `nil` if unavailable
    public var defaultTextTrack: MediaTrack? {
        return tech.defaultTextTrack
    }
    
    /// Should fetch all associated text tracks
    public var textTracks: [MediaTrack] {
        return tech.textTracks
    }
    
    /// Should fetch the selected text track if available, otherwise `nil`
    public var selectedTextTrack: MediaTrack? {
        return tech.selectedTextTrack
    }
    
    /// Should indicate if it is possible to select no text track
    public var allowsEmptyTextSelection: Bool {
        return tech.allowsEmptyTextSelection
    }
    
    /// Should select the specified text track or, if `allowsEmptyTextSelection` == true, select no text track
    ///
    /// - parameter track: The text track to select
    public func selectText(track: MediaTrack?) {
        tech.selectText(track: track)
    }
    
    /// Should select the specified text language if available or, if `allowsEmptyTextSelection` == true, select no text track
    ///
    /// - parameter language: The RFC 4646 language tag identifying the track
    public func selectText(language: String?) {
        tech.selectText(language: language)
    }
}

