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
                    HStack {
                        Image(systemName: "magnifyingglass")
                        TextField("Search in lyrics...", text: $searchText, onEditingChanged: { isEditing in
                            self.showCancelButton = true
                            self.showHymnList = false
                        }).foregroundColor(.primary)
                        
                        Button(action: {
                            UIApplication.shared.endEditing(true) // this must be placed before the other commands here
                            self.searchText = ""
                            self.showHymnList = true
                        }) {
                            Image(systemName: "xmark.circle.fill").opacity(searchText == "" ? 0 : 1)
                        }
                    }
                    .padding(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
                    .foregroundColor(.secondary)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10.0)

                    if showCancelButton  {
                        Button("Cancel") {
                            UIApplication.shared.endEditing(true) // this must be placed before the other commands here
                            self.searchText = ""
                            self.showCancelButton = false
                            self.showHymnList = true
                        }.foregroundColor(Color(.systemBlue))
                    }
                }.padding(.horizontal)
                
                Divider()
                List {
                    let hymnList = HymnList()
                    if showHymnList {
                        ForEach(hymnList.hymns, content: {
                            hymn in
                            NavigationLink(hymn.name, destination: DetailsView(hymn: hymn))
                        })
                    } else {
                        // Filtered list of names
                        ForEach(hymnList.hymns.filter {
                            $0.text.lowercased().contains(searchText.lowercased())
                        }, content: {
                            hymn in
                            NavigationLink(hymn.name, destination: DetailsView(hymn: hymn))
                        })
                    }
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

extension UIApplication {
    // This method will force the end of editing of any currently focused text field.
    func endEditing(_ force: Bool) {
        self.windows
            .filter{$0.isKeyWindow}
            .first?
            .endEditing(force)
    }
}
