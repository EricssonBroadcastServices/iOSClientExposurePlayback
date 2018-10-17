//
//  ContractRestrictionsService.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-29.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Exposure

@objc public protocol ContractRestrictionsService {
    /// The receiver should return the allowed target seek offset (optionally modifying it) or return a negative value if seeking is not allowed
    ///
    /// - parameter origin: The position from where the seek was initiated (playhead position in milliseconds)
    /// - parameter destination: The requested seek target offset (playhead position in milliseconds)
    /// - returns: The allowed seek target offset, or a negative value if seeking is disallowed (playhead position in milliseconds)
    func canSeek(fromPosition origin: Int64, toPosition destination: Int64) -> Int64
    
    /// The receiver should return the allowed target seek offset (optionally modifying it) or return a negative value if seeking is not allowed
    ///
    /// - parameter origin: The position from where the seek was initiated (unix epoc in milliseconds)
    /// - parameter destination: The requested seek target offset (unix epoc in milliseconds)
    /// - returns: The allowed seek target offset, or a negative value if seeking is disallowed (unix epoc in milliseconds)
    func canSeek(fromTime origin: Int64, toTime destination: Int64) -> Int64
    
    /// The receiver should return if the caller is allowed to pause playback at the requested position
    ///
    /// - parameter position: The requested position for which the caller wishes to pause
    /// - returns: `true` if pausing is allowed at `position`, `false` otherwise.
    func canPause(at position: Int64) -> Bool
    
    
    /// Bridges the contract policy restrictions in `PlaybackEntitlement` and the objective c environment.
    ///
    /// This information might be used to guide playback behaviour
    var contractRestrictionsPolicy: ContractRestrictionsPolicy? { get set }
}
