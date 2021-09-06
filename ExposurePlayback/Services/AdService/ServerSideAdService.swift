//
//  ServerSideAdService.swift
//  ExposurePlayback
//
//  Created by Udaya Sri Senarathne on 2021-07-20.
//  Copyright © 2021 emp. All rights reserved.
//

import Foundation
import Exposure

fileprivate struct TimelineContent:Equatable {
    let contentType: String?
    let contentTitle: String?
    let contentStartTime: Double
    let contentEndTime: Double
    let isWatched: Bool
    
    init(contentType: String? = nil, contentTitle: String? = nil , contentStartTime: Double, contentEndTime:Double, isWatched: Bool = false ) {
        self.contentType = contentType
        self.contentTitle = contentTitle
        self.contentStartTime = contentStartTime
        self.contentEndTime = contentEndTime
        self.isWatched = isWatched
    }
}


public class ServerSideAdService: AdService {
    
    let ads: Ads
    let context: ExposureContext
    let source: ExposureSource
    let durationInMs: Double
    
    let policy = ContractRestrictionsPolicy()
    
    fileprivate var allTimelineContent : [TimelineContent] = []
    
    private var adMarkerPositions: [MarkerPoint] = []
    
    private var timeInterval: Double = 0
    private var timer : Timer?
    private var clipIndexToPlayNow: Int = 0
    
    var shouldSkipAd: Bool = false
    
    var scrubbedDestination: Int64 = 0
    
    public init(ads: Ads, context: ExposureContext, source: ExposureSource, durationInMs: Double ) {
        self.ads = ads
        self.context = context
        self.source = source
        self.durationInMs = durationInMs
    }
    
    public func playbackReady() {
        print(" Play back ready ")
    }
    
    public func playbackStarted() {
        print(" PlayBack Started")
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
        if let clips = ads.clips {
            self.startAdPlaybackTimer(clipIndexToStart: self.clipIndexToPlayNow, clips: clips, startTimeInterval: self.timeInterval)
        }
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
    
    public func seekRequestInitiated(fromPosition origin: Int64) {
        // print(" seekRequestInitiated " , origin)
    }
    
    public func seekRequestTriggered(withTargetPosition destination: Int64) {
        // print(" seekRequestInitiated " , destination )
        self.timer?.invalidate()
        self.scrubbed(withTargetPosition: destination)
        
    }
    
    public func playbackTimedMetadata(metaData: Any?) {
        
//        if let currentClip = allTimelineContent.filter( { $0.contentEndTime >= Double(self.timeInterval) && Double(self.timeInterval) >= $0.contentStartTime }).first {
//            if let index = allTimelineContent.indices.filter({allTimelineContent[$0] == currentClip}).first {
//
//                self.timer?.invalidate()
//                print(" Time metadata changed  , restart the timer ")
//                self.clipIndexToPlayNow = index
//                if let clips = ads.clips {
//                    self.startAdPlaybackTimer(clipIndexToStart: (index), clips: clips, startTimeInterval: self.timeInterval)
//                }
//            }
//        }
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
    
    private func getNextClip( index:Int,_ completion: @escaping (Int?) -> Void) {
        
        
        
    }
    
    
    /// Player intiated a seek to destination
    /// - Parameter destination: destination
    private func scrubbed(withTargetPosition destination: Int64) {

        // Check if previously assigned scrubbedDestination is available , this value will be assigned if an ad needs to be played before seeking to the vod / live content
        if (destination == self.scrubbedDestination ) {
            
            if let scrubbedContent = allTimelineContent.filter( { $0.contentEndTime >= Double(destination) && Double(destination) >= $0.contentStartTime }).first {
                if let index = allTimelineContent.indices.filter({allTimelineContent[$0] == scrubbedContent}).first {
                    self.clipIndexToPlayNow = index
                    self.timeInterval = Double(destination)
                    self.scrubbedDestination = 0
                    
                    if let clips = ads.clips {
                        self.startAdPlaybackTimer(clipIndexToStart: (index), clips: clips, startTimeInterval: Double(destination))
                    }
                }
            }
        }
        
        // Check if the player seeked to a future position
        else if ( (destination >= Int64(self.timeInterval)) && self.scrubbedDestination == 0 ) {

            // Check if any Ads available in between orgin & scrubbed destination
            if let scrubbedToAd = allTimelineContent.filter( { $0.contentEndTime <= Double(destination) && $0.contentType == "ad" }).last, let index = allTimelineContent.firstIndex(where:  { $0 == scrubbedToAd }) {

                // if the Ad found in between origin & the seek destination was watched before, allow seek & start the timer with destination value
                if scrubbedToAd.isWatched == true {

                    if let scrubbedContent = allTimelineContent.filter( { $0.contentEndTime >= Double(destination) && Double(destination) >= $0.contentStartTime }).first {
                        if let vodContentIndex = allTimelineContent.indices.filter({allTimelineContent[$0] == scrubbedContent}).first {
                            
                            self.clipIndexToPlayNow = vodContentIndex
                            self.timeInterval = Double(destination)
                            if let clips = ads.clips {
                                self.startAdPlaybackTimer(clipIndexToStart: vodContentIndex, clips: clips, startTimeInterval: Double(destination))
                            }
                        }
                    }

                } else {

                    // There is a Ad inbetween seek origin & destination & that Ad was not watched before. First player should seek to that Ad & start playing that.
                    self.timer?.invalidate()
                    self.clipIndexToPlayNow = index
                    
                    self.timeInterval = Double(destination)
                    
                    self.scrubbedDestination = destination
                    self.context.onServerSideAdShouldSkip(scrubbedToAd.contentStartTime)
                
                }
            }
        
            else {
                // Did not find any Ad that the user haven't watched in between scrubbed destination & current time. Scrubbed to the destination & keep playing content
                if let scrubbedContent = allTimelineContent.filter( { $0.contentEndTime >= Double(destination) && Double(destination) >= $0.contentStartTime }).first {
                    if let index = allTimelineContent.indices.filter({allTimelineContent[$0] == scrubbedContent}).first {
                        self.timer?.invalidate()
                        self.clipIndexToPlayNow = index
                        self.timeInterval = Double(destination)
                        if let clips = ads.clips {
                            self.startAdPlaybackTimer(clipIndexToStart: (index), clips: clips, startTimeInterval: Double(destination))
                        }
                    }
                }
            }
        }
        
        // Player was seek to a past time
        else if (destination < Int64(self.timeInterval)){
            
            // Check if user has scrubbed to a Vod clip , if so do nothing, keep playing the content
            if let scrubbedToVod = allTimelineContent.filter( { $0.contentStartTime == Double(destination) && $0.contentType == "vod" }).first , let index = allTimelineContent.firstIndex(where:  { $0 == scrubbedToVod }) {

                self.timer?.invalidate()
                self.clipIndexToPlayNow = index
                self.timeInterval = Double(destination)
                if let clips = ads.clips {
                    self.startAdPlaybackTimer(clipIndexToStart: (index), clips: clips, startTimeInterval: Double(destination))
                }
            }
            
            // Check if the player was seeked to an Ad
            else if let scrubbedToAd = allTimelineContent.filter( { $0.contentEndTime >= Double(destination) && Double(destination) >= $0.contentStartTime && $0.contentType == "ad" }).first,  let index = allTimelineContent.firstIndex(where:  { $0 == scrubbedToAd }) {

                // Player was seeked to an Ad which was watched before, player should skip that & find the next Vod clip & start play from that position
                if scrubbedToAd.isWatched == true {

                    for (index, clip) in allTimelineContent.enumerated().dropFirst(index) {
                        if clip.contentType == "ad" && clip.isWatched == true {
                            continue
                        } else if(clip.contentType == "ad" && clip.isWatched == false ) {
                            continue
                        }
                        else if (clip.contentType == "vod") {
                            self.clipIndexToPlayNow = index
                            self.timeInterval = clip.contentStartTime
                            self.scrubbedDestination = Int64(clip.contentStartTime)
                            self.context.onServerSideAdShouldSkip(clip.contentStartTime)
                            break
                        }
                    }
                }
                
                // Player was seek to an Ad which was not watched before, should play the Ad
                else {
                    self.timer?.invalidate()
                    self.clipIndexToPlayNow = index
                    
                    self.timeInterval = scrubbedToAd.contentStartTime
                    
                    if let clips = ads.clips {
                        self.startAdPlaybackTimer(clipIndexToStart: index, clips: clips, startTimeInterval: scrubbedToAd.contentStartTime)
                    }
                }
            }
            
            // Player was seek to a past position , but scrubbedDestination is not 0. Which means player was forcely seek to an Ad
            else if (destination < Int64(self.timeInterval) && self.scrubbedDestination != 0 ){
                if let scrubbedAd = allTimelineContent.filter( { $0.contentEndTime >= Double(destination) && Double(destination) >= $0.contentStartTime }).first {
                    
                    if let index = allTimelineContent.indices.filter({allTimelineContent[$0] == scrubbedAd}).first {
                        self.timer?.invalidate()
                        self.timeInterval = scrubbedAd.contentStartTime
                        self.clipIndexToPlayNow = index
                        if let clips = ads.clips {
                            self.startAdPlaybackTimer(clipIndexToStart: (index), clips: clips, startTimeInterval: scrubbedAd.contentStartTime)
                        }
                    }
                }
            }
            
            // Fall back when both above conditions fails. Seek to the destination & keep playing the content
            else {
                if let scrubbedContent = allTimelineContent.filter( { $0.contentEndTime >= Double(destination) && Double(destination) >= $0.contentStartTime }).first {
                    
                    if let index = allTimelineContent.indices.filter({allTimelineContent[$0] == scrubbedContent}).first {
                        self.timer?.invalidate()
                        self.timeInterval = Double(destination)
                        self.clipIndexToPlayNow = index
                        if let clips = ads.clips {
                            self.startAdPlaybackTimer(clipIndexToStart: (index), clips: clips, startTimeInterval: Double(destination))
                        }
                    }
                }
                
            }
            
        }
        // Player was seek not to a future position neither past position, should not happen. But keep the fall back
        else {
            if let scrubbedContent = allTimelineContent.filter( { $0.contentEndTime >= Double(destination) && Double(destination) >= $0.contentStartTime }).first {

                if let index = allTimelineContent.indices.filter({allTimelineContent[$0] == scrubbedContent}).first {
                    self.timer?.invalidate()
                    self.clipIndexToPlayNow = index
                    self.timeInterval = Double(destination)
                    if let clips = ads.clips {
                        self.startAdPlaybackTimer(clipIndexToStart: index, clips: clips, startTimeInterval: Double(destination))
                    }
                }
            }
        }
        
    }
    
    
    /// Start Ad service when play back starts
    private func startAdService() {
        if let clips = ads.clips {
            self.startAdPlaybackTimer(clipIndexToStart: self.clipIndexToPlayNow, clips: clips, startTimeInterval: 0)
        }
    }
    
    
    /// Handles internal Timer that will start / stop / pause  depend on the player inputs
    /// - Parameters:
    ///   - clipIndexToStart: index of the clip to start from : allTimelineContent
    ///   - clips: Ads.Clips
    ///   - startTimeInterval: time interval that Timer should start from
    private func startAdPlaybackTimer( clipIndexToStart: Int = 0 , clips: [AdClips], startTimeInterval: Double = 0 ) {
        
        self.timer?.invalidate()
        self.timeInterval = startTimeInterval
        
        self.clipIndexToPlayNow = clipIndexToStart
        
        let clip = clips[clipIndexToStart]
        
        if clipIndexToStart < allTimelineContent.count {
            let content = allTimelineContent[clipIndexToStart]
            
            let clipStartTime = content.contentStartTime
            let clipEndTime = content.contentEndTime
            
            // New Clip Duration is , clip start time & the duration
            // let clipDuration = clipStartTime + Double(duration)
            let duration = clipEndTime - clipStartTime
            
            let clipFirstQuartile =  clipStartTime + Double(duration)/4
            let clipMidpoint = clipStartTime + Double( duration)/2
            let clipThirdQuartile = clipStartTime + ( Double(duration) * 3/4)

            // Check if the pre roll is an ad
            if content.contentType == "ad" && Int(timeInterval)  == Int(clipStartTime) {
  
                if content.isWatched == false {

                    policy.fastForwardEnabled = false
                    policy.rewindEnabled = false
                    policy.timeshiftEnabled = self.source.entitlement.timeshiftEnabled
                    self.source.contractRestrictionsService.contractRestrictionsPolicy = policy
                    
                    self.context.onServerSideAdStarted(self.source.contractRestrictionsService, false, nil)
                    
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
                                
                                self.allTimelineContent[clipIndexToStart] = TimelineContent(contentType: content.contentType, contentTitle: content.contentTitle, contentStartTime: content.contentStartTime, contentEndTime: content.contentEndTime, isWatched: true)
                                
                                self.policy.fastForwardEnabled = self.source.entitlement.ffEnabled
                                self.policy.rewindEnabled = self.source.entitlement.rwEnabled
                                self.policy.timeshiftEnabled = self.source.entitlement.timeshiftEnabled
                                self.source.contractRestrictionsService.contractRestrictionsPolicy = self.policy
                                self.context.onServerSideAdEnded(self.source.contractRestrictionsService)
                                
                                // Send complete tracking events
                                self.adTracking(adTrackingUrls: clip.trackingEvents?.complete ?? [] )
                                
                                // We have a predefined scrub destination , player should skipped to this position
                                if self.scrubbedDestination != 0 {
                                    self.timer?.invalidate()
                                    self.context.onServerSideAdShouldSkip(Double(self.scrubbedDestination))
                                    
                                } else {
  
                                    // If we don't have a predefined scrub destination, find the next clip & start the timer for that clip
                                    if (self.clipIndexToPlayNow + 1) < self.allTimelineContent.count {
                                        self.clipIndexToPlayNow = self.clipIndexToPlayNow + 1

                                        self.timer?.invalidate()
                                        
                                        self.startAdPlaybackTimer(clipIndexToStart: self.clipIndexToPlayNow , clips: clips, startTimeInterval: content.contentEndTime)
                                    } else {
                                        self.timer?.invalidate()
                                    }
                                }
                            }
                    }
                }
                
                // Clip is an Ad , but was watched before, so Find the next Vod / Live clip
                else {
                     
                    for (index, clip) in allTimelineContent.enumerated().dropFirst(clipIndexToPlayNow) {
                        if clip.contentType == "ad" && clip.isWatched == true {
                            continue
                        } else if(clip.contentType == "ad" && clip.isWatched == false ) {
                            continue
                        }
                        else if (clip.contentType == "vod") {
                            self.clipIndexToPlayNow = index
                            self.timeInterval = clip.contentStartTime
                            self.scrubbedDestination = Int64(clip.contentStartTime)
                            self.context.onServerSideAdShouldSkip(clip.contentStartTime)
                            break
                        }
                    }
                }
            }
            // Clip is a Vod / live clip
            else if content.contentType == "vod" {
                
                // Starting timer
                self.timer = Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true) { timer in
                    self.timeInterval += 1
                    
                    self.context.onClipStarted(Int64(self.timeInterval), Int64(content.contentEndTime))
                    
                    // When the clip ends, find the next clip & start the timer for that clip
                    if Int(self.timeInterval) == Int(clipEndTime) {
                        if self.clipIndexToPlayNow + 1 < self.allTimelineContent.count {
                            self.clipIndexToPlayNow = self.clipIndexToPlayNow + 1
                            self.timer?.invalidate()
                            self.startAdPlaybackTimer(clipIndexToStart: self.clipIndexToPlayNow , clips: clips, startTimeInterval:  content.contentEndTime )
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
                            self.startAdPlaybackTimer(clipIndexToStart: self.clipIndexToPlayNow , clips: clips, startTimeInterval:  content.contentEndTime )
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
    
    private func prepareAdService() {
        
        var vodDuration: Int64 = 0
        var totalDuration : Float = 0
        if let clips = self.ads.clips {
            
            // Total Duration in miliseconds
            totalDuration = clips.compactMap { Float($0.duration ?? 0) }.reduce(0, +)
            
            
            var currentDuration : Float = 0
            
            for (index,clip) in clips.enumerated() {
            
                // Clip is a Vod , add it to vodDuration
                if clip.category == "vod" {
                    if let duration = clip.duration {
                        vodDuration = vodDuration + Int64(duration)
                    }
                }
                
                // Clips is an ad, should add an adMarker to the timeLine on ad starting point
                else if clip.category == "ad" {
                    if let duration = clip.duration   {
                        if index == 0 {
                            let markerPoint = MarkerPoint(type: "Ad", offset: Int(currentDuration), endOffset: (Int(currentDuration + duration)) )
                            
                            // If the first clip is an Ad, we directly Ad it
                            self.adMarkerPositions.append(markerPoint)
                        } else if index != 0 && index != clips.count {
                            // check if the just previous clip was an Ad, if so we will skip it
                            let previousClip = clips[index - 1]
                            if previousClip.category != "ad" {
                                let markerPoint = MarkerPoint(type: "Ad", offset: Int(currentDuration), endOffset: Int(currentDuration + duration))
                                self.adMarkerPositions.append(markerPoint)
                            }
                        } else if index == clips.count {
                            // If the last clip is an Ad, we directly Ad it
                            let markerPoint = MarkerPoint(type: "Ad", offset: Int(totalDuration), endOffset: Int(totalDuration))
                            self.adMarkerPositions.append(markerPoint)
                        }

                    } else {
                        // print(" Clip type is something else : Not a vod neither ad")
                    }
                    }

                
                // Add the clip duration to currentTotalDuration
                if let duration = clip.duration   {
                    
                    let clipStartTime = Double(currentDuration)
                    let clipEndTime = Double(currentDuration + duration )
                    
                    let timelineContent = TimelineContent(contentType: clip.category, contentTitle: clip.title, contentStartTime: clipStartTime, contentEndTime: clipEndTime)
                    
                    allTimelineContent.append(timelineContent)
                    currentDuration = currentDuration + duration
                }
            }

            context.onPlaybackStartWithAds(vodDuration, totalDuration, adMarkerPositions )
        }
    }
    
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
