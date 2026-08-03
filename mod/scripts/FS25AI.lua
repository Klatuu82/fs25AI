FS25AI = {}
FS25AI.__index = FS25AI

function FS25AI.new(overrides)
    local self = setmetatable({}, FS25AI)
    self.config = Config.new(overrides)
    self.stateCollector = StateCollector.new(self.config)
    self.bridgeClient = BridgeClient.new(self.config)
    self.actionExecutor = ActionExecutor.new(self.config)
    self.debugHud = DebugHud.new(self.config)
    self.lastTelemetryAt = 0
    return self
end

function FS25AI:log(message)
    if self.config.logging.enabled then
        print(string.format("%s %s", self.config.logging.prefix, message))
    end
end

function FS25AI:update(currentTimeMs)
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
end

function FS25AI:handleCommand(request)
    return self.actionExecutor:execute(request)
end

g_fs25AI = g_fs25AI or FS25AI.new()
