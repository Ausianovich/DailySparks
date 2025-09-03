import SwiftUI

enum MarkdownHelper {
    static func attributed(from text: String) -> AttributedString {
        if let attr = try? AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace,
                failurePolicy: .returnPartiallyParsedIfPossible
            )
        ) {
            return attr
        } else {
            return AttributedString(text)
        }
    }
}

