//
//  Analytics.swift
//  A2N Hymnal
//

import Foundation
import UIKit
import Mixpanel

/// One usage event: a name and its properties. Every app sends the same events to the same
/// Mixpanel project, so `content/fixtures/analytics.json` pins them; see `ANALYTICS.md`.
struct AnalyticsEvent: Equatable {
    let name: String
    var properties: [String: AnyHashable] = [:]

    static func appOpened() -> Self { Self(name: "App Opened") }
    static func hymnViewed(_ hymn: String, locale: String) -> Self {
        Self(name: "Hymn Viewed", properties: ["hymn": hymn, "locale": locale])
    }
    static func hymnPlayed(_ hymn: String, locale: String) -> Self {
        Self(name: "Hymn Played", properties: ["hymn": hymn, "locale": locale])
    }
    static func hymnFinished(_ hymn: String, locale: String) -> Self {
        Self(name: "Hymn Finished", properties: ["hymn": hymn, "locale": locale])
    }
    static func repeatToggled(_ enabled: Bool) -> Self {
        Self(name: "Repeat Toggled", properties: ["enabled": enabled])
    }
    /// Never the search text itself: only how long it was and what it found.
    static func hymnSearched(queryLength: Int, resultCount: Int) -> Self {
        Self(name: "Hymn Searched", properties: ["query_length": queryLength, "result_count": resultCount])
    }
    static func favoriteAdded(_ hymn: String) -> Self { Self(name: "Favorite Added", properties: ["hymn": hymn]) }
    static func favoriteRemoved(_ hymn: String) -> Self { Self(name: "Favorite Removed", properties: ["hymn": hymn]) }
    /// `setting` is language, text_size (a percent), appearance, christmas_hymns or search_highlighting.
    static func settingChanged(_ setting: String, value: AnyHashable) -> Self {
        Self(name: "Setting Changed", properties: ["setting": setting, "value": value])
    }
}

/// Anonymous usage analytics, in the A2N Hymnal Mixpanel project shared with Android and
/// Windows. Mixpanel's SDK queues events on the device and sends them when it can, so the app
/// stays fully usable offline. Every event is tagged with `platform` and `app_version`.
enum Analytics {
    static let mixpanelToken = "030517a13efaff4880d81caee92d3d95"
    /// How long search text must sit still before it counts as a search.
    static let searchDebounce: TimeInterval = 1.5

    private static var mixpanel: MixpanelInstance?
    private static var settingsObserver: SettingsObserver?

    /// Starts Mixpanel, once, at launch. Not while the unit tests run in the app.
    static func start() {
        guard mixpanel == nil,
              ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        // Automatic events (first open, sessions, app updates) come on top of ours.
        let instance = Mixpanel.initialize(token: mixpanelToken, trackAutomaticEvents: true)
        instance.registerSuperProperties([
            "platform": platform,
            "app_version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
        ])
        mixpanel = instance
        settingsObserver = SettingsObserver()
        track(.appOpened())
    }

    static func track(_ event: AnalyticsEvent) {
        mixpanel?.track(event: event.name, properties: event.properties.compactMapValues { $0.base as? MixpanelType })
    }

    /// The hymn language, for events about a hymn.
    static var locale: String {
        UserDefaults.standard.string(forKey: "hymnLocale") ?? "en-us"
    }

    /// "ios", "ipados" or "macos"; Android and Windows send "android" and "windows".
    private static var platform: String {
        #if targetEnvironment(macCatalyst)
        return "macos"
        #else
        return UIDevice.current.userInterfaceIdiom == .pad ? "ipados" : "ios"
        #endif
    }
}

/// Tracks settings changes, whichever screen, menu command or window made them: they're all
/// `@AppStorage` values, so this watches the stored values rather than each control.
private final class SettingsObserver {
    private struct Tracked {
        let key: String
        let event: (Any) -> AnalyticsEvent?
    }

    private let tracked: [Tracked] = [
        Tracked(key: "hymnLocale") { ($0 as? String).map { .settingChanged("language", value: $0) } },
        Tracked(key: LyricsTextSize.storageKey) {
            ($0 as? Int).map { .settingChanged("text_size", value: LyricsTextSize.percent(step: $0)) }
        },
        Tracked(key: Appearance.storageKey) { ($0 as? String).map { .settingChanged("appearance", value: $0) } },
        Tracked(key: "showChristmasHymns") { ($0 as? Bool).map { .settingChanged("christmas_hymns", value: $0) } },
        Tracked(key: "enableSearchHighlighting") { ($0 as? Bool).map { .settingChanged("search_highlighting", value: $0) } },
        Tracked(key: Mp3Player.repeatKey) { ($0 as? Bool).map { .repeatToggled($0) } },
    ]
    private var last: [String: NSObject] = [:]
    private var token: NSObjectProtocol?

    init() {
        let defaults = UserDefaults.standard
        for item in tracked { last[item.key] = defaults.object(forKey: item.key) as? NSObject }
        token = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification,
                                                       object: nil, queue: .main) { [weak self] _ in
            self?.check(defaults)
        }
    }

    private func check(_ defaults: UserDefaults) {
        for item in tracked {
            let value = defaults.object(forKey: item.key) as? NSObject
            guard value != last[item.key] else { continue }
            last[item.key] = value
            if let value, let event = item.event(value) { Analytics.track(event) }
        }
    }
}
