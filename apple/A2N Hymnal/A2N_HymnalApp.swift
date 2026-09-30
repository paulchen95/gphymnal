//
//  A2N_HymnalApp.swift
//  A2N Hymnal
//
//  Created by Paul Chen on 7/29/21.
//

import SwiftUI
import AVKit
#if targetEnvironment(macCatalyst)
import UIKit.UIGestureRecognizerSubclass
#endif

@main
struct A2N_HymnalApp: App {
    @StateObject var settings = Settings()
    @StateObject var nowPlaying = NowPlaying()
    @StateObject var searchState = SearchState()
    
    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        Brand.applyNavigationBarAppearance()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(nowPlaying)
                .environmentObject(searchState)
                // Set explicitly: the asset catalog's global accent (NSAccentColorName) isn't
                // being picked up on its own.
                .tint(.brandAccent)
                .onAppear(perform: Self.setUpMacWindow)
        }
        .commands { HymnalCommands(nowPlaying: nowPlaying, searchState: searchState) }
    }

    /// On the Mac, keep the window big enough for the list and lyrics side by side, and
    /// watch for double-clicks in the hymn list (see `ListDoubleClickRecognizer`).
    private static func setUpMacWindow() {
        #if targetEnvironment(macCatalyst)
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            scene.sizeRestrictions?.minimumSize = CGSize(width: 760, height: 520)
            for window in scene.windows
            where !(window.gestureRecognizers ?? []).contains(where: { $0 is ListDoubleClickRecognizer }) {
                window.addGestureRecognizer(ListDoubleClickRecognizer())
            }
        }
        #endif
    }
}

#if targetEnvironment(macCatalyst)
/// Double-click a hymn in the list to play it, as in Spotify. macOS counts the clicks itself
/// (`UITouch.tapCount`, using the system double-click speed), so this doesn't miss the second
/// click while the first one is still opening the hymn, as a SwiftUI count-2 tap gesture did.
/// The first click has already selected the hymn, so a second click in the list plays the
/// selection. It only watches: every click still reaches the list as normal.
final class ListDoubleClickRecognizer: UIGestureRecognizer {
    init() {
        super.init(target: nil, action: nil)
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if let touch = touches.first, touch.tapCount == 2, Self.isInList(touch.view) {
            NotificationCenter.default.post(name: .playOpenHymn, object: nil)
        }
        state = .failed
    }

    override func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool { false }

    /// SwiftUI lists are collection views; the lyrics and player aren't.
    private static func isInList(_ view: UIView?) -> Bool {
        var view = view
        while let current = view {
            if current is UICollectionView { return true }
            view = current.superview
        }
        return false
    }
}
#endif

extension Notification.Name {
    /// Sent by the Settings… menu command; ContentView presents Settings.
    static let openSettings = Notification.Name("openSettings")
    /// Sent by Search Hymns (⌘F); ContentView shows the list and focuses its search field.
    static let focusSearch = Notification.Name("focusSearch")
    /// Sent by Play This Hymn (Return), or Play (Space) when nothing is loaded; ContentView
    /// plays the open hymn, replacing whatever was playing.
    static let playOpenHymn = Notification.Name("playOpenHymn")
    /// Sent by Next (⌘→) and Previous (⌘←); ContentView plays the neighbouring hymn in the
    /// list as it's currently shown, and opens its lyrics.
    static let playNextHymn = Notification.Name("playNextHymn")
    static let playPreviousHymn = Notification.Name("playPreviousHymn")
}

/// Whether the search field is active, so a bare Space shortcut doesn't swallow typed spaces.
final class SearchState: ObservableObject {
    @Published var isSearching = false
    /// The text cursor is in the search field (known on iOS 18+ / macOS 15+).
    @Published var searchFieldFocused = false

    /// Typing in the search field, so Space, Return and ⌘-arrows should reach it. Where the
    /// field's focus is known, use it: on the Mac, `isSearching` stays true after you've
    /// moved on to the list, which switched those shortcuts off.
    var isTyping: Bool {
        if #available(iOS 18, *) { return searchFieldFocused }
        return isSearching
    }
}

/// Menu bar commands (Mac) and hardware-keyboard shortcuts (iPad): Settings…, lyrics text
/// size, and playback of the loaded hymn.
struct HymnalCommands: Commands {
    @ObservedObject var nowPlaying: NowPlaying
    @ObservedObject var searchState: SearchState
    @AppStorage(LyricsTextSize.storageKey) private var textSizeStep = LyricsTextSize.defaultStep

    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Settings…") { NotificationCenter.default.post(name: .openSettings, object: nil) }
                .keyboardShortcut(",")
        }
        CommandGroup(after: .pasteboard) {
            Divider()
            Button("Search Hymns") { NotificationCenter.default.post(name: .focusSearch, object: nil) }
                .keyboardShortcut("f")
        }
        CommandGroup(after: .toolbar) {
            Button("Larger Text") { textSizeStep = LyricsTextSize.clamped(textSizeStep + 1) }
                .keyboardShortcut("+")
                .disabled(textSizeStep >= LyricsTextSize.multipliers.count - 1)
            Button("Smaller Text") { textSizeStep = LyricsTextSize.clamped(textSizeStep - 1) }
                .keyboardShortcut("-")
                .disabled(textSizeStep <= 0)
            Button("Actual Size") { textSizeStep = LyricsTextSize.defaultStep }
                .keyboardShortcut("0")
            Divider()
        }
        // Spotify's Playback menu and shortcuts (minus Shuffle), so there's nothing new to learn.
        CommandMenu("Playback") {
            PlaybackCommands(nowPlaying: nowPlaying, typing: searchState.isTyping)
        }
    }
}

private struct PlaybackCommands: View {
    @ObservedObject var nowPlaying: NowPlaying
    /// While typing in search, bare keys and ⌘-arrows belong to the search field.
    let typing: Bool

    var body: some View {
        if let player = nowPlaying.player {
            PlayerCommands(player: player, typing: typing)
        } else {
            // Like Spotify: with nothing loaded, Space plays the hymn you're looking at.
            Button("Play") { post(.playOpenHymn) }
                .shortcut(.space, enabled: !typing)
            Divider()
            Button("Next") { post(.playNextHymn) }
                .shortcut(.rightArrow, modifiers: .command, enabled: !typing)
            Button("Previous") { post(.playPreviousHymn) }
                .shortcut(.leftArrow, modifiers: .command, enabled: !typing)
            Button("Seek Forward") {}.disabled(true)
            Button("Seek Backward") {}.disabled(true)
            Divider()
            Button("Repeat") {}.disabled(true)
            Button("Start Over") {}.disabled(true)
            Button("Play This Hymn") { post(.playOpenHymn) }
                .shortcut(.return, enabled: !typing)
            Divider()
            Button("Volume Up") {}.disabled(true)
            Button("Volume Down") {}.disabled(true)
        }
    }
}

private struct PlayerCommands: View {
    @ObservedObject var player: Mp3Player
    let typing: Bool

    private var isPlaying: Bool { player.state == PlayerState.Playing }

    var body: some View {
        Button(isPlaying ? "Pause" : "Play") {
            _ = isPlaying ? player.paused() : player.play()
        }
        .shortcut(.space, enabled: !typing)

        Divider()
        Button("Next") { post(.playNextHymn) }
            .shortcut(.rightArrow, modifiers: .command, enabled: !typing)
        // Like Spotify, Previous restarts the hymn unless it has only just begun.
        Button("Previous") {
            if player.currentTime > 3 { player.seek(to: 0) } else { post(.playPreviousHymn) }
        }
        .shortcut(.leftArrow, modifiers: .command, enabled: !typing)
        Button("Seek Forward") { player.skip(by: 15) }
            .shortcut(.rightArrow, modifiers: [.command, .shift], enabled: !typing)
        Button("Seek Backward") { player.skip(by: -15) }
            .shortcut(.leftArrow, modifiers: [.command, .shift], enabled: !typing)

        Divider()
        Toggle("Repeat", isOn: $player.repeats)
            .keyboardShortcut("r")
        Button("Start Over") { _ = player.restart() }
            .disabled(player.state == PlayerState.Stopped)
        // Like Spotify's Return on a selected track: play the hymn you're looking at.
        Button("Play This Hymn") { post(.playOpenHymn) }
            .shortcut(.return, enabled: !typing)

        Divider()
        Button("Volume Up") { player.volume = min(player.volume + 0.1, 1) }
            .keyboardShortcut(.upArrow)
            .disabled(player.volume >= 1)
        Button("Volume Down") { player.volume = max(player.volume - 0.1, 0) }
            .keyboardShortcut(.downArrow)
            .disabled(player.volume <= 0)
    }
}

private func post(_ name: Notification.Name) {
    NotificationCenter.default.post(name: name, object: nil)
}

private extension View {
    /// A menu shortcut that's switched off while typing in search, where Space, Return and
    /// ⌘-arrows belong to the search field.
    @ViewBuilder
    func shortcut(_ key: KeyEquivalent, modifiers: EventModifiers = [], enabled: Bool) -> some View {
        if enabled {
            keyboardShortcut(key, modifiers: modifiers)
        } else {
            self
        }
    }
}
