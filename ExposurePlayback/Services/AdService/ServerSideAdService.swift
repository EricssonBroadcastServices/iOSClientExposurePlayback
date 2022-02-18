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
    private var userInitiatedSeek:Bool = true
    
    #if TARGET_OS_TV
    private var avInterstitialTimeRange = [AVInterstitialTimeRange]()
    #endif
    
    var shouldSkipAd: Bool = false
    
    /// Use this as a temporary to store user's scrubed / seek destiantion. When there is an `ad` in between current location & scrubbed destination , sdk will first play the `ad` & then jump to this scrubbed destination
    private var oldScrubbedDestination: Int64 = 0
    
    private var destination: Int64 = 0
    
    /// Seek starting position
    private var scrubbedFromPosition: Int64 = 0
    
    
    var initialPlayback = false
    
    
    /// This will hold the state of the seek : ex : If an `ad` should be skipped this will be `true` as SDK decided the seek. If the seek is initiated by the user this will `false`
    private var isSDKInitatedSeek: Bool = false
    
    public init(ads: Ads, clips:[AdClips], context: ExposureContext, source: ExposureSource, durationInMs: Double, tech: HLSNative<ExposureContext>) {
        self.ads = ads
        self.context = context
        self.source = source
        self.durationInMs = durationInMs
        self.tech = tech
        self.clips = clips
        
        self.userInitiatedSeek = true
        
        
        
    }
    
    public func playbackReady() {
        // print(" Play back ready ")
    }
    
    public func playbackStarted() {
        deallocAll()
        
        self.initialPlayback = true
        self.prepareAdService()
        self.startAdService()
    }
    
    public func playbackAborted() {
        deallocAll()
    }
    
    public func playbackEnded() {
        deallocAll()
        
    }
    
    public func playbackPaused() {
        // self.timer?.invalidate()
    }
    
    public func playbackResumed() {
        // self.startAdPlaybackTimer(clipIndexToStart: self.clipIndexToPlayNow, startTimeInterval: self.timeInterval, clip: clips[self.clipIndexToPlayNow])
    }
    
    /// Clear & de allocate
    private func deallocAll() {
        self.timer?.invalidate()
        self.tempAdTimeLine.removeAll()
        self.allTimelineContent.removeAll()
        self.adMarkerPositions.removeAll()
        self.oldScrubbedDestination = 0
        self.scrubbedFromPosition = 0
        self.destination = 0
        self.timeInterval = 0
        
        self.tech.removePeriodicTimeObserverToPlayer()
        
        #if TARGET_OS_TV
        self.avInterstitialTimeRange.removeAll()
        #endif
    }
    

    
    public func playbackFailed(error: NSError) {
        deallocAll()
    }
    
    public func playbackBufferingStarted() {
        // print(" playbackBufferingStarted")
    }
    
    public func playbackBufferingEnded() {

        // self.timer?.invalidate()
        // self.scrubbed(withTargetPosition: destination)
    }
    
    /// Seek request intiated / scrubing started
    /// - Parameter origin: fromPosition
    public func seekRequestInitiated(fromPosition origin: Int64) {
        
        // print(" playback seek intiiated fromPosition " , origin )
        self.scrubbedFromPosition = origin
    }
    
    /// Seek request Triggered / scrub ended
    /// - Parameter destination: withTargetPosition
    public func seekRequestTriggered(withTargetPosition destination: Int64) {
        
        // print(" playback seek intiiated withTargetPosition " , destination )
        
        self.destination = destination
        
        self.scrubbed(destination)
        
       
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
    
    
    /// Start Ad service when play back starts
    private func startAdService() {
        
        self.startPlayback()

    }
    
    /// Prepare Ad service with initial clips & timeline content
    private func prepareAdService() {
        
        var vodDuration: Float = 0
        var totalDuration : Float = 0
        var totalAdDuration: Float = 0
        
        // Reset admarker arrays
        self.adMarkerPositions.removeAll()
        self.tempAdMarkerPositions.removeAll()
        
        if let clips = self.ads.clips {
            
            // Total Duration in miliseconds
            totalDuration = clips.compactMap { Float($0.duration ?? 0) }.reduce(0, +)
            
            totalAdDuration = clips.compactMap {
                if ($0.category == "ad") { return Float($0.duration ?? 0)} else { return 0}
            }.reduce(0, +)
            
            var currentDuration : Float = 0
            
            for (index,clip) in clips.enumerated() {
                
                // Add the clip duration to currentTotalDuration
                if let duration = clip.duration   {
                    
                    let clipStartTime = Double(currentDuration)
                    let clipEndTime = Double(currentDuration + duration )
                    
                    let timeRange = CMTimeRange(start: CMTime(milliseconds: Int64(clipStartTime)), end: CMTime(milliseconds: Int64(clipEndTime)))
                    
                    let timelineContent = TimelineContent(contentType: clip.category, contentTitle: clip.title, contentStartTime: clipStartTime, contentEndTime: clipEndTime, timeRange: timeRange)
                    
                    allTimelineContent.append(timelineContent)
                    
                    // Clips is an ad, should add an adMarker to the timeLine on ad starting point
                    if clip.category == "ad" {
                        if index == 0 {
                            
                            // Keep the ad marker in the tempAdMarkerPositions
                            let markerPoint = MarkerPoint(type: "Ad", offset: 0, endOffset: (Int(duration)) )
                            self.tempAdMarkerPositions.append(markerPoint)
                            currentDuration = currentDuration + duration
                            
                        } else if index != 0 && index != ( clips.count - 1 )  {
                            
                            // Keep the ad marker in the tempAdMarkerPositions
                            let markerPoint = MarkerPoint(type: "Ad", offset: Int(currentDuration), endOffset: Int(currentDuration + duration))
                            currentDuration = currentDuration + duration
                            self.tempAdMarkerPositions.append(markerPoint)
                            
                            
                        } else if index == ( clips.count - 1 ) {
                            // If the last clip is an Ad, we check the tempAdMarkerPositions to find if there are any elements / ads before the last ad clip. If so, get the offSet value from the first element & use the totalDuration value as the endOffset
                            if let offset = tempAdMarkerPositions.first?.offset {
                                let markerPoint = MarkerPoint(type: "Ad", offset: offset, endOffset: Int(totalDuration) )
                                self.adMarkerPositions.append(markerPoint)
                                
                                // Clear tempAdMarkerPositions array
                                tempAdMarkerPositions.removeAll()
                            } else {
                                let markerPoint = MarkerPoint(type: "Ad", offset: Int(currentDuration), endOffset: Int(totalDuration))
                                self.adMarkerPositions.append(markerPoint)
                                
                                // Clear tempAdMarkerPositions array
                                tempAdMarkerPositions.removeAll()
                            }
                        }
                        else {
                            // print(" Clip type is an Ad, but something is wrong with index & clip duration")
                        }
                    } else {
                        
                        // Clip is not an ad , add it to vodDuration
                        vodDuration = vodDuration + (duration)
                        currentDuration = currentDuration + duration
                        
                        // Clip is not an AD : Create a new ad marker if the tempAdMarkerPositions is not empty
                        
                        // Check if there are any values in tempAdMarkerPositions.
                        // If so create a new adMarker with offet value of the first element & endoffset value from the last element
                        if let offset = tempAdMarkerPositions.first?.offset, let endOffset = tempAdMarkerPositions.last?.endOffset {
                            let markerPoint = MarkerPoint(type: "Ad", offset: offset, endOffset: endOffset )
                            self.adMarkerPositions.append(markerPoint)
                            
                            // Clear tempAdMarkerPositions array
                            tempAdMarkerPositions.removeAll()
                        }
                    }
                    
                } else {
                    // print(" Should not happen ")
                    // print(" Clip duration is not available : clip category \(clip.category) & clip title \(clip.title) & clip titleId \(clip.titleId)" )
                }
            }
            
            context.onPlaybackStartWithAds(vodDuration,totalAdDuration, totalDuration, adMarkerPositions )
        }
    }
    
    #if TARGET_OS_TV
    
    #endif
    
    func scrubbed(_ targetDestination: Int64 ) {
        print(" Scrubbed ")
        
        if userInitiatedSeek == true {
            self.userInitiatedSeek = false
            self.oldScrubbedDestination = targetDestination
        } else {
            // print(" user initiated seek is false ")
        }
    }
    
    func startPlayback() {
        
        // Add preiodoci time oberver for the player
        tech.addPeriodicTimeObserverToPlayer { [weak self] time in
            
            guard let `self` = self else { return }
            
            
            // Find if there are any ads in between playhead start position & start time
            // This is needed when a player starts from a bookmark to check if there any available ads before the bookmark
            if self.initialPlayback == true {
                
                self.initialPlayback = false
                
             
                
                let range = CMTimeRange(start: CMTime(milliseconds: 0), end: CMTime(milliseconds: self.tech.playheadPosition))

                // check for an Ad
                if let adClipIndex = self.allTimelineContent.firstIndex(where:  { range.containsTimeRange($0.timeRange) && !self.tempAdTimeLine.contains($0) }) {
                    
                    // temporary store the previously assigned playhead time. After the ads are played, player will seek to this position
                    self.oldScrubbedDestination = self.tech.playheadPosition
                    
                    let adClip = self.allTimelineContent[adClipIndex]
                    
                 
                    self.oldScrubbedDestination = self.tech.playheadPosition
                    
                    self.userInitiatedSeek = false
                    self.context.onServerSideAdShouldSkip( Int64(adClip.contentStartTime + 10) )

                } else {
                    // print("No matching ads found, keep playing content")
                }
                
                
                
            } else {
                
                // print(" Not initial play ")
                
                let _ = self.allTimelineContent.compactMap { content in
                    if let start = content.timeRange.start.milliseconds , let end = content.timeRange.end.milliseconds, let timeInMil = time.milliseconds {


                        let duration = (end / 10 * 10) - (start / 10 * 10)
                        
                        let clipFirstQuartile =  start + (duration)/4
                        let clipMidpoint = start + ( duration)/2
                        let clipThirdQuartile = start + ((duration) * 3/4)

                        if (start / 10 * 10) <= timeInMil && (end / 10 * 10) >= timeInMil && content.contentType == "ad" && !(self.tempAdTimeLine.contains(content)) {


                            if let adClipIndex = self.allTimelineContent.firstIndex(where:  { content.timeRange.containsTimeRange($0.timeRange) }) {

                                // print(" Found an ad clip ")
                                
                                let clip = self.clips[adClipIndex]
                                
                                
                                if timeInMil == (start / 10 * 10) ||  timeInMil == (start / 10 * 10) + 10    {
                                    

                                    // Send load tracking events
                                    self.adTracking(adTrackingUrls: clip.trackingEvents?.load ?? [] )
                                    
                                    // Send start tracking events
                                    self.adTracking(adTrackingUrls: clip.trackingEvents?.start ?? [] )
                               
                                    self.policy.fastForwardEnabled = false
                                    self.policy.rewindEnabled = false
                                    self.policy.timeshiftEnabled = self.source.entitlement.timeshiftEnabled
                                    self.source.contractRestrictionsService.contractRestrictionsPolicy = self.policy

                                    self.adTracking(adTrackingUrls: clip.impressionUrlTemplates ?? [] )
                                    
                                  
                                    
                                    if let adMediaId = clip.titleId {
                                        self.tech.currentSource?.analyticsConnector.providers
                                            .compactMap{ $0 as? ExposureAnalytics }
                                            .forEach{ $0.onAdStarted(tech: self.tech, source: self.source, adMediaId: adMediaId) }
                                    }
                                    
                                    self.context.onWillPresentInterstitial(self.source.contractRestrictionsService , clip.videoClicks?.clickThroughUrl, Int64(clip.duration ?? 0))
                                    
                                }

                                else if timeInMil == (clipFirstQuartile / 10 * 10)  {
                                    // Send firstQuartile tracking events
                                   
                                    self.adTracking(adTrackingUrls: clip.trackingEvents?.firstQuartile ?? [] )
                                    
                                } else if timeInMil == (clipMidpoint / 10 * 10) {
                                    // Send clipMidpoint tracking events
                                    
                                    self.adTracking(adTrackingUrls: clip.trackingEvents?.midpoint ?? [] )
                                    
                                } else if timeInMil == (clipThirdQuartile / 10 * 10)  {
                                    // Send thirdQuartile tracking events
                                    
                                    self.adTracking(adTrackingUrls: clip.trackingEvents?.thirdQuartile ?? [] )
                                    
                                } else if timeInMil == (end / 10 * 10)  {
                                    
                                    
                                    // Send complete tracking events
                                    self.adTracking(adTrackingUrls: clip.trackingEvents?.complete ?? [] )
                                    
                                    // Send EMP anlytics
                                    if let adMediaId = clip.titleId {
                                        self.tech.currentSource?.analyticsConnector.providers
                                            .compactMap{ $0 as? ExposureAnalytics }
                                            .forEach{ $0.onAdCompleted(tech: self.tech, source: self.source, adMediaId: adMediaId) }
                                    }
                                    
                                    self.tempAdTimeLine.append(content)
                                    
                                    // Check if there is a previously assigned scrub destiantion is available. If so after the ad is played, player should seek to tha destination
                                    
                                    self.policy.fastForwardEnabled = self.source.entitlement.ffEnabled
                                    self.policy.rewindEnabled = self.source.entitlement.rwEnabled
                                    self.policy.timeshiftEnabled = self.source.entitlement.timeshiftEnabled
                                    self.source.contractRestrictionsService.contractRestrictionsPolicy = self.policy
                                    self.context.onDidPresentInterstitial(self.source.contractRestrictionsService)
                                    
                                    if self.oldScrubbedDestination != 0 {
                                        self.userInitiatedSeek = false
                                        self.context.onServerSideAdShouldSkip(self.oldScrubbedDestination)
                                    }
                                }
                                
                            }
                        } else if (start / 10 * 10) <= timeInMil && (end / 10 * 10) >= timeInMil && content.contentType == "ad" && (self.tempAdTimeLine.contains(content)) {
                            
                            // self.skipAlreadyPlayedAd()
                            
                            if self.oldScrubbedDestination != 0 {
                                self.userInitiatedSeek = false
                                self.context.onServerSideAdShouldSkip(self.oldScrubbedDestination)
                            } else {
                                
                                self.userInitiatedSeek = false
                                self.context.onServerSideAdShouldSkip(Int64(content.contentStartTime + 10))
                            }
                            
                        } else {
                            
                        }
                    }
                }
            }
            
        }
    }

    
    fileprivate func skipAlreadyPlayedAd() {
        
        // Find the next available vod clip
        for (index, clip) in allTimelineContent.enumerated().dropFirst(clipIndexToPlayNow) {
            
            
            if(self.tempAdTimeLine.contains(clip)) {
                continue
            }
            
            /* if clip.contentType == "ad" && clip.isWatched == true {
                continue
            } else if(clip.contentType == "ad" && clip.isWatched == false ) {
                continue
            } */
            else if (clip.contentType != "ad") {
                self.clipIndexToPlayNow = index
                self.timeInterval = clip.contentStartTime + 1
                self.oldScrubbedDestination = Int64(clip.contentStartTime + 10 )
                self.userInitiatedSeek = true
                self.context.onServerSideAdShouldSkip(Int64(clip.contentStartTime + 10 ))
                break
            }
            else {
                self.clipIndexToPlayNow = index
                self.timeInterval = clip.contentStartTime
                self.oldScrubbedDestination = Int64(clip.contentEndTime + 10 )
                self.self.userInitiatedSeek = true
                self.context.onServerSideAdShouldSkip(Int64(clip.contentEndTime + 10 ))
            }
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
