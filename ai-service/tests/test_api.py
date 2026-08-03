from __future__ import annotations

from fastapi.testclient import TestClient

from app.main import app, state_repository

client = TestClient(app)


def setup_function() -> None:
    state_repository._latest = None


def test_health_endpoint_reports_provider() -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "provider": "rule-based"}


def test_ingest_snapshot_returns_conservative_suggestion() -> None:
    response = client.post(
        "/telemetry/snapshots",
        json={
            "session_id": "savegame-1",
            "active_tasks": [
                {"id": "task-1", "title": "Check harvest window", "status": "active"}
            ],
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["snapshot"]["session_id"] == "savegame-1"
    assert payload["decision"]["decision_type"] == "suggestion"
    assert payload["decision"]["recommended_actions"][0]["action_type"] == "review_task"


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
