//
//  ThreadUsage.swift
//  Threadfolio
//
//  Created by Ekaterina on 28.10.2026.
//

import SwiftUI

/// Сколько стежков вышито одним цветом нитки — строка легенды ниток.
nonisolated struct ThreadUsage: Identifiable, Equatable {

    let color: CellColor
    let count: Int

    var id: CellColor { color }

    /// Цвета значков в клетках, от самого частого к редкому.
    /// Пустые клетки и заливка фона не считаются: фон — это канва, а не нитка.
    static func count(in cells: [Cell]) -> [Self] {
        var counts: [CellColor: Int] = [:]
        for cell in cells where cell.symbol != nil {
            counts[cell.color ?? .default, default: 0] += 1
        }
        return counts
            .map { Self(color: $0.key, count: $0.value) }
            .sorted { lhs, rhs in
                lhs.count != rhs.count
                    ? lhs.count > rhs.count
                    : lhs.color.sortKey.lexicographicallyPrecedes(rhs.color.sortKey)
            }
    }
}

private extension CellColor {

    /// Стабильный порядок для цветов с одинаковым числом стежков:
    /// сначала палитра по порядку, потом свои цвета.
    nonisolated var sortKey: [Float] {
        switch self {
        case .palette(let palette):
            [Float(PaletteColor.allCases.firstIndex(of: palette) ?? 0)]
        case .custom(let resolved):
            [Float(PaletteColor.allCases.count), resolved.red, resolved.green, resolved.blue]
        }
    }
}
