//
//  GridSettingsView.swift
//  KnittingPattern
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftData
import SwiftUI

/// Настройки сетки
struct GridSettingsView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Bindable var draft: PatternDraft
    var onCreate: (Pattern) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                TextField("Chart name", text: $draft.name)
                    .padding(12)
                    .background(.card.opacity(0.6), in: .rect(cornerRadius: 12))
                    .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(.cardBorder) }

                VStack(spacing: 12) {
                    NumberStepperRow(title: "Width (stitch count)", value: $draft.columns)
                    NumberStepperRow(title: "Height (row count)", value: $draft.rows)
                }

                VStack(spacing: 14) {
                    Toggle("Column numbers", isOn: $draft.showColumnNumbers)
                    Toggle("Row numbers", isOn: $draft.showRowNumbers)
                }
                .font(.subheadline)
                .tint(.accent)
                .foregroundStyle(.ink)

                DirectionPicker(
                    title: "Row numbering",
                    selection: $draft.rowDirection,
                    options: [.init(.bottomToTop, "arrow.up", "Bottom to top"), .init(.topToBottom, "arrow.down", "Top to bottom")]
                )
                DirectionPicker(
                    title: "Stitch reading",
                    selection: $draft.columnDirection,
                    options: [.init(.leftToRight, "arrow.right", "Left to right"), .init(.rightToLeft, "arrow.left", "Right to left")]
                )

                if draft.imageData != nil {
                    Toggle(isOn: $draft.sampleImageColors) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Copy colors from photo")
                            Text("Each cell takes the color of the matching part of the photo")
                                .font(.caption)
                                .foregroundStyle(.secondaryText)
                        }
                    }
                    .tint(.accent)
                    .foregroundStyle(.ink)
                }
            }
            .padding(20)
        }
        .background(Color.background)
        .stickyFooter {
            Button("Create") {
                let pattern = draft.makePattern()
                modelContext.insert(pattern)
                onCreate(pattern)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .inlineNavigationTitle("Grid Settings")
    }
}

#if DEBUG
#Preview("Grid Settings") {
    NavigationStack {
        GridSettingsView(draft: PatternDraft()) { _ in }
    }
    .modelContainer(for: Pattern.self, inMemory: true)
}
#endif
