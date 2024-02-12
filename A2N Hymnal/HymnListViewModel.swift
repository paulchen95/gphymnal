//
//  HymnListViewModel.swift
//  A2N Hymnal
//
//  Created by Paul Chen on 12/5/23.
//
import SwiftUI

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
            hymn.text.lowercased().contains(searchText.lowercased())
        }
    }
    
    init() {
        regenHymnList()
    }
    
    func regenHymnList() {
        hymns = HymnList(locale: settings.hymnLocale).build()
    }
}
