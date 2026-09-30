//
//  HymnDataTests.swift
//  A2N HymnalTests
//
//  Integrity checks over the hymn text files and audio actually shipped in the app
//  bundle. These are the tests that fail when a new hymn is added with a bad header.
//

import XCTest
@testable import A2N_Hymnal

final class HymnDataTests: XCTestCase {
    private static let attributeKeys = [
        "name", "author", "translator", "composer", "arranger", "tune", "collection", "text",
    ]

    private func hymns(for locale: String) -> [Hymn] {
        HymnList(locale: locale, searchHighlighting: false).build()
    }

    func testEveryLocaleShipsHymns() {
        for locale in locales.keys {
            XCTAssertFalse(hymns(for: locale).isEmpty, "no hymns bundled for \(locale)")
        }
    }

    func testEveryHymnHasANameAndLyrics() {
        for locale in locales.keys {
            for hymn in hymns(for: locale) {
                XCTAssertFalse(hymn.name.isEmpty, "\(locale)/\(hymn.filename) has no name::")
                XCTAssertFalse(hymn.text.isEmpty, "\(locale)/\(hymn.filename) has no text::")
            }
        }
    }

    func testHymnsAreSortedByName() {
        for locale in locales.keys {
            let names = hymns(for: locale).map(\.name)
            XCTAssertEqual(names, names.sorted(), "\(locale) hymns are not sorted")
        }
    }

    func testFilenamesAreUniqueWithinALocale() {
        for locale in locales.keys {
            let filenames = hymns(for: locale).map(\.filename)
            XCTAssertEqual(Set(filenames).count, filenames.count, "duplicate filenames in \(locale)")
        }
    }

    func testCollectionIsAlwaysHymnOrChristmas() {
        for locale in locales.keys {
            for hymn in hymns(for: locale) {
                XCTAssertTrue(["Hymn", "Christmas"].contains(hymn.collection),
                              "\(locale)/\(hymn.filename) has unknown collection:: \(hymn.collection)")
            }
        }
    }

    /// Every translated hymn must reuse an English filename, since audio lookup and
    /// the `music/` folder are keyed off it.
    func testTranslatedHymnsReuseEnglishFilenames() {
        let english = Set(hymns(for: "en-us").map(\.filename))
        for locale in locales.keys where locale != "en-us" {
            for hymn in hymns(for: locale) {
                XCTAssertTrue(english.contains(hymn.filename),
                              "\(locale)/\(hymn.filename) has no en-us counterpart")
            }
        }
    }

    /// A stray `tune:` (one colon) parses as lyrics instead of an attribute and the
    /// credit silently disappears from the details view.
    func testHymnFilesUseDoubleColonAttributes() {
        for locale in locales.keys {
            guard let urls = Bundle.main.urls(forResourcesWithExtension: "txt",
                                              subdirectory: "hymns/" + locale) else {
                return XCTFail("no hymns/\(locale) in the bundle")
            }
            for url in urls {
                guard let content = try? String(contentsOf: url, encoding: .utf8) else {
                    return XCTFail("could not read \(url.lastPathComponent)")
                }
                for line in content.split(whereSeparator: \.isNewline) {
                    for key in Self.attributeKeys where line.hasPrefix(key + ":") {
                        XCTAssertTrue(line.hasPrefix(key + "::"),
                                      "\(locale)/\(url.lastPathComponent): `\(line)` needs a double colon")
                    }
                }
            }
        }
    }

    func testEveryBundledMp3BelongsToAnEnglishHymn() {
        let filenames = Set(hymns(for: "en-us").map(\.filename))
        let mp3s = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: "music") ?? []

        XCTAssertFalse(mp3s.isEmpty, "no audio bundled")
        for mp3 in mp3s {
            let name = mp3.deletingPathExtension().lastPathComponent
            XCTAssertTrue(filenames.contains(name), "music/\(name).mp3 has no matching hymn")
        }
    }

    func testAudioIsLoadableForAHymnThatHasIt() throws {
        let withAudio = try XCTUnwrap(
            hymns(for: "en-us").first { Bundle.main.url(forResource: $0.filename,
                                                        withExtension: "mp3",
                                                        subdirectory: "music") != nil })

        let player = Mp3Player(name: withAudio.filename)
        XCTAssertTrue(player.isAvailable())
        XCTAssertEqual(player.state, .Stopped)
    }

    func testPlayerIsUnavailableForAnUnknownHymn() {
        let player = Mp3Player(name: "NoSuchHymn")

        XCTAssertFalse(player.isAvailable())
        XCTAssertEqual(player.stop(), .Stopped)
    }

    func testEveryLocaleHasLabelStrings() {
        for locale in locales.keys {
            let strings = try? XCTUnwrap(locales[locale])
            XCTAssertNotNil(strings, "no label strings for \(locale)")
        }
    }
}
