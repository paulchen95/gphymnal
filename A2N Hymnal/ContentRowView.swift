//
//  ContentRowView.swift
//  A2N Hymnal
//
//  Created by Paul Chen on 12/9/23.
//

import SwiftUI

struct ContentRowView: View {
    var hymn: Hymn

    private var isChristmas: Bool { hymn.collection == "Christmas" }

    var body: some View {
        // No audio badge: every hymn ships with its mp3, so it would be on every row.
        // The Christmas marker follows the title inline rather than sitting in its own column.
        (Text(hymn.name) + Text(isChristmas ? " " + Hymn.christmasMarker : ""))
            .frame(maxWidth: .infinity, alignment: .leading)
            // Keep long titles clear of the A–Z index that runs down the list's trailing edge.
            .padding(.trailing, 18)
            .accessibilityLabel(isChristmas ? hymn.name + ", Christmas" : hymn.name)
    }
}
