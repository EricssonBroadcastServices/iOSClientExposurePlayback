//
//  OfflineMediaPlayable.swift
//  ExposurePlayback
//
//  Created by Udaya Sri Senarathne on 2020-05-20.
//  Copyright © 2020 emp. All rights reserved.
//

import Foundation
import iOSClientExposure
import AVKit

///// Playable that can be use to play downloaded assets
public struct OfflineMediaPlayable {
    public init(assetId: String, entitlement: PlayBackEntitlementV2, url: URL) {
        self.assetId = assetId
        self.entitlement = entitlement
        self.urlAsset = AVURLAsset(url: url)
        // self.fairplayRequester = fairplayRequester
    }

    /// Identifier for this `OfflineMediaAsset`
    public let assetId: String

    /// `PlaybackEntitlementV2` associated with this media
    public let entitlement: PlayBackEntitlementV2

    /// `AVURLAsset` used to initiate playback.
    public let urlAsset: AVURLAsset

    // internal let fairplayRequester: FairplayRequester?

}
