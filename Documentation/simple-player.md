## Integrating a Simple Exposure Based Player

#### Authentication
Accessing most functionality on the *EMP Platform* requires a valid `SessionToken`.
Authentication requests return a valid `SessionToken` (or an encapsulating `Credentials`) if the request is successful. This `sessionToken` should be persisted and used in subsequent calls when an authenticated user is required.

```Swift
Authenticate(environment: exposureEnv)
    .login(username: someUser,
           password: somePassword)
    .request()
    .response{
        if let credentials = $0.value {
            // Store/pass along the returned SessionToken
            let sessionToken: SessionToken = credentials.sessionToken
        }
    }
```

#### Creation
`ExposureContext` based `Player`s require an `Environment` and a `SessionToken` to operate. They are provided on *initialisation* together with an *analytics provider* to handle *EMP analytics*. An out of the box implementation of this *provider* can be found in the [`Analytics`](https://github.com/EricssonBroadcastServices/iOSClientAnalytics) module.

```Swift
import Player
import Exposure

class SimplePlayerViewController: UIViewController {
    var environment: Environment!
    var sessionToken: SessionToken!

    @IBOutlet weak var playerView: UIView!
    
    var exposureAnalytics: ExposureStreamingAnalyticsProvider!
    
    fileprivate(set) var player: Player<HLSNative<ExposureContext>>!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// This will configure the player with the `SessionToken` aquired in the specified `Environment`
        player = Player(environment: environment, sessionToken: sessionToken, analytics: exposureAnalytics)
        
        player.configure(playerView: playerView)
    }
}
```

#### Event Listeners
The preparation and loading process can be followed by listening to associated events.

```Swift
player
    .onPlaybackCreated{ tech, source in
        // Fires once the associated MediaSource has been created.
        // Playback is not ready to start at this point.
    }
    .onPlaybackPrepared{ tech, source in
        // Published when the associated MediaSource completed asynchronous loading of relevant properties.
        // Playback is not ready to start at this point.
    }
    .onPlaybackReady{ tech, source in
        // When this event fires starting playback is possible (playback can optionally be set to autoplay instead)
        tech.play()
    }
```

Once playback is in progress the `Player` continuously publishes *events* related media status and user interaction.

```Swift
player
    .onPlaybackStarted{ tech, source in
        // Published once the playback starts for the first time.
        // This is a one-time event.
    }
    .onPlaybackPaused{ [weak self] tech, source in
        // Fires when the playback pauses for some reason
        self?.pausePlayButton.toggle(paused: true)
    }
    .onPlaybackResumed{ [weak self] tech, source in
        // Fires when the playback resumes from a paused state
        self?.pausePlayButton.toggle(paused: false)
    }
    .onPlaybackAborted{ tech, source in
        // Published once the player.stop() method is called.
        // This is considered a user action
    }
    .onPlaybackCompleted{ tech, source in
        // Published when playback reached the end of the current media.
    }
```
Besides playback control events `Player` also publishes several status related events.

```Swift
player
    .onProgramChanged { [weak self] tech, source, program in
        // Update user facing program information
        self?.updateProgram(with: program)
    }
    .onBitrateChanged{ [weak self] tech, source, bitrate in
        // Published whenever the current bitrate changes
        self?.updateQualityIndicator(with: bitrate)
    }
    .onBufferingStarted{ tech, source in
        // Fires whenever the buffer is unable to keep up with playback
    }
    .onBufferingStopped{ tech, source in
        // Fires when buffering is no longer needed
    }
    .onDurationChanged{ tech, source in
        // Published when the active media received an update to its duration property
    }
```

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

Fetching channel associated *Epg* can be done by calling

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

#### Playback Management
I order to start playback of a channel from the *live edge*, client applications should use the  `ExposureContext` extension on `Player`.

```Swift
player.startPlayback(channelId: "aChannelId")
```

Specific programs may be started by supplying a *programId*. This will start the requested program from the last known bookmarked position.

```Swift
player.startPlayback(channelId: "aChannelId", programId: "aProgramId")
```

If the required behaviour is for playback is to start from the begining of the program, `useBookmark: false` shoud be set.

```Swift
player.startPlayback(channelId: "aChannelId", programId: "aProgramId", useBookmark: false)
```

Playback progress is available in two formats. Playhead position reports the position timestamp using the internal buffer time reference in milliseconds. It is also possible to seek to an offset relative to the current position

```Swift
let position = player.playheadPosition
player.seek(toPosition: position - 30 * 1000)
```

For program related playback `playheadTime` reports the offset mapped to the current wallclock time.

```Swift
let position = player.playheadTime
```

The wallclock related time interface allows for easy and intiutive program seeking. *Going live* in a catchup or timeshifted scenario is as easy as seeking to the current server time.

```Swift
if let timeRightNow = player.serverTime {
    player.seek(toTime: timeRightNow)
}
```

Additionally, restarting the currently playing program can be done by calling

```Swift
if let programStartTime = player.currentProgram?.startDate?.millisecondsSince1970 {
    player.seek(toTime: programStartTime)
}
```

All information regarding the currently playing program is encapsulated in the `Program` *struct* accessed through `player.currentProgram`. This data can be used to populate the user interface.
