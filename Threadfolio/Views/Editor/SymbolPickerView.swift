//
//  SymbolPickerView.swift
//  KnittingPattern
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftUI

struct SymbolPickerView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var craft: Craft
    let selected: StitchID
    var onSelect: (StitchID) -> Void

    init(craft: Craft, selected: StitchID, onSelect: @escaping (StitchID) -> Void) {
        _craft = State(initialValue: Stitch.with(id: selected)?.craft ?? craft)
        self.selected = selected
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Set", selection: $craft) {
                        ForEach(Craft.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 12) {
                        ForEach(Stitch.all(for: craft)) { stitch in
                            Button {
                                onSelect(stitch.id)
                                dismiss()
                            } label: {
                                VStack(spacing: 6) {
                                    StitchGlyph(stitch: stitch)
                                        .padding(14)
                                        .frame(maxWidth: .infinity)
                                        .aspectRatio(1, contentMode: .fit)
                                        .background(stitch.id == selected ? Color.selected : Color.card, in: .rect(cornerRadius: 12))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(stitch.id == selected ? Color.selectedBorder : Color.cardBorder)
                                        }
                                    Text(stitch.name)
                                        .font(.caption2)
                                        .foregroundStyle(Color.secondaryText)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2, reservesSpace: true)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(stitch.name)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.background)
            .inlineNavigationTitle("Choose Symbol")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
            }
        }
    }
}

#if DEBUG
#Preview("Crochet") {
    SymbolPickerView(craft: .crochet, selected: .singleCrochet) { _ in }
}

#Preview("Knitting") {
    SymbolPickerView(craft: .knitting, selected: .knit) { _ in }
}
#endif
