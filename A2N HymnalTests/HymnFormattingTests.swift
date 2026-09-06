//
//  HymnFormattingTests.swift
//  A2N HymnalTests
//
//  Covers Hymn's rendering of lyrics, the metadata footer, and search highlighting.
//
//  SwiftUI.Text is Equatable and compares structurally, so expected values are built
//  the same way the code under test builds them. Two things matter when doing that:
//    * Hymn feeds runtime strings into Text, which selects the verbatim initializer.
//      Expected values must therefore use `Text(verbatim:)`; a `Text("literal")` is a
//      LocalizedStringKey and never compares equal to it, even when it renders the same.
//    * Both `formatLyrics` and `highlightSearchedText` seed their result with an empty
//      `Text("")`, which is part of the tree and so part of the expected value.
//

import SwiftUI
import XCTest
@testable import A2N_Hymnal

final class HymnFormattingTests: XCTestCase {
    private func makeHymn(text: String,
                          author: String = "",
                          translator: String = "",
                          composer: String = "",
                          arranger: String = "",
                          tune: String = "",
                          locale: String = "en-us",
                          searchHighlighting: Bool = false) -> Hymn {
        Hymn(name: "Test", filename: "Test", author: author, translator: translator,
             composer: composer, arranger: arranger, tune: tune, text: text,
             locale: locale, searchHighlighting: searchHighlighting)
    }

    // MARK: - Lyrics

    func testPlainStanzaLinesAreUnstyled() {
        let hymn = makeHymn(text: "Line one\nLine two")

        XCTAssertEqual(hymn.formatLyrics(),
                       Text("") + Text(verbatim: "Line one") + Text("\n")
                       + Text(verbatim: "Line two") + Text("\n"))
    }

    func testRefrainIsBoldItalicUntilBlankLine() {
        let hymn = makeHymn(text: "[Refrain]\nSaved\n\nAfter")

        XCTAssertEqual(hymn.formatLyrics(),
                       Text("") + Text(verbatim: "Saved").bold().italic() + Text("\n")
                       + Text("\n")
                       + Text(verbatim: "After") + Text("\n"))
    }

    func testTagIsItalicUntilBlankLine() {
        let hymn = makeHymn(text: "[Tag]\nTagged\n\nAfter")

        XCTAssertEqual(hymn.formatLyrics(),
                       Text("") + Text(verbatim: "Tagged").italic() + Text("\n")
                       + Text("\n")
                       + Text(verbatim: "After") + Text("\n"))
    }

    /// The `[Refrain]` / `[Tag]` markers control styling and are never rendered.
    func testMarkersAreNotRendered() {
        let hymn = makeHymn(text: "[Refrain]\nSaved")

        XCTAssertFalse(String(describing: hymn.formatLyrics()).contains("[Refrain]"))
    }

    // MARK: - Metadata footer

    func testNoMetadataFooterWhenAllCreditsAreEmpty() {
        let hymn = makeHymn(text: "Line one")

        XCTAssertEqual(hymn.formatText(), hymn.formatLyrics())
    }

    func testMetadataFooterUsesLocalizedLabels() {
        let hymn = makeHymn(text: "Line one", author: "John Newton", locale: "zh-tw")

        XCTAssertEqual(hymn.formatText(),
                       hymn.formatLyrics() + Text("\n\n") + Text(verbatim: "作者: John Newton\n"))
    }

    func testMetadataFooterOrder() {
        let hymn = makeHymn(text: "L", author: "A", translator: "T", composer: "C",
                            arranger: "R", tune: "N")

        XCTAssertEqual(hymn.formatText(),
                       hymn.formatLyrics() + Text("\n\n")
                       + Text(verbatim: "Author: A\n")
                       + Text(verbatim: "Translator: T\n")
                       + Text(verbatim: "Composer: C\n")
                       + Text(verbatim: "Arranger: R\n")
                       + Text(verbatim: "Tune: N\n"))
    }

    func testMetadataFooterSkipsEmptyCredits() {
        let hymn = makeHymn(text: "L", composer: "C")

        XCTAssertEqual(hymn.formatText(),
                       hymn.formatLyrics() + Text("\n\n") + Text(verbatim: "Composer: C\n"))
    }

    // MARK: - Search highlighting

    func testHighlightingIsSkippedWhenDisabled() {
        let hymn = makeHymn(text: "Amazing grace", searchHighlighting: false)

        XCTAssertEqual(hymn.formatLyrics(searchedText: "grace"),
                       Text("") + Text(verbatim: "Amazing grace") + Text("\n"))
    }

    func testHighlightingIsSkippedForAnEmptySearch() {
        let hymn = makeHymn(text: "Amazing grace", searchHighlighting: true)

        XCTAssertEqual(hymn.formatLyrics(searchedText: ""),
                       Text("") + Text(verbatim: "Amazing grace") + Text("\n"))
    }

    func testHighlightLeavesNonMatchingWordsAlone() {
        let hymn = makeHymn(text: "x", searchHighlighting: true)

        XCTAssertEqual(hymn.highlightSearchedText(content: "Amazing",
                                                  textToHighlight: "zzz",
                                                  highlightColor: .red),
                       Text("") + Text(verbatim: "Amazing") + Text(" "))
    }

    /// Punctuation is peeled off before matching, then re-stitched around the match.
    func testHighlightMatchesCaseInsensitivelyAndKeepsPunctuation() {
        let hymn = makeHymn(text: "x", searchHighlighting: true)

        XCTAssertEqual(hymn.highlightSearchedText(content: "(Grace!)",
                                                  textToHighlight: "grace",
                                                  highlightColor: .red),
                       Text("")
                       + (Text(verbatim: "(") + Text(verbatim: "")
                          + Text(verbatim: "Grace").foregroundColor(.red)
                          + Text(verbatim: "") + Text(verbatim: "!)"))
                       + Text(" "))
    }

    func testHighlightMatchesInsideAWord() {
        let hymn = makeHymn(text: "x", searchHighlighting: true)

        XCTAssertEqual(hymn.highlightSearchedText(content: "wretch",
                                                  textToHighlight: "ret",
                                                  highlightColor: .red),
                       Text("")
                       + (Text(verbatim: "") + Text(verbatim: "w")
                          + Text(verbatim: "ret").foregroundColor(.red)
                          + Text(verbatim: "ch") + Text(verbatim: ""))
                       + Text(" "))
    }

    /// Highlighting rebuilds the line word by word, so words end up space-separated
    /// regardless of the original run of whitespace.
    func testHighlightRendersWordsSeparatedBySpaces() {
        let hymn = makeHymn(text: "x", searchHighlighting: true)

        XCTAssertEqual(hymn.highlightSearchedText(content: "a  b",
                                                  textToHighlight: "zzz",
                                                  highlightColor: .red),
                       Text("") + Text(verbatim: "a") + Text(" ")
                       + Text(verbatim: "") + Text(" ")
                       + Text(verbatim: "b") + Text(" "))
    }
}
