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
                Section("Context") {
                    TextField("Situation", text: $situation)
                    TextField("Audience", text: $audience)
                    Button(action: generate) {
                        if isLoading { ProgressView() } else { Text("Generate Sparks") }
                    }.disabled(isLoading || situation.isEmpty || audience.isEmpty)
                }
                Section("Results") {
                    if results.isEmpty {
                        Text("No sparks yet.").foregroundStyle(.secondary)
                    } else {
                        ForEach(results, id: \.id) { spark in
                            HStack(alignment: .top) {
                                Text(spark.typeRaw.capitalized).font(.caption).foregroundStyle(.secondary).frame(width: 90, alignment: .leading)
                                Text(spark.text)
                                Spacer()
                                Button(action: { save(spark) }) { Image(systemName: "tray.and.arrow.down") }
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
                    var type: Spark.SparkType = .question
                    var text = line
                    if line.lowercased().hasPrefix("- question:") { type = .question; text = String(line.dropFirst("- question:".count)).trimmingCharacters(in: .whitespaces) }
                    else if line.lowercased().hasPrefix("- observation:") { type = .observation; text = String(line.dropFirst("- observation:".count)).trimmingCharacters(in: .whitespaces) }
                    else if line.lowercased().hasPrefix("- theme:") { type = .theme; text = String(line.dropFirst("- theme:".count)).trimmingCharacters(in: .whitespaces) }
                    out.append(Spark(type: type, text: text, situationLabel: situation, audienceLabel: audience))
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
}
