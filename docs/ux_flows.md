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
1) Idle: User sees two fields (Situation, Audience) + Presets + Generate button.
2) Generate: Validate non-empty; show loading indicator.
3) Results: Show 3–5 sparks grouped by type (Question/Observation/Theme).
4) Actions: Regenerate, Save spark, Copy spark, Share (iOS share sheet).
5) Optional: Quick feedback buttons (Helpful / Not relevant) for tuning.

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
1) User picks scenario (Corporate | Date). Brief scenario card shows persona gist.
2) Start: Show TrainingChatView with AI opening line.

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
- Show Feedback: 2 strengths, 1 suggestion, 1 micro-lesson.
- Actions: Save session (if opt-in enabled), View micro-lesson, Restart.

States
- Setup → Chatting → Feedback | Error
- Error: show retry; transcript remains in-memory until saved.

## Library Flow
Saved Sparks
- List by createdAt desc; filters by type; swipe to copy/delete.
- Detail: show full text, context, quick share.

Micro Lessons
- List of 6–8 short lessons (static for MVP) with tags.
- Detail shows content and related actions (start training, generate sparks).

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
