//
//  HLSNative+ExposureContext+Program.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-10.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Player
import iOSClientExposure

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

    /**
     Move to the next program and performs the necessary entitlement checks if it's not a live program.
     - important: NextProgram is not available for the events.
     */
    public func nextProgram() {
        guard let currentProgram = currentProgram else { return }
        guard let service = context.programService else { return }
        
        // If the program is an event navigating to the next program is not allowed
        guard (self.tech.currentSource?.streamingInfo?.event) != true else {
            let error = NSError(domain: "Navigating to the next program is not allowed for events", code: 40, userInfo: nil)
            service.onWarning(.navigateToNextProgramFailed(programId: currentProgram.programId, channelId: currentProgram.assetId, error: ExposureError.generalError(error: error)))
            return
            
        }
        
        service.nextProgram(program: currentProgram, callback: { program, error in
            
            guard let program = program else {
                return
            }

            var properties: PlaybackProperties?
            
            let currentTimeStamp = Date().millisecondsSince1970
            guard let start = program.startDate?.millisecondsSince1970, let end = program.endDate?.millisecondsSince1970 else { return }
            
            guard start < currentTimeStamp else {
                
                // Next program has not published yet
                let error = NSError(domain: "Next Program has not published", code: 40, userInfo: nil)
                service.onWarning(.navigateToNextProgramFailed(programId: program.programId, channelId: program.assetId, error: ExposureError.generalError(error: error)))
                return
                
            }
            
            if start <= currentTimeStamp && currentTimeStamp < end {
                // This is a live program, need to start from the live edge
                properties = PlaybackProperties(old: self.context.playbackProperties, playFrom: PlaybackProperties.PlayFrom.defaultBehaviour)
            } else {
                // If it is not a live, program should always start from the beginning
                 properties = PlaybackProperties(old: self.context.playbackProperties, playFrom: PlaybackProperties.PlayFrom.beginning)
            }
            
            let playable = self.context.programPlayableGenerator(program)
            self.startPlayback(playable: playable, properties: properties!)
        })
    }
    
    /**
     Move to the previous program and performs the necessary entitlement checks.
     - important: previousProgram is not available for the events.
     */
    public func previousProgram() {

        guard let currentProgram = currentProgram else { return }
        guard let service = context.programService else { return }
        
        // If the program is an event navigating to the previous program is not allowed
        guard (self.tech.currentSource?.streamingInfo?.event) != true else {
            let error = NSError(domain: "Navigating to the previous program is not allowed for events", code: 40, userInfo: nil)
            service.onWarning(.navigateToNextProgramFailed(programId: currentProgram.programId, channelId: currentProgram.assetId, error: ExposureError.generalError(error: error)))
            return
            
        }
        
        service.previousProgram(program: currentProgram, callback: { program, error in
            guard let program = program else {
                return
            }
            let properties = PlaybackProperties(old: self.context.playbackProperties, playFrom: PlaybackProperties.PlayFrom.beginning)
            let playable = self.context.programPlayableGenerator(program)
            self.startPlayback(playable: playable, properties: properties)
        })
    }
}
