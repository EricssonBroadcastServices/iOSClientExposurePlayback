//
//  VttImageDownloader.swift
//  ExposurePlayback
//
//  Created by Udaya Sri Senarathne on 2021-01-22.
//  Copyright © 2021 emp. All rights reserved.
//

import Foundation
import UIKit

/// Handle download / loading & removing sprite images
internal class SpriteImageDownloader {
    
    let queue = OperationQueue()
    let downloadSession = URLSession.shared
    
    let assetId: String
    init(assetId: String) {
        self.assetId = assetId
    }
    
    public func downloadImagesInQue(urlStrings: [String], quality: JPEGQuality) {
        
        queue.maxConcurrentOperationCount = 4
        
        let _ = ImageFileManager(assetId: assetId).createDirectory()
        
        let urls = urlStrings.compactMap { URL(string: $0) }

        let completion = BlockOperation {
                // print(" All images are downloaded ")
            }
        for url in urls {
            queue.addOperation(DownloadOperation(session: downloadSession, url: url, assetId: assetId, qulaity: quality))
        }

        OperationQueue.main.addOperation(completion)
    }
    
    public func loadImage(url: String, completion: @escaping (UIImage?, Error?) -> Void)  {
        
        if let spriteImageName = url.components(separatedBy: "/").last {
            
            if let file = ImageFileManager(assetId: assetId).getDirectoryUrl() {
                let spriteImage =  file.appendingPathComponent("\(spriteImageName)")
                // If the image exists in the cache,load the image from the cache and exit
                if let image = UIImage(contentsOfFile: spriteImage.path) {
                    completion(image, nil)
                    return
                }
            }
        }
    }
    
    /// Remove the temp folder created to save the sprite images. This will delete all the sprite images as well
    internal func removeDownloadedSprites() {
        do {
            if let file = ImageFileManager(assetId: assetId).getDirectoryUrl() {
                try FileManager.default.removeItem(at: file)
            }
        } catch {
            print("Error on removing the folder " , error)
        }
    }

    
    /// Cancel all downloads
    internal func cancelAllDownloads() {
        for operation in queue.operations {
            operation.cancel()
        }

        downloadSession.getAllTasks { tasks in
            for task in tasks {
                task.cancel()
            }
        }
        queue.cancelAllOperations()
    }
}








