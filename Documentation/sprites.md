## Usage

Client applications can use the sprites , preview thumbnails for VOD assets & for Catchups if it is provided by the backend. If there are any sprites streams available for the given asset, client application can find that in the `source` object return from the player events.  

```Swift
player
    .onEntitlementResponse { player, source, entitlement in
        // Fires when a new entitlement is received, such as after attempting to start playback
        // source.sprites contains array of Sprites with each sprite has it's own vtt url & width
        print(source.sprites)
    }
```

Developers can use their own implementation to handle the vtt streams & get the sprite images. But `ExposurePlayback` module provides out of the box solution that developers can use to add sprite to their players. 

## Activate Sprites

First you need to `activate` the sprites to use in the player. Client application can easily do this by passing the `assetId` , `width` & the `JPEGQulaity`. `width` & the `JPEGQulaity` are optional fields. If nothing provided sdk will use the width of the first available sprite stream & cache the sprite images with the `highest` JPEGQulaity.

```Swift
if let playable = playable, let sprites = sprites , let width = sprites.first?.width {
       let _ = self.player.activateSprites(assetId: playable.assetId, width: width, quality: .medium) {  spritesData, error in
       // print(" Sprites have been activated " , spritesData )
    }
}
```

When the developer activate the sprites, sdk will fetch all the sprite images & cache it.


## Get Sprites

After the activation client developers can get the sprite images by passing the player current time when scrubbing through the timeline. 

```Swift

let sliderPosition = Int64(sender.value * Float(duration))
let currentTime = timeFormat(time: sliderPosition)

if let assetId = self?.playable?.assetId {
       let _ = self?.player.getSprite(time: currentTime, assetId: assetId,callback: { image in
       // assign the image in to the UIImage 
   })
}
```

You can find a sample implementation on how to use the sprites in the SDK Sample App [`SDKSampleApp`](https://github.com/EricssonBroadcastServices/iOSClientSDKSampleApp) git hub repository.
