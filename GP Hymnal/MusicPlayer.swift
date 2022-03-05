import Foundation
import SwiftUI
import AVKit

enum PlayerState {
    case Playing, Stopped
}

class MidiPlayer {
    var player: AVMIDIPlayer?
    var state: PlayerState = PlayerState.Stopped
    var filename: String

    init (name: String) {
        filename = name
        if let midiFile = Bundle.main.url(forResource: name, withExtension: "mid", subdirectory: "Music") {
            if let soundBank = Bundle.main.url(forResource: "Abbey-Steinway-D-v1.9", withExtension: "sf2", subdirectory: "Music") {
                if let midiPlayer = try? AVMIDIPlayer(contentsOf: midiFile, soundBankURL: soundBank) {
                    player = midiPlayer
                    player!.prepareToPlay()
                }
            }
        }
    }

    func play() -> PlayerState {
        if (player != nil) {
            player!.play()
            state = PlayerState.Playing
        }
        return state
    }

    func stop() -> PlayerState {
        if (player != nil) {
            player!.stop()
            player!.currentPosition = 0
            player!.prepareToPlay()
            state = PlayerState.Stopped
        }
        return state
    }

    func isAvailable() -> Bool {
        return (player != nil)
    }
}
