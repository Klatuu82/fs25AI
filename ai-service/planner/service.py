from __future__ import annotations

from planner.interface import Planner
from providers.base import AIProvider
from schemas.messages import AiDecision, GameStateSnapshot


class PlannerService(Planner):
    def __init__(self, provider: AIProvider) -> None:
        self.provider = provider
        self.provider_name = provider.name

    async def plan(self, snapshot: GameStateSnapshot) -> AiDecision:
        return await self.provider.decide(snapshot)
