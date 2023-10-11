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

    var tmpTaskIdentifierArray: [Int] = []
    
    let assetId: String
    init(assetId: String) {
        self.assetId = assetId
    }
    
    public func downloadImagesInQue(urlStrings: [String], quality: JPEGQuality) {
        
        //  queue.maxConcurrentOperationCount = 4
        
        // clean tmp cache if available
        let _ = self.cleanTmpCache()
        
        let _ = ImageFileManager(assetId: assetId).createDirectory()
        
        let urls = urlStrings.compactMap { URL(string: $0) }
        
        let completion = BlockOperation {
            // print(" All images are downloaded ")
        }

        // clear tmpTaskIdentifierArray
        tmpTaskIdentifierArray.removeAll()
        
        for url in urls {
            let downloadTask = DownloadOperation(session: downloadSession, url: url, assetId: assetId, qulaity: quality)
            
            // keep track of current download tasks
            tmpTaskIdentifierArray.append(downloadTask.task.taskIdentifier)
            queue.addOperation(downloadTask)
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
            } else {
                // print(" Assigninig image to UIImage was failed ")
                completion(nil,nil)
                
            }
        } else {
            // print(" spriteImageName could not be found " )
            completion(nil, nil)
        }
    }
    
    /// Remove the temp folder created to save the sprite images. This will delete all the sprite images as well
    internal func removeDownloadedSprites() {
        do {
            if let file = ImageFileManager(assetId: assetId).getDirectoryUrl() {
                try FileManager.default.removeItem(at: file)
            }
        } catch {
            // print("Error in removeDownloadedSprites " , error)
        }
    }
    
    
    
    /// Remove all the .tmp files created inside the tmp folder when doing URLRequests
    internal func cleanTmpCache() {
        do {
            let tmpDirURL = FileManager.default.temporaryDirectory
            let tmpDirectory = try FileManager.default.contentsOfDirectory(atPath: tmpDirURL.path)
            try tmpDirectory.forEach { file in
                let fileUrl = tmpDirURL.appendingPathComponent(file)
                try FileManager.default.removeItem(atPath: fileUrl.path)
            }
        } catch {
            // print(" Error in cleanTmpCache " , error )
        }
    }
    
    
    /// Cancel all downloads
    internal func cancelAllDownloads() {
        for operation in queue.operations {
            operation.cancel()
        }
        
        downloadSession.getAllTasks { tasks in
            for task in tasks {
                if self.tmpTaskIdentifierArray.contains(task.taskIdentifier) { task.cancel() }
            }
        }
        queue.cancelAllOperations()
    }
}








