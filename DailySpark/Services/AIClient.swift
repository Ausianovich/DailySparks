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

    // MARK: - Generator (non-streaming)
    func generateSparks(situation: String, audience: String, locale: String = "en", model: String = "4o-nano") async throws -> String {
        let system = "You are DailySpark, generating light, safe, contemporary conversation sparks for adults 30+. Avoid politics, religion, explicit content, or controversy. Prefer positive, neutral topics. Provide variety and freshness."
        let user = "Situation: \(situation)\nAudience: \(audience)\nLocale: \(locale)\nConstraints: 3–5 items; mix of Questions, Observations, Themes; brief (1–2 lines each)."

        var req = URLRequest(url: apiURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(try authHeader(), forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": model,
            "temperature": 0.7,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            // Fallback to gpt-4o-mini if 4o-nano is not available on chat completions
            if model == "4o-nano" {
                return try await generateSparks(situation: situation, audience: audience, locale: locale, model: "gpt-4o-mini")
            }
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw AIError.server(msg)
        }
        struct Choice: Decodable { let message: Msg }
        struct Msg: Decodable { let role: String; let content: String }
        struct Resp: Decodable { let choices: [Choice] }
        let decoded = try JSONDecoder().decode(Resp.self, from: data)
        return decoded.choices.first?.message.content ?? ""
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
}
