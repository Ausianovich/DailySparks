import SwiftUI
import SwiftData

struct GeneratorView: View {
    @State private var situation: String = ""
    @State private var audience: String = ""
    @State private var results: [Spark] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            Form {
                Section("Presets") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Situations")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Presets.situations, id: \.self) { item in
                                    Button(action: { situation = item }) {
                                        Text(item)
                                            .font(.footnote)
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 10)
                                            .background(Capsule().fill(Color.secondary.opacity(0.15)))
                                    }
                                }
                            }
                            .padding(.leading, 16)
                            .padding(.vertical, 2)
                        }

                        Text("Audiences")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Presets.audiences, id: \.self) { item in
                                    Button(action: { audience = item }) {
                                        Text(item)
                                            .font(.footnote)
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 10)
                                            .background(Capsule().fill(Color.secondary.opacity(0.15)))
                                    }
                                }
                            }
                            .padding(.leading, 16)
                            .padding(.vertical, 2)
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                Section("Context") {
                    ZStack(alignment: .trailing) {
                        TextField("Situation", text: $situation, axis: .vertical)
                            .lineLimit(1...4)
                        if !situation.isEmpty {
                            Button(action: { situation = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 2)
                        }
                    }
                    ZStack(alignment: .trailing) {
                        TextField("Audience", text: $audience, axis: .vertical)
                            .lineLimit(1...4)
                        if !audience.isEmpty {
                            Button(action: { audience = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 2)
                        }
                    }
                    Button(action: generate) {
                        if isLoading { ProgressView() } else { Text("Generate Sparks") }
                    }.disabled(isLoading || situation.isEmpty || audience.isEmpty)
                }
                Section("Results") {
                    if results.isEmpty {
                        Text("No sparks yet.").foregroundStyle(.secondary)
                    } else {
                        ForEach(results, id: \.id) { spark in
                            SparkRowView(spark: spark)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button {
                                        copyText(spark.text)
                                    } label: {
                                        Label("Copy", systemImage: "doc.on.doc")
                                    }
                                    .tint(.blue)

                                    Button {
                                        save(spark)
                                    } label: {
                                        Label("Save", systemImage: "tray.and.arrow.down")
                                    }
                                    .tint(.green)
                                }
                        }
                    }
                }
            }
            .navigationTitle("Generator")
            .alert("Error", isPresented: .constant(errorMessage != nil), actions: {
                Button("OK") { errorMessage = nil }
            }, message: {
                Text(errorMessage ?? "")
            })
        }
    }

    private func generate() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let raw = try await AIClient.shared.generateSparks(situation: situation, audience: audience, locale: "en", model: "4o-nano")
                // Parse format lines like: - Question: ..., - Observation: ..., - Theme: ...
                let lines = SafetyFilter.filterSparks(raw)
                var out: [Spark] = []
                for line in lines {
                    let (stype, text) = parseSpark(line)
                    out.append(Spark(type: stype, text: text, situationLabel: situation, audienceLabel: audience))
                }
                await MainActor.run { self.results = out; self.isLoading = false }
            } catch {
                await MainActor.run {
                    self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    private func save(_ spark: Spark) {
        spark.saved = true
        modelContext.insert(spark)
        try? modelContext.save()
    }

    private func copyText(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
    }

}

// Robust parser for lines like:
// "- Question: ...", "• Observation — ...", "Theme - ...", or plain text.
private func parseSpark(_ line: String) -> (Spark.SparkType, String) {
    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
    // Strip common list bullets and numbering
    var s = trimmed
    let bulletPatterns: [String] = ["- ", "• ", "* ", "— ", "– "]
    for b in bulletPatterns {
        if s.hasPrefix(b) { s.removeFirst(b.count); break }
    }
    if let range = s.range(of: #"^\d+([\.)]|\))\s+"#, options: .regularExpression) {
        s.removeSubrange(range)
    }
    let lower = s.lowercased()

    func stripLabel(_ token: String) -> String? {
        // Match: token [spaces] [: - – —] [spaces] text
        let escaped = NSRegularExpression.escapedPattern(for: token)
        let pattern = "^" + escaped + #"\s*[:\-–—]\s*(.+)$"#
        guard let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let ns = s as NSString
        let range = NSRange(location: 0, length: ns.length)
        if let m = re.firstMatch(in: s, range: range), m.numberOfRanges >= 2 {
            let text = ns.substring(with: m.range(at: 1)).trimmingCharacters(in: .whitespaces)
            return text
        }
        return nil
    }

    // English + Russian labels
    let questionLabels = ["question", "questions", "вопрос", "вопросы"]
    let observationLabels = ["observation", "observations", "comment", "comments", "наблюдение", "наблюдения", "комментарий", "комментарии", "замечание", "замечания"]
    let themeLabels = ["theme", "themes", "topic", "topics", "тема", "темы"]

    for q in questionLabels { if let text = stripLabel(q) { return (.question, text) } }
    for o in observationLabels { if let text = stripLabel(o) { return (.observation, text) } }
    for t in themeLabels { if let text = stripLabel(t) { return (.theme, text) } }

    // Heuristic fallback
    let inferred: Spark.SparkType = s.contains("?") ? .question : .theme
    return (inferred, s)
}

// Removed filter and grouping to show a mixed list, as requested

private struct SparkRowView: View {
    let spark: Spark

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(MarkdownHelper.attributed(from: spark.text))
                .font(.body)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
