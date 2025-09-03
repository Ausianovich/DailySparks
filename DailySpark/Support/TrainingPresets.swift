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
        .init(id: "corp_designer", scenarioId: "corporate", title: "Product Designer", description: "Practical, visual thinker, loves examples"),
        .init(id: "corp_data_analyst", scenarioId: "corporate", title: "Data Analyst", description: "Curious, enjoys small facts and patterns"),
        .init(id: "corp_sales_rep", scenarioId: "corporate", title: "Sales Rep", description: "Energetic, story-driven, people-focused"),
        .init(id: "corp_remote_worker", scenarioId: "corporate", title: "Remote Teammate", description: "Calm, appreciates routines and tools"),
        .init(id: "corp_contractor", scenarioId: "corporate", title: "Contractor", description: "Pragmatic, project-based, cross-company"),
        .init(id: "corp_hr_partner", scenarioId: "corporate", title: "HR Partner", description: "Warm, people-first, mindful of tone"),
        .init(id: "corp_ops_engineer", scenarioId: "corporate", title: "Ops Engineer", description: "Quietly practical, enjoys solving glitches"),
        .init(id: "corp_marketer", scenarioId: "corporate", title: "Marketing", description: "Trends-aware, likes campaigns and events"),
        .init(id: "corp_intern", scenarioId: "corporate", title: "Intern", description: "Learning fast, curious about teams and paths"),
        .init(id: "corp_returnee", scenarioId: "corporate", title: "Returnee", description: "Back from leave, easing into updates"),
        // Date
        .init(id: "date_returning", scenarioId: "date", title: "Returning to Dating", description: "Warm, a bit cautious, sincere"),
        .init(id: "date_book_lover", scenarioId: "date", title: "Book Lover", description: "Thoughtful, curious, story-friendly"),
        .init(id: "date_foodie", scenarioId: "date", title: "Foodie", description: "Playful, loves local spots"),
        .init(id: "date_outdoors", scenarioId: "date", title: "Outdoors Fan", description: "Light, nature-loving, weekend hikes"),
        .init(id: "date_music_fan", scenarioId: "date", title: "Music Fan", description: "Gigs, playlists, curious about venues"),
        .init(id: "date_pet_owner", scenarioId: "date", title: "Pet Owner", description: "Warm, playful, everyday stories"),
        .init(id: "date_traveler", scenarioId: "date", title: "Traveler", description: "City walks, small discoveries over big trips"),
        .init(id: "date_cinema_buff", scenarioId: "date", title: "Cinema Buff", description: "Likes recs, light spoilers only"),
        .init(id: "date_art_teacher", scenarioId: "date", title: "Art Teacher", description: "Patient, creative, loves small exhibitions"),
        .init(id: "date_science_nerd", scenarioId: "date", title: "Science Nerd", description: "Fun facts, simple explanations, kind tone"),
        .init(id: "date_calm_introvert", scenarioId: "date", title: "Calm Introvert", description: "Gentle pace, appreciates open prompts"),
        .init(id: "date_extrovert_fun", scenarioId: "date", title: "Lively Extrovert", description: "Playful, enjoys banter and stories")
    ]

    static func personas(for scenarioId: String) -> [PersonaOption] {
        personas.filter { $0.scenarioId == scenarioId }
    }

    static func randomPersonas(count: Int = 9) -> [PersonaOption] {
        Array(personas.shuffled().prefix(count))
    }
}
