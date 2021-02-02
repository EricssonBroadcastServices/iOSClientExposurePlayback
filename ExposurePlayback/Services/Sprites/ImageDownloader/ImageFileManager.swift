//
//  ImageFileManager.swift
//  ExposurePlayback
//
//  Created by Udaya Sri Senarathne on 2021-02-02.
//  Copyright © 2021 emp. All rights reserved.
//

import Foundation

/// Handle the directory which will be used to save sprite images
internal class ImageFileManager {
    
    let assetId: String
    let fileManager = FileManager.default
    
    init(assetId: String) {
        self.assetId = assetId
    }
    
    
    /// Create a directory with the given assetId
    func createDirectory() {
        guard let applicationSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        
        let applicationDirectoryUrl = applicationSupportDirectory.appendingPathComponent(Bundle.main.bundleIdentifier ?? "com.redbee.exposureplayback")
        
        do {
            let assetFolder = applicationDirectoryUrl.appendingPathComponent (assetId)
            try fileManager.createDirectory (at: assetFolder, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print(" Error in createDirectory" , error)
        }
    }
    
    
    /// Get the directory url for a given assetId
    /// - Returns: url
    func getDirectoryUrl() -> URL? {
        guard let applicationSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        
            let directoryURL = applicationSupportDirectory.appendingPathComponent(Bundle.main.bundleIdentifier ?? "com.redbee.exposureplayback")
            let documentURL = directoryURL.appendingPathComponent (assetId)
            return documentURL
    }
    
}
