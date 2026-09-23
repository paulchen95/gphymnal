//
//  Hymn.swift
//  A2N Hymnal
//
//  Created by Paul Chen on 7/29/21.
//

import SwiftUI

struct Hymn: Identifiable {
    /// Marks Christmas hymns in the list and labels the Christmas setting, so both match.
    static let christmasMarker = "🎄"

    let id = UUID()
    let name: String
    let filename: String
    let author: String
    let translator: String
    let composer: String
    let arranger: String
    let tune: String
    let text: String
    let collection: String
    let locale: String
    let searchHighlighting: Bool
    /// The title in Latin script without accents (pinyin for Chinese), used to order hymns and
    /// file them under an index letter.
    let sortKey: String

    init(name: String, filename: String, author: String, translator: String = "", composer: String, arranger: String = "", tune: String = "", text: String, collection: String = "", locale: String = "en-us", searchHighlighting: Bool = false) {
        self.name = name
        self.filename = filename
        self.author = author
        self.translator = translator
        self.composer = composer
        self.arranger = arranger
        self.tune = tune
        self.text = text
        self.collection = collection.isEmpty ? "Hymn" : collection
        self.locale = locale.isEmpty ? "en-us" : locale
        self.searchHighlighting = searchHighlighting
        self.sortKey = name.applyingTransform(.toLatin, reverse: false)?
            .applyingTransform(.stripDiacritics, reverse: false) ?? name
    }

    /// The letter this hymn is listed under, as in Contacts: leading punctuation is skipped
    /// ("'Tis So Sweet" is under T) and anything that doesn't start with A–Z is under "#".
    var indexLetter: String {
        guard let first = sortKey.first(where: { $0.isLetter || $0.isNumber }),
              let letter = first.uppercased().first,
              ("A"..."Z").contains(letter) else { return "#" }
        return String(letter)
    }

    /// Non-empty credits in display order, with labels in the hymn's language.
    var credits: [(label: String, value: String)] {
        let labels = locales[locale]
        return [
            (labels?.author ?? "Author", author),
            (labels?.translator ?? "Translator", translator),
            (labels?.composer ?? "Composer", composer),
            (labels?.arranger ?? "Arranger", arranger),
            (labels?.tune ?? "Tune", tune),
        ].filter { !$0.1.isEmpty }
    }
    
    /// The opening line of the lyrics, for the Now Playing card.
    var firstLine: String {
        text.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty && $0 != "[Refrain]" && $0 != "[Tag]" } ?? ""
    }

    /// The hymn as plain text for copying and sharing: title, lyrics without the
    /// [Refrain]/[Tag] markers, then the credits.
    var plainText: String {
        let lyrics = text
            .split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
            .filter { $0 != "[Refrain]" && $0 != "[Tag]" }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        var parts = [name, lyrics]
        if !credits.isEmpty {
            parts.append(credits.map { $0.label + ": " + $0.value }.joined(separator: "\n"))
        }
        return parts.joined(separator: "\n\n")
    }

    func formatText(searchedText : String = "") -> Text {
        var formatted:Text = formatLyrics(searchedText: searchedText)
        if !credits.isEmpty {
            formatted = formatted + Text("\n\n")
        }
        for credit in credits {
            formatted = formatted + Text(credit.label + ": " + credit.value + "\n")
        }
        return formatted
    }
    
    func formatLyrics(searchedText : String = "") -> Text {
        let lines = text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
        var lyrics = Text("")
        var refrainMode:Bool = false
        var tagMode:Bool = false
        var formattedLine = Text("")
        for line in lines {
            if (line == "[Refrain]") {
                refrainMode = true
            } else if (line == "[Tag]") {
                tagMode = true
            } else if (line == "") {
                refrainMode = false
                tagMode = false
                lyrics = lyrics + Text("\n")
            } else {
                formattedLine = (!self.searchHighlighting || searchedText.isEmpty) ? Text(line) : highlightSearchedText(content: String(line), textToHighlight: searchedText, highlightColor: .red)
                if (refrainMode) {
                    lyrics = lyrics + formattedLine.bold().italic()
                } else if (tagMode) {
                    lyrics = lyrics + formattedLine.italic()
                } else {
                    lyrics = lyrics + formattedLine
                }
                lyrics = lyrics + Text("\n")
            }
        }
        return lyrics
    }
    
    func highlightSearchedText(content: String, textToHighlight: String, highlightColor: Color) -> Text {
        var highlightedText = Text("")
        
        // Split the content by spaces and newlines.
        let words = content.components(separatedBy: .whitespacesAndNewlines)
        
        // Create a character set of punctuation characters.
        let punctuationCharacterSet = CharacterSet.punctuationCharacters
        
        for word in words {
            // Temporarily remove all punctuations before and after the word before comparison.
            let trimmedWord = word.trimmingCharacters(in: punctuationCharacterSet)
            
            // Get the punctuation characters at the beginning of the word, if any.
            let prefixPunctuation = word.prefix { punctuationCharacterSet.contains($0.unicodeScalars.first!) }
            
            // Get the punctuation characters at the end of the word, if any.
            let suffixPunctuation = word.reversed().prefix { punctuationCharacterSet.contains($0.unicodeScalars.first!) }.reversed()
            
            // Highlight the word (or partial word) if exists.
            if let range = trimmedWord.range(of: textToHighlight, options: .caseInsensitive) {
                let beforeHighlight = trimmedWord[..<range.lowerBound]
                let highlight = trimmedWord[range]
                let afterHighlight = trimmedWord[range.upperBound...]
                
                // Re-stitch punctuation (if any) 
                // + (unhighlighted) pre-trimmed word (if any)
                // + (highlighted) trimmed word
                // + (unhighlighted) post-trimmed word (if any)
                // + punctuation (if any)
                let highlightedPart = Text(String(prefixPunctuation))
                    + Text(beforeHighlight)
                    + Text(String(highlight))
                        .foregroundColor(highlightColor)
                    + Text(String(afterHighlight))
                    + Text(String(suffixPunctuation))
                
                highlightedText = highlightedText + highlightedPart + Text(" ")
            } else {
                highlightedText = highlightedText + Text(word) + Text(" ")
            }
        }
        
        return highlightedText
    }
}

