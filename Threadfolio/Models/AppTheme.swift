//
//  AppTheme.swift
//  KnittingPattern
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftUI

/// Тема оформления, выбранная в профиле. Хранится в UserDefaults.
enum AppTheme: String, CaseIterable, Identifiable {
    
    case system, light, dark

    /// Ключ для `@AppStorage`.
    static let storageKey = "appTheme"

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    /// `nil` — следовать настройке устройства.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
