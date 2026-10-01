# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**A2N Hymnal** (bundle id `org.gracepointonline.GP-Hymnal`, formerly "GP Hymnal") is a
SwiftUI iOS/iPadApp: an offline hymnal with lyrics, credits, royalty-free audio, and
Chinese translations. It ships to the App Store. No package manager, no third-party
dependencies — plain Xcode project, iOS 16+, Swift 5.

Note the mismatch between names: the repo is `gphymnal`, the app/target/source directory
is `A2N Hymnal`, and the Swift module is `A2N_Hymnal`.

## Platform parity

`FEATURES.md` lists every user-facing feature and its status on iPhone/iPad, Mac and
Android. A feature change updates it, and either lands on every platform or files follow-ups
for the others. Rules that must match exactly (parsing, A–Z grouping, search, links, text
size) live as examples in `content/fixtures/`, which every app's tests run. Change the
fixture when a rule changes.

## Layout

```
content/          hymns and audio, shared by every app — adding a hymn happens only here
  hymns/<locale>/<Filename>.txt
  music/<Filename>.mp3
  FORMAT.md       the hymn file format
  fixtures/       shared behaviour examples (JSON) every app's tests run
apple/            Xcode project: iPhone and iPad app (A2N Hymnal/) and tests
android/          planned Android app (Kotlin + Jetpack Compose), not started
scripts/test.sh   runs the Apple app's tests
tools/validate-content   checks every hymn file and mp3 (Python 3, no Xcode needed)
FEATURES.md       feature list and per-platform status
```

## Commands

```bash
# Test — this is the entry point; it resolves a simulator, filters xcodebuild's
# noise down to failures plus the summary, and exits non-zero when tests fail.
scripts/test.sh                                        # all 55 tests, ~45s cold
scripts/test.sh HymnDataTests                          # one class
scripts/test.sh HymnDataTests/testHymnsAreSortedByName # one test
scripts/test.sh HymnParsingTests HymnDataTests         # several

SIMULATOR="iPhone Air" scripts/test.sh                 # pick the device
XCODEBUILD_ARGS=-quiet scripts/test.sh                 # pass flags through
```

On failure the script prints the path to the full xcodebuild log. Bare class and
`Class/method` names are qualified with the `A2N HymnalTests` target automatically.

The underlying invocation, when you need to drive xcodebuild directly:

```bash
xcodebuild test -project "apple/A2N Hymnal.xcodeproj" -scheme "A2N Hymnal" \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Its output is extremely noisy — pipe through
`grep -E "error:|Executed .* tests|\*\* TEST"`. Swap `test` for `build` to just build.
Simulator names change with each Xcode release; `xcrun simctl list devices available`
shows what exists locally.

There is no linter and no formatter configured. `.circleci/config.yml` is still the
generated "say hello" stub — CI does not build or test anything, so `scripts/test.sh`
only ever runs locally.

## Architecture

Content is **data, not code**. Hymns live as plain text files in
`content/hymns/<locale>/<Filename>.txt`, audio as `content/music/<Filename>.mp3`, outside
the Xcode project so other apps can share them. The project adds both as *folder
references* (blue folders pointing at `../../content/...`), so the directory structure
survives into the bundle as `hymns/` and `music/` and is looked up with the `subdirectory:`
argument of `Bundle.main.url(forResource:...)`. Adding a hymn means adding files, not
editing Swift.

The `<Filename>` (no spaces, PascalCase, derived from the English title) is the join key
across everything: it links an `en-us` file to its `zh-cn`/`zh-tw` translations and to the
mp3 of the same name. Translated files must reuse the English filename even though their
`name::` is Chinese — `HymnDataTests` enforces this.

### Hymn file format

Attributes are `key:: value`, separated by lines containing `---`, with `text::` last:

```
name:: Amazing Grace
---
author:: John Newton
---
composer:: Unknown
---
tune:: New Britain
---
text::
Amazing grace! How sweet the sound
...
```

Keys: `name`, `author`, `translator`, `composer`, `arranger`, `tune`, `collection`, `text`.
Only `name`, `author`, `composer`, `text` are used everywhere; the rest are optional.

- **The double colon matters.** `tune:` (one colon) is not recognized as an attribute and
  silently becomes part of the lyrics. Six files had this bug; a test now guards it.
- `collection:: Christmas` is the only non-default collection, and drives both the
  🎄 badge (`Hymn.christmasMarker`) and the "Christmas Hymns" setting. An absent `collection::`
  defaults to `"Hymn"`.
- Inside `text::`, a line of exactly `[Refrain]` styles subsequent lines bold+italic and
  `[Tag]` styles them italic, until the next blank line. The markers are not rendered.
- `text::` keeps the newline that follows the key (only spaces are trimmed), so lyrics
  begin with a blank line in the details view. That is intentional-by-inertia; several
  tests pin it.

### Code flow

`A2N_HymnalApp` → `ContentView` (searchable `List`) → `DetailsView` (zoomable lyrics +
audio toolbar). `HymnList` parses every `.txt` for the current locale into `[Hymn]` on each
call to `HymnListViewModel.regenHymnList()`; there is no cache and no persistence layer.
`Settings` is `@AppStorage`-backed and every settings toggle calls `regenHymnList()`,
because locale and search-highlighting are baked into each `Hymn` at parse time rather than
read at render time.

Playback is app-wide: `NowPlaying` (in `MusicPlayer.swift`) holds the loaded hymn and its
`Mp3Player`, so audio keeps going while you browse. Each page pins the mini player
(`AudioPlayerBar`) with `.miniPlayer(...)`, which opens `NowPlayingView` and its "View
Lyrics" shortcut. The lyrics text size is one `@AppStorage` value (`LyricsTextSize` in
`Settings.swift`) shared by the lyrics page's Aa button and Settings.

The look follows the Acts2 Network brand (`Brand.swift`): warm Paper/Ink colours and a gold
`AccentColor` in the asset catalog, and Clash Grotesk for large titles only. The global
accent isn't being applied, so `Color.accentColor` is system blue: use `Color.brandAccent`
for the gold, and the root sets `.tint(.brandAccent)`.
Anything inside `ZoomableScrollView` is hosted in UIKit and doesn't inherit SwiftUI's
environment (objects or tint), so pass those in explicitly.

Search matches **titles and lyrics** (`hymn.name` and `hymn.text`), case-insensitively.
It used to be lyrics-only; the search field's prompt says "Search titles and lyrics".

The lyrics page draws lyrics with `LyricsTextView` (in `DetailsView.swift`), a UITextView
that sets them like a printed hymnal: hanging indent on wrapped lines, a gap between sung
lines. It applies the same `[Refrain]`/`[Tag]` rules itself, so a change to those rules
belongs in both it and `Hymn.formatLyrics`.

`Hymn.formatText()` returns a composed SwiftUI `Text`, not a string: lyrics, then a
credits footer whose labels come from `locales` in `Locales.swift` (which also defines the
set of supported locales — adding a language means adding an entry there *and* a
`content/hymns/<locale>/` directory). `ZoomableScrollView` is a `UIViewRepresentable` pinch-zoom
workaround for an iOS 15 SwiftUI regression; leave it alone unless the zoom breaks.

## Tests

`apple/A2N HymnalTests/` is a unit-test target hosted by the app, so `Bundle.main` is the app
bundle and tests can read the real shipped hymn and audio files.

- `HymnParsingTests` — the `key:: value` / `---` format.
- `HymnFormattingTests` — lyrics styling, credits footer, search highlighting.
- `HymnListViewModelTests` — Christmas filter, title and lyrics search, and the A–Z sections (Chinese titles file under their pinyin initial).
- `SharedFixtureTests` — runs `content/fixtures/*.json` against the app's code.
- `HymnDataTests` — integrity of the *bundled* content (`tools/validate-content` runs the
  same file checks without Xcode). This is the one that catches a
  badly-formed new hymn: missing keys, unsorted or duplicated entries, an unknown
  `collection::`, a single-colon typo, a translation with no English counterpart, an mp3
  with no matching hymn.

Comparing SwiftUI `Text` has two traps, both explained in the header of
`HymnFormattingTests.swift`: expected values must use `Text(verbatim:)` (a `Text("literal")`
is a `LocalizedStringKey` and never equals a `Text` built from a runtime string), and
`formatLyrics`/`highlightSearchedText` seed their result with an empty `Text("")` that is
part of the tree.

## Releasing

Bump `MARKETING_VERSION` (e.g. `5.3.2`) and `CURRENT_PROJECT_VERSION` (dated, e.g.
`2025.0908`) in `project.pbxproj`, and prepend a version block to the top of `README.md` —
that file is the changelog, newest first.
