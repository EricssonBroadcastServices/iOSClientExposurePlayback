## Live and Catchup Playback

### Epg and Content Presentation
The [`Exposure` module](https://github.com/EricssonBroadcastServices/iOSClientExposure) provides metadata integration with *EMP Exposure layer* for quick and typesafe content access.

Listing all available *channels* can be done by calling

```Swift
FetchAsset(environment: environment)
    .list()
    .includeUserData(for: sessionToken)
    .filter(on: "TV_CHANNEL")
    .sort(on: ["assetId","originalTitle"])
    .request()
    .validate()
    .response{
        if let assetList = $0.value {
            // Present a list of channels
        }
    }
```

*EPG*, or the *electronic programming guide*, details previous, current and upcomming programs on a specific channel. Client applications may request *EPG* data through the `FetchEpg` endpoint.


```Swift
let current = player.serverTime ?? Date()

FetchEpg(environment: environment)
    .channel(id: channelId)
    .show(page: 1, spanning: 100)
    .filter(starting: current.subtract(days: 1), ending: current.add(days: 1) ?? current)
    .request()
    .validate()
    .response{
        if let channelEpg = $0.value {
            // Present the EPG
        }
    }
```

Client applications relying on `ExposureContext` may also fetch the currently playing `Program` directly from the `player` object.

```Swift
let nowPlaying = player.currentProgram
```

Or listen to the `onProgramChanged` event.

```Swift
player.onProgramChanged { player, source, program in
    // Update user facing program information
}
```


### Playing a Live Channel
Starting playback of a live channel is as simple as supplying `Player` with a `ChannelPlayable`. This can be done by creating one by specifying a channelId.

```Swift
let channelPlayable = ChannelPlayable(assetId: "channelId")
player.startPlayback(playable: channelPlayable)
```

Or, thanks to the seamless integration with [`Exposure` module](https://github.com/EricssonBroadcastServices/iOSClientExposure/blob/master), simply supply a previously fetched channel `Asset`s.

```Swift
func play(channel: Asset) {
    player.startPlayback(playable: channel.channelPlayable)
}
```

Playback started through a `ChannelPlayable` equates to starting the currently live program and will continue with the next program until the user is no longer entitled, for example due to a *blackout*.


### Playing a Program on a Channel
The proceedure for playing a specific program is identical to that when starting a live channel, except the client applications should supply `Player` with a `ProgramPlayable`.

```Swift
let programPlayable = ProgramPlayable(assetId: "programId", channelId: "channelId")
player.startPlayback(playable: programPlayable)
```

Or a previously fetched `Program` can be used

```Swift
func play(program: Program) {
    player.startPlayback(playable: program.programPlayable)
}
```

Playback of a program makes no distinction between a currently live program or a catchup program. In fact, playback of a catchup program will continue with the next program until the user is no longer entitled. Applying a *fast forward disabled* contract restriction effectivley turns any program based playback request into *catchup as live*.


### Custom Playback Properties
Client applications can apply custom options to any playback request when the default options needs to be tweaked.

Scenarios include enabling `autoplay` mode, `maximum bitrate` restrictions, `language preferences` and `start time` offset.

With `autoplay` enabled, playback will start as soon as the playback is ready.

```Swift
let properties = PlaybackProperties(autoplay: true)
```

Client applications may opt in to limiting the bitrate at a preferred maximum during playback. Specifying a non-zero value will indicate the player should attempt to limit playback to that bitrate. If network bandwidth consumption cannot be lowered to meet the requested maximum, it will be reduced as much as possible while continuing to play the item.

```Swift
let properties = PlaybackProperties(maxBitrate: 300000)
```

Subtitles and audio preferences can be indicated by specifying `LanguagePreferences` which will be applied automatically if the current playback stream supports the requested selection.

#### Language Preferences

`.defaultBehavior` defers track selection to whatever is specified as default by the selected stream.

```Swift
let properties = PlaybackProperties(language: .defaultBehavior)
```

`.userLocale` takes advantage device's  `Locale` settings when searching for a langugae to select. For example, if the `Locale.current` specifies `fr`, this will be the preferred language. In the event the stream does not support the device´s `Locale`, stream defaults will be applied.

```Swift
let properties = PlaybackProperties(language: .userLocale)
```

Finally, client applications may specify a custom selection for just *subtitles*, *audio* or both.

```Swift
let properties = PlaybackProperties(language: .custom(text: "en", audio: nil))
```

For more information regarding track selection, please see [`Player` module](https://github.com/EricssonBroadcastServices/iOSClientPlayer/blob/master/Documentation/subtitles-and-multi-audio.md)

#### Start Time
`PlaybackProperties` specifies 5 different modes, `PlayFrom`, for defining the playback start position.

* `.beginning` Playback starts from the beginning of the currently live program
* `.bookmark` Playback starts from the bookmarked position if available and fallbacks to `.defaultBehavior`
* `.customPosition(position:)` Playback starts from the specified buffer position (in milliseconds) . Will ignore positions outside the `seekableRange`.
* `.customTime(time:)` Playback starts from the specified *unix timestamp* (in milliseconds). Will ignore timestamps not within the `seekableTimeRange` and present the application with an `invalidStartTime(startTime:seekableRanges:)` warning.

```Swift
let properties = PlaybackProperties(playFrom: .bookmark)
```

The `.defaultBehavior` varies according to stream type:

* Live Channel: `.defaultBehavior` Playback starts from the *live edge*
* Live Program: `.defaultBehavior` Playback starts from the *live edge*
* Catchup Program: `.defaultBehavior` Playback starts from the *program start*


### Stream Navigation
The most intuitive and easy way to navigate the stream is by using the *unix timestamp* based `seek(toTime:)` api which enables client applications seamless transition between programs.

In order to check what unix timestamp *(ms)* the playhead is currently at, client applications use

```Swift
let currentTime = player.playheadTime
```

Two important *ranges* with influence over the playback experience are `seekableTimeRange` and `bufferedTimeRange`.

* `seekableTimeRange` navigating within this range will not require a new play request
* `bufferedTimeRange` navigating within this range will not fetch new segments from the CDN

Although playback started in a specific program, the player will continue playing until it reaches a program without a valid license for the user. Program boundary crossings can occur meaning that the program being displayed has changed. When this happens `onProgramChanged` will fire with updated `Program` information.

*Going live* in a catchup or timeshifted scenario is as easy as calling `seekToLive()`.

```Swift
player.seekToLive()
```

Restarting the currently playing program can be done by calling

```Swift
if let programStartTime = player.currentProgram?.startDate?.millisecondsSince1970 {
    player.seek(toTime: programStartTime)
}
```

Seeking 30 seconds back

```Swift
player.seek(toTime: currentTime - 30 * 1000)
}
```


All information regarding the currently playing program is encapsulated in the `Program` *struct* accessed through `player.currentProgram`. This data can be used to populate the user interface.

In the event that the player tries to play a program, either through natural progression over a program boundary or by stream navigation, that the user does not have the right to watch, playback will stop and throw an `ExposureError.ExposureResponseMessage` specifying `NOT_ENTITLED`.

Continuous validation of the current playback occurs at each program boundary or navigation attempt. If the validation process somehow fails, `onWarning` messages will be triggered. These warnings occur on gaps in EPG or failure to validate or fetch the current program. When this occurs, playback will continue without interruption. Client applications may choose to take other actions, such as stopping playback, if needed.

### Contract Restrictions
Client applications may fetch the playback related *contract restrictions* for the current playback. This can for example be used to enable or disable specific user controls.

```Swift
let entitlement = player.context.entitlement
```

Another option is to register for the `onEntitlementResponse` callback which will fire every time a new entitlement is recieved.

Three `PlaybackEntitlement` propertoes are of special interest

* `ffEnabled` specifies if fast-forwarding is enabled
* `rqwEnabled` specifies if rewinding is enabled
* `timeshiftEnabled` if timeshift is disabled, playback can not be paused

