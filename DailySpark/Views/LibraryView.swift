import SwiftUI
import SwiftData

struct LibraryView: View {
    @Query(sort: \Spark.createdAt, order: .reverse) private var savedSparks: [Spark]
    @Query(sort: \MicroLesson.lastUpdated, order: .reverse) private var lessons: [MicroLesson]
    @Query(sort: \TrainingSession.startedAt, order: .reverse) private var sessions: [TrainingSession]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if !sessions.isEmpty { sessionsSection }
                        if !savedSparks.isEmpty { sparksSection }
                        lessonsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Library")
        }
    }

    private func title(for s: TrainingSession) -> String {
        let scen = s.scenario.capitalized
        let persona = s.personaLabel ?? "Partner"
        return "\(scen): \(persona)"
    }

    private func subtitle(for s: TrainingSession) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        let date = df.string(from: s.startedAt)
        let turns = s.metrics.turns
        return "\(date) • \(turns) turns"
    }

    private func deleteSession(_ s: TrainingSession) {
        modelContext.delete(s)
        try? modelContext.save()
    }

    private func deleteSpark(_ s: Spark) {
        modelContext.delete(s)
        try? modelContext.save()
    }

    private func deleteSparkAt(_ offsets: IndexSet) {
        for index in offsets { deleteSpark(savedSparks[index]) }
    }

    private func clearAllSparks() {
        for s in savedSparks { modelContext.delete(s) }
        try? modelContext.save()
    }

    private func copySpark(_ s: Spark) {
        #if canImport(UIKit)
        UIPasteboard.general.string = s.text
        #endif
    }

    // MARK: - Sections (new)
    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Training Sessions").font(.title2.bold())
            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(sessions, id: \.id) { s in
                    NavigationLink(destination: TrainingSessionDetailView(session: s)) {
                        ZStack {
                            HStack {
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.secondary)
                                    .padding(.trailing, 12.0)
                            }
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    Circle().fill((s.scenario == "corporate" ? Color.blue : Color.pink).opacity(0.2))
                                    Image(systemName: s.scenario == "corporate" ? "briefcase.fill" : "heart.fill")
                                        .foregroundStyle(s.scenario == "corporate" ? .blue : .pink)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .frame(width: 28, height: 28)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(title(for: s)).font(.headline)
                                    Text(subtitle(for: s)).font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 12)
                            }
                            .padding(12)
                        }
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.secondarySystemGroupedBackground)))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(UIColor.separator).opacity(0.25)))
                    }
                    .foregroundStyle(.primary)
                    .contextMenu {
                        Button(role: .destructive) { deleteSession(s) } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
        }
    }

    private var sparksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                Text("Saved Sparks").font(.title2.bold())
                Spacer()
                Button(role: .destructive, action: clearAllSparks) {
                    Label("Clear All", systemImage: "trash")
                        .font(.footnote)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Capsule().fill(Color.red.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }
            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(savedSparks, id: \.id) { s in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            SparkTypePill(typeRaw: s.typeRaw)
                            Spacer()
                            HStack(spacing: 8) {
                                Button(action: { copySpark(s) }) { Image(systemName: "doc.on.doc").padding(6).background(Capsule().fill(Color.secondary.opacity(0.12))) }
                                ShareLink(item: s.text) { Image(systemName: "square.and.arrow.up").padding(6).background(Capsule().fill(Color.secondary.opacity(0.12))) }
                                Button(role: .destructive, action: { deleteSpark(s) }) { Image(systemName: "trash").padding(6).background(Capsule().fill(Color.red.opacity(0.12))) }
                            }
                            .buttonStyle(.plain)
                        }
                        Text(MarkdownHelper.attributed(from: s.text))
                            .font(.body)
                            .lineSpacing(1.3)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.secondarySystemGroupedBackground)))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(UIColor.separator).opacity(0.25)))
                }
            }
        }
    }

    private var lessonsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Micro Lessons").font(.title2.bold())
            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(lessons, id: \.id) { l in
                    NavigationLink(destination: LessonDetailView(lesson: l)) {
                        ZStack {
                            HStack {
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.indigo)
                                    .padding(.trailing, 12.0)
                            }
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    Circle().fill(Color.indigo.opacity(0.2))
                                    Image(systemName: "book.fill").foregroundStyle(.indigo).font(.system(size: 14, weight: .semibold))
                                }
                                .frame(width: 28, height: 28)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(l.title)
                                        .foregroundStyle(.primary)
                                        .font(.headline)
                                        .multilineTextAlignment(.leading)
                                    if !l.tags.isEmpty {
                                        Text(l.tags.joined(separator: ", "))
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer(minLength: 12)
                            }
                            .padding(12)
                        }
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.secondarySystemGroupedBackground)))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(UIColor.separator).opacity(0.25)))
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
    }

    // Helpers for spark type badge
    private struct SparkTypePill: View {
        let typeRaw: String
        var body: some View {
            HStack(spacing: 6) {
                Image(systemName: LibraryView.iconName(for: typeRaw))
                    .foregroundStyle(LibraryView.markerColor(for: typeRaw))
                Text(LibraryView.typeDisplayName(for: typeRaw))
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Capsule().fill(LibraryView.markerColor(for: typeRaw).opacity(0.12)))
        }
    }

    private static func markerColor(for typeRaw: String) -> Color {
        switch typeRaw.lowercased() {
        case "question": return .blue
        case "observation": return .teal
        case "theme": return .orange
        default: return .gray
        }
    }
    private static func iconName(for typeRaw: String) -> String {
        switch typeRaw.lowercased() {
        case "question": return "questionmark.circle.fill"
        case "observation": return "eye.fill"
        case "theme": return "lightbulb.fill"
        default: return "sparkles"
        }
    }
    private static func typeDisplayName(for typeRaw: String) -> String {
        switch typeRaw.lowercased() {
        case "question": return "Question"
        case "observation": return "Observation"
        case "theme": return "Theme"
        default: return "Spark"
        }
    }
}

struct LessonDetailView: View {
    let lesson: MicroLesson
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(lesson.title).font(.title2).bold()
                Text(lesson.body).font(.body)
                if !lesson.tags.isEmpty {
                    Text(lesson.tags.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }.padding()
        }
        .navigationTitle("Lesson")
        .navigationBarTitleDisplayMode(.inline)
    }
}
