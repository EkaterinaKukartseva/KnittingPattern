//
//  EditorSettingsView.swift
//  KnittingPattern
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftUI
import SwiftData

/// Настройки сетки уже созданной схемы: размер, клетки, нумерация, фото.
struct EditorSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var pattern: Pattern
    @State var settings: GridSettings
    var onApply: (GridSettings) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NumberStepperRow(title: "Width (stitches)", value: $settings.columns)
                    NumberStepperRow(title: "Height (rows)", value: $settings.rows)
                } header: {
                    Text("Size")
                } footer: {
                    Text("Shrinking trims the outer stitches and rows. Undo history will be reset.")
                }

                Section("Cells") {
                    Picker("Size", selection: $settings.cellSize) {
                        Text("Small").tag(CellSize.small)
                        Text("Medium").tag(CellSize.medium)
                        Text("Large").tag(CellSize.large)
                    }
                    Picker("Shape", selection: $settings.cellShape) {
                        Text("Square").tag(CellShape.square)
                        Text("Rectangle").tag(CellShape.wide)
                    }
                }

                Section("Numbering and Reading") {
                    Toggle("Column numbers", isOn: $settings.showColumnNumbers)
                    Toggle("Row numbers", isOn: $settings.showRowNumbers)
                    Picker("Row 1", selection: $settings.rowDirection) {
                        Text("Bottom").tag(RowDirection.bottomToTop)
                        Text("Top").tag(RowDirection.topToBottom)
                    }
                    Picker("Stitch 1", selection: $settings.columnDirection) {
                        Text("Left").tag(ColumnDirection.leftToRight)
                        Text("Right").tag(ColumnDirection.rightToLeft)
                    }
                }

                if pattern.imageData != nil {
                    Section("Background Photo") {
                        Toggle("Show photo", isOn: $pattern.showImage)
                        VStack(alignment: .leading) {
                            Text("Opacity")
                            Slider(value: $pattern.imageOpacity, in: 0.1...1)
                        }
                    }
                }
            }
            .tint(Color.accent)
            .scrollContentBackground(.hidden)
            .background(Color.background)
            .inlineNavigationTitle("Grid Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onApply(settings)
                        dismiss()
                    }
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    let pattern = SampleData.previewPattern
    EditorSettingsView(pattern: pattern, settings: pattern.gridSettings) { _ in }
        .modelContainer(SampleData.previewContainer)
}
#endif
