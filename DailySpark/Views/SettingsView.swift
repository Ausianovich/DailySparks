import SwiftUI
import SwiftData
import SafariServices

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query private var settingsList: [UserSettings]
    
    @State private var privacyIsPresented: Bool = false
    @State private var termsIsPresented: Bool = false
    @State private var successRemoveDataIsPresented: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Privacy & Storage") {
                    Button {
                        privacyIsPresented = true
                    } label: {
                        Label("Privacy Policy", systemImage: "lock.shield")
                    }
                    
                    Button {
                        termsIsPresented = true
                    } label: {
                        Label("License Agreement", systemImage: "doc.plaintext")
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        deleteAllUserData()
                    } label: {
                        Label("Delete User History", systemImage: "trash")
                            .foregroundStyle(Color(.systemRed))
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear { ensureSettings() }
            .sheet(isPresented: $privacyIsPresented) { privacyPolicy() }
            .sheet(isPresented: $termsIsPresented) { termsOfService() }
            .alert("All user history has been deleted", isPresented: $successRemoveDataIsPresented) {
                Button("OK") {
                    successRemoveDataIsPresented = false
                }
            }
        }
    }
    
    @ViewBuilder
    func privacyPolicy() -> some View {
        SafariView(url: URL(string: "https://ausianovich.github.io/DailySparksPrivacy/")!)
    }
    
    @ViewBuilder
    func termsOfService() -> some View {
        SafariView(url: URL(string: "https://ausianovich.github.io/DailySparksPrivacy/EULA/")!)
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
            
            successRemoveDataIsPresented = true
        } catch {
            // No-op: keep UX simple
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
  let url: URL
  func makeUIViewController(context: Context) -> SFSafariViewController {
    let config = SFSafariViewController.Configuration()
    config.entersReaderIfAvailable = false
    let vc = SFSafariViewController(url: url, configuration: config)
    vc.preferredControlTintColor = .label // опционально
    return vc
  }
  func updateUIViewController(_ vc: SFSafariViewController, context: Context) {}
}
