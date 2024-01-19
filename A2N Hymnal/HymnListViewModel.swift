//
//  HymnListViewModel.swift
//  A2N Hymnal
//
//  Created by Paul Chen on 12/5/23.
//
import SwiftUI

class HymnListViewModel: ObservableObject {
    @Published var hymns = [Hymn]()
    @Published var searchText: String = ""

    var filteredHymns: [Hymn] {
        let catFilteredHymns = hymns.filter { hymn in
            globals.showChristmas || (hymn.collection != "Christmas")
        }
        guard !searchText.isEmpty else { return catFilteredHymns }
        return catFilteredHymns.filter { hymn in
            hymn.text.lowercased().contains(searchText.lowercased())
        }
    }
    
    init() {
        hymns = HymnList().toArray()
    }
}
