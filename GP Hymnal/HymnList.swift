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
            if line.replacingOccurrences(of: "\n", with: "").starts(with: "name::") {
                nameValue = line.components(separatedBy: "::")[1].trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "\n", with: "")
            } else if line.replacingOccurrences(of: "\n", with: "").starts(with: "author::") {
                authorValue = line.components(separatedBy: "::")[1].trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "\n", with: "")
            } else if line.replacingOccurrences(of: "\n", with: "").starts(with: "translator::") {
                translatorValue = line.components(separatedBy: "::")[1].trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "\n", with: "")
            } else if line.replacingOccurrences(of: "\n", with: "").starts(with: "composer::") {
                composerValue = line.components(separatedBy: "::")[1].trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "\n", with: "")
            } else if line.replacingOccurrences(of: "\n", with: "").starts(with: "text::") {
                textValue = line.components(separatedBy: "::")[1].trimmingCharacters(in: .whitespaces)
            }
        }

        return Hymn(name: nameValue, author: authorValue, translator: translatorValue, composer: composerValue, text: textValue)
    }
}

