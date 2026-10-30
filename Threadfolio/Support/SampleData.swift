//
//  SampleData.swift
//  Threadfolio
//
//  Created by Ekaterina on 26.10.2026.
//

#if DEBUG
import Foundation
import SwiftData

/// Демо-схемы для проверки вёрстки и превью. В приложении — запуск с аргументом `-seedSamples YES`.
enum SampleData {
    
    /// Хранилище в памяти с демо-схемами — для `#Preview`.
    static let previewContainer: ModelContainer = {
        do {
            let container = try ModelContainer(
                for: Pattern.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            for pattern in samples() { container.mainContext.insert(pattern) }
            return container
        } catch {
            fatalError("Could not create the preview container: \(error)")
        }
    }()

    /// Схема из `previewContainer` — для превью экранов одной схемы.
    static var previewPattern: Pattern {
        let descriptor = FetchDescriptor<Pattern>(sortBy: [SortDescriptor(\.name)])
        let patterns = (try? previewContainer.mainContext.fetch(descriptor)) ?? []
        return patterns.first { $0.craft == .crochet } ?? heart()
    }

    static func samples() -> [Pattern] {
        let favorite = heart(name: "Little Heart (favorite)")
        favorite.isFavorite = true
        favorite.notes = "Stopped at row 12"
        return [heart(), knitStripes(), favorite, crossStitchFlower()]
    }

    static func seedIfRequested(in context: ModelContext) {
        guard UserDefaults.standard.bool(forKey: "seedSamples") else { return }
        let existing = (try? context.fetchCount(FetchDescriptor<Pattern>())) ?? 0
        guard existing == 0 else { return }
        for pattern in samples() { context.insert(pattern) }
    }

    static func heart(name: String = "Heart") -> Pattern {
        let rows = [
            "..XX...XX..",
            ".XXXX.XXXX.",
            "XXXXXXXXXXX",
            "XXXXXXXXXXX",
            ".XXXXXXXXX.",
            "..XXXXXXX..",
            "...XXXXX...",
            "....XXX....",
            ".....X.....",
        ]
        let columns = 20, height = 20
        var cells = Array(repeating: Cell.empty, count: columns * height)
        for (r, line) in rows.enumerated() {
            for (c, char) in line.enumerated() where char == "X" {
                let color = CellColor.palette(c < 5 ? .blue : .pink)
                cells[(r + 5) * columns + c + 4] = Cell(symbol: .singleCrochet, color: color)
            }
        }
        let pattern = Pattern(name: name, craft: .crochet, columns: columns, rows: height, cells: cells)
        pattern.summary = "Cotton 50 g, 3 mm hook"
        return pattern
    }

    static func knitStripes() -> Pattern {
        let columns = 16, rows = 24
        let cells = (0..<(columns * rows)).map { index -> Cell in
            let row = index / columns
            return Cell(symbol: row % 4 < 2 ? .knit : .purl, background: row % 8 < 4 ? nil : .palette(.green))
        }
        return Pattern(name: "Striped Rib", craft: .knitting, columns: columns, rows: rows,
                       cells: cells)
    }

    /// Цветок для вышивки: лепестки, стебель и узелок в середине.
    static func crossStitchFlower() -> Pattern {
        let rows = [
            "...PPP.PPP...",
            "..PPPPPPPPP..",
            "..PPPPOPPPP..",
            "...PPPPPPP...",
            "....PPPPP....",
            "......G......",
            "..GG..G..GG..",
            "...GG.G.GG...",
            ".....GGG.....",
            "......G......",
        ]
        let columns = 13, height = 12
        var cells = Array(repeating: Cell.empty, count: columns * height)
        for (r, line) in rows.enumerated() {
            for (c, char) in line.enumerated() {
                let index = (r + 1) * columns + c
                switch char {
                case "P": cells[index] = Cell(symbol: .fullCross, color: .palette(.pink))
                case "G": cells[index] = Cell(symbol: .fullCross, color: .palette(.green))
                case "O": cells[index] = Cell(symbol: .frenchKnot, color: .palette(.beige))
                default: break
                }
            }
        }
        let pattern = Pattern(name: "Flower", craft: .crossStitch, columns: columns, rows: height, cells: cells)
        pattern.summary = "Aida 14, DMC floss"
        return pattern
    }
}
#endif
