//
//  A2N_HymnalApp.swift
//  A2N Hymnal
//
//  Created by Paul Chen on 7/29/21.
//

import SwiftUI
import Siren
import AVKit

@main
struct A2N_HymnalApp: App {
    init() {
        Siren.shared.wail()
        try? AVAudioSession.sharedInstance().setCategory(.playback)
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}