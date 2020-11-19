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
`ExposureContext` based `Player`s require an `Environment` and a `SessionToken` to operate which are provided at *initialisation* through a *convenience initialiser*.

```Swift
public convenience init(environment: Environment, sessionToken: SessionToken)
```

This will configure the `Player` for playback using *EMP* functionality.

```Swift
import Player
import Exposure

class SimplePlayerViewController: UIViewController {
    var environment: Environment!
    var sessionToken: SessionToken!

    @IBOutlet weak var playerView: UIView!
    
    fileprivate(set) var player: Player<HLSNative<ExposureContext>>!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// This will configure the player with the `SessionToken` aquired in the specified `Environment`
        player = Player(environment: environment, sessionToken: sessionToken)
        
        player.configure(playerView: playerView)
    }
}
```

#### Event Listeners
The preparation and loading process can be followed by listening to associated events.

```Swift
player
    .onPlaybackCreated{ player, source in
        // Fires once the associated MediaSource has been created.
        // Playback is not ready to start at this point.
    }
    .onPlaybackPrepared{ player, source in
        // Published when the associated MediaSource completed asynchronous loading of relevant properties.
        // Playback is not ready to start at this point.
    }
    .onPlaybackReady{ player, source in
        // When this event fires starting playback is possible (playback can optionally be set to autoplay instead)
        player.play()
    }
```

Once playback is in progress the `Player` continuously publishes *events* related media status and user interaction.

```Swift
player
    .onPlaybackStarted{ player, source in
        // Published once the playback starts for the first time.
        // This is a one-time event.
    }
    .onPlaybackPaused{ [weak self] player, source in
        // Fires when the playback pauses for some reason
        self?.pausePlayButton.toggle(paused: true)
    }
    .onPlaybackResumed{ [weak self] player, source in
        // Fires when the playback resumes from a paused state
        self?.pausePlayButton.toggle(paused: false)
    }
    .onPlaybackAborted{ player, source in
        // Published once the player.stop() method is called.
        // This is considered a user action
    }
    .onPlaybackCompleted{ player, source in
        // Published when playback reached the end of the current media.
    }
```
Besides playback control events `Player` also publishes several status related events.

```Swift
player
    .onProgramChanged { [weak self] player, source, program in
        // Update user facing program information
        self?.updateProgram(with: program)
    }
    .onEntitlementResponse { player, source, entitlement in
        // Fires when a new entitlement is received, such as after attempting to start playback
    }
    .onBitrateChanged{ [weak self] player, source, bitrate in
        // Published whenever the current bitrate changes
        self?.updateQualityIndicator(with: bitrate)
    }
    .onBufferingStarted{ player, source in
        // Fires whenever the buffer is unable to keep up with playback
    }
    .onBufferingStopped{ player, source in
        // Fires when buffering is no longer needed
    }
    .onDurationChanged{ player, source in
        // Published when the active media received an update to its duration property
    }
```



#### Starting Playback
Client applications start playback by supplying `Player` with a `Playable`.

**With the SDK `2.xxx` up versions we have deprecated the `ChannelPlayable` & `ProgramPlayable` . Instead now you can simply 
create an `AssetPlayable` to play a live channel , programme or vod assets.**


```Swift
let assetPlayable = AssetPlayable(assetId: "assetId")
player.startPlayback(playable: assetPlayable)
```

Optionally, client applications can set specific playback options by specifying them in `PlaybackProperties`. These options include maximum bitrate, autoplay mode, custom start time and language preferences.

```Swift
let properties = PlaybackProperties(autoPlay: true,
                                    playFrom: .bookmark,
                                    language: .custom(text: "fr", audio: "en"),
                                    maxBitrate: 300000)

player.startPlayback(playable: assetPlayable, properties: properties)
```


#### Playback Progress
Playback progress is available in two formats. Playhead position reports the position timestamp using the internal buffer time reference in milliseconds. It is also possible to seek to an offset relative to the current position

```Swift
let position = player.playheadPosition
player.seek(toPosition: position - 30 * 1000)
```

For date-time related streams, `playheadTime` reports the offset mapped to the current wallclock time. This feature is used for live and catchup.

```Swift
let position = player.playheadTime
```

It is possible to seek to a specific timestamp by supplying a unix timestamp in milliseconds.

```Swift
let thirtyMinutes = 30 * 60 * 1000
let thirtyMinutesAgo = Date().millisecondsSince1970 - thirtyMinutes
player.seek(toTime: thirtyMinutesAgo)
```

#### Server-Side Ad Insertion (SSAI)

if you are planning to use server side ads insertion with the player you can set `AdsOptions` to pass client / device specific information that can be used for ad targeting when starting the playback.


```Swift
let adsOptions = AdsOptions(latitude: 18.000, longitude: 18.000, mute: true, consent: "consent", deviceMake: "deviceMake", ifa: "ifa", gdprOptin: true)
player.startPlayback(playable: assetPlayable, properties: properties, adsOptions: adsOptions)
```




