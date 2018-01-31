//
//  DownloadResumed.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-11-09.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Exposure

extension Playback {
    internal struct DownloadResumed: AnalyticsEvent {
        internal let eventType: String = "Playback.DownloadResumed"
        internal let bufferLimit: Int64 = 3000
        internal let timestamp: Int64
        
        /// *EMP* asset id of the video being downloaded.
        internal var assetData: PlaybackIdentifier? {
            return requiredAssetData
        }
        internal let requiredAssetData: PlaybackIdentifier
        
        /// The currently downloaded media size
        internal let downloadedSize: Int64?
        
        /// Total size of media download
        internal let mediaSize: Int64?
        
        internal init(timestamp: Int64, assetData: PlaybackIdentifier, downloadedSize: Int64? = nil, mediaSize: Int64? = nil) {
            self.timestamp = timestamp
            self.requiredAssetData = assetData
            self.downloadedSize = downloadedSize
            self.mediaSize = mediaSize
        }
    }
}

extension Playback.DownloadResumed: AssetIdentifier { }
extension Playback.DownloadResumed {
    internal var jsonPayload: [String : Any] {
        var params: [String: Any] = [
            JSONKeys.eventType.rawValue: eventType,
            JSONKeys.timestamp.rawValue: timestamp
        ]
        
        if let downloadedSize = downloadedSize {
            params[JSONKeys.downloadedSize.rawValue] = downloadedSize
        }
        
        if let mediaSize = mediaSize {
            params[JSONKeys.mediaSize.rawValue] = mediaSize
        }
        
        if let assetId = assetId {
            params[JSONKeys.assetId.rawValue] = assetId
        }
        
        return params
    }
    
    internal enum JSONKeys: String {
        case eventType = "EventType"
        case timestamp = "Timestamp"
        case assetId = "AssetId"
        case downloadedSize = "DownloadedSize"
        case mediaSize = "MediaSize"
    }
}
