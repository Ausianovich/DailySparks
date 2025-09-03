import Foundation

struct ScenarioOption: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
}

struct PersonaOption: Identifiable, Hashable {
    let id: String
    let scenarioId: String
    let title: String
    let description: String
}

enum TrainingPresets {
    static let scenarios: [ScenarioOption] = [
        .init(id: "corporate", title: "Corporate", description: "Work event, cross-team mixer"),
        .init(id: "date", title: "Date", description: "Light first date or coffee chat")
    ]

    static let personas: [PersonaOption] = [
        // Corporate
        .init(id: "corp_peer", scenarioId: "corporate", title: "Colleague (peer)", description: "Friendly, curious, from another team"),
        .init(id: "corp_manager", scenarioId: "corporate", title: "Manager (other team)", description: "Supportive, concise, time-aware"),
        .init(id: "corp_new_hire", scenarioId: "corporate", title: "New Hire", description: "Eager, exploring, open to tips"),
        // Date
        .init(id: "date_returning", scenarioId: "date", title: "Returning to Dating", description: "Warm, a bit cautious, sincere"),
        .init(id: "date_book_lover", scenarioId: "date", title: "Book Lover", description: "Thoughtful, curious, story-friendly"),
        .init(id: "date_foodie", scenarioId: "date", title: "Foodie", description: "Playful, loves local spots")
    ]

    static func personas(for scenarioId: String) -> [PersonaOption] {
        personas.filter { $0.scenarioId == scenarioId }
    }
}

