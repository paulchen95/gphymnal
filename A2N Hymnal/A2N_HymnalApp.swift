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
    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback)
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
    }
}
