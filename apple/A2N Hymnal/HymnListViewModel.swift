//
//  HymnListViewModel.swift
//  A2N Hymnal
//
//  Created by Paul Chen on 12/5/23.
//
import SwiftUI
import Combine

struct HymnSection: Identifiable {
    let letter: String
    let hymns: [Hymn]
    var id: String { letter }
}

class HymnListViewModel: ObservableObject {
    @State var settings = Settings()
    @Published var hymns = [Hymn]()
    @Published var searchText: String = ""
    private var searchTracking: AnyCancellable?

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
    
    /// The index letter and id of the Favorites section.
    static let favoritesLetter = "★"

    /// `filteredHymns` grouped by first letter, A–Z then "#", for the indexed list.
    var sections: [HymnSection] {
        let grouped = Dictionary(grouping: filteredHymns, by: \.indexLetter)
        return grouped.keys
            .sorted { ($0 == "#" ? 1 : 0, $0) < ($1 == "#" ? 1 : 0, $1) }
            .map { letter in
                HymnSection(letter: letter, hymns: grouped[letter]!.sorted { $0.sortKey < $1.sortKey })
            }
    }

    /// `sections`, led by a Favorites section of the starred hymns (they stay in A–Z too).
    /// Left out while searching. `content/fixtures/favorites.json` pins the rules.
    func sections(favorites: Set<String>) -> [HymnSection] {
        let starred = searchText.isEmpty
            ? filteredHymns.filter { favorites.contains($0.filename) }.sorted { $0.sortKey < $1.sortKey }
            : []
        return (starred.isEmpty ? [] : [HymnSection(letter: Self.favoritesLetter, hymns: starred)]) + sections
    }

    init() {
        regenHymnList()
        // Counts a search once the text has sat still for a moment, not every keystroke.
        searchTracking = $searchText
            .debounce(for: .seconds(Analytics.searchDebounce), scheduler: RunLoop.main)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .sink { [weak self] text in
                guard let self else { return }
                Analytics.track(.hymnSearched(queryLength: text.count, resultCount: self.filteredHymns.count))
            }
    }
    
    func regenHymnList() {
        hymns = HymnList(locale: settings.hymnLocale, searchHighlighting: settings.enableSearchHighlighting).build()
    }
}
