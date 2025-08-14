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
    
    private let searchText: String
    private var mp3Player: Mp3Player
    private var hymn: Hymn
    var isMp3FileAvailable : Bool
    
    init (hymn: Hymn, searchText: String) {
        self.hymn = hymn
        self.mp3Player = Mp3Player(name: hymn.filename)
        self.searchText = searchText
        self.isMp3FileAvailable = mp3Player.IsFileAvailable()
    }
    
    var body: some View {
        ZoomableScrollView {
            // Apply text highlighting using the highlightedText method
            hymn.formatText(searchedText: searchText)
                .onAppear() {
                }
                .padding(.horizontal)
                .onDisappear(
                    perform: {
                        if (isMp3FileAvailable &&
                           playerState == PlayerState.Playing) {
                            playerState = mp3Player.stop()
                        }// if
                    } // perform
                ) // .onDisappear
                .navigationBarTitle(hymn.name, displayMode: .inline) // have title inline on top
                .textSelection(.enabled)
                .toolbar { // show play/stop button in toolbar
                    if (isMp3FileAvailable) {
                        HStack {
                            if (playerState == PlayerState.Stopped) {
                                Button {
                                    playerState = mp3Player.play()
                                } label: {
                                    Label("Play", systemImage: "play.circle.fill")
                                }
                            } else {
                                Button {
                                    playerState = mp3Player.stop()
                                } label: {
                                    Label("Stop", systemImage: "stop.circle.fill")
                                }
                            }
                        } // HStack
                    } // if mp3Player
                } // .toolbar
        } //  ZoomableScrollView
    } // var body
}

struct DetailsView_Previews: PreviewProvider {
    
    
    static var previews: some View {
        let hymn = Hymn(name: "Abide With Me",
                        filename: "AbideWithMe",
                        author: "Henry F. Lyte",
                        composer: "William H. Monk",
                        text:
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
        """)
        return DetailsView(hymn: hymn, searchText: "")
    }
}
