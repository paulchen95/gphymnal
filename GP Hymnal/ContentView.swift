//
//  ContentView.swift
//  GP Hymnal
//
//  Created by Paul Chen on 7/29/21.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @State private var searchText = ""
    @State private var showCancelButton: Bool = false
    @State private var showHymnList: Bool = true
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search in lyrics...", text: $searchText, onEditingChanged: { isEditing in
                        self.showCancelButton = true
                        self.showHymnList = false
                    }).foregroundColor(.primary)

                    if !self.showHymnList {
                        Button {
                            UIApplication.shared.endEditing(true) // this must be placed before the other commands here
                            self.searchText = ""
                            self.showHymnList = true
                        } label: {
                            Label("", systemImage: "xmark.circle.fill")
                        }
                    }
                }
                .padding(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
                .background(Color(.secondarySystemBackground))
                
                List {
                    let hymnList = HymnList()
                    if showHymnList {
                        ForEach(hymnList.hymns, content: { hymn in
                            NavigationLink(destination: DetailsView(hymn: hymn)) {
                               HStack {
                                  Text(hymn.name).frame(maxWidth: .infinity, alignment: .leading)
                                  let midi = Bundle.main.url(forResource: hymn.filename, withExtension: "mid", subdirectory: "Music")
                                  if (midi != nil) {
                                     Image(systemName: "music.note")
                                  }
                               }
                           }
                        })
                    } else {
                        // Filtered list of names
                        ForEach(hymnList.hymns.filter {
                            $0.text.lowercased().contains(searchText.lowercased())
                        }, content: { hymn in
                            HStack {
                                NavigationLink(destination: DetailsView(hymn: hymn)) {
                                    Text(hymn.name).frame(maxWidth: .infinity, alignment: .leading)
                                    let midi = Bundle.main.url(forResource: hymn.filename, withExtension: "mid", subdirectory: "Music")
                                    if (midi != nil) {
              	     		     				         Image(systemName: "music.note")
               				                 }
                                }
                            }
                        })
                    }
                }
                .listStyle(PlainListStyle())
                .navigationBarTitle("", displayMode: .automatic) // set both navigationBarTitle and navigationBarHidden to hide the bar
                .navigationBarHidden(true)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension UIApplication {
    // This method will force the end of editing of any currently focused text field.
    func endEditing(_ force: Bool) {
        self.windows
            .filter{$0.isKeyWindow}
            .first?
            .endEditing(force)
    }
}

