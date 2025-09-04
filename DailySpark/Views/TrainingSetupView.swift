import SwiftUI

struct TrainingSetupView: View {
    @State private var candidatePersonas: [PersonaOption] = TrainingPresets.randomPersonas()
    @State private var selectedPersona: PersonaOption? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Choose who to chat with") {
                    ForEach(candidatePersonas) { p in
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(p.title).font(.body)
                                Text(p.description).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedPersona?.id == p.id {
                                Image(systemName: "checkmark").foregroundStyle(.tint)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { selectedPersona = p }
                    }
                }

                Section {
                    NavigationLink {
                        TrainingView(scenarioId: selectedPersona?.scenarioId ?? "corporate", personaLabel: (selectedPersona?.title ?? "Partner"))
                    } label: {
                        Text("Start Training")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(selectedPersona == nil)
                }
            }
            .navigationTitle("Training Setup")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await regenerate()
            }
            .onAppear {
                if selectedPersona == nil { selectedPersona = candidatePersonas.first }
            }
        }
    }

    private func regenerate() async {
        await MainActor.run {
            candidatePersonas = TrainingPresets.randomPersonas()
            selectedPersona = candidatePersonas.first
        }
    }
}
