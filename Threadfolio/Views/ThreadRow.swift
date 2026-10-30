//
//  ThreadRow.swift
//  Threadfolio
//
//  Created by Ekaterina on 28.10.2026.
//

import SwiftUI

/// Образец цвета в легенде.
struct ColorSwatch: View {

    let color: CellColor

    var body: some View {
        Circle()
            .fill(color.color)
            .frame(width: 22, height: 22)
            .overlay { Circle().strokeBorder(Color.cardBorder) }
    }
}

/// Строка легенды ниток: образец цвета и число стежков.
struct ThreadRow: View {

    let thread: ThreadUsage

    var body: some View {
        HStack(spacing: 12) {
            ColorSwatch(color: thread.color)
            Text("\(thread.count) stitches")
                .foregroundStyle(Color.ink)
                .monospacedDigit()
        }
    }
}

/// Образцы цветов схемы в один поток, с переносом на новую строку.
struct ColorSwatches: View {

    let colors: [CellColor]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 22), spacing: 10)], alignment: .leading, spacing: 10) {
            ForEach(colors, id: \.self) { ColorSwatch(color: $0) }
        }
    }
}

#if DEBUG
#Preview("Thread Rows") {
    List {
        ThreadRow(thread: ThreadUsage(color: .palette(.pink), count: 124))
        ThreadRow(thread: ThreadUsage(color: .palette(.green), count: 21))
        ColorSwatches(colors: [.palette(.blue), .palette(.beige), .custom(.init(red: 0.6, green: 0.3, blue: 0.8))])
    }
}
#endif
