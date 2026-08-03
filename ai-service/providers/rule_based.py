from __future__ import annotations

from providers.base import AIProvider
from schemas.messages import AiDecision, DecisionAction, GameStateSnapshot, WarningMessage


class RuleBasedProvider(AIProvider):
    name = "rule-based"

    async def decide(self, snapshot: GameStateSnapshot) -> AiDecision:
        if snapshot.warnings:
            return AiDecision(
                decision_type="suggestion",
                summary="Resolve warnings before attempting higher-risk work.",
                confidence=0.82,
                recommended_actions=[
                    DecisionAction(
                        action_type="inspect_warnings",
                        reason="The game state includes warnings that may block safe automation.",
                        priority="high",
                    )
                ],
                warnings=snapshot.warnings,
            )

        if snapshot.active_tasks:
            first_task = snapshot.active_tasks[0]
            return AiDecision(
                decision_type="suggestion",
                summary=f"Continue monitoring '{first_task.title}'.",
                confidence=0.64,
                recommended_actions=[
                    DecisionAction(
                        action_type="review_task",
                        reason="Telemetry indicates an active task that may need player attention.",
                        priority="normal",
                        parameters={"task_id": first_task.id},
                    )
                ],
            )

        return AiDecision(
            decision_type="noop",
            summary="Telemetry received. No action suggested yet.",
            confidence=0.35,
            warnings=[
                WarningMessage(
                    code="planner.telemetry_only",
                    message="The planner is operating in a conservative telemetry-first mode.",
                    severity="info",
                )
            ],
        )
