//
//  DetailsView.swift
//  A2N Hymnal
//
//  Created by Paul Chen on 7/29/21.
//

import SwiftUI
import AVKit

struct DetailsView: View {
    
    let searchText: String
    @State private var copied = false
    @State private var showTextSize = false
    @EnvironmentObject private var favorites: Favorites
    @AppStorage(LyricsTextSize.storageKey) private var textSizeStep = LyricsTextSize.defaultStep
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var hymn: Hymn
    
    init (hymn: Hymn, searchText: String) {
        self.hymn = hymn
        self.searchText = searchText
    }
    
    private static let topFade: CGFloat = 24
    private static let bottomFade: CGFloat = 64

    var body: some View {
        ZoomableScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(hymn.name)
                    .font(.brandTitle(size: 34, relativeTo: .largeTitle))
                    .fixedSize(horizontal: false, vertical: true)

                LyricsTextView(hymn: hymn, searchText: searchText,
                               pointSize: LyricsTextSize.pointSize(step: textSizeStep))

                if !hymn.credits.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(hymn.credits, id: \.label) { credit in
                            Text(credit.label + ": ").fontWeight(.semibold) + Text(credit.value)
                        }
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.ink)
            // On iPad, a wider margin (clear of the sidebar in the split layout) and a
            // comfortable reading measure rather than lines running the full width.
            .frame(maxWidth: horizontalSizeClass == .regular ? 640 : .infinity, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, horizontalSizeClass == .regular ? 56 : 24)
            // Room to clear the edge fades: the title starts below the top one, and the end
            // of the credits can scroll above the bottom one and the player.
            .padding(.top, Self.topFade + 4)
            .padding(.bottom, Self.bottomFade)
            .textSelection(.enabled)
        } //  ZoomableScrollView
        // The scroll view draws past its edges (for zooming); clip it here so lyrics never
        // show up under the top bar or below the player, only through the fades.
        .clipped()
        // Lyrics fade out as they scroll toward the top bar and under the player, like the
        // hymn list does under its bars, so the eye stays on the middle of the page. The
        // bottom fade reaches down under the player (it's pinned by the parent view).
        .overlay(alignment: .top) {
            LinearGradient(colors: [Color.paper, Color.paper.opacity(0)],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: Self.topFade)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .bottom) {
            LinearGradient(stops: [
                .init(color: Color.paper.opacity(0), location: 0),
                .init(color: Color.paper.opacity(0.8), location: 0.45),
                .init(color: Color.paper.opacity(0.95), location: 1),
            ], startPoint: .top, endPoint: .bottom)
                .frame(height: Self.bottomFade)
                .allowsHitTesting(false)
        }
        .background(Color.paper.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline) // the title is in the content, above the lyrics
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    favorites.toggle(hymn)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Label(favorites.contains(hymn) ? "Remove from Favorites" : "Add to Favorites",
                          systemImage: favorites.contains(hymn) ? "star.fill" : "star")
                }
                .plainToolbarButton()
                .help(favorites.contains(hymn) ? "Remove from Favorites" : "Add to Favorites")
                Button {
                    showTextSize = true
                } label: {
                    Label("Text Size", systemImage: "textformat.size")
                }
                .plainToolbarButton()
                .popover(isPresented: $showTextSize) {
                    TextSizeControl(step: $textSizeStep)
                        .padding()
                        .compactPopover()
                }
                Button {
                    UIPasteboard.general.string = hymn.plainText
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
                } label: {
                    Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                }
                .plainToolbarButton()
                if HymnLink.isSharingEnabled {
                    ShareLink(item: hymn.plainText, subject: Text(hymn.name)) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
    } // var body
}

/// The lyrics, set like a printed hymnal so each sung line stays distinct at any size:
/// a line that wraps continues with a hanging indent, wrapped lines sit close together, and
/// separate lines get a clear gap. SwiftUI's Text can't do hanging indents, so this is a
/// non-editable, selectable UITextView. [Refrain] lines are bold italic and [Tag] lines
/// italic until the next blank line, as in `Hymn.formatLyrics`; search matches are red.
struct LyricsTextView: UIViewRepresentable {
    let hymn: Hymn
    let searchText: String
    let pointSize: CGFloat

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isEditable = false
        view.isSelectable = true
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        view.attributedText = attributedLyrics()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? UIScreen.main.bounds.width
        let size = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: ceil(size.height))
    }

    private func attributedLyrics() -> NSAttributedString {
        let regular = UIFont.systemFont(ofSize: pointSize)
        let paragraph = NSMutableParagraphStyle()
        paragraph.firstLineHeadIndent = 0
        paragraph.headIndent = pointSize * 1.2       // hanging indent for wrapped continuations
        paragraph.lineSpacing = pointSize * 0.12     // tight within a wrapped line
        paragraph.paragraphSpacing = pointSize * 0.45 // clear gap between sung lines

        let result = NSMutableAttributedString()
        var refrain = false, tag = false
        let lines = hymn.text
            .split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
            .map(String.init)
            .drop { $0.trimmingCharacters(in: .whitespaces).isEmpty }
        for line in lines {
            if line == "[Refrain]" { refrain = true; continue }
            if line == "[Tag]" { tag = true; continue }
            if line.isEmpty { refrain = false; tag = false }
            var font = regular
            if refrain || tag {
                var traits: UIFontDescriptor.SymbolicTraits = .traitItalic
                if refrain { traits.insert(.traitBold) }
                if let descriptor = regular.fontDescriptor.withSymbolicTraits(traits) {
                    font = UIFont(descriptor: descriptor, size: pointSize)
                }
            }
            result.append(NSAttributedString(string: line + "\n", attributes: [
                .font: font,
                .foregroundColor: UIColor(named: "Ink") ?? .label,
                .paragraphStyle: paragraph,
            ]))
        }
        // Trailing blank lines would only add space before the credits.
        while result.string.hasSuffix("\n") {
            result.deleteCharacters(in: NSRange(location: result.length - 1, length: 1))
        }
        highlightMatches(in: result)
        return result
    }

    private func highlightMatches(in text: NSMutableAttributedString) {
        guard hymn.searchHighlighting, !searchText.isEmpty else { return }
        let string = text.string as NSString
        var range = NSRange(location: 0, length: string.length)
        while true {
            let match = string.range(of: searchText, options: [.caseInsensitive, .diacriticInsensitive], range: range)
            guard match.location != NSNotFound else { break }
            text.addAttribute(.foregroundColor, value: UIColor.systemRed, range: match)
            let next = match.location + match.length
            range = NSRange(location: next, length: string.length - next)
        }
    }
}

/// Smaller / current size / larger, as in Apple Books. Used on the lyrics page and in
/// Settings, which share one stored value.
struct TextSizeControl: View {
    @Binding var step: Int

    var body: some View {
        HStack(spacing: 20) {
            Button {
                step = LyricsTextSize.clamped(step - 1)
            } label: {
                Label("Smaller Text", systemImage: "textformat.size.smaller")
                    .frame(width: 44, height: 44)
            }
            .disabled(step <= 0)

            Text("\(LyricsTextSize.percent(step: step))%")
                .font(.body.monospacedDigit().weight(.semibold))
                .frame(minWidth: 56)
                .accessibilityHidden(true)

            Button {
                step = LyricsTextSize.clamped(step + 1)
            } label: {
                Label("Larger Text", systemImage: "textformat.size.larger")
                    .frame(width: 44, height: 44)
            }
            .disabled(step >= LyricsTextSize.multipliers.count - 1)
        }
        .labelStyle(.iconOnly)
        .font(.title2)
        .buttonStyle(.borderless)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Lyrics Text Size, \(LyricsTextSize.percent(step: step)) percent")
    }
}

private extension View {
    /// Keeps the popover a popover on iPhone instead of turning into a sheet.
    @ViewBuilder
    func compactPopover() -> some View {
        if #available(iOS 16.4, *) {
            presentationCompactAdaptation(.popover)
        } else {
            self
        }
    }
}

struct DetailsView_Previews: PreviewProvider {
    static var previews: some View {
        DetailsView(hymn: Hymn(name: "Abide With Me", filename: "AbideWithMe", author: "Henry F. Lyte", composer: "William H. Monk", text:
        """
        Abide with me, fast falls the eventide;
        The darkness deepens, Lord, with me abide.
        When other helpers fail and comforts flee,
        Help of the helpless, O, abide with me!
        
        Swift to its close ebbs out life’s little day;
        Earth’s joys grow dim, its glories pass away;
        Change and decay in all around I see;
        O Thou who changest not, abide with me!
        
        I need Thy presence ev’ry passing hour;
        What but Thy grace can foil the tempter’s pow’r?
        Who like Thyself my guide and stay can be?
        Through cloud and sunshine, O abide with me!
        
        I fear no foe with Thee at hand to bless,
        Though ills have weight and tears their bitterness
        Where is death’s sting? Where grave, Thy victory?
        I triumph still, if Thou abide with me.
        
        Hold Thou Thy cross before my closing eyes;
        Shine through the gloom, and point me to the skies;
        Heaven’s morning breaks and earth’s vain shadows flee;
        In life, in death, O Lord, abide with me!
        """), searchText: "")
    }
}
