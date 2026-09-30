//
//  A2N_HymnalApp.swift
//  A2N Hymnal
//
//  Created by Paul Chen on 7/29/21.
//

import SwiftUI
import AVKit

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
                .onAppear(perform: Self.setMinimumWindowSize)
        }
        .commands { HymnalCommands(nowPlaying: nowPlaying, searchState: searchState) }
    }

    /// On the Mac, keep the window big enough for the list and lyrics side by side.
    private static func setMinimumWindowSize() {
        #if targetEnvironment(macCatalyst)
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            scene.sizeRestrictions?.minimumSize = CGSize(width: 760, height: 520)
        }
        #endif
    }
}

extension Notification.Name {
    /// Sent by the Settings… menu command; ContentView presents Settings.
    static let openSettings = Notification.Name("openSettings")
    /// Sent by Search Hymns (⌘F); ContentView shows the list and focuses its search field.
    static let focusSearch = Notification.Name("focusSearch")
    /// Sent by Play This Hymn (Return), or Play (Space) when nothing is loaded; ContentView
    /// plays the open hymn, replacing whatever was playing.
    static let playOpenHymn = Notification.Name("playOpenHymn")
}

/// Whether the search field is active, so a bare Space shortcut doesn't swallow typed spaces.
final class SearchState: ObservableObject {
    @Published var isSearching = false
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
        CommandMenu("Playback") {
            PlaybackCommands(nowPlaying: nowPlaying, spaceEnabled: !searchState.isSearching)
            Divider()
            // Like Spotify's Return on a selected track: play the hymn you're looking at.
            Button("Play This Hymn") { NotificationCenter.default.post(name: .playOpenHymn, object: nil) }
                .bareKeyShortcut(.return, enabled: !searchState.isSearching)
        }
    }
}

private struct PlaybackCommands: View {
    @ObservedObject var nowPlaying: NowPlaying
    let spaceEnabled: Bool

    var body: some View {
        if let player = nowPlaying.player {
            PlayerCommands(player: player, spaceEnabled: spaceEnabled)
        } else {
            // Like Spotify: with nothing loaded, Space plays the hymn you're looking at.
            Button("Play") { NotificationCenter.default.post(name: .playOpenHymn, object: nil) }
                .bareKeyShortcut(.space, enabled: spaceEnabled)
            Button("Start Over") {}.disabled(true)
            Button("Repeat") {}.disabled(true)
        }
    }
}

private struct PlayerCommands: View {
    @ObservedObject var player: Mp3Player
    let spaceEnabled: Bool

    var body: some View {
        Button(player.state == PlayerState.Playing ? "Pause" : "Play") {
            _ = player.state == PlayerState.Playing ? player.paused() : player.play()
        }
        .bareKeyShortcut(.space, enabled: spaceEnabled)
        Button("Start Over") { _ = player.restart() }
            .disabled(player.state == PlayerState.Stopped)
        Toggle("Repeat", isOn: $player.repeats)
            .keyboardShortcut("r", modifiers: [.command, .option])
    }
}

private extension View {
    /// A shortcut with no modifier (Space, Return), as in Spotify and Music. Turned off while
    /// typing in search, where those keys belong to the search field.
    @ViewBuilder
    func bareKeyShortcut(_ key: KeyEquivalent, enabled: Bool) -> some View {
        if enabled {
            keyboardShortcut(key, modifiers: [])
        } else {
            self
        }
    }
}
