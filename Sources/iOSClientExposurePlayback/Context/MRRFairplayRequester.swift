//
//  ExposureStreamFairplayRequester.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-10-02.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import AVFoundation
import iOSClientPlayer
import iOSClientExposure


@available(*, deprecated, message: "Please use only EMUPFairPlayRequester")
/// *MRR* specific implementation of the `FairplayRequester` protocol for streaming purposes.
///
/// This class handles any *Exposure* related `DRM` validation with regards to *Fairplay*. It is designed to be *plug-and-play* and should require no configuration to use.
internal class MRRFairplayRequester: NSObject, ExposureFairplayRequester {
    
    var keyValidationError: Error?
    
    init(entitlement: PlaybackEntitlement) {
        self.entitlement = entitlement
    }
    
    internal let entitlement: PlaybackEntitlement
    internal let resourceLoadingRequestQueue = DispatchQueue(label: "com.emp.exposure.streaming.fairplay.requests")
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
extension MRRFairplayRequester {
    internal func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        return canHandle(resourceLoadingRequest: loadingRequest)
    }
    
    internal func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
        return canHandle(resourceLoadingRequest: renewalRequest)
    }
}

extension MRRFairplayRequester {
    /// Starting point for the *Fairplay* validation chain. Note that returning `false` from this method does not automatically mean *Fairplay* validation failed.
    ///
    /// - parameter resourceLoadingRequest: loading request to handle
    /// - returns: ´true` if the requester can handle the request, `false` otherwise.
    internal func canHandle(resourceLoadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        guard let url = resourceLoadingRequest.request.url else {
            return false
        }
        
        //EMPFairplayRequester only should handle FPS Content Key requests.
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

extension MRRFairplayRequester {
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
        
        guard let url = resourceLoadingRequest.request.url,
            let assetIDString = url.host,
            let contentIdentifier = assetIDString.data(using: String.Encoding.utf8) else {
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }
                    let error = ExposureContext.Error.fairplay(reason: .invalidContentIdentifier)
                    self.keyValidationError = error
                    resourceLoadingRequest.finishLoading(with: error)
                }
                return
        }
        
        
        
        print("MRRFairplayRequester url : \(url) - ,\(assetIDString)")
        
        fetchApplicationCertificate{ [weak self] certificate, certificateError in
            guard let `self` = self else { return }
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
                    
                    // Content Key Context fetch from licenseUrl requires base64 encoded data
                    let spcBase64 = spcData.base64EncodedData(options: Data.Base64EncodingOptions.endLineWithLineFeed)
                    
                    self.fetchContentKeyContext(spc: spcBase64) { [weak self] ckcBase64, ckcError in
                        guard let `self` = self else { return }
                        
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
                    DispatchQueue.main.async{ [weak self] in
                        self?.keyValidationError = error
                        resourceLoadingRequest.finishLoading(with: error)
                    }
                    return
                }
            }
        }
    }
}

// MARK: - Application Certificate
extension MRRFairplayRequester {
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
            .request(url, method: .get)
            .validate()
            .rawResponse{ [weak self] _, _, data, error in
                if let error = error {
                    callback(nil, .fairplay(reason: .networking(error: error)))
                    return
                }
                
                if let success = data {
                    do {
                        let certificate = try self?.parseApplicationCertificate(response: success)
                        callback(certificate, nil)
                    }
                    catch {
                        // parseApplicationCertificate will only throw PlayerError
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
    
    /// MRR Application Certificate response format is XML
    ///
    /// Success format
    /// ```xml
    /// <fps>
    ///    <checksum>82033743d5c0</checksum>
    ///    <version>1.2.3.400</version>
    ///    <hostname>host.example.com</hostname>
    ///    <cert>MIIExzCCA6+gAwIBAgIIVRMcpsYSxcIwDQYJKoZIhvcNAQEFBQAwfzELMAkGA1UE</cert>
    /// </fps>
    /// ```
    ///
    /// `<fps/><cert/>` Contains the Application Certificate as base64 encoded string
    ///
    ///
    /// Error format
    /// ```xml
    /// <error>
    ///    <checksum>82033743d5c0</checksum>
    ///    <version>1.2.3.400</version>
    ///    <hostname>Some host</hostname>
    ///    <code>500</code>
    ///    <message>Error message</message>
    /// </error>
    /// ```
    fileprivate func parseApplicationCertificate(response data: Data) throws -> Data {
        let xml = SWXMLHash.parse(data)
        // MRR Certifica
        if let certString = xml["fps"]["cert"].element?.text {
            // http://iosdevelopertips.com/core-services/encode-decode-using-base64.html
            guard let base64 = Data(base64Encoded: certString, options: Data.Base64DecodingOptions.ignoreUnknownCharacters) else {
                throw ExposureContext.Error.fairplay(reason: .applicationCertificateDataFormatInvalid)
            }
            return base64
        }
        else if let codeString = xml["error"]["code"].element?.text,
            let code = Int(codeString),
            let message = xml["error"]["message"].element?.text {
            
            throw ExposureContext.Error.fairplay(reason: .applicationCertificateServer(code: code, message: message))
        }
        throw ExposureContext.Error.fairplay(reason: .applicationCertificateParsing(error: nil))
    }
}

// MARK: - Content Key Context
extension MRRFairplayRequester {
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
        
        guard let playToken = entitlement.playToken else {
            callback(nil, .fairplay(reason: .missingPlaytoken))
            return
        }
        
        let headers = [
            "AzukiApp": playToken, // May not be needed
            "Content-type": "application/octet-stream"
        ]
        
        SessionManager
            .default
            .request(url,
                     method: .post,
                     data: spc,
                     headers: headers)
            .validate()
            .rawResponse{ _,_, data, error in
                if let error = error {
                    callback(nil, .fairplay(reason:.networking(error: error)))
                    return
                }
                
                if let success = data {
                    do {
                        let ckc = try self.parseContentKeyContext(response: success)
                        callback(ckc, nil)
                    }
                    catch {
                        // parseContentKeyContext will only throw PlayerError
                        callback(nil, error as? ExposureContext.Error)
                    }
                }
        }
    }
    
    /// Retrieve the `licenseUrl` by parsing the *entitlement*.
    internal var licenseUrl: URL? {
        guard let urlString = entitlement.fairplay?.licenseAcquisitionUrl else { return nil }
        return URL(string: urlString)
    }
    
    /// MRR Content Key Context response format is XML
    ///
    /// Success format
    /// ```xml
    /// <fps>
    ///    <checksum>82033743d5c0</checksum>
    ///    <version>1.2.3.400</version>
    ///    <hostname>host.example.com</hostname>
    ///    <ckc>MIIExzCCA6+gAwIBAgIIVRMcpsYSxcIwDQYJKoZIhvcNAQEFBQAwfzELMAkGA1UE</cert>
    /// </fps>
    /// ```
    ///
    /// `<fps/><ckc/>` Contains the Application Certificate as base64 encoded string
    ///
    ///
    /// Error format
    /// ```xml
    /// <error>
    ///    <checksum>82033743d5c0</checksum>
    ///    <version>1.2.3.400</version>
    ///    <hostname>Some host</hostname>
    ///    <code>500</code>
    ///    <message>Error message</message>
    /// </error>
    /// ```
    fileprivate func parseContentKeyContext(response data: Data) throws -> Data {
        let xml = SWXMLHash.parse(data)
        if let ckc = xml["fps"]["ckc"].element?.text {
            // http://iosdevelopertips.com/core-services/encode-decode-using-base64.html
            guard let base64 = Data(base64Encoded: ckc, options: Data.Base64DecodingOptions.ignoreUnknownCharacters) else {
                throw ExposureContext.Error.fairplay(reason: .contentKeyContextDataFormatInvalid)
            }
            return base64
        }
        else if let codeString = xml["error"]["code"].element?.text,
            let code = Int(codeString),
            let message = xml["error"]["message"].element?.text {
            
            throw ExposureContext.Error.fairplay(reason: .contentKeyContextServer(code: code, message: message))
        }
        throw ExposureContext.Error.fairplay(reason: .contentKeyContextParsing(error: nil))
    }
}
