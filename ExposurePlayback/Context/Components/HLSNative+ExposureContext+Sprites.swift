//
//  HLSNative+ExposureContext+Sprites.swift
//  ExposurePlayback
//
//  Created by Udaya Sri Senarathne on 2021-01-29.
//  Copyright © 2021 emp. All rights reserved.
//

import Foundation
import Exposure
import Player

extension Player where Tech == HLSNative<ExposureContext> {
    
    /// Activate sprites with given width & quality
    /// - Parameters:
    ///   - assetId: asset Id
    ///   - width: width
    ///   - quality: JPEG Quality : lowest = 0 | low = 0.25 | medium  = 0.5 | high = 0.75 | highest = 1
    ///   - callback: completion SpriteData array
    /// - Returns: self
    public func activateSprites(assetId: String, width: Int? = nil, quality: JPEGQuality = .highest, callback: @escaping ([SpriteData]?, Error?) -> Void) -> Self   {
        
        /// Find if there is any vtt file with the given resolution / width
        if let data = UserDefaults.standard.value(forKey:"sprites") as? Data {
            
            let sprites = try? PropertyListDecoder().decode(Array<Sprites>.self, from: data)
            
            var spriteWidth = width
            // if the width is nil, assign the width of the first available sprite's width
            if width == nil { spriteWidth = sprites?.first?.width }
            
            let matchedSprite = sprites?.first(where: { $0.width == spriteWidth })

            if let url = matchedSprite?.vtt {

                // Remove any spritesData cache available in the UserDefaults
                UserDefaults.standard.removeObject(forKey: "spritesData")
      
                var spritedata = [SpriteData]()
                
                    if let url = URL(string: url) {
                        
                        // Fetch the vtt stream
                        let task = URLSession.shared.downloadTask(with: url) { localURL, urlResponse, error in
                            
                            if error == nil {
                                if let localURL = localURL {
                                    if let urlContent = try? String(contentsOf: localURL) {
                                        // print(urlContent)
                                        
                                        do {
                                            let webVTT = try WebVTTParser(string: urlContent, vttUrl: url).parse()
                                            
                                            var imageUrls = [String]()
                                            
                                            for cue in webVTT.cues {
                                                
                                                if let frame = cue.frame, let imageUrl = cue.imageUrl {
                                                    let sprite = SpriteData(duration: cue.duration, timelinePosition: cue.timing.start, startTime: cue.timeStart, endTime: cue.timeEnd, spriteImage: imageUrl, frame: frame)
                                                    spritedata.append(sprite)
                                                    
                                                    imageUrls.append(imageUrl)
                                                }
                                            }
                                            
                                            let imageDownloader = SpriteImageDownloader(assetId: assetId)
                                            imageDownloader.downloadImagesInQue(urlStrings: imageUrls, quality: quality)
                                            
                                            self.listenToPlayBackAbort(assetId)
 
                                            // sets all the spritesData in to the userDefaults
                                            UserDefaults.standard.set(try? PropertyListEncoder().encode(spritedata), forKey:"spritesData")
          
                                        } catch {
                                            callback(nil, ExposureError.generalError(error: error))
                                        }
                                        
                                    } else {
                                        let error = NSError(domain: "VTT stream content is missing", code: 51, userInfo: nil)
                                        callback(nil, ExposureError.generalError(error: error))
                                    }
                                } else {
                                    let error = NSError(domain: "VTT url is missing", code: 50, userInfo: nil)
                                    callback(nil, ExposureError.generalError(error: error))
                                }
                            } else {
                                // print(" vtt stream download task failed with an error")
                                callback(nil, error)
                            }
                            
                        }
                        task.resume()
                    }
            } else {
                let error = NSError(domain: "Coudn't find a vtt file with the given resolution", code: 55, userInfo: nil)
                callback(nil, ExposureError.generalError(error: error))
            }
        } else {
            let error = NSError(domain: "Sprites are empty in the session", code: 56, userInfo: nil)
            callback(nil, ExposureError.generalError(error: error))
        }

        return self
    }
}


extension Player where Tech == HLSNative<ExposureContext> {
    
    /// Get sprite image for give time & assetId
    /// - Parameters:
    ///   - time: current time
    ///   - assetId: assetId
    ///   - callback: completion : sprite image
    /// - Returns: self
        public func getSprite(time: String, assetId: String, callback: @escaping (UIImage?) -> Void) -> Self  {
            
            let timelineTime = time.convertToTimeInterval()

            // get the cached sprites from the userdefaults
            guard let data = UserDefaults.standard.value(forKey:"spritesData") as? Data else {
                callback(nil)
                return self
            }
                
            let sprites = try? PropertyListDecoder().decode(Array<SpriteData>.self, from: data)
            
            let matchedSprite = sprites?.first(where: { $0.startTime <= timelineTime && timelineTime <= $0.endTime })
            
            guard let x = matchedSprite?.frame.x , let y = matchedSprite?.frame.y , let width = matchedSprite?.frame.width, let height = matchedSprite?.frame.height, let imageUrl = matchedSprite?.spriteImage else {
                callback(nil)
                return self
            }
            
            let imageDownloader = SpriteImageDownloader(assetId: assetId)
            imageDownloader.loadImage(url: imageUrl, completion: { image , error in
                if let image = image {
                        guard let newCGImage = image.cgImage?.cropping(to: CGRect(x: x, y: y, width: width, height: height)) else { return }
                        
                        let newImage = UIImage.init(cgImage: newCGImage)
                        callback(newImage)
                   
                } else {
                    callback(nil)
                }
            })
            callback(nil)
        return self
    }
}

extension Player where Tech == HLSNative<ExposureContext> {
    
    /// Listner for play back abort
    /// - Parameter assetId: assetId
    public func listenToPlayBackAbort(_ assetId: String) {
        self.onPlaybackAborted(callback: {_,_ in
            let imageDownloader = SpriteImageDownloader(assetId: assetId)
            imageDownloader.removeDownloadedSprites()
            imageDownloader.cleanTmpCache()
            imageDownloader.cancelAllDownloads()
        })
    }
}
