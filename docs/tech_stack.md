# Tech Stack — DailySpark (MVP)

## Platform
- iOS (iPhone only), iOS 17+

## UI & State
- SwiftUI (NavigationStack, TabView as needed)
- Observation: @Observable / @State / @Environment
- Theming & Accessibility: Dynamic Type, VoiceOver labels

## Concurrency
- Swift modern concurrency (async/await, Task, TaskGroup)
- Isolation patterns: actors for shared services (e.g., AIClient, Cache)

## Data Layer
- SwiftData for local persistence
  - Entities (MVP): Spark, TrainingSession, Persona (seed), MicroLesson, UserSettings
  - Migrations: lightweight, additive only for MVP
- Caching: on-device cached sparks for offline fallback

## Networking & AI
- URLSession with async/await
- AI Provider: OpenAI (4o-nano for testing; switchable); abstraction to allow provider swap
- Streaming: SSE/streaming responses parsed into an AsyncThrowingStream of content deltas
- UI: Incremental rendering in SwiftUI (main-actor updates), with cancel on navigation/back
- Safety pass: lightweight heuristic/classifier + rewrite fallback

## Configuration
- Secrets: OpenAI API key stored in iOS Keychain for local testing (no secrets in repo)
- Feature flags via simple struct / build configs

## Testing
- Unit tests for prompt builders and safety filters
- Snapshot tests for key SwiftUI screens (optional MVP)

## Analytics (MVP-minimal)
- Privacy-first: basic in-house counters for usage events; no 3rd-party SDKs
