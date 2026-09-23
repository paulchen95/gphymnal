//
//  SectionIndex.swift
//  A2N Hymnal
//
//  The A–Z index down the side of the hymn list, like Contacts. iOS 26 has one built into
//  List; earlier versions get SectionIndexBar, a lookalike you can tap or drag along.
//

import SwiftUI

extension View {
    /// Shows a section index for a List whose sections are tagged with `sectionIndexLetter`.
    func sectionIndex(_ letters: [String], proxy: ScrollViewProxy) -> some View {
        modifier(SectionIndexModifier(letters: letters, proxy: proxy))
    }

    /// Tags a List section with the letter it is listed under in the index.
    func sectionIndexLetter(_ letter: String) -> some View {
        modifier(SectionIndexLetterModifier(letter: letter))
    }
}

private struct SectionIndexModifier: ViewModifier {
    let letters: [String]
    let proxy: ScrollViewProxy

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.listSectionIndexVisibility(letters.count > 1 ? .visible : .hidden)
        } else {
            content.safeAreaInset(edge: .trailing, spacing: 0) {
                if letters.count > 1 {
                    SectionIndexBar(letters: letters) { letter in
                        proxy.scrollTo(letter, anchor: .top)
                    }
                }
            }
        }
    }
}

private struct SectionIndexLetterModifier: ViewModifier {
    let letter: String

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.sectionIndexLabel(letter).id(letter)
        } else {
            content.id(letter)
        }
    }
}

struct SectionIndexBar: View {
    let letters: [String]
    let onSelect: (String) -> Void

    @State private var selected: String?
    private let rowHeight: CGFloat = 16

    var body: some View {
        VStack(spacing: 0) {
            ForEach(letters, id: \.self) { letter in
                Text(letter)
                    .font(.caption2.weight(.semibold))
                    .frame(width: 22, height: rowHeight)
            }
        }
        .foregroundColor(.accentColor)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let row = Int(value.location.y / rowHeight)
                    let letter = letters[min(max(row, 0), letters.count - 1)]
                    guard letter != selected else { return }
                    selected = letter
                    UISelectionFeedbackGenerator().selectionChanged()
                    onSelect(letter)
                }
                .onEnded { _ in selected = nil }
        )
        .frame(maxHeight: .infinity)
        .accessibilityHidden(true)
    }
}
