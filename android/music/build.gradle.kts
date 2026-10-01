// The recordings, as a Play install-time asset pack: they install with the app (so it still
// works offline) but don't count toward Google Play's 200 MB base limit. The app reads them
// like any other asset, at music/<name>.mp3.
plugins {
    id("com.android.asset-pack")
}

assetPack {
    packName.set("music")
    dynamicDelivery {
        deliveryType.set("install-time")
    }
}
