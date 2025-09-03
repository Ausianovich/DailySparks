import SwiftUI
import SwiftData

struct LibraryView: View {
    @Query(sort: \Spark.createdAt, order: .reverse) private var savedSparks: [Spark]
    @Query(sort: \MicroLesson.lastUpdated, order: .reverse) private var lessons: [MicroLesson]

    var body: some View {
        NavigationStack {
            List {
                if !savedSparks.isEmpty {
                    Section("Saved Sparks") {
                        ForEach(savedSparks, id: \.id) { s in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(s.text)
                                Text((s.typeRaw.capitalized))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
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
            .toolbar {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gear")
                }
            }
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
    }
}
