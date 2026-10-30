//
//  ChartLayoutTests.swift
//  ThreadfolioTests
//
//  Created by Ekaterina on 28.10.2026.
//

import CoreGraphics
import Foundation
import Testing
@testable import Threadfolio

@MainActor
struct ChartLayoutTests {

    private let settings = GridSettings(columns: 10, rows: 5, showColumnNumbers: true, showRowNumbers: true,
                                        rowDirection: .bottomToTop, columnDirection: .leftToRight)

    @Test func cellsAreSquare() {
        let layout = ChartLayout(settings: settings, zoom: 1.5)
        let rect = layout.rect(column: 2, row: 3)
        #expect(rect.width == ChartLayout.cellPoints * 1.5)
        #expect(rect.width == rect.height)
    }

    @Test func numbersAddMargins() {
        let withNumbers = ChartLayout(settings: settings)
        let withoutNumbers = ChartLayout(settings: settings, showNumbers: false)
        #expect(withNumbers.leftMargin > 0)
        #expect(withNumbers.bottomMargin > 0)
        #expect(withoutNumbers.leftMargin == 0)
        #expect(withoutNumbers.bottomMargin == 0)
        #expect(withoutNumbers.totalSize.width == 10 * ChartLayout.cellPoints + 1)
        #expect(withoutNumbers.totalSize.height == 5 * ChartLayout.cellPoints + 1)
    }

    @Test func hiddenRowNumbersRemoveLeftMarginOnly() {
        var noRowNumbers = settings
        noRowNumbers.showRowNumbers = false
        let layout = ChartLayout(settings: noRowNumbers)
        #expect(layout.leftMargin == 0)
        #expect(layout.bottomMargin > 0)
    }

    @Test func pointInsideCellFindsIt() {
        let layout = ChartLayout(settings: settings)
        let center = CGPoint(x: layout.rect(column: 7, row: 2).midX, y: layout.rect(column: 7, row: 2).midY)
        #expect(layout.cell(at: center) == GridPoint(column: 7, row: 2))
    }

    @Test func pointOutsideGridFindsNothing() {
        let layout = ChartLayout(settings: settings)
        #expect(layout.cell(at: CGPoint(x: layout.leftMargin - 1, y: 1)) == nil)
        #expect(layout.cell(at: CGPoint(x: layout.gridRect.maxX + 1, y: 1)) == nil)
        #expect(layout.cell(at: CGPoint(x: layout.leftMargin + 1, y: layout.gridRect.maxY + 1)) == nil)
    }

    @Test func clampedPointSticksToEdge() {
        let layout = ChartLayout(settings: settings)
        #expect(layout.cell(at: CGPoint(x: -100, y: -100), clamped: true) == GridPoint(column: 0, row: 0))
        #expect(layout.cell(at: CGPoint(x: 10_000, y: 10_000), clamped: true) == GridPoint(column: 9, row: 4))
    }

    @Test func regionIsNormalized() {
        let region = GridRegion(start: GridPoint(column: 5, row: 4), end: GridPoint(column: 2, row: 1))
        #expect(region.minColumn == 2)
        #expect(region.maxColumn == 5)
        #expect(region.minRow == 1)
        #expect(region.maxRow == 4)
        #expect(region.width == 4)
        #expect(region.height == 4)
    }
}

@MainActor
struct PatternDraftTests {

    @Test func draftBecomesPatternWithChosenSettings() {
        let draft = PatternDraft()
        draft.name = "  Scarf  "
        draft.craft = .knitting
        draft.columns = 12
        draft.rows = 30
        draft.showRowNumbers = false
        draft.columnDirection = .rightToLeft

        let pattern = draft.makePattern()
        #expect(pattern.name == "Scarf")
        #expect(pattern.craft == .knitting)
        #expect(pattern.columns == 12)
        #expect(pattern.rows == 30)
        #expect(pattern.cells.count == 360)
        #expect(!pattern.showRowNumbers)
        #expect(pattern.columnDirection == .rightToLeft)
        #expect(pattern.imageData == nil)
        #expect(!pattern.showImage)
    }

    @Test func emptyNameGetsDefault() {
        let draft = PatternDraft()
        draft.name = "   "
        #expect(!draft.makePattern().name.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    @Test func photoBecomesVisibleBackground() {
        let draft = PatternDraft()
        draft.imageData = Data([0x89, 0x50, 0x4E, 0x47])
        let pattern = draft.makePattern()
        #expect(pattern.imageData != nil)
        #expect(pattern.showImage)
    }
}
