//
//  Settings.swift  
//  A2N Hymnal
//

import SwiftUI
import UIKit

class Settings: ObservableObject {
    @AppStorage("showChristmasHymns") public var showChristmas = true
    @AppStorage("hymnLocale") public var hymnLocale = "en-us"
    @AppStorage("enableSearchHighlighting") public var enableSearchHighlighting = true
    @AppStorage(LyricsTextSize.storageKey) public var lyricsTextSizeStep = LyricsTextSize.defaultStep
    @AppStorage(Appearance.storageKey) public var appearance = Appearance.system.rawValue
}

/// Light or dark, or whatever the system uses (the default). Set in Settings.
enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark

    static let storageKey = "appearance"
    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    /// For `preferredColorScheme`: nil follows the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Hymns the reader has starred, listed in a Favorites section at the top of the hymn list
/// (see `HymnListViewModel.sections(favorites:)`). Kept by filename, so a favourite holds
/// across languages, and saved on this device only.
final class Favorites: ObservableObject {
    static let storageKey = "favoriteHymns"

    @Published private(set) var filenames: Set<String>
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        filenames = Set(defaults.stringArray(forKey: Self.storageKey) ?? [])
    }

    func contains(_ hymn: Hymn) -> Bool { filenames.contains(hymn.filename) }

    func toggle(_ hymn: Hymn) {
        if filenames.contains(hymn.filename) {
            filenames.remove(hymn.filename)
        } else {
            filenames.insert(hymn.filename)
        }
        defaults.set(filenames.sorted(), forKey: Self.storageKey)
    }
}

/// The reader's lyrics size, set from the lyrics page or Settings (one stored value, so the
/// two stay in step). Each step multiplies the system text size, so it also respects the
/// reader's Dynamic Type setting; the result is clamped so the two can't compound into
/// something unusable.
enum LyricsTextSize {
    static let storageKey = "lyricsTextSizeStep"
    static let multipliers: [CGFloat] = [0.85, 1.0, 1.15, 1.3, 1.5, 1.75, 2.0]
    static let defaultStep = 1
    static let pointRange: ClosedRange<CGFloat> = 14...48

    static func clamped(_ step: Int) -> Int {
        min(max(step, 0), multipliers.count - 1)
    }

    static func percent(step: Int) -> Int {
        Int((multipliers[clamped(step)] * 100).rounded())
    }

    /// Point size for `step`: 17pt body, scaled by Dynamic Type, then by the step.
    static func pointSize(step: Int) -> CGFloat {
        let base = UIFontMetrics(forTextStyle: .body).scaledValue(for: 17)
        let size = base * multipliers[clamped(step)]
        return min(max(size, pointRange.lowerBound), pointRange.upperBound)
    }

    /// Extra space between lines, bringing line height to about 1.5 × the text size —
    /// the spacing WCAG recommends for readability, and easier on older eyes.
    static func lineSpacing(step: Int) -> CGFloat {
        pointSize(step: step) * 0.3
    }
}
