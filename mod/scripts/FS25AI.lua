FS25AIRuntime = {}
FS25AIRuntime.__index = FS25AIRuntime

function FS25AIRuntime.new(overrides)
    local self = setmetatable({}, FS25AIRuntime)
    self.config = Config.new(overrides)
    self.stateCollector = StateCollector.new(self.config)
    self.bridgeClient = BridgeClient.new(self.config)
    self.actionExecutor = ActionExecutor.new(self.config)
    self.debugHud = DebugHud.new(self.config)
    self.heartbeatCount = 0
    self.lastHeartbeatAt = nil
    self.lastTelemetryAt = 0
    return self
end

function FS25AIRuntime:log(message)
    if self.config.logging.enabled then
        print(string.format("%s %s", self.config.logging.prefix, message))
    end
end

function FS25AIRuntime:updateHeartbeat(currentTimeMs)
    if self.config.diagnostics.heartbeatEnabled ~= true then
        return
    end

    if self.config.features.debugHudEnabled ~= true then
        return
    end

    if self.lastHeartbeatAt ~= nil then
        local elapsedMs = currentTimeMs - self.lastHeartbeatAt

        if elapsedMs < self.config.diagnostics.heartbeatIntervalMs then
            return
        end
    end

    self.heartbeatCount = self.heartbeatCount + 1
    self.lastHeartbeatAt = currentTimeMs
    self.debugHud:setHeartbeat(string.format("fs25AI active - heartbeat %d", self.heartbeatCount))
end

function FS25AIRuntime:update(currentTimeMs)
    self:updateHeartbeat(currentTimeMs)

    if self.config.features.telemetryEnabled ~= true then
        return
    end

    if currentTimeMs - self.lastTelemetryAt < self.config.bridge.telemetryIntervalMs then
        return
    end

    local snapshot = self.stateCollector:collect()
    local success, errorMessage = self.bridgeClient:sendTelemetry(snapshot)

    if success then
        self.lastTelemetryAt = currentTimeMs
        self.debugHud:setStatus({
            "Bridge: queued telemetry",
            string.format("Queue: %d", #self.bridgeClient.outboundQueue)
        })
    else
        self.debugHud:setStatus({
            "Bridge: degraded",
            errorMessage or "unknown error"
        })
    end

    -- Process the outbound queue to actually perform the network requests.
    self.bridgeClient:processOutboundQueue(currentTimeMs)
end

function FS25AIRuntime:handleCommand(request)
    return self.actionExecutor:execute(request)
end

function FS25AIRuntime:shutdown()
    self.debugHud:savePosition()
    self.debugHud:setStatus({})
    self.debugHud:setHeartbeat(nil)
end

FS25AI = {
    MOD_NAME = g_currentModName or "fs25AI",
    BASE_DIRECTORY = g_currentModDirectory,
    runtime = nil
}

function FS25AI:getVersion()
    if g_modManager ~= nil and g_modManager.getModByName ~= nil then
        local mod = g_modManager:getModByName(self.MOD_NAME)

        if mod ~= nil and mod.version ~= nil then
            return mod.version
        end
    end

    return "unknown"
end

function FS25AI:log(message)
    local prefix = "[fs25AI]"

    if Logging ~= nil and Logging.info ~= nil then
        Logging.info("%s %s", prefix, message)
    else
        print(string.format("%s %s", prefix, message))
    end
end

function FS25AI:getCurrentTimeMs()
    local mission = g_currentMission

    if mission == nil then
        return 0
    end

    if mission.time ~= nil then
        return mission.time
    end

    if mission.environment ~= nil and mission.environment.dayTime ~= nil then
        return mission.environment.dayTime
    end

    return 0
end

function FS25AI:loadMap(mapFilename)
    if self.runtime ~= nil then
        self:deleteMap()
    end

    self.runtime = FS25AIRuntime.new()
    g_fs25AI = self.runtime

    if self.runtime.config.diagnostics.windowMovable == true
        and self.runtime.config.diagnostics.showMouseCursor == true
        and g_inputBinding ~= nil
        and g_inputBinding.setShowMouseCursor ~= nil
    then
        g_inputBinding:setShowMouseCursor(true)
    end

    local missionInfo = g_currentMission ~= nil and g_currentMission.missionInfo or nil
    local savegameName = missionInfo ~= nil and missionInfo.savegameName or "unknown"

    if self.runtime.config.diagnostics.startupSignalEnabled == true then
        self:log("Startup smoke signal active")
    end

    self:log(string.format(
        "Loaded mod version %s for map '%s' (savegame: %s)",
        self:getVersion(),
        tostring(mapFilename),
        tostring(savegameName)
    ))
end

function FS25AI:deleteMap()
    if self.runtime == nil then
        return
    end

    self.runtime:shutdown()

    if self.runtime.config.diagnostics.showMouseCursor == true
        and g_inputBinding ~= nil
        and g_inputBinding.setShowMouseCursor ~= nil
    then
        g_inputBinding:setShowMouseCursor(false)
    end

    self.runtime = nil
    g_fs25AI = nil

    self:log("Shutdown complete for current mission")
end

function FS25AI:update(dt)
    if self.runtime == nil then
        return
    end

    self.runtime:update(self:getCurrentTimeMs())
end

function FS25AI:draw()
    if self.runtime == nil then
        return
    end

    self.runtime.debugHud:draw()
end

function FS25AI:mouseEvent(posX, posY, isDown, isUp, button)
    if self.runtime == nil then
        return false
    end

    return self.runtime.debugHud:mouseEvent(posX, posY, isDown, isUp, button)
end

addModEventListener(FS25AI)
