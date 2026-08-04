BridgeClient = {}
BridgeClient.__index = BridgeClient

function BridgeClient.new(config)
    local self = setmetatable({}, BridgeClient)
    self.config = config
    self.outboundQueue = {}
    self.inboundQueue = {}
    self.lastError = nil
    self.isSending = false
    return self
end

function BridgeClient:escapeJsonString(value)
    local escaped = tostring(value)
    escaped = escaped:gsub("\\", "\\\\")
    escaped = escaped:gsub('"', '\\"')
    escaped = escaped:gsub("\b", "\\b")
    escaped = escaped:gsub("\f", "\\f")
    escaped = escaped:gsub("\n", "\\n")
    escaped = escaped:gsub("\r", "\\r")
    escaped = escaped:gsub("\t", "\\t")

    return escaped
end

function BridgeClient:isArrayTable(value)
    if type(value) ~= "table" then
        return false
    end

    local entryCount = 0
    local highestIndex = 0

    for key, _ in pairs(value) do
        if type(key) ~= "number" or key < 1 or math.floor(key) ~= key then
            return false
        end

        entryCount = entryCount + 1

        if key > highestIndex then
            highestIndex = key
        end
    end

    return entryCount > 0 and highestIndex == entryCount
end

function BridgeClient:encodeArray(values)
    local encodedItems = {}

    for index, item in ipairs(values) do
        encodedItems[index] = self:encodeValue(item)
    end

    return "[" .. table.concat(encodedItems, ",") .. "]"
end

function BridgeClient:encodeObject(values)
    local keys = {}

    for key, entryValue in pairs(values) do
        if entryValue ~= nil then
            table.insert(keys, key)
        end
    end

    table.sort(keys, function(left, right)
        return tostring(left) < tostring(right)
    end)

    local encodedEntries = {}

    for index, key in ipairs(keys) do
        encodedEntries[index] = string.format(
            '"%s":%s',
            self:escapeJsonString(key),
            self:encodeValue(values[key])
        )
    end

    return "{" .. table.concat(encodedEntries, ",") .. "}"
end

function BridgeClient:encodeValue(value)
    local valueType = type(value)

    if valueType == "nil" then
        return "null"
    elseif valueType == "string" then
        return '"' .. self:escapeJsonString(value) .. '"'
    elseif valueType == "number" then
        return tostring(value)
    elseif valueType == "boolean" then
        return value and "true" or "false"
    elseif valueType == "table" then
        if self:isArrayTable(value) then
            return self:encodeArray(value)
        end

        return self:encodeObject(value)
    end

    return '"' .. self:escapeJsonString(value) .. '"'
end

function BridgeClient:serializeSnapshot(snapshot)
    local encodedFields = {
        string.format('"%s":%s', "schema_version", self:encodeValue(snapshot.schema_version)),
        string.format('"%s":%s', "generated_at", self:encodeValue(snapshot.generated_at)),
        string.format('"%s":%s', "source", self:encodeValue(snapshot.source)),
        string.format('"%s":%s', "session_id", self:encodeValue(snapshot.session_id)),
        string.format('"%s":%s', "fields", self:encodeArray(snapshot.fields or {})),
        string.format('"%s":%s', "vehicles", self:encodeArray(snapshot.vehicles or {})),
        string.format('"%s":%s', "jobs", self:encodeArray(snapshot.jobs or {})),
        string.format('"%s":%s', "economy", self:encodeValue(snapshot.economy or {})),
        string.format('"%s":%s', "weather", self:encodeValue(snapshot.weather or {})),
        string.format('"%s":%s', "storages", self:encodeArray(snapshot.storages or {})),
        string.format('"%s":%s', "warnings", self:encodeArray(snapshot.warnings or {})),
        string.format('"%s":%s', "active_tasks", self:encodeArray(snapshot.active_tasks or {})),
        string.format('"%s":%s', "raw", self:encodeValue(snapshot.raw or {}))
    }

    return "{" .. table.concat(encodedFields, ",") .. "}"
end

function BridgeClient:processOutboundQueue()
    if self.isSending or #self.outboundQueue == 0 then
        return
    end

    local item = self.outboundQueue[1]
    local transport = self.config.bridge.transport or "http"
    local endpoint = (transport == "websocket") and self.config.bridge.websocketEndpoint or self.config.bridge.endpoint
    local payload = item.serializedPayload

    self.isSending = true
    self.lastError = nil

    -- Note: The actual implementation of HTTP/WebSocket calls depends on the
    -- availability of networking APIs in the FS25 Lua environment (e.int: engine-side bindings).
    -- This implementation uses a generic abstraction that should be replaced with
    -- the specific GIANTS Engine/Lua API call (e.g., HTTPClient:post or similar).

    if transport == "http" then
        -- We use an asynchronous pattern here to avoid blocking the main loop.
        -- In a real FS25 environment, this would be an engine-level async request.
        self:_performHttpRequest(endpoint, payload)
    elseif transport == "websocket" then
        self:_performWebSocketSend(endpoint, payload)
    else
        self.lastError = "Unsupported transport: " .. tostring(transport)
        self.isSending = false
    end
end

function BridgeClient:_performHttpRequest(url, payload)
    -- Placeholder for actual engine-level async HTTP POST request.
    -- In a real implementation, the callback would handle success/failure.
    local success, err = pcall(function()
        -- This is where the engine-specific call goes.
        -- Example: EngineHTTPClient:post(url, payload)
    end)

    if not success then
        self.lastError = "HTTP Request failed: " .. (err or "unknown error")
        self.isSending = false
    else
        -- Success path would usually be handled by the engine's async callback.
        -- For this implementation, we simulate completion after a delay or via completion check.
        -- In reality, FS25 might have an 'onComplete' hook for these requests.
        self.isSending = false
    end

    if not success then
        table.remove(self.outboundQueue, 1)
    end
end

function BridgeClient:_performWebSocketSend(url, payload)
    -- Placeholder for actual engine-level WebSocket send.
    local success, err = pcall(function()
        -- Example: EngineWebSocket:send(url, payload)
    end)

    if not success then
        self.lastError = "WebSocket Send failed: " .. (err or "unknown error")
        self.isSending = false
    else
        self.isSending = false
    end

    if not success then
        table.remove(self.outboundQueue, 1)
    end
end

function BridgeClient:sendTelemetry(snapshot)
    if not self.config.features.telemetryEnabled then
        return false, "telemetry disabled"
    end

    if #self.outboundQueue >= self.config.bridge.maxBufferedMessages then
        table.remove(self.outboundQueue, 1)
    end

    table.insert(self.outboundQueue, {
        kind = "game_int", -- Corrected from 'game_state' to match typical naming if needed
        payload = snapshot,
        serializedPayload = self:serializeSnapshot(snapshot)
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
