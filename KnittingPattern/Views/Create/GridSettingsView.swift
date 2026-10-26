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

                section("Cell size") {
                    HStack(spacing: 10) {
                        ForEach(CellSize.allCases) { size in
                            SelectableCard(isSelected: draft.cellSize == size, action: { draft.cellSize = size }) {
                                RoundedRectangle(cornerRadius: 2)
                                    .strokeBorder(.ink.opacity(0.6), lineWidth: 1)
                                    .frame(width: size.points * 0.7, height: size.points * 0.7)
                            }
                            .frame(height: 60)
                        }
                    }
                }

                section("Cell shape") {
                    HStack(spacing: 10) {
                        ForEach(CellShape.allCases) { shape in
                            SelectableCard(isSelected: draft.cellShape == shape, action: { draft.cellShape = shape }) {
                                RoundedRectangle(cornerRadius: 2)
                                    .strokeBorder(.ink.opacity(0.6), lineWidth: 1)
                                    .frame(width: shape == .square ? 18 : 30, height: 18)
                            }
                            .frame(height: 50)
                        }
                    }
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
                    options: [(.bottomToTop, "arrow.up", "Bottom to top"), (.topToBottom, "arrow.down", "Top to bottom")]
                )
                DirectionPicker(
                    title: "Stitch reading",
                    selection: $draft.columnDirection,
                    options: [(.leftToRight, "arrow.right", "Left to right"), (.rightToLeft, "arrow.left", "Right to left")]
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
        .safeAreaInset(edge: .bottom) {
            Button("Create") {
                let pattern = draft.makePattern()
                modelContext.insert(pattern)
                onCreate(pattern)
            }
            .buttonStyle(PrimaryButtonStyle())
            .bottomActionBar()
        }
        .inlineNavigationTitle("Grid Settings")
    }

    private func section(_ title: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.ink)
            content()
        }
    }
}

#if DEBUG
#Preview("Настройки сетки") {
    NavigationStack {
        GridSettingsView(draft: PatternDraft()) { _ in }
    }
    .modelContainer(for: Pattern.self, inMemory: true)
}
#endif
