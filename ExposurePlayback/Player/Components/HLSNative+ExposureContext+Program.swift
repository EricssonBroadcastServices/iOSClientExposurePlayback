//
//  HLSNative+ExposureContext+Program.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-10.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Player

// MARK: - Program Data
extension Player where Tech == HLSNative<ExposureContext> {
    public var currentProgram: Program? {
        return context.programService?.currentProgram
    }
    
    public func currentProgram(callback: @escaping (Program?, ExposureError?) -> Void) {
        guard let service = context.programService else {
            callback(nil, nil)
            return
        }
        context.monotonicTimeService.serverTime{ [weak service] serverTime, error in
            if let serverTime = serverTime {
                service?.currentProgram(for: serverTime, callback: callback)
            }
            
            if let error = error {
                callback(nil, error)
            }
        }
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
