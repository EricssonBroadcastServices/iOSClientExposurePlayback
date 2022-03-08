# CHANGELOG

* `2.6.40` Release - [2.6.40](#2640)
* `2.6.30` Release - [2.6.30](#2630)
* `2.6.20` Release - [2.6.20](#2620)
* `2.6.10` Release - [2.6.10](#2610)
* `2.6.00` Release - [2.6.00](#2600)
* `2.5.20` Release - [2.5.20](#2520)
* `2.5.00` Release - [2.5.00](#2500)
* `2.4.10` Release - [2.4.10](#2410)
* `2.4.00` Release - [2.4.00](#2400)
* `2.2.60` Release - [2.2.60](#2260)
* `2.2.51` Release - [2.2.51](#2251)
* `2.2.50` Release - [2.2.50](#2250)
* `2.2.40` Release - [2.2.40](#2240)
* `2.2.30` Release - [2.2.30](#2230)
* `2.2.20` Release - [2.2.20](#2220)
* `2.2.10` Release - [2.2.10](#2210)
* `2.1.130` Release - [2.1.130](#21130)
* `2.1.00` Release - [2.1.00](#2100)
* `2.0.98` Release - [2.0.98](#2098)
* `2.0.97` Release - [2.0.97](#2097)
* `2.0.96` Release - [2.0.96](#2096)
* `2.0.95` Release - [2.0.95](#2095)
* `2.0.93` Release - [2.0.93](#2093)
* `2.0.92` Release - [2.0.92](#2092)
* `2.0.91` Release - [2.0.91](#2091)
* `2.0.89` Release - [2.0.89](#2089)
* `2.0.86` Release - [2.0.86](#2086)
* `2.0.85` Release - [2.0.85](#2085)
* `2.0.81` Release - [2.0.81](#2081)
* `2.0.80` Release - [2.0.80](#2080)
* `2.0.79` Release - [2.0.79](#2079)
* `2.0.78` Release - [2.0.78](#2078)
* `0.77.x` Releases - [0.77.0](#0770)


## 2.6.40
#### Bug Fixes
* `Emp-17465` Bug fixes on SSAI 

## 2.6.30
#### Bug Fixes
* `EMP-17738` Clean `.tmp` cache files in tmp folder 

## 2.6.20
#### Features
* `EMP-17701` Allow client developers to set `preferredPeakBitRate`

## 2.6.10
#### Features
* `EMP-17693` Allow client developers to access `AVAssetVariant` s in the `currentAsset` 

## 2.6.00
#### Features
* `EMP-17612` Add support for audio only playback

## 2.5.20
#### Bug Fixes
* Bug Fix : wrong no of ad marker values &  wrong values in ad marker offset / enddOffset values

## 2.5.00
#### Features
* `EMP-17364` Align analytics with the newest specification

## 2.4.10
#### Features
* `EMP-17283` Remove `exclude arm64` as it affected sdk not supporting real devices 

## 2.4.00
#### Features
* `EMP-16373` SSAI Vod implementation in SDK

## 2.2.600
#### Features
* `EMP-15925` Analytics Enhancements 
* `EMP-15925` Now developers can disable analytics when playing content.


## 2.2.510
#### Changes
* `EMP-15910` Change minimum support version to iOS 11

## 2.2.500
#### Features
* `EMP-15794` Add support for `Adobe Primetime Media Token parameter` 

## 2.2.400
#### Features
* `EMP-15242` Add support for `sprites`  

## 2.2.300
#### Features
* `EMP-15242` Add support to pass `AdsOptions`  when starting a playback


## 2.2.200
#### Changes
* `EMP-15073` Remove example application from the project 
* `EMP-15073` Remove unused sub modules


## 2.2.100
#### Features
* `EMP-14806` Update sample application to show how to use downloads & download additional media. 

## 2.2.000
#### Features
* `EMP-14376` Add support for playing downloaded assets using  `OfflineMediaPlayable`
* `EMP-14376` Update example project to show downloading assets & playback of downloaded assets

## 2.1.130

#### Changes
* `EMP-14239` Add option to pass assetType when creating AssetPlayable
* `EMP-14239` Updated reference app to use AssetType enum.

## 2.1.00
* Released 31 January 2020

## 2.0.108

#### Features
* `EMP-12764` Expanded support for next & previous programs.
* `EMP-12717` Expanded support for the live events. 

## 2.0.98

#### Features
* `EMP-12351` Expanded support for custom environment in  *Exposure*
* `EMP-12207` Create the player view to demonstrate the SDK playback lifecycle.

## 2.0.97

#### Bug Fixes
* Log message instead of hierarchy from error if the root error is an `ExposureError` 

## 2.0.96

#### Features
* `EMP-12204` Introduced `RBMTheme` to handle common UI elements related to the reference app.
* `EMP-12206` Added `TableViewDataSource` class to handle `UITableViewDataSource`.
* `EMP-12206` Added `UITableView+EmptyMessage` to show empty message when `UITableView`  has no data .

#### Changes
* `EMP-12204` Load the project from programmatically created views instead from the storyboard. 
* `EMP-12205` Create the authentication view to allow login through username and password. 
* `EMP-12206` Create the asset list view to show the assets fetched from the Exposure API.

## 2.0.95

#### Changes
* Source preparation for ad-based playback now requires both an `adMediaLocator` and an attached `AdService` to work.

## 2.0.93

#### Features
* `EMP-11839` Introduced `AdService` to handle server side ad insertion.
* `EMP-11894` `ContractRestrictionsService` exposed as a public protocol and is now a part of source instead of context.
* `EMP-11852` Expanded `AdService` to handle contract restrictions through specific ad playback policies if required.

#### Bug Fixes
* `EMP-11909` Fixed inconsistent behaviour when seeking by position in a *unix time based stream*. Bounds checking and relevant callbacks should now use the correct offset.

#### Changes
* `EMP-11894` Contract restrictions service now part of source instead of context.

#### Known Limitations
* `EMP-11863` *Carthage*, using `xcodebuild` and `Xcode10`s new build system, fails to resolve and link the correct dependencies when `ExposurePlayback` is included as a dependency.

## 2.0.92

#### Features
* `EMP-11805` Report connection type changes by dispatching `Playback.ConnectionChanged` analytics events.

#### Changes
* Promote underlying errors in analytics.
* Expanded Fairplay error reporting.
* Upgraded unit testing frameworks.

## 2.0.91

#### Features
* Added *Exposure* `X-Request-Id` to license requests.
* `EMP-11711` Playtoken passed as header when requesting fairplay licenses.
* `EMP-11747` Added `EntitlementSourceResponseHeaders` protocol.
* `EMP-11766` Expanded and harmonized error reporting through analytics dispatch.

#### Changes
* Stop and unload `MediaAsset` when playback reaches end of duration.

#### Bug Fixes
* Fixed an issue where `Playback.Aborted` was sent after a terminating error event.

## 2.0.89

#### Features
* `EMP-11449` Improved debug potential for the *Fairplay* validation process. Added `Playback.DRM` event to trace license and cerrtificate requests.
* `EMP-11338` `ExposureAnalytics` now adopts `SourceAbandonedEventProvider`, delivering trace events on media abandonment.
* `EMP-11640` Playback is now stopped when analytics responds with `INVALID_SESSION_TOKEN`
* `EMP-11647` Added analytics event triggering when *Airplay* sessions end.
* `EMP-11667` `X-Request-Id` associated with Exposure response when requesting a `PlaybackEntitlement` dispatched in `Playback.Created`.

#### Bug Fixes
* `EMP-11567` Complete media locator included in `Playback.Started` and `Playback.HandshakeStarted` events.
* Fixed several small bugs related to error handling during *Fairplay* validation.
* `EMP-11637` Send correct _media Id_ in `Playback.HandshakeStarted`.

#### Changes
* `EMP-11646`Align buffering ended events with overall platform specs.

#### Known Limitations
* `EMP-11583` Contract restrictions are bypassed when using the *AppleTV remote* during *Airplay*.

## 2.0.86

#### Features
* `EMP-11452` Cache *Fairplay* certificates on on request url.

#### Bug Fixes
* Use correct `FairplayRequester` when streaming *vod*

## 2.0.85

#### Features
* `EMP-11335` `ExposureAnalytics` now adopts `TraceProvider` protocol.
* `EMP-11356` `ExposureAnalytics` now correctly handles analytics for playback sessions where the `Tech` was deallocated before media preparation completed.

#### Bug Fixes
* `EMP-11313` Reported tech version now correctly identifies `HLSNative` bundle if used.
* `EMP-11361` Fixed an issue where analytics events dispatched with a unix timestamp of 0 if no playback timestamp was found.

## 2.0.81

#### Features
* `EMP-11171` `ExposurePlayback` now supports *tvOS*.

#### Bug Fixes
* Errors encountered during *Fairplay Certificate* processing are now forwarded correctly, including server messages.

## 2.0.80

#### Features
* `EMP-11121` New playcalls are now made for each *Airplay* transition.
* Added analytics event to signal an *Airplay* session was initiated from local playback.

#### Changes
* `EMP-11156` Standardized error messages and introduced an `info` variable

## 2.0.79

#### Bugfixes
* Fixed a crash when attempting to retrieve bundleId.

#### Changes
* Forward `.invalidStartTime` warning when custom start time is set through `PlaybackProperties.PlayFrom`
* Heartbeats that fail to deliver will be exempt from dispatch retry

## 2.0.78

#### Features
* Track selection for `HLSNative` when using `ExposureContext`
* Preferred language selection added in `PlaybackProperties`
* Preferred bitrate limitation added in `PlaybackProperties`

#### Changes
* Standalone networking
* `HeartbeatsProvider` as a closure instead of a protocol
* `EMP-11047` Clarifies error events delivered to analytics by including error `Domain` in the dispatc

#### Bugfixes
* Heartbeats report offset based on stream type
* `EMP-11029` Forced locale to en_GB for framework dependantn date calculations
* `EMP-11035` Exposing *FairPlay* errors encountered during the validation process
* `EMP-11070` Accounted for `AVPlayer` loosing sync between `currentTime()` and `currentDate()` during rapid `seekToLive()` events

## 0.77.0

#### Features
* `EMP-10646` `ExposureContext` exposes cached server walltime.
* `EMP-10852` `playheadTime` of streams associated with a *unix epoch timestamp* are synched with server walltime.
* `EMP-10861` Internal management of *timeshift delay* implemented for `ExposureContext`.
* Introduced `PlaybackProperties` to manage additional configuration of playback.
* Added `onEntitlementResponse` callback
* *fastForward*, *rewind* and *timeshift* contract restrictions enforced.
* Context aware `seekTo` api enabling automatic entitlement renewal and enforcement.
* Added `onWarning` callback which broadcasts *warnings* to interested parties.

#### Changes
* `EMP-10852` API changes to `ExposureContext` playback extensions starting playback by *EMP* assetId has been renamed.
* `SessionShift` protocol has been reamed to `StartTime` 
