//
//  DrmAnalyticsProvider.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-08-02.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import iOSClientPlayer

internal protocol DrmAnalyticsProvider {
    func onCertificateRequest<Tech, Source>(tech: Tech, source: Source) where Tech: PlaybackTech, Source: MediaSource
    func onCertificateResponse<Tech, Source>(tech: Tech, source: Source, error: ExposureContext.Error?) where Tech: PlaybackTech, Source: MediaSource
    
    func onLicenseRequest<Tech, Source>(tech: Tech, source: Source) where Tech: PlaybackTech, Source: MediaSource
    func onLicenseResponse<Tech, Source>(tech: Tech, source: Source, error: ExposureContext.Error?) where Tech: PlaybackTech, Source: MediaSource
}


extension AnalyticsLogger: DrmAnalyticsProvider {
    func onCertificateRequest<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        print("🏷 AnalyticsLogger",type(of: tech),"🎬 onCertificateRequest",source.playSessionId)
    }
    
    func onCertificateResponse<Tech, Source>(tech: Tech, source: Source, error: ExposureContext.Error?) where Tech : PlaybackTech, Source : MediaSource {
        print("🏷 AnalyticsLogger",type(of: tech),"🎬 onCertificateResponse",error == nil ? "SUCCESS" : "ERROR",source.playSessionId)
    }
    
    func onLicenseRequest<Tech, Source>(tech: Tech, source: Source) where Tech : PlaybackTech, Source : MediaSource {
        print("🏷 AnalyticsLogger",type(of: tech),"🎬 onLicenseRequest",source.playSessionId)
    }
    
    func onLicenseResponse<Tech, Source>(tech: Tech, source: Source, error: ExposureContext.Error?) where Tech : PlaybackTech, Source : MediaSource {
        print("🏷 AnalyticsLogger",type(of: tech),"🎬 onLicenseResponse",error == nil ? "SUCCESS" : "ERROR",source.playSessionId)
    }
}
