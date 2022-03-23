//
//  ContractRestrictionsService.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-29.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import iOSClientExposure

@objc public protocol ContractRestrictionsService {
    /// The receiver should return if the seeking is allowed
    ///
    /// - parameter origin: The position from where the seek was initiated (playhead position in milliseconds)
    /// - parameter destination: The requested seek target offset (playhead position in milliseconds)
    /// - returns: If seeking is allowed
    @objc func canSeek(fromPosition origin: Int64, toPosition destination: Int64) -> Bool
    
    /// The receiver should return the allowed target seek offset (optionally modifying it) or return a negative value if seeking is not allowed
    ///
    /// - parameter origin: The position from where the seek was initiated (playhead position in milliseconds)
    /// - parameter destination: The requested seek target offset (playhead position in milliseconds)
    /// - returns: The allowed seek target offset (playhead position in milliseconds)
    @objc func willSeek(fromPosition origin: Int64, toPosition destination: Int64) -> Int64
    
    /// The receiver should return if the caller is allowed to pause playback at the requested position
    ///
    /// - parameter position: The requested position for which the caller wishes to pause
    /// - returns: `true` if pausing is allowed at `position`, `false` otherwise.
    @objc func canPause(at position: Int64) -> Bool
    
    
    /// Bridges the contract policy restrictions in `PlaybackEntitlement` and the objective c environment.
    ///
    /// This information might be used to guide playback behaviour
    @objc var contractRestrictionsPolicy: ContractRestrictionsPolicy? { get set }
}
