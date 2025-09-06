import Foundation

actor AIClient {
    static let shared = AIClient()

    enum AIError: Error, LocalizedError {
        case missingAPIKey
        case badResponse
        case decoding
        case server(String)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey: return "OpenAI API key is missing. Configure it in AppSecrets.openAIKey."
            case .badResponse: return "Bad response from server."
            case .decoding: return "Failed to decode server response."
            case .server(let msg): return msg
            }
        }
    }

    private let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!

    private func authHeader() throws -> String {
        // Prefer local in-code secret for development
        if let hardcoded = AppSecrets.openAIKey, !hardcoded.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Bearer \(hardcoded)"
        }
        // Fallback to Keychain (kept for future flexibility)
        if let key = KeychainHelper.loadAPIKey(), !key.isEmpty {
            return "Bearer \(key)"
        }
        throw AIError.missingAPIKey
    }

    // MARK: - Generator (non-streaming, JSON structured)
    struct SparkItem: Decodable { let type: String; let text: String }
    struct SparksResponse: Decodable { let items: [SparkItem] }

    func generateSparksStructured(situation: String, audience: String, locale: String = "en", model: String = "4o-nano", tone: String? = nil, length: String? = nil) async throws -> [SparkItem] {
        let system = "You are DailySpark, generating light, safe, contemporary conversation sparks for adults 30+. Avoid politics, religion, explicit content, or controversy. Prefer positive, neutral topics. Provide variety and freshness."
        var rules = "Rules: 3–5 items; concise 1–2 lines each; no preamble or extra keys."
        if let tone = tone, !tone.isEmpty { rules += " Tone: \(tone)." }
        if let length = length, !length.isEmpty { rules += " Length: \(length)." }
        let user = "Output strictly valid JSON only. Schema: {\\n  \\\"items\\\": [ { \\\"type\\\": \\\"question|observation|theme\\\", \\\"text\\\": \\\"...\\\" } ]\\n}\\n\(rules)\\nSituation: \(situation)\\nAudience: \(audience)\\nLocale: \(locale)"

        var req = URLRequest(url: apiURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(try authHeader(), forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": model,
            "temperature": 0.6,
            "response_format": ["type": "json_object"],
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            // Fallback to gpt-4o-mini with JSON mode
            if model == "4o-nano" {
                return try await generateSparksStructured(situation: situation, audience: audience, locale: locale, model: "gpt-4o-mini", tone: tone, length: length)
            }
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw AIError.server(msg)
        }
        struct Choice: Decodable { let message: Msg }
        struct Msg: Decodable { let role: String; let content: String }
        struct Resp: Decodable { let choices: [Choice] }
        let decoded = try JSONDecoder().decode(Resp.self, from: data)
        guard let content = decoded.choices.first?.message.content,
              let jsonData = content.data(using: .utf8) else {
            throw AIError.decoding
        }
        do {
            let parsed = try JSONDecoder().decode(SparksResponse.self, from: jsonData)
            return parsed.items
        } catch {
            if let range = content.range(of: #"\{[\s\S]*\}"#, options: .regularExpression) {
                let jsonString = String(content[range])
                if let data2 = jsonString.data(using: .utf8), let parsed = try? JSONDecoder().decode(SparksResponse.self, from: data2) {
                    return parsed.items
                }
            }
            throw AIError.decoding
        }
    }

    // MARK: - Daily Tip (non-streaming)
    func generateDailyAdvice(locale: String = "en", model: String = "gpt-4o-mini") async throws -> String {
        let system = "You are DailySpark, a concise small‑talk coach. Generate several short, friendly, practical tips about starting, maintaining, or ending light conversation; avoid sensitive topics."
        let user = "Locale: \(locale). Provide 5 varied one‑line tips. Return JSON only: {\\n  \\\"tips\\\": [\\\"...\\\", \\\"...\\\", \\\"...\\\", \\\"...\\\", \\\"...\\\"]\\n}. Keep each tip 10–20 words, natural, no quotes, no numbering."

        var req = URLRequest(url: apiURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(try authHeader(), forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "model": model,
            "temperature": 0.7,
            "presence_penalty": 0.6,
            "response_format": ["type": "json_object"],
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            if model == "4o-nano" { return try await generateDailyAdvice(locale: locale, model: "gpt-4o-mini") }
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw AIError.server(msg)
        }
        struct Choice: Decodable { let message: Msg }
        struct Msg: Decodable { let role: String; let content: String }
        struct Resp: Decodable { let choices: [Choice] }
        let decoded = try JSONDecoder().decode(Resp.self, from: data)
        guard let content = decoded.choices.first?.message.content else { throw AIError.decoding }
        // Try to parse JSON directly
        if let jsonData = content.data(using: .utf8) {
            struct Tips: Decodable { let tips: [String] }
            if let parsed = try? JSONDecoder().decode(Tips.self, from: jsonData), let choice = parsed.tips.randomElement() {
                return choice.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        // If model wrapped JSON in text, try extracting
        if let range = content.range(of: #"\{[\s\S]*\}"#, options: .regularExpression) {
            let jsonString = String(content[range])
            if let data2 = jsonString.data(using: .utf8) {
                struct Tips: Decodable { let tips: [String] }
                if let parsed2 = try? JSONDecoder().decode(Tips.self, from: data2), let choice = parsed2.tips.randomElement() {
                    return choice.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        // Fallback to plain text
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Daily Tips (structured list helper)
    struct DailyTips: Decodable { let tips: [String] }

    func generateDailyTips(locale: String = "en", model: String = "gpt-4o-mini") async throws -> [String] {
        let system = "You are DailySpark, a concise small‑talk coach. Generate several short, friendly, practical tips about starting, maintaining, or ending light conversation; avoid sensitive topics."
        let user = "Locale: \(locale). Provide 5 varied one‑line tips. Return JSON only: {\\n  \\\"tips\\\": [\\\"...\\\", \\\"...\\\", \\\"...\\\", \\\"...\\\", \\\"...\\\"]\\n}. Keep each tip 10–20 words, natural, no quotes, no numbering."

        var req = URLRequest(url: apiURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(try authHeader(), forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "model": model,
            "temperature": 0.7,
            "presence_penalty": 0.6,
            "response_format": ["type": "json_object"],
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            if model == "gpt-4o-mini" { return try await generateDailyTips(locale: locale, model: "4o-nano") }
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw AIError.server(msg)
        }
        struct Choice: Decodable { let message: Msg }
        struct Msg: Decodable { let role: String; let content: String }
        struct Resp: Decodable { let choices: [Choice] }
        let decoded = try JSONDecoder().decode(Resp.self, from: data)
        guard let content = decoded.choices.first?.message.content else { throw AIError.decoding }
        if let jsonData = content.data(using: .utf8), let parsed = try? JSONDecoder().decode(DailyTips.self, from: jsonData) {
            return parsed.tips
        }
        if let range = content.range(of: #"\{[\s\S]*\}"#, options: .regularExpression) {
            let jsonString = String(content[range])
            if let d2 = jsonString.data(using: .utf8), let parsed2 = try? JSONDecoder().decode(DailyTips.self, from: d2) {
                return parsed2.tips
            }
        }
        throw AIError.decoding
    }

    // MARK: - Daily Topics (non-streaming, JSON)
    struct TopicsResp: Decodable { let topics: [String] }
    func generateDailyTopics(count: Int = 4, locale: String = "en", model: String = "4o-nano") async throws -> [String] {
        let system = "You are DailySpark, proposing light, safe, contemporary conversation topics for casual small talk. Avoid sensitive areas; prefer hobbies, places, events, everyday observations."
        let user = "Locale: \(locale). Provide \(count) concise topic labels suitable for buttons (2–4 words). Return JSON: { \"topics\": [\"...\"] }."

        var req = URLRequest(url: apiURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(try authHeader(), forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "model": model,
            "temperature": 0.7,
            "response_format": ["type": "json_object"],
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            if model == "4o-nano" { return try await generateDailyTopics(count: count, locale: locale, model: "gpt-4o-mini") }
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw AIError.server(msg)
        }
        struct Choice: Decodable { let message: Msg }
        struct Msg: Decodable { let role: String; let content: String }
        struct Resp: Decodable { let choices: [Choice] }
        let decoded = try JSONDecoder().decode(Resp.self, from: data)
        guard let content = decoded.choices.first?.message.content,
              let jsonData = content.data(using: .utf8) else { throw AIError.decoding }
        do {
            let parsed = try JSONDecoder().decode(TopicsResp.self, from: jsonData)
            return parsed.topics
        } catch {
            if let range = content.range(of: #"\{[\s\S]*\}"#, options: .regularExpression) {
                let jsonString = String(content[range])
                if let data2 = jsonString.data(using: .utf8), let parsed = try? JSONDecoder().decode(TopicsResp.self, from: data2) {
                    return parsed.topics
                }
            }
            throw AIError.decoding
        }
    }

    // MARK: - Training (streaming)
    func streamTrainingReply(persona: String, context: String, assistantName: String, transcript: [DialogueTurn], locale: String = "en", model: String = "gpt-4o-mini") -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let system = "You are role‑playing as \(assistantName), a realistic persona for casual small talk. Speak in first person (\"I\"). Keep a consistent identity and name across the whole chat. If you start the chat, use a short, natural opener; you may introduce yourself as \"I'm \(assistantName)\" in one brief phrase if it fits the scenario. If the user shares their name, acknowledge it once and use it naturally; do not ask for their name again. Never ask two questions in a row: if the user just asked a question, answer briefly and add a small statement or bridge without another question. Aim for about 40% of turns to end with a question; otherwise end with a light observation, acknowledgement, or invitation the user can build on. Keep 1–3 sentences; vary tone; be friendly and natural. Avoid sensitive topics per safety policy. Persona details: \(persona). Context: \(context)."

                    var messages: [[String: String]] = [["role": "system", "content": system]]
                    // Include last few turns
                    let lastTurns = transcript.suffix(10)
                    for t in lastTurns {
                        let role = (t.role == .user) ? "user" : "assistant"
                        messages.append(["role": role, "content": t.text])
                    }

                    var req = URLRequest(url: apiURL)
                    req.httpMethod = "POST"
                    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    req.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    req.setValue(try authHeader(), forHTTPHeaderField: "Authorization")
                    let body: [String: Any] = [
                        "model": model,
                        "temperature": 0.6,
                        "stream": true,
                        "messages": messages
                    ]
                    req.httpBody = try JSONSerialization.data(withJSONObject: body)

                    var (bytes, response) = try await URLSession.shared.bytes(for: req)
                    if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                        if model == "gpt-4o-mini" {
                            // Retry with 4o-nano as fallback
                            var req2 = URLRequest(url: apiURL)
                            req2.httpMethod = "POST"
                            req2.setValue("application/json", forHTTPHeaderField: "Content-Type")
                            req2.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                            req2.setValue(try authHeader(), forHTTPHeaderField: "Authorization")
                            let body2: [String: Any] = [
                                "model": "4o-nano",
                                "temperature": 0.6,
                                "stream": true,
                                "messages": messages
                            ]
                            req2.httpBody = try JSONSerialization.data(withJSONObject: body2)
                            (bytes, response) = try await URLSession.shared.bytes(for: req2)
                            if let http2 = response as? HTTPURLResponse, !(200..<300).contains(http2.statusCode) {
                                throw AIError.server("HTTP \(http2.statusCode)")
                            }
                        } else {
                            throw AIError.server("HTTP \(http.statusCode)")
                        }
                    }
                    for try await line in bytes.lines {
                        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard trimmed.hasPrefix("data:") else { continue }
                        let payload = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                        if payload == "[DONE]" { break }
                        // Parse delta content
                        if let data = payload.data(using: .utf8) {
                            if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let choices = obj["choices"] as? [[String: Any]],
                               let delta = (choices.first? ["delta"]) as? [String: Any],
                               let content = delta["content"] as? String, !content.isEmpty {
                                continuation.yield(content)
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Post-dialogue feedback (non-streaming, JSON)
    struct AIFeedback: Decodable {
        let strengths: [String]
        let suggestion: String
        let micro_lesson: String?
    }

    func generateFeedback(transcript: [DialogueTurn], metrics: TrainingMetrics, locale: String = "en", model: String = "4o-nano") async throws -> AIFeedback {
        let system = "Provide concise, kind feedback for a short casual dialogue. Return JSON only."
        // Compact transcript text
        let turns = transcript.suffix(12).map { t in
            let role = (t.role == .user) ? "user" : (t.role == .ai ? "ai" : "hint")
            return "\(role): \(t.text)"
        }.joined(separator: "\n")
        let user = "Output strictly valid JSON only. Schema: {\\n  \\\"strengths\\\": [\\\"...\\\", \\\"...\\\"],\\n  \\\"suggestion\\\": \\\"...\\\",\\n  \\\"micro_lesson\\\": \\\"optional title\\\"\\n}\\nRules: 2 strengths; 1 actionable suggestion (1 sentence); neutral, kind, specific.\nMetrics: short=\(metrics.shortAnswersCount), openQ=\(metrics.openQuestionsCount), turns=\(metrics.turns)\nTranscript (\(locale)):\n\(turns)"

        var req = URLRequest(url: apiURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(try authHeader(), forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "model": model,
            "temperature": 0.4,
            "response_format": ["type": "json_object"],
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            if model == "4o-nano" {
                return try await generateFeedback(transcript: transcript, metrics: metrics, locale: locale, model: "gpt-4o-mini")
            }
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw AIError.server(msg)
        }
        struct Choice: Decodable { let message: Msg }
        struct Msg: Decodable { let role: String; let content: String }
        struct Resp: Decodable { let choices: [Choice] }
        let decoded = try JSONDecoder().decode(Resp.self, from: data)
        guard let content = decoded.choices.first?.message.content,
              let jsonData = content.data(using: .utf8) else { throw AIError.decoding }
        return try JSONDecoder().decode(AIFeedback.self, from: jsonData)
    }

    // MARK: - Repair suggestions (non-streaming)
    func generateRepairSuggestion(kind: String, persona: String, scenarioContext: String, transcript: [DialogueTurn], locale: String = "en", model: String = "4o-nano", avoid: [String] = []) async throws -> String {
        let system = "You are a discreet conversation coach inside an ongoing chat. Provide ONE concise line the user can say next. Keep it friendly, natural, and safe for casual conversation. Tie your line to the current topic when possible."
        let lastTurns = transcript.suffix(8).map { t in
            let role = (t.role == .user) ? "user" : (t.role == .ai ? "ai" : "hint")
            return "\(role): \(t.text)"
        }.joined(separator: "\n")
        let instruction: String
        switch kind.lowercased() {
        case "rephrase": instruction = "Rephrase the user's last message to sound warmer, more open, and directly connected to what was just said."
        case "pivot": instruction = "Offer a gentle pivot line that bridges from a mentioned detail to a safe, light topic relevant to the scenario."
        case "open": instruction = "Propose one open question that invites a short story or preference, referencing a detail from the last turn."
        default: instruction = "Propose a friendly, open follow-up line."
        }
        let avoidBlock: String = avoid.isEmpty ? "" : ("\nDo NOT repeat or closely paraphrase any of these lines:" + avoid.prefix(6).map { "\n• \($0)" }.joined())
        let user = "Context locale=\(locale). Return only the line, no quotes, no prefix.\nScenario: \(scenarioContext)\nPartner persona: \(persona)\nGoal: \(instruction)\nRules: 8–18 words; natural tone; reference a concrete word or detail from the last 1–2 turns if possible; avoid yes/no questions unless playful.\nTranscript (last turns):\n\(lastTurns)\(avoidBlock)"

        var req = URLRequest(url: apiURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(try authHeader(), forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "model": model,
            "temperature": 0.6,
            "presence_penalty": 0.6,
            "frequency_penalty": 0.4,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            if model == "4o-nano" {
                return try await generateRepairSuggestion(kind: kind, persona: persona, scenarioContext: scenarioContext, transcript: transcript, locale: locale, model: "gpt-4o-mini", avoid: avoid)
            }
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw AIError.server(msg)
        }
        struct Choice: Decodable { let message: Msg }
        struct Msg: Decodable { let role: String; let content: String }
        struct Resp: Decodable { let choices: [Choice] }
        let decoded = try JSONDecoder().decode(Resp.self, from: data)
        let text = decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text
    }
}
