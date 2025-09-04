//
//  Hymn.swift
//  A2N Hymnal
//
//  Created by Paul Chen on 7/29/21.
//

import SwiftUI

struct Hymn: Identifiable {
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
    }
    
    func formatText(searchedText : String = "") -> Text {
        var formatted:Text = formatLyrics(searchedText: searchedText)
        if ((author.count > 0) ||
            (translator.count > 0) ||
            (composer.count > 0) ||
            (arranger.count > 0) ||
            (tune.count > 0)) {
            formatted = formatted + Text("\n\n")
        }
        if (author.count > 0) {
            formatted = formatted + Text((locales[locale]?.author ?? "Author") + ": " + author + "\n")
        }
        if (translator.count > 0) {
            formatted = formatted + Text((locales[locale]?.translator ?? "Translator") + ": " + translator + "\n")
        }
        if (composer.count > 0) {
            formatted = formatted + Text((locales[locale]?.composer ?? "Composer") + ": " + composer + "\n")
        }
        if (arranger.count > 0) {
            formatted = formatted + Text((locales[locale]?.arranger ?? "Arranger") + ": " + arranger + "\n")
        }
        if (tune.count > 0) {
            formatted = formatted + Text((locales[locale]?.tune ?? "Tune") + ": " + tune + "\n")
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

