import SwiftUI

struct TrainingSetupView: View {
    @State private var candidatePersonas: [PersonaOption] = TrainingPresets.randomPersonas(count: 7)
    @State private var selectedPersona: PersonaOption? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Choose who to chat with") {
                    ForEach(candidatePersonas) { p in
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(p.title)
                                    .font(.body)
                                    .contentTransition(.opacity)
                                Text(p.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .contentTransition(.opacity)
                            }
                            Spacer()
                            if selectedPersona?.id == p.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { selectedPersona = p }
                        .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity),
                                                removal: .opacity))
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
            .refreshable { await regenerate() }
            .onAppear {
                if selectedPersona == nil { selectedPersona = candidatePersonas.first }
            }
        }
    }

    private func regenerate() async {
        let newList = TrainingPresets.randomPersonas(count: 7)

        // 1) Animate removal of all rows and clear selection
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.2)) {
                candidatePersonas.removeAll()
                selectedPersona = nil
            }
        }

        // 2) Staggered insertion one-by-one without selection
        for item in newList {
            try? await Task.sleep(nanoseconds: 80_000_000) // 80ms between inserts
            await MainActor.run {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.2)) {
                    candidatePersonas.append(item)
                }
            }
        }

        // 3) After insert animations settle, select the first item
        try? await Task.sleep(nanoseconds: 360_000_000)
        await MainActor.run {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.9, blendDuration: 0.1)) {
                selectedPersona = candidatePersonas.first
            }
        }
    }
}
