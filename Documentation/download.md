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

```Swift
    let downloadedAsset = enigmaDownloadManager.getDownloadedAsset(assetId: assetId)
    
    if let entitlement = downloadedAsset?.entitlement, let urlAsset = downloadedAsset?.urlAsset {
    
        let offlineMediaPlayable = OfflineMediaPlayable(assetId: assetId, entitlement: entitlement, url: urlAsset.url)
        
        // Play downloaded asset
        player.startPlayback(offlineMediaPlayable: offlineMediaPlayable)
        
    }
````
