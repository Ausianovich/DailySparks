import SwiftUI
import SwiftData

struct DailyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
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
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(colors: [Color.orange.opacity(0.9), Color.pink.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Daily Spark")
                            .font(.headline.weight(.bold))
                    }
                    .foregroundStyle(.yellow)
                    Text(dailyTip.isEmpty ? "—" : dailyTip)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineSpacing(2)
                }
                Spacer()
                Image(systemName: "flame.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(.yellow)
                    .shadow(color: .yellow.opacity(0.4), radius: 10, x: 0, y: 6)
            }
            .padding(20)
        }
    }
    
    private var growthArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Growth Area").font(.title2.bold())
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(growth.prefix(2)) { issue in
                    NavigationLink(value: issue) {
                        ZStack {
                            // Higher-contrast background using a gentle tint gradient + subtle stroke
                            let base = growthColor(for: issue.title)
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(colors: [base.opacity(0.28), base.opacity(0.16)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(base.opacity(0.35))
                                )
                            HStack {
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(growthColor(for: issue.title).secondary)
                                    .padding(.trailing, 6.0)
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(issue.title)
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(growthColor(for: issue.title))
                                    Spacer()
                                }
                                HStack {
                                    Text(issue.hint)
                                        .multilineTextAlignment(.leading)
                                        .font(.footnote)
                                        .foregroundStyle(
                                            growthColor(for: issue.title)
                                                .secondary
                                        )
                                    Spacer()
                                }
                                Spacer()
                            }
                            .padding(12)
                            .padding(.trailing, 10.0)
                        }
                        .frame(maxHeight: 220)
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
            HStack { Text("Topics").font(.title2.bold()); Spacer(); if isLoadingTopics { ProgressView().scaleEffect(0.8) } }
            VStack(alignment: .leading, spacing: 12) {
                ForEach(topics.prefix(4), id: \.self) { t in
                    NavigationLink(value: t) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(topicColor(for: t).opacity(0.25))
                                Image(systemName: topicIcon(for: t))
                                    .foregroundStyle(topicColor(for: t))
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .frame(width: 30, height: 30)
                            Text(t)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(topicColor(for: t))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(topicColor(for: t))
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(topicColor(for: t).opacity(0.18))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(topicColor(for: t).opacity(0.28))
                        )
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
            let tips = (try? await AIClient.shared.generateDailyTips(locale: currentLocaleCode())) ?? []
            let tip = tips.randomElement() ?? (defaultTips.randomElement() ?? "Ask open questions and listen for details.")
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
            let arr = (try? await AIClient.shared.generateDailyTopics(count: 4, locale: currentLocaleCode())) ?? defaultTopics.shuffled().prefix(4).map { $0 }
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
    
    private func currentLocaleCode() -> String {
        if #available(iOS 16.0, *) {
            return Locale.current.language.languageCode?.identifier ?? "en"
        }
        return Locale.current.languageCode ?? "en"
    }
    
    private func greetingTitle() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let salutation: String = (hour < 12 ? "Good morning!" : (hour < 18 ? "Good afternoon!" : "Good evening!"))
        return salutation
    }
    
    private func topicIcon(for title: String) -> String {
        let lower = title.lowercased()
        if lower.contains("hobb") { return "paintpalette.fill" }
        if lower.contains("travel") || lower.contains("trip") { return "suitcase.fill" }
        if lower.contains("event") || lower.contains("local") { return "party.popper" }
        if lower.contains("weekend") || lower.contains("plan") { return "calendar" }
        if lower.contains("music") { return "music.note" }
        if lower.contains("food") || lower.contains("cafe") { return "fork.knife" }
        return "sparkles"
    }
    
    private func topicColor(for title: String) -> Color {
        let palette: [Color] = [.orange, .blue, .pink, .green, .purple, .teal, .indigo]
        var hash = 0
        for u in title.unicodeScalars { hash = (hash &* 31 &+ Int(u.value)) & 0x7fffffff }
        return palette[abs(hash) % palette.count]
    }
    
    private func growthIcon(for title: String) -> String {
        let lower = title.lowercased()
        if lower.contains("open question") { return "questionmark.circle.fill" }
        if lower.contains("expand") || lower.contains("answer") { return "text.bubble.fill" }
        if lower.contains("hint") { return "lightbulb.fill" }
        if lower.contains("follow") { return "magnifyingglass" }
        if lower.contains("share") { return "arrowshape.turn.up.right.fill" }
        if lower.contains("ending") || lower.contains("wrap") { return "hand.wave.fill" }
        return "sparkles"
    }
    
    private func growthColor(for title: String) -> Color {
        // Deterministic color selection based on title
        return topicColor(for: title)
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
