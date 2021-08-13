//
//  Hymn.swift
//  GP Hymnal
//
//  Created by Paul Chen on 7/29/21.
//

import Foundation

struct Hymn: Identifiable {
    let id = UUID()
    let name: String
    let author: String
    let translator: String
    let composer: String
    let text: String
}
