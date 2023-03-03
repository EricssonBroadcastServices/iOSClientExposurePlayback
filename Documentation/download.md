## Usage

Client applications can use the `ExpoureDownload` by  confirming `EnigmaDownloadManager` to any class.

```Swift
class MyTestViewController: UIViewController, EnigmaDownloadManager {
    // After confirming client applications can use `enigmaDownloadManager` instance to perform any download related tasks.
}
```

## Playback of a downloaded Asset

Check - [`ExposureDownload`](https://github.com/EricssonBroadcastServices/iOSClientExposureDownload) for more information regarding downloads.

Client applications can get an `offlineMediaAsset` ( downloaded asset ) by using the `EnigmaDownloadManager`. 

```Swift
    let downloadedAsset = enigmaDownloadManager.getDownloadedAsset(assetId: assetId)
```

Or client applications can get `AllDownloadedAssets` by using `getDownloadedAssets()`

```Swift
    let allDownloadedAssets = enigmaDownloadManager.getDownloadedAssets()
```


Then developers can create a  `OfflineMediaPlayable` & pass it to the player to play any downloaded asset.

But there is an exception when playing downloaded mp3. AVPlayer sometimes doesn't play offline mp3 files, so the client application developers are encourage to use `AVAudioPlayer` or `AVAudioEngine` to play offline mp3 files. 

check SDK Sample application for an example implementation. ( https://github.com/EricssonBroadcastServices/iOSClientSDKSampleApp )

`OfflineMediaPlayable` has the attribute `format` which will pass the format of the downloaded file's format. 

```Swift
    let downloadedAsset = enigmaDownloadManager.getDownloadedAsset(assetId: assetId)
    
    if let entitlement = downloadedAsset?.entitlement, let urlAsset = downloadedAsset?.urlAsset, let format = downloadedAsset?.format {
    
        if format == "MP3" || format == "mp3" {
            // Create `AVAudioPlayer` or `AVAudioFile` and pass to `AVAudioEngine`
        } else {
    
             let offlineMediaPlayable = OfflineMediaPlayable(assetId: assetId, entitlement: entitlement, url: urlAsset.url)
        
               // Play downloaded asset
            player.startPlayback(offlineMediaPlayable: offlineMediaPlayable)
        }    
    }
````
