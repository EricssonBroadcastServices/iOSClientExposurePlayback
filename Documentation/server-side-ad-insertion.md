#### Server-Side Ad Insertion (SSAI)

**Preparation**

If you are planning to use server side ad insertion with the player you can set `AdsOptions` to pass client / device specific information that can be used for ad targeting when starting the playback.

```Swift
let adsOptions = AdsOptions(latitude: 18.000, longitude: 18.000, mute: true, consent: "consent", deviceMake: "deviceMake", ifa: "ifa", gdprOptin: true)
player.startPlayback(playable: assetPlayable, properties: properties, adsOptions: adsOptions)
```

**Events Related to SSAI** 

If the stream has server side ads enabled player will publish several events related to the ads. 

You can replace your `.onPlaybackStarted` event with `.onPlaybackStartWithAds` which will return several attributes related to the ads. 

```Swift
.onPlaybackStartWithAds { [weak self] vodDurationInMs, adDurationInMs, totalDurationInMs, adMarkers   in 
    // vodDurationInMs : Actual vod content duration 
    // adDurationInMs : Total Ads duration 
    // totalDurationInMs : Total duration ( vod + ads )
    // adMarkers : Ad Markers ( MarkerPoints) that you can place in your timeline

}
```

Player will publish `onWillPresentInterstitial` when an Ad starts playing & `onDidPresentInterstitial` when an Ad ends playing.

```Swift
.onWillPresentInterstitial { [weak self] contractRestrictionService, clickThroughUrl, adTrackingUrls, adClipDuration, noOfAds, adIndex  in 

    // contractRestrictionService : contractRestrictionsPolicy.fastForwardEnabled & contractRestrictionsPolicy.rewindEnabled
    // clickThroughUrl : External link to navigate to when the user clicked the ad. ( ex : Show / hide link button when ad is playing )
    // adTrackingUrls : If user clicked the ad `clickThroughUrl` link / button, send these Urls back to the player to track the ad click. 
    // adClipDuration : Duration of the currently playing ad clip
    // noOfAds : Number of ads in the ad break
    // adIndex : Index of the current playing ad
}

.onDidPresentInterstitial { [weak self] contractRestrictionService  in
    // contractRestrictionService : contractRestrictionsPolicy.fastForwardEnabled & contractRestrictionsPolicy.rewindEnabled
}
```

Player will publish `onServerSideAdShouldSkip` event as it requires the player to seek specific position. App developers must implement this event.

```Swift
.onServerSideAdShouldSkip { [weak self] skipTime in
    self.player.seek(toPosition: Int64(skipTime) )        
}
```

**Implementing for tvOS**

When implementing the SSAI on tvOS player, you need to implement the following method to

```
class PlayerViewController: UIViewController, AVPlayerViewControllerDelegate {
        func playerViewController(_ playerViewController: AVPlayerViewController,
        willResumePlaybackAfterUserNavigatedFrom oldTime: CMTime,
                                  to targetTime: CMTime) {
            if let targetTime = targetTime.milliseconds {
                self.player.seek(toPosition: targetTime)
            }
        }
}
```

**Tracking Ad's clickThroughUrl**

Optionally app developers can use `clickThroughUrl` to navigate the users to the Ad´s external link if the ad contains that url. This can be done adding a button / link in the player skin. 

When / if the clickThroughUrl button is clicked , app developers should pass relevant `adTrackingUrls` back to the player to track & send analytics back to the ad server. 

```Swift
self.player.trackClickedAd(adTrackingUrls: adTrackingUrls)
```


