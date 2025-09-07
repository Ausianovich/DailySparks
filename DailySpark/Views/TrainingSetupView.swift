import SwiftUI

struct TrainingSetupView: View {
    @State private var candidatePersonas: [PersonaOption] = TrainingPresets.randomPersonas(count: 8)
    @State private var selectedPersona: PersonaOption? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header
                        grid
                        startButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Training Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { Task { await regenerate() } }) {
                        Label("Shuffle", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
            }
            .onAppear {
                if selectedPersona == nil { selectedPersona = candidatePersonas.first }
            }
        }
    }

    private func regenerate() async {
        let newList = TrainingPresets.randomPersonas(count: 8)

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

// MARK: - Subviews
private extension TrainingSetupView {
    var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Who do you want to chat with?")
                .font(.title2.bold())
            Text("Pick a persona to start a realistic practice chat.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    var grid: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(candidatePersonas) { p in
                PersonaCard(persona: p, selected: selectedPersona?.id == p.id) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) { selectedPersona = p }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    var startButton: some View {
        HStack {
            let disabled = (selectedPersona == nil)
            NavigationLink(destination: TrainingView(scenarioId: selectedPersona?.scenarioId ?? "corporate", personaLabel: (selectedPersona?.title ?? "Partner"))) {
                HStack(spacing: 10) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("Start Training")
                        .font(.headline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .opacity(disabled ? 0.6 : 1)
                )
                .clipShape(Capsule())
                .shadow(color: .orange.opacity(disabled ? 0.0 : 0.25), radius: 10, x: 0, y: 6)
            }
            .disabled(disabled)
        }
    }
}

private struct PersonaCard: View {
    let persona: PersonaOption
    var selected: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle().fill(scenarioColor.opacity(0.2))
                        Image(systemName: scenarioIcon)
                            .foregroundStyle(scenarioColor)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(width: 28, height: 28)
                    Text(persona.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                Text(persona.description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selected ? scenarioColor.opacity(0.8) : Color(UIColor.separator).opacity(0.25), lineWidth: selected ? 2 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if selected {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(scenarioColor)
                        .background(Circle().fill(Color(UIColor.secondarySystemGroupedBackground)))
                        .offset(x: 6, y: -6)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var scenarioIcon: String { persona.scenarioId == "corporate" ? "briefcase.fill" : "heart.fill" }
    private var scenarioColor: Color { persona.scenarioId == "corporate" ? .blue : .pink }
}
