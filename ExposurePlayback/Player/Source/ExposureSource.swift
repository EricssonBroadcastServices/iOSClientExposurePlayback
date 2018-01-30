//
//  ExposureSource.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-11-27.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Player

/// `MediaSource` object defining the response from a successful playback request in the `ExposureContext`
public class ExposureSource: MediaSource {
    internal static let segmentLength: Int64 = 6000
    
    /// Connector used to process Analytics Events
    public var analyticsConnector: AnalyticsConnector = PassThroughConnector()
    
    /// Unique playSession Id
    public var playSessionId: String {
        return entitlement.playSessionId
    }
    
    /// Media locator
    public var url: URL {
        return entitlement.mediaLocator
    }
    
    /// Entitlement related to this playback request.
    public let entitlement: PlaybackEntitlement
    
    /// *EMP* assetId
    public let assetId: String
    
    public init(entitlement: PlaybackEntitlement, assetId: String) {
        self.entitlement = entitlement
        self.assetId = assetId
    }
    
    deinit {
        print("ExposureSource deinit")
    }
    
    internal func handleStartTime(for tech: HLSNative<ExposureContext>, in context: ExposureContext) {
        
    }
}

extension ExposureSource {
    /// Checks if the manifest comes from the *Unified Packager*
    internal var isUnifiedPackager: Bool {
        return entitlement
            .mediaLocator
            .pathComponents
            .reduce(false) { $0 || $1.contains(".isml") }
    }
}

extension ExposureSource {
    private enum UnifiedPackageParams: String {
        case dvrWindowLength = "dvr_window_length"
        case timeshift = "time_shift"
        case tParam = "t"
    }
    
    internal var tParameter: (Int64, Int64?)? {
        if let param:String = entitlement
            .mediaLocator
            .queryParam(for: UnifiedPackageParams.tParam.rawValue) {
            let formatter = Program.exposureDateFormatter
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            if let ms = formatter.date(from: param)?.millisecondsSince1970 {
                return (ms, nil)
            }
            return nil
        }
        return nil
    }
    
    /// Retrieves the *DVR* window
    internal var dvrWindowLength: Int64? {
        return entitlement
            .mediaLocator
            .queryParam(for: UnifiedPackageParams.dvrWindowLength.rawValue)
    }
    
    /// Specifies the timeshift delay *in seconds* (if available).
    ///
    /// Negative timeshift delays will be clamped at zero.
    ///
    /// - note: Requires a *Unified Packager* sourced stream.
    internal var timeshiftDelay: Int64? {
        return entitlement
            .mediaLocator
            .queryParam(for: UnifiedPackageParams.timeshift.rawValue)
    }
}

extension ExposureSource: HLSNativeConfigurable {
    public var hlsNativeConfiguration: HLSNativeConfiguration {
        let drmAgent = ExposureStreamFairplayRequester(entitlement: entitlement)
        return HLSNativeConfiguration(url: url,
                                      playSessionId: entitlement.playSessionId,
                                      drm: drmAgent)
    }
}
