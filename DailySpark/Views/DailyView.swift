import SwiftUI
import SwiftData

struct DailyView: View {
    @Environment(\.modelContext) private var modelContext

    // Simple cache in UserDefaults
    @AppStorage("dailyTipText") private var cachedTip: String = ""
    @AppStorage("dailyTipDate") private var cachedTipDate: String = ""
    @AppStorage("dailyTopicsJSON") private var cachedTopicsJSON: String = ""

    @State private var isLoadingTip = false
    @State private var isLoadingTopics = false
    @State private var dailyTip: String = ""
    @State private var topics: [String] = []
    @State private var growth: [GrowthIssue] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        dailyTipCard
                        if !growth.isEmpty { growthArea }
                        topicsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Daily")
            .onAppear {
                loadDailyTip()
                loadTopics()
                growth = GrowthAnalyzer.derive(using: modelContext)
            }
        }
    }

    // MARK: - Sections
    private var dailyTipCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                Text("Daily Spark:").bold()
                Spacer()
                if isLoadingTip { ProgressView().scaleEffect(0.8) }
            }
            .foregroundStyle(.accent)
            Text(dailyTip.isEmpty ? "—" : dailyTip)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(UIColor.separator).opacity(0.15))
        )
    }

    private var growthArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Growth Area").font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(growth.prefix(2)) { issue in
                    NavigationLink(value: issue) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(issue.title).font(.subheadline).bold()
                            Text(issue.hint).font(.footnote).foregroundStyle(.secondary).lineLimit(3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .frame(height: 120)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemGroupedBackground)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(UIColor.separator).opacity(0.15)))
                    }
                }
            }
        }
        .navigationDestination(for: GrowthIssue.self) { issue in
            // Start training with a random persona to practice this issue
            let persona = TrainingPresets.randomPersonas(count: 1).first
            TrainingView(scenarioId: persona?.scenarioId ?? "corporate", personaLabel: persona?.title ?? "Partner")
        }
    }

    private var topicsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Text("Topics").font(.headline); Spacer(); if isLoadingTopics { ProgressView().scaleEffect(0.8) } }
            VStack(alignment: .leading, spacing: 8) {
                ForEach(topics.prefix(4), id: \.self) { t in
                    NavigationLink(value: t) {
                        HStack {
                            Text(t)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemGroupedBackground)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(UIColor.separator).opacity(0.15)))
                    }
                }
            }
        }
        .navigationDestination(for: String.self) { topic in
            let persona = TrainingPresets.randomPersonas(count: 1).first
            TrainingView(scenarioId: persona?.scenarioId ?? "date", personaLabel: (persona?.title ?? "Partner") + " — \(topic)")
        }
    }

    // MARK: - Loading
    private func loadDailyTip() {
        let today = isoDay(Date())
        if cachedTipDate == today, !cachedTip.isEmpty {
            dailyTip = cachedTip
            return
        }
        isLoadingTip = true
        Task {
            let tip = (try? await AIClient.shared.generateDailyAdvice(locale: "en")) ?? defaultTips.randomElement() ?? "Ask open questions and listen for details."
            await MainActor.run {
                self.dailyTip = tip
                self.isLoadingTip = false
                self.cachedTip = tip
                self.cachedTipDate = today
            }
        }
    }

    private func loadTopics() {
        if let arr = decodeTopics(cachedTopicsJSON), !arr.isEmpty {
            topics = arr
        }
        isLoadingTopics = true
        Task {
            let arr = (try? await AIClient.shared.generateDailyTopics(count: 4, locale: "en")) ?? defaultTopics.shuffled().prefix(4).map { $0 }
            await MainActor.run {
                self.topics = Array(arr)
                self.isLoadingTopics = false
                self.cachedTopicsJSON = encodeTopics(self.topics)
            }
        }
    }

    private func isoDay(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX"); return f.string(from: d)
    }

    private func decodeTopics(_ json: String) -> [String]? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([String].self, from: data)
    }
    private func encodeTopics(_ arr: [String]) -> String {
        (try? String(data: JSONEncoder().encode(arr), encoding: .utf8)) ?? "[]"
    }

    private let defaultTips: [String] = [
        "Open with something specific you noticed.",
        "Avoid yes/no questions; invite short stories.",
        "Mirror a keyword and ask a light follow-up.",
        "Share a small detail, then ask about theirs.",
        "Close with a kind wrap-up and option to continue."
    ]

    private let defaultTopics: [String] = [
        "Local Cafés",
        "Weekend Plans",
        "Books & Podcasts",
        "City Walks",
        "Small Passions",
        "Concerts",
        "Hobbies",
        "Travel Tips"
    ]
}

// MARK: - Growth Analyzer
struct GrowthIssue: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let hint: String
}

enum GrowthAnalyzer {
    static func derive(using context: ModelContext) -> [GrowthIssue] {
        let desc = FetchDescriptor<TrainingSession>(predicate: #Predicate { _ in true }, sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        let recent: [TrainingSession] = (try? context.fetch(desc)) ?? []
        guard !recent.isEmpty else { return [] }
        let last = Array(recent.prefix(6))
        let totalTurns = last.map { $0.metrics.turns }.reduce(0, +)
        let shortAns = last.map { $0.metrics.shortAnswersCount }.reduce(0, +)
        let openQs = last.map { $0.metrics.openQuestionsCount }.reduce(0, +)
        let hints = last.map { $0.metrics.hintsShown }.reduce(0, +)

        var issues: [GrowthIssue] = []
        if totalTurns > 0 && Double(openQs) / Double(max(totalTurns, 1)) < 0.25 {
            issues.append(.init(title: "Ask more open questions", hint: "Try starting with 'what/which/how' and invite a short story."))
        }
        if shortAns >= last.count * 2 { // many short replies across sessions
            issues.append(.init(title: "Expand your answers", hint: "Add one concrete detail or feeling to avoid one-word replies."))
        }
        if hints >= last.count * 2 {
            issues.append(.init(title: "Rely less on hints", hint: "Bridge from a keyword the partner said, then ask lightly."))
        }
        // Fallback: if sessions exist but no specific issues triggered, surface two generic growth ideas
        if issues.isEmpty {
            issues = [
                .init(title: "Follow up on details", hint: "Pick one word they used and ask a gentle follow‑up."),
                .init(title: "Share, then ask", hint: "Offer a tiny example from you, then invite theirs."),
                .init(title: "Smooth endings", hint: "Wrap with appreciation and a light next‑time option.")
            ]
        }
        return issues.shuffled()
    }
}
