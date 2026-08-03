from __future__ import annotations

from abc import ABC, abstractmethod

from schemas.messages import AiDecision, GameStateSnapshot


class AIProvider(ABC):
    name = "abstract"

    @abstractmethod
    async def decide(self, snapshot: GameStateSnapshot) -> AiDecision:
        raise NotImplementedError
