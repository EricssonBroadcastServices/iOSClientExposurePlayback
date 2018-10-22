//
//  AdInteractionPolicy.swift
//  ExposurePlayback-iOS
//
//  Created by Fredrik Sjöberg on 2018-10-11.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation

@objc public protocol AdInteractionPolicy {
    func requiredAttentionBeforeSkipping(fromPosition: Int64) -> Int64
    func allowedTargetSeek(forRequest: Int64) -> Int64
    func canPause(atPosition: Int64) -> Bool
}
