import Foundation
import SwiftData

struct DialogueTurn: Codable, Identifiable, Hashable {
    enum Role: String, Codable { case user, ai, hint }
    var id: UUID = UUID()
    var role: Role
    var text: String
    var timestamp: Date = .now
}

struct TrainingMetrics: Codable, Hashable {
    var shortAnswersCount: Int = 0
    var openQuestionsCount: Int = 0
    var hintsShown: Int = 0
    var turns: Int = 0
}

struct FeedbackSummary: Codable, Hashable {
    var strengths: [String] = []
    var suggestion: String = ""
    var microLessonId: UUID?
}

@Model
final class TrainingSession {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var scenario: String
    var personaId: String?
    var personaLabel: String?
    // Store JSON-encoded data for SwiftData compatibility
    var transcriptData: Data
    var metricsData: Data
    var feedbackData: Data?
    var kept: Bool
    var locale: String?

    init(id: UUID = UUID(), startedAt: Date = .now, endedAt: Date? = nil, scenario: String, personaId: String? = nil, personaLabel: String? = nil, transcript: [DialogueTurn] = [], metrics: TrainingMetrics = .init(), feedback: FeedbackSummary? = nil, kept: Bool = false, locale: String? = "en") {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.scenario = scenario
        self.personaId = personaId
        self.personaLabel = personaLabel
        self.transcriptData = (try? JSONEncoder().encode(transcript)) ?? Data()
        self.metricsData = (try? JSONEncoder().encode(metrics)) ?? Data()
        self.feedbackData = try? JSONEncoder().encode(feedback)
        self.kept = kept
        self.locale = locale
    }

    // Computed convenience accessors
    var transcript: [DialogueTurn] {
        get { (try? JSONDecoder().decode([DialogueTurn].self, from: transcriptData)) ?? [] }
        set { transcriptData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var metrics: TrainingMetrics {
        get { (try? JSONDecoder().decode(TrainingMetrics.self, from: metricsData)) ?? TrainingMetrics() }
        set { metricsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var feedback: FeedbackSummary? {
        get {
            guard let fd = feedbackData else { return nil }
            return try? JSONDecoder().decode(FeedbackSummary.self, from: fd)
        }
        set { feedbackData = try? JSONEncoder().encode(newValue) }
    }
}
