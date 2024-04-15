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

/**
 - Note: This class handles the playback behaviour for the streams which has server side insertions.
 
 What is expected :
  - Ad's position should be marked on the timeline
  - The timeline should be shown as time excluding ad breaks (i.e. ad breaks will only be dots, or similar, shown on the timeline)
  - The user's position in the stream should be shown as time excluding ad breaks
  - The progress report should be time excluding ad breaks
  - When the user scrubs to a position after an unseen ad break, the player should "jump back" to play that ad break and then "jump back" to the position to where the user scrubbed.
  - If the user has already seen the specific ad break - the player should "jump over" the ad break and continue on the content afterwards, just as if the ad break didn't exist.
  - If the user has a bookmark after an ad break, start play content but play the ad breaks if the user scrubs back and forth. I.e. don't mark them as watched.
  - While playing ads
    - Hide timeline & don't let the user scrub/seek
    - Hide jump backwards and forward
    - If Chrome cast during an ad break, the time position before the ad break should be sent to the receiver.
 
 -  Note: tvOS provides out of box implementation for the ads / Interstitial Content. ( https://developer.apple.com/documentation/avkit/working_with_interstitial_content ).
          At the moment there is no support for the iOS. If Apple starts supporting Interstitial content for iOS in future, it will be a good idea to have a look at that.
*/
public class ServerSideAdService: AdService {
    
    let ads: Ads
    let clips:[AdClips]
    let context: ExposureContext
    let source: ExposureSource
    let durationInMs: Double
    let tech: HLSNative<ExposureContext>
    
    let policy = ContractRestrictionsPolicy()
    
    fileprivate var allTimelineContent: [TimelineContent] = []
    
    /// This will store all the ads that are already played during the current session
    fileprivate var alreadyPlayedAds: [TimelineContent] = []
    
	/// This property keep track of already started ads
    fileprivate var alreadyStartedAds: [TimelineContent] = []
    
    /// Temporary store all adTracking urls of an Ad to prevent sending multiple trackings events to the backend
    fileprivate var alreadySentAdTrackingUrls: [[String]] = []
    
    /// Whenver content type is not an`ad` append the first item from `tempAdMarkerPositions` & reset `tempAdMarkerPositions` array.
    private var adMarkerPositions: [MarkerPoint] = []
    
    /// This will be used to store Ad marker positions temporary, when there are multiple `adMarkers` `tempAdMarkerPositions` will hold them until next clip is not an `ad` , then append the first item to the `adMarkerPositions` array.
    ///
    /// Note:- Reason for this is to show only the combined adMarker in the timeline. : If there are mutiple Ads playing together , it will show as one marker in the timeline
    private var tempAdMarkerPositions: [MarkerPoint] = []
    
    /// When seek / scrub is initiated it will check if the seek is initiated by the user or by the sdk.
    private var isSeekUserInitiated: Bool = true
    
    /// Use this as a temporary to store user's scrubbed / seek destination. When there is an `ad` in between current location & scrubbed destination, sdk will first play the `ad` & then jump to this scrubbed destination
    private var intendedScrubPosition: Int64 = 0
    
    /// Seek started from this position
    private var originalScrubPosition: Int64 = 0
    
    // Variables use for calculating AdCounter values
    private var previousVodClipIndex: Array<TimelineContent>.Index = 0
    private var nextVodClipIndex: Array<TimelineContent>.Index = 0
    private var numberOfAdsInAdBreak: Int = 0
    private var currentAdIndexInAdBreak: Int = 0
    
    public init(ads: Ads, clips:[AdClips], context: ExposureContext, source: ExposureSource, durationInMs: Double, tech: HLSNative<ExposureContext>) {
        self.ads = ads
        self.context = context
        self.source = source
        self.durationInMs = durationInMs
        self.tech = tech
        self.clips = clips
        
        self.deallocAll()
        
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
    
    /// Clear & de allocate
    private func deallocAll() {
        self.alreadyPlayedAds.removeAll()
        self.alreadyStartedAds.removeAll()
        self.alreadySentAdTrackingUrls.removeAll()
        self.allTimelineContent.removeAll()
        self.adMarkerPositions.removeAll()
        self.intendedScrubPosition = 0
        self.originalScrubPosition = 0
        self.tech.removePeriodicTimeObserverToPlayer()
        self.isSeekUserInitiated = true
        self.previousVodClipIndex = 0
        self.nextVodClipIndex = 0
        self.numberOfAdsInAdBreak = 0
        self.currentAdIndexInAdBreak = 0
    }
    
    
    
    public func playbackFailed(error: NSError) {
        deallocAll()
    }
    
    /// Seek request initiated / scrubbing started
    /// - Parameter origin: fromPosition
    public func seekRequestInitiated(fromPosition origin: Int64) {

        // Note : Player sends multiple seek events when scrubbing through the tvOS timeline. This cause the bug that prevent player seek to mid roll ads, if a user seek beyond already unwatched ad.
        // To fix this issue, assume that `scrubbedFromPosition` is always zero when seeking in tvOS.
        #if TARGET_OS_TV
            self.originalScrubPosition = 0
        #else
            self.originalScrubPosition = origin
        #endif
            
    }
    
    /// Seek request Triggered / scrub ended
    /// - Parameter destination: withTargetPosition
    public func seekRequestTriggered(withTargetPosition destination: Int64) {
        self.scrubbed(destination)
    }
    
    public var playerProxy: AdPlayerProxy?
    
    public var contractRestrictionsService: ContractRestrictionsService?
    
    private func getNextClip( index:Int,_ completion: @escaping (Int?) -> Void) { }
    
    
    /// Start Ad service when play back starts
    private func startAdService() {
        self.startObservingPlayer(
            originalScrubPosition: 0,
            targetScrubPosition: self.tech.playheadPosition
        )
    }
    
    
    private func scrubbed(_ targetScrubPosition: Int64) {
        guard isSeekUserInitiated else {
            self.isSeekUserInitiated = true
            return
        }
        self.tech.removePeriodicTimeObserverToPlayer()
        self.startObservingPlayer(
            originalScrubPosition: self.originalScrubPosition,
            targetScrubPosition: targetScrubPosition
        )
    }
}


// MARK: Playback
extension ServerSideAdService {
    func makeLastDigitZero(_ number: Int64) -> Int64 {
        guard number != 0 else {
            return 0
        }
        var num = number
        let lastDigit = num % 10
        
        if lastDigit != 0 { num -= lastDigit }

        return num
    }
    
    private func startObservingPlayer(originalScrubPosition: Int64, targetScrubPosition: Int64) {
        var originalPosition = originalScrubPosition
        var targetPosition = targetScrubPosition
        
        self.tech.addPeriodicTimeObserverToPlayer { [weak self] time in
            guard let `self` = self else {
                return
            }
            
            let isNonScrubbedSeek = targetPosition.rounded() != 0 && self.intendedScrubPosition == 0
            let isResumingFromBookmark = targetPosition == 0 && originalPosition != 0
            let shouldSeekToScrubbedPosition = isNonScrubbedSeek || isResumingFromBookmark
            
            if shouldSeekToScrubbedPosition {
                seekToScrubbedPosition(&originalPosition, &targetPosition)
            } else {
                seekToAdIfNeeded(time, &originalPosition, &targetPosition)
            }
        }
    }
    
    private func seekToScrubbedPosition(_ originalPosition: inout Int64, _ targetPosition: inout Int64) {
        let range = CMTimeRange(
            start: CMTime(milliseconds: originalPosition),
            end: CMTime(milliseconds: targetPosition)
        )
        
        guard let adBreakIndex = findAdBreakIndex(for: range),
              let offset = self.adMarkerPositions[adBreakIndex].offset,
              let adClipIndex = findAdClipIndex(for: offset)
        else {
            self.isSeekUserInitiated = true
            originalPosition = 0
            targetPosition = 0
            return
        }
        
        let adClip = self.allTimelineContent[adClipIndex]
        let wasAdPlayedBefore = self.alreadyPlayedAds.contains(adClip)
        
        guard !wasAdPlayedBefore else {
            self.isSeekUserInitiated = true
            originalPosition = 0
            targetPosition = 0
            return
        }
        seekToAd(adClip, &originalPosition, &targetPosition)
    }
    
    fileprivate func seekToAd(
        _ adClip: TimelineContent,
        _ originalPosition: inout Int64,
        _ targetPosition: inout Int64
    ) {
        // temporary store the previously assigned playhead time. After the ads are played, player will seek to this position
        self.intendedScrubPosition = targetPosition
        
        // reset temporary stored values
        originalPosition = 0
        targetPosition = 0
        
        // Make it as SDK initiated seek.
        self.isSeekUserInitiated = false
        self.context.onServerSideAdShouldSkip(Int64(adClip.contentStartTime + 100))
    }
    
    private func seekToAdIfNeeded(_ time: CMTime, _ originalPosition: inout Int64, _ targetPosition: inout Int64) {
        originalPosition = 0
        targetPosition = 0
        
        let _ = self.allTimelineContent.enumerated().compactMap { index, content in
            if var start = content.timeRange.start.milliseconds , var end = content.timeRange.end.milliseconds, var timeInMil = time.milliseconds {
                
                timeInMil = self.makeLastDigitZero(timeInMil)
                start = self.makeLastDigitZero(start)
                end = self.makeLastDigitZero(end)
                
                if start.rounded() <= timeInMil &&
                    end.rounded() + 10 >= timeInMil &&
                    content.contentType == "ad" &&
                    !self.alreadyPlayedAds.contains(content) {
                    
                    if let adClipIndex = self.allTimelineContent.firstIndex(where:  { content.timeRange.containsTimeRange($0.timeRange) }) {
                        
                        let duration = end.rounded() - start.rounded()
                        
                        let clipFirstQuartile =  start + (duration)/4
                        let clipMidpoint = start + ( duration)/2
                        let clipThirdQuartile = start + ((duration) * 3/4)
                        
                        let clip = self.clips[adClipIndex]
                        
                        if timeInMil.rounded() == clipFirstQuartile.rounded()  {
                            
                            // Send firstQuartile tracking events
                            if let firstQuartileUrls = clip.trackingEvents?.firstQuartile {
                                if !self.alreadySentAdTrackingUrls.contains(firstQuartileUrls) {
                                    self.context.trackAds(adTrackingUrls: firstQuartileUrls)
                                    self.alreadySentAdTrackingUrls.append( firstQuartileUrls )
                                }
                            }
                            
                        } else if timeInMil.rounded() == clipMidpoint.rounded() {
                            
                            // Send clipMidpoint tracking events
                            if let midpointUrls = clip.trackingEvents?.midpoint {
                                if !self.alreadySentAdTrackingUrls.contains(midpointUrls) {
                                    self.context.trackAds(adTrackingUrls: midpointUrls)
                                    self.alreadySentAdTrackingUrls.append( midpointUrls )
                                }
                            }
                            
                        } else if timeInMil.rounded() == clipThirdQuartile.rounded()  {
                            
                            // Send thirdQuartile tracking events
                            if let thirdQuartileUrls = clip.trackingEvents?.thirdQuartile {
                                if !self.alreadySentAdTrackingUrls.contains(thirdQuartileUrls) {
                                    self.context.trackAds(adTrackingUrls: thirdQuartileUrls)
                                    self.alreadySentAdTrackingUrls.append( thirdQuartileUrls )
                                }
                            }
                            
                        } else if timeInMil.rounded() == end.rounded() {
                            
                            // Send complete tracking events
                            if let completeUrls = clip.trackingEvents?.complete {
                                if !self.alreadySentAdTrackingUrls.contains(completeUrls) {
                                    self.context.trackAds(adTrackingUrls: completeUrls)
                                    self.alreadySentAdTrackingUrls.append( completeUrls )
                                }
                            }
                            
                            // Send EMP analytics
                            if let adMediaId = clip.titleId {
                                self.tech.currentSource?.analyticsConnector.providers
                                    .compactMap{ $0 as? ExposureAnalytics }
                                    .forEach{ $0.onAdCompleted(tech: self.tech, source: self.source, adMediaId: adMediaId) }
                            }
                            
                            self.alreadyPlayedAds.append(content)
                            
                            self.policy.fastForwardEnabled = self.source.entitlement.ffEnabled
                            self.policy.rewindEnabled = self.source.entitlement.rwEnabled
                            self.policy.timeshiftEnabled = self.source.entitlement.timeshiftEnabled
                            self.source.contractRestrictionsService.contractRestrictionsPolicy = self.policy
                            
                            
                            self.context.onDidPresentInterstitial(self.source.contractRestrictionsService)
                            
                            
                            // Check if all the ads are played , if so reset the temporary stored values for AdCounter
                            if (self.numberOfAdsInAdBreak - self.currentAdIndexInAdBreak) == 0 {
                                self.nextVodClipIndex = 0
                                self.previousVodClipIndex = 0
                                self.numberOfAdsInAdBreak = 0
                                self.currentAdIndexInAdBreak = 0
                            }
                            
                            // remove the temporary stored adTracking urls
                            self.alreadySentAdTrackingUrls.removeAll()
                        } else {
                            
                            /// Note :
                            // Some content may not have the `timeInMil` 0 when start. It seems like `PeriodicTimeObserverToPlayer` may have a slight delay and then timeInMil may be higher than the `start`. [ Add a second condition to check if timeInMil is larger than start :=> Ad has already started] . But this will only run once when the ad has started.
                            if timeInMil.rounded() + 10 == start.rounded() + 10 ||
                                timeInMil.rounded() + 10 > start.rounded() + 10 {
                                
                                // This will prevent sending multiple start events
                                if !(self.alreadyStartedAds.contains(content)) {
                                    
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
                                    self.alreadyStartedAds.append(content)
                                    
                                    
                                    self.calculateAdCounterValues(adClipIndex, end, start)
                                    self.context.onWillPresentInterstitial(self.source.contractRestrictionsService , clip.videoClicks?.clickThroughUrl, clip.videoClicks?.clickTrackingUrls, Int64(clip.duration ?? 0), self.numberOfAdsInAdBreak, self.currentAdIndexInAdBreak )
                                }
                            }
                        }
                    }
                }
                
                // Ad is already watched
                else if start.rounded() <= timeInMil.rounded() &&
                            end.rounded() >= timeInMil.rounded() &&
                            content.contentType == "ad" &&
                            self.alreadyPlayedAds.contains(content) {
                    
                    // Check if we have a previously assigned destination
                    if self.intendedScrubPosition != 0 {
                        // Check if the next content is an Ad or not , if it's not assign the `tempDestination` & seek to that destination after the ad
                        if ( index != (self.allTimelineContent.count - 1) && self.allTimelineContent[index+1].contentType != "ad" ) {
                            
                            // Make it as a user initiated seek
                            self.isSeekUserInitiated = true
                            
                            let tempDestination = self.intendedScrubPosition
                            
                            // Reset oldScrubbedDestination value
                            self.intendedScrubPosition = 0
                            
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
                            self.isSeekUserInitiated = false
                            
                            self.context.onServerSideAdShouldSkip( Int64(vodClip.contentStartTime + 1000) )
                        } else {
                            self.isSeekUserInitiated = true
                        }
                    }
                }
                else {
                    return
                }
            }
        }
    }
    
    private func findAdBreakIndex(for range: CMTimeRange) -> Array<MarkerPoint>.Index? {
        return self.adMarkerPositions.lastIndex {
            guard let startOffset = $0.offset , let endOffset = $0.endOffset else {
                return false
            }
            
            let adRange = CMTimeRange(
                start: CMTime(milliseconds: Int64(startOffset)),
                end: CMTime(milliseconds:  Int64(endOffset))
            )
            
            return range.containsTimeRange(adRange)
        }
    }
    
    private func findAdClipIndex(for offset: Int) -> Array<TimelineContent>.Index? {
        return self.allTimelineContent.firstIndex {
            $0.contentStartTime.rounded() == offset.rounded() && $0.contentType == "ad"
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
            // Assign value to previousVodClipIndex only if  previousVodClipIndex == 0 means, no value has been assigned or reset after playing an full Ad Break
            if previousVodClipIndex == 0 {
                previousVodClipIndex = 0
            }
            
            // Find the next vod clip index
            if let next = self.allTimelineContent.firstIndex(where:  { Int64($0.contentStartTime + 10 ) > end && $0.contentType != "ad" }) {
                
                // Assign value to nextVodClipIndex only if  nextVodClipIndex == 0 means, no value has been assigned or reseted after playing an full Ad Break
                if nextVodClipIndex == 0 {
                    nextVodClipIndex = next
                }
                
                // Calculate the number of Ads in the ad break
                numberOfAdsInAdBreak = nextVodClipIndex - adClipIndex
                
                // Find the ad clip index inside the ad break
                currentAdIndexInAdBreak = clipIndex
                
            } else {
                // print(" Couldn't find the next vod clip : Should not happen as after a preroll ad break there has to be a VodClip ")
                self.nextVodClipIndex = 0
                self.previousVodClipIndex = 0
                // self.noOfAdsInAdBreak = 0
                
                // Couldn't find the next vod clip , still keep adding the ad index assuming we have another ad
                self.currentAdIndexInAdBreak = clipIndex
            }
        } else {
            
            // adClipIndex is not `0` , This can  still be a pre roll ad break or mid roll ad break
            if let previous = self.allTimelineContent.firstIndex(where:  { Int64($0.contentEndTime ) < ( start + 10 ) && $0.contentType != "ad" }) {

                // Assign value to previousVodClipIndex only if  previousVodClipIndex == 0 means, no value has been assigned or reseted after playing an full Ad Break
                // use adClipIndex as previousVodClipIndex as it should be the same as previous VodClip (or clipIndex - 1 )
                if previousVodClipIndex == 0 {
                    previousVodClipIndex = adClipIndex
                }

                // Find the next vod clip index
                if let next = self.allTimelineContent.firstIndex(where:  { Int64($0.contentStartTime + 10 ) > end && $0.contentType != "ad" }) {
 
                    // Assign value to nextVodClipIndex only if  nextVodClipIndex == 0 means, no value has been assigned or reset after playing an full Ad Break
                    if nextVodClipIndex == 0 {
                        nextVodClipIndex = next
                    }
                    numberOfAdsInAdBreak = nextVodClipIndex - previousVodClipIndex
                    currentAdIndexInAdBreak =  clipIndex - previousVodClipIndex
                    
                } else {
                    
                    // Couldn't find any Vod Clip as the nextVodClip
                    // There was a previous vod clip but no next vod clip . Should be a post roll ad break
                    // Assign value to nextVodClipIndex only if  nextVodClipIndex == 0 means, no value has been assigned or reseted after playing an full Ad Break
                    if nextVodClipIndex == 0 {
                        
                        // Assume the previous clip index is the same as current playing first ad of the post roll ad break
                        previousVodClipIndex = adClipIndex
                        
                        // Assign the last index as the nextVodClipIndex
                        nextVodClipIndex = self.allTimelineContent.count
                    }
                    
                    numberOfAdsInAdBreak = nextVodClipIndex - previousVodClipIndex
                    currentAdIndexInAdBreak =  clipIndex - previousVodClipIndex
                    
                }
                
                
            } else {
                
                // Couldn't find any previous vod clips : So still a pre roll ad break
                
                // Make the previousVodClipIndex to 0 , as there are no any VodClips before the preroll Ad
                // Assign value to previousVodClipIndex only if  previousVodClipIndex == 0 means, no value has been assigned or reseted after playing an full Ad Break
                if previousVodClipIndex == 0 {
                    previousVodClipIndex = 0
                }
                
                // Find the next vod clip index
                if let next = self.allTimelineContent.firstIndex(where:  { Int64($0.contentStartTime) > end && $0.contentType != "ad" }) {
                    
                    
                    // Assign value to nextVodClipIndex only if nextVodClipIndex == 0 means, no value has been assigned or reseted after playing an full Ad Break
                    if nextVodClipIndex == 0 {
                        nextVodClipIndex = next
                    }
                    
                    numberOfAdsInAdBreak = nextVodClipIndex - previousVodClipIndex
                    currentAdIndexInAdBreak = clipIndex
                } else {
                    // print(" Couldn't find the next vod clip : Should not happen as after a preroll ad break there has to be a VodClip ")
                    self.nextVodClipIndex = 0
                    self.previousVodClipIndex = 0
                    // self.noOfAdsInAdBreak = 0
                    
                    // Couldn't find the next vod clip , still keep adding the ad index assuming we have another ad
                    self.currentAdIndexInAdBreak = clipIndex
                }
            }
        }
    }
}

// MARK: Preparation
extension ServerSideAdService {
    
    /// Prepare Ad service with initial clips & timeline content
    private func prepareAdService() {
        var vodDuration: Int64 = 0
        var totalDuration: Int64  = 0
        var totalAdDuration: Int64 = 0
        
        // Reset admarker arrays
        self.adMarkerPositions.removeAll()
        self.tempAdMarkerPositions.removeAll()
        
        if let clips = self.ads.clips {
            
            // Total Duration in milliseconds
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
                        // If so create a new adMarker with offset value of the first element & endoffset value from the last element
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

// MARK: - Unused AdService protocol methods
extension ServerSideAdService {
    public func playbackReady() {
        // print(" Play back ready ")
    }
    
    public func playbackPaused() {
        // self.timer?.invalidate()
    }
    
    public func playbackResumed() {
        // playbackResumed
    }
    
    public func playbackBufferingStarted() {
        // print(" playbackBufferingStarted")
    }
    
    public func playbackBufferingEnded() {
        // print("playbackBufferingEnded")
        
    }
    
    public func playbackTimedMetadata(metaData: Any?) {
        // print(" playbackTimedMetadata " , (metaData: Any?) )
    }
    
    public func prepareAsset(source: URL, callback: @escaping (URL) -> Void) {
        // print(" prepareAsset")
    }
    
    public func prepareProgram(source: URL, callback: @escaping (URL) -> Void) {
        // print(" prepareProgram")
    }
    
    public func prepareChannel(source: URL, callback: @escaping (URL) -> Void) {
        // print(" prepareChannel")
    }
}

// MARK: - Helper extensions
/// The purpose of these extensions is to essentially remove the last digit of integer part
/// and replace it with a zero, effectively rounding down to the nearest multiple of 10.
fileprivate extension Double {
    func rounded() -> Int {
        Int(self) / 10 * 10
    }
}

fileprivate extension Int {
    func rounded() -> Self {
        self / 10 * 10
    }
}

fileprivate extension Int64 {
    func rounded() -> Self {
        self / 10 * 10
    }
}
