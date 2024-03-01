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

    init(name: String, filename: String, author: String, translator: String = "", composer: String, arranger: String = "", tune: String = "", text: String, collection: String = "", locale: String = "en-us") {
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
    }
    
    func formatText() -> Text {
        var formatted:Text = formatLyrics()
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
    
    func formatLyrics() -> Text {
        let lines = text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
        var lyrics = Text("")
        var refrainMode:Bool = false
        for line in lines {
            if (line == "[Refrain]") {
                refrainMode = true
            } else if (line == "") {
                refrainMode = false
                lyrics = lyrics + Text("\n")
            } else {
                if (refrainMode) {
                    lyrics = lyrics + Text(line).bold().italic()
                } else {
                    lyrics = lyrics + Text(line)
                }
                lyrics = lyrics + Text("\n")
            }
        }
        return lyrics
    }
}
