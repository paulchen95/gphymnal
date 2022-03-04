//
//  DetailsView.swift
//  GP Hymnal
//
//  Created by Paul Chen on 7/29/21.
//

import SwiftUI
import AVKit

enum AudioPlayerState {
    case Playing, Stopped
}

struct DetailsView: View {
    @State var playerState: PlayerState = PlayerState.Stopped
    var midiPlayer: MidiPlayer?
    var hymn: Hymn

    init (hymn: Hymn) {
        self.hymn = hymn
        self.midiPlayer = MidiPlayer(name: hymn.filename)
    }
    
    var body: some View {
        MyUITextView(hymn: hymn)
            .padding(.horizontal)
            .onDisappear(
                perform: {
                    if (midiPlayer != nil && midiPlayer!.isAvailable() && playerState == PlayerState.Playing) {
                        playerState = midiPlayer!.stop()
                    }
                }
            )
            .navigationBarTitle(hymn.name, displayMode: .inline) // have title inline on top
            .toolbar { // show play/stop button in toolbar
                if (midiPlayer != nil && midiPlayer!.isAvailable()) {
                    HStack {
                        if (playerState == PlayerState.Stopped) {
                            Button {
                                playerState = midiPlayer!.play()
                            } label: {
                                Label("Play", systemImage: "play.circle.fill")
                            }
                        } else {
                            Button {
                                playerState = midiPlayer!.stop()
                            } label: {
                                Label("Stop", systemImage: "stop.circle.fill")
                            }
                        }
                    }
                }
            }
    }
}

struct DetailsView_Previews: PreviewProvider {
    static var previews: some View {
        DetailsView(hymn: Hymn(name: "Abide With Me", filename: "AbideWithMe", author: "Henry F. Lyte", translator: "", composer: "William H. Monk", text:
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
        """))
    }
}
