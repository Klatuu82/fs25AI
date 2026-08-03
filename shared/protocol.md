# Shared Protocol

All cross-process communication uses JSON and a versioned schema.

## Payload types

### Game state snapshot
Represents the latest structured FS25 world state collected by the mod.

### AI decision
Represents a conservative recommendation or no-op response returned by the planner.

### Action request
Represents a high-level command proposed for the mod.

### Execution result
Represents the outcome of validating or executing an action.

### Warning/error
Represents non-fatal issues, degraded behavior, or validation feedback.

## Versioning

- `schema_version` identifies payload compatibility.
- Unknown fields should be ignored conservatively.
- Breaking changes should increment the schema version and update sample payloads.
- Current `GameStateSnapshot` schema version: `1.0.0`
- Current snapshot source identifier: `fs25-mod`

## Lua snapshot serialization contract

The FS25 mod emitter should serialize snapshots as deterministic JSON-compatible
payloads before transport.

- `generated_at` must be a UTC timestamp string in RFC 3339 / ISO 8601 format
  with a trailing `Z`.
- All top-level `GameStateSnapshot` fields must always be present, even when the
  collector is degraded.
- Unsupported top-level categories must use the schema default for their shape:
  empty arrays for lists, empty objects for maps, and conservative scalar
  defaults such as `0`, `"unknown"`, or `"00:00"`.
- Unsupported nested fields should be omitted instead of encoded as `null`
  unless the schema explicitly models them as nullable.
- Degraded or placeholder data must be surfaced through `warnings[]` and
  `raw.adapter_status`, not by silently changing field shapes.

## Early-stage contract rules

- Telemetry is the first-class milestone.
- Suggestions are advisory until safe action execution is explicitly enabled.
- The mod should continue operating when the service is unavailable.
