[![Swift](https://img.shields.io/badge/Swift-5.x-orange?style=flat-square)](https://img.shields.io/badge/Swift-5.3_5.4_5.5-Orange?style=flat-square)
[![Platforms](https://img.shields.io/badge/Platforms-iOS_tvOS-yellowgreen?style=flat-square)](https://img.shields.io/badge/Platforms-macOS_iOS_tvOS_watchOS_Linux_Windows-Green?style=flat-square)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Alamofire.svg?style=flat-square)](https://img.shields.io/cocoapods/v/Alamofire.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat-square)](https://github.com/Carthage/Carthage)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)

# Exposure Playback

* [Features](#features)
* [License](https://github.com/EricssonBroadcastServices/iOSClientExposurePlayback/blob/master/LICENSE)
* [Requirements](#requirements)
* [Installation](#installation)
* Documentation
    - [Simple Player](https://github.com/EricssonBroadcastServices/iOSClientExposurePlayback/blob/master/Documentation/simple-player.md)
    - [Live and Catchup](https://github.com/EricssonBroadcastServices/iOSClientExposurePlayback/blob/master/Documentation/live-and-catchup-playback.md)
    - [Error Handling and Warning Messages](https://github.com/EricssonBroadcastServices/iOSClientExposurePlayback/blob/master/Documentation/error-handling-and-warning-messages.md)
    - [Migrating from MRR](https://github.com/EricssonBroadcastServices/iOSClientExposurePlayback/blob/master/Documentation/migrating-from-mrr.md)
    - [Playback of Downloaded Assets](https://github.com/EricssonBroadcastServices/iOSClientExposurePlayback/blob/master/Documentation/download.md)
* [Release Notes](#release-notes)
* [Upgrade Guides](#upgrade-guides)
* [Known Limitations](https://github.com/EricssonBroadcastServices/iOSClientExposurePlayback/blob/master/KNOWN_LIMITATIONS.md)

## Features

- [x] Catchup as Live
- [x] Playback through *ExposureContext*
- [x] Program Based Stream Navigation
- [x] Program Service
- [x] Advanced Contract Restrictions
- [x] Analytics Provider

## Requirements

* `iOS` 9.0+
* `tvOS` 9.0+
* `Swift` 4.0+
* `Xcode` 9.0+

* Framework dependencies
    - [`iOSClientPlayer`](https://github.com/EricssonBroadcastServices/iOSClientPlayer)
    - [`iOSClientExposure`](https://github.com/EricssonBroadcastServices/iOSClientExposure)
    - Exact versions described in [Cartfile](https://github.com/EricssonBroadcastServices/iOSClientExposurePlayback/blob/master/Cartfile)

## Installation

The Swift Package Manager is a tool for automating the distribution of Swift code and is integrated into the swift compiler.
Once you have your Swift package set up, adding `iOSClientExposurePlayback` as a dependency is as easy as adding it to the dependencies value of your Package.swift.

```sh
dependencies: [
    .package(url: "https://github.com/EricssonBroadcastServices/iOSClientExposurePlayback", from: "3.2.0")
]
```

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

### CocoaPods
CocoaPods is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate `iOSClientExposurePlayback` into your Xcode project using CocoaPods, specify it in your Podfile:

```sh
pod 'iOSClientExposurePlayback', '~>  3.2.0'
```

## Release Notes
Release specific changes can be found in the [CHANGELOG](https://github.com/EricssonBroadcastServices/iOSClientExposurePlayback/blob/master/CHANGELOG.md).

## Upgrade Guides
The procedure to apply when upgrading from one version to another depends on what solution your client application has chosen to integrate `ExposurePlayback`.

Major changes between releases will be documented with special [Upgrade Guides](https://github.com/EricssonBroadcastServices/iOSClientExposurePlayback/blob/master/UPGRADE_GUIDE.md).

### Carthage
Updating your dependencies is done by running  `carthage update` with the relevant *options*, such as `--use-submodules`, depending on your project setup. For more information regarding dependency management with `Carthage` please consult their [documentation](https://github.com/Carthage/Carthage/blob/master/README.md) or run `carthage help`.

