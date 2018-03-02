## Live and Catchup Playback

### Epg and Content Presentation
The `Exposure` module provides metadata integration with *EMP Exposure layer* for quick and typesafe content access.

Listing all available *channels* can be done by calling

```Swift
FetchAsset(environment: environment)
    .list()
    .includeUserData(for: sessionToken)
    .filter(on: "TV_CHANNEL")
    .sort(on: ["assetId","originalTitle"])
    .request()
    .response{ [weak self] in
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
    // Update userfacing program information
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
Client applications can apply custom options to any playback start when the default options needs to be tweaked.

Scenarios include enabling `autoplay` mode, `maximum bitrate` restrictions, `language preferences` and `start time` offset.

With autoplay enabled, playback will start as soon as the playback is ready.










For more information regarding track selection, please see [Player module](https://github.com/EricssonBroadcastServices/iOSClientPlayer/blob/master/Documentation/subtitles-and-multi-audio.md)



### Stream Navigation

The wallclock related time interface allows for easy and intiutive program seeking. *Going live* in a catchup or timeshifted scenario is as easy as calling `seekToLive()`.

```Swift
player.seekToLive()
```

Additionally, restarting the currently playing program can be done by calling

```Swift
if let programStartTime = player.currentProgram?.startDate?.millisecondsSince1970 {
    player.seek(toTime: programStartTime)
}
```

All information regarding the currently playing program is encapsulated in the `Program` *struct* accessed through `player.currentProgram`. This data can be used to populate the user interface.


### Program Boundaries


### Contract Restrictions
