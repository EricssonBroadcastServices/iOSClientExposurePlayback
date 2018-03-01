## Live and Catchup Playback

#### Epg and Content Presentation
The `Exposure` module provides metadata integration with *EMP Exposure layer* for quick and typesafe content access.

Listing all available *channels* can be done by calling

```Swift
FetchAsset(environment: environment)
    .list()
    .includeUserData(for: sessionToken)
    .filter(on: .tvChannel)
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

Client applications relying obn `ExposureContext` may also fetch the currently playing `Program` directly from the `player` object.

```Swift
let nowPlaying = player.currentProgram
```

Or listen to the `onProgramChanged` event.

```Swift
player.onProgramChanged { tech, source, program in
    // Update userfacing program information
}
```


#### Custom Playback Properties



#### Stream Navigation

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

