//
//  AdPlayerProxy.swift
//  ExposurePlayback-iOS
//
//  Created by Fredrik Sjöberg on 2018-10-11.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation

/// Defines a wrapper protocol exposed to Objective-c to facilitate cooperation with non-swift `AdService` sdks.
@objc public protocol AdPlayerProxy: class {
    /// Returns the playhead positon in milliseconds (or -1 if no position can be found)
    var playheadPosition: Int64 { get }
    
    /// Returns if the volume is muted or not (or false if the information is unavailable)
    var isMuted: Bool { get set }
    
    /// Returns the duration of the media source (or -1 if no duration can be found)
    var duration: Int64 { get }
    
    /// Returns the playback rate of the media source (or 0 if no rate can be found)
    var rate: Float { get set }
    
    /// Should set playback rate to 1, resuming the stream
    func play()
    
    /// Should set playback rate to 0, pauing the stream
    func pause()
    
    /// Should stop playback, effetively ending the session and unloading the media source
    func stop()
    
    /// Should seek to the specified time, if possible. The callback should indicate if the seek action was successful or not
    ///
    /// - parameter timeInterval: Target offset for the seek action
    /// - parameter callback: fires when the seek action finishes.
    func seek(toTime timeInterval: Int64, callback: @escaping (Bool) -> Void)
}
