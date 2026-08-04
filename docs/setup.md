# Setup

## Prerequisites

- Windows 10/11 with a local Farming Simulator 25 installation
- Python 3.12+
- Access to your local FS25 user profile under `Documents\My Games\FarmingSimulator2025`

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

## Build the FS25 mod ZIP

Build the mod ZIP from the repository root:

```bash
python /home/runner/work/fs25AI/fs25AI/scripts/build_mod_zip.py
```

The script packages the contents of `/mod` into a versioned artifact such as
`dist/FS25_fs25AI_0_1_0_0.zip`.

During packaging, the script validates that:

- `modDesc.xml` is present
- every file referenced from `extraSourceFiles` exists and is included
- the ZIP is only published after archive validation succeeds

## Install or replace the ZIP on Windows

1. Build the ZIP locally and note the version in `/home/runner/work/fs25AI/fs25AI/mod/modDesc.xml`.
2. Close Farming Simulator 25 before replacing any installed archive.
3. Open your mods folder in Windows Explorer:
   `Documents\My Games\FarmingSimulator2025\mods`
4. Remove or move any older `fs25AI` ZIP you previously installed so that only one copy of the mod remains in the folder.
5. Copy the newly built `dist/FS25_fs25AI_<version>.zip` into the `mods` folder without unpacking it.
6. Start the game and enable the mod for the savegame or map you want to test.

Keeping only one installed ZIP matters because FS25 can otherwise load an older archive and make it look like your latest build was ignored.

## Reproducible GitHub Actions packaging

Maintainers can build the install-ready ZIP on a clean GitHub runner from the
Actions UI:

1. Open **Actions** in GitHub.
2. Select **Build FS25 Mod ZIP**.
3. Click **Run workflow**.
4. Optionally enter a branch, tag, or commit SHA in `ref` to package a specific revision.
5. Start the workflow and wait for the `Build install-ready FS25 mod ZIP` job to finish.

The completed workflow uploads the generated ZIP as an artifact named after the
archive file, for example `FS25_fs25AI_0_1_0_0.zip`.

To download it:

1. Open the finished workflow run.
2. In the **Artifacts** section, download the `FS25_fs25AI_<version>.zip` artifact.
3. Extract or copy the ZIP as needed for installation or release publication.

The same workflow can also be called by other GitHub workflows through
`workflow_call`, which makes it the reproducible shared build path for release
automation while keeping the local script available for quick developer checks.

## Publish a GitHub Release

Release tags use the four-part mod version from `mod/modDesc.xml`, prefixed with
`v`, for example `v0.1.0.0`. Pushing a tag in that format runs the release
workflow, which calls the validated packaging workflow and publishes
`FS25_fs25AI_0_1_0_0.zip` to a newly created GitHub Release for that tag.

After the workflow completes, download the ZIP from the release's **Assets**
section on the repository's GitHub Releases page. Packaging must succeed before
the release asset is created or uploaded.

The **Build FS25 Mod ZIP** workflow remains available through
**Actions → Run workflow** for branch, tag, or commit-SHA builds. Manual runs
upload a workflow artifact only; they do not create or modify a GitHub Release.

## Suggested local workflow

1. Run the AI service locally.
2. Point the mod bridge configuration at the local endpoint.
3. Start with telemetry collection only.
4. Inspect the JSON payloads in `/shared/samples` while filling in real FS25 adapters.
5. Check `docs/fs25-telemetry-reference.md` before adding new FS25 runtime lookups.

## FS25 smoke-test and log verification

### Where to find the game log

FS25 writes its main runtime log to:

`Documents\My Games\FarmingSimulator2025\log.txt`

Keep that file open while testing or reopen it after quitting the game.

### Expected successful load signal
... (rest of content)

After copying the ZIP into the mods folder and loading into a savegame or map:

1. Open `log.txt`.
2. Confirm it contains `[fs25AI] Startup smoke signal active`.
3. Confirm it then contains a line like:
   `[fs25AI] Loaded mod version 0.1.0.0 for map '...' (savegame: ...)`
4. While the mission is running, confirm the in-game debug HUD shows `fs25AI active - heartbeat ...`.
5. Return to the main menu or switch missions and confirm `log.txt` contains `[fs25AI] Shutdown complete for current mission`.

Those entries show that the script-mod lifecycle hooks executed for mission load, update, and teardown.

### How to confirm the correct ZIP version is loaded

- Compare the version inside `/home/runner/work/fs25AI/fs25AI/mod/modDesc.xml` with the version reported in `log.txt` by `Loaded mod version ...`.
- If you just replaced the ZIP, make sure the log reports the new version on the next load.
- If the log still shows an older version, quit the game and re-check the `mods` folder for a second `fs25AI` archive that was not removed.

### Diagnosing a failed load

If the smoke signal does not appear in `log.txt`, check the same log file for nearby FS25 error lines before assuming the Lua bootstrap is broken.

Common things to verify:

- the ZIP is still compressed and was not copied into the mods folder as an extracted directory
- only one `fs25AI` ZIP is installed
- the archive build completed successfully and includes `modDesc.xml`
- `log.txt` does not report a failed mod load, XML parsing problem, or missing script file from `extraSourceFiles`
- the mod is actually enabled for the current savegame

If the mod loads but telemetry does not reach the AI service, treat that separately from bootstrap success: the startup smoke and shutdown signals confirm the local mod lifecycle is active even when the bridge endpoint is offline. **To troubleshoot telemetry specifically, refer to the [Telemetry E2E Verification Checklist](docs/telemetry-e2e-checklist.md).**


## Current scaffold limitations

The current scaffold is intentionally conservative:

- telemetry, field, vehicle, economy, weather, and contract adapters are still placeholders until the target FS25 APIs are confirmed
- the AI service can be offline without blocking gameplay, so bridge failures do not prove the mod failed to load
- action execution remains disabled by default and the service is still aimed at telemetry and conservative suggestions first
- the debug HUD and startup diagnostics are meant for local smoke tests and can be turned off in `mod/scripts/Config.lua` once bootstrap validation is complete
