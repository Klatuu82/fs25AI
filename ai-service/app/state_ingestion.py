from __future__ import annotations

from schemas.messages import GameStateSnapshot


class StateRepository:
    def __init__(self) -> None:
        self._latest: GameStateSnapshot | None = None

    async def ingest(self, snapshot: GameStateSnapshot) -> GameStateSnapshot:
        self._latest = snapshot
        return snapshot

    def latest(self) -> GameStateSnapshot | None:
        return self._latest
