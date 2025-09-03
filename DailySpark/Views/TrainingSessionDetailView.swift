import SwiftUI

struct TrainingSessionDetailView: View {
    let session: TrainingSession

    var body: some View {
        List {
            Section("Summary") {
                HStack {
                    Label(session.scenario.capitalized, systemImage: iconName)
                    Spacer()
                    Text(dateString(session.startedAt)).foregroundStyle(.secondary)
                }
                if let p = session.personaLabel { Text("Persona: \(p)") }
            }

            Section("Metrics") {
                HStack { Text("Turns"); Spacer(); Text("\(session.metrics.turns)").foregroundStyle(.secondary) }
                HStack { Text("Short answers"); Spacer(); Text("\(session.metrics.shortAnswersCount)").foregroundStyle(.secondary) }
                HStack { Text("Open questions"); Spacer(); Text("\(session.metrics.openQuestionsCount)").foregroundStyle(.secondary) }
                HStack { Text("Hints shown"); Spacer(); Text("\(session.metrics.hintsShown)").foregroundStyle(.secondary) }
            }

            if let fb = session.feedback {
                Section("Feedback") {
                    if !fb.strengths.isEmpty {
                        ForEach(fb.strengths, id: \.self) { Text($0) }
                    }
                    Text(fb.suggestion)
                }
            }

            Section("Transcript") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(session.transcript, id: \.id) { turn in
                        HStack(alignment: .top, spacing: 8) {
                            Text(prefix(for: turn.role)).font(.caption).foregroundStyle(.secondary).frame(width: 48, alignment: .leading)
                            Text(MarkdownHelper.attributed(from: turn.text))
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(turn.role == .user ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.12)))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            }
        }
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var iconName: String { session.scenario == "corporate" ? "briefcase" : "heart" }
    private func dateString(_ d: Date) -> String {
        let df = DateFormatter(); df.dateStyle = .medium; df.timeStyle = .short; return df.string(from: d)
    }
    private func prefix(for role: DialogueTurn.Role) -> String { role == .user ? "You" : (role == .ai ? "AI" : "Hint") }
}

