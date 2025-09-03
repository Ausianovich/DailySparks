# UX Flows — DailySpark (iOS)

This document details screen structure, states, and user flows for MVP.

## Conventions
- Platform: iPhone, iOS 17+, SwiftUI.
- Navigation: TabView with three tabs — Generator, Training, Library; Settings accessible from Library or profile icon.

## Screen Map
- Generator
  - GeneratorView (input: situation, audience) → ResultsView (sparks)
  - Presets source: see `docs/presets.md`
- Training
  - TrainingSetupView (choose scenario: Corporate, Date) → TrainingChatView
  - SessionEndView (feedback summary + micro-lesson suggestion)
- Library
  - SavedSparksView
  - MicroLessonsView → LessonDetailView
- Settings
  - SettingsView (storage opt-in, safety level, locale, data controls)

## Generator Flow
1) Context card: Situation/Audience (multi-line), Tone/Length chips, primary "Generate" button.
2) Generate: Validate non-empty; button shows loading; skeleton cards in results area.
3) Results: Fresh Sparks header + vertical list of spark cards with type badge (question/observation/theme).
4) Per-card interactions: tap=Copy; long-press=Copy/Save/Share; swipe right=Save; header action=Save All.

States
- Idle → Loading → Results | Error
- Empty state (first use): example placeholders + 1-tap presets.
- Offline fallback: if provider error, show cached generic sparks with a banner.

Errors
- Validation: show inline hint under fields.
- Network/Provider: toast + Retry; offer offline sparks.

Persistence
- Saved sparks go to SwiftData (Spark entity) with context metadata.
- Default ephemeral for generated content unless saved by user.

## Training Flow
Setup
1) User picks persona from a randomized list (9 items). Pull-to-refresh reshuffles candidates. Persona card shows a short gist.
2) Start: TrainingChatView opens. Random start (AI or user). Typing indicator shows during streaming.

Chat Loop
1) User sends a message.
2) AI replies (1–3 sentences) with a subtle hook.
3) Coaching hint may appear under input as a single line chip.
4) Repeat for 3–6 turns or until user taps End Session.

Hints Logic (minimal rules)
- Short answer detected (<= 4 words) → suggest open question.
- Closed question detected (regex on auxiliaries) → suggest follow-up.
- Long gap (typing idle ≥ 10s) → propose a gentle prompt.
- If strong turn → "No hint" (do not show anything).

End of Session
 - Show Feedback: 2 strengths, 1 suggestion, 1 micro-lesson (link to lesson).
- Actions: Save session (if opt-in enabled), View micro-lesson, Restart.

States
- Setup → Chatting → Feedback | Error
- Error: show retry; transcript remains in-memory until saved.

## Library Flow
Saved Sparks
- List by createdAt desc; manage via swipe (delete) and context menu (share/copy/delete); Clear All in header.

Micro Lessons
- List of 6–8 short lessons (static for MVP) with tags.
- Detail shows content and related actions (start training, generate sparks).

Training Sessions
- List of saved sessions with title (Scenario: Persona) and date/turns.
- Detail shows chat-like transcript, metrics as 2x2 tiles, and feedback section.

## Settings Flow
- Storage Opt-in: toggle to store transcripts and saved sparks.
- Safety Level: standard (default) / strict (fewer edgy topics).
- Data Controls: delete all saved data; export JSON.
- About: version, content policy link.

## Navigation & Deep Links
- Tabs: Generator (default) | Training | Library.
- Deep links: app://generate?situation=...&audience=...

## Accessibility & Performance
- Support Dynamic Type; VoiceOver labels for spark types and buttons.
- Prefer minimal view recomposition; cache results; async tasks cancellable.
