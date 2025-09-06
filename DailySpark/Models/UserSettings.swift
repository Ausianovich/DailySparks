import Foundation
import SwiftData

@Model
final class UserSettings {
    @Attribute(.unique) var id: UUID
    var storeTranscripts: Bool
    var safetyLevel: String
    var locale: String
    var openAIModel: String?
    var lastUsedSituationId: String?
    var lastUsedAudienceId: String?

    init(id: UUID = UUID(), storeTranscripts: Bool = true, safetyLevel: String = "standard", locale: String = "en", openAIModel: String? = nil, lastUsedSituationId: String? = nil, lastUsedAudienceId: String? = nil) {
        self.id = id
        self.storeTranscripts = storeTranscripts
        self.safetyLevel = safetyLevel
        self.locale = locale
        self.openAIModel = openAIModel
        self.lastUsedSituationId = lastUsedSituationId
        self.lastUsedAudienceId = lastUsedAudienceId
    }
}
