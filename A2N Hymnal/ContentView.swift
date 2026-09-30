//
//  ContentView.swift
//  A2N Hymnal
//
//  Created by Paul Chen on 7/29/21.
//
import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = HymnListViewModel()
    @EnvironmentObject private var nowPlaying: NowPlaying
    @State private var showSettings: Bool = false
    /// The open hymn's filename. Shared by both layouts, so rotating keeps it open.
    @State private var selection: String?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    /// Whether the list and lyrics are side by side, so the open hymn is highlighted in the list.
    @State private var isSplit = false

    var body: some View {
        GeometryReader { geometry in
            // Side by side only when there's width to spare: iPad in landscape and the larger
            // iPhones held sideways. iPad in portrait keeps the single, pushed layout.
            let split = horizontalSizeClass == .regular && geometry.size.width > geometry.size.height
            Group {
            if split {
                NavigationSplitView {
                    hymnList
                        .navigationSplitViewColumnWidth(min: 320, ideal: 400, max: 480)
                } detail: {
                    NavigationStack {
                        Group {
                            if let hymn = selectedHymn {
                                details(for: hymn)
                            } else {
                                NoHymnSelectedView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.paper.ignoresSafeArea())
                            }
                        }
                        .miniPlayer(nowPlaying, pageHymn: selectedHymn, showLyrics: { selection = $0 })
                    }
                }
                .navigationSplitViewStyle(.balanced)
            } else {
                NavigationStack(path: Binding(
                    get: { selection.map { [$0] } ?? [] },
                    set: { selection = $0.last }
                )) {
                    hymnList
                        .miniPlayer(nowPlaying, showLyrics: { selection = $0 })
                        .navigationDestination(for: String.self) { filename in
                            if let hymn = viewModel.hymns.first(where: { $0.filename == filename }) {
                                details(for: hymn)
                                    .miniPlayer(nowPlaying, pageHymn: hymn, showLyrics: { selection = $0 })
                            }
                        }
                }
            }
            }
            .onAppear { isSplit = split }
            .onChange(of: split) { newValue in isSplit = newValue }
        }
        // Shared links (see HymnLink) open straight to the hymn, and can start it playing.
        .onOpenURL { url in
            guard let link = HymnLink.parse(url),
                  let hymn = HymnLink.hymn(forSlug: link.slug, in: viewModel.hymns) else { return }
            showSettings = false
            selection = hymn.filename
            if link.play { nowPlaying.play(hymn) }
        }
        .sheet(isPresented: $showSettings, content: {
            SettingsView()
                .environmentObject(viewModel)
        })
    }

    private var selectedHymn: Hymn? {
        selection.flatMap { filename in viewModel.hymns.first { $0.filename == filename } }
    }

    private func details(for hymn: Hymn) -> some View {
        // A fresh view per hymn, so each gets its own audio player.
        DetailsView(hymn: hymn, searchText: viewModel.searchText)
            .id(hymn.filename)
    }

    /// On iPad the search field sits under the title across the list; the default placement
    /// there squeezes it into the toolbar under the status bar, or hides it in the split
    /// layout. iPhone keeps the default, at the bottom of the screen.
    private var searchPlacement: SearchFieldPlacement {
        horizontalSizeClass == .regular ? .navigationBarDrawer(displayMode: .always) : .automatic
    }

    private var hymnList: some View {
        let sections = viewModel.sections
        return ScrollViewReader { proxy in
            List {
                ForEach(sections) { section in
                    Section {
                        ForEach(section.hymns) { hymn in
                            // A plain button rather than a NavigationLink: no chevron, as in
                            // Contacts, so rows don't crowd the A–Z index. Setting the selection
                            // opens the hymn in either layout.
                            Button {
                                selection = hymn.filename
                            } label: {
                                ContentRowView(hymn: hymn)
                                    .foregroundColor(.ink)
                                    .contentShape(Rectangle())
                            }
                            .listRowBackground(
                                selection == hymn.filename && isSplit
                                    ? Color.brandAccent.opacity(0.15) : Color.paper
                            )
                        }
                    } header: {
                        SectionHeader(letter: section.letter)
                    }
                    .sectionIndexLetter(section.letter)
                }
            } //: LIST
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.paper.ignoresSafeArea())
            .pinnedHeaderEdgeEffect()
            .sectionIndex(sections.map(\.letter), proxy: proxy)
            .overlay {
                if sections.isEmpty && !viewModel.searchText.isEmpty {
                    NoSearchResultsView(searchText: viewModel.searchText)
                }
            }
        }
        .navigationTitle("Hymns")
        .searchable(text: $viewModel.searchText, placement: searchPlacement, prompt: "Search titles and lyrics")
        .environmentObject(viewModel)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSettings.toggle()
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        } //: TOOLBAR
    }
}

/// A pinned letter header. On iOS 26 it's the system header inside a hard top scroll edge
/// effect (see `pinnedHeaderEdgeEffect`), so rows fade out behind it as they do under the nav
/// bar. Earlier versions have no edge effect, so there it sits on a solid bar instead.
private struct SectionHeader: View {
    let letter: String

    var body: some View {
        if #available(iOS 26, *) {
            Text(letter)
        } else {
            Text(letter)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(Color.paperDeep)
                .listRowInsets(EdgeInsets())
        }
    }
}

extension View {
    /// Pins the player bar under this page's content. It's the one place for audio: on a
    /// hymn page with nothing loaded it offers that hymn, ready to play; otherwise it's the
    /// live mini player, with a "play this one instead" button when you're looking at a
    /// different hymn. Attached per page rather than to the whole app so it sits above
    /// iOS 26's bottom search field instead of on it.
    func miniPlayer(_ nowPlaying: NowPlaying, pageHymn: Hymn? = nil,
                    showLyrics: @escaping (String) -> Void) -> some View {
        modifier(MiniPlayerInset(nowPlaying: nowPlaying, pageHymn: pageHymn, showLyrics: showLyrics))
    }
}

private struct MiniPlayerInset: ViewModifier {
    @ObservedObject var nowPlaying: NowPlaying
    let pageHymn: Hymn?
    let showLyrics: (String) -> Void

    /// The page's hymn, if it has audio.
    private var playablePageHymn: Hymn? {
        guard let pageHymn, Mp3Player.hasAudio(pageHymn.filename) else { return nil }
        return pageHymn
    }

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 8) {
                    if let player = nowPlaying.player, let hymn = nowPlaying.hymn {
                        if let page = playablePageHymn, page.filename != hymn.filename {
                            PlayInsteadButton(hymn: page) { nowPlaying.play(page) }
                        }
                        AudioPlayerBar(player: player, hymn: hymn,
                                       onShowLyrics: { showLyrics(hymn.filename) },
                                       onClose: { nowPlaying.close() })
                    } else if let page = playablePageHymn {
                        ReadyToPlayBar(hymn: page) { nowPlaying.play(page) }
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .animation(.easeOut(duration: 0.25), value: nowPlaying.hymn?.filename)
    }
}

private extension View {
    /// Apple's guidance for pinned headers under Liquid Glass: a hard top edge effect, which
    /// extends the frosted area under the nav bar down over the pinned header.
    @ViewBuilder
    func pinnedHeaderEdgeEffect() -> some View {
        if #available(iOS 26, *) {
            scrollEdgeEffectStyle(.hard, for: .top)
        } else {
            self
        }
    }
}

private struct NoHymnSelectedView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Choose a Hymn")
                .font(.title2.bold())
            Text("Pick a hymn from the list to see its lyrics.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding()
    }
}

private struct NoSearchResultsView: View {
    let searchText: String

    var body: some View {
        if #available(iOS 17, *) {
            ContentUnavailableView.search(text: searchText)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("No Results for “\(searchText)”")
                    .font(.title3.bold())
                Text("Search looks through the titles and lyrics of every hymn.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(NowPlaying())
    }
}
