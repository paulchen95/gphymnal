//
//  SettingsView.swift
//  A2N Hymnal
//
//  Created by Paul Chen on 12/5/23.
//

import SwiftUI

struct SettingsView : View {
    @StateObject var globals = Globals()
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // MARK: - Settings
                    GroupBox(
                        label: SettingsLabelView(labelText: "View Options", labelImage: "checklist")
                    ) {
                        Divider().padding(.vertical, 4)
                        Toggle(isOn: $globals.showChristmas, label: {
                            HStack {
                                Text("Show Christmas Hymns")
                                Image(systemName: "snowflake")
                            }
                        })
                        .controlSize(.mini)
                        .padding()
                    }

                    // MARK: - Settings
                    GroupBox(
                        label: SettingsLabelView(labelText: "Language", labelImage: "text.bubble")
                    ) {
                        Divider().padding(.vertical, 4)
                        Picker("Language", selection: $globals.hymnLocale) {
                            ForEach(Array(locales.keys), id: \.self) {
                                Text(locales[$0]!.name)
                            }
                        }
                        .controlSize(.mini)
                        .padding()
                    }

                    // MARK: - Hymnal Info
                    GroupBox(
                        label:
                            SettingsLabelView(labelText: "A2N Hymnal", labelImage: "info.circle")
                    ) {
                        Divider().padding(.vertical, 4)
                        HStack(alignment: .center, spacing: 10) {
                            Image(uiImage: getAppIcon())
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .cornerRadius(10)
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Simple, no-frills hymnal. Good for offline use." +
                                     "  Included music is royalty and copyright-free.")
                            } //: VSTACK
                        } //: HSTACK
                    }

                    // MARK: - App Info
                    GroupBox(
                        label: SettingsLabelView(labelText: "Application", labelImage: "apps.iphone")
                    ) {
                        Divider().padding(.vertical, 4)
                        SettingsRowView(name: "Developer", content: "Cedric Young, Jay Park, Paul Chen")
                        SettingsRowView(name: "Logo Designer", content: "Madison Li")
                        SettingsRowView(name: "App Version", content: getAppInfo(key: "CFBundleShortVersionString"))
                        SettingsRowView(name: "Release", content: getAppInfo(key: "CFBundleVersion"))
                    }
                    

                } //: VSTACK
                .navigationBarTitle(Text("Settings"), displayMode: .large)
                .navigationBarItems(
                    trailing:
                        Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                    }
                )
                .padding()
            } //: SCROLLVIEW
        } //: NAVIGATION
    }
}

func getAppIcon() -> UIImage {
    var appIcon: UIImage! {
        guard let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String:Any],
         let primaryIconsDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? [String:Any],
         let iconFiles = primaryIconsDictionary["CFBundleIconFiles"] as? [String],
         let lastIcon = iconFiles.last else { return nil }
         return UIImage(named: lastIcon)
    }
    return appIcon
}
func getAppInfo(key: String) -> String? {
    if let value = Bundle.main.infoDictionary?[key] as? String {
        return value
    }
    return nil;
}

#Preview {
    SettingsView()
}
