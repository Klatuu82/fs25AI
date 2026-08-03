from __future__ import annotations

from abc import ABC, abstractmethod

from schemas.messages import AiDecision, GameStateSnapshot


class Planner(ABC):
    @abstractmethod
    async def plan(self, snapshot: GameStateSnapshot) -> AiDecision:
        raise NotImplementedError
