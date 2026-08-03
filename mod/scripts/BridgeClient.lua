BridgeClient = {}
BridgeClient.__index = BridgeClient

function BridgeClient.new(config)
    local self = setmetatable({}, BridgeClient)
    self.config = config
    self.outboundQueue = {}
    self.inboundQueue = {}
    self.lastError = nil
    return self
end

function BridgeClient:sendTelemetry(snapshot)
    if not self.config.features.telemetryEnabled then
        return false, "telemetry disabled"
    end

    if #self.outboundQueue >= self.config.bridge.maxBufferedMessages then
        table.remove(self.outboundQueue, 1)
    end

    table.insert(self.outboundQueue, {
        kind = "game_state",
        payload = snapshot
    })

    return true, nil
end

function BridgeClient:queueInboundCommand(command)
    table.insert(self.inboundQueue, command)
end

function BridgeClient:pollInboundCommand()
    if #self.inboundQueue == 0 then
        return nil
    end

    return table.remove(self.inboundQueue, 1)
end
