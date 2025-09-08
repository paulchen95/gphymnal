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
    var mp3File: URL?
    var player: AVAudioPlayer?
    @Published var state: PlayerState = PlayerState.Stopped

    init (name: String) {
        super.init()
        mp3File = Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "Music")
        if let mp3File = mp3File {
            player = try? AVAudioPlayer(contentsOf: mp3File)
            player?.delegate = self
        }
    }
    
    func play() -> PlayerState {
        if let player = player, player.prepareToPlay() {
            player.play()
            state = PlayerState.Playing
        }
        return state
    }
    
    func paused() -> PlayerState {
        if isAvailable(), let player = player {
            player.pause()
            state = PlayerState.Paused
        }
        return state
    }

    func stop() -> PlayerState {
        if isAvailable(), let player = player {
            player.stop()
            player.currentTime = 0.0
            state = PlayerState.Stopped
        }
        return state
    }

    func isAvailable() -> Bool {
        return mp3File != nil
    }
    
    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        state = PlayerState.Stopped
    }
}
