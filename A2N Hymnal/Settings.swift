//
//  Globals.swift
//  A2N Hymnal
//
//  Created by Admin User on 1/19/24.
//

import SwiftUI

class Settings: ObservableObject {
    @AppStorage("showChristmasHymns") public var showChristmas = true
    @AppStorage("hymnLocale") public var hymnLocale = "en-us"
}
