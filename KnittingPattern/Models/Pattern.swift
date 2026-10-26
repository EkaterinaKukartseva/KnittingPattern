//
//  Pattern.swift
//  KnittingPattern
//
//  Created by Ekaterina on 26.10.2026.
//

import Foundation
import SwiftUI
import SwiftData

enum Craft: String, CaseIterable, Identifiable, Codable {
    
    case crochet, knitting

    var id: String { rawValue }

    var title: String {
        switch self {
        case .crochet: String(localized: "Crochet")
        case .knitting: String(localized: "Knitting")
        }
    }

    var stitch: StitchID {
        switch self {
        case .crochet: .singleCrochet
        case .knitting: .knit
        }
    }
}

enum CellSize: String, CaseIterable, Identifiable {
    
    case small, medium, large

    var id: String { rawValue }

    var points: CGFloat {
        switch self {
        case .small: 18
        case .medium: 24
        case .large: 32
        }
    }
}

enum CellShape: String, CaseIterable, Identifiable {
    
    /// Квадратная клетка — типично для крючка и вышивки.
    case square
    /// Прямоугольная (шире, чем выше) — пропорции вязаной лицевой петли.
    case wide

    var id: String { rawValue }
    var heightRatio: CGFloat { self == .square ? 1 : 0.75 }
}

enum RowDirection: String, CaseIterable, Identifiable {
    
    /// Ряд 1 снизу, как читают большинство схем.
    case bottomToTop
    /// Ряд 1 сверху.
    case topToBottom

    var id: String { rawValue }
}

enum ColumnDirection: String, CaseIterable, Identifiable {
    
    /// Петля 1 справа — схема читается справа налево.
    case rightToLeft
    case leftToRight

    var id: String { rawValue }
}

/// Содержимое одной клетки схемы. Пустые поля не кодируются, поэтому
/// большая пустая сетка занимает мало места.
struct Cell: Codable, Equatable, Hashable {
    
    var symbol: StitchID?
    var color: CellColor?
    var background: CellColor?

    static let empty = Cell()
    var isEmpty: Bool { symbol == nil && background == nil }

    enum CodingKeys: String, CodingKey {
        case symbol = "s", color = "c", background = "b"
    }
}

@Model
final class Pattern {
    
    var name: String
    /// Описание схемы (что это, пряжа, инструмент).
    var summary: String
    var notes: String
    var craftRaw: String
    var columns: Int
    var rows: Int
    var cellSizeRaw: String
    var cellShapeRaw: String
    var showColumnNumbers: Bool
    var showRowNumbers: Bool
    var rowDirectionRaw: String
    var columnDirectionRaw: String
    var cellsData: Data
    /// Фото готовой схемы — показывается подложкой под сеткой.
    @Attribute(.externalStorage) var imageData: Data?
    var showImage: Bool
    var imageOpacity: Double
    var isFavorite: Bool
    /// Дополнительные цвета, добавленные пользователем (JSON-массив `Color.Resolved`).
    var customColorsData: Data = Data()
    var createdAt: Date
    var updatedAt: Date
    
    init(name: String,
         craft: Craft,
         columns: Int,
         rows: Int,
         cellSize: CellSize = .medium,
         cellShape: CellShape = .square,
         showColumnNumbers: Bool = true,
         showRowNumbers: Bool = true,
         rowDirection: RowDirection = .bottomToTop,
         columnDirection: ColumnDirection = .leftToRight,
         imageData: Data? = nil,
         cells: [Cell]? = nil) {
        self.name = name
        self.summary = ""
        self.notes = ""
        self.craftRaw = craft.rawValue
        self.columns = columns
        self.rows = rows
        self.cellSizeRaw = cellSize.rawValue
        self.cellShapeRaw = cellShape.rawValue
        self.showColumnNumbers = showColumnNumbers
        self.showRowNumbers = showRowNumbers
        self.rowDirectionRaw = rowDirection.rawValue
        self.columnDirectionRaw = columnDirection.rawValue
        self.cellsData = Pattern.encode(cells ?? Array(repeating: .empty, count: columns * rows))
        self.imageData = imageData
        self.showImage = imageData != nil
        self.imageOpacity = 0.45
        self.isFavorite = false
        self.createdAt = .now
        self.updatedAt = .now
    }

    var customColors: [Color.Resolved] {
        get { (try? JSONDecoder().decode([Color.Resolved].self, from: customColorsData)) ?? [] }
        set { customColorsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var craft: Craft {
        get { Craft(rawValue: craftRaw) ?? .crochet }
        set { craftRaw = newValue.rawValue }
    }

    var cellSize: CellSize {
        get { CellSize(rawValue: cellSizeRaw) ?? .medium }
        set { cellSizeRaw = newValue.rawValue }
    }

    var cellShape: CellShape {
        get { CellShape(rawValue: cellShapeRaw) ?? .square }
        set { cellShapeRaw = newValue.rawValue }
    }

    var rowDirection: RowDirection {
        get { RowDirection(rawValue: rowDirectionRaw) ?? .bottomToTop }
        set { rowDirectionRaw = newValue.rawValue }
    }

    var columnDirection: ColumnDirection {
        get { ColumnDirection(rawValue: columnDirectionRaw) ?? .rightToLeft }
        set { columnDirectionRaw = newValue.rawValue }
    }

    /// Клетки построчно сверху вниз: индекс = row * columns + column.
    var cells: [Cell] {
        get {
            let decoded = (try? JSONDecoder().decode([Cell].self, from: cellsData)) ?? []
            guard decoded.count == columns * rows else {
                return Array(repeating: .empty, count: columns * rows)
            }
            return decoded
        }
        set {
            cellsData = Pattern.encode(newValue)
            updatedAt = .now
        }
    }

    var gridSettings: GridSettings {
        GridSettings(columns: columns, rows: rows,
                     cellSize: cellSize, cellShape: cellShape,
                     showColumnNumbers: showColumnNumbers, showRowNumbers: showRowNumbers,
                     rowDirection: rowDirection, columnDirection: columnDirection)
    }
    
    static func encode(_ cells: [Cell]) -> Data {
        (try? JSONEncoder().encode(cells)) ?? Data()
    }
    
    func duplicate() -> Pattern {
        let copy = Pattern(name: String(localized: "\(name) (copy)"), craft: craft, columns: columns, rows: rows,
                           cellSize: cellSize, cellShape: cellShape,
                           showColumnNumbers: showColumnNumbers, showRowNumbers: showRowNumbers,
                           rowDirection: rowDirection, columnDirection: columnDirection,
                           imageData: imageData, cells: cells)
        copy.summary = summary
        copy.notes = notes
        copy.showImage = showImage
        copy.imageOpacity = imageOpacity
        copy.customColorsData = customColorsData
        return copy
    }
}

/// Параметры отрисовки сетки, не зависящие от SwiftData.
struct GridSettings: Equatable {
    
    var columns: Int
    var rows: Int
    var cellSize: CellSize
    var cellShape: CellShape
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
