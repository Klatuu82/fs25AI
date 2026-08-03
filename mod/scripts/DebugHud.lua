DebugHud = {}
DebugHud.__index = DebugHud

function DebugHud.new(config)
    local self = setmetatable({}, DebugHud)
    self.config = config
    self.statusLines = {}
    self.heartbeatLine = nil
    return self
end

function DebugHud:setStatus(lines)
    self.statusLines = lines or {}
end

function DebugHud:setHeartbeat(message)
    self.heartbeatLine = message
end

function DebugHud:getLines()
    if self.config.features.debugHudEnabled ~= true then
        return {}
    end

    local lines = {}

    if self.heartbeatLine ~= nil then
        table.insert(lines, self.heartbeatLine)
    end

    for _, line in ipairs(self.statusLines) do
        table.insert(lines, line)
    end

    return lines
end

function DebugHud:draw()
    local lines = self:getLines()

    if #lines == 0 or renderText == nil then
        return
    end

    if setTextColor ~= nil then
        setTextColor(1, 1, 1, 0.85)
    end

    local x = 0.01
    local y = 0.97
    local textSize = 0.015
    local lineStep = 0.018

    for index, line in ipairs(lines) do
        renderText(x, y - ((index - 1) * lineStep), textSize, tostring(line))
    end
end
