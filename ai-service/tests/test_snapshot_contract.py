from __future__ import annotations

import json
from pathlib import Path

from fastapi.testclient import TestClient

from app.main import app, state_repository
from schemas.messages import (
    GAME_STATE_SNAPSHOT_SCHEMA_VERSION,
    GAME_STATE_SNAPSHOT_SOURCE,
    GameStateSnapshot,
)


REPO_ROOT = Path(__file__).resolve().parents[2]
SAMPLE_SNAPSHOT_PATH = REPO_ROOT / "shared" / "samples" / "game-state.snapshot.json"

client = TestClient(app)


def setup_function() -> None:
    state_repository._latest = None


def test_shared_sample_snapshot_matches_contract() -> None:
    sample_payload = json.loads(SAMPLE_SNAPSHOT_PATH.read_text(encoding="utf-8"))
    snapshot = GameStateSnapshot.model_validate(sample_payload)

    assert snapshot.schema_version == GAME_STATE_SNAPSHOT_SCHEMA_VERSION
    assert snapshot.source == GAME_STATE_SNAPSHOT_SOURCE
    assert snapshot.generated_at.isoformat() == "2026-08-03T12:00:00+00:00"
    assert snapshot.jobs[0].job_id == "harvest-42"
    assert snapshot.weather.season == "period_4"
    assert snapshot.raw["serialization_policy"] == "omit_with_warning"


def test_service_ingest_accepts_shared_sample_snapshot() -> None:
    sample_payload = json.loads(SAMPLE_SNAPSHOT_PATH.read_text(encoding="utf-8"))

    response = client.post("/telemetry/snapshots", json=sample_payload)

    assert response.status_code == 200
    body = response.json()
    assert body["snapshot"]["schema_version"] == GAME_STATE_SNAPSHOT_SCHEMA_VERSION
    assert body["snapshot"]["source"] == GAME_STATE_SNAPSHOT_SOURCE
    assert body["snapshot"]["jobs"][0]["job_id"] == "harvest-42"
