# A2N Hymnal for Android

A native Kotlin + Jetpack Compose app with the same features as the Apple app (see
`../FEATURES.md`). It reads the shared hymns and recordings straight from `../content/` as
APK assets, so a hymn is added once for every app. The recordings are stored as they are,
uncompressed and at full quality, and nothing is downloaded: the app must work offline,
including behind China's firewall.

## Build and run

Needs the Android SDK (Android Studio installs it) and JDK 17+. Android Studio's bundled
JDK works:

```bash
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
cd android
./gradlew testDebugUnitTest     # shared fixtures + content checks, no emulator needed
./gradlew installDebug          # build and install on a running emulator or device
```

Or open `android/` in Android Studio and press Run.

## Layout

```
app/src/main/java/network/acts2/hymnal/
  core/        plain Kotlin rules shared with Apple: parsing, A–Z sections, search,
               links, text size. The JVM tests run content/fixtures against these.
  data/        the bundled hymns (HymnRepository) and saved settings
  playback/    the one app-wide player (Media3 ExoPlayer) and its background service
  ui/          Compose screens: list, lyrics, mini player and Now Playing, Settings
app/src/test/  SharedFixtureTest (content/fixtures/*.json), ContentTest (real hymn files)
```

Chinese titles sort by pinyin using Android's built-in ICU (Android 10+). On Android 8–9
they file under "#". The tests use ICU4J, which gives the same results.

## Before Google Play

- **Size.** The APK is about 270 MB, nearly all audio, and Google Play's base limit is
  200 MB. Ship the `music/` folder as an install-time asset pack (Play Asset Delivery), which
  installs with the app and stays offline. Stores in China take the full APK as built here.
- **Application ID.** `network.acts2.hymnal` is a placeholder until it's confirmed. It can't
  change once published.
- **Signing.** Release builds are unsigned; set up a Play upload key.
