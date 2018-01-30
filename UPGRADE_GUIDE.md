# Upgrade Guide

## Adopting 0.76.0

#### Architecture
`Exposure` module has been refactored with the playback and download related functionality extracted into new modules. 

#### API changes
Several API changes where introduced to streamline with *Android* and *HTML5* platforms.

##### `ExposureContext`
Playback related functionality associated with `ExposureContext` received a renovation which improved *shared api consistency* between *iOS*, *Android* and the *HTML5* platforms.

* `stream(vod assetId: String)`: renamed to `startPlayback(assetId: String, properties: PlaybackProperties = PlaybackProperties())`
* `stream(live channelId: String)` and `stream(programId: String, channelId: String)`: renamed to `startPlayback(channelId: String, properties: PlaybackProperties = PlaybackProperties())` and `startPlayback(channelId: String, programId: String, properties: PlaybackProperties = PlaybackProperties())` respectivley.

Additionaly, managing *Exposure* bookmarking functionality can now optionally be specified in the playback call.
