[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

# Exposure

* [Features](#features)
* [License](https://github.com/EricssonBroadcastServices/iOSClientExposurePlayback/blob/master/LICENSE)
* [Requirements](#requirements)
* [Installation](#installation)
* Usage
    - [Getting Started](#getting-started)
    - [Playback through `Player` using `ExposureContext`](#playback-through-player-using-exposurecontext)
    - [Program Service](#program-service)
    - [Fairplay Integration](#fairplay-integration)
    - [Error Handling](#error-handling)
* [Release Notes](#release-notes)
* [Upgrade Guides](#upgrade-guides)
* [Roadmap](#roadmap)
* [Contributing](#contributing)

## Features

- [x] Playback through *Exposure*
- [x] Program Service
- [x] Program based seeking
- [x] Contract Restrictions

## Requirements

* `iOS` 9.0+
* `Swift` 4.0+
* `Xcode` 9.0+

* Framework dependencies
    - [`Player`](https://github.com/EricssonBroadcastServices/iOSClientPlayer)
    - [`Exposure`](https://github.com/EricssonBroadcastServices/iOSClientExposure)
    - Exact versions described in [Cartfile](https://github.com/EricssonBroadcastServices/iOSClientExposurePlayback/blob/master/Cartfile)

## Installation

### Carthage
[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependency graph without interfering with your `Xcode` project setup. `CI` integration through [fastlane](https://github.com/fastlane/fastlane) is also available.

Install *Carthage* through [Homebrew](https://brew.sh) by performing the following commands:

```sh
$ brew update
$ brew install carthage
```

Once *Carthage* has been installed, you need to create a `Cartfile` which specifies your dependencies. Please consult the [artifacts](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md) documentation for in-depth information about `Cartfile`s and the other artifacts created by *Carthage*.

```sh
github "EricssonBroadcastServices/iOSClientExposurePlayback"
```

Running `carthage update` will fetch your dependencies and place them in `/Carthage/Checkouts`. You either build the `.framework`s and drag them in your `Xcode` or attach the fetched projects to your `Xcode workspace`.

Finally, make sure you add the `.framework`s to your targets *General -> Embedded Binaries* section.

## Usage
`Exposure` conveys seamless integration with the *EMP Exposure Layer* and enables client applications quick access to functionality such as *authentication*, *entitlement requests* and *EPG*.

### Getting Started

### Playback through `Player` using `ExposureContext`
`Exposure` module is designed to integrate seamlessly with `Player` enabling a smooth transition between the request phase and the playback phase. Context sensitive playback allows for constrained extensions on the `PlaybackTech` and `MediaContext`, encapsulating all logic for an entitlement request.

*Client Applications* can make use of `ExposureContext` which provides out of the box integration with the *EMP* backend, allowing playback from asset identifiers.

```Swift
player.startPlayback(channelId: "someEMPLiveChannel")
```

Using the `Player.startPlayback(channelId:)` method ensures playback will be configured with `Exposure` related functionality. This includes *Fairplay* configuration and *Session Shift* management.

### Program Service
*EPG*, or the *electronic programming guide*, details previous, current and upcomming programs on a specific channel. Client applications may request *EPG* data through the `FetchEpg` endpoint.

`Exposure` supports fetching *EPG* for a set of channels, either all channels or filtered on `channelId`s.


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

### Fairplay Integration
`Exposure` provides out of the box integration for managing *EMP* configured *Fairplay* `DRM` protection. By using the `Player.startPlayback(...)` function to engage playback the framework automatically configures `player` to use an `ExposureStreamFairplayRequester` as its `FairplayRequester`.

### Error Handling

#### Fairplay DRM Errors
Another major cause of errors is *Fairplay* `DRM` issues, broadly categorized into two types:

* Server related `DRM` errors
* Application related

Server related issues most likely stem from an invalid or broken backend configuration. Application issues range from parsing errors, unexpected server response or networking issues.

*Fairplay* `DRM` troubleshooting is highly coupled with the specific application and backend implementations and as such hard to generalize. For more information about *Fairplay* debugging, please see Apple's [documentation](https://developer.apple.com/library/content/technotes/tn2454).

## Release Notes
Release specific changes can be found in the [CHANGELOG](https://github.com/EricssonBroadcastServices/iOSClientExposurePlayback/blob/master/CHANGELOG.md).

## Upgrade Guides
The procedure to apply when upgrading from one version to another depends on what solution your client application has chosen to integrate `Exposure`.

Major changes between releases will be documented with special [Upgrade Guides](https://github.com/EricssonBroadcastServices/iOSClientExposurePlayback/blob/master/UPGRADE_GUIDE.md).

### Carthage
Updating your dependencies is done by running  `carthage update` with the relevant *options*, such as `--use-submodules`, depending on your project setup. For more information regarding dependency management with `Carthage` please consult their [documentation](https://github.com/Carthage/Carthage/blob/master/README.md) or run `carthage help`.

## Roadmap
No formalised roadmap has yet been established but an extensive backlog of possible items exist. The following represent an unordered *wish list* and is subject to change.


## Contributing
