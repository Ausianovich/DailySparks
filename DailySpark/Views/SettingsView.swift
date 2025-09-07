import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query private var settingsList: [UserSettings]

    var body: some View {
        NavigationStack {
            Form {
                Section("Privacy & Storage") {
                    NavigationLink(destination: privacyPolicy()) {
                        Label("Privacy Policy", systemImage: "lock.shield")
                    }
                    NavigationLink(destination: termsOfService()) {
                        Label("License Agreement", systemImage: "doc.plaintext")
                    }
                    Button(role: .destructive) {
                        deleteAllUserData()
                    } label: {
                        Text("Delete All User Data")
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear { ensureSettings() }
        }
    }
    
    @ViewBuilder
    func privacyPolicy() -> some View {
        WebView(url: URL(string: "https://ausianovich.github.io/DailySparksPrivacy/")!)
            .ignoresSafeArea(edges: .bottom)
            .padding(.horizontal)
    }
    
    @ViewBuilder
    func termsOfService() -> some View {
        WebView(url: URL(string: "https://ausianovich.github.io/DailySparksPrivacy/EULA/")!)
            .ignoresSafeArea(edges: .bottom)
            .padding(.horizontal)
    }

    private var currentSettings: UserSettings? { settingsList.first }

    private func ensureSettings() {
        if settingsList.isEmpty {
            let s = UserSettings()
            modelContext.insert(s)
            try? modelContext.save()
        }
    }

    private func deleteAllUserData() {
        do {
            let sparks = try modelContext.fetch(FetchDescriptor<Spark>())
            for s in sparks { modelContext.delete(s) }
            let sessions = try modelContext.fetch(FetchDescriptor<TrainingSession>())
            for s in sessions { modelContext.delete(s) }
            try modelContext.save()
        } catch {
            // No-op: keep UX simple
        }
    }
}
