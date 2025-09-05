import SwiftUI
import SwiftData

struct LibraryView: View {
    @Query(sort: \Spark.createdAt, order: .reverse) private var savedSparks: [Spark]
    @Query(sort: \MicroLesson.lastUpdated, order: .reverse) private var lessons: [MicroLesson]
    @Query(sort: \TrainingSession.startedAt, order: .reverse) private var sessions: [TrainingSession]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            List {
                if !sessions.isEmpty {
                    Section("Training Sessions") {
                        ForEach(sessions, id: \.id) { s in
                            NavigationLink(destination: TrainingSessionDetailView(session: s)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(title(for: s))
                                        .font(.body)
                                    Text(subtitle(for: s))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    deleteSession(s)
                                } label: { Label("Delete", systemImage: "trash") }
                            }
                        }
                    }
                }
                if !savedSparks.isEmpty {
                    Section {
                        ForEach(savedSparks, id: \.id) { s in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(MarkdownHelper.attributed(from: s.text))
                                Text((s.typeRaw.capitalized))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .contextMenu {
                                ShareLink(item: s.text) { Label("Share", systemImage: "square.and.arrow.up") }
                                Button { copySpark(s) } label: { Label("Copy", systemImage: "doc.on.doc") }
                                Button(role: .destructive) { deleteSpark(s) } label: { Label("Delete", systemImage: "trash") }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) { deleteSpark(s) } label: { Label("Delete", systemImage: "trash") }
                                Button { copySpark(s) } label: { Label("Copy", systemImage: "doc.on.doc") }.tint(.blue)
                            }
                        }
                        .onDelete(perform: deleteSparkAt)
                    } header: {
                        HStack {
                            Text("Saved Sparks")
                            Spacer()
                            Button(role: .destructive) {
                                clearAllSparks()
                            } label: {
                                Label("Clear All", systemImage: "trash")
                                    .labelStyle(.iconOnly)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Clear All Saved Sparks")
                        }
                    }
                }
                Section("Micro Lessons") {
                    ForEach(lessons, id: \.id) { l in
                        NavigationLink(destination: LessonDetailView(lesson: l)) {
                            VStack(alignment: .leading) {
                                Text(l.title)
                                if !l.tags.isEmpty {
                                    Text(l.tags.joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
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
