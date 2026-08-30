//
//  HymnListViewModelTests.swift
//  A2N HymnalTests
//
//  Covers the Christmas-collection filter and the lyrics search in HymnListViewModel.
//

import XCTest
@testable import A2N_Hymnal

final class HymnListViewModelTests: XCTestCase {
    private var originalShowChristmas: Any?

    override func setUp() {
        super.setUp()
        originalShowChristmas = UserDefaults.standard.object(forKey: "showChristmasHymns")
    }

    override func tearDown() {
        if let originalShowChristmas {
            UserDefaults.standard.set(originalShowChristmas, forKey: "showChristmasHymns")
        } else {
            UserDefaults.standard.removeObject(forKey: "showChristmasHymns")
        }
        super.tearDown()
    }

    private func makeViewModel(showChristmas: Bool) -> HymnListViewModel {
        UserDefaults.standard.set(showChristmas, forKey: "showChristmasHymns")
        let viewModel = HymnListViewModel()
        viewModel.hymns = [
            hymn(name: "Away In A Manger", collection: "Christmas", text: "Away in a manger"),
            hymn(name: "Amazing Grace", collection: "Hymn", text: "Amazing grace! How sweet the sound"),
        ]
        return viewModel
    }

    private func hymn(name: String, collection: String, text: String) -> Hymn {
        Hymn(name: name, filename: name, author: "", composer: "", text: text, collection: collection)
    }

    func testChristmasHymnsAreHiddenWhenTheSettingIsOff() {
        let viewModel = makeViewModel(showChristmas: false)

        XCTAssertEqual(viewModel.filteredHymns.map(\.name), ["Amazing Grace"])
    }

    func testChristmasHymnsAreShownWhenTheSettingIsOn() {
        let viewModel = makeViewModel(showChristmas: true)

        XCTAssertEqual(viewModel.filteredHymns.count, 2)
    }

    func testSearchMatchesLyricsCaseInsensitively() {
        let viewModel = makeViewModel(showChristmas: true)
        viewModel.searchText = "SWEET THE SOUND"

        XCTAssertEqual(viewModel.filteredHymns.map(\.name), ["Amazing Grace"])
    }

    func testSearchMatchesLyricsIncludingSpaces() {
        let viewModel = makeViewModel(showChristmas: true)
        viewModel.searchText = "in a manger"

        XCTAssertEqual(viewModel.filteredHymns.map(\.name), ["Away In A Manger"])
    }

    /// Search deliberately looks at lyrics only — a title-only match returns nothing.
    func testSearchDoesNotMatchTitlesAlone() {
        let viewModel = makeViewModel(showChristmas: true)
        viewModel.hymns = [hymn(name: "Unique Title", collection: "Hymn", text: "some lyrics")]
        viewModel.searchText = "Unique Title"

        XCTAssertTrue(viewModel.filteredHymns.isEmpty)
    }

    func testChristmasFilterAppliesBeforeSearch() {
        let viewModel = makeViewModel(showChristmas: false)
        viewModel.searchText = "manger"

        XCTAssertTrue(viewModel.filteredHymns.isEmpty)
    }
}
