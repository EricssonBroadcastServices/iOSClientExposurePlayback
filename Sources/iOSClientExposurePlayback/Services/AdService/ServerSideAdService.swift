//
//  ServerSideAdService.swift
//  ExposurePlayback
//
//  Created by Udaya Sri Senarathne on 2021-07-20.
//  Copyright © 2021 emp. All rights reserved.
//

import Foundation
import iOSClientExposure
import iOSClientPlayer
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
    
    
    fileprivate var alreadyStartedAd: [TimelineContent] = []
    
    /// Temporary store all adTracking urls of an Ad to prevent sending multiple trackings events to the backend
    fileprivate var alreadySentadTrackingUrls: [[String]] = []
    
    /// Whenver content type is not an`ad` append the first item from `tempAdMarkerPositions` & reset `tempAdMarkerPositions` array.
    private var adMarkerPositions: [MarkerPoint] = []
    
    /// This will be used to store Ad marker positions temporary, when there are multiple `adMarkers` `tempAdMarkerPositions` will hold them until next clip is not an `ad` , then append the first item to the `adMarkerPositions` array.
    ///
    /// Note:- Reason for this is to show only the combined adMarker in the timeline. : If there are mutiple Ads playing together , it will show as one marker in the timeline
    private var tempAdMarkerPositions: [MarkerPoint] = []
    
    /// When seek / scrub is initiated it will check if the seek is initiated by the user or by the sdk.
    private var userInitiatedSeek:Bool = true
    
    /// Use this as a temporary to store user's scrubed / seek destiantion. When there is an `ad` in between current location & scrubbed destination , sdk will first play the `ad` & then jump to this scrubbed destination
    private var oldScrubbedDestination: Int64 = 0
    
    /// Player should seek to this position
    private var scrubbedToPosition: Int64 = 0
    
    /// Seek started from this position
    private var scrubbedFromPosition: Int64 = 0
    
    /// Check if the playback is started initialy . Either playback has started from beginning or from a bookmark.
    private var initialPlayback = false
    
    // Variables use for calculating AdCounter values
    private var previousVodClipIndex : Array<TimelineContent>.Index = 0
    private var nextVodClipIndex : Array<TimelineContent>.Index = 0
    private var noOfAdsInAdBreak: Int = 0
    private var adIndexInAdBreak: Int = 0
    
    public init(ads: Ads, clips:[AdClips], context: ExposureContext, source: ExposureSource, durationInMs: Double, tech: HLSNative<ExposureContext>) {
        self.ads = ads
        self.context = context
        self.source = source
        self.durationInMs = durationInMs
        self.tech = tech
        self.clips = clips
        
        self.deallocAll()
        
    }
    
    public func playbackReady() {
        // print(" Play back ready ")
    }
    
    public func playbackStarted() {
        deallocAll()
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
        // playbackResumed
    }
    
    /// Clear & de allocate
    private func deallocAll() {
        self.tempAdTimeLine.removeAll()
        self.alreadyStartedAd.removeAll()
        self.alreadySentadTrackingUrls.removeAll()
        self.allTimelineContent.removeAll()
        self.adMarkerPositions.removeAll()
        self.oldScrubbedDestination = 0
        self.scrubbedFromPosition = 0
        self.scrubbedToPosition = 0
        self.tech.removePeriodicTimeObserverToPlayer()
        self.userInitiatedSeek = true
        self.previousVodClipIndex = 0
        self.nextVodClipIndex = 0
        self.noOfAdsInAdBreak = 0
        self.adIndexInAdBreak = 0
    }
    
    
    
    public func playbackFailed(error: NSError) {
        deallocAll()
    }
    
    public func playbackBufferingStarted() {
        // print(" playbackBufferingStarted")
    }
    
    public func playbackBufferingEnded() {
        // print("playbackBufferingEnded")
        
    }
    
    /// Seek request intiated / scrubing started
    /// - Parameter origin: fromPosition
    public func seekRequestInitiated(fromPosition origin: Int64) {
        
        // Note : Player sends multiple seek events when scrubbing through the tvOS timeilne. This cause the bug that prevent player seek to midroll ads, if a user seek beyond already unwatched ad.
        // To fix this issue, assume that `scrubbedFromPosition` is always zero when seeking in tvOS.
        #if TARGET_OS_TV
            self.scrubbedFromPosition = 0
        #else
            self.scrubbedFromPosition = 0
            self.scrubbedFromPosition = origin
        #endif
            
    }
    
    /// Seek request Triggered / scrub ended
    /// - Parameter destination: withTargetPosition
    public func seekRequestTriggered(withTargetPosition destination: Int64) {
        self.scrubbedToPosition = 0
        self.scrubbedToPosition = destination
        self.scrubbed(self.scrubbedToPosition)
        
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
        self.startPlayback(0, self.tech.playheadPosition)
        
    }
    
    
    private func scrubbed(_ targetDestination: Int64 ) {
        if userInitiatedSeek == true {
            self.tech.removePeriodicTimeObserverToPlayer()
            self.startPlayback(self.scrubbedFromPosition, self.scrubbedToPosition)
        } else {
            self.userInitiatedSeek = true
        }
    }
}


// MARK: Playback
extension ServerSideAdService {

    
    /// Started plyabck with Ads
    /// - Parameters:
    ///   - startTime: start position. This will be 0
    ///   - currentPlayheadPosition: current playhead position : This will be `zero` if the content started from beginning. Not `zero` if the content started from a bookmark
    private func startPlayback(_ startTime:Int64 , _ currentPlayheadPosition: Int64 ) {
        
        // Note:This should be refactored at some point
        
        // Reset the values
        self.tempAdTimeLine.removeAll()
        self.noOfAdsInAdBreak = 0
        self.adIndexInAdBreak = 0
        
        // temporary store values
        var rangeStart = startTime
        var rangeEnd = currentPlayheadPosition
        
        // Add preiodic time oberver for the player
        self.tech.addPeriodicTimeObserverToPlayer { [weak self] time in
            
            guard let `self` = self else { return }
            
            // Find if there are any ads in between playhead start position & start time
            // This is needed when a player starts from a bookmark to check if there any available ads before the bookmark
            if ((rangeEnd / 10 * 10) != 0 && self.oldScrubbedDestination == 0) || (rangeEnd == 0 && rangeStart != 0)  {
                
                let range = CMTimeRange(start: CMTime(milliseconds: rangeStart), end: CMTime(milliseconds: rangeEnd))
  
                if let adBreakIndex = self.adMarkerPositions.lastIndex(where: {
                    if let startOffset = $0.offset , let endOffset = $0.endOffset {
                        let adRange = CMTimeRange(start: CMTime(milliseconds: Int64(startOffset)), end: CMTime(milliseconds:  Int64(endOffset)))
                        return range.containsTimeRange(adRange)
                    }
                    return false
                }) {
                    if let offset = self.adMarkerPositions[adBreakIndex].offset {
                        
                        if let adClipIndex = self.allTimelineContent.firstIndex(where: {
                            if Int($0.contentStartTime / 10 * 10)  == (offset / 10 * 10) && $0.contentType == "ad"  {
                                return true
                            } else {
                                return false
                            }
                        }) {
                            let adClip = self.allTimelineContent[adClipIndex]
                            
                            // Check if the Ad is already played or not
                            //
                            // Ad is not played before. Store the target destination & seek to the Ad
                            if(!(self.tempAdTimeLine.contains(adClip))) {
                                
                                // temporary store the previously assigned playhead time. After the ads are played, player will seek to this position
                                self.oldScrubbedDestination = rangeEnd
                                
                                // Find the adClip from all timeline content
                                let adClip = self.allTimelineContent[adClipIndex]
                                
                                // reset temporary stored values
                                rangeStart = 0
                                rangeEnd = 0
                              
                                // Make it as sdk initiated seek.
                                self.userInitiatedSeek = false
                                self.context.onServerSideAdShouldSkip( Int64(adClip.contentStartTime + 100) )
                                
                            }
                            
                            // Ad was played before. Should skipped to the next clip
                            else {
                                // Check if we have a previously assigned destination
                                if self.oldScrubbedDestination != 0 {

                                    // Make it as a user intiated seek
                                    self.userInitiatedSeek = true
                                    
                                    let tempDestination = self.oldScrubbedDestination

                                    // Reset oldScrubbedDestination value
                                    self.oldScrubbedDestination = 0
                                    
                                    // reset temporary stored values
                                    rangeStart = 0
                                    rangeEnd = 0
                                
                                    // Inform the player that , it should seek to this position
                                    self.context.onServerSideAdShouldSkip(tempDestination)
                                    
                                } else {
                                    
                                    // This will prevent from always start from the beginning of next vodclip after an Ad break
                                    #if TARGET_OS_TV
                                        self.userInitiatedSeek = true
                                        rangeStart = 0
                                        rangeEnd = 0
                                        
                                    #else
                                    
                                    // There is no previously assigned destination. Find the next `Non Ad` clip & seek to that
                                    if let vodClipIndex = self.allTimelineContent.firstIndex(where:  { $0.contentType != "ad" && ($0.contentStartTime + 10 > adClip.contentEndTime) }) {
                                        let vodClip = self.allTimelineContent[vodClipIndex]
                                        
                                        // Make it as a SDK intiated seek
                                        self.userInitiatedSeek = false
                                        
                                        // reset temporary stored values
                                        rangeStart = 0
                                        rangeEnd = 0
                                        
                                        self.context.onServerSideAdShouldSkip( Int64(vodClip.contentStartTime + 1000) )
                                    } else {
                                        rangeStart = 0
                                        rangeEnd = 0
                                       
                                        self.userInitiatedSeek = true
                                    }
                                    #endif
                                }
                            }
                            
                        } else {
                            // An `AdBreak` was found, but could not find an ad clip in the main timeline. ( Should not happen) , but as a fall back keep playing the content
                            self.userInitiatedSeek = true
                            rangeStart = 0
                            rangeEnd = 0
                        }
                    } else {
                        // No ad clip offset was found, Should not happen.( This should not happen ) , but as a fall back keep playing the content
                        self.userInitiatedSeek = true
                        rangeStart = 0
                        rangeEnd = 0
                    }
                } else {
                    // No `AdBreak` was found, keep playing the content
                    self.userInitiatedSeek = true
                    rangeStart = 0
                    rangeEnd = 0
                }
                
            } else {
                
                rangeStart = 0
                rangeEnd = 0
                
                let _ = self.allTimelineContent.enumerated().compactMap { index, content in
                    if let start = content.timeRange.start.milliseconds , let end = content.timeRange.end.milliseconds, let timeInMil = time.milliseconds {
 
                        if (start / 10 * 10) <= timeInMil && (end / 10 * 10) + 10 >= timeInMil && content.contentType == "ad" && !(self.tempAdTimeLine.contains(content)) {
                            
                            if let adClipIndex = self.allTimelineContent.firstIndex(where:  { content.timeRange.containsTimeRange($0.timeRange) }) {
                                
                                let duration = (end / 10 * 10) - (start / 10 * 10)
    
                                let clipFirstQuartile =  start + (duration)/4
                                let clipMidpoint = start + ( duration)/2
                                let clipThirdQuartile = start + ((duration) * 3/4)
                                
                                let clip = self.clips[adClipIndex]

                                if (timeInMil / 10 * 10) == (clipFirstQuartile / 10 * 10)  {

                                    // Send firstQuartile tracking events
                                    if let firstQuartileUrls = clip.trackingEvents?.firstQuartile {
                                        if !self.alreadySentadTrackingUrls.contains(firstQuartileUrls) {
                                            self.context.trackAds(adTrackingUrls: firstQuartileUrls)
                                            self.alreadySentadTrackingUrls.append( firstQuartileUrls )
                                        }
                                    }
    
                                } else if (timeInMil / 10 * 10) == (clipMidpoint / 10 * 10) {

                                    // Send clipMidpoint tracking events
                                    if let midpointUrls = clip.trackingEvents?.midpoint {
                                        if !self.alreadySentadTrackingUrls.contains(midpointUrls) {
                                            self.context.trackAds(adTrackingUrls: midpointUrls)
                                            self.alreadySentadTrackingUrls.append( midpointUrls )
                                        }
                                    }
                                    
                                } else if (timeInMil / 10 * 10) == (clipThirdQuartile / 10 * 10)  {
                                    
                                    // Send thirdQuartile tracking events
                                    if let thirdQuartileUrls = clip.trackingEvents?.thirdQuartile {
                                        if !self.alreadySentadTrackingUrls.contains(thirdQuartileUrls) {
                                            self.context.trackAds(adTrackingUrls: thirdQuartileUrls)
                                            self.alreadySentadTrackingUrls.append( thirdQuartileUrls )
                                        }
                                    }
                                    
                                } else if ((timeInMil / 10 * 10) == (end / 10 * 10)) {
                                    
                                    // Send complete tracking events
                                    if let completeUrls = clip.trackingEvents?.complete {
                                        if !self.alreadySentadTrackingUrls.contains(completeUrls) {
                                            self.context.trackAds(adTrackingUrls: completeUrls)
                                            self.alreadySentadTrackingUrls.append( completeUrls )
                                        }
                                    }
                                    
                                    // Send EMP anlytics
                                    if let adMediaId = clip.titleId {
                                        self.tech.currentSource?.analyticsConnector.providers
                                            .compactMap{ $0 as? ExposureAnalytics }
                                            .forEach{ $0.onAdCompleted(tech: self.tech, source: self.source, adMediaId: adMediaId) }
                                    }

                                    self.tempAdTimeLine.append(content)
                                    
                                    self.policy.fastForwardEnabled = self.source.entitlement.ffEnabled
                                    self.policy.rewindEnabled = self.source.entitlement.rwEnabled
                                    self.policy.timeshiftEnabled = self.source.entitlement.timeshiftEnabled
                                    self.source.contractRestrictionsService.contractRestrictionsPolicy = self.policy

                                    self.context.onDidPresentInterstitial(self.source.contractRestrictionsService)
                                    
                                    
                                    // Check if all the ads are played , if so reset the temporary stored values for AdCounter
                                    if ( self.noOfAdsInAdBreak - self.adIndexInAdBreak )  == 0 {
                                        self.nextVodClipIndex = 0
                                        self.previousVodClipIndex = 0
                                        self.noOfAdsInAdBreak = 0
                                        self.adIndexInAdBreak = 0
                                        
                                    } else {
                                        // Do nothing
                                    }
                                   
                                    // remove the temporary stored adTracking urls
                                    self.alreadySentadTrackingUrls.removeAll()
                                } else {
                                    
                                    /// Note :
                                    // Some content may not have the `timeInMil` 0 when start. It seems like `PeriodicTimeObserverToPlayer` may have a slight delay and then timeInMil may be higher than the `start`. [ Add a second condition to check if timeInMil is larger than start :=> Ad has already started] . But this will only run once when the ad has started.
                                    if (timeInMil / 10 * 10) + 10 == (start / 10 * 10) + 10 || (timeInMil / 10 * 10) + 10 > (start / 10 * 10) + 10 {
                                        
                                        // print("Some content may not have the `timeInMil` 0 when start. It seems like `PeriodicTimeObserverToPlayer` may have a slight delay and then timeInMil may be higher than the `start`. [ Add a second condition to check if timeInMil is larger than start :=> Ad has already started] . But this will only run once when the ad has started.")

                                        // This will prevent sending multiple satrt events
                                        if !(self.alreadyStartedAd.contains(content)) {
                                            
                                            // Send load tracking events
                                            self.context.trackAds(adTrackingUrls: clip.trackingEvents?.load ?? [] )
                                            
                                            // Send start tracking events
                                            self.context.trackAds(adTrackingUrls: clip.trackingEvents?.start ?? [] )
                                            
                                            self.policy.fastForwardEnabled = false
                                            self.policy.rewindEnabled = false
                                            self.policy.timeshiftEnabled = self.source.entitlement.timeshiftEnabled
                                            self.source.contractRestrictionsService.contractRestrictionsPolicy = self.policy
                                            
                                            self.context.trackAds(adTrackingUrls: clip.impressionUrlTemplates ?? [] )
                                            
                                            
                                            if let adMediaId = clip.titleId {
                                                self.tech.currentSource?.analyticsConnector.providers
                                                    .compactMap{ $0 as? ExposureAnalytics }
                                                    .forEach{ $0.onAdStarted(tech: self.tech, source: self.source, adMediaId: adMediaId) }
                                            }
                                            
                                            // Keep track of already started ads
                                            self.alreadyStartedAd.append(content)

                                            
                                            self.calculateAdCounterValues(adClipIndex, end, start)
                                            self.context.onWillPresentInterstitial(self.source.contractRestrictionsService , clip.videoClicks?.clickThroughUrl, clip.videoClicks?.clickTrackingUrls, Int64(clip.duration ?? 0), self.noOfAdsInAdBreak, self.adIndexInAdBreak )
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Ad is already watched
                        else if (start / 10 * 10) <= (timeInMil / 10 * 10) && (end / 10 * 10) >= (timeInMil / 10 * 10) && content.contentType == "ad" && (self.tempAdTimeLine.contains(content)) {

                            // Check if we have a previously assigned destination
                            if self.oldScrubbedDestination != 0 {
                                // Check if the next content is an Ad or not , if it's not assign the `tempDestination` & seek to that destination after the ad
                                if ( index != (self.allTimelineContent.count - 1) && self.allTimelineContent[index+1].contentType != "ad" ) {

                                    // Make it as a user intiated seek
                                    self.userInitiatedSeek = true
                                    
                                    let tempDestination = self.oldScrubbedDestination
                                    
                                    // Reset oldScrubbedDestination value
                                    self.oldScrubbedDestination = 0
                                    
                                    // Inform the player that , it should seek to this position
                                    self.context.onServerSideAdShouldSkip(tempDestination)
                                } else {
                                    // print(" Still timeline is playing an Ad")
                                }
                                
                            } else {
                                // There is no previously assigned destination. Find the next `Non Ad` clip & seek to that
                                if let vodClipIndex = self.allTimelineContent.firstIndex(where:  { $0.contentType != "ad" && ($0.contentStartTime + 10  > content.contentEndTime) }) {
                                    
                                    let vodClip = self.allTimelineContent[vodClipIndex]
                                    
                                    // Make it as a SDK intiated seek
                                    self.userInitiatedSeek = false
                                    
                                    self.context.onServerSideAdShouldSkip( Int64(vodClip.contentStartTime + 1000) )
                                } else {
                                    self.userInitiatedSeek = true
                                }
                            }
                        }
                        else {
                            return
                        }
                    }
                }
            }
            
        }
    }
}

extension ServerSideAdService {
    
    
    /// Calculate the ad counter values : No of Ads in a ad break & ad index of currently playing ad
    /// - Parameters:
    ///   - adClipIndex: adClipIndex
    ///   - end: end
    ///   - start: start
    fileprivate func calculateAdCounterValues(_ adClipIndex: Array<TimelineContent>.Index, _ end: Int64, _ start: Int64) {
        // Store current playing clip Index ( Add + 1 as indexing start from 0 )
        // ( Index from all the allTimelineContent array )
        let clipIndex = adClipIndex + 1
        
        // adClipIndex == 0 : => Playing a preroll ad
        if adClipIndex == 0 {
            
            // Make the previousVodClipIndex to 0 , as there are no any VodClips before the preroll Ad
            // Assign value to previousVodClipIndex only if  previousVodClipIndex == 0 means, no value has been assigned or resetted after playing an full Ad Break
            if previousVodClipIndex == 0 {
                previousVodClipIndex = 0
            }
            
            // Find the next vod clip index
            if let next = self.allTimelineContent.firstIndex(where:  { Int64($0.contentStartTime + 10 ) > end && $0.contentType != "ad" }) {
                
                // Assign value to nextVodClipIndex only if  nextVodClipIndex == 0 means, no value has been assigned or resetted after playing an full Ad Break
                if nextVodClipIndex == 0 {
                    nextVodClipIndex = next
                }
                
                // Caculate the number of Ads in the ad break
                noOfAdsInAdBreak = nextVodClipIndex - adClipIndex
                
                // Find the ad clip index inside the ad break
                adIndexInAdBreak = clipIndex
                
            } else {
                // print(" Couldn't find the next vod clip : Should not happen as after a preroll ad break there has to be a VodClip ")
                self.nextVodClipIndex = 0
                self.previousVodClipIndex = 0
                // self.noOfAdsInAdBreak = 0
                
                // Couldn't find the next vod clip , still keep adding the ad index assuming we have anothe ad
                self.adIndexInAdBreak = clipIndex
            }
        } else {
            
            // adClipIndex is not `0` , This can  still be a pre roll ad break or mid roll ad break
            if let previous = self.allTimelineContent.firstIndex(where:  { Int64($0.contentEndTime ) < ( start + 10 ) && $0.contentType != "ad" }) {

                // Assign value to previousVodClipIndex only if  previousVodClipIndex == 0 means, no value has been assigned or resetted after playing an full Ad Break
                // use adClipIndex as previousVodClipIndex as it should be the same as previous VodClip (or clipIndex - 1 )
                if previousVodClipIndex == 0 {
                    previousVodClipIndex = adClipIndex
                }

                // Find the next vod clip index
                if let next = self.allTimelineContent.firstIndex(where:  { Int64($0.contentStartTime + 10 ) > end && $0.contentType != "ad" }) {
 
                    // Assign value to nextVodClipIndex only if  nextVodClipIndex == 0 means, no value has been assigned or resetted after playing an full Ad Break
                    if nextVodClipIndex == 0 {
                        nextVodClipIndex = next
                    }
                    noOfAdsInAdBreak = nextVodClipIndex - previousVodClipIndex
                    adIndexInAdBreak =  clipIndex - previousVodClipIndex
                    
                } else {
                    
                    // Couldn't find any Vod Clip as the nextVodClip
                    // There was a previous vod clip but no next vod clip . Should be a post roll ad break
                    // Assign value to nextVodClipIndex only if  nextVodClipIndex == 0 means, no value has been assigned or resetted after playing an full Ad Break
                    if nextVodClipIndex == 0 {
                        
                        // Assume the previous clip index is the same as current playing first ad of the post roll ad break
                        previousVodClipIndex = adClipIndex
                        
                        // Assign the last index as the nextVodClipIndex
                        nextVodClipIndex = self.allTimelineContent.count
                    }
                    
                    noOfAdsInAdBreak = nextVodClipIndex - previousVodClipIndex
                    adIndexInAdBreak =  clipIndex - previousVodClipIndex
                    
                }
                
                
            } else {
                
                // Couldn't find any previous vod clips : So still a pre roll ad break
                
                // Make the previousVodClipIndex to 0 , as there are no any VodClips before the preroll Ad
                // Assign value to previousVodClipIndex only if  previousVodClipIndex == 0 means, no value has been assigned or resetted after playing an full Ad Break
                if previousVodClipIndex == 0 {
                    previousVodClipIndex = 0
                }
                
                // Find the next vod clip index
                if let next = self.allTimelineContent.firstIndex(where:  { Int64($0.contentStartTime) > end && $0.contentType != "ad" }) {
                    
                    
                    // Assign value to nextVodClipIndex only if nextVodClipIndex == 0 means, no value has been assigned or resetted after playing an full Ad Break
                    if nextVodClipIndex == 0 {
                        nextVodClipIndex = next
                    }
                    
                    noOfAdsInAdBreak = nextVodClipIndex - previousVodClipIndex
                    adIndexInAdBreak = clipIndex
                } else {
                    // print(" Couldn't find the next vod clip : Should not happen as after a preroll ad break there has to be a VodClip ")
                    self.nextVodClipIndex = 0
                    self.previousVodClipIndex = 0
                    // self.noOfAdsInAdBreak = 0
                    
                    // Couldn't find the next vod clip , still keep adding the ad index assuming we have anothe ad
                    self.adIndexInAdBreak = clipIndex
                }
            }
        }
    }
}

// MARK: Preparation
extension ServerSideAdService {
    
    /// Prepare Ad service with initial clips & timeline content
    private func prepareAdService() {
        
        self.initialPlayback = true
        
        var vodDuration: Int64 = 0
        var totalDuration: Int64  = 0
        var totalAdDuration: Int64 = 0
        
        // Reset admarker arrays
        self.adMarkerPositions.removeAll()
        self.tempAdMarkerPositions.removeAll()
        
        if let clips = self.ads.clips {
            
            // Total Duration in miliseconds
            let totalclipDuration = clips.compactMap { ($0.duration ?? 0) }.reduce(0, +)
            
            totalDuration =  Int64(totalclipDuration)
            
            totalAdDuration = clips.compactMap {
                if ($0.category == "ad") { return Int64($0.duration ?? 0)} else { return 0}
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
                        vodDuration = vodDuration + Int64(duration)
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
}
