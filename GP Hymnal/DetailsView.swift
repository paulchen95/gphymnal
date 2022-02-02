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
        DetailsView(hymn: Hymn(name: "Test Hymn", author: "Test Author", translator: "Test Translator", composer: "Test Composer", text: "I once was blind but now I see"))
    }
}
