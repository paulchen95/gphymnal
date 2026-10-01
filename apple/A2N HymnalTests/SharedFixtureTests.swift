//
//  SharedFixtureTests.swift
//  A2N HymnalTests
//
//  Runs the shared behaviour examples in content/fixtures/ against the Apple app's code.
//  The Android app runs the same files, so if the two apps ever disagree about parsing,
//  A-Z grouping, search, hymn links or text size, one of them fails here. When a rule
//  changes, change the fixture and both apps.
//

import XCTest
@testable import A2N_Hymnal

final class SharedFixtureTests: XCTestCase {
    private func fixture(_ name: String) throws -> [String: Any] {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: name, withExtension: "json",
                                                            subdirectory: "fixtures"),
                                "content/fixtures/\(name).json isn't in the test bundle")
        let object = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
        return try XCTUnwrap(object as? [String: Any])
    }

    private func cases(_ fixture: [String: Any], _ key: String = "cases") throws -> [[String: Any]] {
        try XCTUnwrap(fixture[key] as? [[String: Any]])
    }

    func testParsing() throws {
        let list = HymnList(locale: "en-us", searchHighlighting: false)
        for testCase in try cases(fixture("parsing")) {
            let label = testCase["name"] as? String ?? "?"
            let hymn = list.formatHymn(fileContent: try XCTUnwrap(testCase["file"] as? String), fileName: "Test")
            let expect = try XCTUnwrap(testCase["expect"] as? [String: String])
            let actual = ["name": hymn.name, "author": hymn.author, "translator": hymn.translator,
                          "composer": hymn.composer, "arranger": hymn.arranger, "tune": hymn.tune,
                          "collection": hymn.collection, "text": hymn.text]
            for (key, value) in expect {
                XCTAssertEqual(actual[key], value, "\(label): \(key)")
            }
        }
    }

    func testSections() throws {
        UserDefaults.standard.set(true, forKey: "showChristmasHymns")
        for testCase in try cases(fixture("sections")) {
            let label = testCase["name"] as? String ?? "?"
            let viewModel = HymnListViewModel()
            viewModel.hymns = try XCTUnwrap(testCase["names"] as? [String]).map {
                Hymn(name: $0, filename: $0, author: "", composer: "", text: "")
            }
            let expect = try XCTUnwrap(testCase["expect"] as? [[String: Any]])
            XCTAssertEqual(viewModel.sections.map(\.letter), expect.map { $0["letter"] as? String ?? "" }, label)
            XCTAssertEqual(viewModel.sections.map { $0.hymns.map(\.name) },
                           expect.map { $0["names"] as? [String] ?? [] }, label)
        }
    }

    func testSearch() throws {
        UserDefaults.standard.set(true, forKey: "showChristmasHymns")
        let fixture = try fixture("search")
        let viewModel = HymnListViewModel()
        viewModel.hymns = try cases(fixture, "hymns").map {
            Hymn(name: $0["name"] as? String ?? "", filename: $0["name"] as? String ?? "",
                 author: "", composer: "", text: $0["text"] as? String ?? "")
        }
        for testCase in try cases(fixture) {
            let query = try XCTUnwrap(testCase["query"] as? String)
            viewModel.searchText = query
            XCTAssertEqual(viewModel.filteredHymns.map(\.name), testCase["expect"] as? [String], "query \(query)")
        }
    }

    func testLinks() throws {
        let fixture = try fixture("links")
        for testCase in try cases(fixture, "slugs") {
            XCTAssertEqual(HymnLink.slug(forFilename: testCase["filename"] as? String ?? ""),
                           testCase["slug"] as? String)
        }
        for testCase in try cases(fixture, "urls") {
            let url = try XCTUnwrap(URL(string: testCase["url"] as? String ?? ""))
            let link = HymnLink.parse(url)
            XCTAssertEqual(link?.slug, testCase["slug"] as? String, url.absoluteString)
            if let play = testCase["play"] as? Bool {
                XCTAssertEqual(link?.play, play, url.absoluteString)
            }
        }
    }

    func testTextSize() throws {
        let fixture = try fixture("text-size")
        let multipliers = try XCTUnwrap(fixture["multipliers"] as? [Double])
        XCTAssertEqual(LyricsTextSize.multipliers.map(Double.init), multipliers)
        XCTAssertEqual(LyricsTextSize.defaultStep, fixture["default_step"] as? Int)
        XCTAssertEqual(LyricsTextSize.multipliers.indices.map(LyricsTextSize.percent(step:)),
                       fixture["percents"] as? [Int])
        let range = try XCTUnwrap(fixture["point_range"] as? [Double])
        XCTAssertEqual([Double(LyricsTextSize.pointRange.lowerBound), Double(LyricsTextSize.pointRange.upperBound)], range)
    }
}
