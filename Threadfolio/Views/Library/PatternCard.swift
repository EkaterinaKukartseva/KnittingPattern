//
//  PatternCard.swift
//  Threadfolio
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftData
import SwiftUI

struct PatternCard: View {
    
    @Environment(\.modelContext) private var modelContext
    let pattern: Pattern
    var onRename: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            PatternThumbnail(pattern: pattern)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(.rect(cornerRadius: 12))
                .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(.cardBorder) }
                .overlay(alignment: .topTrailing) { menu }
                .overlay(alignment: .bottomTrailing) {
                    if pattern.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(.accent)
                            .padding(6)
                            .background(Color.background.opacity(0.9), in: .rect(cornerRadius: 6))
                            .padding(6)
                    }
                }

            Text(pattern.name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.ink)
                .lineLimit(1)
            Text("\(pattern.craft.title) · \(pattern.columns)×\(pattern.rows)")
                .font(.caption)
                .foregroundStyle(.secondaryText)
        }
        .contentShape(.rect)
        .contextMenu { menuItems }
    }

    private var menu: some View {
        Menu { menuItems } label: {
            Image(systemName: "ellipsis")
                .font(.caption.weight(.bold))
                .foregroundStyle(.ink)
                .frame(width: 26, height: 22)
                .background(Color.background.opacity(0.92), in: .rect(cornerRadius: 6))
                .padding(6)
        }
    }

    @ViewBuilder private var menuItems: some View {
        Button(action: onRename) {
            Label("Rename", systemImage: "pencil.line")
        }
        Button {
            pattern.isFavorite.toggle()
        } label: {
            Label(pattern.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                  systemImage: pattern.isFavorite ? "heart.slash" : "heart")
        }
        Button {
            modelContext.insert(pattern.duplicate())
        } label: {
            Label("Duplicate", systemImage: "plus.square.on.square")
        }
        Button(role: .destructive, action: onDelete) {
            Label("Delete", systemImage: "trash")
        }
    }
}

#if DEBUG
#Preview("Chart Card") {
    PatternCard(pattern: SampleData.previewPattern, onRename: {}, onDelete: {})
        .frame(width: 180)
        .padding()
        .background(Color.background)
        .modelContainer(SampleData.previewContainer)
}
#endif
