# fs25AI

`fs25AI` is a telemetry-first monorepo for a Farming Simulator 25 project focused on AI-assisted, and later partially autonomous, gameplay.

The foundation is intentionally conservative:
- the **in-game FS25 mod** stays lightweight and non-blocking
- the **external AI companion** owns planning and inference
- the **shared protocol** keeps both sides aligned with explicit JSON payloads
- the **roadmap** moves from telemetry to suggestions to safe action execution

## Repository layout

```text
.
├── ai-service/        # FastAPI + Pydantic AI companion service
├── docs/              # Architecture, setup, roadmap
├── mod/               # FS25 mod scaffold (Lua + XML)
├── scripts/           # Utility scripts, including mod packaging
└── shared/            # Shared protocol notes and example payloads
```

## Architecture at a glance

### 1. In-game FS25 mod (`/mod`)
The mod is split into small, safe components:
- `StateCollector` gathers structured game state snapshots
- `BridgeClient` queues telemetry and receives high-level commands
- `ActionExecutor` enforces safe command handling
- `DebugHud` exposes observability hooks
- `Config` centralizes feature toggles and bridge settings

The mod is built around **telemetry-first behavior**. If the AI service is offline, the game remains playable and the mod degrades to logging and local buffering.

### 2. External AI companion (`/ai-service`)
The AI service uses:
- **Python 3.12+**
- **FastAPI** for HTTP/WebSocket endpoints
- **Pydantic** for request/response schemas
- a **pluggable provider interface** so the planner can later target local models, OpenAI-compatible APIs, or rule-based strategies

The initial implementation stores incoming snapshots, returns conservative AI suggestions, and keeps action routing in safe dry-run mode.

### 3. Shared protocol (`/shared`)
The shared layer documents and demonstrates JSON payloads for:
- game state snapshots
- AI decisions
- action requests
- execution results
- warnings and errors

## Milestones

1. **Telemetry only** — collect and expose structured state safely
2. **AI suggestions only** — return recommendations without taking control
3. **Safe high-level action execution** — route explicit, allow-listed commands
4. **More autonomous orchestration** — expand planning with stronger safeguards

## Quick start

### AI service
```bash
python -m pip install -e ./ai-service[dev]
pytest /home/runner/work/fs25AI/fs25AI/ai-service/tests
uvicorn app.main:app --app-dir /home/runner/work/fs25AI/fs25AI/ai-service --reload
```

### Build the FS25 mod zip
```bash
python /home/runner/work/fs25AI/fs25AI/scripts/build_mod_zip.py
```

The zip is written to `dist/FS25_fs25AI_<version>.zip`, matching the naming
convention used by the other installed FS25 mods.

## Documentation

- [Architecture overview](docs/architecture.md)
- [FS25 telemetry API reference](docs/fs25-telemetry-reference.md)
- [Setup guide](docs/setup.md)
- [Roadmap](docs/roadmap.md)
- [Shared protocol](shared/protocol.md)

## Important implementation notes

- Unknown FS25-specific integration points are left as **documented adapter stubs** rather than guessed engine calls.
- Heavy inference does **not** run in the Lua update loop.
- Input emulation is explicitly out of scope for the foundation and should remain a last resort.
- Single-player is the default target; multiplayer support can be added later.


Latest Session: copilot --resume=3392a307-4769-4e75-bd84-f94869fa224e
