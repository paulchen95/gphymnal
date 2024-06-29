//
//  ContentView.swift
//  A2N Hymnal
//
//  Created by Paul Chen on 7/29/21.
//
import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = HymnListViewModel()
    @State private var showCancelButton: Bool = false
    @State private var showHymnList: Bool = true
    @State private var showSettings: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.filteredHymns) { hymn in
                    NavigationLink(destination: DetailsView(hymn: hymn, searchText: viewModel.searchText)) {
                        ContentRowView(hymn: hymn)
                    } //: NAVIGATIONLINK
                }
                .listRowSeparator(.automatic, edges: .all)
            } //: LIST
            .listStyle(.plain)
            .searchable(text: $viewModel.searchText)
            .environmentObject(viewModel)
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
                .environmentObject(viewModel)
                .interactiveDismissDisabled(false)
        })
        //    DetailsView(hymn: Hymn)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
