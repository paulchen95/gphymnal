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

class Mp3Player {
    var mp3File: URL?
    var player: AVAudioPlayer?
    var state: PlayerState = PlayerState.Stopped

    init (name: String) {
        mp3File = Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "Music")
        if let mp3File = mp3File {
            player = try? AVAudioPlayer(contentsOf: mp3File)
        }
    }
    
    func play() -> PlayerState {
        if player!.prepareToPlay() {
            player!.play()
            state = PlayerState.Playing
        }
        return state
    }
    
    func paused() -> PlayerState {
        if isAvailable() && player != nil {
            player!.pause()
            state = PlayerState.Paused
        }
        return state
    }

    func stop() -> PlayerState {
        if isAvailable() && player != nil {
            player!.stop()
            player!.currentTime = 0.0
            state = PlayerState.Stopped
        }
        return state
    }

    func isAvailable() -> Bool {
        return mp3File != nil
    }
}
