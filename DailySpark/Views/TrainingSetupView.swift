import SwiftUI

struct TrainingSetupView: View {
    @State private var selectedScenarioId: String = TrainingPresets.scenarios.first?.id ?? "corporate"
    @State private var selectedPersona: PersonaOption? = TrainingPresets.personas(for: TrainingPresets.scenarios.first?.id ?? "corporate").first

    var body: some View {
        NavigationStack {
            Form {
                Section("Scenario") {
                    Picker("Scenario", selection: $selectedScenarioId) {
                        ForEach(TrainingPresets.scenarios) { s in
                            Text(s.title).tag(s.id)
                        }
                    }
                    .pickerStyle(.segmented)
                    if let scenario = TrainingPresets.scenarios.first(where: { $0.id == selectedScenarioId }) {
                        Text(scenario.description).font(.footnote).foregroundStyle(.secondary)
                    }
                }

                Section("Persona") {
                    let options = TrainingPresets.personas(for: selectedScenarioId)
                    ForEach(options) { p in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(p.title).font(.body)
                                Text(p.description).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedPersona?.id == p.id {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { selectedPersona = p }
                    }
                }

                Section {
                    NavigationLink {
                        TrainingView(scenarioId: selectedScenarioId, personaLabel: (selectedPersona?.title ?? "Partner"))
                    } label: {
                        Text("Start Training")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(selectedPersona == nil)
                }
            }
            .navigationTitle("Training Setup")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedScenarioId) { newValue in
                // Reset persona to first of the selected scenario
                selectedPersona = TrainingPresets.personas(for: newValue).first
            }
        }
    }
}
