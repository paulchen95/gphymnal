//
//  ContentView.swift
//  GP Hymnal
//
//  Created by Paul Chen on 7/29/21.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("GP Hymnal v0.0.3")
            NavigationView {
                List {
                    ForEach(hymnalData.hymns, content: {
                        hymn in
                        NavigationLink(hymn.name, destination:
                                        DetailsView(hymn: hymn))
                    })
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
