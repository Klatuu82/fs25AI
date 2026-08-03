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

The script packages the contents of `/mod` into a versioned artifact such as
`dist/fs25AI-mod-0.1.0.0.zip`.

During packaging, the script validates that:

- `modDesc.xml` is present
- every file referenced from `extraSourceFiles` exists and is included
- the ZIP is only published after archive validation succeeds

### Reproducible GitHub Actions packaging

Maintainers can build the install-ready ZIP on a clean GitHub runner from the
Actions UI:

1. Open **Actions** in GitHub.
2. Select **Build FS25 Mod ZIP**.
3. Click **Run workflow**.
4. Optionally enter a branch, tag, or commit SHA in `ref` to package a specific revision.
5. Start the workflow and wait for the `Build install-ready FS25 mod ZIP` job to finish.

The completed workflow uploads the generated ZIP as an artifact named after the
archive file, for example `fs25AI-mod-0.1.0.0.zip`.

To download it:

1. Open the finished workflow run.
2. In the **Artifacts** section, download the `fs25AI-mod-<version>.zip` artifact.
3. Extract or copy the ZIP as needed for installation or release publication.

The same workflow can also be called by other GitHub workflows through
`workflow_call`, which makes it the reproducible shared build path for release
automation while keeping the local script available for quick developer checks.

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
