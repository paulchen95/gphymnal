//
//  SettingsView.swift
//  A2N Hymnal
//
//  Created by Paul Chen on 12/5/23.
//

import SwiftUI

struct SettingsView : View {
    @EnvironmentObject var settings: Settings
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: HymnListViewModel

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - About
                Section {
                    HStack(spacing: 16) {
                        // A copy of the icon artwork in the asset catalog: the compiled app
                        // icon can't be loaded as an image on the Mac.
                        Image("AppIconImage")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.1)))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("A2N Hymnal")
                                .font(.headline)
                            Text("Version \(getAppInfo(key: "CFBundleShortVersionString") ?? "") (\(getAppInfo(key: "CFBundleVersion") ?? ""))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.surface)
                } footer: {
                    Text("A simple hymnal that works offline. Included music is royalty-free and copyright-free.")
                }

                // MARK: - Language
                Section {
                    Picker(selection: settings.$hymnLocale) {
                        ForEach(Array(locales.keys.sorted(by: { locales[$0]!.name < locales[$1]!.name })), id: \.self) {
                            Text(locales[$0]!.name)
                        }
                    } label: {
                        Label("Language", systemImage: "globe")
                    }
                    .onChange(of: settings.hymnLocale) { newValue in
                        viewModel.regenHymnList()
                    }
                    .listRowBackground(Color.surface)
                } footer: {
                    Text("Chinese translations are in beta.")
                }

                // MARK: - Reading
                Section {
                    HStack {
                        Text("Text Size")
                        Spacer()
                        TextSizeControl(step: settings.$lyricsTextSizeStep)
                            .font(.body)
                    }
                    .listRowBackground(Color.surface)

                    Text("Amazing grace! How sweet the sound\nThat saved a wretch like me!")
                        .font(.system(size: LyricsTextSize.pointSize(step: settings.lyricsTextSizeStep)))
                        .lineSpacing(LyricsTextSize.lineSpacing(step: settings.lyricsTextSizeStep))
                        .foregroundColor(.ink)
                        .padding(.vertical, 6)
                        .listRowBackground(Color.surface)
                        .accessibilityLabel("Preview")
                } header: {
                    Text("Reading")
                }

                // MARK: - Display
                Section {
                    Toggle(isOn: settings.$showChristmas) {
                        Label {
                            Text("Christmas Hymns")
                        } icon: {
                            Text(Hymn.christmasMarker)
                        }
                    }
                    .onChange(of: settings.showChristmas) { newValue in
                        viewModel.regenHymnList()
                    }
                    .listRowBackground(Color.surface)

                    Toggle(isOn: settings.$enableSearchHighlighting) {
                        Label("Highlight Search Matches", systemImage: "highlighter")
                    }
                    .onChange(of: settings.enableSearchHighlighting) { newValue in
                        viewModel.regenHymnList()
                    }
                    .listRowBackground(Color.surface)
                } header: {
                    Text("Display")
                } footer: {
                    Text("When you search, matching words in the lyrics are shown in red.")
                }
            } //: FORM
            .scrollContentBackground(.hidden)
            .background(Color.paper.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        } //: NAVIGATION
    }
}

func getAppInfo(key: String) -> String? {
    return Bundle.main.infoDictionary?[key] as? String
}

#Preview {
    SettingsView()
        .environmentObject(Settings())
        .environmentObject(HymnListViewModel())
}
