//
//  Locales.swift
//  A2N Hymnal
//
//  Created by Paul Chen on 1/19/24.
//
import Foundation

struct Locale {
    let name: String
    let author: String
    let translator: String
    let composer: String
    let arranger: String
    let tune: String
}

let locales = [
    "en-us": Locale(name: "English", author: "Author", translator: "Translator", composer: "Composer", arranger: "Arranger", tune: "Tune"),
    "zh-cn": Locale(name: "Chinese (Simplified)", author: "作者", translator: "翻译", composer: "作曲家", arranger: "编曲者", tune: "曲调"),
    "zh-tw": Locale(name: "Chinese (Traditional)", author: "作者", translator: "翻譯", composer: "作曲家", arranger: "編曲者", tune: "曲調")
]
