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
1) User enters Situation/Audience in Context; optional Tone (Friendly/Playful/Formal) and Length (Short/Medium).
2) Tap Generate (inside Context card).
3) Backend returns structured JSON (items[{type,text}]) mapped to Questions/Observations/Themes.
4) Fresh Sparks: header + list of cards with type badge; interactions: tap=Copy, long‑press menu (Copy/Save/Share), swipe right=Save. Header action: Save All.

### Training
1) Setup: list of personas (randomized 9); pull‑to‑refresh regenerates list; user selects persona and starts.
2) Chat: iMessage-like — user bubbles right; assistant text left with avatar. Random start (50/50 AI or user). Typing indicator during streaming.
3) Repair Kit: Rephrase / Pivot / Open Q chips insert a suggested line (with de‑duplication to avoid repeats).
4) End of session (Summary sheet): 2 strengths + 1 suggestion; optional micro‑lesson link; Save Session if storage opt‑in enabled.

### Library & Settings
- Library: Saved Sparks (copy/share/delete, Clear All), Training Sessions (history + detail with metrics/feedback/transcript), Micro-lessons (list/detail).
- Settings (tab): OpenAI API key (Keychain), opt‑in storage toggle, Delete All User Data.

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
- Streaming: Training chat uses streaming responses with UI update throttling (~20 Hz); cancellation supported.

## Empty States
- No situation provided → show examples and presets.
- Provider error → friendly retry + offline sparks.

## Out of Scope (MVP)
- Voice I/O; advanced analytics; user-to-user features; deep behavioral profiling.

## Open Questions
- Model choice within OpenAI, budget, and latency SLA.
- Data retention window for opt-in transcripts; anonymization strategy.
- In-app analytics scope (privacy-first, no 3P SDKs at MVP).
