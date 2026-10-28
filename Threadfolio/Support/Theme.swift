//
//  Theme.swift
//  KnittingPattern
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftUI

/// Карточка-кнопка в стиле макета: светлая плашка, розовая при выборе.
struct SelectableCard<Content: View>: View {
    
    var isSelected: Bool
    var action: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        Button(action: action) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isSelected ? .selected : .card, in: .rect(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(isSelected ? .selectedBorder : .cardBorder, lineWidth: 1)
                }
                .contentShape(.rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.accent.opacity(configuration.isPressed ? 0.8 : 1), in: .capsule)
    }
}

extension View {
    
    /// Заголовок навигации по центру (на iOS — inline). Строковый литерал переводится.
    func inlineNavigationTitle(_ title: LocalizedStringKey) -> some View {
        navigationTitle(title)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    /// То же для данных пользователя (например, названия схемы) — без перевода.
    @_disfavoredOverload
    func inlineNavigationTitle<S: StringProtocol>(_ title: S) -> some View {
        navigationTitle(title)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#if DEBUG
#Preview("Cards and Button") {
    @Previewable @State var selected = 0
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            ForEach(0..<2) { index in
                SelectableCard(isSelected: selected == index, action: { selected = index }) {
                    Text(index == 0 ? "Crochet" : "Knitting").foregroundStyle(.ink)
                }
                .frame(height: 90)
            }
        }
        Button("Continue") {}
            .buttonStyle(PrimaryButtonStyle())
    }
    .padding()
    .background(Color.background)
}
#endif
