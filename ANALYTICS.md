# Analytics

Anonymous usage analytics, sent to one Mixpanel project ("A2N Hymnal", token
`030517a13efaff4880d81caee92d3d95`) from every platform, the way Tribe does it: one project, with
a `platform` super property on every event to split it.

| Platform | How | Code |
|---|---|---|
| iPhone, iPad, Mac | Mixpanel's Swift SDK (Swift Package Manager) | `apple/A2N Hymnal/Analytics.swift` |
| Android | Mixpanel's Android SDK | `android/app/.../MixpanelSink.kt` |
| Windows | Mixpanel's HTTP API (`/track`); there is no SDK for a desktop JVM app | `android/desktop/.../MixpanelHttpSink.kt` |

Android and Windows share the event code (`android/shared/.../analytics/Analytics.kt`); each
app only supplies where events go. The SDKs also send Mixpanel's automatic events (first open,
sessions, app updates); Windows doesn't, so cross-platform charts use `App Opened`.

The app works offline and must keep working behind China's firewall. So events queue on the
device and are sent when a connection is available (the SDKs do this themselves; Windows keeps
its queue in `%LOCALAPPDATA%\A2N Hymnal\analytics-queue.jsonl`). A failure to send never
blocks or breaks the app. The Apple unit tests don't send anything.

## What's sent

No sign-in and no personal data: each install gets a random ID. No search text and no lyrics.
There is no setting to turn it off. The store privacy forms must say so: App Store "Data Used
to Track You: none; Data Not Linked to You: usage data, diagnostics"; Google Play Data safety;
Microsoft Store privacy policy.

Every event carries `platform` (`ios`, `ipados`, `macos`, `android` or `windows`) and
`app_version` (e.g. `5.4.0`). `content/fixtures/analytics.json` pins the names and properties,
and every app's tests check them.

| Event | Properties | When |
|---|---|---|
| App Opened | | The app starts |
| Hymn Viewed | `hymn` (filename), `locale` | A hymn's lyrics are opened (not when the app reopens on one) |
| Hymn Played | `hymn`, `locale` | A hymn is started from the list, lyrics page, mini player, a link or a shortcut |
| Hymn Finished | `hymn`, `locale` | A recording plays to the end (never while Repeat is on) |
| Repeat Toggled | `enabled` | |
| Hymn Searched | `query_length`, `result_count` | Search text has sat still for 1.5 s |
| Favorite Added / Favorite Removed | `hymn` | |
| Setting Changed | `setting`, `value` | `language`, `text_size` (percent), `appearance`, `christmas_hymns`, `search_highlighting` |

Adding an event: add it to the fixture, then to both `Analytics.swift` and `Analytics.kt`, and
to this table.
