//
//  HymnListViewModelTests.swift
//  A2N HymnalTests
//
//  Covers the Christmas-collection filter, the lyrics search, and the alphabetical sections
//  in HymnListViewModel.
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

    func testSearchMatchesTitlesAsWellAsLyrics() {
        let viewModel = makeViewModel(showChristmas: true)
        viewModel.hymns = [hymn(name: "Unique Title", collection: "Hymn", text: "some lyrics")]
        viewModel.searchText = "unique title"

        XCTAssertEqual(viewModel.filteredHymns.map(\.name), ["Unique Title"])
    }

    func testChristmasFilterAppliesBeforeSearch() {
        let viewModel = makeViewModel(showChristmas: false)
        viewModel.searchText = "manger"

        XCTAssertTrue(viewModel.filteredHymns.isEmpty)
    }

    // MARK: - Alphabetical sections

    func testSectionsGroupByFirstLetterInOrder() {
        let viewModel = makeViewModel(showChristmas: true)
        viewModel.hymns = ["Be Thou My Vision", "Amazing Grace", "Because He Lives", "Abide With Me"]
            .map { hymn(name: $0, collection: "Hymn", text: "") }

        XCTAssertEqual(viewModel.sections.map(\.letter), ["A", "B"])
        XCTAssertEqual(viewModel.sections.map { $0.hymns.map(\.name) },
                       [["Abide With Me", "Amazing Grace"], ["Be Thou My Vision", "Because He Lives"]])
    }

    func testSectionsPutNonLettersLastUnderHash() {
        let viewModel = makeViewModel(showChristmas: true)
        viewModel.hymns = ["10,000 Reasons", "Zion", "'Tis So Sweet"]
            .map { hymn(name: $0, collection: "Hymn", text: "") }

        XCTAssertEqual(viewModel.sections.map(\.letter), ["T", "Z", "#"])
    }

    func testSectionsFollowSearch() {
        let viewModel = makeViewModel(showChristmas: true)
        viewModel.searchText = "grace"

        XCTAssertEqual(viewModel.sections.map(\.letter), ["A"])
    }

    func testChineseTitlesAreIndexedByPinyin() {
        XCTAssertEqual(hymn(name: "奇异恩典", collection: "Hymn", text: "").indexLetter, "Q")
        XCTAssertEqual(hymn(name: "奇異恩典", collection: "Hymn", text: "").indexLetter, "Q")
    }

    func testAccentedTitlesAreIndexedByBaseLetter() {
        XCTAssertEqual(hymn(name: "Ésaïe", collection: "Hymn", text: "").indexLetter, "E")
    }

    // MARK: - Lyrics text size

    func testTextSizeStepsAreClampedToTheRange() {
        XCTAssertEqual(LyricsTextSize.clamped(-3), 0)
        XCTAssertEqual(LyricsTextSize.clamped(99), LyricsTextSize.multipliers.count - 1)
        XCTAssertEqual(LyricsTextSize.percent(step: LyricsTextSize.defaultStep), 100)
    }

    func testTextSizeStaysWithinPointRangeAndGrowsWithStep() {
        let sizes = LyricsTextSize.multipliers.indices.map(LyricsTextSize.pointSize(step:))
        XCTAssertEqual(sizes, sizes.sorted())
        XCTAssertTrue(sizes.allSatisfy(LyricsTextSize.pointRange.contains))
    }
}
