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
open class ExposureSource: MediaSource {
    internal static let segmentLength: Int64 = 6000
    
    /// Connector used to process Analytics Events
    public var analyticsConnector: AnalyticsConnector = PassThroughConnector()
    
    /// Unique playSession Id
    public var playSessionId: String {
        return entitlement.playSessionId
    }
    
    
    /// Media locator
    open var url: URL {
        return proxyUrl ?? URL(string: "https://csm-e.tls1.yospace.com/csm/access/149023395/L0Rldkdyb3VwL0VuaWdtYVRWL3VuZW5jcnlwdGVkX2VuaWdtYS91bmVuY3J5cHRlZC0xX2VuaWdtYS92b2QuaXNtLy5tM3U4?position=start,00:01:11,00:02:10")!
        return proxyUrl ?? entitlement.mediaLocator
    }
    
    /// Internal storage for a proxy mediaLocator
    ///
    /// Sources may optionally modify the mediaLocator, for example by redirecting through an external provider. Will be provided as the source url when loading the tech.
    internal var proxyUrl: URL?
    
    /// Entitlement related to this playback request.
    public let entitlement: PlaybackEntitlement
    
    /// EMP assetId
    public let assetId: String
    
    internal let fairplayRequester: ExposureFairplayRequester
    
    /// Service that manages contract restrictions
    public var contractRestrictionsService: ContractRestrictionsService
    
    /// Creates a new `ExposureSource`
    ///
    /// - note: Creation of *raw* `ExposureSource`s is discouraged. Please use the specialized subclasses such as `AssetSource`, `ProgramSource` or `ChannelSource`
    ///
    /// - parameter entitlement: `PlaybackEntitlement` used to play the asset
    /// - parameter assetId: The id for the asset
    public init(entitlement: PlaybackEntitlement, assetId: String) {
        self.entitlement = entitlement
        self.assetId = assetId
        self.fairplayRequester = entitlement.isUnifiedPackager ? EMUPFairPlayRequester(entitlement: entitlement) : MRRFairplayRequester(entitlement: entitlement)
        self.contractRestrictionsService = BasicContractRestrictions(entitlement: entitlement)
        self.mediaSourceRequestHeaders = [:]
        self.response = nil
    }
    
    /// Creates a new `ExposureSource`
    ///
    /// - note: Creation of *raw* `ExposureSource`s is discouraged. Please use the specialized subclasses such as `AssetSource`, `ProgramSource` or `ChannelSource`
    ///
    /// - parameter entitlement: `PlaybackEntitlement` used to play the asset
    /// - parameter assetId: The id for the asset
    /// - parameter response: HTTP response received when requesting the entitlement
    public init(entitlement: PlaybackEntitlement, assetId: String, response: HTTPURLResponse?) {
        self.entitlement = entitlement
        self.assetId = assetId
        self.fairplayRequester = entitlement.isUnifiedPackager ? EMUPFairPlayRequester(entitlement: entitlement) : MRRFairplayRequester(entitlement: entitlement)
        self.contractRestrictionsService = BasicContractRestrictions(entitlement: entitlement)
        self.mediaSourceRequestHeaders = [:]
        self.response = response
    }
    
    deinit {
        print("ExposureSource deinit")
    }
    
    /// The HTTPURLResponse associated with the Entitlement Request, ie `ExposureRequest`, made to *Exposure* which resulted in the creation of this `Source`.
    internal var response: HTTPURLResponse? {
        didSet {
            if let emupFairplayRequester = fairplayRequester as? EMUPFairPlayRequester, let response = self.response {
                emupFairplayRequester.exposureRequestId = response.allHeaderFields["X-Request-Id"] as? String
            }
        }
    }
    
    /// Stores any HTTP headers used when requesting manifest and media segments for this `Source`.
    public var mediaSourceRequestHeaders: [String: String]
    
    /// Response headers for the entitlement response call
    public var entitlementSourceResponseHeaders: [String : String] {
        var result: [String: String] = [:]
        response?.allHeaderFields.forEach{
            if let key = $0.key as? String, let value = $0.value as? String {
                result[key] = value
            }
        }
        return result
    }
    
    /// Service responsible for handling Ad presentation.
    public var adService: AdService?
    
    /// Provides a way for performing pre-processing of the *Source Url* before feeding it into the `PlaybackTech`.
    ///
    /// Override this method to provide custom modifications on the url. `ExposureContext` will use the `URL` returned by the callback as the `Source`'s proxied mediaLocator when instructing the `tech` to load the `Source`.
    ///
    /// - parameter callback: The callback that will fire when custom source url modifications are done.
    public func prepareSourceUrl(callback: @escaping (URL?) -> Void) {
        callback(nil)
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
        formatter.locale = Locale(identifier: "en_GB")
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

extension ExposureSource: MediaSourceRequestHeaders { }
extension ExposureSource: EntitlementSourceResponseHeaders { }
