# Roadmap

## Milestone 1: Telemetry only
- Collect structured game state safely inside the mod
- Expose telemetry to the external service
- Validate protocol payloads and basic service health

## Milestone 2: AI suggestions only
- Generate conservative recommendations from the latest snapshot
- Surface suggestions in logs, debug views, or future GUI panels
- Keep all execution paths manual or dry-run only

## Milestone 3: Safe high-level action execution
- Add explicit allow-listed commands
- Gate execution behind feature flags and safety checks
- Return structured execution results for observability

## Milestone 4: More autonomous orchestration
- Expand planner/provider capabilities
- Coordinate multi-step tasks
- Revisit multiplayer implications after the single-player path is stable
