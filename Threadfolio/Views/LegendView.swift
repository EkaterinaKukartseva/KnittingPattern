//
//  LegendView.swift
//  Threadfolio
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftUI

/// Справочник условных обозначений для крючка, спиц и вышивки.
struct LegendView: View {
    
    @State private var craft: Craft = .crochet

    var body: some View {
        List {
            Section {
                Picker("Set", selection: $craft) {
                    ForEach(Craft.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            }
            Section {
                ForEach(Stitch.all(for: craft)) { stitch in
                    HStack(spacing: 14) {
                        StitchGlyph(stitch: stitch)
                            .padding(6)
                            .frame(width: 40, height: 40)
                            .background(Color.gridBackground, in: .rect(cornerRadius: 8))
                            .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(Color.cardBorder) }
                        Text(stitch.name).foregroundStyle(Color.ink)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.background)
        .navigationTitle("Symbols")
    }
}

#if DEBUG
#Preview("Legend") {
    NavigationStack { LegendView() }
}
#endif
