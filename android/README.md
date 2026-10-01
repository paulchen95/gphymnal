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

## Releasing

The recordings ship as `music`, a Play **install-time asset pack** (`music/build.gradle.kts`):
it installs with the app and works offline, but doesn't count toward Google Play's 200 MB
base limit (the base is ~4 MB). Debug builds put the music straight in the APK instead, so
`installDebug` plays without Play.

Release builds are signed with the Play **upload key**, kept out of the repo. Its keystore
is `~/.android-keys/a2n-hymnal-upload.jks` and its passwords are in
`~/.gradle/gradle.properties` (`A2N_HYMNAL_UPLOAD_*`). Back both up somewhere safe. If the key
is lost, Google can reset it, since Play App Signing holds the real signing key.

1. Bump `versionName` (same as the Apple app's `MARKETING_VERSION`) and `versionCode`
   (the date, and it must always go up) in `app/build.gradle.kts`.
2. `./gradlew bundleRelease` → `app/build/outputs/bundle/release/app-release.aab`. Upload
   that to Play Console.
3. For stores in China and sideloading, make one full APK from the same bundle with
   [bundletool](https://github.com/google/bundletool/releases):
   ```bash
   java -jar bundletool.jar build-apks --mode=universal \
     --bundle=app/build/outputs/bundle/release/app-release.aab --output=hymnal.apks \
     --ks=$HOME/.android-keys/a2n-hymnal-upload.jks --ks-key-alias=upload
   unzip hymnal.apks universal.apk
   ```

The application ID is `network.acts2.hymnal`, matching Tribe's `network.acts2.tribe`. It can't
change once published.
