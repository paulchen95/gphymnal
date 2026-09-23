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
                .tint(Color("AccentColor"))
        }
    }
}
