# Known Limitations

### `EMP-11583`
Contract restrictions are bypassed when using the *AppleTV remote* during *Airplay*.

Event callbacks and notifications related to *AppleTV remote* commands are not posted and communication occurs exclusively through private *api*s.

* `Reported`: 2.0.86
* `Radar`: http://openradar.appspot.com/radar?id=5327082565402624


### `EMP-11863`
*Carthage*, using `xcodebuild` and `Xcode10`s new build system, fails to resolve and link the correct dependencies when `ExposurePlayback` is included as a dependency.


* `Reported`: 2.0.92
* `Workaround`: Use the old (legacy) build system. See `File -> Workspace Settings... -> Build Settings` in Xcode.
