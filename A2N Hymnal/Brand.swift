//
//  Brand.swift
//  A2N Hymnal
//
//  The Acts2 Network look (acts2.network), adapted for a reading app: warm "paper" and
//  stone colours in place of pure white and black, one gold accent, and Clash Grotesk for
//  large titles only. The colours are in Assets.xcassets (Paper, PaperDeep, Surface, Ink,
//  OnAccent, AccentColor); Xcode generates `Color.paper` and friends from them.
//
//  Clash Grotesk is by the Indian Type Foundry (fontshare.com/terms). It has no Chinese
//  glyphs, so Chinese titles fall back to the system font.
//

import SwiftUI
import UIKit

enum Brand {
    static let titleFontName = "ClashGrotesk-Semibold"

    /// Large navigation titles ("Hymns") in Clash Grotesk. Call once at launch.
    static func applyNavigationBarAppearance() {
        guard let font = UIFont(name: titleFontName, size: 34) else { return }
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: font),
        ]
    }
}

extension Font {
    /// Clash Grotesk at `size`, scaling with Dynamic Type like `style`.
    static func brandTitle(size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        .custom(Brand.titleFontName, size: size, relativeTo: style)
    }
}
