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
        guard let mp3File = mp3File else {return}
        player = try? AVAudioPlayer(contentsOf: mp3File)
        if let player {
            player.prepareToPlay()
        }
    }
    
    func play() -> PlayerState {
        initPlayer()
        
        guard let player else { return state }
        player.play()
        state = PlayerState.Playing
        return state
    }

    func stop() -> PlayerState {
        guard let player else { return state }
        
        player.stop()
        player.currentTime = 0
        player.prepareToPlay()
        state = PlayerState.Stopped
        return state
    }

    func IsFileAvailable() -> Bool {
        return (mp3File != nil)
    }

}
