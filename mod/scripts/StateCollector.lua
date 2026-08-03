StateCollector = {}
StateCollector.__index = StateCollector

function StateCollector.new(config)
    local self = setmetatable({}, StateCollector)
    self.config = config
    self.lastSnapshot = nil
    self.adapters = {
        fields = function(context)
            return self:collectFields(context)
        end,
        vehicles = function(context)
            return self:collectVehicles(context)
        end,
        jobs = function(context)
            return self:collectJobs(context)
        end,
        economy = function(context)
            return self:collectEconomy(context)
        end,
        weather = function(context)
            return self:collectWeather(context)
        end,
        storages = function(context)
            return self:collectStorages(context)
        end,
        active_tasks = function(context)
            return self:collectActiveTasks(context)
        end
    }
    return self
end

function StateCollector:getGeneratedAt()
    if type(os) == "table" and type(os.date) == "function" then
        return os.date("!%Y-%m-%dT%H:%M:%SZ"), nil
    end

    return "1970-01-01T00:00:00Z", self:makeWarning(
        "collector.timestamp_fallback",
        "FS25 Lua runtime does not expose os.date; using a fallback timestamp.",
        "info",
        {
            fallback = "1970-01-01T00:00:00Z"
        }
    )
end

function StateCollector:makeWarning(code, message, severity, details)
    return {
        code = code,
        message = message,
        severity = severity or "warning",
        details = details or {}
    }
end

function StateCollector:appendWarning(warnings, warning)
    if warning ~= nil then
        table.insert(warnings, warning)
    end
end

function StateCollector:appendWarnings(warnings, additionalWarnings)
    if additionalWarnings == nil then
        return
    end

    for _, warning in ipairs(additionalWarnings) do
        self:appendWarning(warnings, warning)
    end
end

function StateCollector:buildContext()
    local mission = _G.g_currentMission
    local generatedAt, generatedAtWarning = self:getGeneratedAt()
    local warnings = {}

    self:appendWarning(warnings, generatedAtWarning)

    if mission == nil then
        self:appendWarning(warnings, self:makeWarning(
            "collector.mission_unavailable",
            "No active mission is available; collecting a degraded snapshot.",
            "warning"
        ))
    end

    return {
        mission = mission,
        generatedAt = generatedAt,
        warnings = warnings
    }
end

function StateCollector:getSessionId(context)
    local mission = context.mission

    if mission == nil or mission.missionInfo == nil or mission.missionInfo.savegameName == nil then
        self:appendWarning(context.warnings, self:makeWarning(
            "collector.session_id_unavailable",
            "Mission savegame name is unavailable; using an unknown session identifier.",
            "info"
        ))
        return "unknown"
    end

    return tostring(mission.missionInfo.savegameName)
end

function StateCollector:placeholderWarning(category)
    return self:makeWarning(
        "collector.adapter_placeholder",
        string.format("The %s adapter still returns placeholder telemetry until the FS25 API is confirmed.", category),
        "info",
        {
            category = category
        }
    )
end

function StateCollector:collectFields(context)
    return {}, {self:placeholderWarning("fields")}
end

function StateCollector:collectVehicles(context)
    return {}, {self:placeholderWarning("vehicles")}
end

function StateCollector:collectJobs(context)
    return {}, {self:placeholderWarning("jobs")}
end

function StateCollector:collectEconomy(context)
    return {
        money = 0,
        loan = 0,
        prices = {}
    }, {self:placeholderWarning("economy")}
end

function StateCollector:collectWeather(context)
    local mission = context.mission
    local weather = {
        season = "unknown",
        day = 0,
        time = "00:00",
        forecast = "unknown"
    }

    if mission ~= nil and mission.environment ~= nil and mission.environment.dayTime ~= nil then
        weather.time = tostring(mission.environment.dayTime)
    end

    return weather, {self:placeholderWarning("weather")}
end

function StateCollector:collectStorages(context)
    return {}, {self:placeholderWarning("storages")}
end

function StateCollector:collectActiveTasks(context)
    return {}, {self:placeholderWarning("active_tasks")}
end

function StateCollector:applyAdapters(snapshot, context)
    for category, adapter in pairs(self.adapters) do
        local value, adapterWarnings = adapter(context)
        snapshot[category] = value
        self:appendWarnings(snapshot.warnings, adapterWarnings)
    end
end

function StateCollector:collect()
    local context = self:buildContext()
    local snapshot = {
        schema_version = "1.0.0",
        generated_at = context.generatedAt,
        source = "fs25-mod",
        session_id = self:getSessionId(context),
        fields = {},
        vehicles = {},
        jobs = {},
        economy = {
            money = 0,
            loan = 0,
            prices = {}
        },
        weather = {
            season = "unknown",
            day = 0,
            time = "00:00",
            forecast = "unknown"
        },
        storages = {},
        warnings = context.warnings,
        active_tasks = {},
        raw = {
            assumptions = {
                "Field, vehicle, economy, and contract adapters are placeholders until concrete FS25 APIs are confirmed."
            },
            adapter_status = {
                fields = "placeholder",
                vehicles = "placeholder",
                jobs = "placeholder",
                economy = "placeholder",
                weather = "placeholder",
                storages = "placeholder",
                active_tasks = "placeholder"
            }
        }
    }

    self:applyAdapters(snapshot, context)

    self.lastSnapshot = snapshot
    return snapshot
end

function StateCollector:getLastSnapshot()
    return self.lastSnapshot
end
