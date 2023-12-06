//
//  ContentView.swift
//  A2N Hymnal
//
//  Created by Paul Chen on 7/29/21.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @StateObject var viewModel = HymnListViewModel()
    @State private var searchText = ""
    @State private var showCancelButton: Bool = false
    @State private var showHymnList: Bool = true
    @State private var showSettings: Bool = false
 
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.filteredHymns) { hymn in
                    NavigationLink(destination: DetailsView(hymn: hymn)) {
                       HStack {
                          Text(hymn.name).frame(maxWidth: .infinity, alignment: .leading)
                          let midi = Bundle.main.url(forResource: hymn.filename, withExtension: "mp3", subdirectory: "Music")
                          if (midi != nil) {
                             Image(systemName: "music.note")
                          }
                          if (hymn.collection == "Christmas") {
                             Image(systemName: "snowflake")
                          }
                       }
                    } //: NAVIGATIONLINK
                }
                .listRowSeparator(.automatic, edges: .all)
            } //: LIST
            .listStyle(.plain)
            .searchable(text: $viewModel.searchText)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    HStack {
                        Button {
                            showSettings.toggle()
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                        }
                    }
                }
            } //: TOOLBAR
        } //: NAVIGATION
        .sheet(isPresented: $showSettings, content: {
            SettingsView()
            .interactiveDismissDisabled(false)
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

//extension UIApplication {
//    // This method will force the end of editing of any currently focused text field.
//    func endEditing(_ force: Bool) {
//        let scenes = UIApplication.shared.connectedScenes
//        let windowScene = scenes.first as? UIWindowScene
//        windowScene?.windows
//            .filter{$0.isKeyWindow}
//            .first?
//            .endEditing(force)
//    }
//}
//
//extension View {
//    func phoneOnlyStackNavigationView() -> some View {
//        if UIDevice.current.userInterfaceIdiom == .phone {
//            return AnyView(self.navigationViewStyle(StackNavigationViewStyle()))
//        } else {
//            return AnyView(self)
//        }
//    }
//}
