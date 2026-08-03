from __future__ import annotations

from schemas.messages import ActionRequest, ExecutionResult, WarningMessage


class ActionRouter:
    def __init__(self, execution_enabled: bool = False) -> None:
        self.execution_enabled = execution_enabled
        self.allowed_actions = {"acknowledgeSuggestion", "setGuidanceMarker", "review_harvest_plan"}

    async def route(self, request: ActionRequest) -> ExecutionResult:
        if request.action_type not in self.allowed_actions:
            return ExecutionResult(
                request_id=request.request_id,
                status="rejected",
                message="Action is not allow-listed.",
                executed=False,
                details={"action_type": request.action_type},
                warnings=[
                    WarningMessage(
                        code="action.not_allowed",
                        message="The requested action is outside the current safety boundary.",
                        severity="warning",
                    )
                ],
            )

        if request.mode == "execute" and not self.execution_enabled:
            return ExecutionResult(
                request_id=request.request_id,
                status="accepted",
                message="Execution is disabled for the telemetry-first milestone.",
                executed=False,
                details={"mode": request.mode},
            )

        return ExecutionResult(
            request_id=request.request_id,
            status="accepted",
            message="Action reviewed successfully.",
            executed=request.mode == "execute" and self.execution_enabled,
            details={"mode": request.mode, "action_type": request.action_type},
        )
