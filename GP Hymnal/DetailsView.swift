//
//  DetailsView.swift
//  GP Hymnal
//
//  Created by Paul Chen on 7/29/21.
//

import SwiftUI

struct DetailsView: View {
    let hymn: Hymn
    
    var body: some View {
        ScrollView(/*@START_MENU_TOKEN@*/.vertical/*@END_MENU_TOKEN@*/, showsIndicators: false, content: {
            Text(hymn.name).font(.title3).fontWeight(.heavy).foregroundColor(Color.blue).minimumScaleFactor(0.1)
            Text(hymn.text).padding()
                .contextMenu {
                Button(action: {
                    UIPasteboard.general.string = hymn.text
                }) {
                    Text("Copy to clipboard")
                    Image(systemName: "doc.on.doc")
                }
            }
            Spacer()
            Divider()
            VStack(alignment: .leading) {
                if (hymn.author.count > 0) {
                    Text("Author: " + hymn.author)
                }
                if (hymn.translator.count > 0) {
                    Text("Translator: " + hymn.translator)
                }
                if (hymn.composer.count > 0) {
                    Text("Composer: " + hymn.composer)
                }
            }
        })
    }
}

struct DetailsView_Previews: PreviewProvider {
    static var previews: some View {
        DetailsView(hymn: Hymn(name: "Abide With Me", author: "Henry F. Lyte", translator: "", composer: "William H. Monk", text:
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
