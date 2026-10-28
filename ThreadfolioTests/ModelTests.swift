//
//  ModelTests.swift
//  KnittingPatternTests
//
//  Created by Ekaterina on 28.10.2026.
//

import Foundation
import SwiftData
import SwiftUI
import Testing
@testable import KnittingPattern

struct CellColorTests {

    @Test func paletteColorIsStoredByName() throws {
        let data = try JSONEncoder().encode(CellColor.palette(.green))
        #expect(String(data: data, encoding: .utf8) == #""green""#)
        #expect(try JSONDecoder().decode(CellColor.self, from: data) == .palette(.green))
    }

    @Test func customColorIsStoredAsRGB() throws {
        let color = CellColor.custom(Color.Resolved(red: 0.25, green: 0.5, blue: 1))
        let data = try JSONEncoder().encode(color)
        #expect(String(data: data, encoding: .utf8) == "[0.25,0.5,1]")
        #expect(try JSONDecoder().decode(CellColor.self, from: data) == color)
    }

    @Test func wrongComponentCountFails() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(CellColor.self, from: Data("[0.1,0.2]".utf8))
        }
    }

    @Test func emptyCellTakesNoSpace() throws {
        let data = try JSONEncoder().encode(Cell.empty)
        #expect(String(data: data, encoding: .utf8) == "{}")
        #expect(Cell.empty.isEmpty)
        #expect(!Cell(background: .palette(.pink)).isEmpty)
    }
}

struct GridSettingsTests {

    private func settings(rows: RowDirection, columns: ColumnDirection) -> GridSettings {
        GridSettings(columns: 10, rows: 5, showColumnNumbers: true, showRowNumbers: true,
                     rowDirection: rows, columnDirection: columns)
    }

    @Test func bottomToTopCountsFromTheBottom() {
        let grid = settings(rows: .bottomToTop, columns: .leftToRight)
        #expect(grid.rowNumber(forRow: 4) == 1)
        #expect(grid.rowNumber(forRow: 0) == 5)
    }

    @Test func topToBottomCountsFromTheTop() {
        let grid = settings(rows: .topToBottom, columns: .leftToRight)
        #expect(grid.rowNumber(forRow: 0) == 1)
        #expect(grid.rowNumber(forRow: 4) == 5)
    }

    @Test func columnsCanBeReadInBothDirections() {
        #expect(settings(rows: .bottomToTop, columns: .leftToRight).columnNumber(forColumn: 0) == 1)
        #expect(settings(rows: .bottomToTop, columns: .rightToLeft).columnNumber(forColumn: 0) == 10)
        #expect(settings(rows: .bottomToTop, columns: .rightToLeft).columnNumber(forColumn: 9) == 1)
    }
}

@MainActor
struct PatternTests {

    @Test func newPatternHasEmptyGrid() {
        let pattern = Pattern(name: "Test", craft: .knitting, columns: 4, rows: 3)
        #expect(pattern.cells.count == 12)
        #expect(pattern.cells.allSatisfy { $0.isEmpty })
        #expect(pattern.craft == .knitting)
    }

    @Test func settingCellsUpdatesModificationDate() {
        let pattern = Pattern(name: "Test", craft: .crochet, columns: 2, rows: 2)
        pattern.updatedAt = .distantPast
        var cells = pattern.cells
        cells[3] = Cell(symbol: .chain)
        pattern.cells = cells
        #expect(pattern.cells[3].symbol == .chain)
        #expect(pattern.updatedAt > .distantPast)
    }

    @Test func cellsOfWrongSizeAreReplacedWithEmptyGrid() {
        let pattern = Pattern(name: "Test", craft: .crochet, columns: 2, rows: 2)
        pattern.cellsData = Pattern.encode([Cell(symbol: .chain)])
        #expect(pattern.cells.count == 4)
        #expect(pattern.cells.allSatisfy { $0.isEmpty })
    }

    @Test func unknownRawValuesFallBackToDefaults() {
        let pattern = Pattern(name: "Test", craft: .knitting, columns: 2, rows: 2)
        pattern.craftRaw = "weaving"
        pattern.rowDirectionRaw = "sideways"
        #expect(pattern.craft == .crochet)
        #expect(pattern.rowDirection == .bottomToTop)
    }

    @Test func customColorsRoundTrip() throws {
        let pattern = Pattern(name: "Test", craft: .crochet, columns: 2, rows: 2)
        let color = Color.Resolved(red: 0.9, green: 0.1, blue: 0.3)
        pattern.customColors = [color]

        // После JSON компоненты могут отличаться в последнем знаке (0.1 → 0.09999999).
        let stored = try #require(pattern.customColors.first)
        #expect(pattern.customColors.count == 1)
        #expect(abs(stored.red - color.red) < 0.0001)
        #expect(abs(stored.green - color.green) < 0.0001)
        #expect(abs(stored.blue - color.blue) < 0.0001)
    }

    @Test func gridSettingsMirrorPattern() {
        let pattern = Pattern(name: "Test", craft: .crochet, columns: 7, rows: 3,
                              showColumnNumbers: false, rowDirection: .topToBottom, columnDirection: .rightToLeft)
        let settings = pattern.gridSettings
        #expect(settings.columns == 7)
        #expect(settings.rows == 3)
        #expect(!settings.showColumnNumbers)
        #expect(settings.showRowNumbers)
        #expect(settings.rowDirection == .topToBottom)
        #expect(settings.columnDirection == .rightToLeft)
    }

    @Test func duplicateCopiesContentUnderNewName() {
        let pattern = Pattern(name: "Heart", craft: .crochet, columns: 2, rows: 1,
                              cells: [Cell(symbol: .chain), .empty])
        pattern.summary = "Cotton"
        pattern.notes = "Row 5"
        pattern.customColors = [Color.Resolved(red: 1, green: 0, blue: 0)]

        let copy = pattern.duplicate()
        #expect(copy.name != pattern.name)
        #expect(copy.name.contains("Heart"))
        #expect(copy.cells == pattern.cells)
        #expect(copy.summary == "Cotton")
        #expect(copy.notes == "Row 5")
        #expect(copy.customColors == pattern.customColors)
        #expect(!copy.isFavorite)
    }
}

@MainActor
struct StorageTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Schema(versionedSchema: CurrentSchema.self),
            migrationPlan: PatternMigrationPlan.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test func currentSchemaIsLatestInMigrationPlan() throws {
        let latest = try #require(PatternMigrationPlan.schemas.last)
        #expect(ObjectIdentifier(latest) == ObjectIdentifier(CurrentSchema.self))
    }

    @Test func schemaVersionsGoUp() {
        let versions = PatternMigrationPlan.schemas.map { schema in schema.versionIdentifier }
        for (older, newer) in zip(versions, versions.dropFirst()) {
            #expect(older < newer)
        }
    }

    @Test func savedPatternIsReadBack() throws {
        let container = try makeContainer()
        let pattern = Pattern(name: "Saved", craft: .knitting, columns: 2, rows: 2,
                              cells: [Cell(symbol: .knit, color: .palette(.blue)), .empty, .empty, Cell(symbol: .purl)])
        container.mainContext.insert(pattern)
        try container.mainContext.save()

        let fetched = try container.mainContext.fetch(FetchDescriptor<Pattern>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Saved")
        #expect(fetched.first?.cells == pattern.cells)
    }
}
