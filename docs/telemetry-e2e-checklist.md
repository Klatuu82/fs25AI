# FS25 Telemetry E2E Verification Checklist

This checklist is used to verify that the telemetry pipeline between the FS25 mod and the AI companion service is working correctly, reliably, and without impacting gameplay performance.

## 1. Startup & Bootstrap
- [ ] **Smoke Signal**: Check `log.txt` for `[fs25AI] Startup smoke signal active`.
- [ ] **Mod Loading**: Confirm version and map name are logged in `log.txt`.
- [ ] **HUD Presence**: Verify the FS25AI debug HUD is visible on screen.

## 2. Service Connectivity (HTTP)
*Prerequisite: AI service running with `--host 127.0.0.1 --port 8000`*
- [ ] **Payload Arrival**: Monitor AI service logs/stdout to see incoming `POST /telemetry/snapshots` requests.
- [ ] **JSON Validity**: Verify the payload structure matches the expected `GameStateSnapshot` schema.
- [ ] **Service Offline (Detection)**: Stop the AI service. Verify the Debug HUD updates to show `Bridge: degraded` or an error message.
- [ ] **Gameplay Impact**: Ensure no stuttering or frame drops occur when the service is stopped.

## 3. Service Connectivity (WebSocket)
*Prerequisite: Configured with `transport = "websocket"` in `Config.lua`*
- [ ] **Handshake**: Verify WebSocket connection attempt in AI service logs.
- [ ] **Continuous Stream**: Confirm continuous stream of JSON snapshots arriving via the WS endpoint.
- [ 
    **Service Offline (Detection)**: Stop the AI service. Verify the Debug HUD reflects the disconnection.

## 4. Robustness & Recovery
- [ ] **Service Reconnect**: Restart the AI service while the game is running. Verify that telemetry resumes automatically without requiring a map reload.
- [ ] **Queue Overflow**: (Simulated) If the service is extremely slow, verify via Debug HUD that the `Queue` count stays within bounded limits (`maxBufferedMessages`).
- [ ] **Mission Transition**: Load a new map/mission. Verify `log.txt` shows `Shutdown complete` for the old mission and the new startup sequence for the current one.

## 5. Shutdown
- [ ] **Clean Exit**: Quit the game. Verify `log.txt` contains `[fs25AI] Shutdown complete for current mission`.
