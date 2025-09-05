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
    @State private var errorIsPresented: Bool = false
    @State private var error: Error? = nil
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
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isPresented: Binding(
                get: { !didCompleteOnboarding },
                set: { newValue in didCompleteOnboarding = !newValue; showOnboarding = newValue }
            ))
        }
        .fullScreenCover(isPresented: $showPaywall) {
            SubscriptionStoreView(groupID: "21774164", visibleRelationships: .upgrade) {
                VStack {
                    ZStack {
                        VStack {
                            Image(.group)
                                .resizable()
                                .scaledToFill()
                        }
                        .containerRelativeFrame(.horizontal)
                        .clipped()
                        VStack {
                            Text("Ready for Any Conversation")
                                .font(.largeTitle)
                                .foregroundStyle(.bullets)
                                .multilineTextAlignment(.center)
                                .bold()
                        }
                        .padding()
                    }
                    VStack(alignment: .leading) {
                        ForEach(promotions, id: \.self) { text in
                            HStack(alignment: .top) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.bullets)
                                Text(text)
                                    .multilineTextAlignment(.leading)
                                    .foregroundStyle(Color.promoText)
                            }
                            .font(.title3)
                            .bold()
                        }
                    }
                    .padding(.horizontal, 12.0)
                }
            }
            .storeButton(.hidden, for: .cancellation)
            .storeButton(.visible, for: .restorePurchases)
            .subscriptionStorePolicyForegroundStyle(.white)
            .subscriptionStoreControlStyle(.buttons)
            .subscriptionStoreButtonLabel(.action)
            .background(LinearGradient(colors: [Color.accentColor, .white], startPoint: .top, endPoint: .bottom))
            .tint(Color.bullets)
            .onInAppPurchaseCompletion { product, result in
                switch result {
                case .success(.success):
                    showPaywall = false
                case .failure(let error):
                    self.error = error
                    errorIsPresented = true
                default:
                    break
                }
            }
            .alert(isPresented: $errorIsPresented, content: {
                Alert(title: Text("subscription_error"), message: Text(error?.localizedDescription ?? ""), dismissButton: .cancel(Text("ok"), action: {
                    errorIsPresented = false
                }))
            })
            .interactiveDismissDisabled(true)
        }
        .onAppear {
            // Show onboarding only on first launch or when explicitly reset
            if didCompleteOnboarding == false {
                showOnboarding = true
            } else {
                Task { @MainActor in
                    let hasSub = await SubscriptionService.hasActiveSubscription(groupID: "21774164")
                    if !hasSub { showPaywall = true }
                }
            }
        }
    }
}
