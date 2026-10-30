//
//  PatternExportView.swift
//  Threadfolio
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftData
import SwiftUI

/// То, что уходит в PNG при «Поделиться».
struct PatternExportView: View {
    
    let pattern: Pattern
    let usedStitches: [Stitch]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(pattern.name).font(.system(.title, design: .serif))
                Text(pattern.craft == .crossStitch
                     ? "\(pattern.craft.title) · \(pattern.columns)×\(pattern.rows)"
                     : "\(pattern.craft.title) · \(pattern.columns) stitches × \(pattern.rows) rows")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText)
                if !pattern.summary.isEmpty {
                    Text(pattern.summary).font(.body)
                }
            }
            ChartView(
                settings: pattern.gridSettings, cells: pattern.cells,
                image: pattern.showImage ? ImageSupport.image(from: pattern.imageData) : nil,
                imageOpacity: pattern.imageOpacity
            )
            // Легенда в один столбец: сначала символы, под ними цвета.
            VStack(alignment: .leading, spacing: 8) {
                ForEach(usedStitches) { stitch in
                    HStack(spacing: 8) {
                        StitchGlyph(stitch: stitch)
                            .frame(width: 22, height: 22)
                            .overlay { Rectangle().strokeBorder(Color.gridLine) }
                        Text(stitch.name).font(.callout)
                    }
                }
                ForEach(ThreadUsage.colors(in: pattern.cells), id: \.self) { ColorSwatch(color: $0) }
            }
        }
        .foregroundStyle(Color.ink)
        .padding(24)
        .frame(minWidth: 420, alignment: .leading)
        .background(.white)
        // PNG для отправки всегда светлый, независимо от темы телефона.
        .environment(\.colorScheme, .light)
    }
}

#if DEBUG
#Preview("PNG Export") {
    ScrollView([.horizontal, .vertical]) {
        PatternExportView(pattern: SampleData.heart(), usedStitches: [Stitch.crochet[2]])
    }
}
#endif
