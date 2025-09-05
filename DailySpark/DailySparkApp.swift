//
//  DailySparkApp.swift
//  DailySpark
//
//  Created by Kanstantsin Ausianovich on 03/09/2025.
//

import SwiftUI
import SwiftData
import StoreKit

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
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding: Bool = false
    @State private var showOnboarding: Bool = false
    @State private var showPaywall: Bool = false
    @Environment(\.scenePhase) var phase
    
    @State private var subscriptionsObserver = SubscriptionsObserver()
    var body: some View {
        TabView {
            GeneratorView()
                .tabItem { Label("Generator", systemImage: "sparkles") }
            TrainingSetupView()
                .tabItem { Label("Training", systemImage: "bubble.left.and.text.bubble.right") }
            LibraryView()
                .tabItem { Label("Library", systemImage: "book") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .onChange(of: phase) { _, new in
            if new == .active {
                Task { @MainActor in
                    await subscriptionsObserver.updateStatuses()
                    showPaywall = subscriptionsObserver.disabled
                }
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isPresented: Binding(
                get: { !didCompleteOnboarding },
                set: { newValue in didCompleteOnboarding = !newValue; showOnboarding = newValue }
            ))
        }
        .onChange(of: subscriptionsObserver.disabled, { oldValue, newValue in
            guard newValue else { return }
            showPaywall = subscriptionsObserver.disabled
        })
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView {
                showPaywall = false
            }
        }
    }
}
