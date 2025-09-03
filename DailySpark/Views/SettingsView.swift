import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = KeychainHelper.loadAPIKey() ?? ""
    @State private var saved = false

    var body: some View {
        NavigationStack {
            Form {
                Section("OpenAI") {
                    SecureField("API Key", text: $apiKey)
                    Button("Save to Keychain") {
                        do {
                            try KeychainHelper.saveAPIKey(apiKey)
                            saved = true
                        } catch {
                            saved = false
                        }
                    }.disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if saved { Text("Saved").font(.caption).foregroundStyle(.secondary) }
                }
            }
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close", action: { dismiss() }) } }
        }
    }
}

