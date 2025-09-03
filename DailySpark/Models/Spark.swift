import Foundation
import SwiftData

@Model
final class Spark {
    enum SparkType: String, Codable, CaseIterable { case question, observation, theme }

    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var typeRaw: String
    var text: String
    var situationId: String?
    var situationLabel: String?
    var audienceId: String?
    var audienceLabel: String?
    var locale: String?
    var source: String
    var saved: Bool

    var type: SparkType {
        get { SparkType(rawValue: typeRaw) ?? .question }
        set { typeRaw = newValue.rawValue }
    }

    init(id: UUID = UUID(), createdAt: Date = .now, type: SparkType, text: String, situationId: String? = nil, situationLabel: String? = nil, audienceId: String? = nil, audienceLabel: String? = nil, locale: String? = "en", source: String = "ai", saved: Bool = true) {
        self.id = id
        self.createdAt = createdAt
        self.typeRaw = type.rawValue
        self.text = text
        self.situationId = situationId
        self.situationLabel = situationLabel
        self.audienceId = audienceId
        self.audienceLabel = audienceLabel
        self.locale = locale
        self.source = source
        self.saved = saved
    }
}

