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

    func testFavorites() throws {
        defer { UserDefaults.standard.set(true, forKey: "showChristmasHymns") }
        for testCase in try cases(fixture("favorites")) {
            let label = testCase["name"] as? String ?? "?"
            UserDefaults.standard.set(testCase["show_christmas"] as? Bool ?? true, forKey: "showChristmasHymns")
            let christmas = Set(testCase["christmas"] as? [String] ?? [])
            let viewModel = HymnListViewModel()
            viewModel.hymns = try XCTUnwrap(testCase["names"] as? [String]).map {
                Hymn(name: $0, filename: $0, author: "", composer: "", text: "",
                     collection: christmas.contains($0) ? "Christmas" : "")
            }
            viewModel.searchText = testCase["query"] as? String ?? ""
            let sections = viewModel.sections(favorites: Set(testCase["favorites"] as? [String] ?? []))
            let expect = try XCTUnwrap(testCase["expect"] as? [[String: Any]])
            XCTAssertEqual(sections.map(\.letter), expect.map { $0["letter"] as? String ?? "" }, label)
            XCTAssertEqual(sections.map { $0.hymns.map(\.name) }, expect.map { $0["names"] as? [String] ?? [] }, label)
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
    func testAnalytics() throws {
        let fixture = try fixture("analytics")
        XCTAssertEqual(Int(Analytics.searchDebounce * 1000), fixture["search_debounce_ms"] as? Int)
        for testCase in try cases(fixture) {
            let name = try XCTUnwrap(testCase["event"] as? String)
            let p = try XCTUnwrap(testCase["properties"] as? [String: Any])
            let string = { (key: String) in p[key] as? String ?? "" }
            let event: AnalyticsEvent
            switch name {
            case "App Opened": event = .appOpened()
            case "Hymn Viewed": event = .hymnViewed(string("hymn"), locale: string("locale"))
            case "Hymn Played": event = .hymnPlayed(string("hymn"), locale: string("locale"))
            case "Hymn Finished": event = .hymnFinished(string("hymn"), locale: string("locale"))
            case "Repeat Toggled": event = .repeatToggled(p["enabled"] as? Bool ?? false)
            case "Hymn Searched":
                event = .hymnSearched(queryLength: p["query_length"] as? Int ?? -1, resultCount: p["result_count"] as? Int ?? -1)
            case "Favorite Added": event = .favoriteAdded(string("hymn"))
            case "Favorite Removed": event = .favoriteRemoved(string("hymn"))
            case "Setting Changed": event = .settingChanged(string("setting"), value: try XCTUnwrap(p["value"] as? AnyHashable))
            default: XCTFail("No builder for analytics event '\(name)'"); continue
            }
            // Compared as JSON, which is what reaches Mixpanel, so true and 1 stay different.
            XCTAssertEqual(event.name, name)
            XCTAssertEqual(try json(event.properties), try json(p), name)
        }
    }

    private func json(_ object: Any) throws -> String {
        String(decoding: try JSONSerialization.data(withJSONObject: object, options: .sortedKeys), as: UTF8.self)
    }
}
