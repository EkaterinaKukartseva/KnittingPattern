//
//  ThreadRow.swift
//  Threadfolio
//
//  Created by Ekaterina on 28.10.2026.
//

import SwiftUI

/// Строка легенды ниток: образец цвета, название и число стежков.
struct ThreadRow: View {

    let thread: ThreadUsage

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(thread.color.color)
                .frame(width: 22, height: 22)
                .overlay { Circle().strokeBorder(Color.cardBorder) }
            Text(thread.color.title)
                .foregroundStyle(Color.ink)
            Spacer()
            Text("\(thread.count) stitches")
                .foregroundStyle(Color.secondaryText)
                .monospacedDigit()
        }
    }
}

#if DEBUG
#Preview("Thread Rows") {
    List {
        ThreadRow(thread: ThreadUsage(color: .palette(.pink), count: 124))
        ThreadRow(thread: ThreadUsage(color: .palette(.green), count: 21))
        ThreadRow(thread: ThreadUsage(color: .custom(.init(red: 0.6, green: 0.3, blue: 0.8)), count: 1))
    }
}
#endif
