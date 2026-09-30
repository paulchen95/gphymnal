//
//  HymnListViewModel.swift
//  A2N Hymnal
//
//  Created by Paul Chen on 12/5/23.
//
import SwiftUI

struct HymnSection: Identifiable {
    let letter: String
    let hymns: [Hymn]
    var id: String { letter }
}

class HymnListViewModel: ObservableObject {
    @State var settings = Settings()
    @Published var hymns = [Hymn]()
    @Published var searchText: String = ""

    var filteredHymns: [Hymn] {
        let catFilteredHymns = hymns.filter { hymn in
            settings.showChristmas || (hymn.collection != "Christmas")
        }
        guard !searchText.isEmpty else { return catFilteredHymns }
        return catFilteredHymns.filter { hymn in
            hymn.name.localizedCaseInsensitiveContains(searchText)
                || hymn.text.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    /// `filteredHymns` grouped by first letter, A–Z then "#", for the indexed list.
    var sections: [HymnSection] {
        let grouped = Dictionary(grouping: filteredHymns, by: \.indexLetter)
        return grouped.keys
            .sorted { ($0 == "#" ? 1 : 0, $0) < ($1 == "#" ? 1 : 0, $1) }
            .map { letter in
                HymnSection(letter: letter, hymns: grouped[letter]!.sorted { $0.sortKey < $1.sortKey })
            }
    }

    init() {
        regenHymnList()
    }
    
    func regenHymnList() {
        hymns = HymnList(locale: settings.hymnLocale, searchHighlighting: settings.enableSearchHighlighting).build()
    }
}
