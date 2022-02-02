//
//  ContentView.swift
//  GP Hymnal
//
//  Created by Paul Chen on 7/29/21.
//

import SwiftUI
import Foundation

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                let hymnList = HymnList()
                ForEach(hymnList.hymns, content: {
                    hymn in
                    NavigationLink(hymn.name, destination:
                                    DetailsView(hymn: hymn))
                })
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
