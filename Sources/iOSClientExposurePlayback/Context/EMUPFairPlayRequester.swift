//
//  EMUPFairPlayRequester.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-01-25.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import AVFoundation
import iOSClientExposure

internal class EMUPFairPlayRequester: NSObject, ExposureFairplayRequester {
    var keyValidationError: Error?
    
    init(entitlement: PlaybackEntitlement, assetId: String) {
        self.entitlement = entitlement
        self.assetId = assetId
    }
    
    internal let assetId: String
    internal let entitlement: PlaybackEntitlement
    internal let resourceLoadingRequestQueue = DispatchQueue(label: "com.emp.exposurePlayback.fairplay.emup.requests")
    internal let customScheme = "skd"
    internal let resourceLoadingRequestOptions: [String : AnyObject]? = nil
    internal var exposureRequestId: String?
    
    internal func onSuccessfulRetrieval(of ckc: Data, for resourceLoadingRequest: AVAssetResourceLoadingRequest) throws -> Data {
        return ckc
    }
    
    /// Streaming requests normally always contact the remote for license and certificates but if it's a downloaded asset we do not need to contact the remote server
    internal func shouldContactRemote(for resourceLoadingRequest: AVAssetResourceLoadingRequest) throws -> Bool {

        // Check if we have an ActiveAirplayRoute , if so pass true to contact remote server
        if AVAudioSession.sharedInstance().hasActiveAirplayRoute {
            return true
        } else {
            // Check if we can handle the request with a previously persisted content key
            if try !persistedContentKeyExists(for: assetId) {
                return true
            } else {
                return false
            }
        }
    }
    
    internal var onCertificateRequest: () -> Void = { }
    internal var onCertificateResponse: (ExposureContext.Error?) -> Void = { _ in }
    
    internal var onLicenseRequest: () -> Void = { }
    internal var onLicenseResponse: (ExposureContext.Error?) -> Void = { _ in }
}




// MARK: - AVAssetResourceLoaderDelegate
extension EMUPFairPlayRequester {
    internal func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        return canHandle(resourceLoadingRequest: loadingRequest)
    }
    
    internal func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
        return canHandle(resourceLoadingRequest: renewalRequest)
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
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
                } else {
                    weakSelf.handleOffline(resourceLoadingRequest: resourceLoadingRequest)
                }
            }
            catch {
                DispatchQueue.main.async{
                    resourceLoadingRequest.finishLoading(with: error)
                }
            }
        }
        
        return true
    }
}

extension EMUPFairPlayRequester {
    
    fileprivate func handleOffline(resourceLoadingRequest: AVAssetResourceLoadingRequest) {
        
        guard let assetIDString = resourceLoadingRequest.request.url?.host, let contentIdentifier = assetIDString.data(using: String.Encoding.utf8) else {
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                let error = ExposureContext.Error.fairplay(reason: .invalidContentIdentifier)
                self.keyValidationError = error
                resourceLoadingRequest.finishLoading(with: error)
            }
            return
        }
        
        do {
            
           guard let dataRequest = resourceLoadingRequest.dataRequest else {
                let error = ExposureContext.Error.fairplay(reason: .missingDataRequest)
                self.keyValidationError = error
                resourceLoadingRequest.finishLoading(with: error)
                return
            }
            
            if let keyData = try persistedContentKey(for: assetId) {
                resourceLoadingRequest.contentInformationRequest?.contentType = AVStreamingKeyDeliveryPersistentContentKeyType
                resourceLoadingRequest.contentInformationRequest?.isByteRangeAccessSupported = true
                resourceLoadingRequest.contentInformationRequest?.contentLength = Int64(keyData.count)
                let contentKey = try self.onSuccessfulRetrieval(of: keyData, for: resourceLoadingRequest)
                
                // Provide data to the loading request.
                dataRequest.respond(with: contentKey)
                resourceLoadingRequest.finishLoading()

                
            }
        } catch {
            self.keyValidationError = error
            resourceLoadingRequest.finishLoading(with: error)
        }
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
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                let error = ExposureContext.Error.fairplay(reason: .invalidContentIdentifier)
                self.keyValidationError = error
                resourceLoadingRequest.finishLoading(with: error)
            }
            return
        }
        
        
        guard let certificateUrl = certificateUrl else {
            let missingCertificateUrlError = ExposureContext.Error.fairplay(reason: .missingApplicationCertificateUrl)
            self.keyValidationError = missingCertificateUrlError
            resourceLoadingRequest.finishLoading(with: missingCertificateUrlError)
            return
        }
        
        /// Fetch the certificate
        fetchApplicationCertificate(url: certificateUrl) { [weak self] certificate, cachedResponse, certificateError in
            guard let `self` = self else { return }

            /// Trigger the certificate response listener
            if !cachedResponse {
                self.onCertificateResponse(certificateError)
            }
            
            if let certificateError = certificateError {
                DispatchQueue.main.async{ [weak self] in
                    self?.keyValidationError = certificateError
                    resourceLoadingRequest.finishLoading(with: certificateError)
                }
                return
            }
            
            if let certificate = certificate {
                do {
                    let spcData = try resourceLoadingRequest.streamingContentKeyRequestData(forApp: certificate, contentIdentifier: contentIdentifier, options: self.resourceLoadingRequestOptions)
                    guard let licenseUrl = self.licenseUrl else {
                        let missingLicenseUrlError = ExposureContext.Error.fairplay(reason: .missingContentKeyContextUrl)
                        self.keyValidationError = missingLicenseUrlError
                        resourceLoadingRequest.finishLoading(with: missingLicenseUrlError)
                        return
                    }
                    
                    /// Fetch the CKC
                    self.fetchContentKeyContext(url: licenseUrl, spc: spcData) { [weak self] ckcBase64, ckcError in
                        guard let `self` = self else { return }
                        
                        /// Trigger the license response listener
                        self.onLicenseResponse(ckcError)
                        
                        DispatchQueue.main.async{ [weak self] in
                            if let ckcError = ckcError {
                                self?.keyValidationError = ckcError
                                resourceLoadingRequest.finishLoading(with: ckcError)
                                return
                            }
                            
                            guard let dataRequest = resourceLoadingRequest.dataRequest else {
                                let error = ExposureContext.Error.fairplay(reason: .missingDataRequest)
                                self?.keyValidationError = error
                                resourceLoadingRequest.finishLoading(with: error)
                                return
                            }
                            
                            guard let ckcBase64 = ckcBase64 else {
                                let error = ExposureContext.Error.fairplay(reason: .missingContentKeyContext)
                                self?.keyValidationError = error
                                resourceLoadingRequest.finishLoading(with: error)
                                return
                            }
                            
                            guard let `self` = self else { return }
                            do {
                                // Allow implementation specific handling of the returned `CKC`
                                let contentKey = try self.onSuccessfulRetrieval(of: ckcBase64, for: resourceLoadingRequest)
                                
                                // Provide data to the loading request.
                                dataRequest.respond(with: contentKey)
                                resourceLoadingRequest.finishLoading() // Treat the processing of the request as complete.
                            }
                            catch {
                                self.keyValidationError = error
                                resourceLoadingRequest.finishLoading(with: error)
                            }
                        }
                    }
                }
                catch {
                    // -42656 Lease duration has expired.
                    // -42668 The CKC passed in for processing is not valid.
                    // -42672 A certificate is not supplied when creating SPC.
                    // -42673 assetId is not supplied when creating an SPC.
                    // -42674 Version list is not supplied when creating an SPC.
                    // -42675 The assetID supplied to SPC creation is not valid.
                    // -42676 An error occurred during SPC creation.
                    // -42679 The certificate supplied for SPC creation is not valid.
                    // -42681 The version list supplied to SPC creation is not valid.
                    // -42783 The certificate supplied for SPC is not valid and is possibly revoked.
                    DispatchQueue.main.async{ [weak self] in
                        if let nsError = error as? NSError, let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError, underlyingError.domain == NSOSStatusErrorDomain {
                            print("SPC Error:",underlyingError.domain, underlyingError.code, underlyingError.debugDescription)
                            self?.keyValidationError = underlyingError
                            resourceLoadingRequest.finishLoading(with: underlyingError)
                        }
                        else {
                            print("SPC Error:",error.localizedDescription)
                            self?.keyValidationError = error
                            resourceLoadingRequest.finishLoading(with: error)
                        }
                    }
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
    /// Callback:
    ///     * Data: The certificate data
    ///     * Bool: If the certificate data was cached (ie no network request was made)
    ///     * Error: An error, if one occured
    ///
    /// - note: This method uses a specialized function for parsing the retrieved *Application Certificate* from an *EMUP specific* format.
    /// - parameter callback: fires when the certificate is fetched or when an `error` occurs.
    fileprivate func fetchApplicationCertificate(url: URL, callback: @escaping (Data?, Bool, ExposureContext.Error?) -> Void) {
        /// Check if the certificate is cached for the requested `certificateUrl`
        if let cachedCertificate = FairplayCertificateCache.shared.cache[url] {
            callback(cachedCertificate, true, nil)
            return
        }
        
        /// Trigger the certificate request listener
        onCertificateRequest()
        
        var headers: [String: String] = [:]
        if let requestId = exposureRequestId {
            headers["X-Request-Id"] = requestId
        }
        
        SessionManager
            .default
            .request(url, method: .get, headers: headers)
            .validate()
            .rawResponse { _, response, data, error in
                guard error == nil else {
                    if let statusError = error as? Request.Networking {
                        if case Request.Networking.unacceptableStatusCode(code: let statusCode) = statusError, let statusData = data {
                            do {
                                let message = try JSONDecoder().decode(ServerErrorMessage.self, from: statusData)
                                callback(nil, false, .fairplay(reason: .applicationCertificateServer(code: message.code, message: message.message)))
                            }
                            catch {
                                callback(nil, false, .fairplay(reason: .applicationCertificateServer(code: statusCode, message: "UNKNOWN_ERROR")))
                            }
                        }
                        else {
                            callback(nil, false, .fairplay(reason: .networking(error: statusError)))
                        }
                    }
                    else {
                        callback(nil, false, .fairplay(reason: .networking(error: error!)))
                    }
                    return
                }
                
                if let certificate = data {
                    FairplayCertificateCache.shared.cache[url] = certificate
                    callback(certificate, false, nil)
                }
        }
    }
    
    /// Retrieve the `certificateUrl` by parsing the *entitlement*.
    fileprivate var certificateUrl: URL? {
        guard let urlString = entitlement.fairplay?.certificateUrl else { return nil }
        return URL(string: urlString)
    }
}


// MARK: - Content Key Context
extension EMUPFairPlayRequester {
    struct ServerErrorMessage: Decodable {
        /// `http` code returned by *Exposure*
        internal let code: Int
        
        /// Related error message returned by *Exposure*
        internal let message: String
        
        internal init(code: Int, message: String) {
            self.code = code
            self.message = message
        }
        
        internal init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            code = try container.decode(Int.self, forKey: .code)
            if let errorMessage = try container.decodeIfPresent(String.self, forKey: .message) {
                message = errorMessage
            }
            else {
                /// HACK: Exposure sometimes returns
                ///
                /// ```json
                /// {
                ///     httpCode: 500
                /// }
                /// ````
                ///
                /// Ie with a missing `message` key:value. This will account for the scenario and internally
                /// map all 500 without a message to "INTERNAL_ERROR". If `httpCode` != 500`, throws a decoding error.
                if code == 500 { message = "INTERNAL_ERROR" }
                else { message = try container.decode(String.self, forKey: .message) }
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(code, forKey: .code)
            try container.encode(message, forKey: .message)
        }
        
        internal enum CodingKeys: CodingKey {
            case code
            case message
        }
    }
    
    /// Fetching a *Content Key Context*, `CKC`, requires a valid *Server Playback Context*.
    ///
    /// - note: This method uses a specialized function for parsing the retrieved *Content Key Context* from an *MRR specific* format.
    ///
    /// - parameter spc: *Server Playback Context*
    /// - parameter callback: fires when `CKC` is fetched or when an `error` occurs.
    fileprivate func fetchContentKeyContext(url: URL, spc: Data, callback: @escaping (Data?, ExposureContext.Error?) -> Void) {
        
        /// Trigger the license request listener
        self.onLicenseRequest()
        
        var headers = ["Content-type": "application/octet-stream"]
        if let requestId = exposureRequestId {
            headers["X-Request-Id"] = requestId
        }
        if let playToken = entitlement.playToken {
            headers["Authorization"] = "Bearer " + playToken
        }
        
        SessionManager
            .default
            .request(url,
                     method: .post,
                     data: spc,
                     headers: headers)
            .validate()
            .rawResponse { _,urlResponse, data, error in
                guard error == nil else {
                    if let statusError = error as? Request.Networking {
                        if case Request.Networking.unacceptableStatusCode(code: let statusCode) = statusError, let statusData = data {
                            do {
                                let message = try JSONDecoder().decode(ServerErrorMessage.self, from: statusData)
                                callback(nil, .fairplay(reason: .contentKeyContextServer(code: message.code, message: message.message)))
                            }
                            catch {
                                callback(nil, .fairplay(reason: .contentKeyContextServer(code: statusCode, message: "UNKNOWN_ERROR")))
                            }
                        }
                        else {
                            callback(nil, .fairplay(reason: .networking(error: statusError)))
                        }
                    }
                    else {
                        callback(nil, .fairplay(reason: .networking(error: error!)))
                    }
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


//MARK: Check for persistedContentKeys
extension EMUPFairPlayRequester {
    internal func contentKeyDirectory() throws -> URL {
        let contentKeyDirectory =  try FileManager
            .default
            .url(for: .documentDirectory,
                 in: .userDomainMask,
                 appropriateFor: nil,
                 create: true)
            .appendingPathComponent("emp")
            .appendingPathComponent("exposure")
            .appendingPathComponent("offlineMedia")
            .appendingPathComponent("keys", isDirectory: true)
        return contentKeyDirectory
    }
    
    internal func contentKeyUrl(for assetId: String) throws -> URL {
        return try contentKeyDirectory().appendingPathComponent("\(assetId)-key")
    }
    
    public func persistedContentKeyExists(for assetId: String) throws -> Bool {
        let url = try contentKeyUrl(for: assetId)
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    public func deletePersistedContentKey(for assetId: String) throws {
        let url = try contentKeyUrl(for: assetId)
        print("deletePersistedContentKey Persisted CKC",assetId,url)
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("Persisted CKC? : NO")
            return
        }
        try FileManager.default.removeItem(at: url)
    }
    
    internal func persistedContentKey(for assetId: String) throws -> Data? {
        let url = try contentKeyUrl(for: assetId)
        print("persistedContentKey : Persisted CKC",assetId,url)
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("Persisted CKC? : NO")
            return nil
        }
        print("Persisted CKC? : YES")
        return try Data(contentsOf: url)
    }
}
