import SwiftUI
import SwiftData

struct TrainingView: View {
    let scenarioId: String
    let personaLabel: String
    @State private var input: String = ""
    @FocusState private var inputFocused: Bool
    @State private var transcript: [DialogueTurn] = []
    @State private var isStreaming = false
    @State private var errorMessage: String?
    @State private var metrics = TrainingMetrics()
    @State private var showEndSheet = false
    @State private var isEnding = false
    @State private var isRepairLoading = false
    @State private var feedback: FeedbackSummary? = nil
    @State private var suggestedLesson: MicroLesson? = nil
    @State private var recentRepairs: [String] = []
    @State private var streamBuffer: String = ""
    @State private var lastStreamFlush: Date = .now
    @State private var streamTask: Task<Void, Never>? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(transcript.reversed()) { turn in
                            let isUser = (turn.role == .user)
                            let isLastAIRow = (turn.role == .ai && turn.id == transcript.last?.id)
                            let thinking = isStreaming && isLastAIRow && turn.text.isEmpty
                            let useMarkdown = !(isStreaming && isLastAIRow)
                            ChatMessageRow(isUser: isUser, text: turn.text, isThinking: thinking, useMarkdown: useMarkdown)
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
                .contentShape(Rectangle())
                .onTapGesture { inputFocused = false }
            }
            // Repair Kit (above input)
            HStack(spacing: 8) {
                RepairChip(title: "Rephrase", recommended: recommendedRepair() == .rephrase) { repair(.rephrase) }
                    .disabled(isStreaming || isRepairLoading)
                RepairChip(title: "Pivot", recommended: recommendedRepair() == .pivot) { repair(.pivot) }
                    .disabled(isStreaming || isRepairLoading)
                RepairChip(title: "Open Q", recommended: recommendedRepair() == .open) { repair(.open) }
                    .disabled(isStreaming || isRepairLoading)
                if isRepairLoading { ProgressView().scaleEffect(0.8) }
            }
            .padding(.horizontal)

            HStack(alignment: .center, spacing: 8) {
                TextField("Type your message…", text: $input, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(2)
                    .padding(8)
                    .background(
                        Capsule()
                            .stroke(.accent, lineWidth: 1)
                    )
                    .focused($inputFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .submitLabel(.return) // show Return, not Send; Return inserts newline

                // Right action button: Stop (streaming) / Retry (error) / Send (idle)
                if isStreaming {
                    Button(action: cancelStream) {
                        Image(systemName: "stop.circle")
                            .foregroundStyle(.red)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .accessibilityLabel("Stop")
                } else if errorMessage != nil {
                    Button(action: retryStream) {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundStyle(.accent)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .accessibilityLabel("Retry")
                } else {
                    Button(action: send) {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(.accent)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel("Send")
                }
            }
            .padding()
        }
        .navigationTitle("Training")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK") { errorMessage = nil }
        }, message: { Text(errorMessage ?? "") })
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("End") { endSession() }
                    .disabled(isStreaming || isEnding || transcript.filter { $0.role == .user }.isEmpty)
            }
        }
        .sheet(isPresented: $showEndSheet) {
            // Check permission to save
            let canSave: Bool = {
                let fetch = FetchDescriptor<UserSettings>(predicate: #Predicate { _ in true })
                return (try? modelContext.fetch(fetch).first?.storeTranscripts) ?? false
            }()
            if let fb = feedback {
                SessionEndView(feedback: fb, suggestedLesson: suggestedLesson, canSave: canSave, onSave: {
                    saveSession()
                    showEndSheet = false
                    dismiss()
                }, onClose: {
                    showEndSheet = false
                    dismiss()
                })
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            } else {
                NavigationStack {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Preparing summary…").font(.caption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .navigationTitle("Summary")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        .onChange(of: showEndSheet) { open in
            // If user closed the summary sheet after it was shown, exit training view
            if open == false, feedback != nil { dismiss() }
        }
        .onAppear {
            // Occasionally let AI open; otherwise focus input for the user to start
            if transcript.isEmpty && !isStreaming {
                if Bool.random() {
                    isStreaming = true
                    streamFromAI()
                } else {
                    inputFocused = true
                }
            }
        }
        .onDisappear {
            // Ensure we stop any in-flight stream when leaving the screen
            cancelStream()
        }
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
        metrics.turns += 1
        if text.split(separator: " ").count <= 4 { metrics.shortAnswersCount += 1 }
        if text.contains("?") || matchesOpenPrefix(text) { metrics.openQuestionsCount += 1 }
        isStreaming = true
        streamFromAI()
    }

    private func streamFromAI() {
        // If there is a pending empty AI turn from a previous attempt, remove it first
        if hasPendingEmptyAITurn {
            _ = transcript.popLast()
        }
        // Use transcript context before adding the empty AI turn
        let contextTranscript = transcript
        transcript.append(.init(role: .ai, text: ""))
        let aiIndex = transcript.count - 1
        errorMessage = nil
        streamTask?.cancel()
        streamTask = Task { [contextTranscript] in
            let persona = personaLabel
            let context = scenarioId == "corporate" ? "Corporate mixer" : "Light first date"
            do {
                let stream = AIClient.shared.streamTrainingReply(persona: persona, context: context, transcript: contextTranscript)
                for try await delta in stream {
                    // Throttle UI updates: buffer small deltas, flush at ~20Hz
                    streamBuffer.append(delta)
                    let now = Date()
                    if now.timeIntervalSince(lastStreamFlush) > 0.05 || streamBuffer.count > 24 {
                        let chunk = streamBuffer
                        streamBuffer.removeAll(keepingCapacity: true)
                        lastStreamFlush = now
                        await MainActor.run {
                            transcript[aiIndex].text.append(contentsOf: chunk)
                        }
                    }
                }
                // Flush remainder
                if !streamBuffer.isEmpty {
                    let chunk = streamBuffer
                    streamBuffer.removeAll(keepingCapacity: true)
                    await MainActor.run { transcript[aiIndex].text.append(contentsOf: chunk) }
                }
            } catch {
                if (error as? CancellationError) == nil {
                    await MainActor.run { errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription }
                }
            }
            await MainActor.run { isStreaming = false }
        }
    }

    private enum RepairKind { case rephrase, pivot, open }

    private func recommendedRepair() -> RepairKind {
        if metrics.openQuestionsCount == 0 || metrics.shortAnswersCount >= 2 { return .open }
        return .pivot
    }

    private func repair(_ kind: RepairKind) {
        guard !isStreaming else { return }
        isRepairLoading = true
        let kindString: String = {
            switch kind { case .rephrase: return "rephrase"; case .pivot: return "pivot"; case .open: return "open" }
        }()
        Task {
            do {
                // Build avoid list from recent transcript and past repairs
                let avoid = buildAvoidList()
                var suggestion = try await AIClient.shared.generateRepairSuggestion(kind: kindString, transcript: transcript, avoid: avoid)
                // Deduplicate client-side (simple normalization)
                if isDuplicateSuggestion(suggestion) {
                    // One retry with extra avoid
                    let extraAvoid = avoid + [suggestion]
                    suggestion = try await AIClient.shared.generateRepairSuggestion(kind: kindString, transcript: transcript, avoid: extraAvoid)
                }
                await MainActor.run {
                    self.input = suggestion
                    self.inputFocused = true
                    self.isRepairLoading = false
                    self.recentRepairs.append(suggestion)
                    if self.recentRepairs.count > 6 { self.recentRepairs.removeFirst(self.recentRepairs.count - 6) }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    self.isRepairLoading = false
                }
            }
        }
    }

    private func buildAvoidList() -> [String] {
        let recentTurns = transcript.suffix(10).map { $0.text }
        let current = input.isEmpty ? [] : [input]
        return Array((recentTurns + current + recentRepairs).suffix(10))
    }

    private func isDuplicateSuggestion(_ s: String) -> Bool {
        let normS = normalize(s)
        if normS.isEmpty { return true }
        // Check against transcript and recent repairs
        if transcript.suffix(12).map({ normalize($0.text) }).contains(normS) { return true }
        if recentRepairs.map({ normalize($0) }).contains(normS) { return true }
        if normalize(input) == normS { return true }
        return false
    }

    private func normalize(_ s: String) -> String {
        let lowered = s.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = lowered.unicodeScalars.filter { CharacterSet.alphanumerics.union(CharacterSet.whitespaces).contains($0) }
        let compact = String(String.UnicodeScalarView(filtered)).replacingOccurrences(of: " +", with: " ", options: .regularExpression)
        return compact
    }

    private func endSession() {
        isEnding = true
        showEndSheet = true
        feedback = nil
        Task {
            do {
                let ai = try await AIClient.shared.generateFeedback(transcript: transcript, metrics: metrics)
                var lessonMatch: MicroLesson? = nil
                if let title = ai.micro_lesson, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    lessonMatch = findLesson(byTitleApprox: title)
                }
                let fb = FeedbackSummary(strengths: Array(ai.strengths.prefix(2)), suggestion: ai.suggestion, microLessonId: lessonMatch?.id)
                await MainActor.run {
                    self.feedback = fb
                    self.suggestedLesson = lessonMatch
                    self.isEnding = false
                }
            } catch {
                await MainActor.run {
                    self.isEnding = false
                    self.showEndSheet = false
                    self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
            }
        }
    }

    // MARK: - Streaming controls
    private var hasPendingEmptyAITurn: Bool {
        if let last = transcript.last { return last.role == .ai && last.text.isEmpty }
        return false
    }

    private var canRetry: Bool {
        return !isStreaming && (hasPendingEmptyAITurn || errorMessage != nil)
    }

    private func retryStream() {
        errorMessage = nil
        isStreaming = true
        streamFromAI()
    }

    private func cancelStream() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
    }

    private func saveSession() {
        // Check settings for opt-in
        let fetch = FetchDescriptor<UserSettings>(predicate: #Predicate { _ in true })
        let allowStore = (try? modelContext.fetch(fetch).first?.storeTranscripts) ?? false
        guard allowStore else { return }
        let session = TrainingSession(scenario: scenarioId, personaId: nil, personaLabel: personaLabel, transcript: transcript, metrics: metrics, feedback: feedback, kept: true, locale: "en")
        session.endedAt = Date()
        modelContext.insert(session)
        try? modelContext.save()
    }

    private func matchesOpenPrefix(_ text: String) -> Bool {
        let lower = text.lowercased()
        let prefixes = ["how ", "what ", "which ", "why ", "кто ", "что ", "как ", "почему "]
        return prefixes.contains { lower.hasPrefix($0) }
    }

    private func findLesson(byTitleApprox title: String) -> MicroLesson? {
        // Simple case-insensitive contains match over small seed set
        let all: [MicroLesson] = (try? modelContext.fetch(FetchDescriptor<MicroLesson>())) ?? []
        let lower = title.lowercased()
        // exact title match first
        if let exact = all.first(where: { $0.title.lowercased() == lower }) { return exact }
        // contains any significant token
        let tokens = lower.split(separator: " ").map { String($0) }.filter { $0.count > 3 }
        return all.first(where: { l in
            let lt = l.title.lowercased()
            return tokens.contains(where: { lt.contains($0) })
        })
    }
}

private struct ChatMessageRow: View {
    let isUser: Bool
    let text: String
    var isThinking: Bool = false
    var useMarkdown: Bool = true
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if isUser {
                Spacer(minLength: 48)
                // User bubble on the right
                Group {
                    if useMarkdown { Text(MarkdownHelper.attributed(from: text)) } else { Text(text) }
                }
                .font(.body)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.accentColor)
                )
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                // Assistant avatar
                AssistantIcon()
                if isThinking {
                    TypingIndicatorBubble()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Group {
                        if useMarkdown { Text(MarkdownHelper.attributed(from: text)) } else { Text(text) }
                    }
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer(minLength: 48)
            }
        }
        .padding(.horizontal, 12)
        .scaleEffect(x: 1, y: -1)
    }
}

private struct AssistantIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 28, height: 28)
            Image(systemName: "sparkles")
                .foregroundStyle(.accent)
                .font(.system(size: 14, weight: .semibold))
        }
        .padding(.top, 2)
    }
}

private struct TypingIndicatorBubble: View {
    @State private var animate = false
    var body: some View {
        HStack(spacing: 6) {
            Circle().frame(width: 6, height: 6).opacity(animate ? 1 : 0.25)
            Circle().frame(width: 6, height: 6).opacity(animate ? 0.6 : 0.25)
            Circle().frame(width: 6, height: 6).opacity(animate ? 0.3 : 0.25)
        }
        .foregroundStyle(.secondary)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

private struct RepairChip: View {
    let title: String
    var recommended: Bool = false
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.footnote)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Capsule().fill(recommended ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.15)))
        }
        .buttonStyle(.plain)
    }
}

// End-of-session sheet
private struct SessionEndView: View {
    let feedback: FeedbackSummary
    let suggestedLesson: MicroLesson?
    let canSave: Bool
    var onSave: () -> Void
    var onClose: () -> Void
    var body: some View {
        NavigationStack {
            List {
                Section("What worked") {
                    ForEach(feedback.strengths, id: \.self) { Text($0) }
                }
                Section("Try next") { Text(feedback.suggestion) }
                if let lesson = suggestedLesson {
                    Section("Micro-lesson") {
                        NavigationLink(destination: LessonDetailView(lesson: lesson)) {
                            Label(lesson.title, systemImage: "book")
                        }
                    }
                }
                if canSave {
                    Section { Button("Save Session", action: onSave) }
                } else {
                    Section { Text("Enable saving in Settings to store sessions.").font(.caption).foregroundStyle(.secondary) }
                }
            }
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Close", action: onClose) } }
        }
    }
}
