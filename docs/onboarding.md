# Onboarding — DailySpark (MVP)

This document describes the onboarding experience implemented in the iOS app, its goals, screen content, logic, and technical behavior.

## Goals
- Communicate value in under 10–12 seconds.
- Show how the app works (context → sparks → training) with clear expectations.
- Set privacy expectations up front (opt‑in storage; safety filters).
- Let users try a super‑short practice chat before entering the app.

## Structure (4 screens)
Presented as a full‑screen cover on first launch. Page indicator shows 4 steps.

1) Value — “Meet DailySpark”
   - Icon: `sparkles`
   - Title: “Meet DailySpark”
   - Subtitle: “Light, safe small‑talk help in seconds.”
   - Bullets:
     - “Get 3–5 tailored conversation sparks”
     - “Practice short, realistic chats with feedback”
     - “Keep favorites for later”

2) How It Works
   - Icon: `list.bullet`
   - Title: “How it works”
   - Subtitle: “Tell us the context — we’ll do the rest.”
   - Bullets:
     - “Pick situation and audience”
     - “Generate fresh questions and observations”
     - “Tap to Copy, Save, or Share”
     - “Train in 3–6 short turns”

3) Privacy & Safety
   - Icon: `lock.shield`
   - Title: “Privacy & Safety”
   - Subtitle: “You’re in control of what’s stored.”
   - Bullets:
     - “No transcripts saved by default”
     - “Opt in to store training history”
     - “Safety filters avoid sensitive topics”
     - “OpenAI key stored in Keychain (optional)”

4) Quick Practice (Training Preview)
   - Icon/color theme: teal variant
   - Title: “Try a quick chat”
   - Subtitle: “Say up to three lines to get a feel.”
   - Inline chat with a friendly AI partner (“Alex”).
   - After the user sends 3 messages:
     - Input hides, keyboard dismisses, and a “Finish and get started” button appears.
     - Tapping the button ends onboarding (continues to paywall check as usual).

## Behavior & Logic
- Presentation: `OnboardingView` is shown as a full‑screen cover if `didCompleteOnboarding == false`.
- Navigation:
  - Page indicator: 4 steps; accessible label “Page X of 4”.
  - “Skip” button available; respects subscription check.
  - CTA on pages 1–3: “Next” / “Get Started”. CTA hidden on page 4 (finish button is inline in the chat).
- Visuals: dynamic gradient backgrounds and subtle animated blobs; page‑specific tint.
- Text & Localization: English copy by default; aligns with content policy and tone rules.

## Training Preview — Technical Notes
- Component: `OBTrainingPreviewPage` (within `OnboardingView`).
- Streaming: Uses `AIClient.shared.streamTrainingReply(...)` to generate real‑time AI replies.
  - Persona: short, friendly seed (e.g., “Friendly, curious conversation partner; keeps things light, warm, and safe.”)
  - Context: “Casual small talk (onboarding preview)”
  - Assistant name: “Alex” (deterministic; non‑personal data)
- UX constraints:
  - Max 3 user turns; Send is disabled while streaming to avoid overlap.
  - Adds an empty assistant bubble and fills it with streaming deltas.
  - After 3rd user turn: input hidden, keyboard dismissed, inline finish button shown.
  - On finish: cancels streaming if active, proceeds to regular finish/paywall flow.
- Error & Offline:
  - If streaming fails (e.g., missing API key or network), a gentle fallback line is shown.
  - The preview is non‑persistent; nothing is stored by default.

## Accessibility
- Page indicator has VoiceOver label “Page X of 4”.
- Large tap targets; readable contrast; Dynamic Type supported by default SwiftUI controls.
- Typing indicator displayed during streaming replies.

## Telemetry (future)
- Track CTA taps and page dwell (privacy‑first, no 3P SDKs).
- Track whether users complete the 3‑turn preview.

## Open Questions / Future Enhancements
- Add quick persona/scenario toggle (Corporate/Date) to the preview.
- Offer “Start with presets” action after onboarding to jump into Generator with 1‑tap context.
- Localize onboarding copy per app locale when localization lands.

