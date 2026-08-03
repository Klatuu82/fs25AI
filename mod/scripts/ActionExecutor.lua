ActionExecutor = {}
ActionExecutor.__index = ActionExecutor

function ActionExecutor.new(config)
    local self = setmetatable({}, ActionExecutor)
    self.config = config
    self.safeActions = {
        acknowledgeSuggestion = true,
        setGuidanceMarker = true
    }
    return self
end

function ActionExecutor:execute(request)
    if request == nil or request.action_type == nil then
        return {
            status = "rejected",
            executed = false,
            message = "Missing action_type"
        }
    end

    if self.safeActions[request.action_type] ~= true then
        return {
            status = "rejected",
            executed = false,
            message = "Action is not allow-listed"
        }
    end

    if self.config.features.actionExecutionEnabled ~= true then
        return {
            status = "accepted",
            executed = false,
            message = "Action execution is disabled in the current milestone"
        }
    end

    return {
        status = "accepted",
        executed = true,
        message = "Action execution stub reached"
    }
end
