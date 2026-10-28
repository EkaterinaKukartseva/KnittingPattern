//
//  EditorModelTests.swift
//  KnittingPatternTests
//
//  Created by Ekaterina on 28.10.2026.
//

import SwiftUI
import Testing
@testable import KnittingPattern

@MainActor
struct EditorModelTests {

    private func makeModel(columns: Int = 4, rows: Int = 3, craft: Craft = .crochet) -> EditorModel {
        EditorModel(pattern: Pattern(name: "Test", craft: craft, columns: columns, rows: rows))
    }

    private func cell(_ model: EditorModel, _ column: Int, _ row: Int) -> Cell {
        model.cells[row * model.settings.columns + column]
    }

    private func draw(_ model: EditorModel, _ points: GridPoint...) {
        for point in points { model.stroke(to: point) }
        model.endStroke()
    }

    private func at(_ column: Int, _ row: Int) -> GridPoint {
        GridPoint(column: column, row: row)
    }

    // MARK: Кисть

    @Test func defaultStitchDependsOnCraft() {
        #expect(makeModel(craft: .crochet).currentSymbol == .singleCrochet)
        #expect(makeModel(craft: .knitting).currentSymbol == .knit)
    }

    @Test func strokeFillsEveryCellAlongTheWay() {
        let model = makeModel()
        draw(model, at(0, 0), at(3, 0))
        for column in 0..<4 {
            #expect(cell(model, column, 0).symbol == .singleCrochet)
        }
        #expect(cell(model, 0, 1).isEmpty)
    }

    @Test func strokeIsSavedToPattern() {
        let model = makeModel()
        draw(model, at(1, 1))
        #expect(model.pattern.cells[1 * 4 + 1].symbol == .singleCrochet)
    }

    @Test func backgroundBrushKeepsSymbol() {
        let model = makeModel()
        draw(model, at(0, 0))
        model.paintsBackground = true
        model.currentColor = .palette(.pink)
        draw(model, at(0, 0))
        #expect(cell(model, 0, 0).symbol == .singleCrochet)
        #expect(cell(model, 0, 0).background == .palette(.pink))
    }

    @Test func eraserRemovesOnlyWhatTheBrushPaints() {
        let model = makeModel()
        draw(model, at(0, 0))
        model.paintsBackground = true
        draw(model, at(0, 0))

        model.tool = .eraser
        draw(model, at(0, 0))
        #expect(cell(model, 0, 0).background == nil)
        #expect(cell(model, 0, 0).symbol == .singleCrochet)

        model.paintsBackground = false
        draw(model, at(0, 0))
        #expect(cell(model, 0, 0).isEmpty)
    }

    @Test func placeSetsSymbolAndMakesItCurrent() {
        let model = makeModel()
        model.place(symbol: .chain, at: at(2, 1))
        #expect(cell(model, 2, 1).symbol == .chain)
        #expect(model.currentSymbol == .chain)
    }

    // MARK: История

    @Test func undoAndRedoWholeStroke() {
        let model = makeModel()
        draw(model, at(0, 0), at(2, 0))
        #expect(model.canUndo)

        model.undo()
        #expect(model.cells.allSatisfy { $0.isEmpty })
        #expect(model.canRedo)

        model.redo()
        #expect(cell(model, 2, 0).symbol == .singleCrochet)
        #expect(!model.canRedo)
    }

    @Test func newEditClearsRedo() {
        let model = makeModel()
        draw(model, at(0, 0))
        model.undo()
        draw(model, at(1, 1))
        #expect(!model.canRedo)
    }

    @Test func clearAllCanBeUndone() {
        let model = makeModel()
        draw(model, at(0, 0), at(3, 0))
        model.clearAll()
        #expect(model.cells.allSatisfy { $0.isEmpty })
        model.undo()
        #expect(cell(model, 3, 0).symbol == .singleCrochet)
    }

    // MARK: Заливка

    @Test func floodFillStopsAtDifferentStitches() {
        let model = makeModel(columns: 3, rows: 3)
        model.currentSymbol = .chain
        draw(model, at(1, 0), at(1, 2))

        model.currentSymbol = .doubleCrochet
        model.floodFill(at: at(0, 0))
        for row in 0..<3 {
            #expect(cell(model, 0, row).symbol == .doubleCrochet)
            #expect(cell(model, 1, row).symbol == .chain)
            #expect(cell(model, 2, row).isEmpty)
        }
    }

    @Test func floodFillWithSameStitchAddsNoHistoryStep() {
        let model = makeModel()
        draw(model, at(0, 0))
        model.floodFill(at: at(0, 0))
        // Заливка тем же значком ничего не меняет, поэтому undo сразу отменяет рисунок.
        model.undo()
        #expect(model.cells.allSatisfy { $0.isEmpty })
        #expect(!model.canUndo)
    }

    @Test func backgroundFloodFillIgnoresSymbols() {
        let model = makeModel(columns: 2, rows: 1)
        draw(model, at(0, 0))
        model.paintsBackground = true
        model.currentColor = .palette(.beige)
        model.floodFill(at: at(1, 0))
        #expect(cell(model, 0, 0).background == .palette(.beige))
        #expect(cell(model, 1, 0).background == .palette(.beige))
        #expect(cell(model, 0, 0).symbol == .singleCrochet)
    }

    // MARK: Выделение

    @Test func copyAndPasteFragment() {
        let model = makeModel()
        model.place(symbol: .chain, at: at(0, 0))
        model.place(symbol: .picot, at: at(1, 0))

        model.selection = GridRegion(start: at(0, 0), end: at(1, 0))
        model.copySelection()
        model.selection = GridRegion(start: at(2, 2), end: at(2, 2))
        model.paste()

        #expect(cell(model, 2, 2).symbol == .chain)
        #expect(cell(model, 3, 2).symbol == .picot)
        #expect(model.selection == GridRegion(start: at(2, 2), end: at(3, 2)))
    }

    @Test func pasteIsClippedAtGridEdge() {
        let model = makeModel()
        model.place(symbol: .chain, at: at(0, 0))
        model.place(symbol: .picot, at: at(1, 0))
        model.selection = GridRegion(start: at(0, 0), end: at(1, 0))
        model.copySelection()

        model.selection = GridRegion(start: at(3, 0), end: at(3, 0))
        model.paste()
        #expect(cell(model, 3, 0).symbol == .chain)
        #expect(model.selection == GridRegion(start: at(3, 0), end: at(3, 0)))
    }

    @Test func flipSelectionHorizontally() {
        let model = makeModel()
        model.place(symbol: .chain, at: at(0, 0))
        model.place(symbol: .picot, at: at(2, 0))
        model.selection = GridRegion(start: at(0, 0), end: at(2, 0))
        model.flipSelection(horizontally: true)
        #expect(cell(model, 0, 0).symbol == .picot)
        #expect(cell(model, 2, 0).symbol == .chain)
    }

    @Test func flipSelectionVertically() {
        let model = makeModel()
        model.place(symbol: .chain, at: at(1, 0))
        model.selection = GridRegion(start: at(1, 0), end: at(1, 2))
        model.flipSelection(horizontally: false)
        #expect(cell(model, 1, 0).isEmpty)
        #expect(cell(model, 1, 2).symbol == .chain)
    }

    @Test func fillAndClearSelection() {
        let model = makeModel()
        model.selection = GridRegion(start: at(1, 1), end: at(2, 2))
        model.fillSelection()
        #expect(model.cells.filter { !$0.isEmpty }.count == 4)

        model.clearSelection()
        #expect(model.cells.allSatisfy { $0.isEmpty })
    }

    @Test func dragSelectionKeepsAnchor() {
        let model = makeModel()
        model.tool = .select
        model.dragSelection(to: at(2, 2))
        model.dragSelection(to: at(0, 1))
        model.endSelectionDrag()
        #expect(model.selection?.minColumn == 0)
        #expect(model.selection?.maxColumn == 2)
        #expect(model.selection?.minRow == 1)
        #expect(model.selection?.maxRow == 2)
    }

    @Test func switchingToolClearsSelection() {
        let model = makeModel()
        model.tool = .select
        model.selection = GridRegion(start: at(0, 0), end: at(1, 1))
        model.tool = .pencil
        #expect(model.selection == nil)
    }

    // MARK: Настройки сетки

    @Test func growingGridKeepsRowOneInPlace() {
        // Ряд 1 снизу, петля 1 слева: новые ряды добавляются сверху, петли — справа.
        let model = makeModel(columns: 3, rows: 3)
        model.place(symbol: .chain, at: at(0, 2))

        var settings = model.settings
        settings.columns = 4
        settings.rows = 5
        model.apply(settings)

        #expect(model.cells.count == 20)
        #expect(cell(model, 0, 4).symbol == .chain)
        #expect(model.pattern.columns == 4)
        #expect(model.pattern.rows == 5)
    }

    @Test func rightToLeftGridGrowsOnTheLeft() {
        let pattern = Pattern(name: "Test", craft: .knitting, columns: 3, rows: 2,
                              rowDirection: .topToBottom, columnDirection: .rightToLeft)
        let model = EditorModel(pattern: pattern)
        model.place(symbol: .knit, at: at(2, 0))

        var settings = model.settings
        settings.columns = 5
        model.apply(settings)
        #expect(cell(model, 4, 0).symbol == .knit)
    }

    @Test func shrinkingGridTrimsOuterCellsAndResetsHistory() {
        let model = makeModel(columns: 3, rows: 3)
        model.place(symbol: .chain, at: at(2, 0))
        model.place(symbol: .picot, at: at(0, 2))

        var settings = model.settings
        settings.columns = 2
        settings.rows = 2
        model.apply(settings)

        #expect(model.cells.count == 4)
        #expect(cell(model, 0, 1).symbol == .picot)
        #expect(!model.cells.contains { $0.symbol == .chain })
        #expect(!model.canUndo)
    }

    @Test func numberingChangeKeepsCells() {
        let model = makeModel()
        model.place(symbol: .chain, at: at(1, 1))
        var settings = model.settings
        settings.showRowNumbers = false
        settings.rowDirection = .topToBottom
        model.apply(settings)

        #expect(cell(model, 1, 1).symbol == .chain)
        #expect(!model.pattern.showRowNumbers)
        #expect(model.pattern.rowDirection == .topToBottom)
        #expect(model.canUndo)
    }

    // MARK: Палитра и легенда

    @Test func customColorIsAddedOnceWhileAdjusting() {
        let model = makeModel()
        model.pickCustomColor(Color(red: 1, green: 0, blue: 0))
        model.pickCustomColor(Color(red: 0.9, green: 0, blue: 0))
        #expect(model.pattern.customColors.count == 1)
        #expect(model.palette.count == PaletteColor.allCases.count + 1)

        model.selectColor(.palette(.ink))
        model.pickCustomColor(Color(red: 0, green: 0, blue: 1))
        #expect(model.pattern.customColors.count == 2)
    }

    @Test func usedStitchesListsEachStitchOnce() {
        let model = makeModel()
        model.place(symbol: .chain, at: at(0, 0))
        model.place(symbol: .chain, at: at(1, 0))
        model.place(symbol: .picot, at: at(2, 0))
        #expect(Set(model.usedStitches.map(\.id)) == [.chain, .picot])
        #expect(model.usedStitches.count == 2)
    }

    // MARK: Линия Брезенхема

    /// Отрезки: (column, row) начала и конца.
    @Test(arguments: [
        [0, 0, 5, 2],
        [4, 4, 0, 1],
        [2, 0, 2, 6],
        [3, 3, 3, 3],
    ])
    func lineIsContinuous(_ segment: [Int]) {
        let start = at(segment[0], segment[1])
        let end = at(segment[2], segment[3])
        let points = EditorModel.line(from: start, to: end)
        #expect(points.first == start)
        #expect(points.last == end)
        for (a, b) in zip(points, points.dropFirst()) {
            #expect(abs(a.column - b.column) <= 1 && abs(a.row - b.row) <= 1)
            #expect(a != b)
        }
    }
}
