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
    case Playing, Stopped
}

class Mp3Player {
    var mp3File: URL?
    var player: AVAudioPlayer?
    var state: PlayerState = PlayerState.Stopped

    init (name: String) {
        mp3File = Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "Music")
    }

    func initPlayer() {
        if (isAvailable()) {
            player = try? AVAudioPlayer(contentsOf: mp3File!)
            player!.prepareToPlay()
        }
    }
    
    func play() -> PlayerState {
        if (isAvailable()) {
            if (player == nil) {
                initPlayer()
            }
            if (player != nil) {
                player!.play()
                state = PlayerState.Playing
            }
        }
        return state
    }

    func stop() -> PlayerState {
        if (isAvailable() && (player != nil)) {
            player!.stop()
            player!.currentTime = 0
            player!.prepareToPlay()
            state = PlayerState.Stopped
        }
        return state
    }

    func isAvailable() -> Bool {
        return (mp3File != nil)
    }
}
