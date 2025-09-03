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
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    MetricTile(title: "Turns", value: String(session.metrics.turns), color: .accentColor)
                    MetricTile(title: "Short answers", value: String(session.metrics.shortAnswersCount), color: .orange)
                    MetricTile(title: "Open questions", value: String(session.metrics.openQuestionsCount), color: .blue)
                    MetricTile(title: "Hints shown", value: String(session.metrics.hintsShown), color: .teal)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
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

private struct MetricTile: View {
    let title: String
    let value: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .bold()
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.12))
        )
    }
}
