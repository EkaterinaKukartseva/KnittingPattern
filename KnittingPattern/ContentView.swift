//
//  ContentView.swift
//  KnittingPattern
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftUI
import SwiftData

/// Навигация приложения: вкладки, стек библиотеки и окно создания схемы.
@Observable
final class AppRouter {
    enum Tab: Hashable { case patterns, create, legend, profile }

    var selectedTab: Tab = .patterns
    var libraryPath = NavigationPath()
    var isCreating = false

    func open(_ pattern: Pattern) {
        selectedTab = .patterns
        libraryPath = NavigationPath()
        libraryPath.append(pattern)
    }
}

struct ContentView: View {
    @State private var router = AppRouter()

    var body: some View {
        // Вкладка «Создать» не переключает экран, а открывает мастер создания.
        let tabSelection = Binding<AppRouter.Tab>(
            get: { router.selectedTab },
            set: { tab in
                if tab == .create {
                    router.isCreating = true
                } else {
                    router.selectedTab = tab
                }
            }
        )

        TabView(selection: tabSelection) {
            SwiftUI.Tab("Charts", systemImage: "house", value: AppRouter.Tab.patterns) {
                NavigationStack(path: $router.libraryPath) {
                    LibraryView()
                        .navigationDestination(for: Pattern.self) { pattern in
                            EditorView(pattern: pattern)
                        }
                }
            }
            SwiftUI.Tab("Create", systemImage: "plus.square", value: AppRouter.Tab.create) {
                Color.clear
            }
            SwiftUI.Tab("Symbols", systemImage: "book.closed", value: AppRouter.Tab.legend) {
                NavigationStack { LegendView() }
            }
            SwiftUI.Tab("Profile", systemImage: "person", value: AppRouter.Tab.profile) {
                NavigationStack { ProfileView() }
            }
        }
        .tint(Color.accentDark)
        .environment(router)
        .sheet(isPresented: $router.isCreating) {
            CreatePatternFlow { pattern in
                router.isCreating = false
                router.open(pattern)
            }
        }
    }
}

#if DEBUG
#Preview("Со схемами") {
    ContentView()
        .modelContainer(SampleData.previewContainer)
}

#Preview("Пустая библиотека") {
    ContentView()
        .modelContainer(for: Pattern.self, inMemory: true)
}
#endif
