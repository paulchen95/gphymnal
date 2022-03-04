//
//  GP_HymnalApp.swift
//  GP Hymnal
//
//  Created by Paul Chen on 7/29/21.
//

import SwiftUI
import Siren
import AVKit

@main
struct GP_HymnalApp: App {
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
