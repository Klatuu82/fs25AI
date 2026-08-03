from __future__ import annotations

import json
from pathlib import Path

from fastapi.testclient import TestClient

from app.main import app, state_repository


REPO_ROOT = Path(__file__).resolve().parents[2]
SAMPLE_SNAPSHOT_PATH = REPO_ROOT / "shared" / "samples" / "game-state.snapshot.json"

client = TestClient(app)


def setup_function() -> None:
    state_repository._latest = None


def load_sample_snapshot() -> dict[str, object]:
    return json.loads(SAMPLE_SNAPSHOT_PATH.read_text(encoding="utf-8"))


def test_health_endpoint_reports_provider() -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "provider": "rule-based"}


def test_ingest_snapshot_returns_conservative_suggestion() -> None:
    response = client.post("/telemetry/snapshots", json=load_sample_snapshot())

    assert response.status_code == 200
    payload = response.json()
    assert payload["snapshot"]["session_id"] == "CareerSavegame1"
    assert payload["decision"]["decision_type"] == "suggestion"
    assert payload["decision"]["recommended_actions"][0]["action_type"] == "inspect_warnings"


def test_ingest_snapshot_rejects_unsupported_contract_values() -> None:
    snapshot = load_sample_snapshot()
    snapshot["schema_version"] = "9.9.9"

    response = client.post("/telemetry/snapshots", json=snapshot)

    assert response.status_code == 422


def test_latest_snapshot_returns_404_before_ingestion() -> None:
    response = client.get("/telemetry/snapshots/latest")

    assert response.status_code == 404


def test_action_routing_stays_in_safe_dry_run_mode() -> None:
    response = client.post(
        "/actions/route",
        json={
            "request_id": "request-1",
            "action_type": "review_harvest_plan",
            "mode": "execute",
            "parameters": {"field_id": "field-12"},
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "accepted"
    assert payload["executed"] is False
    assert payload["details"]["mode"] == "execute"
