//
//  GP_HymnalApp.swift
//  GP Hymnal
//
//  Created by Paul Chen on 7/29/21.
//

import SwiftUI
import Siren

@main
struct GP_HymnalApp: App {
    init() {
        Siren.shared.wail()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct audioResources {
    static var soundBank = Bundle.main.url(forResource: "Abbey-Steinway-D-v1.9", withExtension: "sf2", subdirectory: "Music")
}
