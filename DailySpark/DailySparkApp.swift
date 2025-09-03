//
//  DailySparkApp.swift
//  DailySpark
//
//  Created by Kanstantsin Ausianovich on 03/09/2025.
//

import SwiftUI
import SwiftData

@main
struct DailySparkApp: App {
    @State private var modelContainer: ModelContainer = {
        let schema = Schema([
            Spark.self,
            TrainingSession.self,
            MicroLesson.self,
            UserSettings.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(modelContainer)
                .onAppear {
                    SeedService.seedIfNeeded(modelContext: modelContainer.mainContext)
                }
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            GeneratorView()
                .tabItem { Label("Generator", systemImage: "sparkles") }
            TrainingSetupView()
                .tabItem { Label("Training", systemImage: "bubble.left.and.text.bubble.right") }
            LibraryView()
                .tabItem { Label("Library", systemImage: "book") }
        }
    }
}
