StateCollector = {}
StateCollector.__index = StateCollector

function StateCollector.new(config)
    local self = setmetatable({}, StateCollector)
    self.config = config
    self.lastSnapshot = nil
    return self
end

function StateCollector:collect()
    local mission = _G.g_currentMission
    local generatedAt = "1970-01-01T00:00:00Z"

    if type(os) == "table" and type(os.date) == "function" then
        generatedAt = os.date("!%Y-%m-%dT%H:%M:%SZ")
    end

    local snapshot = {
        schema_version = "1.0.0",
        generated_at = generatedAt,
        source = "fs25-mod",
        session_id = mission ~= nil and tostring(mission.missionInfo and mission.missionInfo.savegameName or "unknown") or "unknown",
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
        warnings = {},
        active_tasks = {},
        raw = {
            assumptions = {
                "Field, vehicle, economy, and contract adapters are placeholders until concrete FS25 APIs are confirmed."
            }
        }
    }

    self.lastSnapshot = snapshot
    return snapshot
end

function StateCollector:getLastSnapshot()
    return self.lastSnapshot
end
