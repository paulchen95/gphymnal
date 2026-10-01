# Features and platform parity

Every user-facing feature, and where it's done. A PR that adds or changes a feature updates
this table. A feature lands on every platform, or the PR files follow-ups for the platforms
it doesn't cover.

✅ done · 🔲 not started · ◐ platform-native version (deliberately different, noted) · — not applicable

Behaviour marked **[fixture]** has examples in `content/fixtures/`. Every app's tests run
them, so the platforms can't drift on those rules.

## Hymns and content

| Feature | iPhone / iPad | Mac | Android | Notes |
|---|---|---|---|---|
| All hymns, lyrics and audio bundled; fully offline | ✅ | ✅ | 🔲 | Audio at full quality (96 kbps MP3), never streamed or re-encoded. Must work behind China's firewall. |
| Languages: English, Chinese (Simplified), Chinese (Traditional) | ✅ | ✅ | 🔲 | Chinese is "beta" in Settings. Translations reuse the English filename. |
| Hymn file format (`key:: value`, `---`, `text::` last) | ✅ | ✅ | 🔲 | **[fixture]** `parsing.json`. See `content/FORMAT.md`. |
| `[Refrain]` bold italic, `[Tag]` italic, until the next blank line | ✅ | ✅ | 🔲 | Markers aren't shown. |
| Credits under the lyrics (author, translator, composer, arranger, tune) | ✅ | ✅ | 🔲 | Labels translated per language. |
| Christmas hymns marked 🎄 after the title; can be hidden in Settings | ✅ | ✅ | 🔲 | `collection:: Christmas`. |

## Hymn list

| Feature | iPhone / iPad | Mac | Android | Notes |
|---|---|---|---|---|
| A–Z sections with pinned letter headers; `#` last | ✅ | ✅ | 🔲 | **[fixture]** `sections.json`: pinyin initials for Chinese, accents and leading punctuation ignored. |
| A–Z quick index down the side | ✅ | ✅ | 🔲 | Native index on iOS 26; drag-to-scrub. |
| Search titles and lyrics, ignoring case | ✅ | ✅ | 🔲 | **[fixture]** `search.json`. "No results" message. |
| Search highlighting in the lyrics (setting) | ✅ | ✅ | 🔲 | Red text. Multi-word matches. |
| List and lyrics side by side on wide screens | ✅ | ✅ | 🔲 | iPad landscape and large iPhones sideways; always on Mac. Portrait iPad pushes. |
| Rows have no disclosure chevrons | ✅ | ✅ | 🔲 | Keeps rows clear of the A–Z index. |

## Lyrics page

| Feature | iPhone / iPad | Mac | Android | Notes |
|---|---|---|---|---|
| Title in the page (not a truncated nav title), Clash Grotesk | ✅ | ✅ | 🔲 | |
| Hymnal setting: wrapped lines get a hanging indent; gap between sung lines | ✅ | ✅ | 🔲 | |
| Text size 85–200%, saved, shared with Settings | ✅ | ✅ | 🔲 | **[fixture]** `text-size.json`. On top of the system text size; clamped 14–48pt; line height ≈1.5×. |
| Lyrics fade under the top bar and the player | ✅ | ✅ | 🔲 | |
| Pinch to zoom | ✅ | ✅ | 🔲 | |
| Copy lyrics as plain text | ✅ | ✅ | 🔲 | Title, lyrics without markers, credits. |
| Share | — | — | — | Hidden until web links are live (`HymnLink.isSharingEnabled`). |

## Playback

| Feature | iPhone / iPad | Mac | Android | Notes |
|---|---|---|---|---|
| Keeps playing while you browse other hymns | ✅ | ✅ | 🔲 | One app-wide player. |
| Mini player pinned at the bottom; "ready to play" bar on a hymn with nothing loaded | ✅ | ✅ | 🔲 | "Play '…' instead" when viewing a different hymn. |
| Now Playing: cover card, timeline (tap or drag to seek), ±15 s, play/pause, Start Over, Repeat, View Lyrics | ✅ | ✅ | 🔲 | Cover card shows title and opening line on the gold gradient. |
| Repeat (loop the hymn), remembered | ✅ | ✅ | 🔲 | |
| Background audio | ✅ | ✅ | 🔲 | |
| Lock-screen / notification / Control Center controls | 🔲 | 🔲 | 🔲 | Planned. Android gets these from Media3. |
| Double-click a hymn to play it | ◐ | ✅ | 🔲 | iPad: double-tap in the side-by-side list. Mac: reads macOS's click count. |
| Keyboard: Space play/pause, Return play selected, ⌘→/⌘← next/previous, ⇧⌘→/⇧⌘← seek 15 s, ⌘R repeat, ⌘↑/⌘↓ volume | ◐ | ✅ | 🔲 | Spotify's shortcuts. iPad with a keyboard gets them via the same menu commands. Off while typing in search. Android: use the same keys with a hardware keyboard. |
| Previous restarts the hymn if more than 3 s in | ✅ | ✅ | 🔲 | Like Spotify. |

## Links

| Feature | iPhone / iPad | Mac | Android | Notes |
|---|---|---|---|---|
| Open a hymn from a link; `?play=1` plays it | ✅ | ✅ | 🔲 | **[fixture]** `links.json`. `a2nhymnal://hymn/<slug>`; web links once a host exists. |

## Settings and look

| Feature | iPhone / iPad | Mac | Android | Notes |
|---|---|---|---|---|
| Settings: About (icon, version), Language, Reading (text size + preview), Display (Christmas, highlighting) | ✅ | ✅ | 🔲 | Mac: Settings… (⌘,). |
| Acts2 Network look: warm paper/ink colours, gold accent, Clash Grotesk titles | ✅ | ✅ | 🔲 | Tokens in `apple/A2N Hymnal/Assets.xcassets`; gold is `Color.brandAccent`. |
| Follows system light/dark mode | ✅ | ✅ | 🔲 | |
| App icon: flat glyph, light and dark | ✅ | ✅ | 🔲 | Android: adaptive icon from the same glyph. |
| Mac menus: View text size (⌘+ ⌘- ⌘0), Edit → Search Hymns (⌘F), Playback | — | ✅ | — | |
| Mac minimum window size (760×520) | — | ✅ | — | |
