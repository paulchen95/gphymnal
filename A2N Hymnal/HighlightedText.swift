//
//  HighlightedText.swift
//  A2N Hymnal
//
//  Created by Jay Park on 4/28/24.
//

import SwiftUI

struct HighlightedText: View {
    let text: String
    let searchText: String
    
    init(text: String, searchText: String) {
        self.text = text
        self.searchText = searchText
    }
    
    var body: some View {
        highlightedText(for: text, searchText: searchText)
    }
    
    private func highlightedText(for text: String, searchText: String) -> Text {
        guard !searchText.isEmpty else {
            return Text(text)
        }

        var highlightedText = Text("")

        // Find all ranges of the search text in the text
        let ranges: [Range<String.Index>] = text.ranges(of: searchText, options: .caseInsensitive)

        // Iterate through each range and construct the highlighted text
        var currentIndex = text.startIndex
        for range in ranges {
            // Append the text before the match
            let beforeRange = currentIndex..<range.lowerBound
            highlightedText = highlightedText + Text(text[beforeRange])

            // Append the match with the highlighting
            let matchRange = range.lowerBound..<range.upperBound
            highlightedText = highlightedText + Text(text[matchRange]).foregroundColor(.red)

            // Move the current index to the end of the match
            currentIndex = range.upperBound
        }

        // Append any remaining text after the last match
        let afterRange = currentIndex..<text.endIndex
        highlightedText = highlightedText + Text(text[afterRange])

        return highlightedText
    }
}

extension String {
    func ranges(of searchString: String, options: String.CompareOptions = []) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var startIndex = self.startIndex
        while let range = self.range(of: searchString, options: options, range: startIndex..<self.endIndex) {
            ranges.append(range)
            startIndex = range.upperBound
        }
        return ranges
    }
}
