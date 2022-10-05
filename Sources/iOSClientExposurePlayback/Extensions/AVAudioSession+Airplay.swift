//
//  AVAudioSession+Airplay.swift
//  iOSClientExposurePlayback
//
//  Created by Udaya Sri Senarathne on 2022-08-18.
//  Copyright © 2022 emp. All rights reserved.
//

import Foundation
import AVFoundation

extension AVAudioSession {
    var hasActiveAirplayRoute: Bool {
        return currentRoute.outputs.reduce(false) { $0 || $1.portType == AVAudioSession.Port.airPlay }
    }
}
