//
//  CellColor.swift
//  Threadfolio
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftUI

/// Базовая палитра редактора. Каждый цвет — из Assets, со своим вариантом для тёмной темы.
nonisolated enum PaletteColor: String, CaseIterable, Codable {
    
    case ink, gray, blue, pink, green, beige

    @MainActor var color: Color {
        switch self {
        case .ink: .ink
        case .gray: .paletteGray
        case .blue: .paletteBlue
        case .pink: .palettePink
        case .green: .paletteGreen
        case .beige: .paletteBeige
        }
    }

    /// Название цвета для легенды ниток.
    var title: String {
        switch self {
        case .ink: String(localized: "Black")
        case .gray: String(localized: "Gray")
        case .blue: String(localized: "Blue")
        case .pink: String(localized: "Pink")
        case .green: String(localized: "Green")
        case .beige: String(localized: "Beige")
        }
    }
}

/// Цвет символа или фона клетки: цвет палитры (по имени из Assets)
/// или свой цвет — выбранный пользователем или взятый с фото.
nonisolated enum CellColor: Hashable, Codable {
    
    case palette(PaletteColor)
    case custom(Color.Resolved)

    static let `default` = Self.palette(.ink)

    @MainActor var color: Color {
        switch self {
        case .palette(let palette): palette.color
        case .custom(let resolved): Color(resolved)
        }
    }

    var title: String {
        switch self {
        case .palette(let palette): palette.title
        case .custom: String(localized: "Custom color")
        }
    }

    // Компактная запись в схеме: цвет палитры — строкой ("blue"),
    // свой цвет — массивом компонентов sRGB [r, g, b].
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let name = try? container.decode(PaletteColor.self) {
            self = .palette(name)
        } else {
            let rgb = try container.decode([Float].self)
            guard rgb.count == 3 else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected 3 color components")
            }
            self = .custom(Color.Resolved(red: rgb[0], green: rgb[1], blue: rgb[2]))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .palette(let name):
            try container.encode(name)
        case .custom(let resolved):
            try container.encode([resolved.red, resolved.green, resolved.blue])
        }
    }
}
