//
//  ChartRenderer.swift
//  KnittingPattern
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftUI

/// Геометрия сетки: где клетки, где нумерация, какая клетка под пальцем.
struct ChartLayout {

    /// Сторона квадратной клетки при масштабе 1. Размер на экране задаёт только зум редактора.
    static let cellPoints: CGFloat = 24

    let settings: GridSettings
    let cellSide: CGFloat
    let leftMargin: CGFloat
    let bottomMargin: CGFloat

    init(settings: GridSettings, zoom: CGFloat = 1, showNumbers: Bool = true) {
        self.settings = settings
        cellSide = Self.cellPoints * zoom
        let numberSpace = max(16, 9 * zoom + 8)
        leftMargin = showNumbers && settings.showRowNumbers ? numberSpace : 0
        bottomMargin = showNumbers && settings.showColumnNumbers ? numberSpace : 0
    }

    var gridRect: CGRect {
        CGRect(
            x: leftMargin, y: 0,
            width: CGFloat(settings.columns) * cellSide,
            height: CGFloat(settings.rows) * cellSide
        )
    }

    var totalSize: CGSize {
        CGSize(width: gridRect.maxX + 1, height: gridRect.maxY + bottomMargin + 1)
    }

    func rect(column: Int, row: Int) -> CGRect {
        CGRect(
            x: leftMargin + CGFloat(column) * cellSide,
            y: CGFloat(row) * cellSide,
            width: cellSide, height: cellSide
        )
    }

    /// Клетка под точкой; `clamped` прижимает точку к краю сетки (для протяжки).
    func cell(at point: CGPoint, clamped: Bool = false) -> GridPoint? {
        let column = Int(floor((point.x - leftMargin) / cellSide))
        let row = Int(floor(point.y / cellSide))
        if clamped {
            return GridPoint(
                column: min(max(column, 0), settings.columns - 1),
                row: min(max(row, 0), settings.rows - 1)
            )
        }
        guard (0..<settings.columns).contains(column), (0..<settings.rows).contains(row) else { return nil }
        return GridPoint(column: column, row: row)
    }
}

struct GridPoint: Hashable {
    
    var column: Int
    var row: Int
}

/// Прямоугольная область клеток (включительно).
struct GridRegion: Equatable {
    
    var start: GridPoint
    var end: GridPoint

    var minColumn: Int { min(start.column, end.column) }
    var maxColumn: Int { max(start.column, end.column) }
    var minRow: Int { min(start.row, end.row) }
    var maxRow: Int { max(start.row, end.row) }
    var width: Int { maxColumn - minColumn + 1 }
    var height: Int { maxRow - minRow + 1 }
}

enum ChartRenderer {

    static func draw(
        _ context: inout GraphicsContext,
        layout: ChartLayout,
        cells: [Cell],
        image: Image? = nil,
        imageOpacity: Double = 0.45,
        selection: GridRegion? = nil,
        showNumbers: Bool = true
    ) {
        let grid = layout.gridRect
        context.fill(Path(grid), with: .color(Color.gridBackground))

        if let image {
            var imageContext = context
            imageContext.opacity = imageOpacity
            imageContext.clip(to: Path(grid))
            imageContext.draw(image, in: grid)
        }

        drawCells(&context, layout: layout, cells: cells)
        drawGridLines(&context, layout: layout)
        if let selection {
            drawSelection(&context, layout: layout, selection: selection)
        }
        if showNumbers {
            drawNumbers(&context, layout: layout)
        }
    }

    /// Фон и символы клеток.
    private static func drawCells(_ context: inout GraphicsContext, layout: ChartLayout, cells: [Cell]) {
        let settings = layout.settings
        for row in 0..<settings.rows {
            for column in 0..<settings.columns {
                let index = row * settings.columns + column
                guard index < cells.count else { continue }
                let cell = cells[index]
                guard !cell.isEmpty else { continue }
                let rect = layout.rect(column: column, row: row)
                if let background = cell.background {
                    context.fill(Path(rect), with: .color(background.color))
                }
                if let stitch = Stitch.with(id: cell.symbol) {
                    stitch.draw(
                        in: &context, rect: rect.insetBy(dx: rect.width * 0.08, dy: rect.height * 0.08),
                        color: (cell.color ?? .default).color
                    )
                }
            }
        }
    }

    /// Линии сетки; каждая 10-я петля/ряд — жирнее, как в печатных схемах.
    private static func drawGridLines(_ context: inout GraphicsContext, layout: ChartLayout) {
        let settings = layout.settings
        let grid = layout.gridRect
        var thin = Path()
        var bold = Path()
        for column in 0...settings.columns {
            let x = grid.minX + CGFloat(column) * layout.cellSide
            let number = settings.columnDirection == .leftToRight ? column : settings.columns - column
            var line = Path()
            line.move(to: CGPoint(x: x, y: grid.minY))
            line.addLine(to: CGPoint(x: x, y: grid.maxY))
            if number % 10 == 0 { bold.addPath(line) } else { thin.addPath(line) }
        }
        for row in 0...settings.rows {
            let y = grid.minY + CGFloat(row) * layout.cellSide
            let number = settings.rowDirection == .topToBottom ? row : settings.rows - row
            var line = Path()
            line.move(to: CGPoint(x: grid.minX, y: y))
            line.addLine(to: CGPoint(x: grid.maxX, y: y))
            if number % 10 == 0 { bold.addPath(line) } else { thin.addPath(line) }
        }
        context.stroke(thin, with: .color(Color.gridLine), lineWidth: 0.5)
        context.stroke(bold, with: .color(Color.gridLineBold), lineWidth: 1)
        context.stroke(Path(grid), with: .color(Color.gridLineBold), lineWidth: 1)
    }

    /// Выделенная область с маркерами по углам.
    private static func drawSelection(_ context: inout GraphicsContext, layout: ChartLayout, selection: GridRegion) {
        let rect = layout.rect(column: selection.minColumn, row: selection.minRow)
            .union(layout.rect(column: selection.maxColumn, row: selection.maxRow))
        context.fill(Path(rect), with: .color(Color.accent.opacity(0.22)))
        context.stroke(Path(rect), with: .color(Color.accent), lineWidth: 1.5)
        for corner in [rect.origin, CGPoint(x: rect.maxX, y: rect.minY),
                       CGPoint(x: rect.minX, y: rect.maxY), CGPoint(x: rect.maxX, y: rect.maxY)] {
            let handle = CGRect(x: corner.x - 4, y: corner.y - 4, width: 8, height: 8)
            context.fill(Path(roundedRect: handle, cornerRadius: 2), with: .color(Color.accent))
        }
    }

    /// Номера рядов слева и петель снизу.
    private static func drawNumbers(_ context: inout GraphicsContext, layout: ChartLayout) {
        let settings = layout.settings
        let fontSize = min(11, max(7, layout.cellSide * 0.42))
        if settings.showRowNumbers {
            for row in 0..<settings.rows {
                let rect = layout.rect(column: 0, row: row)
                let text = Text(verbatim: "\(settings.rowNumber(forRow: row))")
                    .font(.system(size: fontSize, weight: .medium).monospacedDigit())
                    .foregroundStyle(Color.secondaryText)
                context.draw(text, at: CGPoint(x: layout.leftMargin - 4, y: rect.midY), anchor: .trailing)
            }
        }
        if settings.showColumnNumbers {
            for column in 0..<settings.columns {
                let rect = layout.rect(column: column, row: settings.rows - 1)
                let text = Text(verbatim: "\(settings.columnNumber(forColumn: column))")
                    .font(.system(size: min(fontSize, layout.cellSide * 0.45), weight: .medium).monospacedDigit())
                    .foregroundStyle(Color.secondaryText)
                context.draw(text, at: CGPoint(x: rect.midX, y: rect.maxY + 4), anchor: .top)
            }
        }
    }
}

/// Статичная схема — для превью в библиотеке и экспорта.
struct ChartView: View {

    let settings: GridSettings
    let cells: [Cell]
    var image: Image?
    var imageOpacity: Double = 0.45
    var zoom: CGFloat = 1
    var showNumbers = true

    var body: some View {
        let layout = ChartLayout(settings: settings, zoom: zoom, showNumbers: showNumbers)
        Canvas { context, _ in
            ChartRenderer.draw(
                &context, layout: layout, cells: cells, image: image,
                imageOpacity: imageOpacity, showNumbers: showNumbers
            )
        }
        .frame(width: layout.totalSize.width, height: layout.totalSize.height)
    }
}

#if DEBUG
#Preview("Grid") {
    let pattern = SampleData.heart()
    ScrollView([.horizontal, .vertical]) {
        ChartView(settings: pattern.gridSettings, cells: pattern.cells)
            .padding()
    }
    .background(Color.background)
}
#endif
