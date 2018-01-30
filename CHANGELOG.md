# CHANGELOG

* `0.76.x` Releases - [0.76.0](#0760)

## 0.76.0

#### Features
* `EMP-10646` `ExposureContext` exposes cached server walltime.
* `EMP-10852` `playheadTime` of streams associated with a *unix epoch timestamp* are synched with server walltime.
* `EMP-10861` Internal management of *timeshift delay* implemented for `ExposureContext`.
* Introduced `PlaybackProperties` to manage additional configuration of playback.
* Added `onEntitlementResponse` callback
* *fastForward*, *rewind* and *timeshift* contract restrictions enforced.

#### Changes
* `EMP-10852` API changes to `ExposureContext` playback extensions starting playback by *EMP* assetId has been renamed.
* `SessionShift` protocol has been reamed to `StartTime` 
