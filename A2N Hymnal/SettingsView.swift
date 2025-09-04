//
//  SettingsView.swift
//  A2N Hymnal
//
//  Created by Paul Chen on 12/5/23.
//

import SwiftUI

struct SettingsView : View {
    @EnvironmentObject var settings: Settings
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: HymnListViewModel

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // MARK: - Show Christmas Hymns
                    GroupBox(
                        label: SettingsLabelView(labelText: "View Options", labelImage: "checklist")
                    ) {
                        Divider().padding(.vertical, 4)
                        Toggle(isOn: settings.$showChristmas, label: {
                            HStack {
                                Text("Show Christmas Hymns")
                                Image(systemName: "snowflake")
                            }
                        })
                        .controlSize(.mini)
                        .padding()
                        .onChange(of: settings.showChristmas) { newValue in
                            viewModel.regenHymnList()
                        }
                        
                        Toggle(isOn: settings.$enableSearchHighlighting, label: {
                            HStack {
                                Text("Enable Search Highlighting")
                                Image(systemName: "highlighter")
                            }
                        })
                        .controlSize(.mini)
                        .padding()
                        .onChange(of: settings.enableSearchHighlighting) { newValue in
                            viewModel.regenHymnList()
                        }
                    }

                    // MARK: - Language Settings
                    GroupBox(
                        label: SettingsLabelView(labelText: "Language (Beta)", labelImage: "text.bubble")
                    ) {
                        Divider().padding(.vertical, 4)
                        Picker("Language", selection: settings.$hymnLocale) {
                            ForEach(Array(locales.keys.sorted(by: { locales[$0]!.name < locales[$1]!.name })), id: \.self) {
                                Text(locales[$0]!.name)
                            }
                        }
                        .controlSize(.mini)
                        .padding()
                        .onChange(of: settings.hymnLocale) { newValue in
                            viewModel.regenHymnList()
                        }
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
    guard let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
          let primaryIconsDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
          let iconFiles = primaryIconsDictionary["CFBundleIconFiles"] as? [String],
          let lastIcon = iconFiles.last,
          let appIcon = UIImage(named: lastIcon) else {
        return UIImage(systemName: "questionmark") ?? UIImage()
    }
    return appIcon
}

func getAppInfo(key: String) -> String? {
    return Bundle.main.infoDictionary?[key] as? String
}

#Preview {
    SettingsView()
        .environmentObject(Settings())
}
