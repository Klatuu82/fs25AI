# Architecture Overview

## Goals

`fs25AI` separates game integration from AI planning so that the Farming Simulator 25 mod remains responsive, observable, and safe even when the external service is unavailable.

## High-level components

### FS25 mod
- **StateCollector**: gathers structured snapshots of fields, crops, contracts, weather, finances, vehicles, storage, messages, and tasks
- **BridgeClient**: handles outbound telemetry and inbound high-level commands without blocking gameplay
- **ActionExecutor**: validates and executes only safe, allow-listed actions
- **DebugHud**: surfaces bridge state, latest telemetry, and warnings for local debugging
- **Config**: centralizes bridge endpoint, throttling, logging, and feature flags

### AI companion service
- **API entrypoint**: FastAPI app exposing HTTP and WebSocket endpoints
- **State ingestion**: validates and stores incoming game state snapshots
- **Planner interface**: stable contract for decision generation
- **Provider abstraction**: pluggable provider layer for rule-based logic, local models, or OpenAI-compatible backends
- **Action routing**: validates requested actions and keeps execution conservative in early milestones

### Shared protocol
The protocol is JSON-based and versioned. It defines payloads for:
- game state snapshots
- AI decisions
- action requests
- execution results
- warnings/errors

## Runtime flow

1. The mod collects a lightweight game-state snapshot.
2. `BridgeClient` publishes telemetry over HTTP or WebSocket.
3. The AI service validates the payload with Pydantic.
4. The planner asks the configured provider for a conservative decision.
5. The service returns a suggestion or dry-run action result.
6. The mod logs the result and only executes actions through `ActionExecutor` when explicitly enabled.

## Reliability and safety

- The AI service is optional at runtime; gameplay must continue without it.
- Lua-side work stays lightweight and avoids heavy inference or blocking calls.
- Commands are high-level, explicit, and routed through a safety boundary.
- Failures are logged and surfaced through telemetry/debug hooks.

## FS25 API assumptions

The mod bootstrap now uses the standard script-mod lifecycle that GIANTS mods commonly wire through `addModEventListener(...)`, with `loadMap`, `update`, and `deleteMap` callbacks owning per-mission startup and teardown.

Other FS25 integration details still stay intentionally conservative: field, vehicle, economy, weather, and contract adapters remain placeholders until those game-specific APIs are confirmed in the target runtime. When those APIs are verified, the adapters should be filled in without changing the boundary between collection, transport, planning, and execution.
