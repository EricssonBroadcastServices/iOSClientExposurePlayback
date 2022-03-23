//
//  ExposureContext+Error.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-01-30.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Player
import iOSClientExposure

extension ExposureContext {
    /// `ExposureContext` specific errors
    public enum Error: ExpandedError {
        /// Errors related to *Fairplay* `DRM` validation.
        case fairplay(reason: FairplayError)
        
        /// Errors originating from Exposure
        case exposure(reason: ExposureError)
    }
}

extension ExposureContext.Error {
    
    /// Errors associated with *Fairplay* can be categorized, broadly, into two types:
    /// * Fairplay server related *DRM* errors.
    /// * Application related.
    ///
    /// Server related issues most likely stem from an invalid or broken backend configuration. Application issues range from parsing errors, unexpected server response or networking issues.
    public enum FairplayError: ExpandedError {
        // MARK: Application Certificate
        /// Networking issues caused the application to fail while verifying the *Fairplay* DRM.
        case networking(error: Error)
        
        /// No `URL` available to fetch the *Application Certificate*. This is a configuration issue.
        case missingApplicationCertificateUrl
        
        /// The *Application Certificate* response contained an unexpected or invalid data format.
        ///
        /// `FairplayRequester` failed to decode the raw data, most likely due to a missmatch between expected and supplied data format.
        case applicationCertificateDataFormatInvalid
        
        /// *Certificate Server* responded with an error message.
        ///
        /// Details are expressed by `code` and `message`
        case applicationCertificateServer(code: Int, message: String)
        
        /// There was an error while parsing the *Application Certificate*. This is considered a general error
        ///
        /// `error` containes the underlying error
        case applicationCertificateParsing(error: Error?)
        
        /// `AVAssetResourceLoadingRequest` failed to prepare the *Fairplay* related content identifier. This should normaly be encoded in the resouce loader's `urlRequest.url.host`.
        case invalidContentIdentifier
        
        // MARK: Server Playback Context
        /// An `error` occured while the `AVAssetResourceLoadingRequest` was trying to obtain the *Server Playback Context*, `SPC`, key request data for a specific combination of application and content.
        ///
        /// ```swift
        /// do {
        ///     try resourceLoadingRequest.streamingContentKeyRequestData(forApp: certificate, contentIdentifier: contentIdentifier, options: resourceLoadingRequestOptions)
        /// }
        /// catch {
        ///     // serverPlaybackContext error
        /// }
        /// ```
        ///
        /// For more information, please consult Apple's documentation.
        case serverPlaybackContext(error: Error)
        
        // MARK: Content Key Context
        /// `FairplayRequester` could not fetch a *Content Key Context*, `CKC`, since the *license acquisition url* was missing.
        case missingContentKeyContextUrl
        
        /// `CKC`, *content key context*, request data could not be generated because the identifying `playToken` was missing.
        case missingPlaytoken
        
        /// The *Content Key Context* response data contained an unexpected or invalid data format.
        ///
        /// `FairplayRequester` failed to decode the raw data, most likely due to a missmatch between expected and supplied data format.
        case contentKeyContextDataFormatInvalid
        
        /// *Content Key Context* server responded with an error message.
        ///
        /// Details are expressed by `code` and `message`
        case contentKeyContextServer(code: Int, message: String)
        
        /// There was an error while parsing the *Content Key Context*. This is considered a general error
        ///
        /// `error` containes the underlying error
        case contentKeyContextParsing(error: Error?)
        
        /// *Content Key Context* server did not respond with an error not a valid `CKC`. This is considered a general error
        case missingContentKeyContext
        
        /// `FairplayRequester` could not complete the resource loading request because its associated `AVAssetResourceLoadingDataRequest` was `nil`. This indicates no data was being requested.
        case missingDataRequest
        
        // MARK: General
        /// Unable to set *contentType* to `AVStreamingKeyDeliveryPersistentContentKeyType` since no content information is requested for the `AVAssetResourceLoadingRequest`.
        case contentInformationRequestMissing
    }
}

extension ExposureContext.Error {
    /// Returns a unique message describing the error
    public var message: String {
        switch self {
        case .fairplay(reason: let reason): return reason.message
        case .exposure(reason: let error): return error.message
        }
    }
}

extension ExposureContext.Error {
    /// Returns detailed information about the error
    public var info: String? {
        switch self {
        case .fairplay(reason: let reason): return reason.info
        case .exposure(reason: let error): return error.info
        }
    }
}

extension ExposureContext.Error {
    /// Defines the `domain` specific code for the underlying error.
    public var code: Int {
        switch self {
        case .fairplay(reason: let reason): return reason.code
        case .exposure(reason: let error): return error.code
        }
    }
}

extension ExposureContext.Error {
    /// The specific error domain the error belongs to
    public var domain: String {
        switch self {
        case .fairplay(reason: let reason): return reason.domain
        case .exposure(reason: let reason): return reason.domain
        }
    }
}

extension ExposureContext.Error {
    public var underlyingError: Error? {
        switch self {
        case .fairplay(reason: let error): return error.underlyingError
        case .exposure(reason: let error): return error.underlyingError
        }
    }
}

extension ExposureContext.Error.FairplayError {
    public var message: String {
        switch self {
        // Application Certificate
        case .missingApplicationCertificateUrl: return "MISSING_APPLICATION_CERTIFICATE_URL"
        case .networking(error: ): return "FAIRPLAY_NETWORKING_ERROR"
        case .applicationCertificateDataFormatInvalid: return "APPLICATION_CERTIFICATE_DATA_FORMAT_INVALID"
        case .applicationCertificateServer(code: _, message: _): return "APPLICATION_CERTIFICATE_SERVER_ERROR"
        case .applicationCertificateParsing: return "APPLICATION_CERTIFICATE_PARSING_ERROR"
        case .invalidContentIdentifier: return "INVALID_CONTENT_IDENTIFIER"
            
        // Server Playback Context
        case .serverPlaybackContext(error: _): return "SERVER_PLAYBACK_CONTEXT_ERROR"
            
        // Content Key Context
        case .missingContentKeyContextUrl: return "MISSING_CONTENT_KEY_CONTEXT_URL"
        case .missingPlaytoken: return "MISSING_PLAYTOKEN"
        case .contentKeyContextDataFormatInvalid: return "CONTENT_KEY_CONTEXT_DATA_FORMAT_INVALID"
        case .contentKeyContextServer(code: _, message: _): return "CONTENT_KEY_CONTEXT_SERVER_ERROR"
        case .contentKeyContextParsing(error: _): return "CONTENT_KEY_CONTEXT_PARSING_ERROR"
        case .missingContentKeyContext: return "MISSING_CONTENT_KEY_CONTEXT"
        case .missingDataRequest: return "MISSING_DATA_REQUEST"
        case .contentInformationRequestMissing: return "CONTENT_INFORMATION_REQUEST_MISSING"
        }
    }
}

extension ExposureContext.Error.FairplayError {
    /// Returns detailed information about the error
    public var info: String? {
        switch self {
        // Application Certificate
        case .missingApplicationCertificateUrl: return "Application Certificate Url not found"
        case .networking(error: let error): return condensedInfo(error: error) ?? "Networking Error"
        case .applicationCertificateDataFormatInvalid: return "Certificate Data was not encodable using base64"
        case .applicationCertificateServer(code: let code, message: let message): return "Application Certificate server returned error: \(code) with message: \(message)"
        case .applicationCertificateParsing(error: let error): return condensedInfo(error: error) ?? "Unable to parce Application Certificate"
        case .invalidContentIdentifier: return "Invalid Content Identifier"
            
        // Server Playback Context
        case .serverPlaybackContext(error: let error): return condensedInfo(error: error) ?? "Server Playback Context Error"
            
        // Content Key Context
        case .missingContentKeyContextUrl: return "Content Key Context Url not found"
        case .missingPlaytoken: return "Content Key Context call requires a playtoken"
        case .contentKeyContextDataFormatInvalid: return "Content Key Context was not encodable using base64"
        case .contentKeyContextServer(code: let code, message: let message): return "Content Key Context server returned error: \(code) with message: \(message)"
        case .contentKeyContextParsing(error: let error): return condensedInfo(error: error) ?? "Content Key Context server response lacks parsable data"
        case .missingContentKeyContext: return "Content Key Context missing from response"
        case .missingDataRequest: return "Data Request missing"
        case .contentInformationRequestMissing: return "Unable to set contentType on contentInformationRequest"
        }
    }
    
    private func condensedInfo(error: Error?) -> String? {
        guard let error = error else { return nil }
        if let networkingError = error as? iOSClientExposure.Request.Networking {
            var message = "[\(networkingError.code):\(networkingError.domain)] \n "
            message += "[\(networkingError.message)] \n "
            return message
        }
        else if let nsError = error as? NSError  {
            var message = "[\(nsError.code):\(nsError.domain)] \n "
            message += "[\(nsError.debugDescription)] \n "
            
            if let uError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError, let uInfo = condensedInfo(error: uError) {
                message += uInfo
            }
            return message
        }
        return "[" + error.localizedDescription + "]"
    }
}

extension ExposureContext.Error.FairplayError {
    /// Defines the `domain` specific code for the underlying error.
    public var code: Int {
        switch self {
        case .applicationCertificateDataFormatInvalid: return 301
        case .applicationCertificateParsing(error: _): return 302
        case .applicationCertificateServer(code: _, message: _): return 303
        case .contentKeyContextDataFormatInvalid: return 304
        case .contentKeyContextParsing(error: _): return 305
        case .contentKeyContextServer(code: _, message: _): return 306
        case .invalidContentIdentifier: return 307
        case .missingApplicationCertificateUrl: return 308
        case .missingContentKeyContext: return 309
        case .missingContentKeyContextUrl: return 310
        case .missingDataRequest: return 311
        case .missingPlaytoken: return 312
        case .networking(error: _): return 313
        case .serverPlaybackContext(error: _): return 314
        case .contentInformationRequestMissing: return 315
        }
    }
}

extension ExposureContext.Error.FairplayError {
    public var underlyingError: Error? {
        switch self {
        case .applicationCertificateDataFormatInvalid: return nil
        case .applicationCertificateParsing(error: let error): return error
        case .applicationCertificateServer(code: let code, message: let message): return FairplayServerError.certificateError(code: code, serverMessage: message)
        case .contentKeyContextDataFormatInvalid: return nil
        case .contentKeyContextParsing(error: let error): return error
        case .contentKeyContextServer(code: let code, message: let message): return FairplayServerError.licenseError(code: code, serverMessage: message)
        case .invalidContentIdentifier: return nil
        case .missingApplicationCertificateUrl: return nil
        case .missingContentKeyContext: return nil
        case .missingContentKeyContextUrl: return nil
        case .missingDataRequest: return nil
        case .missingPlaytoken: return nil
        case .networking(error: let error): return error
        case .serverPlaybackContext(error: let error): return error
        case .contentInformationRequestMissing: return nil
        }
    }
}

extension ExposureContext.Error.FairplayError {
    public var domain: String { return String(describing: type(of: self))+"Domain" }
}


extension ExposureContext.Error.FairplayError {
    public enum FairplayServerError: ExpandedError {
        
        /// The certificate request resulted in a server error
        ///
        /// - code: The server supplied error code
        /// - serverMessage: The server supplied error message
        case certificateError(code: Int, serverMessage: String)
        
        /// The license request resulted in a server error
        ///
        /// - code: The server supplied error code
        /// - serverMessage: The server supplied error message
        case licenseError(code: Int, serverMessage: String)
        
        /// Error code as described by the server
        public var code: Int {
            switch self {
            case .certificateError(code: let value, serverMessage: _): return value
            case .licenseError(code: let value, serverMessage: _): return value
            }
        }
        
        /// Human readable error message
        public var message: String {
            switch self {
            case .certificateError(code: _, serverMessage: _): return "FAIRPLAY_SERVER_CERTIFICATE_ERROR"
            case .licenseError(code: _, serverMessage: _): return "FAIRPLAY_SERVER_LICENSE_ERROR"
            }
        }
        
        /// The fairplay server error domain
        public var domain: String {
            return "FairplayServerErrorDomain"
        }
        
        /// Returns detailed information about the server error, if available
        public var info: String? {
            switch self {
            case .certificateError(code: _, serverMessage: let value): return value
            case .licenseError(code: _, serverMessage: let value): return value
            }
        }
    }
}
