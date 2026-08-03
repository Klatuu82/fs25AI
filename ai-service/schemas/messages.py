from __future__ import annotations

from datetime import datetime
from typing import Any, Literal
from uuid import uuid4

from pydantic import BaseModel, Field, field_validator

GAME_STATE_SNAPSHOT_SCHEMA_VERSION = "1.0.0"
GAME_STATE_SNAPSHOT_SOURCE = "fs25-mod"


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


class JobState(BaseModel):
    job_id: str
    title: str
    status: str = "available"
    reward: int = 0
    completion: float = 0.0
    mission_type: str | None = None
    farm_id: int | None = None
    active_id: int | None = None
    field_id: int | None = None
    field_name: str | None = None


class WeatherState(BaseModel):
    season: str = "unknown"
    day: int = 0
    time: str = "00:00"
    forecast: str = "unknown"


class StorageState(BaseModel):
    storage_id: str
    name: str
    contents: dict[str, int] = Field(default_factory=dict)


class GameStateSnapshot(BaseModel):
    schema_version: str
    generated_at: datetime
    source: str
    session_id: str
    fields: list[FieldStatus]
    vehicles: list[VehicleState]
    jobs: list[JobState]
    economy: EconomyState
    weather: WeatherState
    storages: list[StorageState]
    warnings: list[WarningMessage]
    active_tasks: list[ActiveTask]
    raw: dict[str, Any]

    @field_validator("schema_version")
    @classmethod
    def validate_schema_version(cls, value: str) -> str:
        if value != GAME_STATE_SNAPSHOT_SCHEMA_VERSION:
            msg = f"Unsupported schema_version '{value}'. Expected '{GAME_STATE_SNAPSHOT_SCHEMA_VERSION}'."
            raise ValueError(msg)

        return value

    @field_validator("source")
    @classmethod
    def validate_source(cls, value: str) -> str:
        if value != GAME_STATE_SNAPSHOT_SOURCE:
            msg = f"Unsupported snapshot source '{value}'. Expected '{GAME_STATE_SNAPSHOT_SOURCE}'."
            raise ValueError(msg)

        return value


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
