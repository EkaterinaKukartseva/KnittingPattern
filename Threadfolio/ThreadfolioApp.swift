//
//  ThreadfolioApp.swift
//  Threadfolio
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftUI
import SwiftData

@main
struct ThreadfolioApp: App {
    
    @AppStorage(AppTheme.storageKey) private var theme: AppTheme = .system

    var sharedModelContainer: ModelContainer = {
        let schema = Schema(versionedSchema: CurrentSchema.self)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: Self.isUITesting)

        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: PatternMigrationPlan.self,
                configurations: [modelConfiguration]
            )
            #if DEBUG
            SampleData.seedIfRequested(in: container.mainContext)
            #endif
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    /// UI-тесты запускают приложение с `-uiTesting`: каждый тест начинает с пустой базы в памяти.
    private static var isUITesting: Bool {
        #if DEBUG
        CommandLine.arguments.contains("-uiTesting")
        #else
        false
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(theme.colorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}
