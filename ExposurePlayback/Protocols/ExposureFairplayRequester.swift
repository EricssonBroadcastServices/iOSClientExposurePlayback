//
//  ExposureFairplayRequester.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-07-03.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import AVFoundation
import Player
import Exposure

internal protocol ExposureFairplayRequester: class, FairplayRequester {
    /// Entitlement related to this specific *Fairplay* request.
    var entitlement: PlaybackEntitlement { get }
    
    /// The DispatchQueue to use for AVAssetResourceLoaderDelegate callbacks.
    var resourceLoadingRequestQueue: DispatchQueue { get }
    
    /// Options specifying the resource loading request
    var resourceLoadingRequestOptions: [String : AnyObject]? { get }
    
    /// The URL scheme for FPS content.
    var customScheme: String { get }
}

