//
//  DetailsView.swift
//  A2N Hymnal
//
//  Created by Paul Chen on 7/29/21.
//

import SwiftUI
import AVKit

struct DetailsView: View {
    @State var playerState: PlayerState = PlayerState.Stopped
    
    let searchText: String
    var mp3Player: Mp3Player?
    var hymn: Hymn
    
    init (hymn: Hymn, searchText: String) {
        self.hymn = hymn
        self.mp3Player = Mp3Player(name: hymn.filename)
        self.searchText = searchText
    }
    
    var body: some View {
        ZoomableScrollView {
            // Apply text highlighting using the highlightedText method
            //            if let formattedText = extractText(from: hymn.formatText()) { <-- need this but not working
            //                highlightedText(for: formattedText) <-- need this but not working
            HighlightedText(text: hymn.text, searchText: searchText) // <-- highlight works but excluding hymn.formatText()
                .padding(.horizontal)
                .onDisappear(
                    perform: {
                        if (mp3Player != nil && mp3Player!.isAvailable() && playerState == PlayerState.Playing) {
                            playerState = mp3Player!.stop()
                        } // if
                    } // perform
                ) // .onDisappear
                .navigationBarTitle(hymn.name, displayMode: .inline) // have title inline on top
                .textSelection(.enabled)
                .toolbar { // show play/stop button in toolbar
                    if (mp3Player != nil && mp3Player!.isAvailable()) {
                        HStack {
                            if (playerState == PlayerState.Stopped) {
                                Button {
                                    playerState = mp3Player!.play()
                                } label: {
                                    Label("Play", systemImage: "play.circle.fill")
                                }
                            } else {
                                Button {
                                    playerState = mp3Player!.stop()
                                } label: {
                                    Label("Stop", systemImage: "stop.circle.fill")
                                }
                            }
                        } // HStack
                    } // if mp3Player
                } // .toolbar
            //            } <-- need this but not working
        } //  ZoomableScrollView
    } // var body
    
    private func extractText(from text: Text) -> String? {
        // Temporary variable to capture the text content
        var extractedText: String?
        
        // Apply the TextFormatter modifier to the Text view
        _ = text.modifier(TextFormatter { string in
            extractedText = string
        })
        
        return extractedText
    }
    
    // Custom modifier to extract string content from Text view
    struct TextFormatter: ViewModifier {
        var onStringExtracted: (String) -> Void
        
        func body(content: Content) -> some View {
            content.onAppear {
                let mirror = Mirror(reflecting: content)
                for child in mirror.children {
                    if let string = child.value as? String {
                        onStringExtracted(string)
                        break
                    }
                }
            }
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
