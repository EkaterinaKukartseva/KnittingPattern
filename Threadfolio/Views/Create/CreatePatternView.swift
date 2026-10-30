//
//  CreatePatternView.swift
//  Threadfolio
//
//  Created by Ekaterina on 27.10.2026.
//

import PhotosUI
import SwiftData
import SwiftUI

/// Источник и тип вязания
struct CreatePatternView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Bindable var draft: PatternDraft
    var onCreate: (Pattern) -> Void

    @State private var photoItem: PhotosPickerItem?
    @State private var isLoadingPhoto = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SelectableCard(isSelected: draft.source == .blank, action: { draft.source = .blank }) {
                    sourceLabel(icon: "squareshape.split.3x3", title: "Blank Grid", subtitle: nil)
                }
                .frame(height: 88)

                PhotosPicker(selection: $photoItem, matching: .images) {
                    sourceLabel(
                        icon: "photo", title: "From Image",
                        subtitle: draft.imageData == nil
                            ? "A photo of a chart becomes the background layer"
                            : "Photo selected — tap to replace"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(draft.source == .image ? .selected : .card, in: .rect(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(draft.source == .image ? .selectedBorder : .cardBorder)
                    }
                }
                .buttonStyle(.plain)
                .frame(height: 88)

                if let image = ImageSupport.image(from: draft.imageData), draft.source == .image {
                    image.resizable().scaledToFit()
                        .frame(maxHeight: 180)
                        .clipShape(.rect(cornerRadius: 12))
                        .frame(maxWidth: .infinity)
                }
                if isLoadingPhoto {
                    ProgressView().frame(maxWidth: .infinity)
                }

                Text("Craft")
                    .font(.headline)
                    .foregroundStyle(.ink)
                    .padding(.top, 12)

                HStack(spacing: 12) {
                    ForEach(Craft.allCases) { craft in
                        SelectableCard(isSelected: draft.craft == craft, action: { draft.craft = craft }) {
                            VStack(spacing: 12) {
                                Image(systemName: craft.icon)
                                    .font(.system(size: 34, weight: .light))
                                    .foregroundStyle(.accentDark)
                                Text(craft.title)
                                    .font(.subheadline)
                                    .foregroundStyle(.ink)
                            }
                        }
                        .frame(height: 110)
                    }
                }
            }
            .padding(20)
        }
        .background(Color.background)
        .stickyFooter {
            NavigationLink("Continue") {
                GridSettingsView(draft: draft, onCreate: onCreate)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .inlineNavigationTitle("Create Chart")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            isLoadingPhoto = true
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    draft.imageData = ImageSupport.compressedData(from: data) ?? data
                    draft.source = .image
                }
                isLoadingPhoto = false
            }
        }
    }

    private func sourceLabel(icon: String, title: LocalizedStringKey, subtitle: LocalizedStringKey?) -> some View {
        HStack(spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.accentDark)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.medium)).foregroundStyle(.ink)
                if let subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(.secondaryText)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

#if DEBUG
#Preview("Source and Craft") {
    NavigationStack {
        CreatePatternView(draft: PatternDraft()) { _ in }
    }
    .modelContainer(for: Pattern.self, inMemory: true)
}

#Preview("Knitting Selected") {
    let draft = PatternDraft()
    draft.craft = .knitting
    return NavigationStack {
        CreatePatternView(draft: draft) { _ in }
    }
    .modelContainer(for: Pattern.self, inMemory: true)
}
#endif
