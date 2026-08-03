# Setup

## Prerequisites

- Python 3.12+
- A local Farming Simulator 25 modding workflow

## AI service

From the repository root:

```bash
python -m pip install -e ./ai-service[dev]
pytest /home/runner/work/fs25AI/fs25AI/ai-service/tests
uvicorn app.main:app --app-dir /home/runner/work/fs25AI/fs25AI/ai-service --host 127.0.0.1 --port 8000
```

### Available endpoints

- `GET /health`
- `POST /telemetry/snapshots`
- `GET /telemetry/snapshots/latest`
- `POST /actions/route`
- `WS /ws/telemetry`

## FS25 mod packaging

Build the mod zip from `/mod`:

```bash
python /home/runner/work/fs25AI/fs25AI/scripts/build_mod_zip.py
```

The script packages the contents of `/mod` into `dist/fs25AI-mod.zip`.

## Suggested local workflow

1. Run the AI service locally.
2. Point the mod bridge configuration at the local endpoint.
3. Start with telemetry collection only.
4. Inspect the JSON payloads in `/shared/samples` while filling in real FS25 adapters.

## FS25 runtime bootstrap verification

After packaging and copying the mod into the FS25 mods folder:

1. Start or load a savegame.
2. Confirm `log.txt` contains `[fs25AI] Startup smoke signal active` followed by a line like `[fs25AI] Loaded mod version ...`.
3. Confirm the in-game debug HUD shows an `fs25AI active - heartbeat ...` status while the mission is running.
4. Return to the main menu or switch missions and confirm `log.txt` contains `[fs25AI] Shutdown complete for current mission`.
5. If needed, disable the smoke signal through `mod/scripts/Config.lua` by toggling `diagnostics.startupSignalEnabled`, `diagnostics.heartbeatEnabled`, or `features.debugHudEnabled`.
6. If telemetry adapters are still placeholders, treat that as expected scaffold behavior rather than evidence that the lifecycle hook failed.

The runtime entrypoint is intentionally bound through the script-mod listener callbacks `loadMap`, `update`, and `deleteMap` instead of relying on Lua file-load side effects alone.
