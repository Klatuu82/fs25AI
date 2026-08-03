StateCollector = {}
StateCollector.__index = StateCollector

function StateCollector.new(config)
    local self = setmetatable({}, StateCollector)
    self.config = config
    self.lastSnapshot = nil
    self.adapterOrder = {
        "fields",
        "vehicles",
        "jobs",
        "economy",
        "weather",
        "storages",
        "active_tasks"
    }
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

function StateCollector:getProtocolSetting(key, fallback)
    if self.config ~= nil and self.config.protocol ~= nil and self.config.protocol[key] ~= nil then
        return self.config.protocol[key]
    end

    return fallback
end

function StateCollector:coerceString(value, fallback)
    if value == nil then
        return fallback
    end

    return tostring(value)
end

function StateCollector:coerceInteger(value, fallback)
    if type(value) ~= "number" then
        return fallback
    end

    return math.floor(value + 0.5)
end

function StateCollector:coerceNumber(value, fallback)
    if type(value) ~= "number" then
        return fallback
    end

    return value
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
        environment = mission ~= nil and mission.environment or nil,
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

    return self:coerceString(mission.missionInfo.savegameName, "unknown")
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

function StateCollector:getCurrentFarmId(context)
    if context.currentFarmId ~= nil then
        return context.currentFarmId
    end

    local mission = context.mission

    if mission ~= nil and mission.getFarmId ~= nil then
        local farmId = mission:getFarmId()

        if self:isUsableFarmId(farmId) then
            context.currentFarmId = farmId
            return farmId
        end
    end

    if mission ~= nil and mission.playerSystem ~= nil and mission.playerSystem.getLocalPlayer ~= nil then
        local player = mission.playerSystem:getLocalPlayer()

        if player ~= nil and self:isUsableFarmId(player.farmId) then
            context.currentFarmId = player.farmId
            return player.farmId
        end
    end

    self:appendWarning(context.warnings, self:makeWarning(
        "collector.farm_id_unavailable",
        "The current player farm could not be resolved from the mission runtime.",
        "warning"
    ))

    return nil
end

function StateCollector:isUsableFarmId(farmId)
    if type(farmId) ~= "number" then
        return false
    end

    if FarmManager ~= nil and farmId == FarmManager.SPECTATOR_FARM_ID then
        return false
    end

    return farmId >= 1
end

function StateCollector:getCurrentFarm(context)
    local farmId = self:getCurrentFarmId(context)

    if farmId == nil then
        return nil
    end

    if g_farmManager ~= nil and g_farmManager.getFarmById ~= nil then
        local farm = g_farmManager:getFarmById(farmId)

        if farm ~= nil then
            return farm
        end
    end

    self:appendWarning(context.warnings, self:makeWarning(
        "collector.farm_unavailable",
        "The current player farm could not be loaded from g_farmManager.",
        "warning",
        {
            farm_id = farmId
        }
    ))

    return nil
end

function StateCollector:formatDayTime(dayTimeMs)
    if type(dayTimeMs) ~= "number" then
        return "00:00"
    end

    local totalMinutes = math.floor(dayTimeMs / (1000 * 60))
    local hours = math.floor(totalMinutes / 60) % 24
    local minutes = totalMinutes % 60

    return string.format("%02d:%02d", hours, minutes)
end

function StateCollector:getWeatherSeason(context)
    local environment = context.environment

    if environment ~= nil and environment.currentPeriod ~= nil then
        return string.format("period_%d", self:coerceInteger(environment.currentPeriod, 0))
    end

    return "unknown"
end

function StateCollector:getWeatherForecast(context)
    return "unknown"
end

function StateCollector:getMissionStatusName(status)
    if MissionStatus ~= nil then
        if status == MissionStatus.CREATED then
            return "available"
        elseif status == MissionStatus.PREPARING then
            return "preparing"
        elseif status == MissionStatus.RUNNING then
            return "running"
        elseif status == MissionStatus.FINISHED then
            return "finished"
        elseif status == MissionStatus.DISMISSED then
            return "dismissed"
        end
    end

    return tostring(status)
end

function StateCollector:getMissionTitle(mission)
    if mission == nil then
        return "Unknown mission"
    end

    if mission.getTitle ~= nil then
        local title = mission:getTitle()

        if title ~= nil and title ~= "" then
            return self:coerceString(title, "Unknown mission")
        end
    end

    if mission.progressTitle ~= nil and mission.progressTitle ~= "" then
        return self:coerceString(mission.progressTitle, "Unknown mission")
    end

    if mission.type ~= nil and mission.type.name ~= nil then
        return self:coerceString(mission.type.name, "Unknown mission")
    end

    return "Unknown mission"
end

function StateCollector:collectFields(context)
    return {}, {self:placeholderWarning("fields")}, "placeholder"
end

function StateCollector:collectVehicles(context)
    return {}, {self:placeholderWarning("vehicles")}, "placeholder"
end

function StateCollector:collectEconomy(context)
    local farm = self:getCurrentFarm(context)

    if farm ~= nil and farm.getBalance ~= nil then
        local balance = farm:getBalance()

        return {
            money = self:coerceInteger(balance, 0),
            loan = 0,
            prices = {}
        }, {
            self:makeWarning(
                "collector.loan_placeholder",
                "Loan telemetry remains unavailable until a confirmed FS25 loan accessor is identified.",
                "info"
            ),
            self:placeholderWarning("prices")
        }, "runtime"
    end

    return {
        money = 0,
        loan = 0,
        prices = {}
    }, {self:placeholderWarning("economy")}, "placeholder"
end

function StateCollector:collectWeather(context)
    local environment = context.environment
    local weather = {
        season = self:getWeatherSeason(context),
        day = 0,
        time = "00:00",
        forecast = self:getWeatherForecast(context)
    }

    if environment ~= nil and environment.dayTime ~= nil then
        weather.time = self:formatDayTime(environment.dayTime)
    end

    if environment ~= nil then
        if environment.currentDay ~= nil then
            weather.day = self:coerceInteger(environment.currentDay, 0)
        elseif environment.currentMonotonicDay ~= nil then
            weather.day = self:coerceInteger(environment.currentMonotonicDay, 0)
        end
    end

    return weather, {
        self:makeWarning(
            "collector.weather_forecast_placeholder",
            "Weather forecast telemetry remains limited until a confirmed runtime accessor exposes the current forecast type.",
            "info"
        )
    }, environment ~= nil and "runtime" or "placeholder"
end

function StateCollector:collectStorages(context)
    return {}, {self:placeholderWarning("storages")}, "placeholder"
end

function StateCollector:collectActiveTasks(context)
    local jobs, _, jobsStatus = self:collectJobs(context)
    local tasks = {}
    local currentFarmId = self:getCurrentFarmId(context)

    for _, job in ipairs(jobs) do
        local isCurrentFarmTask = currentFarmId == nil or job.farm_id == nil or job.farm_id == currentFarmId

        if isCurrentFarmTask and (job.status == "running" or job.status == "preparing") then
            table.insert(tasks, {
                id = self:coerceString(job.job_id, "unknown"),
                title = self:coerceString(job.title, "Unknown mission"),
                status = job.status == "running" and "active" or "pending"
            })
        end
    end

    return tasks, nil, jobsStatus == "runtime" and "runtime" or "placeholder"
end

function StateCollector:collectJobs(context)
    if context.jobsCache ~= nil then
        return context.jobsCache.jobs, context.jobsCache.warnings, context.jobsCache.status
    end

    if g_missionManager == nil or g_missionManager.getMissions == nil then
        local warnings = {
            self:placeholderWarning("jobs"),
            self:makeWarning(
                "collector.mission_manager_unavailable",
                "g_missionManager is unavailable; mission telemetry could not be collected.",
                "warning"
            )
        }
        context.jobsCache = {
            jobs = {},
            warnings = warnings,
            status = "placeholder"
        }

        return context.jobsCache.jobs, context.jobsCache.warnings, context.jobsCache.status
    end

    local jobs = {}
    local missions = g_missionManager:getMissions()

    if type(missions) ~= "table" then
        local warnings = {
            self:placeholderWarning("jobs"),
            self:makeWarning(
                "collector.missions_unavailable",
                "g_missionManager:getMissions() did not return a mission list.",
                "warning"
            )
        }
        context.jobsCache = {
            jobs = {},
            warnings = warnings,
            status = "placeholder"
        }

        return context.jobsCache.jobs, context.jobsCache.warnings, context.jobsCache.status
    end

    for _, mission in ipairs(missions) do
        local runtimeStatus = mission.status
        local job = {
            job_id = mission.getUniqueId ~= nil and self:coerceString(mission:getUniqueId(), "unknown") or self:coerceString(mission.uniqueId or mission.activeMissionId or ((mission.type ~= nil and mission.type.name) or "unknown"), "unknown"),
            title = self:getMissionTitle(mission),
            status = self:getMissionStatusName(runtimeStatus),
            reward = self:coerceInteger(mission.reward, 0),
            completion = self:coerceNumber(mission.completion, 0)
        }

        if mission.type ~= nil and mission.type.name ~= nil then
            job.mission_type = self:coerceString(mission.type.name, nil)
        end

        if type(mission.farmId) == "number" then
            job.farm_id = self:coerceInteger(mission.farmId, 0)
        end

        if type(mission.activeMissionId) == "number" then
            job.active_id = self:coerceInteger(mission.activeMissionId, 0)
        end

        if mission.getField ~= nil then
            local field = mission:getField()

            if field ~= nil then
                local fieldId = field.getId ~= nil and field:getId() or nil

                if type(fieldId) == "number" then
                    job.field_id = self:coerceInteger(fieldId, 0)
                end

                if field.getName ~= nil then
                    job.field_name = self:coerceString(field:getName(), nil)
                end
            end
        end

        table.insert(jobs, job)
    end

    context.jobsCache = {
        jobs = jobs,
        warnings = nil,
        status = "runtime"
    }

    return context.jobsCache.jobs, context.jobsCache.warnings, context.jobsCache.status
end

function StateCollector:applyAdapters(snapshot, context)
    for _, category in ipairs(self.adapterOrder) do
        local adapter = self.adapters[category]
        local value, adapterWarnings, adapterStatus = adapter(context)
        snapshot[category] = value
        self:appendWarnings(snapshot.warnings, adapterWarnings)
        snapshot.raw.adapter_status[category] = adapterStatus or "placeholder"
    end
end

function StateCollector:collect()
    local context = self:buildContext()
    local snapshot = {
        schema_version = self:getProtocolSetting("snapshotSchemaVersion", "1.0.0"),
        generated_at = context.generatedAt,
        source = self:getProtocolSetting("snapshotSource", "fs25-mod"),
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
                "Field, vehicle, storage, loan, price, and weather forecast telemetry remain placeholders until concrete FS25 APIs are confirmed."
            },
            serialization_policy = self:getProtocolSetting("unsupportedFieldPolicy", "omit_with_warning"),
            adapter_status = {}
        }
    }

    self:applyAdapters(snapshot, context)

    self.lastSnapshot = snapshot
    return snapshot
end

function StateCollector:getLastSnapshot()
    return self.lastSnapshot
end
