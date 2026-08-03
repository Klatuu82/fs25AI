Config = {}
Config.__index = Config

function Config.new(overrides)
    local self = setmetatable({}, Config)
    self.bridge = {
        transport = "http",
        endpoint = "http://127.0.0.1:8000/telemetry/snapshots",
        websocketEndpoint = "ws://127.0.0.1:8000/ws/telemetry",
        telemetryIntervalMs = 1000,
        maxBufferedMessages = 32
    }
    self.features = {
        telemetryEnabled = true,
        suggestionsEnabled = true,
        actionExecutionEnabled = false,
        debugHudEnabled = true
    }
    self.logging = {
        enabled = true,
        prefix = "[fs25AI]"
    }

    if overrides ~= nil then
        for sectionName, values in pairs(overrides) do
            if self[sectionName] ~= nil and type(values) == "table" then
                for key, value in pairs(values) do
                    self[sectionName][key] = value
                end
            end
        end
    end

    return self
end
