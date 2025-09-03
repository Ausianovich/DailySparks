import SwiftUI
import SwiftData

struct GeneratorView: View {
    @State private var situation: String = ""
    @State private var audience: String = ""
    @State private var results: [Spark] = []
    @State private var isLoading = false

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
        }
    }

    private func generate() {
        isLoading = true
        // Placeholder: generate three local sparks until AI integration is wired
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            results = [
                Spark(type: .question, text: "What’s your go-to spot nearby?", situationId: nil, situationLabel: situation, audienceId: nil, audienceLabel: audience),
                Spark(type: .observation, text: "This place has a calm vibe—nice for a weekday.", situationId: nil, situationLabel: situation, audienceId: nil, audienceLabel: audience),
                Spark(type: .theme, text: "Hidden local gems and small weekend plans.", situationId: nil, situationLabel: situation, audienceId: nil, audienceLabel: audience)
            ]
            isLoading = false
        }
    }

    private func save(_ spark: Spark) {
        spark.saved = true
        modelContext.insert(spark)
        try? modelContext.save()
    }
}

