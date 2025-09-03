# Roadmap — DailySpark

## Phase 0 — Foundations (Week 1)
- Docs skeleton, prompts, content policy, evaluation rubric.
- Decide platform (DONE: iOS iPhone-only, iOS 17+), AI provider (DONE: OpenAI), data policy.

## Phase 1 — MVP (Weeks 2–4)
- iOS app skeleton (SwiftUI, NavigationStack, @Observable models).
- SwiftData schema (Sparks, Sessions, Settings) and storage policies.
- Spark Generator: HIG-aligned UI (cards), structured JSON, tone/length controls, per-card interactions, Save All.
- Training: Setup (random personas + refresh), chat UI (bubbles/text, typing), Repair Kit, streaming with throttling, Summary with micro‑lesson link, opt‑in save.
- Library: Saved Sparks management; Training Sessions history + detail; Micro-lessons list/detail.
- Settings: API key, storage opt‑in, delete all.

## Phase 2 — Hardening (Weeks 5–6)
- Latency/quality tuning; offline fallback sparks.
- Basic analytics (privacy-first, no 3P SDKs) and feedback collection.
- Privacy controls (export/delete), opt-in personalization storage.
 - Upgrade path to higher-quality model; configurable via settings.

## Phase 3 — Growth Options (Weeks 7+)
- Additional scenarios; deeper feedback; content expansions.
- Mobile wrapper or PWA polish; basic paywall experiments.
