//
//  ContentViewRow.swift
//  A2N Hymnal
//
//  Created by Paul Chen on 12/9/23.
//

import SwiftUI

struct ContentViewRow: View {
    var hymn: Hymn

    var body: some View {
        HStack {
            Text(hymn.name).frame(maxWidth: .infinity, alignment: .leading)
            let midi = Bundle.main.url(forResource: hymn.filename, withExtension: "mp3", subdirectory: "Music")
            if (hymn.collection == "Christmas") {
                Image(systemName: "snowflake")
            } else {
                Image(systemName: "snowflake").hidden()
            }
            if (midi != nil) {
                Image(systemName: "music.note")
            } else {
                Image(systemName: "music.note").hidden()
            }
        }
    }
}
