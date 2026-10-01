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
    @EnvironmentObject private var searchState: SearchState
    @State private var showSettings: Bool = false
    @FocusState private var searchFocused: Bool
    /// The open hymn's filename. Shared by both layouts, so rotating keeps it open.
    @State private var selection: String?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    /// Whether the list and lyrics are side by side, so the open hymn is highlighted in the list.
    @State private var isSplit = false

    var body: some View {
        GeometryReader { geometry in
            // Side by side only when there's width to spare: iPad in landscape and the larger
            // iPhones held sideways, and always on the Mac. iPad in portrait keeps the single,
            // pushed layout.
            let split = Self.isMac
                || (horizontalSizeClass == .regular && geometry.size.width > geometry.size.height)
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
            .onChange(of: searchFocused) { focused in
                // Whether the cursor is really in the search field (iOS 18+). On the Mac the
                // field can stay "searching" after you've moved on to the list.
                searchState.searchFieldFocused = focused
            }
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
        .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in showSettings = true }
        .onReceive(NotificationCenter.default.publisher(for: .focusSearch)) { _ in
            showSettings = false
            if !isSplit { selection = nil } // back to the list, where the search field is
            DispatchQueue.main.async { searchFocused = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: .playNextHymn)) { _ in playNeighbour(1) }
        .onReceive(NotificationCenter.default.publisher(for: .playPreviousHymn)) { _ in playNeighbour(-1) }
        .onReceive(NotificationCenter.default.publisher(for: .playOpenHymn)) { _ in
            // Not while Settings is up: its form is a list too.
            if !showSettings, let hymn = selectedHymn { nowPlaying.play(hymn) }
        }
        .sheet(isPresented: $showSettings, content: {
            SettingsView()
                .environmentObject(viewModel)
        })
    }

    /// The Mac app always shows the list and lyrics side by side.
    private static var isMac: Bool {
        #if targetEnvironment(macCatalyst)
        true
        #else
        false
        #endif
    }

    @ViewBuilder
    private func hymnSections(_ sections: [HymnSection], selectable: Bool) -> some View {
        ForEach(sections) { section in
            Section {
                ForEach(section.hymns) { hymn in
                    if selectable {
                        ContentRowView(hymn: hymn)
                            .foregroundColor(.ink)
                            .contentShape(Rectangle())
                            // Double-click plays, as in Spotify and Music; a single click just
                            // selects, and Return plays the selection via the Playback menu. On
                            // the Mac, ListDoubleClickRecognizer handles double-clicks instead.
                            .iPadDoubleTapToPlay { playHymn(filename: hymn.filename) }
                            .tag(hymn.filename)
                            .help(Self.isMac ? "Double-click or press Return to play" : "")
                            .listRowBackground(selection == hymn.filename
                                               ? Color.brandAccent.opacity(0.15) : Color.paper)
                    } else {
                        // A plain button rather than a NavigationLink: no chevron, as in
                        // Contacts, so rows don't crowd the A–Z index. Setting the selection
                        // pushes the lyrics page.
                        Button {
                            selection = hymn.filename
                        } label: {
                            ContentRowView(hymn: hymn)
                                .foregroundColor(.ink)
                                .contentShape(Rectangle())
                        }
                        .listRowBackground(Color.paper)
                    }
                }
            } header: {
                SectionHeader(letter: section.letter)
            }
            .sectionIndexLetter(section.letter)
        }
    }

    private func playHymn(filename: String) {
        guard let hymn = viewModel.hymns.first(where: { $0.filename == filename }) else { return }
        selection = filename
        nowPlaying.play(hymn)
    }

    private func copyLyrics(filename: String) {
        guard let hymn = viewModel.hymns.first(where: { $0.filename == filename }) else { return }
        UIPasteboard.general.string = hymn.plainText
    }

    /// Plays the hymn `offset` places from the playing (or open) one, in the list's current
    /// order, and opens its lyrics. Stops at either end of the list.
    private func playNeighbour(_ offset: Int) {
        let ordered = viewModel.sections.flatMap(\.hymns)
        guard let current = nowPlaying.hymn?.filename ?? selection,
              let index = ordered.firstIndex(where: { $0.filename == current }),
              ordered.indices.contains(index + offset) else { return }
        let hymn = ordered[index + offset]
        selection = hymn.filename
        nowPlaying.play(hymn)
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
            Group {
                if isSplit {
                    // Side by side: a real selectable list, as in Mail and Music. Clicking or
                    // arrowing through hymns selects them (showing the lyrics); double-click
                    // or Return plays the selection.
                    List(selection: $selection) {
                        hymnSections(sections, selectable: true)
                    }
                    .macPlayAction(play: { playHymn(filename: $0) }, copy: { copyLyrics(filename: $0) })
                } else {
                    List {
                        hymnSections(sections, selectable: false)
                    }
                }
            }
            .listStyle(.plain)
            .background(SearchStateReporter(state: searchState))
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
        .searchFocusable($searchFocused)
        .environmentObject(viewModel)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSettings.toggle()
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                .plainToolbarButton()
            }
        } //: TOOLBAR
    }
}

/// A pinned letter header. On iOS 26 it's the system header inside a hard top scroll edge
/// effect (see `pinnedHeaderEdgeEffect`), so rows fade out behind it as they do under the nav
/// bar. Earlier versions have no edge effect, and on the Mac the effect frosts the whole
/// section rather than a strip under the letter, so there it sits on a solid bar instead.
/// Pinned headers sit in a scroll edge effect on iOS 26, but not on the Mac (see SectionHeader).
private var usesEdgeEffect: Bool {
    #if targetEnvironment(macCatalyst)
    return false
    #else
    if #available(iOS 26, *) { return true }
    return false
    #endif
}

private struct SectionHeader: View {
    let letter: String

    var body: some View {
        if usesEdgeEffect {
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

private extension View {
    /// iPad side-by-side list: double-tap a hymn to play it. (The Mac uses
    /// ListDoubleClickRecognizer, which counts clicks the way macOS does.)
    @ViewBuilder
    func iPadDoubleTapToPlay(_ play: @escaping () -> Void) -> some View {
        #if targetEnvironment(macCatalyst)
        self
        #else
        simultaneousGesture(TapGesture(count: 2).onEnded(play))
        #endif
    }

    /// Mac only: right-click a hymn for Play and Copy Lyrics. (Not the list's primaryAction,
    /// which on Catalyst fires on a single click; double-click is a gesture on each row.)
    @ViewBuilder
    func macPlayAction(play: @escaping (String) -> Void, copy: @escaping (String) -> Void) -> some View {
        #if targetEnvironment(macCatalyst)
        contextMenu(forSelectionType: String.self) { ids in
            if let id = ids.first {
                Button("Play") { play(id) }
                Button("Copy Lyrics") { copy(id) }
            }
        }
        #else
        self
        #endif
    }

    /// Lets ⌘F put the cursor in the search field (iOS 18 and later; earlier versions just
    /// show the list).
    @ViewBuilder
    func searchFocusable(_ focused: FocusState<Bool>.Binding) -> some View {
        if #available(iOS 18, *) {
            searchFocused(focused)
        } else {
            self
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
        if #available(iOS 26, *), usesEdgeEffect {
            scrollEdgeEffectStyle(.hard, for: .top)
        } else if #available(iOS 26, *) {
            // On the Mac, a solid bar instead: the edge effect there frosts far down the list.
            scrollEdgeEffectHidden(true, for: .all)
                .toolbarBackground(Color.paper, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        } else {
            self
        }
    }
}

/// Mirrors the list's `isSearching` into `SearchState` for the keyboard shortcuts.
private struct SearchStateReporter: View {
    @ObservedObject var state: SearchState
    @Environment(\.isSearching) private var isSearching

    var body: some View {
        Color.clear
            .onAppear { state.isSearching = isSearching }
            .onChange(of: isSearching) { newValue in state.isSearching = newValue }
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
            .environmentObject(SearchState())
    }
}
