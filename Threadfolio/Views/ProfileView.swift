//
//  ProfileView.swift
//  Threadfolio
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftData
import SwiftUI

struct ProfileView: View {
    
    @Query private var patterns: [Pattern]
    @AppStorage(AppTheme.storageKey) private var theme: AppTheme = .system

    var body: some View {
        List {
            Section("Appearance") {
                Picker(selection: $theme) {
                    ForEach(AppTheme.allCases) { Text($0.title).tag($0) }
                } label: {
                    Label("Theme", systemImage: "circle.lefthalf.filled").foregroundStyle(Color.ink)
                }
                .pickerStyle(.menu)
                .tint(Color.secondaryText)
            }
            Section("My Charts") {
                statRow("Total", patterns.count, icon: "square.grid.2x2")
                statRow("Crochet", patterns.filter { $0.craft == .crochet }.count, icon: Craft.crochet.icon)
                statRow("Knitting", patterns.filter { $0.craft == .knitting }.count, icon: Craft.knitting.icon)
                statRow("Cross-stitch", patterns.filter { $0.craft == .crossStitch }.count, icon: Craft.crossStitch.icon)
                statRow("Favorites", patterns.filter(\.isFavorite).count, icon: "heart")
            }
            Section {
                LabeledContent {
                    Text(verbatim: appVersion).monospacedDigit()
                } label: {
                    Label("Version", systemImage: "info.circle").foregroundStyle(Color.ink)
                }
            } footer: {
                Text("Charts are stored on this device and saved automatically after every change.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.background)
        .navigationTitle("Profile")
    }

    /// «1.0 (1)» — версия из App Store и номер сборки.
    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    private func statRow(_ title: LocalizedStringKey, _ value: Int, icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon).foregroundStyle(Color.ink)
            Spacer()
            Text(verbatim: "\(value)").foregroundStyle(Color.secondaryText).monospacedDigit()
        }
    }
}

#if DEBUG
#Preview("Profile") {
    NavigationStack { ProfileView() }
        .modelContainer(SampleData.previewContainer)
}
#endif
