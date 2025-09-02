//
//  Settings.swift  
//  A2N Hymnal
//

import SwiftUI

class Settings: ObservableObject {
    @AppStorage("showChristmasHymns") public var showChristmas = true
    @AppStorage("hymnLocale") public var hymnLocale = "en-us"
    @AppStorage("enableSearchHighlighting") public var enableSearchHighlighting = true
}
