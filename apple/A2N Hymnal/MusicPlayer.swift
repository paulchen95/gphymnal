//
//  MusicPlayer.swift
//  A2N Hymnal
//
//  Created by Paul Chen on 3/4/22.
//
import Foundation
import SwiftUI
import AVKit

enum PlayerState {
    case Playing, Stopped, Paused
}

class Mp3Player: NSObject, ObservableObject, AVAudioPlayerDelegate {
    /// The hymn's filename.
    let name: String
    var mp3File: URL?
    var player: AVAudioPlayer?
    @Published var state: PlayerState = PlayerState.Stopped
    /// Loop the hymn continuously (for practicing). Remembered across hymns and launches.
    @Published var repeats = UserDefaults.standard.bool(forKey: Mp3Player.repeatKey) {
        didSet {
            UserDefaults.standard.set(repeats, forKey: Mp3Player.repeatKey)
            player?.numberOfLoops = repeats ? -1 : 0
        }
    }
    static let repeatKey = "repeatHymn"
    /// Playback volume within the app (0–1), set from the Playback menu on the Mac. Carried
    /// over to the next hymn's player for the rest of the session.
    @Published var volume: Float = Mp3Player.sessionVolume {
        didSet {
            player?.volume = volume
            Mp3Player.sessionVolume = volume
        }
    }
    private static var sessionVolume: Float = 1
    @Published var currentTime: TimeInterval = 0
    private var progressTimer: Timer?

    var duration: TimeInterval { player?.duration ?? 0 }

    init (name: String) {
        self.name = name
        super.init()
        mp3File = Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "music")
        if let mp3File = mp3File {
            player = try? AVAudioPlayer(contentsOf: mp3File)
            player?.delegate = self
            player?.numberOfLoops = repeats ? -1 : 0
            player?.volume = volume
        }
    }
    
    func play() -> PlayerState {
        if let player = player, player.prepareToPlay() {
            player.play()
            state = PlayerState.Playing
            startProgressTimer()
        }
        return state
    }
    
    func paused() -> PlayerState {
        if isAvailable(), let player = player {
            player.pause()
            state = PlayerState.Paused
            stopProgressTimer()
            currentTime = player.currentTime
        }
        return state
    }

    func stop() -> PlayerState {
        if isAvailable(), let player = player {
            player.stop()
            player.currentTime = 0.0
            state = PlayerState.Stopped
            stopProgressTimer()
            currentTime = 0
        }
        return state
    }

    /// Back to the beginning. Keeps playing if it was playing; otherwise resets to stopped.
    func restart() -> PlayerState {
        guard state == PlayerState.Playing else { return stop() }
        seek(to: 0)
        return state
    }

    func skip(by seconds: TimeInterval) {
        seek(to: currentTime + seconds)
    }

    func seek(to time: TimeInterval) {
        guard let player = player else { return }
        player.currentTime = min(max(time, 0), player.duration)
        currentTime = player.currentTime
        if state == PlayerState.Stopped && currentTime > 0 {
            state = PlayerState.Paused
        }
    }

    static func hasAudio(_ name: String) -> Bool {
        Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "music") != nil
    }

    /// Length of a hymn's recording without loading it for playback; 0 if there isn't one.
    nonisolated static func duration(of name: String) -> TimeInterval {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "music"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return 0 }
        return player.duration
    }

    func isAvailable() -> Bool {
        return mp3File != nil
    }
    
    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        state = PlayerState.Stopped
        stopProgressTimer()
        currentTime = 0
        Analytics.track(.hymnFinished(name, locale: Analytics.locale))
    }

    // MARK: - Progress
    private func startProgressTimer() {
        stopProgressTimer()
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player else { return }
            self.currentTime = player.currentTime
        }
        // .common so the progress keeps moving while the lyrics are being scrolled.
        RunLoop.main.add(timer, forMode: .common)
        progressTimer = timer
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
}

/// The hymn loaded for playback, shared across the app so audio keeps going while you
/// browse other hymns — the mini player follows you, picture-in-picture style.
final class NowPlaying: ObservableObject {
    @Published private(set) var hymn: Hymn?
    @Published private(set) var player: Mp3Player?

    func isCurrent(_ hymn: Hymn) -> Bool { self.hymn?.filename == hymn.filename }

    /// Starts `hymn`, replacing whatever was loaded; resumes it if it's already loaded.
    func play(_ hymn: Hymn) {
        if !isCurrent(hymn) {
            _ = player?.stop()
            let newPlayer = Mp3Player(name: hymn.filename)
            guard newPlayer.isAvailable() else { return }
            player = newPlayer
            self.hymn = hymn
        }
        _ = player?.play()
        Analytics.track(.hymnPlayed(hymn.filename, locale: Analytics.locale))
    }

    /// Stops playback and dismisses the mini player.
    func close() {
        _ = player?.stop()
        player = nil
        hymn = nil
    }
}
