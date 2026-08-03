DebugHud = {}
DebugHud.__index = DebugHud

function DebugHud.new(config)
    local self = setmetatable({}, DebugHud)
    self.config = config
    self.lines = {}
    return self
end

function DebugHud:setStatus(lines)
    self.lines = lines or {}
end

function DebugHud:getLines()
    return self.lines
end
