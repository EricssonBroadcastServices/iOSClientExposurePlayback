//
//  AdTechWrapper.swift
//  ExposurePlayback-iOS
//
//  Created by Fredrik Sjöberg on 2018-10-11.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import iOSClientPlayer

internal class AdTechWrapper: AdPlayerProxy {
    internal weak var tech: HLSNative<ExposureContext>?
    internal init(tech: HLSNative<ExposureContext>) {
        self.tech = tech
    }
    
    var playheadPosition: Int64 {
        return (tech?.playheadPosition ?? -1)
    }
    
    var isMuted: Bool {
        get { return tech?.isMuted ?? false }
        set { tech?.isMuted = newValue }
    }
    
    var duration: Int64 {
        return tech?.duration ?? -1
    }
    
    var rate: Float {
        get { return tech?.rate ?? 0 }
        set { tech?.rate = newValue }
    }
    
    func play() {
        tech?.play()
    }
    
    func pause() {
        tech?.pause()
    }
    
    func stop() {
        tech?.stop()
    }
    
    func seek(toTime timeInterval: Int64, callback: @escaping (Bool) -> Void) {
        guard let tech = tech else {
            callback(false)
            return
        }
        tech.seek(toPosition: timeInterval, callback: callback)
    }
}
