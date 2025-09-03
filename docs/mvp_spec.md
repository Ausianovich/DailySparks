# MVP Specification — DailySpark

## Scope
- Spark Generator: Input situation + audience → 3–5 sparks (questions, observations, themes).
- Training Prototype: 2 scenarios (Corporate, Date) with short real-time tips and post-dialogue feedback.
- Micro-Learning: 6–8 short articles (1–2 min) on small talk fundamentals.
 - Presets: Provide 10–12 situations and 10–12 audiences (see `docs/presets.md`).

## Platform & Tech
- Platform: iOS (iPhone only), target iOS 17+
- UI: SwiftUI
- Concurrency: Swift modern concurrency (async/await, Task, actors)
- Persistence: SwiftData (on-device, opt-in persisted transcripts)
- Networking: URLSession with async/await
- AI Provider: OpenAI — model: 4o-nano for testing (switchable), pluggable interface
- Localization: App UI in English unless specified; user input may be RU/EN

## Data Schema
See SwiftData entities and fields in `docs/swiftdata_schema.md`.

## User Flows
See detailed UX flows in `docs/ux_flows.md`.

### Spark Generator
1) User selects/enters situation and audience.
2) System returns 3–5 sparks categorized as Questions / Observations / Themes.
3) User can regenerate, save, or copy.

### Training (Corporate, Date)
1) User picks a scenario and sees a short setup.
2) AI role-plays a persona; user replies in a chat. AI messages stream token-by-token (typing effect).
3) Real-time tips appear when user pauses or sends a short/closed response.
4) End of session: concise feedback with 2–3 suggestions.

### Library & Settings
- Library: Saved sparks (list, copy/share/delete); Micro-lessons (list/detail).
- Settings: Opt-in storage, safety level, data controls (export/delete).

## Functional Requirements
- Context capture: situation (free text + presets), audience (presets + free text).
- Output: 3–5 sparks; labeled by type; safe-by-default topics.
- Tips: Suggest openers, follow-ups, tone adjustments.
- Feedback: Brief summary of strengths and one area to improve.
- Content policy: Avoid sensitive topics by default (see content_policy.md).

## Non-Functional Requirements
- Latency: P95 < 2.5s for sparks; < 4s first training reply.
- Reliability: Degraded mode with cached generic sparks if provider is down.
- Privacy: Opt-in storage for personalization; default ephemeral. On-device storage via SwiftData; clear delete/export.
- Startup: App cold start < 1.5s on iPhone 12+.
- Accessibility: Dynamic Type, VoiceOver labels for core screens.
- Internationalization: UX copy in English unless specified; RU allowed for user input.
 - Streaming: Training chat uses streaming responses (incremental tokens) to render AI messages progressively; cancellation supported.

## Empty States
- No situation provided → show examples and presets.
- Provider error → friendly retry + offline sparks.

## Out of Scope (MVP)
- Voice I/O; advanced analytics; user-to-user features; deep behavioral profiling.

## Open Questions
- Model choice within OpenAI, budget, and latency SLA.
- Data retention window for opt-in transcripts; anonymization strategy.
- In-app analytics scope (privacy-first, no 3P SDKs at MVP).
