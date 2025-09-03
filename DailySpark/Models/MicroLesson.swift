import Foundation
import SwiftData

@Model
final class MicroLesson {
    @Attribute(.unique) var id: UUID
    var title: String
    var body: String
    var tagsData: String
    var lastUpdated: Date

    var tags: [String] {
        get { tagsData.split(separator: ",").map { String($0) } }
        set { tagsData = newValue.joined(separator: ",") }
    }

    init(id: UUID = UUID(), title: String, body: String, tags: [String] = [], lastUpdated: Date = .now) {
        self.id = id
        self.title = title
        self.body = body
        self.tagsData = tags.joined(separator: ",")
        self.lastUpdated = lastUpdated
    }
}

