//
//  PatternThumbnail.swift
//  KnittingPattern
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftUI

/// Мини-превью схемы: сетка с символами, а для импортированных фото — само фото.
struct PatternThumbnail: View {
    
    let pattern: Pattern

    var body: some View {
        let cells = pattern.cells
        let hasContent = cells.contains { !$0.isEmpty }
        let image = ImageSupport.image(from: pattern.imageData)

        GeometryReader { proxy in
            if !hasContent, let image {
                image.resizable().scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
            } else {
                let settings = pattern.gridSettings
                let base = ChartLayout(settings: settings, showNumbers: false).totalSize
                let zoom = min(proxy.size.width / base.width, proxy.size.height / base.height) * 0.9
                ChartView(
                    settings: settings, cells: cells,
                    image: pattern.showImage ? image : nil, imageOpacity: pattern.imageOpacity,
                    zoom: zoom, showNumbers: false
                )
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .background(.card)
    }
}

#if DEBUG
#Preview("Миниатюра") {
    HStack {
        PatternThumbnail(pattern: SampleData.heart())
        PatternThumbnail(pattern: SampleData.knitStripes())
    }
    .frame(height: 160)
    .padding()
}
#endif
