//
//  SettingsRowView.swift
//  A2N Hymnal
//
//  Created by Paul Chen on 12/5/23.
//

import SwiftUI

struct SettingsRowView: View {
    var name: String
    var content: String? = nil

    var body: some View {
        HStack {
            Text(name).foregroundColor(Color.gray)
            Spacer()
            if (content != nil) {
                Text(content!).font(.footnote)
            } else {
                EmptyView()
            }
        }
    }
}

struct SettingsRowView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsRowView(name: "Developer", content: "John / Jane")
            .previewLayout(.fixed(width: 375, height: 60))
            .padding()
    }
}
