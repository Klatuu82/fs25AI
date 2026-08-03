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

## Early-stage contract rules

- Telemetry is the first-class milestone.
- Suggestions are advisory until safe action execution is explicitly enabled.
- The mod should continue operating when the service is unavailable.
