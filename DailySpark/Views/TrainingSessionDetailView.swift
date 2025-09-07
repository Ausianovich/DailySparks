import SwiftUI

struct TrainingSessionDetailView: View {
    let session: TrainingSession

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Summary
                    HStack(alignment: .center, spacing: 12) {
                        ZStack {
                            Circle().fill((session.scenario == "corporate" ? Color.blue : Color.pink).opacity(0.2))
                            Image(systemName: iconName).foregroundStyle(session.scenario == "corporate" ? .blue : .pink)
                        }
                        .frame(width: 36, height: 36)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(summaryTitle)
                                .font(.headline)
                            Text(dateString(session.startedAt))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.secondarySystemGroupedBackground)))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(UIColor.separator).opacity(0.25)))

                    // Metrics
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Metrics").font(.title2.bold())
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            MetricTile(title: "Turns", value: String(session.metrics.turns), color: .orange)
                            MetricTile(title: "Short answers", value: String(session.metrics.shortAnswersCount), color: .pink)
                            MetricTile(title: "Open questions", value: String(session.metrics.openQuestionsCount), color: .blue)
                            MetricTile(title: "Hints shown", value: String(session.metrics.hintsShown), color: .teal)
                        }
                    }

                    // Feedback
                    if let fb = session.feedback {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Feedback").font(.title2.bold())
                            VStack(alignment: .leading, spacing: 8) {
                                if !fb.strengths.isEmpty {
                                    ForEach(fb.strengths, id: \.self) { s in
                                        HStack(spacing: 8) {
                                            Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                                            Text(s)
                                        }
                                    }
                                }
                                HStack(spacing: 8) {
                                    Image(systemName: "lightbulb.fill").foregroundStyle(.yellow)
                                    Text(fb.suggestion)
                                }
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.secondarySystemGroupedBackground)))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(UIColor.separator).opacity(0.25)))
                        }
                    }

                    // Transcript
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Transcript").font(.title2.bold())
                        VStack(spacing: 10) {
                            ForEach(Array(session.transcript.enumerated()), id: \.element.id) { index, turn in
                                let isUser = (turn.role == .user)
                                let prevRole: DialogueTurn.Role? = index > 0 ? session.transcript[index-1].role : nil
                                let showName = prevRole != turn.role
                                ChatBubbleRow(text: turn.text, isUser: isUser, name: prefix(for: turn.role), showName: showName)
                            }
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.secondarySystemGroupedBackground)))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(UIColor.separator).opacity(0.25)))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summaryTitle: String {
        if let p = session.personaLabel { return "\(session.scenario.capitalized): \(p)" }
        return session.scenario.capitalized
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
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(
                        Group {
                            if isUser {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                            } else {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                            }
                        }
                    )
                    .overlay(
                        Group { if !isUser { RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color(UIColor.separator).opacity(0.25)) } }
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
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(color.opacity(0.35))
        )
    }
}

