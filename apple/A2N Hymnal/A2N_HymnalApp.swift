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
    
    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        Brand.applyNavigationBarAppearance()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(nowPlaying)
                // Set explicitly: the asset catalog's global accent (NSAccentColorName) isn't
                // being picked up on its own.
                .tint(.brandAccent)
                .onAppear(perform: Self.setMinimumWindowSize)
        }
        .commands { HymnalCommands(nowPlaying: nowPlaying) }
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
}

/// Menu bar commands (Mac) and hardware-keyboard shortcuts (iPad): Settings…, lyrics text
/// size, and playback of the loaded hymn.
struct HymnalCommands: Commands {
    @ObservedObject var nowPlaying: NowPlaying
    @AppStorage(LyricsTextSize.storageKey) private var textSizeStep = LyricsTextSize.defaultStep

    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Settings…") { NotificationCenter.default.post(name: .openSettings, object: nil) }
                .keyboardShortcut(",")
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
            PlaybackCommands(nowPlaying: nowPlaying)
        }
    }
}

private struct PlaybackCommands: View {
    @ObservedObject var nowPlaying: NowPlaying

    var body: some View {
        if let player = nowPlaying.player {
            PlayerCommands(player: player)
        } else {
            Button("Play") {}.disabled(true)
            Button("Repeat") {}.disabled(true)
        }
    }
}

private struct PlayerCommands: View {
    @ObservedObject var player: Mp3Player

    var body: some View {
        Button(player.state == PlayerState.Playing ? "Pause" : "Play") {
            _ = player.state == PlayerState.Playing ? player.paused() : player.play()
        }
        .keyboardShortcut("p", modifiers: [.command, .option])
        Button("Start Over") { _ = player.restart() }
            .disabled(player.state == PlayerState.Stopped)
        Toggle("Repeat", isOn: $player.repeats)
            .keyboardShortcut("r", modifiers: [.command, .option])
    }
}
