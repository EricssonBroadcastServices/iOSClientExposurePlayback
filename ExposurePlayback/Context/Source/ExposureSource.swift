//
//  ExposureSource.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-11-27.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Player
import Exposure

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
    
    internal let fairplayRequester: ExposureFairplayRequester
    
    public init(entitlement: PlaybackEntitlement, assetId: String) {
        self.entitlement = entitlement
        self.assetId = assetId
        self.fairplayRequester = entitlement.isUnifiedPackager ? EMUPFairPlayRequester(entitlement: entitlement) : MRRFairplayRequester(entitlement: entitlement)
    }
    
    deinit {
        print("ExposureSource deinit")
    }
}

extension ExposureSource {
    /// Checks if the manifest comes from the *Unified Packager*
    internal var isUnifiedPackager: Bool {
        return entitlement.isUnifiedPackager
    }
}

extension ExposureSource {
    private enum UnifiedPackageParams: String {
        case dvrWindowLength = "dvr_window_length"
        case timeshift = "time_shift"
        case tParam = "t"
    }
    
    internal var tParameter: (Int64, Int64?)? {
        guard let param:String = entitlement
            .mediaLocator
            .queryParam(for: UnifiedPackageParams.tParam.rawValue) else  { return nil }
        let comp = param.components(separatedBy: "-")
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        if comp.count == 3 {
            guard let first = formatter.date(from: comp[0...2].joined(separator: "-"))?.millisecondsSince1970 else { return nil }
            return (first,nil)
        }
        else if comp.count == 6 {
            guard let first = formatter.date(from: comp[0...2].joined(separator: "-"))?.millisecondsSince1970 else { return nil }
            let second = formatter.date(from: comp[3...5].joined(separator: "-"))?.millisecondsSince1970
            return (first,second)
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
    internal var timeshiftDelay: Int64? {
        return entitlement
            .mediaLocator
            .queryParam(for: UnifiedPackageParams.timeshift.rawValue)
    }
}

// MARK: - HLSNativeConfigurable
extension ExposureSource: HLSNativeConfigurable {
    public var hlsNativeConfiguration: HLSNativeConfiguration {
        return HLSNativeConfiguration(url: url,
                                      playSessionId: entitlement.playSessionId,
                                      drm: fairplayRequester)
    }
}
