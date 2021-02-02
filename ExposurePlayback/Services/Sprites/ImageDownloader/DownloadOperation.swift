//
//  DownloadOperation.swift
//  ExposurePlayback
//
//  Created by Udaya Sri Senarathne on 2021-02-02.
//  Copyright © 2021 emp. All rights reserved.
//

import Foundation

/// Internal class for handling sprite image downloads & saving it in a application support directory
internal class DownloadOperation : AsynchronousOperation {
    var task: URLSessionTask!
    
    init(session: URLSession, url: URL, assetId:String, qulaity: JPEGQuality) {
        super.init()
        
        task = session.downloadTask(with: url) { temporaryURL, response, error in
            
            guard let temporaryURL = temporaryURL, error == nil else { return }
            do {
                /// Get the sprite image names
                if let spriteImageName = url.absoluteString.components(separatedBy: "/").last {
                    if let file = ImageFileManager(assetId: assetId).getDirectoryUrl() {
                        
                        /// Create sprite image name file url
                        let spriteImage =  file.appendingPathComponent(spriteImageName)
                        
                        /// Check if file already exsits in the directory, if so ignore saving
                        if !(FileManager.default.fileExists(atPath: spriteImage.path)) {
                            if let image = UIImage(contentsOfFile: temporaryURL.path) {
                                if let imageData = image.jpeg(qulaity) {
                                    try imageData.write(to: spriteImage)
                                }
                            }
                        }
                    } else {
                        print(" applicationSupportDirectory can not be find")
                    }
                }
            } catch {
                print(" Error in Download Operation ", error)
            }
            
        }
    }
    
    override func cancel() {
        task.cancel()
        super.cancel()
    }
    
    override func main() {
        task.resume()
    }
    
}
