//
//  KnittingPatternApp.swift
//  KnittingPattern
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftUI
import SwiftData

@main
struct KnittingPatternApp: App {
    
    @AppStorage(AppTheme.storageKey) private var theme: AppTheme = .system

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Pattern.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            #if DEBUG
            SampleData.seedIfRequested(in: container.mainContext)
            #endif
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(theme.colorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}
