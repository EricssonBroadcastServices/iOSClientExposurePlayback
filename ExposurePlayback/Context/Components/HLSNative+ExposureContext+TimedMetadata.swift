//
//  HLSNative+ExposureContext+TimedMetadata.swift
//  ExposurePlayback-iOS
//
//  Created by Fredrik Sjöberg on 2018-10-02.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import AVFoundation
import Player

extension Player where Tech == HLSNative<ExposureContext> {
    
    public func onTimedMetadataChanged(callback: @escaping (Player<HLSNative<ExposureContext>>, ExposureSource?, [AVMetadataItem]?) -> Void) -> Self  {
        tech.onTimedMetadataChanged = { [weak self] tech, source, metadata in
            guard let `self` = self else { return }
            callback(self, source, metadata)
        }
        return self
    }
}

