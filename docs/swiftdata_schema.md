# SwiftData Schema — DailySpark (iOS 17+)

This document defines MVP entities, attributes, relationships, and storage policies. It is implementation-ready but code-free to keep flexibility.

## Principles
- Opt-in persistence: do not store transcripts unless user enables it.
- Additive migrations only for MVP (no breaking field removals/renames).
- Keep domain simple; prefer denormalized context labels alongside IDs for UX.

## Entities

### Spark
- id: UUID (primary)
- createdAt: Date (index desc)
- type: String ("question" | "observation" | "theme")
- text: String (1–280 chars target)
- situationId: String (from presets)
- situationLabel: String (snapshot for UX)
- audienceId: String (from presets)
- audienceLabel: String (snapshot for UX)
- locale: String (e.g., "en", "ru")
- source: String ("ai" | "offline" | "manual"), default "ai"
- saved: Bool (default true; only saved items persist)

Indexes
- createdAt, type, situationId, audienceId

### TrainingSession
- id: UUID (primary)
- startedAt: Date (index)
- endedAt: Date? (nullable until end)
- scenario: String ("corporate" | "date")
- personaId: String? (seed reference)
- personaLabel: String (snapshot)
- transcript: [DialogueTurn] (embedded array JSON or child records)
- metrics: TrainingMetrics (embedded)
- feedback: FeedbackSummary? (embedded, nullable)
- kept: Bool (default false; set true if user saves session)
- locale: String (e.g., "en", "ru")

Indexes
- startedAt, scenario

### DialogueTurn (embedded/value)
- id: UUID
- role: String ("user" | "ai" | "hint")
- text: String
- timestamp: Date

### TrainingMetrics (embedded/value)
- shortAnswersCount: Int
- openQuestionsCount: Int
- hintsShown: Int
- turns: Int

### FeedbackSummary (embedded/value)
- strengths: [String] (max 3)
- suggestion: String (single actionable next step)
- microLessonId: UUID? (optional link)

### MicroLesson
- id: UUID (primary)
- title: String
- body: String (short, ~200–400 words)
- tags: [String]
- lastUpdated: Date

Indexes
- lastUpdated, tags (where supported)

### Persona (seed/static, optional persistence)
- id: String (primary)
- name: String
- description: String (1–2 sentences)
- scenario: String ("corporate" | "date")
- toneNotes: String?

### UserSettings (singleton)
- id: UUID (fixed single row)
- storeTranscripts: Bool (default false)
- safetyLevel: String ("standard" | "strict")
- locale: String (default "en")
- openAIModel: String? (optional override)
- lastUsedSituationId: String?
- lastUsedAudienceId: String?

## Relationships
- TrainingSession.feedback.microLessonId → MicroLesson.id (optional, soft reference)
- Spark has no hard foreign keys; stores context IDs and labels for resilience.
- Persona may be loaded from seed JSON; persistence optional for local editing.

## Storage Policies
- Gate TrainingSession writes behind UserSettings.storeTranscripts.
- Sparks only persist on explicit Save action; generated-but-unsaved remain in-memory.
- Provide Delete All and Export JSON in Settings.

## Migration Plan (MVP)
- v1: Entities above.
- v1.1: Add Spark.favorite (Bool), optional; add MicroLesson.locale.
- v1.2: Add TrainingSession.rating (Int?); keep prior fields.

## Query Examples (conceptual)
- Recent sparks: filter by createdAt desc, limit 50.
- By preset: situationId == X AND audienceId == Y.
- Sessions: scenario == "corporate" order by startedAt desc.

## Seeding
- Presets from `docs/presets.md` (bundle JSON) for situations/audiences.
- Micro-lessons: bundle 6–8 static items on first launch.
- Personas: 2 seeds (Corporate colleague, First date).

