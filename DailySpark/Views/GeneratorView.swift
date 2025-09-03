import SwiftUI
import SwiftData

struct GeneratorView: View {
    @State private var situation: String = ""
    @State private var audience: String = ""
    @State private var results: [Spark] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var toastText: String? = nil
    @State private var tone: Tone = .friendly
    @State private var length: Length = .short

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Presets
                    CardSection(title: "Presets") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Situations").font(.caption).foregroundStyle(.secondary)
                                .padding(.horizontal, 12)
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: -12) {
                                    ForEach(Presets.situations, id: \.self) { item in
                                        ChipButton(title: item) { situation = item }
                                            .padding(.horizontal, 12)
                                    }
                                }.padding(.vertical, 2)
                            }
                            Text("Audiences").font(.caption).foregroundStyle(.secondary)
                                .padding(.horizontal, 12)
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: -12) {
                                    ForEach(Presets.audiences, id: \.self) { item in
                                        ChipButton(title: item) { audience = item }
                                            .padding(.horizontal, 12)
                                    }
                                }.padding(.vertical, 2)
                            }
                        }
                        .padding(.bottom, 8)
                    }

                    // Context inputs
                    CardSection(title: "Context") {
                        VStack(alignment: .leading, spacing: 10) {
                            LabeledInput(label: "Situation", text: $situation)
                            LabeledInput(label: "Audience", text: $audience)
                            ToneLengthControls(tone: $tone, length: $length)
                            HStack {
                                Button(action: generate) {
                                    HStack(spacing: 8) {
                                        if isLoading { ProgressView() }
                                        Text(isLoading ? "Generating…" : "Generate Sparks").bold()
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .disabled(isLoading || situation.isEmpty || audience.isEmpty)
                                .buttonStyle(.borderedProminent)
                                .padding(.bottom, 12)
                            }
                        }
                        .padding(.horizontal, 12)
                    }

                    // Results header (no card) and list
                    HStack {
                        Text("Fresh Sparks").font(.headline)
                        Spacer()
                        if !results.isEmpty { Button(action: saveAll) { Image(systemName: "tray.and.arrow.down.fill") } .buttonStyle(.plain) }
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        if isLoading && results.isEmpty {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)).frame(height: 64).redacted(reason: .placeholder)
                            }
                        } else if results.isEmpty {
                            Text("No sparks yet.").foregroundStyle(.secondary)
                        } else {
                            ForEach(results, id: \.id) { spark in
                                SparkRowView(
                                    spark: spark,
                                    onCopy: { copyText(spark.text); showToast("Copied") },
                                    onSave: { save(spark); showToast("Saved") }
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button { save(spark); showToast("Saved") } label: { Label("Save", systemImage: "tray.and.arrow.down") }.tint(.green)
                                }
                            }
                        }
                    }

                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
            .navigationTitle("Generator")
            .alert("Error", isPresented: .constant(errorMessage != nil)) { Button("OK") { errorMessage = nil } } message: { Text(errorMessage ?? "") }
            // no bottom toolbar; primary action lives inside Context card per HIG
        }
            
    }

    private func generate() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let items = try await AIClient.shared.generateSparksStructured(situation: situation, audience: audience, locale: "en", model: "4o-nano", tone: tone.prompt, length: length.prompt)
                var out: [Spark] = []
                for item in items {
                    let lower = item.type.lowercased()
                    let type: Spark.SparkType = (lower.contains("question") ? .question : (lower.contains("observation") ? .observation : .theme))
                    let text = item.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !SafetyFilter.isUnsafe(text) {
                        out.append(Spark(type: type, text: text, situationLabel: situation, audienceLabel: audience))
                    }
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

    private func saveAll() {
        for s in results {
            let item = Spark(type: s.type, text: s.text, situationId: s.situationId, situationLabel: s.situationLabel, audienceId: s.audienceId, audienceLabel: s.audienceLabel, locale: s.locale, source: s.source, saved: true)
            modelContext.insert(item)
        }
        try? modelContext.save()
    }

    private func copyText(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
    }

}

private enum Tone: String, CaseIterable { case friendly, playful, formal
    var title: String { rawValue.capitalized }
    var prompt: String { self == .friendly ? "friendly" : (self == .playful ? "playful" : "formal") }
}
private enum Length: String, CaseIterable { case short, medium
    var title: String { rawValue.capitalized }
    var prompt: String { self == .short ? "short" : "medium" }
}

private struct ToneLengthControls: View {
    @Binding var tone: Tone
    @Binding var length: Length
    var body: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(Tone.allCases, id: \.self) { t in
                    Button(action: { tone = t }) { Label(t.title, systemImage: toneIcon(t)) }
                }
            } label: {
                HStack {
                    Spacer()
                    Label("Tone: \(tone.title)", systemImage: "face.smiling")
                        .font(.footnote)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                    Spacer()
                }
                .background(Capsule().fill(Color.secondary.opacity(0.12)))
            }

            Menu {
                ForEach(Length.allCases, id: \.self) { l in
                    Button(action: { length = l }) { Text(l.title) }
                }
            } label: {
                HStack {
                    Spacer()
                    Label("Length: \(length.title)", systemImage: "textformat")
                        .font(.footnote)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                    Spacer()
                }
                .background(Capsule().fill(Color.secondary.opacity(0.12)))
            }
        }
    }

    private func toneIcon(_ t: Tone) -> String {
        switch t { case .friendly: return "hand.wave"; case .playful: return "face.smiling"; case .formal: return "person.text.rectangle" }
    }
}

private extension GeneratorView {
    func showToast(_ text: String) {
        withAnimation { toastText = text }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation { toastText = nil }
        }
    }

    func newSet() {
        generate()
    }

    func appendMore(_ count: Int) {
        Task {
            do {
                let items = try await AIClient.shared.generateSparksStructured(situation: situation, audience: audience, locale: "en", model: "4o-nano", tone: tone.prompt, length: length.prompt)
                var appended = 0
                var newOnes: [Spark] = []
                let existing = Set(results.map { $0.text.lowercased() })
                for item in items where appended < count {
                    let lower = item.type.lowercased()
                    let type: Spark.SparkType = (lower.contains("question") ? .question : (lower.contains("observation") ? .observation : .theme))
                    let text = item.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !existing.contains(text.lowercased()) && !SafetyFilter.isUnsafe(text) {
                        newOnes.append(Spark(type: type, text: text, situationLabel: situation, audienceLabel: audience))
                        appended += 1
                    }
                }
                await MainActor.run { withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { results.append(contentsOf: newOnes) } }
            } catch {
                await MainActor.run { self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription }
            }
        }
    }
}

private struct HeroHeader: View {
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.accentColor.opacity(0.35), Color.blue.opacity(0.25)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea(edges: .top)
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("DailySpark")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                Text("Quick, light conversation starters for any moment")
                    .font(.subheadline)
                    .opacity(0.9)
            }
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
    }
}

// Regex-based parsing removed; generator now uses structured JSON from the model.

// Removed filter and grouping to show a mixed list, as requested

private struct SparkRowView: View {
    let spark: Spark
    var onCopy: (() -> Void)? = nil
    var onSave: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Card background
            RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08))
            // Text content
            Text(MarkdownHelper.attributed(from: spark.text))
                .font(.body)
                .multilineTextAlignment(.leading)
                .lineSpacing(1.5)
                .padding(12)
            // Badge overlay pinned to top-left corner
            TypeBadge(typeRaw: spark.typeRaw)
                .offset(x: -8, y: -8)
        }
        .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
        .contentShape(Rectangle())
        .onTapGesture { onCopy?() }
        .contextMenu {
            if let onCopy { Button(action: onCopy) { Label("Copy", systemImage: "doc.on.doc") } }
            if let onSave { Button(action: onSave) { Label("Save", systemImage: "tray.and.arrow.down") } }
            ShareLink(item: spark.text) { Label("Share", systemImage: "square.and.arrow.up") }
        }
    }
}

private struct TypeBadge: View {
    let typeRaw: String
    var body: some View {
        let color = markerColor(for: typeRaw)
        let icon = iconName(for: typeRaw)
        ZStack {
            Circle().fill(color)
            Image(systemName: icon).foregroundStyle(.white).font(.system(size: 10, weight: .bold))
        }
        .frame(width: 22, height: 22)
        .shadow(color: color.opacity(0.2), radius: 1, x: 0, y: 1)
    }
}

// Color marker for spark type
private func markerColor(for typeRaw: String) -> Color {
    switch typeRaw.lowercased() {
    case "question": return .blue
    case "observation": return .teal
    case "theme": return .orange
    default: return .gray
    }
}

private func iconName(for typeRaw: String) -> String {
    switch typeRaw.lowercased() {
    case "question": return "questionmark.circle.fill"
    case "observation": return "eye.fill"
    case "theme": return "lightbulb.fill"
    default: return "sparkles"
    }
}

// Reusable UI bits
private struct ChipButton: View {
    let title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.footnote)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Capsule().fill(Color.secondary.opacity(0.15)))
        }
        .buttonStyle(.plain)
    }
}

private struct LabeledInput: View {
    let label: String
    @Binding var text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            ZStack(alignment: .trailing) {
                TextField(label, text: $text, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor.systemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.secondary.opacity(0.3))
                    )
                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 6)
                }
            }
        }
    }
}

private struct CardSection<Content: View>: View {
    let title: String
    var trailing: AnyView? = nil
    @ViewBuilder var content: () -> Content

    init(title: String, trailing: AnyView? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.trailing = trailing
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                if let trailing = trailing { trailing }
            }
            .padding(.top, 12)
            .padding(.horizontal, 12)
            content()
        }
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))
    }
}
