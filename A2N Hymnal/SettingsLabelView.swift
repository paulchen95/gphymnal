//
//  SettingsLabelView.swift
//  A2N Hymnal
//
//  Created by Paul Chen on 12/5/23.
//

import SwiftUI

struct SettingsLabelView: View {
    var labelText: String
    var labelImage: String
    
    var body: some View {
        HStack {
            Text(labelText.uppercased()).fontWeight(.bold)
            Spacer()
            Image(systemName: labelImage)
        }
    }
}

struct SettingsLabelView_Preview: PreviewProvider {
    static var previews: some View {
        SettingsLabelView(labelText: "Sample Label", labelImage: "info.circle")
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
