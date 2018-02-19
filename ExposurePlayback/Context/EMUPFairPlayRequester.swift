//
//  EMUPFairPlayRequester.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-01-25.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import AVFoundation
import Player
import Exposure

internal class EMUPFairPlayRequester: NSObject, ExposureFairplayRequester {
    
    init(entitlement: PlaybackEntitlement) {
        self.entitlement = entitlement
    }
    
    internal let entitlement: PlaybackEntitlement
    internal let resourceLoadingRequestQueue = DispatchQueue(label: "com.emp.exposurePlayback.fairplay.emup.requests")
    internal let customScheme = "skd"
    internal let resourceLoadingRequestOptions: [String : AnyObject]? = nil
    
    internal func onSuccessfulRetrieval(of ckc: Data, for resourceLoadingRequest: AVAssetResourceLoadingRequest) throws -> Data {
        return ckc
    }
    
    /// Streaming requests normally always contact the remote for license and certificates.
    internal func shouldContactRemote(for resourceLoadingRequest: AVAssetResourceLoadingRequest) throws -> Bool {
        return true
    }
}

// MARK: - AVAssetResourceLoaderDelegate
extension EMUPFairPlayRequester {
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        return canHandle(resourceLoadingRequest: loadingRequest)
    }
    
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
        return canHandle(resourceLoadingRequest: renewalRequest)
    }
}

extension EMUPFairPlayRequester {
    /// Starting point for the *Fairplay* validation chain. Note that returning `false` from this method does not automatically mean *Fairplay* validation failed.
    ///
    /// - parameter resourceLoadingRequest: loading request to handle
    /// - returns: ´true` if the requester can handle the request, `false` otherwise.
    internal func canHandle(resourceLoadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        guard let url = resourceLoadingRequest.request.url else {
            return false
        }
        
        // Should handle FPS Content Key requests.
        if url.scheme != customScheme {
            return false
        }
        
        resourceLoadingRequestQueue.async { [weak self] in
            guard let weakSelf = self else { return }
            do {
                if try weakSelf.shouldContactRemote(for: resourceLoadingRequest) {
                    weakSelf.handle(resourceLoadingRequest: resourceLoadingRequest)
                }
            }
            catch {
                resourceLoadingRequest.finishLoading(with: error)
            }
        }
        
        return true
    }
}

extension EMUPFairPlayRequester {
    /// Handling a *Fairplay* validation request is a process in several parts:
    ///
    /// * Fetch and parse the *Application Certificate*
    /// * Request a *Server Playback Context*, `SPC`, for the specified asset using the *Application Certificate*
    /// * Request a *Content Key Context*, `CKC`, for the validated `SPC`.
    ///
    /// If this process fails, the `resourceLoadingRequest` will call `resourceLoadingRequest.finishLoading(with: someError`.
    ///
    /// For more information regarding *Fairplay* validation, please see Apple's documentation regarding *Fairplay Streaming*.
    fileprivate func handle(resourceLoadingRequest: AVAssetResourceLoadingRequest) {
        
        guard let assetIDString = resourceLoadingRequest.request.url?.host, let contentIdentifier = assetIDString.data(using: String.Encoding.utf8) else {
            resourceLoadingRequest.finishLoading(with: ExposureContext.Error.fairplay(reason: .invalidContentIdentifier))
            return
        }
        
        fetchApplicationCertificate{ [weak self] certificate, certificateError in
            guard let `self` = self else { return }
            if let certificateError = certificateError {
                print("Certificate Error",certificateError.localizedDescription)
                resourceLoadingRequest.finishLoading(with: certificateError)
                return
            }
            
            if let certificate = certificate {
                do {
                    let spcData = try resourceLoadingRequest.streamingContentKeyRequestData(forApp: certificate, contentIdentifier: contentIdentifier, options: self.resourceLoadingRequestOptions)
                    
                    self.fetchContentKeyContext(spc: spcData) { [weak self] ckcBase64, ckcError in
                        guard let `self` = self else { return }
                        if let ckcError = ckcError {
                            print("CKC Error",ckcError.localizedDescription)
                            resourceLoadingRequest.finishLoading(with: ckcError)
                            return
                        }
                        
                        guard let dataRequest = resourceLoadingRequest.dataRequest else {
                            resourceLoadingRequest.finishLoading(with: ExposureContext.Error.fairplay(reason: .missingDataRequest))
                            return
                        }
                        
                        guard let ckcBase64 = ckcBase64 else {
                            resourceLoadingRequest.finishLoading(with: ExposureContext.Error.fairplay(reason: .missingContentKeyContext))
                            return
                        }
                        
                        do {
                            // Allow implementation specific handling of the returned `CKC`
                            let contentKey = try self.onSuccessfulRetrieval(of: ckcBase64, for: resourceLoadingRequest)
                            
                            // Provide data to the loading request.
                            dataRequest.respond(with: contentKey)
                            resourceLoadingRequest.finishLoading() // Treat the processing of the request as complete.
                        }
                        catch {
                            resourceLoadingRequest.finishLoading(with: error)
                        }
                    }
                }
                catch {
                    //                    -42656 Lease duration has expired.
                    //                    -42668 The CKC passed in for processing is not valid.
                    //                    -42672 A certificate is not supplied when creating SPC.
                    //                    -42673 assetId is not supplied when creating an SPC.
                    //                    -42674 Version list is not supplied when creating an SPC.
                    //                    -42675 The assetID supplied to SPC creation is not valid.
                    //                    -42676 An error occurred during SPC creation.
                    //                    -42679 The certificate supplied for SPC creation is not valid.
                    //                    -42681 The version list supplied to SPC creation is not valid.
                    //                    -42783 The certificate supplied for SPC is not valid and is possibly revoked.
                    print("SPC Error ",error.localizedDescription)
                    resourceLoadingRequest.finishLoading(with: ExposureContext.Error.fairplay(reason: .serverPlaybackContext(error: error)))
                    return
                }
            }
        }
    }
}

// MARK: - Application Certificate
extension EMUPFairPlayRequester {
    /// The *Application Certificate* is fetched from a server specified by a `certificateUrl` delivered in the *entitlement* obtained through *Exposure*.
    ///
    /// - note: This method uses a specialized function for parsing the retrieved *Application Certificate* from an *MRR specific* format.
    /// - parameter callback: fires when the certificate is fetched or when an `error` occurs.
    fileprivate func fetchApplicationCertificate(callback: @escaping (Data?, ExposureContext.Error?) -> Void) {
        guard let url = certificateUrl else {
            callback(nil, .fairplay(reason: .missingApplicationCertificateUrl))
            return
        }
        
        SessionManager
            .default
            .request(url,
                     method: .get)
            .validate()
            .rawResponse { [weak self] _,_, data, error in
                guard let `self` = self else { return }
                if let error = error {
                    callback(nil, .fairplay(reason: .networking(error: error)))
                    return
                }
                
                if let success = data {
                    do {
                        let certificate = try self.parseApplicationCertificate(response: success)
                        callback(certificate, nil)
                    }
                    catch {
                        callback(nil, error as? ExposureContext.Error)
                    }
                }
        }
    }
    
    /// Retrieve the `certificateUrl` by parsing the *entitlement*.
    fileprivate var certificateUrl: URL? {
        guard let urlString = entitlement.fairplay?.certificateUrl else { return nil }
        return URL(string: urlString)
    }
    
    fileprivate func parseApplicationCertificate(response data: Data) throws -> Data {
        return data
    }
    
}


// MARK: - Content Key Context
extension EMUPFairPlayRequester {
    /// Fetching a *Content Key Context*, `CKC`, requires a valid *Server Playback Context*.
    ///
    /// - note: This method uses a specialized function for parsing the retrieved *Content Key Context* from an *MRR specific* format.
    ///
    /// - parameter spc: *Server Playback Context*
    /// - parameter callback: fires when `CKC` is fetched or when an `error` occurs.
    fileprivate func fetchContentKeyContext(spc: Data, callback: @escaping (Data?, ExposureContext.Error?) -> Void) {
        guard let url = licenseUrl else {
            callback(nil, .fairplay(reason: .missingContentKeyContextUrl))
            return
        }
        
        SessionManager
            .default
            .request(url,
                     method: .post,
                     data: spc,
                     headers: ["Content-type": "application/octet-stream"])
            .validate()
            .rawResponse { _,_, data, error in
                if let error = error {
                    callback(nil, .fairplay(reason:.networking(error: error)))
                    return
                }
                
                if let success = data {
                    callback(success,nil)
                }
        }
    }
    
    /// Retrieve the `licenseUrl` by parsing the *entitlement*.
    fileprivate var licenseUrl: URL? {
        guard let urlString = entitlement.fairplay?.licenseAcquisitionUrl else { return nil }
        return URL(string: urlString)
    }
}
