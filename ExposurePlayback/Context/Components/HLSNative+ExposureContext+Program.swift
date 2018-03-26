//
//  HLSNative+ExposureContext+Program.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-10.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Player
import Exposure

extension Player where Tech == HLSNative<ExposureContext> {
    // MARK: Program Information
    
    /// Returns the currently playing program, or `nil` if it is unavailable.
    public var currentProgram: Program? {
        return context.programService?.currentProgram
    }
    
    /// Fetches the program associated with the current `playheadTime`.
    public func currentProgram(callback: @escaping (Program?, ExposureError?) -> Void) {
        guard let service = context.programService else {
            callback(nil, nil)
            return
        }
        guard let playhead = playheadTime else {
            callback(nil, nil)
            return
        }
        
        service.currentProgram(for: playhead, callback: callback)
    }
    
    /// Sets the callback to fire once program change triggers
    ///
    /// - parameter callback: callback to fire once the event is fired.
    /// - returns: `Self`
    @discardableResult
    public func onProgramChanged(callback: @escaping (Player<Tech>, ExposureContext.Source, Program?) -> Void) -> Self {
        context.onProgramChanged = { [weak self] program, source in
            guard let `self` = self else { return }
            callback(self, source, program)
        }
        return self
    }
}
