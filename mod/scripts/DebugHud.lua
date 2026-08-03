DebugHud = {}
DebugHud.__index = DebugHud

function DebugHud.new(config)
    local self = setmetatable({}, DebugHud)
    self.config = config
    self.statusLines = {}
    self.heartbeatLine = nil
    self.position = {x = 0.02, y = 0.68}
    self.size = {width = 0.30, height = 0.18}
    self.headerHeight = 0.032
    self.dragging = false
    self.dragOffset = {x = 0, y = 0}
    self.overlayId = nil

    local defaultX = self.position.x
    local defaultY = self.position.y

    if FS25AIWindowSettings ~= nil and FS25AIWindowSettings.load ~= nil then
        self.position.x, self.position.y = FS25AIWindowSettings.load(defaultX, defaultY)
        self.position.x = math.max(0, math.min(1 - self.size.width, self.position.x))
        self.position.y = math.max(0, math.min(1 - self.size.height, self.position.y))
    end

    if g_overlayManager ~= nil and g_currentModDirectory ~= nil then
        self.overlayId = g_overlayManager:createOverlay(
            g_currentModDirectory .. "ui/fs25ai_window.dds",
            0,
            0,
            self.size.width,
            self.size.height
        )
    end

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

function DebugHud:isInside(posX, posY, includeBody)
    local top = self.position.y + self.size.height
    local bottom = self.position.y

    if includeBody ~= true then
        bottom = top - self.headerHeight
    end

    return posX >= self.position.x
        and posX <= self.position.x + self.size.width
        and posY >= bottom
        and posY <= top
end

function DebugHud:mouseEvent(posX, posY, isDown, isUp, button)
    if self.config.features.debugHudEnabled ~= true
        or self.config.diagnostics.windowMovable ~= true
    then
        return false
    end

    if self.dragging then
        self.position.x = math.max(0, math.min(1 - self.size.width, posX - self.dragOffset.x))
        self.position.y = math.max(0, math.min(1 - self.size.height, posY - self.dragOffset.y))

        if isUp then
            self.dragging = false
            self:savePosition()
        end

        return true
    end

    if isDown and button == 1 and self:isInside(posX, posY, false) then
        self.dragging = true
        self.dragOffset.x = posX - self.position.x
        self.dragOffset.y = posY - self.position.y
        return true
    end

    return false
end

function DebugHud:savePosition()
    if FS25AIWindowSettings ~= nil and FS25AIWindowSettings.save ~= nil then
        FS25AIWindowSettings.save(self.position.x, self.position.y)
    end
end

function DebugHud:draw()
    local lines = self:getLines()

    if #lines == 0 or renderText == nil then
        return
    end

    if self.overlayId ~= nil and renderOverlay ~= nil then
        setOverlayColor(self.overlayId, 0.04, 0.09, 0.09, 0.88)
        renderOverlay(self.overlayId, self.position.x, self.position.y, self.size.width, self.size.height)
    end

    if setTextColor ~= nil then
        setTextColor(1, 1, 1, 0.85)
    end

    local x = self.position.x + 0.012
    local y = self.position.y + self.size.height - 0.024
    local textSize = 0.014
    local lineStep = 0.019

    if setTextBold ~= nil then
        setTextBold(true)
    end
    renderText(x, y, textSize, "fs25AI telemetry")
    if setTextBold ~= nil then
        setTextBold(false)
    end
    y = y - 0.027

    for index, line in ipairs(lines) do
        renderText(x, y - ((index - 1) * lineStep), textSize, tostring(line))
    end
end
