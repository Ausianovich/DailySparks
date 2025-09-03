# Architecture — DailySpark (MVP)

## Overview
A modular, lightweight architecture optimized for iOS 17+ and SwiftUI.

- Presentation: SwiftUI views + view models (@Observable) for Generator, Training, Library.
- Domain: Plain Swift types (Spark, PersonaProfile, DialogueTurn, FeedbackSummary).
- Data: SwiftData models for persisted entities and repositories.
- Services: AIClient (OpenAI), SafetyFilter, SparkBuilder, TrainingEngine.

## Modules (logical)
- Generator
  - Views: GeneratorView, SparkListView
  - VM: GeneratorViewModel (build prompt → call AI → map → store optional)
  - Data: SparkRepository (SwiftData), OfflineSparkStore
- Training
  - Views: TrainingSetupView, TrainingChatView
  - VM: TrainingViewModel (scenario persona → dialogue loop → hints → feedback)
  - Services: CoachingService (hints), FeedbackService
- Library
  - Views: MicroLessonsView, SavedSparksView
  - Data: LessonRepository, SparkRepository

## SwiftData Entities (MVP)
- See detailed schema in `docs/swiftdata_schema.md`.

## Concurrency & Isolation
- AIClient isolated via actor; exposes async funcs and streaming APIs for generator/training/hints.
- Streaming API shape: AsyncThrowingStream<AIChunk> where AIChunk = {contentDelta: String, isTerminal: Bool}
- Repositories as actors or main-safe classes; UI updates on main actor.
- Cancellation via Task handles on view models.

## Networking Flow (OpenAI)
1) Build prompt from context.
2) For Training: call AIClient.streamDialogue(...) → consume chunks and render progressively; for Generator: call generate(...), optionally stream.
3) SafetyFilter.checkAndRewrite(...) (post-process final text or per item for Generator).
4) Map to domain types; cache/save per user choice.

## Error/Offline Handling
- On provider/network errors, show friendly retry.
- Offer offline sparks from cache for Generator.
