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
import Alamofire

internal protocol ExposureFairplayRequester: class {
    /// Entitlement related to this specific *Fairplay* request.
    var entitlement: PlaybackEntitlement { get }
    
    /// The DispatchQueue to use for AVAssetResourceLoaderDelegate callbacks.
    var resourceLoadingRequestQueue: DispatchQueue { get }
    
    /// Options specifying the resource loading request
    var resourceLoadingRequestOptions: [String : AnyObject]? { get }
    
    /// The URL scheme for FPS content.
    var customScheme: String { get }
    
    /// Called when `CKC` data was successfully retrieved from remote server
    ///
    /// - parameter ckc: The `CKC` data retrieved from server
    /// - returns: Key data used to finalize the request
    func onSuccessfulRetrieval(of ckc: Data, for resourceLoadingRequest: AVAssetResourceLoadingRequest) throws-> Data
    
    func shouldContactRemote(for resourceLoadingRequest: AVAssetResourceLoadingRequest) throws -> Bool
}

extension ExposureFairplayRequester {
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

extension ExposureFairplayRequester {
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
                resourceLoadingRequest.finishLoading(with: ExposureError.fairplay(reason: .invalidContentIdentifier))
                return
        }
        
        
        
        print(url, " - ",assetIDString)
        
        fetchApplicationCertificate{ [unowned self] certificate, certificateError in
            print("fetchApplicationCertificate")
            if let certificateError = certificateError {
                print("fetchApplicationCertificate ",certificateError.message)
                resourceLoadingRequest.finishLoading(with: certificateError)
                return
            }
            
            if let certificate = certificate {
                print("prepare SPC")
                do {
                    let spcData = try resourceLoadingRequest.streamingContentKeyRequestData(forApp: certificate, contentIdentifier: contentIdentifier, options: self.resourceLoadingRequestOptions)
                    
                    // Content Key Context fetch from licenseUrl requires base64 encoded data
                    let spcBase64 = spcData.base64EncodedData(options: Data.Base64EncodingOptions.endLineWithLineFeed)
                    
                    self.fetchContentKeyContext(spc: spcBase64) { ckcBase64, ckcError in
                        print("fetchContentKeyContext")
                        if let ckcError = ckcError {
                            print("CKC Error",ckcError.localizedDescription, ckcError.message, ckcError.code)
                            resourceLoadingRequest.finishLoading(with: ckcError)
                            return
                        }
                        
                        guard let dataRequest = resourceLoadingRequest.dataRequest else {
                            print("dataRequest Error",ExposureError.fairplay(reason: .missingDataRequest).message)
                            resourceLoadingRequest.finishLoading(with: ExposureError.fairplay(reason: .missingDataRequest))
                            return
                        }
                        
                        guard let ckcBase64 = ckcBase64 else {
                            print("ckcBase64 Error",ExposureError.fairplay(reason: .missingContentKeyContext).message)
                            resourceLoadingRequest.finishLoading(with: ExposureError.fairplay(reason: .missingContentKeyContext))
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
                            print("onSuccessfulRetrieval Error",error)
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
                    print("SPC - ",error.localizedDescription)
                    resourceLoadingRequest.finishLoading(with: ExposureError.fairplay(reason: .serverPlaybackContext(error: error)))
                    return
                }
            }
        }
    }
}

// MARK: - Application Certificate
extension ExposureFairplayRequester {
    /// The *Application Certificate* is fetched from a server specified by a `certificateUrl` delivered in the *entitlement* obtained through *Exposure*.
    ///
    /// - note: This method uses a specialized function for parsing the retrieved *Application Certificate* from an *MRR specific* format.
    /// - parameter callback: fires when the certificate is fetched or when an `error` occurs.
    fileprivate func fetchApplicationCertificate(callback: @escaping (Data?, ExposureError?) -> Void) {
        guard let url = certificateUrl else {
            callback(nil, .fairplay(reason: .missingApplicationCertificateUrl))
            return
        }
        
        Alamofire
            .request(url, method: .get)
            .responseData{ [weak self] response in
                
                if let error = response.error {
                    callback(nil, .fairplay(reason: .networking(error: error)))
                    return
                }
                
                if let success = response.value {
                    do {
                        let certificate = try self?.parseApplicationCertificate(response: success)
                        callback(certificate, nil)
                    }
                    catch {
                        // parseApplicationCertificate will only throw PlayerError
                        callback(nil, error as? ExposureError)
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
                throw ExposureError.fairplay(reason: .applicationCertificateDataFormatInvalid)
            }
            return base64
        }
        else if let codeString = xml["error"]["code"].element?.text,
            let code = Int(codeString),
            let message = xml["error"]["message"].element?.text {
            
            throw ExposureError.fairplay(reason: .applicationCertificateServer(code: code, message: message))
        }
        throw ExposureError.fairplay(reason: .applicationCertificateParsing)
    }
}

// MARK: - Content Key Context
extension ExposureFairplayRequester {
    /// Fetching a *Content Key Context*, `CKC`, requires a valid *Server Playback Context*.
    ///
    /// - note: This method uses a specialized function for parsing the retrieved *Content Key Context* from an *MRR specific* format.
    ///
    /// - parameter spc: *Server Playback Context*
    /// - parameter callback: fires when `CKC` is fetched or when an `error` occurs.
    fileprivate func fetchContentKeyContext(spc: Data, callback: @escaping (Data?, ExposureError?) -> Void) {
        guard let url = licenseUrl else {
            callback(nil, .fairplay(reason: .missingContentKeyContextUrl))
            return
        }
        
        guard let playToken = entitlement.playToken else {
            callback(nil, .fairplay(reason: .missingPlaytoken))
            return
        }
        
        let headers = ["AzukiApp": playToken, // May not be needed
            "Content-type": "application/octet-stream"]
        
        Alamofire
            .upload(spc,
                    to: url,
                    method: .post,
                    headers: headers)
            .validate()
            .responseData{ response in
                if let error = response.error {
                    callback(nil, .fairplay(reason:.networking(error: error)))
                    return
                }
                
                if let success = response.value {
                    do {
                        let ckc = try self.parseContentKeyContext(response: success)
                        callback(ckc, nil)
                    }
                    catch {
                        // parseContentKeyContext will only throw PlayerError
                        callback(nil, error as? ExposureError)
                    }
                }
        }
    }
    
    /// Retrieve the `licenseUrl` by parsing the *entitlement*.
    fileprivate var licenseUrl: URL? {
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
                throw ExposureError.fairplay(reason: .contentKeyContextDataFormatInvalid)
            }
            return base64
        }
        else if let codeString = xml["error"]["code"].element?.text,
            let code = Int(codeString),
            let message = xml["error"]["message"].element?.text {
            
            throw ExposureError.fairplay(reason: .contentKeyContextServer(code: code, message: message))
        }
        throw ExposureError.fairplay(reason: .contentKeyContextParsing)
    }
    
}
