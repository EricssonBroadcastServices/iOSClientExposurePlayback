# Upgrade Guide

## Adopting 2.0.78

#### Supported Features

* Live playback starts from the "live edge" as default behaviour. There is an option to start the live playback from the beginning of the current live program or the bookmarked position.
* Catchup playback starts from the beginning of the program as default behaviour. There is an option to start the catchup playback from the bookmarked position.
* If timeshift is enabled the playback can be paused/resumed at any time.
* If timeshift and rewind are enabled it is possible to jump back to the beginning of the current program.
* If timeshift and rewind are enabled it is possible to jump back 30s, potentially into the previous program.
* If timeshift and rewind are enabled it is possible to scrub or seek using the progress bar to any point between the current playhead position and the beginning of the program.
* It is always possible to jump to the live point.
* If timeshift and fast-forward are enabled it is possible to jump forward 30s, potentially into the next program.
* If timeshift and fast-forward are enabled it is possible to scrub or seek using the progress bar to any point between the playhead position and the live edge or the end of the current catchup program.
* When playing a catchup program, the playback continues seamlessly between programs (no reload / license request needed).
* Playback stops if the user is not entitled to the upcoming program.
* If a user seeks to a program that is not available due to a gap in the EPG, a warning message is thrown and the playback continues from the sought position.
* It is possible to switch subtitles on/off if there is an available subtitle track on the channel.
* It is possible to select a subtitle language if there are several available subtitle tracks on the channel.
* It is possible to select a default/preferred subtitle language, used if available. If the default subtitle language is not available, the playback starts without subtitles.
* It is possible to choose an audio track if there are several available audio tracks on the channel.
* It is possible to select a default/preferred audio track.
* It is possible to retrieve the restrictions that apply to the current program (disabled controls, contract restrictions, ...).
* It is possible to limit the streaming quality (maxBitrate as a playback property)

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
