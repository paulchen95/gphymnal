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
