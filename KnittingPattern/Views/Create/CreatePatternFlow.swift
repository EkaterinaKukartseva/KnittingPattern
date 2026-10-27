//
//  CreatePatternFlow.swift
//  KnittingPattern
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftUI
import SwiftData

/// Черновик новой схемы, который заполняется по шагам мастера.
@Observable
final class PatternDraft {
    
    nonisolated enum Source { case blank, image }

    var source: Source = .blank
    var craft: Craft = .crochet
    var imageData: Data?
    var name = ""
    var columns = 20
    var rows = 20
    var showColumnNumbers = true
    var showRowNumbers = true
    var rowDirection: RowDirection = .bottomToTop
    var columnDirection: ColumnDirection = .leftToRight
    /// Перенести цвета фото в фон клеток (для жаккарда и вышивки).
    var sampleImageColors = false

    static let sizeRange = 2...150

    func makePattern() -> Pattern {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        var cells: [Cell]?
        if sampleImageColors, let imageData,
           let colors = ImageSupport.sampleColors(from: imageData, columns: columns, rows: rows) {
            cells = colors.map { Cell(background: .custom($0)) }
        }
        return Pattern(name: trimmed.isEmpty ? String(localized: "New Chart") : trimmed,
                       craft: craft, columns: columns, rows: rows,
                       showColumnNumbers: showColumnNumbers, showRowNumbers: showRowNumbers,
                       rowDirection: rowDirection, columnDirection: columnDirection,
                       imageData: imageData, cells: cells)
    }
}

struct CreatePatternFlow: View {
    
    var onCreate: (Pattern) -> Void
    @State private var draft = PatternDraft()

    var body: some View {
        NavigationStack {
            CreatePatternView(draft: draft, onCreate: onCreate)
        }
        .tint(.accentDark)
    }
}

#if DEBUG
#Preview("Create Flow") {
    CreatePatternFlow { _ in }
        .modelContainer(for: Pattern.self, inMemory: true)
}
#endif
