# CHANGELOG

* `2.0.90` Release - [2.0.90](#2090)
* `2.0.89` Release - [2.0.89](#2089)
* `2.0.86` Release - [2.0.86](#2086)
* `2.0.85` Release - [2.0.85](#2085)
* `2.0.81` Release - [2.0.81](#2081)
* `2.0.80` Release - [2.0.80](#2080)
* `2.0.79` Release - [2.0.79](#2079)
* `2.0.78` Release - [2.0.78](#2078)
* `0.77.x` Releases - [0.77.0](#0770)

## 2.0.90

#### Features
* `EMP-11711` Playtoken passed as header when requesting fairplay licenses.

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
