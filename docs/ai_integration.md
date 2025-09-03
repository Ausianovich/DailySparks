# AI Integration & Streaming — DailySpark (OpenAI)

## Overview
- Provider: OpenAI
- Model (testing): 4o-nano (switchable via UserSettings)
- Modes: Non-streaming (Generator, Feedback), Streaming (Training dialogue)

## Streaming Design (Training)
- API: Use OpenAI streaming responses; parse server-sent chunks into an AsyncThrowingStream<String> of deltas.
- Client: AIClient exposes `streamDialogue(context:userTurn:) -> AsyncThrowingStream<AIChunk>`
  - AIChunk: `{ contentDelta: String, isTerminal: Bool }`
- ViewModel: accumulates partial text into the current AI message, updates SwiftUI state on main actor, shows typing indicator.
- Cancellation: cancel Task on back navigation or user stop.
- Hints: trigger hint evaluation after the AI message completes or on user idle.

## Error Handling
- Provider/network errors: stop stream, show retry and keep transcript in-memory.
- Timeout: cancel after N seconds of no deltas; surface friendly message.

## Rate & Tokens
- 4o-nano for development to reduce cost and latency.
- Token budget per turn: ~300 output tokens (Training), ~300 total (Generator).
- Apply brief system prompts; keep user context compact.

## Safety Pipeline
- Pre-prompt instructions to avoid sensitive topics (see content_policy.md).
- Post-process final output for Generator; for Training, rely on system prompt + occasional rephrase if flagged.

## Switching Models
- UserSettings.openAIModel can override default; future upgrades to higher-quality models for production.

