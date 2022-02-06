//
//  HymnList.swift
//  GP Hymnal
//
//  Created by Jay Park on 2/1/22.


import Foundation

struct HymnList {
    var hymns : [Hymn] = []
    init() {
        if let urls = Bundle.main.urls(forResourcesWithExtension: "txt", subdirectory: "Data") {
            for url in urls {
                if let fileContent = try? String(contentsOf: url) {
                    hymns.insert(
                        formatHymn(fileContent: fileContent), at: 0)
                }
            }
        }
        hymns.sort(by: {$0.name < $1.name})
    }
    
    func formatHymn(fileContent: String) -> Hymn {
        let lines = fileContent.components(separatedBy: "---")

        var nameValue = ""
        var authorValue = ""
        var translatorValue = ""
        var composerValue = ""
        var textValue = ""
        
        for line in lines {
            if doesLineStartWith(line: line, string: "name::") {
                nameValue = getAttributeValueWithoutSpecialChars(line: line)
            } else if doesLineStartWith(line: line, string: "author::") {
                authorValue = getAttributeValueWithoutSpecialChars(line: line)
            } else if doesLineStartWith(line: line, string: "translator::") {
                translatorValue = getAttributeValueWithoutSpecialChars(line: line)
            } else if doesLineStartWith(line: line, string: "composer::") {
                composerValue = getAttributeValueWithoutSpecialChars(line: line)
            } else if doesLineStartWith(line: line, string: "text::") {
                textValue = line.components(separatedBy: "::")[1]
                    .trimmingCharacters(in: .whitespaces)
            }
        }

        return Hymn(name: nameValue, author: authorValue, translator: translatorValue, composer: composerValue, text: textValue)
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

