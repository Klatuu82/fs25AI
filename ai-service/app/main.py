from __future__ import annotations

from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect

from app.action_router import ActionRouter
from app.state_ingestion import StateRepository
from planner.service import PlannerService
from providers.factory import build_provider
from schemas.messages import ActionRequest, ApiStatus, ExecutionResult, GameStateSnapshot, IngestResponse

app = FastAPI(title="fs25AI companion service", version="0.1.0")
state_repository = StateRepository()
planner = PlannerService(build_provider())
action_router = ActionRouter(execution_enabled=False)


@app.get("/health", response_model=ApiStatus)
async def health() -> ApiStatus:
    return ApiStatus(status="ok", provider=planner.provider_name)


@app.post("/telemetry/snapshots", response_model=IngestResponse)
async def ingest_snapshot(snapshot: GameStateSnapshot) -> IngestResponse:
    stored_snapshot = await state_repository.ingest(snapshot)
    decision = await planner.plan(stored_snapshot)
    return IngestResponse(snapshot=stored_snapshot, decision=decision)


@app.get("/telemetry/snapshots/latest", response_model=GameStateSnapshot)
async def latest_snapshot() -> GameStateSnapshot:
    snapshot = state_repository.latest()
    if snapshot is None:
        raise HTTPException(status_code=404, detail="No snapshot has been ingested yet.")
    return snapshot


@app.post("/actions/route", response_model=ExecutionResult)
async def route_action(request: ActionRequest) -> ExecutionResult:
    return await action_router.route(request)


@app.websocket("/ws/telemetry")
async def telemetry_socket(websocket: WebSocket) -> None:
    await websocket.accept()
    try:
        while True:
            payload = await websocket.receive_json()
            snapshot = GameStateSnapshot.model_validate(payload)
            await state_repository.ingest(snapshot)
            decision = await planner.plan(snapshot)
            await websocket.send_json(decision.model_dump(mode="json"))
    except WebSocketDisconnect:
        return
