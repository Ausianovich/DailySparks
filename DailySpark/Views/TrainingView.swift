import SwiftUI
import SwiftData

struct TrainingView: View {
    @State private var input: String = ""
    @State private var transcript: [DialogueTurn] = [
        .init(role: .ai, text: "Hey! How’s your evening going so far?")
    ]
    @State private var isStreaming = false

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(transcript) { turn in
                        HStack(alignment: .top) {
                            Text(prefix(for: turn.role)).font(.caption).foregroundStyle(.secondary).frame(width: 48, alignment: .leading)
                            Text(turn.text).frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }.padding()
            }
            HStack {
                TextField("Type your message…", text: $input)
                    .textFieldStyle(.roundedBorder)
                if isStreaming { ProgressView().scaleEffect(0.8) }
                Button("Send", action: send).disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isStreaming)
            }.padding().background(.ultraThinMaterial)
        }
        .navigationTitle("Training")
    }

    private func prefix(for role: DialogueTurn.Role) -> String { role == .user ? "You" : (role == .ai ? "AI" : "Hint") }

    private func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        input = ""
        transcript.append(.init(role: .user, text: text))
        // Simulated streaming
        isStreaming = true
        let message = "Nice! What’s something you’re looking forward to this week?"
        stream(message)
    }

    private func stream(_ full: String) {
        var idx = 0
        transcript.append(.init(role: .ai, text: ""))
        let aiIndex = transcript.count - 1
        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            guard idx < full.count else { timer.invalidate(); isStreaming = false; return }
            let next = full.prefix(idx + 1)
            transcript[aiIndex].text = String(next)
            idx += 1
        }
    }
}

