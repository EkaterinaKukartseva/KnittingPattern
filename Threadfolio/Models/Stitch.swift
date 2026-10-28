//
//  Stitch.swift
//  KnittingPattern
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftUI

/// Условное обозначение петли. Рисуется векторно в единичном квадрате,
/// поэтому одинаково чётко выглядит в сетке, палитре и при экспорте.
struct Stitch: Identifiable, Hashable {
    
    enum Style { case stroke, fill, fillCell }

    let id: StitchID
    private let nameResource: LocalizedStringResource
    let craft: Craft
    let style: Style
    /// Строит контур в координатах 0...1 через функцию `p`.
    private let build: (inout Path, (CGFloat, CGFloat) -> CGPoint, CGFloat) -> Void

    init(_ id: StitchID,
         _ name: LocalizedStringResource,
         _ craft: Craft,
         style: Style = .stroke,
         build: @escaping (inout Path, (CGFloat, CGFloat) -> CGPoint, CGFloat) -> Void
    ) {
        self.id = id
        self.nameResource = name
        self.craft = craft
        self.style = style
        self.build = build
    }

    /// Название петли на языке устройства.
    var name: String { String(localized: nameResource) }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    /// Контур символа, вписанный в `rect` (по меньшей стороне, по центру).
    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        let origin = CGPoint(x: rect.midX - side / 2, y: rect.midY - side / 2)
        let p: (CGFloat, CGFloat) -> CGPoint = { x, y in
            CGPoint(x: origin.x + x * side, y: origin.y + y * side)
        }
        var path = Path()
        build(&path, p, side)
        return path
    }

    func draw(in context: inout GraphicsContext, rect: CGRect, color: Color) {
        switch style {
        case .fillCell:
            context.fill(Path(rect), with: .color(Color.noStitch))
        case .fill:
            context.fill(path(in: rect), with: .color(color))
        case .stroke:
            let width = max(1, min(rect.width, rect.height) * 0.08)
            context.stroke(
                path(in: rect), with: .color(color),
                style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
            )
        }
    }
}

// MARK: - Наборы символов

extension Stitch {
    
    static func all(for craft: Craft) -> [Stitch] {
        craft == .crochet ? crochet : knitting
    }

    static func with(id: StitchID?) -> Stitch? {
        guard let id else { return nil }
        return byID[id]
    }

    private static let byID: [StitchID: Stitch] = Dictionary(
        (crochet + knitting).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first }
    )

    private static func line(_ path: inout Path, _ a: CGPoint, _ b: CGPoint) {
        path.move(to: a)
        path.addLine(to: b)
    }

    private static func tee(_ path: inout Path, _ p: (CGFloat, CGFloat) -> CGPoint) {
        line(&path, p(0.28, 0.15), p(0.72, 0.15))
        line(&path, p(0.5, 0.15), p(0.5, 0.88))
    }

    static let crochet: [Stitch] = [
        Stitch(.chain, "Chain", .crochet) { path, p, s in
            path.addEllipse(in: CGRect(origin: p(0.15, 0.33), size: CGSize(width: 0.7 * s, height: 0.34 * s)))
        },
        Stitch(.slipStitch, "Slip stitch", .crochet, style: .fill) { path, p, s in
            path.addEllipse(in: CGRect(origin: p(0.36, 0.36), size: CGSize(width: 0.28 * s, height: 0.28 * s)))
        },
        Stitch(.singleCrochet, "Single crochet", .crochet) { path, p, _ in
            line(&path, p(0.22, 0.22), p(0.78, 0.78))
            line(&path, p(0.78, 0.22), p(0.22, 0.78))
        },
        Stitch(.singleCrochetPlus, "Single crochet (+)", .crochet) { path, p, _ in
            line(&path, p(0.5, 0.15), p(0.5, 0.85))
            line(&path, p(0.15, 0.5), p(0.85, 0.5))
        },
        Stitch(.halfDoubleCrochet, "Half double crochet", .crochet) { path, p, _ in
            tee(&path, p)
        },
        Stitch(.doubleCrochet, "Double crochet", .crochet) { path, p, _ in
            tee(&path, p)
            line(&path, p(0.36, 0.6), p(0.64, 0.44))
        },
        Stitch(.trebleCrochet, "Treble crochet", .crochet) { path, p, _ in
            tee(&path, p)
            line(&path, p(0.36, 0.48), p(0.64, 0.32))
            line(&path, p(0.36, 0.7), p(0.64, 0.54))
        },
        Stitch(.magicRing, "Magic ring", .crochet) { path, p, s in
            path.addEllipse(in: CGRect(origin: p(0.22, 0.22), size: CGSize(width: 0.56 * s, height: 0.56 * s)))
        },
        Stitch(.crochetIncrease, "Increase", .crochet) { path, p, _ in
            path.move(to: p(0.22, 0.15))
            path.addLine(to: p(0.5, 0.85))
            path.addLine(to: p(0.78, 0.15))
        },
        Stitch(.crochetDecrease, "Decrease", .crochet) { path, p, _ in
            path.move(to: p(0.22, 0.85))
            path.addLine(to: p(0.5, 0.15))
            path.addLine(to: p(0.78, 0.85))
        },
        Stitch(.backLoopOnly, "Back loop only", .crochet) { path, p, _ in
            path.move(to: p(0.18, 0.66))
            path.addQuadCurve(to: p(0.82, 0.66), control: p(0.5, 0.08))
        },
        Stitch(.frontLoopOnly, "Front loop only", .crochet) { path, p, _ in
            path.move(to: p(0.18, 0.34))
            path.addQuadCurve(to: p(0.82, 0.34), control: p(0.5, 0.92))
        },
        Stitch(.shell, "Shell", .crochet) { path, p, _ in
            let base = p(0.5, 0.88)
            for x in stride(from: 0.15, through: 0.85, by: 0.175) {
                let top = p(x, 0.22 + abs(0.5 - x) * 0.3)
                line(&path, base, top)
            }
            path.move(to: p(0.15, 0.32))
            path.addQuadCurve(to: p(0.85, 0.32), control: p(0.5, 0.0))
        },
        Stitch(.puff, "Puff stitch", .crochet) { path, p, s in
            path.addEllipse(in: CGRect(origin: p(0.32, 0.12), size: CGSize(width: 0.36 * s, height: 0.76 * s)))
        },
        Stitch(.popcorn, "Popcorn", .crochet, style: .fill) { path, p, s in
            path.addEllipse(in: CGRect(origin: p(0.32, 0.18), size: CGSize(width: 0.36 * s, height: 0.64 * s)))
        },
        Stitch(.picot, "Picot", .crochet) { path, p, s in
            path.addEllipse(in: CGRect(origin: p(0.34, 0.12), size: CGSize(width: 0.32 * s, height: 0.32 * s)))
            line(&path, p(0.5, 0.44), p(0.5, 0.88))
            path.addEllipse(in: CGRect(origin: p(0.44, 0.82), size: CGSize(width: 0.12 * s, height: 0.12 * s)))
        },
        Stitch(.frontPostDoubleCrochet, "Front post double crochet", .crochet) { path, p, _ in
            tee(&path, p)
            line(&path, p(0.36, 0.52), p(0.64, 0.36))
            path.move(to: p(0.5, 0.7))
            path.addQuadCurve(to: p(0.5, 0.95), control: p(0.78, 0.82))
        },
        Stitch(.backPostDoubleCrochet, "Back post double crochet", .crochet) { path, p, _ in
            tee(&path, p)
            line(&path, p(0.36, 0.52), p(0.64, 0.36))
            path.move(to: p(0.5, 0.7))
            path.addQuadCurve(to: p(0.5, 0.95), control: p(0.22, 0.82))
        },
        Stitch(.doubleCrochet2Together, "Double crochet 2 together", .crochet) { path, p, _ in
            path.move(to: p(0.25, 0.88))
            path.addLine(to: p(0.5, 0.15))
            path.addLine(to: p(0.75, 0.88))
            line(&path, p(0.3, 0.55), p(0.42, 0.48))
            line(&path, p(0.58, 0.55), p(0.7, 0.48))
        },
        Stitch(.vStitch, "V-stitch", .crochet) { path, p, _ in
            path.move(to: p(0.18, 0.15))
            path.addLine(to: p(0.5, 0.88))
            path.addLine(to: p(0.82, 0.15))
            line(&path, p(0.26, 0.42), p(0.38, 0.35))
            line(&path, p(0.62, 0.35), p(0.74, 0.42))
        },
    ]

    static let knitting: [Stitch] = [
        Stitch(.knit, "Knit", .knitting) { path, p, _ in
            line(&path, p(0.5, 0.18), p(0.5, 0.82))
        },
        Stitch(.purl, "Purl", .knitting) { path, p, _ in
            line(&path, p(0.18, 0.5), p(0.82, 0.5))
        },
        Stitch(.purlDot, "Purl (dot)", .knitting, style: .fill) { path, p, s in
            path.addEllipse(in: CGRect(origin: p(0.38, 0.38), size: CGSize(width: 0.24 * s, height: 0.24 * s)))
        },
        Stitch(.yarnOver, "Yarn over", .knitting) { path, p, s in
            path.addEllipse(in: CGRect(origin: p(0.26, 0.26), size: CGSize(width: 0.48 * s, height: 0.48 * s)))
        },
        Stitch(.knit2Together, "Knit 2 together (right slant)", .knitting) { path, p, _ in
            line(&path, p(0.22, 0.85), p(0.78, 0.15))
        },
        Stitch(.slipSlipKnit, "Slip, slip, knit (left slant)", .knitting) { path, p, _ in
            line(&path, p(0.22, 0.15), p(0.78, 0.85))
        },
        Stitch(.knit3Together, "Knit 3 together", .knitting) { path, p, _ in
            path.move(to: p(0.2, 0.85))
            path.addLine(to: p(0.5, 0.15))
            path.addLine(to: p(0.8, 0.85))
            line(&path, p(0.5, 0.15), p(0.5, 0.85))
        },
        Stitch(.slipped, "Slipped stitch", .knitting) { path, p, _ in
            path.move(to: p(0.22, 0.18))
            path.addLine(to: p(0.5, 0.82))
            path.addLine(to: p(0.78, 0.18))
        },
        Stitch(.knitThroughBackLoop, "Knit through back loop", .knitting) { path, p, _ in
            path.move(to: p(0.32, 0.88))
            path.addCurve(to: p(0.68, 0.88), control1: p(0.95, 0.0), control2: p(0.05, 0.0))
        },
        Stitch(.makeOne, "Increase", .knitting) { path, p, _ in
            path.move(to: p(0.2, 0.8))
            path.addLine(to: p(0.2, 0.2))
            path.addLine(to: p(0.5, 0.58))
            path.addLine(to: p(0.8, 0.2))
            path.addLine(to: p(0.8, 0.8))
        },
        Stitch(.rightCross, "Right cross", .knitting) { path, p, _ in
            line(&path, p(0.15, 0.85), p(0.85, 0.15))
            line(&path, p(0.15, 0.15), p(0.4, 0.4))
            line(&path, p(0.6, 0.6), p(0.85, 0.85))
        },
        Stitch(.leftCross, "Left cross", .knitting) { path, p, _ in
            line(&path, p(0.15, 0.15), p(0.85, 0.85))
            line(&path, p(0.15, 0.85), p(0.4, 0.6))
            line(&path, p(0.6, 0.4), p(0.85, 0.15))
        },
        Stitch(.bobble, "Bobble", .knitting, style: .fill) { path, p, s in
            path.addEllipse(in: CGRect(origin: p(0.25, 0.25), size: CGSize(width: 0.5 * s, height: 0.5 * s)))
        },
        Stitch(.bindOff, "Bind off", .knitting, style: .fill) { path, p, s in
            path.addEllipse(in: CGRect(origin: p(0.18, 0.36), size: CGSize(width: 0.64 * s, height: 0.28 * s)))
        },
        Stitch(.castOn, "Cast on", .knitting) { path, p, _ in
            line(&path, p(0.5, 0.15), p(0.5, 0.85))
            line(&path, p(0.25, 0.85), p(0.75, 0.85))
        },
        Stitch(.noStitch, "No stitch", .knitting, style: .fillCell) { path, p, s in
            path.addRect(CGRect(origin: p(0.1, 0.1), size: CGSize(width: 0.8 * s, height: 0.8 * s)))
        },
    ]
}

/// Символ петли как SwiftUI-вью — для палитры и легенды.
struct StitchGlyph: View {
    
    let stitch: Stitch
    var color: Color = .ink

    var body: some View {
        Canvas { context, size in
            stitch.draw(in: &context, rect: CGRect(origin: .zero, size: size), color: color)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#if DEBUG
#Preview("All Symbols") {
    ScrollView {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            ForEach(Stitch.crochet + Stitch.knitting) { stitch in
                StitchGlyph(stitch: stitch)
                    .frame(width: 36, height: 36)
                    .padding(6)
                    .background(Color.gridBackground, in: .rect(cornerRadius: 8))
            }
        }
        .padding()
    }
    .background(Color.background)
}
#endif
