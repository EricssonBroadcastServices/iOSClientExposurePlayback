//
//  ServerSideAdService.swift
//  ExposurePlayback
//
//  Created by Udaya Sri Senarathne on 2021-07-20.
//  Copyright © 2021 emp. All rights reserved.
//

import Foundation
import Exposure
import Player
import AVKit


fileprivate struct TimelineContent:Equatable {
    let contentType: String?
    let contentTitle: String?
    let contentStartTime: Double
    let contentEndTime: Double
    var isWatched: Bool
    let timeRange: CMTimeRange
    
    init(contentType: String? = nil, contentTitle: String? = nil , contentStartTime: Double, contentEndTime:Double, isWatched: Bool = false, timeRange: CMTimeRange) {
        self.contentType = contentType
        self.contentTitle = contentTitle
        self.contentStartTime = contentStartTime
        self.contentEndTime = contentEndTime
        self.isWatched = isWatched
        self.timeRange = timeRange
    }
}


public class ServerSideAdService: AdService {
    
    let ads: Ads
    let clips:[AdClips]
    let context: ExposureContext
    let source: ExposureSource
    let durationInMs: Double
    let tech: HLSNative<ExposureContext>
    
    let policy = ContractRestrictionsPolicy()
    
    fileprivate var allTimelineContent : [TimelineContent] = []
    
    /// This will store all the ads that are already played during the current session
    fileprivate var tempAdTimeLine: [TimelineContent] = []

    
    /// Whenver content type is not an`ad` append the first item from `tempAdMarkerPositions` & reset `tempAdMarkerPositions` array.
    private var adMarkerPositions: [MarkerPoint] = []
    
    /// This will be used to store Ad marker positions temporary, when there are multiple `adMarkers` `tempAdMarkerPositions` will hold them until next clip is not an `ad` , then append the first item to the `adMarkerPositions` array.
    ///
    /// Note:- Reason for this is to show only the first adMarker in the timeline.
    private var tempAdMarkerPositions: [MarkerPoint] = []
    
    
    private var timeInterval: Double = 0
    private var timer : Timer?
    private var clipIndexToPlayNow: Int = 0
    
    #if TARGET_OS_TV
    private var avInterstitialTimeRange = [AVInterstitialTimeRange]()
    #endif
    
    var shouldSkipAd: Bool = false
    
    /// Use this as a temporary to store user's scrubed / seek destiantion. When there is an `ad` in between current location & scrubbed destination , sdk will first play the `ad` & then jump to this scrubbed destination
    private var scrubbedDestination: Int64 = 0
    
    
    /// Seek starting position
    private var scrubbedFromPosition: Int64 = 0
    
    
    /// This will hold the state of the seek : ex : If an `ad` should be skipped this will be `true` as SDK decided the seek. If the seek is initiated by the user this will `false`
    private var isSDKInitatedSeek: Bool = false
    
    public init(ads: Ads, clips:[AdClips], context: ExposureContext, source: ExposureSource, durationInMs: Double, tech: HLSNative<ExposureContext>) {
        self.ads = ads
        self.context = context
        self.source = source
        self.durationInMs = durationInMs
        self.tech = tech
        self.clips = clips
    }
    
    public func playbackReady() {
        // print(" Play back ready ")
    }
    
    public func playbackStarted() {
        
        self.tempAdTimeLine.removeAll()
        
        self.prepareAdService()
        self.startAdService()
    }
    
    public func playbackEnded() {
        timer?.invalidate()
        
    }
    
    public func playbackPaused() {
        self.timer?.invalidate()
    }
    
    public func playbackResumed() {
        self.startAdPlaybackTimer(clipIndexToStart: self.clipIndexToPlayNow, startTimeInterval: self.timeInterval, clip: clips[self.clipIndexToPlayNow])
        
    }
    
    public func playbackFailed(error: NSError) {
        self.timer?.invalidate()
    }
    
    public func playbackBufferingStarted() {
        // print(" playbackBufferingStarted")
    }
    
    public func playbackBufferingEnded() {
        // print(" playbackBufferingEnded")
    }
    
    
    /// Seek request intiated / scrubing started
    /// - Parameter origin: fromPosition
    public func seekRequestInitiated(fromPosition origin: Int64) {
        self.scrubbedFromPosition = origin
    }
    
    
    
    /// Seek request Triggered / scrub ended
    /// - Parameter destination: withTargetPosition
    public func seekRequestTriggered(withTargetPosition destination: Int64) {
        // print(" seekRequestInitiated " , destination )
        
        
        self.timer?.invalidate()
        self.scrubbed(withTargetPosition: destination)
        
    }
    
    public func playbackTimedMetadata(metaData: Any?) {
        // print(" playbackTimedMetadata " , (metaData: Any?) )
    }
    
    public var playerProxy: AdPlayerProxy?
    
    public func prepareAsset(source: URL, callback: @escaping (URL) -> Void) {
        // print(" prepareAsset")
    }
    
    public func prepareProgram(source: URL, callback: @escaping (URL) -> Void) {
        // print(" prepareProgram")
    }
    
    public func prepareChannel(source: URL, callback: @escaping (URL) -> Void) {
        // print(" prepareChannel")
    }
    
    public var contractRestrictionsService: ContractRestrictionsService?
    
    private func getNextClip( index:Int,_ completion: @escaping (Int?) -> Void) { }
    
    
    
    /// Player intiated a seek to destination
    /// - Parameter destination: destination
    private func scrubbed(withTargetPosition destination: Int64) {
        
        
         print(" Scrubbed  " , self.scrubbedDestination )
        
        
            
            // Find the from / current seek position
            print(" Destination " , destination )
            print(" Current Play head time  " , self.tech.playheadTime )
            print(" Current Play headPosition " , self.tech.playheadPosition )
            print(" Time interval " , self.timeInterval )
            
            let oldTime = self.scrubbedFromPosition != 0 ? self.scrubbedFromPosition : Int64(self.timeInterval)
            
            
            let seekRange = CMTimeRange(start: CMTime(milliseconds: oldTime), end: CMTime(milliseconds: destination))
            
            print(" seekRange " , seekRange )
            
            let matchingInterstitialRange = self.allTimelineContent.reversed().first { seekRange.containsTimeRange($0.timeRange) && $0.contentType == "ad" }
            
            let matchingIndex = self.allTimelineContent.firstIndex(where:  { $0 == matchingInterstitialRange })
            
            print(" Found matching Ad " , matchingInterstitialRange?.contentTitle )
            
            if matchingInterstitialRange != nil && matchingIndex != nil  {
                
                if let seekTimeInMiliseconds = matchingInterstitialRange?.timeRange.start.milliseconds, let index = matchingIndex {
                    
                    if self.scrubbedDestination == 0  {
                        
                        
                        let adClip = self.allTimelineContent[index]
                        if !(self.tempAdTimeLine.contains(adClip)) {
                        //if matchingInterstitialRange?.isWatched == false {
                            
                            print(" Found Ad was not watched before ")
                            self.scrubbedDestination = destination
                            
                            self.clipIndexToPlayNow = index
                            self.timeInterval = Double(seekTimeInMiliseconds)
                            self.context.onServerSideAdShouldSkip(Double(seekTimeInMiliseconds))
                            
                            
                            // self.startAdPlaybackTimer(clipIndexToStart: index, clips: clips, startTimeInterval: Double(seekTimeInMiliseconds))
                            // tech.seek(toPosition: seekTimeInMiliseconds)
                            // self.startAdPlaybackTimer(clipIndexToStart: index, clips: clips, startTimeInterval: Double(seekTimeInMiliseconds))
                            
                        } else {
                            skipAlreadyPlayedAd()
                        }
                    } else {
                        print(" SCRUB DESTINATION IS NOT 0 , Means We Need TO SKIP TO THE USER'S SCRUB DESTINATION : \(destination)")
                        
                        if let index = self.allTimelineContent.firstIndex(where:  { $0.timeRange.containsTime(CMTime(milliseconds: destination)) }) {
                            self.timer?.invalidate()
                            self.clipIndexToPlayNow = index
                            self.timeInterval = Double(destination)
                            self.startAdPlaybackTimer(clipIndexToStart: index, startTimeInterval: Double(destination), clip: clips[index])
                            
                        }
                    }

                    
                }
            } else {
                // print(" Scrub destination is 0 & matchingInterstitialRange is Nil, this should be not an Ad ")
                
                if let matchingIndex = self.allTimelineContent.firstIndex(where:  { $0.timeRange.containsTime(CMTime(milliseconds: destination)) }) {
                    
                    // print(" Found matchingIndex " , matchingIndex )
                    self.scrubbedDestination = 0
                    self.clipIndexToPlayNow = matchingIndex
                    
                    self.timeInterval = Double(destination)
                    
                    
                    self.startAdPlaybackTimer(clipIndexToStart: matchingIndex, startTimeInterval: Double(destination), clip: clips[matchingIndex])
                    
                }
            }

    }
    
    
    /// Start Ad service when play back starts
    private func startAdService() {
        if let firstClip = clips.first {
            self.startAdPlaybackTimer(clipIndexToStart: self.clipIndexToPlayNow, startTimeInterval: 0, clip: firstClip )
        } else {
            // print(" can not find first clip of AdClips ")
        }
        
    }
    
    
    fileprivate func handleAdClipPlay(_ clip: AdClips, _ clipFirstQuartile: Double, _ clipMidpoint: Double, _ clipThirdQuartile: Double, _ clipEndTime: Double, _ content: TimelineContent, _ clipIndexToStart: Int) {
        policy.fastForwardEnabled = false
        policy.rewindEnabled = false
        policy.timeshiftEnabled = self.source.entitlement.timeshiftEnabled
        self.source.contractRestrictionsService.contractRestrictionsPolicy = policy
        
        self.context.onWillPresentInterstitial(self.source.contractRestrictionsService, false, nil)
        
        self.adTracking(adTrackingUrls: clip.impressionUrlTemplates ?? [] )
        
        // Starting timer
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true) { timer in
            self.timeInterval += 1
            
            if Int(self.timeInterval) == Int(clipFirstQuartile)  {
                
                // Send firstQuartile tracking events
                self.adTracking(adTrackingUrls: clip.trackingEvents?.firstQuartile ?? [] )
                
            } else if Int(self.timeInterval) == Int(clipMidpoint)  {
                
                // Send clipMidpoint tracking events
                self.adTracking(adTrackingUrls: clip.trackingEvents?.midpoint ?? [] )
                
            } else if Int(self.timeInterval) == Int(clipThirdQuartile)  {
                
                // Send thirdQuartile tracking events
                self.adTracking(adTrackingUrls: clip.trackingEvents?.thirdQuartile ?? [] )
                
            } else if Int(self.timeInterval) == Int(clipEndTime)  {
                
                
                let timeRange = CMTimeRange(start: CMTime(milliseconds: Int64(content.contentStartTime)), end: CMTime(milliseconds: Int64(content.contentEndTime)))
                
                self.allTimelineContent[clipIndexToStart] = TimelineContent(contentType: content.contentType, contentTitle: content.contentTitle, contentStartTime: content.contentStartTime, contentEndTime: content.contentEndTime, isWatched: true, timeRange: timeRange)
                
                self.policy.fastForwardEnabled = self.source.entitlement.ffEnabled
                self.policy.rewindEnabled = self.source.entitlement.rwEnabled
                self.policy.timeshiftEnabled = self.source.entitlement.timeshiftEnabled
                self.source.contractRestrictionsService.contractRestrictionsPolicy = self.policy
                self.context.onDidPresentInterstitial(self.source.contractRestrictionsService)
                
                // Send complete tracking events
                self.adTracking(adTrackingUrls: clip.trackingEvents?.complete ?? [] )
                
                // add this clip as already played ad
                self.tempAdTimeLine.append(self.allTimelineContent[clipIndexToStart])
                
                // We have a predefined scrub destination , player should skipped to this position
                if self.scrubbedDestination != 0 {
                    self.timer?.invalidate()
                    // print(" Ad was done, but previously assigned scrub destination is available , should skip to that position ")
                    let destination = self.scrubbedDestination
                    self.scrubbedDestination = 0
                    self.context.onServerSideAdShouldSkip(Double(destination))
                    
                    
                } else {
                    
                    // If we don't have a predefined scrub destination, find the next clip & start the timer for that clip
                    if (self.clipIndexToPlayNow + 1) < self.allTimelineContent.count {
                        self.clipIndexToPlayNow = self.clipIndexToPlayNow + 1
                        
                        self.timer?.invalidate()
                        
                        self.startAdPlaybackTimer(clipIndexToStart: self.clipIndexToPlayNow , startTimeInterval: content.contentEndTime, clip: self.clips[self.clipIndexToPlayNow])
                    } else {
                        self.timer?.invalidate()
                    }
                }
            }
        }
    }
    
    fileprivate func skipAlreadyPlayedAd() {
         print(" Clip is an Ad , but was watched before, so Find the next Vod / Live clip ")
        
        // Find the next available vod clip
        for (index, clip) in allTimelineContent.enumerated().dropFirst(clipIndexToPlayNow) {
            if clip.contentType == "ad" && clip.isWatched == true {
                continue
            } else if(clip.contentType == "ad" && clip.isWatched == false ) {
                continue
            }
            else if (clip.contentType != "ad") {
                self.clipIndexToPlayNow = index
                self.timeInterval = clip.contentStartTime + 1
                self.scrubbedDestination = Int64(clip.contentStartTime + 1 )
                self.context.onServerSideAdShouldSkip(clip.contentStartTime + 1 )
                break
            }
            else {
                print(" All the clips are done , scrubbed to the end of the timeline ")
                self.clipIndexToPlayNow = index
                self.timeInterval = clip.contentStartTime
                self.scrubbedDestination = Int64(clip.contentEndTime)
                self.context.onServerSideAdShouldSkip(clip.contentEndTime)
            }
        }
    }
    
    /// Handles internal Timer that will start / stop / pause  depend on the player inputs
    /// - Parameters:
    ///   - clipIndexToStart: index of the clip to start from : allTimelineContent
    ///   - clips: Ads.Clips
    ///   - startTimeInterval: time interval that Timer should start from
    private func startAdPlaybackTimer( clipIndexToStart: Int = 0 , startTimeInterval: Double = 0, clip: AdClips) {
        
        self.timer?.invalidate()
        
        self.timeInterval = startTimeInterval
        
        self.clipIndexToPlayNow = clipIndexToStart
        
        // let clip = clips[clipIndexToStart]
        
        //        print(" Clip INdex to start " , self.clipIndexToPlayNow )
        //
        //        print(" allTimelineContent.count " , allTimelineContent.count )
        //
        //
        
        if clipIndexToStart < allTimelineContent.count {
            
            
            let content = allTimelineContent[clipIndexToStart]
            
            let clipStartTime = content.contentStartTime
            let clipEndTime = content.contentEndTime
            
            print(" clipStartTime " , clipStartTime )
            print(" clipEndTime " , clipEndTime )
            print(" clipStartTime " , content.timeRange.start.milliseconds )
            print(" clipEndTime " , content.timeRange.end.milliseconds )
            
            print(" timeInterval => " , Int(timeInterval))
            print(" Int(clipStartTime) ", Int(clipStartTime))
            print(" Int(clipStartTime) ", Int(clipEndTime))
            print(" Content type " , content.contentType )
            
            // New Clip Duration is , clip start time & the duration
            // let clipDuration = clipStartTime + Double(duration)
            let duration = clipEndTime - clipStartTime
            
            let clipFirstQuartile =  clipStartTime + Double(duration)/4
            let clipMidpoint = clipStartTime + Double( duration)/2
            let clipThirdQuartile = clipStartTime + ( Double(duration) * 3/4)
            
            // Check if the pre roll is an ad
            if content.contentType == "ad" && Int(timeInterval)  == Int(clipStartTime) {
                
                if !(self.tempAdTimeLine.contains(content)) {
                    
                // if content.isWatched == false {
                    
                    handleAdClipPlay(clip, clipFirstQuartile, clipMidpoint, clipThirdQuartile, clipEndTime, content, clipIndexToStart)
                }
                
                // Clip is an Ad , but was watched before, so Find the next Vod / Live clip
                else {
                    
                    skipAlreadyPlayedAd()
                }
            } else if (content.contentType == "ad" && (Int(clipStartTime) < Int(timeInterval) && Int(timeInterval) < Int(clipEndTime))) {
                    print(" Else If ")
                if !(self.tempAdTimeLine.contains(content)) {
                    handleAdClipPlay(clip, clipFirstQuartile, clipMidpoint, clipThirdQuartile, clipEndTime, content, clipIndexToStart)
                } else {
                    print(" This Ad was already played ")
                    skipAlreadyPlayedAd()
                }
            }
            
            // Clip is a not an Ad
            else if content.contentType != "ad" {
                
                // Starting timer
                self.timer = Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true) { timer in
                    self.timeInterval += 1
                    
                    self.context.onClipStarted(Int64(self.timeInterval), Int64(content.contentEndTime))
                    
                    // When the clip ends, find the next clip & start the timer for that clip
                    if Int(self.timeInterval) == Int(clipEndTime) {
                        if self.clipIndexToPlayNow + 1 < self.allTimelineContent.count {
                            self.clipIndexToPlayNow = self.clipIndexToPlayNow + 1
                            self.timer?.invalidate()
                            self.startAdPlaybackTimer(clipIndexToStart: self.clipIndexToPlayNow ,startTimeInterval:  content.contentEndTime, clip: self.clips[self.clipIndexToPlayNow] )
                        } else {
                            self.timer?.invalidate()
                        }
                        
                        self.context.onClipEnded(Int64(content.contentStartTime), Int64(content.contentEndTime))
                    }
                }
            }
            
            // Should not happen , but keep the fall back as playing a any clip
            else {
                self.timeInterval = content.contentStartTime
                
                // Starting timer
                self.timer = Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true) { timer in
                    self.timeInterval += 1
                    
                    self.context.onClipStarted(Int64(self.timeInterval), Int64(content.contentEndTime))
                    
                    // print(" Now running a vod clip => " , Int(self.timeInterval) )
                    if  Int(self.timeInterval) == Int(clipEndTime) {
                        
                        if self.clipIndexToPlayNow + 1 < self.allTimelineContent.count {
                            self.clipIndexToPlayNow = self.clipIndexToPlayNow + 1
                            self.timer?.invalidate()
                            self.startAdPlaybackTimer(clipIndexToStart: self.clipIndexToPlayNow, startTimeInterval:  content.contentEndTime, clip: self.clips[self.clipIndexToPlayNow] )
                        } else {
                            self.timer?.invalidate()
                        }
                        
                        self.context.onClipEnded(Int64(content.contentStartTime), Int64(content.contentEndTime))
                    }
                }
            }
        } else {
            // print(" All the clips were played")
        }
    }
    
    /// Prepare Ad service with initial clips & timeline content
    private func prepareAdService() {
        
        var vodDuration: Int64 = 0
        var totalDuration : Float = 0
        
        // Reset admarker arrays
        self.adMarkerPositions.removeAll()
        self.tempAdMarkerPositions.removeAll()
        
        if let clips = self.ads.clips {
            
            // Total Duration in miliseconds
            totalDuration = clips.compactMap { Float($0.duration ?? 0) }.reduce(0, +)
            
            var currentDuration : Float = 0
            
            for (index,clip) in clips.enumerated() {
                
                // Add the clip duration to currentTotalDuration
                if let duration = clip.duration   {
                    
                    let clipStartTime = Double(currentDuration)
                    let clipEndTime = Double(currentDuration + duration )
                    
                    let timeRange = CMTimeRange(start: CMTime(milliseconds: Int64(clipStartTime)), end: CMTime(milliseconds: Int64(clipEndTime)))
                    
                    let timelineContent = TimelineContent(contentType: clip.category, contentTitle: clip.title, contentStartTime: clipStartTime, contentEndTime: clipEndTime, timeRange: timeRange)
                    
                    allTimelineContent.append(timelineContent)
                    currentDuration = currentDuration + duration
                    
                    // Clip is not an ad , add it to vodDuration
                    if clip.category != "ad" {
                        vodDuration = vodDuration + Int64(duration)
                        
                        // get the first time from the tempAdMarkerPositions & add it to marker positions
                        if let adMarkerClip = tempAdMarkerPositions.first {
                            self.adMarkerPositions.append(adMarkerClip)
                            tempAdMarkerPositions.removeAll()
                        }
                        
                    }
                    
                    // Clips is an ad, should add an adMarker to the timeLine on ad starting point
                    else if clip.category == "ad" {
                        if index == 0 {
                            let markerPoint = MarkerPoint(type: "Ad", offset: 0, endOffset: (Int(duration)) )
                            
                            // If the first clip is an Ad, we directly Ad it
                            self.tempAdMarkerPositions.append(markerPoint)
                            
                        } else if index != 0 && index != clips.count {
                            
                            let markerPoint = MarkerPoint(type: "Ad", offset: Int(currentDuration), endOffset: Int(currentDuration + duration))
                            self.tempAdMarkerPositions.append(markerPoint)
                            
                            // check if the just previous clip was an Ad, if so we will skip it
                            /* let previousClip = clips[index - 1]
                             if previousClip.category != "ad" {
                             let markerPoint = MarkerPoint(type: "Ad", offset: Int(currentDuration), endOffset: Int(currentDuration + duration))
                             self.adMarkerPositions.append(markerPoint)
                             } */
                            
                        } else if index == clips.count {
                            // If the last clip is an Ad, we directly Add to the `adMarkerPositions` array as there will not be any other clips, no need to store marker point in temp array
                            
                            // print("index == clips.count \( index) ")
                            let markerPoint = MarkerPoint(type: "Ad", offset: Int(currentDuration), endOffset: Int(totalDuration))
                            self.adMarkerPositions.append(markerPoint)
                            self.tempAdMarkerPositions.removeAll()
                        }
                        else {
                            // print(" Clip type is an Ad, but something is wrong with index & clip duration")
                        }
                    } else {
                        // print(" Clip Category is not vos neither Ad , it is \(clip.category)")
                    }
                    
                } else {
                    // print(" Clip duration is not available : clip category \(clip.category) & clip title \(clip.title) & clip titleId \(clip.titleId)" )
                }
            }
            
            context.onPlaybackStartWithAds(vodDuration, totalDuration, adMarkerPositions )
        }
    }
    
    #if TARGET_OS_TV
    
    #endif
}


extension ServerSideAdService {
    
    /// Call ad tracking urls
    /// - Parameter adTrackingUrls: ad tracking urls
    fileprivate func adTracking(adTrackingUrls: [String]) {
        let group = DispatchGroup()
        
        for url in adTrackingUrls {
            group.enter()
            if let adTrackingUrl = URL(string: url) {
                let task = URLSession.shared.dataTask(with: adTrackingUrl) { data, response, error in
                    if let _ = response as? HTTPURLResponse {
                        // print(" Ad tracking was success" )
                    }
                    group.leave()
                }
                task.resume()
            } else {
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            // print(" All the ad tracking beacons were sent to backend")
        }
    }
    
}
