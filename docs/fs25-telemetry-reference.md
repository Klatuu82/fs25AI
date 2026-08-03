# FS25 Telemetry API Reference

## Scope and version

This reference documents only the Farming Simulator 25 runtime hooks and data
access patterns that are currently confirmed in this repository.

- Game version observed during local validation: `1.21.1.0`
- Mod descriptor baseline: `descVersion="107"`
- Current protocol version: `1.0.0`

Anything not listed here as **confirmed** must be treated as an adapter stub or
placeholder until it is verified in the target runtime.

## Confirmed lifecycle hooks

The mod currently uses the standard script-mod listener pattern:

- `addModEventListener(FS25AI)`
- `FS25AI:loadMap(mapFilename)`
- `FS25AI:update(dt)`
- `FS25AI:draw()`
- `FS25AI:mouseEvent(posX, posY, isDown, isUp, button)`
- `FS25AI:deleteMap()`

### Lifecycle guarantees currently relied on

| Hook | Status | Current use | Notes |
| --- | --- | --- | --- |
| `loadMap(mapFilename)` | Confirmed | Per-mission runtime bootstrap | Called when entering a mission/map. Safe place to create mod runtime state. |
| `update(dt)` | Confirmed | Lightweight telemetry polling and heartbeat updates | Runs frequently and must stay non-blocking. |
| `draw()` | Confirmed | Debug/telemetry window rendering | UI-only work; should not perform heavy logic. |
| `mouseEvent(...)` | Confirmed | Dragging the telemetry window | Used only for HUD interaction. |
| `deleteMap()` | Confirmed | Runtime teardown and final persistence | Safe place to release mission-local state and flush UI settings. |

## Confirmed mission/session access

These access paths are already used by the mod and are treated as verified for
single-player bootstrap and early telemetry work:

| Category | Confirmed access path | Nil-safe behavior | Current usage |
| --- | --- | --- | --- |
| Current mission object | `g_currentMission` | Collector and bootstrap guard against `nil` | Root for mission-local telemetry lookups |
| Savegame/session identity | `g_currentMission.missionInfo.savegameName` | Falls back to `"unknown"` | Serialized as `session_id` |
| Current farm | `g_currentMission:getFarmId()` | Falls back to the local player `farmId` when needed | Resolving farm-scoped telemetry |
| Local player | `g_currentMission.playerSystem:getLocalPlayer()` | Accessed only behind mission/player-system guards | Farm fallback for early telemetry |
| Map identifier | `loadMap(mapFilename)` argument | Logged directly | Smoke-test logging and operator verification |
| Mission time | `g_currentMission.time` | Falls back to `environment.dayTime`, then `0` | Heartbeat/telemetry scheduling |
| Environment daytime | `g_currentMission.environment.dayTime` | Used only when `mission.time` is unavailable | Scheduling fallback |
| Environment day counters | `g_currentMission.environment.currentDay` / `currentMonotonicDay` | Default to `0` when unavailable | Serialized as early weather/day telemetry |
| Environment period | `g_currentMission.environment.currentPeriod` | Falls back to `"unknown"` | Serialized conservatively as a period-based season marker |
| Mod version | `g_modManager:getModByName(g_currentModName).version` | Falls back to `"unknown"` | Logged during load |

## Confirmed filesystem/runtime services

These engine services are confirmed through current mod code:

| Service | Confirmed API | Purpose |
| --- | --- | --- |
| Structured logging | `Logging.info(...)` with `print(...)` fallback | Startup/shutdown diagnostics |
| User profile path | `getUserProfileAppPath()` | Persisting HUD window position outside savegames |
| XML persistence | `XMLFile.load(...)`, `XMLFile.create(...)` | Reading/writing `fs25AI_window.xml` |
| Mouse cursor visibility | `g_inputBinding:setShowMouseCursor(...)` | Enabling drag interaction for the telemetry window |
| Overlay creation | `g_overlayManager:createOverlay(...)` | Drawing the telemetry window background |
| Farm manager | `g_farmManager:getFarmById(farmId)` | Returns `nil` safely when the farm cannot be resolved | Reading confirmed farm balance telemetry |
| Mission manager | `g_missionManager:getMissions()` | Collector degrades to placeholders when unavailable | Reading contract/job telemetry |

## Telemetry categories: confirmed vs placeholder

The shared `GameStateSnapshot` schema already reserves several categories, but
most of them are intentionally still placeholders on the FS25 side.

| Snapshot category | Status | Confirmed source today | Notes |
| --- | --- | --- | --- |
| `schema_version` | Confirmed | `Config.protocol.snapshotSchemaVersion` | Shared protocol contract value |
| `generated_at` | Partially confirmed | `os.date(...)` only if available | Falls back to a safe placeholder timestamp in FS25 runtime |
| `source` | Confirmed | Constant `"fs25-mod"` | Stable emitter identifier |
| `session_id` | Confirmed | `missionInfo.savegameName` | Current best single-player session identifier |
| `fields` | Placeholder | None confirmed yet | Do not guess field manager APIs |
| `vehicles` | Placeholder | None confirmed yet | Do not guess vehicle iteration APIs |
| `jobs` / contracts | Partially confirmed | `g_missionManager:getMissions()`, `mission:getUniqueId()`, `mission:getTitle()`, `mission.status`, `mission.reward`, `mission.completion` | Emits real contract/job rows while preserving placeholder handling when the mission manager is unavailable |
| `economy.money` | Confirmed | `g_farmManager:getFarmById(g_currentMission:getFarmId()):getBalance()` | Emits the active farm balance |
| `economy.loan` | Placeholder | None confirmed yet | Remains `0` until a verified runtime accessor is documented |
| `economy.prices` | Placeholder | None confirmed yet | No price-table integration yet |
| `weather.time` / `weather.day` | Partially confirmed | `environment.dayTime`, `environment.currentDay`, `environment.currentMonotonicDay` | Emits real mission clock/day data |
| `weather.season` | Partially confirmed | `environment.currentPeriod` | Serialized conservatively as `period_<n>` until a canonical season-name accessor is verified |
| `weather.forecast` | Placeholder | None confirmed yet | Remains `"unknown"` until a forecast accessor is verified |
| `storages` | Placeholder | None confirmed yet | No silo/storage adapters yet |
| `warnings` | Placeholder-ready | Local collector may append warnings later | Current collector only stores an assumptions note under `raw` |
| `active_tasks` | Partially confirmed | Derived from mission statuses `PREPARING` and `RUNNING` | Emits pending/active tasks from the current mission list |
| `raw.assumptions` | Confirmed | Static conservative note | Explicitly marks unknown engine integrations |
| `raw.serialization_policy` | Confirmed | `Config.protocol.unsupportedFieldPolicy` | Documents how unsupported nested fields are emitted |

## Nil/error handling rules already verified

The current telemetry path must remain safe when FS25 objects are unavailable:

- `g_currentMission` may be `nil` outside a loaded mission.
- `missionInfo` may be absent and must not be indexed blindly.
- `g_currentMission:getFarmId()` may not resolve a usable farm during transitions;
  the collector falls back to the local player `farmId` before degrading.
- `mission.time` may be absent; `environment.dayTime` is the only current
  fallback used for timing.
- `os.date` is **not** guaranteed in the FS25 Lua runtime and must be guarded.
- `g_farmManager` and `g_missionManager` must be guarded before use so the
  collector can degrade cleanly during early mission lifecycle transitions.
- Unconfirmed engine managers and accessors must not be called from production
  Lua until they are observed and documented.

## Lightweight polling guidance

For the current milestone, `update(dt)` should only do bounded work:

1. update the diagnostic heartbeat
2. check the configured telemetry interval
3. collect a lightweight snapshot
4. enqueue telemetry without blocking gameplay

Heavy inference, filesystem scans, and speculative engine traversal do not
belong in the update loop.

## Explicitly unconfirmed areas

The following categories still require runtime verification before production
use and belong to follow-up telemetry issues:

- field ownership, crop, and growth-state APIs
- contract/job details beyond the confirmed mission-list, status, reward, and completion accessors
- vehicle/tool iteration and attachment state
- loan and sell-price managers
- storage/silo inventory access
- weather forecast APIs beyond clock/day/period access

Until those are confirmed, keep them behind placeholder adapters and document
every newly verified API before relying on it in `StateCollector`.
