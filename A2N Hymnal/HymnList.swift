//
//  HymnList.swift
//  A2N Hymnal
//
//  Created by Jay Park on 2/1/22.


import SwiftUI

struct HymnList {
    private var locale: String

    init(locale: String) {
        self.locale = locale;
    }

    func build() -> [Hymn] {
        var hymns : [Hymn] = []
        if let urls = Bundle.main.urls(forResourcesWithExtension: "txt", subdirectory: "Data/" + locale) {
            for url in urls {
                if let fileContent = try? String(contentsOf: url) {
                    hymns.insert(
                        formatHymn(fileContent: fileContent, fileName: url.deletingPathExtension().lastPathComponent), at: 0)
                }
            }
        }
        hymns.sort(by: {$0.name < $1.name})
        return hymns
    }
    
    func formatHymn(fileContent: String, fileName: String) -> Hymn {
        let lines = fileContent.components(separatedBy: "---")

        var nameValue = ""
        var authorValue = ""
        var translatorValue = ""
        var composerValue = ""
        var arrangerValue = ""
        var tuneValue = ""
        var textValue = ""
        var collectionValue = ""

        for line in lines {
            if doesLineStartWith(line: line, string: "name::") {
                nameValue = getAttributeValueWithoutSpecialChars(line: line)
            } else if doesLineStartWith(line: line, string: "author::") {
                authorValue = getAttributeValueWithoutSpecialChars(line: line)
            } else if doesLineStartWith(line: line, string: "translator::") {
                translatorValue = getAttributeValueWithoutSpecialChars(line: line)
            } else if doesLineStartWith(line: line, string: "composer::") {
                composerValue = getAttributeValueWithoutSpecialChars(line: line)
            } else if doesLineStartWith(line: line, string: "arranger::") {
                arrangerValue = getAttributeValueWithoutSpecialChars(line: line)
            } else if doesLineStartWith(line: line, string: "tune::") {
                tuneValue = getAttributeValueWithoutSpecialChars(line: line)
            } else if doesLineStartWith(line: line, string: "collection::") {
                collectionValue = getAttributeValueWithoutSpecialChars(line: line)
            } else if doesLineStartWith(line: line, string: "text::") {
                textValue = line.components(separatedBy: "::")[1]
                    .trimmingCharacters(in: .whitespaces)
            }
        }

        return Hymn(name: nameValue, filename: fileName, author: authorValue,
                    translator: translatorValue, composer: composerValue, arranger: arrangerValue, tune: tuneValue, text: textValue, collection: collectionValue, locale: locale)
    }
    
    func doesLineStartWith(line: String, string: String) -> Bool {
        line.replacingOccurrences(of: "\n", with: "").starts(with: string)
    }
    
    // Get the attribute without special characters, such as "\n" or leading/trailing spaces.
    func getAttributeValueWithoutSpecialChars(line: String) -> String {
        line.components(separatedBy: "::")[1]
            .replacingOccurrences(of: "\n", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
}
