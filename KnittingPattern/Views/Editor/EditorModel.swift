//
//  EditorModel.swift
//  KnittingPattern
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftUI
import SwiftData

@Observable
final class EditorModel {
    enum Tool: String, CaseIterable, Identifiable {
        case pan, pencil, eraser, fill, select

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .pan: "cursorarrow"
            case .pencil: "pencil"
            case .eraser: "eraser"
            case .fill: "drop"
            case .select: "rectangle.dashed"
            }
        }

        var title: LocalizedStringKey {
            switch self {
            case .pan: "View and pick stitch"
            case .pencil: "Pencil"
            case .eraser: "Eraser"
            case .fill: "Fill"
            case .select: "Selection"
            }
        }
    }

    struct Clipboard {
        var width: Int
        var height: Int
        var cells: [Cell]
    }

    private static let undoLimit = 60

    let pattern: Pattern
    private(set) var cells: [Cell]
    private(set) var settings: GridSettings

    var tool: Tool = .pencil {
        didSet { if tool != .select { selection = nil } }
    }
    var currentSymbol: StitchID
    var currentColor: CellColor = .default
    /// true — кисть красит фон клетки, false — ставит символ петли.
    var paintsBackground = false
    var selection: GridRegion?
    private(set) var clipboard: Clipboard?
    var zoom: CGFloat = 1

    private var undoStack: [[Cell]] = []
    private var redoStack: [[Cell]] = []
    private var lastStrokePoint: GridPoint?
    private var isStroking = false
    private var selectionAnchor: GridPoint?

    init(pattern: Pattern) {
        self.pattern = pattern
        cells = pattern.cells
        settings = pattern.gridSettings
        currentSymbol = pattern.craft.stitch
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    var palette: [CellColor] {
        PaletteColor.allCases.map(CellColor.palette) + pattern.customColors.map(CellColor.custom)
    }

    /// Индекс цвета, который сейчас настраивается в ColorPicker: пока пользователь
    /// ведёт по палитре, обновляем один и тот же цвет, а не плодим новые.
    private var liveCustomColorIndex: Int?

    func pickCustomColor(_ color: Color) {
        let resolved = color.resolve(in: EnvironmentValues())
        if let index = liveCustomColorIndex, index < pattern.customColors.count {
            pattern.customColors[index] = resolved
        } else if !pattern.customColors.contains(resolved) {
            pattern.customColors.append(resolved)
            liveCustomColorIndex = pattern.customColors.count - 1
        }
        currentColor = .custom(resolved)
    }

    func selectColor(_ color: CellColor) {
        liveCustomColorIndex = nil
        currentColor = color
    }

    // MARK: История

    private func checkpoint() {
        undoStack.append(cells)
        if undoStack.count > Self.undoLimit { undoStack.removeFirst() }
        redoStack.removeAll()
    }

    private func save() {
        pattern.cells = cells
        // Сохраняем сразу, не дожидаясь автосохранения SwiftData:
        // иначе последние правки теряются, если приложение закрыли принудительно.
        try? pattern.modelContext?.save()
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(cells)
        cells = previous
        selection = nil
        save()
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(cells)
        cells = next
        save()
    }

    // MARK: Рисование

    private func index(_ point: GridPoint) -> Int {
        point.row * settings.columns + point.column
    }

    private func applyBrush(at point: GridPoint) {
        var cell = cells[index(point)]
        switch tool {
        case .pencil:
            if paintsBackground {
                cell.background = currentColor
            } else {
                cell.symbol = currentSymbol
                cell.color = currentColor
            }
        case .eraser:
            if paintsBackground {
                cell.background = nil
            } else {
                cell = .empty
            }
        default:
            return
        }
        cells[index(point)] = cell
    }

    /// Протяжка пальцем: заполняет все клетки по пути, без пропусков при быстром движении.
    func stroke(to point: GridPoint) {
        if !isStroking {
            checkpoint()
            isStroking = true
            lastStrokePoint = nil
        }
        for cellPoint in Self.line(from: lastStrokePoint ?? point, to: point) {
            applyBrush(at: cellPoint)
        }
        lastStrokePoint = point
    }

    func endStroke() {
        guard isStroking else { return }
        isStroking = false
        lastStrokePoint = nil
        save()
    }

    /// Ставит выбранную в палитре петлю в одну клетку.
    func place(symbol: StitchID, at point: GridPoint) {
        checkpoint()
        cells[index(point)].symbol = symbol
        cells[index(point)].color = currentColor
        currentSymbol = symbol
        save()
    }

    /// Заливка связной области одинаковых клеток (по символу или по фону).
    func floodFill(at start: GridPoint) {
        let target = cells[index(start)]
        let byBackground = paintsBackground
        func matches(_ cell: Cell) -> Bool {
            if byBackground { return cell.background == target.background }
            return cell.symbol == target.symbol && (cell.symbol == nil || cell.color == target.color)
        }
        if paintsBackground, target.background == currentColor { return }
        if !paintsBackground, target.symbol == currentSymbol, target.color == currentColor { return }

        checkpoint()
        var visited = Set<Int>()
        var queue = [start]
        while let point = queue.popLast() {
            let i = index(point)
            guard !visited.contains(i), matches(cells[i]) else { continue }
            visited.insert(i)
            if paintsBackground {
                cells[i].background = currentColor
            } else {
                cells[i].symbol = currentSymbol
                cells[i].color = currentColor
            }
            for (dc, dr) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                let next = GridPoint(column: point.column + dc, row: point.row + dr)
                if (0..<settings.columns).contains(next.column), (0..<settings.rows).contains(next.row) {
                    queue.append(next)
                }
            }
        }
        save()
    }

    // MARK: Выделение

    func dragSelection(to point: GridPoint) {
        if selectionAnchor == nil { selectionAnchor = point }
        selection = GridRegion(start: selectionAnchor ?? point, end: point)
    }

    func endSelectionDrag() {
        selectionAnchor = nil
    }

    private func region() -> [GridPoint] {
        guard let selection else { return [] }
        return (selection.minRow...selection.maxRow).flatMap { row in
            (selection.minColumn...selection.maxColumn).map { GridPoint(column: $0, row: row) }
        }
    }

    func copySelection() {
        guard let selection else { return }
        clipboard = Clipboard(width: selection.width, height: selection.height, cells: region().map { cells[index($0)] })
    }

    /// Вставляет скопированный фрагмент, левым верхним углом в начало выделения.
    func paste() {
        guard let clipboard, let selection else { return }
        checkpoint()
        let origin = GridPoint(column: selection.minColumn, row: selection.minRow)
        for row in 0..<clipboard.height {
            for column in 0..<clipboard.width {
                let target = GridPoint(column: origin.column + column, row: origin.row + row)
                guard target.column < settings.columns, target.row < settings.rows else { continue }
                cells[index(target)] = clipboard.cells[row * clipboard.width + column]
            }
        }
        self.selection = GridRegion(
            start: origin,
            end: GridPoint(
                column: min(origin.column + clipboard.width, settings.columns) - 1,
                row: min(origin.row + clipboard.height, settings.rows) - 1
            )
        )
        save()
    }

    func flipSelection(horizontally: Bool) {
        guard let selection else { return }
        checkpoint()
        let original = cells
        for point in region() {
            let source = horizontally
                ? GridPoint(column: selection.maxColumn - (point.column - selection.minColumn), row: point.row)
                : GridPoint(column: point.column, row: selection.maxRow - (point.row - selection.minRow))
            cells[index(point)] = original[index(source)]
        }
        save()
    }

    func fillSelection() {
        guard selection != nil else { return }
        checkpoint()
        for point in region() {
            if paintsBackground {
                cells[index(point)].background = currentColor
            } else {
                cells[index(point)].symbol = currentSymbol
                cells[index(point)].color = currentColor
            }
        }
        save()
    }

    func clearSelection() {
        guard selection != nil else { return }
        checkpoint()
        for point in region() { cells[index(point)] = .empty }
        save()
    }

    func clearAll() {
        checkpoint()
        cells = Array(repeating: .empty, count: cells.count)
        save()
    }

    // MARK: Настройки сетки

    /// Применяет новые настройки. При изменении размера содержимое
    /// привязано к ряду 1 и петле 1, чтобы схема не «уезжала».
    func apply(_ newSettings: GridSettings) {
        if newSettings.columns != settings.columns || newSettings.rows != settings.rows {
            var resized = Array(repeating: Cell.empty, count: newSettings.columns * newSettings.rows)
            let anchorBottom = settings.rowDirection == .bottomToTop
            let anchorRight = settings.columnDirection == .rightToLeft
            for row in 0..<settings.rows {
                for column in 0..<settings.columns {
                    let newRow = anchorBottom ? row + newSettings.rows - settings.rows : row
                    let newColumn = anchorRight ? column + newSettings.columns - settings.columns : column
                    guard (0..<newSettings.rows).contains(newRow), (0..<newSettings.columns).contains(newColumn) else {
                        continue
                    }
                    resized[newRow * newSettings.columns + newColumn] = cells[row * settings.columns + column]
                }
            }
            // История хранит снимки старого размера — после изменения она неприменима.
            undoStack.removeAll()
            redoStack.removeAll()
            selection = nil
            pattern.columns = newSettings.columns
            pattern.rows = newSettings.rows
            cells = resized
            settings = newSettings
            save()
        }
        settings = newSettings
        pattern.cellSize = newSettings.cellSize
        pattern.cellShape = newSettings.cellShape
        pattern.showColumnNumbers = newSettings.showColumnNumbers
        pattern.showRowNumbers = newSettings.showRowNumbers
        pattern.rowDirection = newSettings.rowDirection
        pattern.columnDirection = newSettings.columnDirection
        pattern.updatedAt = .now
    }

    /// Петли, использованные в схеме, — для легенды.
    var usedStitches: [Stitch] {
        let ids = Set(cells.compactMap(\.symbol))
        return (Stitch.crochet + Stitch.knitting).filter { ids.contains($0.id) }
    }

    /// Алгоритм Брезенхема: клетки на отрезке между двумя точками.
    static func line(from a: GridPoint, to b: GridPoint) -> [GridPoint] {
        var points: [GridPoint] = []
        var x = a.column, y = a.row
        let dx = abs(b.column - x), dy = -abs(b.row - y)
        let sx = x < b.column ? 1 : -1, sy = y < b.row ? 1 : -1
        var error = dx + dy
        while true {
            points.append(GridPoint(column: x, row: y))
            if x == b.column && y == b.row { break }
            let e2 = 2 * error
            if e2 >= dy { error += dy; x += sx }
            if e2 <= dx { error += dx; y += sy }
        }
        return points
    }
}
