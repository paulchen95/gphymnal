# App Store listing

Upload-ready graphics and copy for the App Store Connect product page (iOS app version 5.4.0).

| File | App Store Connect slot |
|---|---|
| `iphone-6.9/1-…7-….png` | iPhone 6.9" screenshots (1320×2868), in this order |
| `iphone-6.3/1-…7-….png` | iPhone 6.1"/6.3" "medium display" screenshots (1206×2622), the same set scaled down |
| `ipad-13/1-…5-….png` | iPad 13" screenshots (2064×2752), in this order |
| `header-3840x1646.png` | Product page header (3840×1646) |

App Store Connect rejects the 6.9" set in the medium-display slot, so `iphone-6.3/` is the same
set resized (`sips -z 2622 1206`). The screenshots are real captures from the simulator (iPhone 17 Pro Max, iPad
Pro 13-inch) with a 9:41 status bar, saved without an alpha channel, which App Store Connect
rejects. The iPad set is portrait, at the 150% text size, because the simulators run headless
here and can't be rotated. To retake them, launch with analytics off so the captures don't
reach Mixpanel:

```bash
SIMCTL_CHILD_XCTestConfigurationFilePath=screenshots xcrun simctl launch <udid> \
  org.gracepointonline.GP-Hymnal -hymnLocale en-us -lastOpenHymn "" \
  -favoriteHymns '("AmazingGrace","GreatIsThyFaithfulness","ItIsWellWithMySoul")'
xcrun simctl status_bar <udid> override --time 9:41 --batteryState discharging --batteryLevel 100
```

## Promotional text (170 max)

Over 120 classic hymns with full lyrics and a recording for each, in English and Chinese. Everything is built in, so it works anywhere, even offline.

## Description

A2N Hymnal is a simple, beautiful hymnal for iPhone, iPad and Mac, from Acts2 Network.

Over 120 classic hymns, each with its full lyrics and a recording to sing along with. Everything is built into the app, so it works anywhere, with no internet connection and nothing to download.

SING
• Lyrics are set like a printed hymnal: each sung line stands on its own, and long lines wrap with an indent so you never lose your place.
• Make the text bigger or smaller to suit your eyes.
• Refrains stand out, so you always know when to come back to the chorus.
• Author, composer and tune are listed with every hymn.

LISTEN
• Every hymn with a recording plays right from the lyrics page.
• Keep listening while you browse other hymns, or with your screen locked.
• Repeat a hymn to learn it, or skip back and forth 15 seconds.

FIND
• Browse A–Z, or jump straight to a letter.
• Search titles and lyrics. Remember a line but not the name? Search for it.
• Star your favorites to keep them at the top of the list.
• Christmas hymns are marked, and can be hidden outside the season.

MORE
• English, with Simplified and Traditional Chinese translations (beta).
• On iPad and Mac, the list and lyrics sit side by side.
• Light and dark mode.
• Free, with no ads and no account.

All included music is royalty-free and copyright-free.

## What's New in This Version (5.4.0)

A fresh design, in the Acts2 Network style:
• Dark mode
• Hymns grouped A–Z with a quick index, and search by title or lyrics
• Star your favorites to keep them at the top of the list
• iPad, and large iPhones turned sideways, show the list and lyrics side by side
• Adjustable lyrics text size, and copy any hymn's lyrics
• Audio keeps playing while you browse, with a new Now Playing screen
• A new app icon

## Keywords (100 max)

hymns,worship,church,lyrics,Christian,songbook,praise,gospel,Chinese,hymn book,sing,choir

The app name is already indexed, so "hymnal" isn't repeated here.

## Other fields

- **Support URL:** https://acts2.network
- **Marketing URL:** the A2N Hymnal Google Site, once it's published
- **Copyright:** 2026 Acts2 Network
- **Sign-in required:** no (there is no account)
- **App Review notes:** No account or sign-in. All hymns and recordings are built into the app. Open any hymn and tap the play button at the bottom to hear it.

## App Privacy

5.4.0 adds anonymous Mixpanel analytics (`ANALYTICS.md`), so the App Privacy answers change
from "no data collected":

- **Usage Data → Product Interaction**, used for Analytics, not linked to the user's
  identity, not used for tracking.
- **Identifiers → Device ID**, if Mixpanel's anonymous ID counts as one under Apple's
  definitions; same answers.
