//
//  StickyFooter.swift
//  KnittingPattern
//
//  Created by Ekaterina on 27.10.2026.
//

import SwiftUI

/// Нижняя панель, закреплённая над прокручиваемым содержимым экрана.
/// Непрозрачная подложка не даёт форме просвечивать под кнопкой
/// (заметно на низких экранах, например iPhone Duo).
struct StickyFooter<Content: View>: View {

    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background {
                Color.background
                    .shadow(color: .black.opacity(0.06), radius: 6, y: -2)
                    .ignoresSafeArea(edges: [.bottom, .horizontal])
            }
    }
}

extension View {

    /// Закрепляет `content` внизу экрана в `StickyFooter`.
    func stickyFooter<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        safeAreaInset(edge: .bottom) {
            StickyFooter(content: content)
        }
    }
}

#if DEBUG
#Preview("Над прокруткой") {
    NavigationStack {
        List(1...30, id: \.self) { index in
            Text(verbatim: "Row \(index)")
        }
        .scrollContentBackground(.hidden)
        .background(Color.background)
        .stickyFooter {
            Button("Continue") {}
                .buttonStyle(PrimaryButtonStyle())
        }
    }
}

#Preview("Отдельно") {
    VStack {
        Spacer()
        StickyFooter {
            Button("Create") {}
                .buttonStyle(PrimaryButtonStyle())
        }
    }
    .background(Color.background)
}
#endif
