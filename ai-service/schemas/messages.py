from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Literal
from uuid import uuid4

from pydantic import BaseModel, Field


class WarningMessage(BaseModel):
    code: str
    message: str
    severity: Literal["info", "warning", "error"] = "info"
    details: dict[str, Any] = Field(default_factory=dict)


class ActiveTask(BaseModel):
    id: str
    title: str
    status: Literal["pending", "active", "blocked", "done"] = "pending"


class FieldStatus(BaseModel):
    field_id: str
    name: str
    owned: bool = False
    crop_type: str | None = None
    growth_state: str | None = None
    needs_attention: bool = False
    area_hectares: float | None = None


class VehicleState(BaseModel):
    vehicle_id: str
    name: str
    category: str
    fill_level: float = 0.0
    fill_type: str | None = None
    active_task: str = "idle"


class EconomyState(BaseModel):
    money: int = 0
    loan: int = 0
    prices: dict[str, int] = Field(default_factory=dict)


class GameStateSnapshot(BaseModel):
    schema_version: str = "1.0.0"
    generated_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    source: str = "fs25-mod"
    session_id: str = "unknown"
    fields: list[FieldStatus] = Field(default_factory=list)
    vehicles: list[VehicleState] = Field(default_factory=list)
    jobs: list[dict[str, Any]] = Field(default_factory=list)
    economy: EconomyState = Field(default_factory=EconomyState)
    weather: dict[str, Any] = Field(default_factory=dict)
    storages: list[dict[str, Any]] = Field(default_factory=list)
    warnings: list[WarningMessage] = Field(default_factory=list)
    active_tasks: list[ActiveTask] = Field(default_factory=list)
    raw: dict[str, Any] = Field(default_factory=dict)


class DecisionAction(BaseModel):
    action_type: str
    reason: str
    priority: Literal["low", "normal", "high"] = "normal"
    parameters: dict[str, Any] = Field(default_factory=dict)


class AiDecision(BaseModel):
    decision_id: str = Field(default_factory=lambda: uuid4().hex)
    decision_type: Literal["suggestion", "action", "noop"] = "suggestion"
    summary: str
    confidence: float = Field(default=0.0, ge=0.0, le=1.0)
    recommended_actions: list[DecisionAction] = Field(default_factory=list)
    warnings: list[WarningMessage] = Field(default_factory=list)


class ActionRequest(BaseModel):
    request_id: str = Field(default_factory=lambda: uuid4().hex)
    action_type: str
    mode: Literal["dry_run", "execute"] = "dry_run"
    parameters: dict[str, Any] = Field(default_factory=dict)
    requested_by: str = "ai-service"


class ExecutionResult(BaseModel):
    request_id: str
    status: Literal["accepted", "rejected", "error"]
    message: str
    executed: bool = False
    details: dict[str, Any] = Field(default_factory=dict)
    warnings: list[WarningMessage] = Field(default_factory=list)


class ApiStatus(BaseModel):
    status: Literal["ok"]
    provider: str


class IngestResponse(BaseModel):
    snapshot: GameStateSnapshot
    decision: AiDecision
