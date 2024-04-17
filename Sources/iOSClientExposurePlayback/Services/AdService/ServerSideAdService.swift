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
    
    private var allTimelineContent: [TimelineContent] = []
    
    /// This will store all the ads that are already played during the current session
    private var alreadyPlayedAds: [TimelineContent] = []
    
    /// This property keep track of already started ads
    private var alreadyStartedAds: [TimelineContent] = []
    
    /// Temporary store all adTracking urls of an Ad to prevent sending multiple trackings events to the backend
    private var alreadySentAdTrackingUrls: [[String]] = []
    
    /// Whenver content type is not an`ad` append the first item from `tempAdMarkerPositions` & reset `tempAdMarkerPositions` array.
    private var adMarkerPositions: [MarkerPoint] = []
    
    /// This will be used to store Ad marker positions temporary, when there are multiple `adMarkers` `tempAdMarkerPositions` will hold them until next clip is not an `ad` , then append the first item to the `adMarkerPositions` array.
    ///
    /// Note:- Reason for this is to show only the combined adMarker in the timeline. : If there are mutiple Ads playing together , it will show as one marker in the timeline
    private var tempAdMarkerPositions: [MarkerPoint] = []
    
    /// When seek / scrub is initiated it will check if the seek is initiated by the user or by the sdk.
    private var isSeekUserInitiated: Bool = true
    
    /// Use this as a temporary to store user's scrubbed / seek destination. When there is an `ad` in between current location & scrubbed destination, sdk will first play the `ad` & then jump to this scrubbed destination
    private var intendedScrubPosition: Int64?
    
    /// Seek started from this position
    private var originalScrubPosition: Int64 = 0
    
    /// Variables used for Ad Counter
    private var numberOfAdsInAdBreak: Int = 0
    private var currentAdIndexInAdBreak: Int = 0
    
    public init(
        ads: Ads,
        clips: [AdClips],
        context: ExposureContext,
        source: ExposureSource,
        durationInMs: Double,
        tech: HLSNative<ExposureContext>
    ) {
        self.ads = ads
        self.context = context
        self.source = source
        self.durationInMs = durationInMs
        self.tech = tech
        self.clips = clips
        
        deallocAll()
    }
    
    public func playbackStarted() {
        deallocAll()
        prepareAdService()
        startAdService()
    }
    
    public func playbackAborted() {
        deallocAll()
    }
    
    public func playbackEnded() {
        deallocAll()
    }
    
    /// Clear & de allocate
    private func deallocAll() {
        alreadyPlayedAds.removeAll()
        alreadyStartedAds.removeAll()
        alreadySentAdTrackingUrls.removeAll()
        allTimelineContent.removeAll()
        adMarkerPositions.removeAll()
        intendedScrubPosition = nil
        originalScrubPosition = 0
        tech.removePeriodicTimeObserverToPlayer()
        isSeekUserInitiated = true
        numberOfAdsInAdBreak = 0
        currentAdIndexInAdBreak = 0
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
        originalScrubPosition = 0
        #else
        originalScrubPosition = origin
        #endif
    }
    
    /// Seek request Triggered / scrub ended
    /// - Parameter destination: withTargetPosition
    public func seekRequestTriggered(withTargetPosition destination: Int64) {
        scrubbed(destination)
    }
    
    public var playerProxy: AdPlayerProxy?
    
    public var contractRestrictionsService: ContractRestrictionsService?
    
    private func getNextClip(index: Int, _ completion: @escaping (Int?) -> Void) {}
    
    /// Start Ad service when play back starts
    private func startAdService() {
        startObservingPlayer(
            originalScrubPosition: 0,
            targetScrubPosition: tech.playheadPosition
        )
    }
    
    private func scrubbed(_ targetScrubPosition: Int64) {
        guard isSeekUserInitiated else {
            isSeekUserInitiated = true
            return
        }
        tech.removePeriodicTimeObserverToPlayer()
        startObservingPlayer(
            originalScrubPosition: originalScrubPosition,
            targetScrubPosition: targetScrubPosition
        )
    }
}

// MARK: Playback
extension ServerSideAdService {
    private func startObservingPlayer(originalScrubPosition: Int64, targetScrubPosition: Int64) {
        var originalPosition = originalScrubPosition
        var targetPosition = targetScrubPosition
        var isFirstTick = true
        
        tech.addPeriodicTimeObserverToPlayer { [weak self] time in
            guard let self else {
                return
            }
            
            if isFirstTick {
                isFirstTick = false
                checkSeekRangeForAds(&originalPosition, &targetPosition)
            } else {
                checkCurrentTimeForAds(time, &originalPosition, &targetPosition)
            }
        }
    }
    
    private func checkSeekRangeForAds(_ originalPosition: inout Int64, _ targetPosition: inout Int64) {
        let range = CMTimeRange(
            start: CMTime(milliseconds: originalPosition),
            end: CMTime(milliseconds: targetPosition)
        )
        
        guard let adBreakIndex = findAdBreakIndex(for: range),
              let offset = adMarkerPositions[adBreakIndex].offset,
              let adClipIndex = findAdClipIndex(for: offset)
        else {
            isSeekUserInitiated = true
            originalPosition = 0
            targetPosition = 0
            return
        }
        
        let adClip = allTimelineContent[adClipIndex]
        let wasAdPlayedBefore = alreadyPlayedAds.contains(adClip)
        
        guard !wasAdPlayedBefore else {
            isSeekUserInitiated = true
            originalPosition = 0
            targetPosition = 0
            return
        }
        seekToAd(adClip, &originalPosition, &targetPosition)
    }
    
    private func seekToAd(
        _ adClip: TimelineContent,
        _ originalPosition: inout Int64,
        _ targetPosition: inout Int64
    ) {
        // Temporary store the previously assigned playhead time.
        // After the ads are played, player will seek to this position
        intendedScrubPosition = targetPosition
        
        // reset temporary stored values
        originalPosition = 0
        targetPosition = 0
        
        isSeekUserInitiated = false
        context.onServerSideAdShouldSkip(Int64(adClip.contentStartTime + 100))
    }
    
    private func checkCurrentTimeForAds(_ time: CMTime, _ originalPosition: inout Int64, _ targetPosition: inout Int64) {
        originalPosition = 0
        targetPosition = 0
        
        guard let timeInMiliseconds = time.milliseconds?.rounded() else {
            return
        }
        
        for (index, content) in allTimelineContent.enumerated() {
            guard let start = content.timeRange.start.milliseconds?.rounded(),
                  let end = content.timeRange.end.milliseconds?.rounded(),
                  start <= timeInMiliseconds,
                  end >= timeInMiliseconds,
                  content.contentType == "ad"
            else {
                continue
            }
            
            if !alreadyPlayedAds.contains(content) {
                handleNotWatchedYetAd(content, start, end, timeInMiliseconds)
            } else {
                handleAlreadyWatchedAd(index, content)
            }
        }
    }
    
    private func handleNotWatchedYetAd(
        _ content: TimelineContent,
        _ start: Int64,
        _ end: Int64,
        _ timeInMiliseconds: Int64
    ) {
        if let adClipIndex = allTimelineContent.firstIndex(
            where: { content.timeRange.containsTimeRange($0.timeRange) }
        ) {
            let duration = end.rounded() - start.rounded()
            
            let clipFirstQuartile = (start + duration / 4).rounded()
            let clipMidpoint = (start + duration / 2).rounded()
            let clipThirdQuartile = (start + duration * 3/4).rounded()
            let clipEnd = end.rounded()
            
            let clip = clips[adClipIndex]
            
            switch timeInMiliseconds.rounded() {
            case clipFirstQuartile:
                sendTrackingEvents(clip.trackingEvents?.firstQuartile)
            case clipMidpoint:
                sendTrackingEvents(clip.trackingEvents?.midpoint)
            case clipThirdQuartile:
                sendTrackingEvents(clip.trackingEvents?.thirdQuartile)
            case clipEnd:
                sendTrackingEvents(clip.trackingEvents?.complete)
                handleAdEnd(clip, content)
            default:
                handleAdStartWithDelay(content, start, end, timeInMiliseconds, adClipIndex)
            }
        }
    }
    
    private func sendTrackingEvents(_ point: [String]?) {
        guard let point,
              !alreadySentAdTrackingUrls.contains(point)
        else {
            return
        }
        
        context.trackAds(adTrackingUrls: point)
        alreadySentAdTrackingUrls.append(point)
    }
    
    private func handleAdEnd(_ clip: AdClips, _ content: TimelineContent) {
        // Send EMP analytics
        if let adMediaId = clip.titleId {
            tech.currentSource?.analyticsConnector.providers
                .compactMap{ $0 as? ExposureAnalytics }
                .forEach{ $0.onAdCompleted(tech: tech, source: source, adMediaId: adMediaId) }
        }
        
        alreadyPlayedAds.append(content)
        
        policy.fastForwardEnabled = source.entitlement.ffEnabled
        policy.rewindEnabled = source.entitlement.rwEnabled
        policy.timeshiftEnabled = source.entitlement.timeshiftEnabled
        source.contractRestrictionsService.contractRestrictionsPolicy = policy
        
        context.onDidPresentInterstitial(source.contractRestrictionsService)
        
        // Check if all the ads are played, if so reset the temporary stored values for AdCounter
        if (numberOfAdsInAdBreak - currentAdIndexInAdBreak) == 0 {
            numberOfAdsInAdBreak = 0
            currentAdIndexInAdBreak = 0
            
            seekToIntendedScrubPosition()
        }
        
        // remove the temporary stored adTracking urls
        alreadySentAdTrackingUrls.removeAll()
    }
    
    private func seekToIntendedScrubPosition() {
        guard let intendedScrubPosition else {
            return
        }
        isSeekUserInitiated = true
        context.onServerSideAdShouldSkip(intendedScrubPosition)
        self.intendedScrubPosition = nil
    }
    
    private func handleAdStartWithDelay(
        _ content: TimelineContent,
        _ start: Int64,
        _ end: Int64,
        _ timeInMiliseconds: Int64,
        _ adClipIndex: Array<TimelineContent>.Index
    ) {
        guard timeInMiliseconds.rounded() >= start.rounded(),
              !alreadyStartedAds.contains(content)
        else {
            return
        }
        
        let clip = clips[adClipIndex]
        
        // Send load tracking events
        context.trackAds(adTrackingUrls: clip.trackingEvents?.load ?? [])
        
        // Send start tracking events
        context.trackAds(adTrackingUrls: clip.trackingEvents?.start ?? [])
        
        policy.fastForwardEnabled = false
        policy.rewindEnabled = false
        policy.timeshiftEnabled = source.entitlement.timeshiftEnabled
        source.contractRestrictionsService.contractRestrictionsPolicy = policy
        
        context.trackAds(adTrackingUrls: clip.impressionUrlTemplates ?? [])
        
        if let adMediaId = clip.titleId {
            tech.currentSource?.analyticsConnector.providers
                .compactMap{ $0 as? ExposureAnalytics }
                .forEach{ $0.onAdStarted(tech: tech, source: source, adMediaId: adMediaId) }
        }
        
        // Keep track of already started ads
        alreadyStartedAds.append(content)
        
        calculateAdCounterValues(adClipIndex)
        
        context.onWillPresentInterstitial(
            source.contractRestrictionsService,
            clip.videoClicks?.clickThroughUrl,
            clip.videoClicks?.clickTrackingUrls,
            Int64(clip.duration ?? 0),
            numberOfAdsInAdBreak,
            currentAdIndexInAdBreak
        )
    }
    
    private func handleAlreadyWatchedAd(_ index: Int, _ content: TimelineContent) {
        // Find the next `Non Ad` clip & seek to that
        guard let vodClipIndex = allTimelineContent.firstIndex(
            where: { $0.contentType != "ad" && ($0.contentStartTime + 10 > content.contentEndTime) }
        ) else {
            isSeekUserInitiated = true
            return
        }
        
        let vodClip = allTimelineContent[vodClipIndex]
        
        isSeekUserInitiated = false
        context.onServerSideAdShouldSkip(Int64(vodClip.contentStartTime + 1000))
    }
    
    private func findAdBreakIndex(for range: CMTimeRange) -> Array<MarkerPoint>.Index? {
        return adMarkerPositions.lastIndex {
            guard let startOffset = $0.offset , let endOffset = $0.endOffset else {
                return false
            }
            
            let adRange = CMTimeRange(
                start: CMTime(milliseconds: Int64(startOffset)),
                end: CMTime(milliseconds: Int64(endOffset))
            )
            
            return range.containsTimeRange(adRange)
        }
    }
    
    private func findAdClipIndex(for offset: Int) -> Array<TimelineContent>.Index? {
        return allTimelineContent.firstIndex {
            $0.contentStartTime.rounded() == offset.rounded() && $0.contentType == "ad"
        }
    }
}

// MARK: - Ad counter values
extension ServerSideAdService {
    private func calculateAdCounterValues(
        _ currentAdIndex: Array<TimelineContent>.Index
    ) {
        var firstAdIndex = currentAdIndex
        var lastAdIndex = currentAdIndex
        
        while allTimelineContent[safeIndex: firstAdIndex - 1]?.contentType == "ad" {
            firstAdIndex -= 1
        }
        
        while allTimelineContent[safeIndex: lastAdIndex + 1]?.contentType == "ad" {
            lastAdIndex += 1
        }
        
        currentAdIndexInAdBreak = currentAdIndex - firstAdIndex + 1
        numberOfAdsInAdBreak = lastAdIndex - firstAdIndex + 1
    }
}

// MARK: Preparation
extension ServerSideAdService {
    /// Prepare Ad service with initial clips & timeline content
    private func prepareAdService() {
        var vodDuration: Int64 = 0
        var totalDuration: Int64 = 0
        var totalAdDuration: Int64 = 0
        
        // Reset admarker arrays
        adMarkerPositions.removeAll()
        tempAdMarkerPositions.removeAll()
        
        guard let clips = ads.clips else {
            return
        }
        
        // Total Duration in milliseconds
        let totalclipDuration = clips.compactMap { ($0.duration ?? 0) }.reduce(0, +)
        
        totalDuration = Int64(totalclipDuration)
        
        totalAdDuration = clips.compactMap {
            if ($0.category == "ad") {
                return Int64($0.duration ?? 0)
            } else {
                return 0
            }
        }.reduce(0, +)
        
        prepareTimeline(clips, totalDuration, &vodDuration)
        context.onPlaybackStartWithAds(vodDuration, totalAdDuration, totalDuration, adMarkerPositions)
    }
    
    private func prepareTimeline(_ clips: [AdClips], _ totalDuration: Int64, _ vodDuration: inout Int64) {
        var currentDuration: Float = 0
        
        for (index, clip) in clips.enumerated() {
            // Add the clip duration to currentTotalDuration
            guard let duration = clip.duration else {
                continue
            }
            
            let clipStartTime = Double(currentDuration)
            let clipEndTime = Double(currentDuration + duration )
            
            let timeRange = CMTimeRange(
                start: CMTime(milliseconds: Int64(clipStartTime)),
                end: CMTime(milliseconds: Int64(clipEndTime))
            )
            
            let timelineContent = TimelineContent(
                contentType: clip.category,
                contentTitle: clip.title,
                contentStartTime: clipStartTime,
                contentEndTime: clipEndTime,
                timeRange: timeRange
            )
            
            allTimelineContent.append(timelineContent)
            
            // Clips is an ad, should add an adMarker to the timeLine on ad starting point
            if clip.category == "ad" {
                addAdMarkerOnTimeline(index, duration, &currentDuration, clips, totalDuration)
            } else {
                // Clip is not an ad, add it to vodDuration
                vodDuration = vodDuration + Int64(duration)
                currentDuration = currentDuration + duration
                
                // Clip is not an AD: Create a new ad marker if the tempAdMarkerPositions is not empty
                // Check if there are any values in tempAdMarkerPositions.
                // If so create a new adMarker with offset value of the first element & endoffset value from the last element
                if let offset = tempAdMarkerPositions.first?.offset,
                   let endOffset = tempAdMarkerPositions.last?.endOffset {
                    let markerPoint = MarkerPoint(
                        type: "Ad",
                        offset: offset,
                        endOffset: endOffset
                    )
                    adMarkerPositions.append(markerPoint)
                    tempAdMarkerPositions.removeAll()
                }
            }
        }
    }
    
    private func addAdMarkerOnTimeline(
        _ index: Int,
        _ duration: Float,
        _ currentDuration: inout Float,
        _ clips: [AdClips],
        _ totalDuration: Int64
    ) {
        switch index {
        case 0:
            let markerPoint = MarkerPoint(
                type: "Ad",
                offset: 0,
                endOffset: Int(duration)
            )
            tempAdMarkerPositions.append(markerPoint)
            currentDuration = currentDuration + duration
        case 1 ..< clips.count - 1:
            let markerPoint = MarkerPoint(
                type: "Ad",
                offset: Int(currentDuration),
                endOffset: Int(currentDuration + duration)
            )
            currentDuration = currentDuration + duration
            tempAdMarkerPositions.append(markerPoint)
        case clips.count - 1:
            // If the last clip is an Ad, we check the tempAdMarkerPositions to find if there are any elements/ads before the last ad clip. If so, get the offSet value from the first element & use the totalDuration value as the endOffset
            if let offset = tempAdMarkerPositions.first?.offset {
                let markerPoint = MarkerPoint(
                    type: "Ad",
                    offset: offset,
                    endOffset: Int(totalDuration)
                )
                adMarkerPositions.append(markerPoint)
            } else {
                let markerPoint = MarkerPoint(
                    type: "Ad",
                    offset: Int(currentDuration),
                    endOffset: Int(totalDuration)
                )
                adMarkerPositions.append(markerPoint)
            }
            tempAdMarkerPositions.removeAll()
        default:
            // Clip type is an Ad, but something is wrong with index & clip duration
            break
        }
    }
}

// MARK: - Unused AdService protocol methods
extension ServerSideAdService {
    public func playbackReady() {}
    
    public func playbackPaused() {}
    
    public func playbackResumed() {}
    
    public func playbackBufferingStarted() {}
    
    public func playbackBufferingEnded() {}
    
    public func playbackTimedMetadata(metaData: Any?) {}
    
    public func prepareAsset(source: URL, callback: @escaping (URL) -> Void) {}
    
    public func prepareProgram(source: URL, callback: @escaping (URL) -> Void) {}
    
    public func prepareChannel(source: URL, callback: @escaping (URL) -> Void) {}
}

// MARK: - Helper extensions
// The purpose of these extensions is to round number to the nearest multiple of 10.
private extension Double {
    func rounded() -> Int {
        Int(self.rounded(.toNearestOrAwayFromZero))
    }
}

private extension Int {
    func rounded() -> Self {
        let lastDigit = self % 10
        if lastDigit < 5 {
            return self - lastDigit
        } else {
            return self + 10 - lastDigit
        }
    }
}

private extension Int64 {
    func rounded() -> Self {
        let lastDigit = self % 10
        if lastDigit < 5 {
            return self - lastDigit
        } else {
            return self + 10 - lastDigit
        }
    }
}
