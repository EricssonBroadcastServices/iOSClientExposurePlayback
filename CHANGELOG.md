# CHANGELOG

* `2.0.79` Release - [2.0.79](#2079)
* `2.0.78` Release - [2.0.78](#2078)
* `0.77.x` Releases - [0.77.0](#0770)

## 2.0.79

#### Bugfixes
* Fixed a crash when attempting to retrieve bundleId.


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
