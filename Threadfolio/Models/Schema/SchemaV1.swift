//
//  SchemaV1.swift
//  KnittingPattern
//
//  Created by Ekaterina on 27.10.2026.
//

import Foundation
import SwiftUI
import SwiftData

/// Первая версия хранилища. Когда появится `SchemaV2`, эта модель
/// остаётся замороженной копией — по ней SwiftData узнаёт старую базу.
nonisolated enum SchemaV1: VersionedSchema {

    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Pattern.self]
    }
}

extension SchemaV1 {

    @Model
    final class Pattern {
        
        var name: String
        /// Описание схемы (что это, пряжа, инструмент).
        var summary: String
        var notes: String
        var craftRaw: String
        var columns: Int
        var rows: Int
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
            self.showColumnNumbers = showColumnNumbers
            self.showRowNumbers = showRowNumbers
            self.rowDirectionRaw = rowDirection.rawValue
            self.columnDirectionRaw = columnDirection.rawValue
            self.cellsData = Self.encode(cells ?? Array(repeating: .empty, count: columns * rows))
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
                cellsData = Self.encode(newValue)
                updatedAt = .now
            }
        }

        var gridSettings: GridSettings {
            GridSettings(columns: columns, rows: rows,
                         showColumnNumbers: showColumnNumbers, showRowNumbers: showRowNumbers,
                         rowDirection: rowDirection, columnDirection: columnDirection)
        }
        
        static func encode(_ cells: [Cell]) -> Data {
            (try? JSONEncoder().encode(cells)) ?? Data()
        }
        
        func duplicate() -> Pattern {
            let copy = Pattern(name: String(localized: "\(name) (copy)"), craft: craft, columns: columns, rows: rows,
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
}
