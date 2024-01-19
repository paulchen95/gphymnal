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
    
    init(name: String, filename: String, author: String, translator: String = "", composer: String, arranger: String = "", tune: String = "", text: String, collection: String = "") {
        self.name = name
        self.filename = filename
        self.author = author
        self.translator = translator
        self.composer = composer
        self.arranger = arranger
        self.tune = tune
        self.text = text
        self.collection = collection.isEmpty ? "Hymn" : collection
    }
    
    func formatText() -> String {
        var formatted = text
        if ((author.count > 0) ||
            (translator.count > 0) ||
            (composer.count > 0) ||
            (arranger.count > 0) ||
            (tune.count > 0)) {
            formatted.append("\n\n")
        }
        if (author.count > 0) {
            formatted.append((locales[globals.hymnLocale]?.author ?? "Author") + ": " + author + "\n")
        }
        if (translator.count > 0) {
            formatted.append((locales[globals.hymnLocale]?.translator ?? "Translator") + ": " + translator + "\n")
        }
        if (composer.count > 0) {
            formatted.append((locales[globals.hymnLocale]?.composer ?? "Composer") + ": " + composer + "\n")
        }
        if (arranger.count > 0) {
            formatted.append((locales[globals.hymnLocale]?.arranger ?? "Arranger") + ": " + arranger + "\n")
        }
        if (tune.count > 0) {
            formatted.append((locales[globals.hymnLocale]?.tune ?? "Tune") + ": " + tune + "\n")
        }
        return formatted
    }
}
