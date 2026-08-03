from __future__ import annotations

from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
STATE_COLLECTOR_PATH = REPO_ROOT / "mod" / "scripts" / "StateCollector.lua"


def test_state_collector_declares_explicit_category_adapters() -> None:
    collector = STATE_COLLECTOR_PATH.read_text(encoding="utf-8")

    assert "self.adapters = {" in collector
    assert "fields = function(context)" in collector
    assert "vehicles = function(context)" in collector
    assert "jobs = function(context)" in collector
    assert "economy = function(context)" in collector
    assert "weather = function(context)" in collector
    assert "storages = function(context)" in collector
    assert "active_tasks = function(context)" in collector
    assert "function StateCollector:applyAdapters(snapshot, context)" in collector


def test_state_collector_uses_structured_warnings_for_missing_runtime_state() -> None:
    collector = STATE_COLLECTOR_PATH.read_text(encoding="utf-8")

    assert "function StateCollector:makeWarning(code, message, severity, details)" in collector
    assert '"collector.mission_unavailable"' in collector
    assert '"collector.session_id_unavailable"' in collector
    assert '"collector.timestamp_fallback"' in collector
    assert '"collector.adapter_placeholder"' in collector
    assert "warnings = context.warnings" in collector


def test_state_collector_preserves_snapshot_boundary_with_adapter_status() -> None:
    collector = STATE_COLLECTOR_PATH.read_text(encoding="utf-8")

    assert 'schema_version = "1.0.0"' in collector
    assert 'source = "fs25-mod"' in collector
    assert "raw = {" in collector
    assert "adapter_status = {" in collector
    assert 'fields = "placeholder"' in collector
    assert 'active_tasks = "placeholder"' in collector
