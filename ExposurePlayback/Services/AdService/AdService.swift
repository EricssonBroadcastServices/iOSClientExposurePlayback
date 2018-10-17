//
//  AdServiceProvider.swift
//  ExposurePlayback-iOS
//
//  Created by Fredrik Sjöberg on 2018-10-01.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation

/// Defines a set of requirements `ExposureContext` places on an `AdService`.
///
/// Service providers are required to declare functionality to handle pre-processing of `Source` url's and accept playback status updates.
@objc public protocol AdService {
    /// Inform `AdService` that playback is ready
    func playbackReady()
    
    /// Inform `AdService` that playback started
    func playbackStarted()
    
    /// Inform `AdService` that playback ended
    func playbackEnded()
    
    /// Inform `AdService` that playback paused
    func playbackPaused()
    
    /// Inform `AdService` that playback resumed from a paused state
    func playbackResumed()
    
    /// Inform `AdService` that playback failed
    ///
    /// - parameter error: the error causing playback to fail
    func playbackFailed(error: NSError)
    
    /// Inform `AdService` that playback was stalled due to buffering
    func playbackBufferingStarted()
    
    /// Inform `AdService` that playback resumed after buffering finished
    func playbackBufferingEnded()
    
    /// Inform `AdService` that timed metadata arrived during playback.
    ///
    /// - parameter metaData: the timed metadata
    func playbackTimedMetadata(metaData: Any?)
    
    /// A proxy for the playback tech. This can be used by the `AdService` implementation to interact with the underlying playback tech.
    var playerProxy: AdPlayerProxy? { get set }
    
    /// Ask the `AdService` to prepare playback of a *VoD* asset.
    ///
    /// The callback should be fired whenever the `AdService` has prepared the source.
    ///
    /// - parameter source: url provided by the `AdService` used to initiate the stream
    /// - parameter callback: the callback to fire
    func prepareAsset(source: URL, callback: @escaping (URL) -> Void)
    
    /// Ask the `AdService` to prepare playback of a *program* asset.
    ///
    /// The callback should be fired whenever the `AdService` has prepared the source.
    ///
    /// - parameter source: url provided by the `AdService` used to initiate the stream
    /// - parameter callback: the callback to fire
    
    func prepareProgram(source: URL, callback: @escaping (URL) -> Void)
    
    /// Ask the `AdService` to prepare playback of a *channel* asset.
    ///
    /// The callback should be fired whenever the `AdService` has prepared the source.
    ///
    /// - parameter source: url provided by the `AdService` used to initiate the stream
    /// - parameter callback: the callback to fire
    func prepareChannel(source: URL, callback: @escaping (URL) -> Void)
    
    /// Should optionally return a contract specialized `ContractRestrictionsService` which will be used to handle player policies during playback of the ad-based stream. Returning `nil` here will use the default service based on `PlaybackEntitlement`s.
    ///
    /// - note: The `Source` object which will be using this service will keep an `unowned` reference to the service in question. It is the responsibility of the `AdService` to keep this object alive as long as the `Source` object is alive.
    var contractRestrictionsService: ContractRestrictionsService? { get }
}


