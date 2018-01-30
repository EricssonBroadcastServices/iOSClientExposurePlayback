[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

# Exposure

* [Features](#features)
* [License](https://github.com/EricssonBroadcastServices/iOSClientExposure/blob/master/LICENSE)
* [Requirements](#requirements)
* [Installation](#installation)
* Usage
    - [Getting Started](#getting-started)
    - [Authentication: Best practices](#authentication-best-practices)
    - [Entitlement Requests and Streaming through  `Player`](#entitlement-requests-and-streaming-through-player)
    - [Fetching EPG](#fetching-epg)
    - [Fetching Assets](#fetching-assets)
    - [Content Search](#content-search)
    - [Analytics Delivery](#analytics-delivery)
    - [Fairplay Integration](#fairplay-integration)
    - [Error Handling](#error-handling)
* [Release Notes](#release-notes)
* [Upgrade Guides](#upgrade-guides)
* [Roadmap](#roadmap)
* [Contributing](#contributing)

## Features
- [x] Asset search
- [x] Authentication
- [x] Playback Entitlement requests
- [x] Download Entitlement requests
- [x] EPG discovery
- [x] Analytics drop-off
- [x] Server time sync
- [x] Carousel integration
- [x] Dynamic customer configuration
- [x] Content search with autocompletion

## Requirements

* `iOS` 9.0+
* `Swift` 4.0+
* `Xcode` 9.0+

* Framework dependencies
    - [`Player`](https://github.com/EricssonBroadcastServices/iOSClientPlayer)
    - [`Download`](https://github.com/EricssonBroadcastServices/iOSClientDownload)
    - [`Alamofire`](https://github.com/Alamofire/Alamofire)
    - Exact versions described in [Cartfile](https://github.com/EricssonBroadcastServices/iOSClientExposure/blob/master/Cartfile)

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
github "EricssonBroadcastServices/iOSClientExposure"
```

Running `carthage update` will fetch your dependencies and place them in `/Carthage/Checkouts`. You either build the `.framework`s and drag them in your `Xcode` or attach the fetched projects to your `Xcode workspace`.

Finally, make sure you add the `.framework`s to your targets *General -> Embedded Binaries* section.

## Usage
`Exposure` conveys seamless integration with the *EMP Exposure Layer* and enables client applications quick access to functionality such as *authentication*, *entitlement requests* and *EPG*.

### Getting Started
*EMP Exposure Layer* has three central concepts of special importance.

* `Environment` Describes the customer specific *Exposure* environment
* `SessionToken` Represents an authenticated user session
* *Asset Id* A unique identifier for a media asset in the system.

The basic building block of any interaction with the *EMP Exposure layer* is `Environment`. This `struct` details the customer specific information required to make requests.

Besides an `Environment`, a valid `SessionToken` is required for accessing most of the functionality. This token is returned upon succesful authentication through the `Authenticate` endpoint. Several methods exist for dealing with user authentication, listed below.

```Swift
Authenticate(environment: exposureEnv)
    .login(username: someUser,
           password: somePassword)
           
Authenticate(environment: exposureEnv)
    .anonymous()
```

Finally, *Asset Id* refers to unique media assets and may represent items such as *tv shows*, *movies*, *tv channels* or *clips*. Client applications should use this id when refering to media in the *EMP system*.

### Authentication: Best Practices
Retrieving, persisting, validating and destroying user `SessionToken`s lays a the heart of the *EMP Exposure layer*.

Authentication requests return a valid `SessionToken` (or an encapsulating `Credentials`) if the request is successful. This `sessionToken` should be persisted and used in subsequent calls when an authenticated user is required.

```Swift
Authenticate(environment: exposureEnv)
    .login(username: someUser,
           password: somePassword)
    .request()
    .response{
        if let error = $0.error {
           // Handle Error
        }
           
        if let credentials = $0.value {
           let sessionToken: SessionToken = credentials.sessionToken
           
           // Store/pass along the returned SessionToken
        }
    }
```

A `sessionToken` by itself is not guaranteed to be valid. `Exposure` supports validation of existing `sessionToken`s by calling `Authenticate.validate(sessionToken:)` and will return `401` `INVALID_SESSION_TOKEN` if the supplied token is no longer valid.

```Swift
Authenticate(environment: exposureEnv)
    .validate(sessionToken: someToken)
    .request()
    .response{
        if let case .exposureResponse(reason: reason) = $0.error, (reason.httpCode == 401 && reason.message == "INVALID_SESSION_TOKEN") {
            // Session is no longer valid.
        }
        
        if let stillValid = $0.value {
            // Optionally handle the data returned by Exposure in the form of a SessionResponse
        }
    }
```

Destroying an authenticated user session is accomplished by calling `Authenticate.logout(sessionToken:)`

### Entitlement Requests and Streaming through Player
Requesting entitlements is part of the core functionality delivered by the `Exposure` module. A `PlaybackEntitlement` contains all information required to create and start a playback session.

Requests are made on *assetId* and return results based on the user associated with the supplied `SessionToken`. Three endpoints exist depending on the type of entitlement that is requested.

```Swift
let request = Entitlement(environment: environment, sessionToken: sessionToken)

let vodRequest = request.vod(assetId: someAsset)
let liveRequest = request.live(channelId: someChannel)
let catchupRequest = request.program(programId: someProgram, channelId: someChannel)
let downloadRequest = request.download(assetId: someOfflineAsset)
```

Optionally, client applications can request a `DRM` other than the default  `.fairplay`. Please note that the `iOS` platform might not support the requested `DRM`. As for *Fairplay* `DRM`, `Exposure` supplies an out of the box implementation of `FairplayRequester` to handle rights management on the *EMP* platform. For more information, please see [Fairplay Integration](#fairplay-integration).

```Swift
Entitlement(environment: environment,
           sessionToken: sessionToken)
    .program(programId: someProgram,
             channelId: someChannel)
    .use(drm: .unencrypted)
    .request()
    .response{
        if let error = $0.error {
            // Handle error
        }
        
        if let entitlement = $0.value {
            // Forward entitlement to playback view
        }
    }
```

A failed entitlement request where the user is not entitled to play an asset will manifest as an `ExposureResponse` encapsulated in an `ExposureError`. For more information, please see [Error Handling](#error-handling).

#### Playback through `Player` using `ExposureContext`
`Exposure` module is designed to integrate seamlessly with `Player` enabling a smooth transition between the request phase and the playback phase. Context sensitive playback allows for constrained extensions on the `PlaybackTech` and `MediaContext`, encapsulating all logic for an entitlement request.

*Client Applications* can make use of `ExposureContext` which provides out of the box integration with the *EMP* backend, allowing playback from asset identifiers.

```Swift
player.startPlayback(channelId: "someEMPLiveChannel")
```

Using the `Player.startPlayback(channelId:)` method ensures playback will be configured with `Exposure` related functionality. This includes *Fairplay* configuration and *Session Shift* management.

### Fetching EPG
*EPG*, or the *electronic programming guide*, details previous, current and upcomming programs on a specific channel. Client applications may request *EPG* data through the `FetchEpg` endpoint.

`Exposure` supports fetching *EPG* for a set of channels, either all channels or filtered on `channelId`s.

The example below fetches *EPG* for 3 specified channels from yesterday to tomorrow, limiting the result to 100 entries and sorting the returned `[ChannelEpg]` on *channelId* in a *descending order*.

```Swift
FetchEpg(environment: environment)
    .channels(ids: ["channel_1_news", "some_sports", "great_series")
    .filter(starting: yesterdaysDate, ending: tomorrowsDate)
    .sort(on: ["-channelId"])
    .show(page: 1, spanning: 100)
    .request()
    .response{
        // Handle response
    }
```

It is also possible to fetch *EPG* data for a specific program on a channel.

```Swift
FetchEpg(environment: environment)
    .channel(id: "great_series", programId: "amazing_show_s01_e01")
    .request()
    .response{
        // Handle response
    }
```

Client applications relying obn `ExposureContext` may also fetch the currently playing `Program` directly from the `player` object.

```Swift
let nowPlaying = player.currentProgram
```

Or listen to the `onProgramChanged` event.

```Swift
player.onProgramChanged { tech, source, program in
    // Update userfacing program information
}


### Fetching Assets
Client applications can fetch and filter assets on a variety of properties.

It is possible to specify what data fields should be included in the response. The following request fetches `.all` fields in the `FieldSet`, excluding `publications.rights` and `tags`.

```Swift
let sortedListRequest = FetchAsset(environment: environment)
    .list()
    .use(fieldSet: .all)
    .exclude(fields: ["publications.rights", "tags"])
```

Just as with *EPG*, it is possible to sort the response and limit it to a set number of entries

```Swift
let pagedSortedRequest = sortedListRequest
    .sort(on: ["-publications.publicationDate","assetId"])
    .show(page: 1, spanning: 100)
```

In addition, it is possible to filter on `DeviceType` and *assetIds*

```Swift
let deviceFilteredRequest = pagedSortedRequest
    .filter(onlyAssetIds: ["amazing_show_s01_e01", "channel_1_news"]
    .filter(on: .tablet)
```

Finally, advanced queries can be performed using *elastic search* on related properties. For example, a filter for finding only assets with *HLS* and *Fairplay* media can be expressed as follows

```Swift
let elasticSearchRequest = deviceFilteredRequest
    .elasticSearch(query: "medias.drm:FAIRPLAY AND medias.format:HLS")
    .request()
    .response{
        // Handle response
    }
```
For more information on how to construct queries, please see [Elastic Search](https://www.elastic.co/guide/en/elasticsearch/reference/1.7/query-dsl-query-string-query.html) documentation.

It is also possible to fetch an asset by Id

```Swift
FetchAsset(environment: environment)
    .filter(assetId: "amazing_show_s01_e01")
    .request()
    .response{
        // Handle response
    }
```

### Content Search
Client applications can do content search with autocompletion by querying *Exposure*.

```Swift
Search(environment: environment)
    .autocomplete(for: "The Amazing TV sh")
    .filter(locale: "en")
    .request()
    .response{
        // Matches "The Amazing TV show"
    }
```

When doing querys on assets, many of the `FetchAssetList` filters are applicable.

```Swift
Search(environment: environment)
    .query(for: "The Amazing TV sh")
    .filter(locale: "en")
    .use(fieldSet: .all)
    .exclude(fields: ["publications.rights", "tags"])
    .sort(on: ["-publications.publicationDate","assetId"])
    .show(page: 1, spanning: 100)
    .request()
    .response{
        // Handle the response
    }
```


### Analytics Delivery
`EventSink` analytics endpoints expose drop-of functionality where client applications can deliver *Analytics Payload*. This payload consists of a `json` object wrapped by an `AnalyticsBatch` envelope. Each batch is self-contained and encapsulates all information required for dispatch.

Initializing analytics returns a response with the configuration parameters detailing how the server wishes contact to proceed.

```Swift
EventSink()
    .initialize(using: myEnvironment)
    .request()
    .response{
        // Handle response
    }
```

`AnalyticsPayload` drop-of is handled in a *per-batch* basis. The response contains an updated analytics configuration.

```Swift
EventSink()
    .send(analytics: batch, clockOffset: unixEpochOffset)
    .request()
    .response{
        // Handle response
    }
```

*EMP* provides an out of the box [Analytics module](https://github.com/FredrikSjoberg/iOSClientAnalytics) which integrates seamlessly with the rest of the platform.

### Fairplay Integration
`Exposure` provides out of the box integration for managing *EMP* configured *Fairplay* `DRM` protection. By using the `Player.stream(playback:)` function to engage playback the framework automatically configures `player` to use an `ExposureStreamFairplayRequester` as its `FairplayRequester`.

### Error Handling
Effective error handling when using `Exposure` revolves around responding to three major categories of errors.

The first category consists of errors related to the underlying *frameworks*, forwarded as `ExposureError.generalError(error:)`. Examples include networking errors and on occation purely general errors. Please consult *framework* related documentation to manage these.

A second category contains `serialization(reason:)` errors. These occur on response serialization and indicate a missmatch between the expected data format and the server provided response.

```Swift
someFunc(callback: (ExposureError?) -> Void) { error in
    if case let .serialization(reason: .jsonSerialization(error: jsonError)) = error {
        // The underlying error occured due to json serialization issues
    }
}
```

`jsonSerialization(error:)` related errors mean the provided response data failed to generate a valid `json` structure. This normally indicates data transfer corruption or an invalid or malformated server response.

`objectSerialization(reason: json:)` indicate a missmatch between the provided `json` object and the specifications from which `Object` is initialized. Possible causes can be changes in server response. As such, client applications are encouraged to make sure they run on the latest version of the `Exposure` framework.

#### Exposure Response Validation
`Exposure` endpoints will return specialized response messages, `ExposureResponseMessage`s, that convey server intentions through an `httpCode`. As such, it is important to *validate* responses generated from an `ExposureRequest`. For example, `Entitlement` requests will return `403` `NOT_ENTITLED` when asking for a `PlaybackEntitlement` the user is not entitled to play.

```Swift
Entitlement(environment: environment,
sessionToken: sessionToken)
    .vod(assetId: someAsset)
    .use(drm: .unencrypted)
    .request()
    .validate(statusCode: 200..<299)
    .response{ [weak self] in
        if case let .exposureResponse(reason: reason) = $0.error, (reason.httpCode == 401) {
            // Handle error
            self?.notifyUser(errorCode: reason.httpCode, withReason: reason.message)
        }
        ...
    }
```

Errors delivered as an `ExposureResponseMessage` should, for the most part, not be considered *fatal*. They convey server intent. Some may however block client applications from proceeding with the intended *navigation flow*. For example, `ExposureResponseMessage` received when using `Authenticate` results in the user failing to log in. This in turn will block entitlement requests and thus make playback initialization impossible.

It is up to the client application to decide how to best handle `ExposureResponseMessage`s. Each endpoint may return a slightly different set of response messages. For more in depth information, please consult the documentation related to each individual request.

#### Fairplay DRM Errors
Another major cause of errors is *Fairplay* `DRM` issues, broadly categorized into two types:

* Server related `DRM` errors
* Application related

Server related issues most likely stem from an invalid or broken backend configuration. Application issues range from parsing errors, unexpected server response or networking issues.

*Fairplay* `DRM` troubleshooting is highly coupled with the specific application and backend implementations and as such hard to generalize. For more information about *Fairplay* debugging, please see Apple's [documentation](https://developer.apple.com/library/content/technotes/tn2454).

## Release Notes
Release specific changes can be found in the [CHANGELOG](https://github.com/EricssonBroadcastServices/iOSClientExposure/blob/master/CHANGELOG.md).

## Upgrade Guides
The procedure to apply when upgrading from one version to another depends on what solution your client application has chosen to integrate `Exposure`.

Major changes between releases will be documented with special [Upgrade Guides](https://github.com/EricssonBroadcastServices/iOSClientExposure/blob/master/UPGRADE_GUIDE.md).

### Carthage
Updating your dependencies is done by running  `carthage update` with the relevant *options*, such as `--use-submodules`, depending on your project setup. For more information regarding dependency management with `Carthage` please consult their [documentation](https://github.com/Carthage/Carthage/blob/master/README.md) or run `carthage help`.

## Roadmap
No formalised roadmap has yet been established but an extensive backlog of possible items exist. The following represent an unordered *wish list* and is subject to change.

- [x] Carousel integration
- [x] Content search
- [ ] User playback history
- [ ] User preferences
- [ ] Device management
- [x] Swift 4: Replace SwiftyJSON with native Codable 

## Contributing
