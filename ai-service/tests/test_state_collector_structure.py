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
    assert 'jobs = "runtime"' in collector
    assert 'economy = "runtime"' in collector
    assert 'weather = "runtime"' in collector
    assert 'active_tasks = "runtime"' in collector


def test_state_collector_reads_confirmed_runtime_data_only() -> None:
    collector = STATE_COLLECTOR_PATH.read_text(encoding="utf-8")

    assert "mission:getFarmId()" in collector
    assert "function StateCollector:isUsableFarmId(farmId)" in collector
    assert "FarmManager.SPECTATOR_FARM_ID" in collector
    assert "mission.playerSystem:getLocalPlayer()" in collector
    assert "g_farmManager:getFarmById(farmId)" in collector
    assert "farm:getBalance()" in collector
    assert "g_missionManager:getMissions()" in collector
    assert "mission:getUniqueId()" in collector
    assert "mission:getTitle()" in collector
    assert "mission:getField()" in collector
    assert "environment.currentDay" in collector
    assert "environment.currentMonotonicDay" in collector
    assert "environment.currentPeriod" in collector
    assert 'string.format("period_%d", environment.currentPeriod)' in collector
    assert 'string.format("%02d:%02d", hours, minutes)' in collector
