//
//  Pattern.swift
//  Threadfolio
//
//  Created by Ekaterina on 26.10.2026.
//

import Foundation
import SwiftUI
import SwiftData

nonisolated enum Craft: String, CaseIterable, Identifiable, Codable {
    
    case crochet, knitting, crossStitch

    var id: String { rawValue }

    var title: String {
        switch self {
        case .crochet: String(localized: "Crochet")
        case .knitting: String(localized: "Knitting")
        case .crossStitch: String(localized: "Cross-stitch")
        }
    }

    /// Значок SF Symbols для карточек и статистики.
    var icon: String {
        switch self {
        case .crochet: "line.diagonal"
        case .knitting: "pause"
        case .crossStitch: "xmark"
        }
    }

    var stitch: StitchID {
        switch self {
        case .crochet: .singleCrochet
        case .knitting: .knit
        case .crossStitch: .fullCross
        }
    }
}

nonisolated enum RowDirection: String, CaseIterable, Identifiable {
    
    /// Ряд 1 снизу, как читают большинство схем.
    case bottomToTop
    /// Ряд 1 сверху.
    case topToBottom

    var id: String { rawValue }
}

nonisolated enum ColumnDirection: String, CaseIterable, Identifiable {
    
    /// Петля 1 справа — схема читается справа налево.
    case rightToLeft
    case leftToRight

    var id: String { rawValue }
}

/// Содержимое одной клетки схемы. Пустые поля не кодируются, поэтому
/// большая пустая сетка занимает мало места.
nonisolated struct Cell: Codable, Equatable, Hashable {
    
    var symbol: StitchID?
    var color: CellColor?
    var background: CellColor?

    static let empty = Self()
    var isEmpty: Bool { symbol == nil && background == nil }

    enum CodingKeys: String, CodingKey {
        
        case symbol = "s", color = "c", background = "b"
    }
}

/// Текущая версия хранилища. При изменении модели заведите `SchemaV2`,
/// перенаправьте на неё оба алиаса и добавьте стадию в `PatternMigrationPlan`.
typealias CurrentSchema = SchemaV1
typealias Pattern = CurrentSchema.Pattern

/// Параметры отрисовки сетки, не зависящие от SwiftData.
struct GridSettings: Equatable {
    
    var columns: Int
    var rows: Int
    var showColumnNumbers: Bool
    var showRowNumbers: Bool
    var rowDirection: RowDirection
    var columnDirection: ColumnDirection

    func rowNumber(forRow row: Int) -> Int {
        rowDirection == .bottomToTop ? rows - row : row + 1
    }

    func columnNumber(forColumn column: Int) -> Int {
        columnDirection == .rightToLeft ? columns - column : column + 1
    }
}
