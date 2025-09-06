import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [UserSettings]

    var body: some View {
        NavigationStack {
            Form {
                Section("Privacy & Storage") {
                    Button(role: .destructive) {
                        deleteAllUserData()
                    } label: {
                        Text("Delete All User Data")
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close", action: { dismiss() }) } }
            .onAppear { ensureSettings() }
        }
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
