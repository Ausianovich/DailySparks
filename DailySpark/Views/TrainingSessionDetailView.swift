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
                VStack(spacing: 10) {
                    ForEach(Array(session.transcript.enumerated()), id: \.element.id) { index, turn in
                        let isUser = (turn.role == .user)
                        let prevRole: DialogueTurn.Role? = index > 0 ? session.transcript[index-1].role : nil
                        let showName = prevRole != turn.role
                        ChatBubbleRow(text: turn.text, isUser: isUser, name: prefix(for: turn.role), showName: showName)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowSeparator(.hidden)
                    }
                }
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

private struct ChatBubbleRow: View {
    let text: String
    let isUser: Bool
    let name: String
    let showName: Bool

    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
            if showName {
                Text(name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
            }
            HStack {
                if isUser { Spacer(minLength: 40) }
                Text(MarkdownHelper.attributed(from: text))
                    .font(.body)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isUser ? Color.accentColor : Color.secondary.opacity(0.15))
                    )
                    .foregroundStyle(isUser ? Color.white : Color.primary)
                    .contextMenu {
                        Button(action: { copy(text) }) { Label("Copy", systemImage: "doc.on.doc") }
                        ShareLink(item: text) { Label("Share", systemImage: "square.and.arrow.up") }
                    }
                if !isUser { Spacer(minLength: 40) }
            }
        }
        .padding(.horizontal, 6)
    }

    private func copy(_ s: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = s
        #endif
    }
}
