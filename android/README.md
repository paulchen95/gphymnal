# A2N Hymnal for Android and Windows

A native Kotlin + Jetpack Compose app with the same features as the Apple app (see
`../FEATURES.md`). The Windows app is the same code on Compose Multiplatform: the rules,
settings and screens live in `shared/`, and each app adds only its player, hymn loading and
window. The Apple apps stay native SwiftUI. It reads the shared hymns and recordings straight from `../content/` as
APK assets, so a hymn is added once for every app. The recordings are stored as they are,
uncompressed and at full quality, and nothing is downloaded: the app must work offline,
including behind China's firewall.

## Build and run

Needs the Android SDK (Android Studio installs it) and JDK 17+. Android Studio's bundled
JDK works:

```bash
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
cd android
./gradlew :shared:desktopTest   # shared fixtures + content checks, no emulator needed
./gradlew installDebug          # build and install on a running emulator or device
./gradlew :desktop:run          # the Windows app, in a window on any OS (for development)
```

Or open `android/` in Android Studio and press Run.

## Layout

```
shared/src/commonMain/kotlin/network/acts2/hymnal/   used by both apps
  core/        plain Kotlin rules shared with Apple: parsing, A–Z sections, search,
               links, text size. The JVM tests run content/fixtures against these.
  data/        saved settings, and HymnRepository (each app says how to read its bundle)
  playback/    the Playback interface the screens drive
  ui/          Compose screens: list, lyrics, mini player and Now Playing, Settings
  HymnalViewModel.kt, Shortcuts.kt
shared/src/commonMain/composeResources/   Clash Grotesk and the About icon
shared/src/desktopTest/   SharedFixtureTest (content/fixtures/*.json), ContentTest (real hymn files)
app/           Android: MainActivity, APK assets, Media3 ExoPlayer and its background service
desktop/       Windows: the window, JavaFX audio, java.util.prefs settings, the installer
```

Chinese titles sort by pinyin using Android's built-in ICU (Android 10+). On Android 8–9
they file under "#". The tests use ICU4J, which gives the same results.

## Windows

`./gradlew :desktop:packageMsi` builds `desktop/build/compose/binaries/main/msi/A2N Hymnal-<version>.msi`.
It has to run on Windows (jpackage can't cross-build), with a full JDK 17+ such as Temurin;
Android Studio's JDK has no jpackage. `:desktop:packageExe` makes an .exe installer instead.

**Test builds.** CI builds the MSI on every Android-side change. Each build on `main`, or a
manual run (Actions → CI → Run workflow, on any branch), is published as a GitHub
pre-release named "Windows test build N", with install steps in its notes. Send testers that
link. N is CI's run number and becomes the MSI's third version number (5.4.N), so a newer
build always installs over an older one without bumping the version Android and Apple share.
Settings → About shows "5.4.0 (Windows build N)".

The installer bundles a trimmed Java runtime, JavaFX (for MP3 playback, through Windows'
own decoders) and the recordings, which install next to the app at full quality, the same as
the other apps. It installs per user, so no administrator prompt. Settings are saved with
`java.util.prefs` (the registry, under `HKCU\Software\JavaSoft\Prefs\network\acts2\hymnal`).

The installer isn't code-signed yet, so Windows SmartScreen warns before installing. Signing
needs a code-signing certificate (or Azure Trusted Signing); the Microsoft Store signs for you.
Keep `upgradeUuid` in `desktop/build.gradle.kts` unchanged forever, so new versions install
over old ones.

## Releasing

The version is set once, in `gradle.properties` (`hymnal.versionName`, `hymnal.versionCode`),
for both Android and Windows.

The recordings ship as `music`, a Play **install-time asset pack** (`music/build.gradle.kts`):
it installs with the app and works offline, but doesn't count toward Google Play's 200 MB
base limit (the base is ~4 MB). Debug builds put the music straight in the APK instead, so
`installDebug` plays without Play.

Release builds are signed with the Play **upload key**, kept out of the repo. Its keystore
is `~/.android-keys/a2n-hymnal-upload.jks` and its passwords are in
`~/.gradle/gradle.properties` (`A2N_HYMNAL_UPLOAD_*`). Back both up somewhere safe. If the key
is lost, Google can reset it, since Play App Signing holds the real signing key.

1. Bump `hymnal.versionName` (same as the Apple app's `MARKETING_VERSION`) and
   `hymnal.versionCode` (`YYYYMMDDNN`: the date and a build number; it must go up with every
   upload) in `gradle.properties`.
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
