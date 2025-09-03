import SwiftUI
import SwiftData

struct TrainingView: View {
    @State private var input: String = ""
    @FocusState private var inputFocused: Bool
    @State private var transcript: [DialogueTurn] = [
        .init(role: .ai, text: "Hey! How’s your evening going so far?")
    ]
    @State private var isStreaming = false
    @State private var errorMessage: String?

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(transcript.reversed()) { turn in
                            ChatMessageRow(prefix: prefix(for: turn.role), text: turn.text)
                                .id(turn.id)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .scaleEffect(x: 1, y: -1)
                .onAppear {
                    if let last = transcript.last?.id { proxy.scrollTo(last, anchor: .bottom) }
                }
                .onChange(of: transcript.count) { _ in
                    if let last = transcript.last?.id {
                        withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(last, anchor: .bottom) }
                    }
                }
            }
            HStack {
                TextField("Type your message…", text: $input)
                    .textFieldStyle(.roundedBorder)
                    .focused($inputFocused)
                    .submitLabel(.send)
                    .onSubmit { send() }
                if isStreaming { ProgressView().scaleEffect(0.8) }
                Button("Send", action: send).disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isStreaming)
            }.padding().background(.ultraThinMaterial)
        }
        .navigationTitle("Training")
        .alert("Error", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK") { errorMessage = nil }
        }, message: { Text(errorMessage ?? "") })
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy, animated: Bool = true) {
        if animated {
            withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("BOTTOM", anchor: .bottom) }
        } else {
            proxy.scrollTo("BOTTOM", anchor: .bottom)
        }
    }

    private func prefix(for role: DialogueTurn.Role) -> String { role == .user ? "You" : (role == .ai ? "AI" : "Hint") }

    private func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        input = ""
        inputFocused = true
        transcript.append(.init(role: .user, text: text))
        isStreaming = true
        streamFromAI()
    }

    private func streamFromAI() {
        // Use transcript context before adding the empty AI turn
        let contextTranscript = transcript
        transcript.append(.init(role: .ai, text: ""))
        let aiIndex = transcript.count - 1
        errorMessage = nil
        Task {
            let persona = "Colleague from another department, friendly and curious"
            let context = "Corporate mixer"
            do {
                let stream = AIClient.shared.streamTrainingReply(persona: persona, context: context, transcript: contextTranscript)
                for try await delta in stream {
                    await MainActor.run {
                        transcript[aiIndex].text.append(delta)
                    }
                }
            } catch {
                await MainActor.run { errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription }
            }
            await MainActor.run { isStreaming = false }
        }
    }
}

private struct ChatMessageRow: View {
    let prefix: String
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(prefix)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .leading)
            Text(MarkdownHelper.attributed(from: text))
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(.secondary.opacity(0.15)))
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        .scaleEffect(x: 1, y: -1)
    }
}
