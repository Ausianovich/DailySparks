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
            case .missingAPIKey: return "OpenAI API key is missing. Add it in Settings."
            case .badResponse: return "Bad response from server."
            case .decoding: return "Failed to decode server response."
            case .server(let msg): return msg
            }
        }
    }

    private let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!

    private func authHeader() throws -> String {
        guard let key = KeychainHelper.loadAPIKey(), !key.isEmpty else { throw AIError.missingAPIKey }
        return "Bearer \(key)"
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

    // MARK: - Training (streaming)
    func streamTrainingReply(persona: String, context: String, transcript: [DialogueTurn], locale: String = "en", model: String = "4o-nano") -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let system = "You role-play a realistic persona in a casual setting. Keep replies 1–3 sentences, friendly, and natural. Seed subtle hooks the user can pick up. Respect safety policy. Persona: \(persona) Context: \(context)"

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
                        if model == "4o-nano" {
                            // Retry with gpt-4o-mini
                            var req2 = URLRequest(url: apiURL)
                            req2.httpMethod = "POST"
                            req2.setValue("application/json", forHTTPHeaderField: "Content-Type")
                            req2.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                            req2.setValue(try authHeader(), forHTTPHeaderField: "Authorization")
                            let body2: [String: Any] = [
                                "model": "gpt-4o-mini",
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
    func generateRepairSuggestion(kind: String, transcript: [DialogueTurn], locale: String = "en", model: String = "4o-nano", avoid: [String] = []) async throws -> String {
        let system = "You are a discreet conversation coach. Provide ONE concise line the user can say next. Keep it friendly, natural, and safe for casual conversation."
        let lastTurns = transcript.suffix(8).map { t in
            let role = (t.role == .user) ? "user" : (t.role == .ai ? "ai" : "hint")
            return "\(role): \(t.text)"
        }.joined(separator: "\n")
        let instruction: String
        switch kind.lowercased() {
        case "rephrase": instruction = "Rephrase the user's last message to sound warmer and more open."
        case "pivot": instruction = "Offer a gentle pivot line to a safe, light topic connected to the context."
        case "open": instruction = "Propose one open question that invites a short story or preference."
        default: instruction = "Propose a friendly, open follow-up line."
        }
        let avoidBlock: String = avoid.isEmpty ? "" : ("\nDo NOT repeat or closely paraphrase any of these lines:" + avoid.prefix(6).map { "\n• \($0)" }.joined())
        let user = "Context locale=\(locale). Return only the line, no quotes, no prefix.\nGoal: \(instruction)\nTranscript:\n\(lastTurns)\(avoidBlock)"

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
                return try await generateRepairSuggestion(kind: kind, transcript: transcript, locale: locale, model: "gpt-4o-mini", avoid: avoid)
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
