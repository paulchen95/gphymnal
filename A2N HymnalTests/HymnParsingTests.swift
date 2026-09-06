//
//  HymnParsingTests.swift
//  A2N HymnalTests
//
//  Covers HymnList's parsing of the `key:: value` / `---` hymn text format.
//

import XCTest
@testable import A2N_Hymnal

final class HymnParsingTests: XCTestCase {
    private let list = HymnList(locale: "en-us", searchHighlighting: false)

    private let fullHymn = """
    name:: Amazing Grace
    ---
    author:: John Newton
    ---
    translator:: Someone
    ---
    composer:: Unknown
    ---
    arranger:: An Arranger
    ---
    tune:: New Britain
    ---
    collection:: Christmas
    ---
    text::
    Amazing grace! How sweet the sound

    [Refrain]
    That saved a wretch like me!
    """

    func testParsesEveryAttribute() {
        let hymn = list.formatHymn(fileContent: fullHymn, fileName: "AmazingGrace")

        XCTAssertEqual(hymn.name, "Amazing Grace")
        XCTAssertEqual(hymn.filename, "AmazingGrace")
        XCTAssertEqual(hymn.author, "John Newton")
        XCTAssertEqual(hymn.translator, "Someone")
        XCTAssertEqual(hymn.composer, "Unknown")
        XCTAssertEqual(hymn.arranger, "An Arranger")
        XCTAssertEqual(hymn.tune, "New Britain")
        XCTAssertEqual(hymn.collection, "Christmas")
        XCTAssertEqual(hymn.locale, "en-us")
    }

    /// Only spaces are trimmed off `text::`, so the newline that follows the key stays
    /// in the lyrics and renders as the leading blank line seen in the details view.
    func testTextKeepsBlankLinesMarkersAndItsLeadingNewline() {
        let hymn = list.formatHymn(fileContent: fullHymn, fileName: "AmazingGrace")

        XCTAssertEqual(hymn.text, """

        Amazing grace! How sweet the sound

        [Refrain]
        That saved a wretch like me!
        """)
    }

    func testOptionalAttributesDefault() {
        let hymn = list.formatHymn(fileContent: """
        name:: Minimal
        ---
        author:: A
        ---
        composer:: B
        ---
        text::
        One line
        """, fileName: "Minimal")

        XCTAssertEqual(hymn.translator, "")
        XCTAssertEqual(hymn.arranger, "")
        XCTAssertEqual(hymn.tune, "")
        // An absent collection falls back to "Hymn" so the Christmas filter can key off it.
        XCTAssertEqual(hymn.collection, "Hymn")
    }

    func testAttributeValuesAreTrimmed() {
        let hymn = list.formatHymn(fileContent: """
        name::    Padded Name
        ---
        author::\tJohn Newton
        ---
        composer:: Unknown
        ---
        text::
        Lyric
        """, fileName: "Padded")

        XCTAssertEqual(hymn.name, "Padded Name")
        XCTAssertEqual(hymn.author, "John Newton")
    }

    /// A single colon is a typo, not a delimiter — it must not be read as an attribute.
    func testSingleColonIsNotAnAttribute() {
        let hymn = list.formatHymn(fileContent: """
        name:: Typo
        ---
        author:: A
        ---
        composer:: B
        ---
        tune: New Britain
        ---
        text::
        Lyric
        """, fileName: "Typo")

        XCTAssertEqual(hymn.tune, "", "`tune:` should be ignored; run the data test to catch it in the bundle")
    }

    func testLocaleIsCarriedOntoParsedHymns() {
        let zh = HymnList(locale: "zh-tw", searchHighlighting: true)
        let hymn = zh.formatHymn(fileContent: """
        name:: 與主同住
        ---
        author:: Henry Francis Lyte
        ---
        composer:: William Henry Monk
        ---
        text::
        日己西沉，求主與我同住﹔
        """, fileName: "AbideWithMe")

        XCTAssertEqual(hymn.locale, "zh-tw")
        XCTAssertEqual(hymn.name, "與主同住")
        XCTAssertTrue(hymn.searchHighlighting)
    }
}
