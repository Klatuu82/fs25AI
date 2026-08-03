FS25AIWindowSettings = {}
FS25AIWindowSettings.__index = FS25AIWindowSettings

function FS25AIWindowSettings.getPath()
    if type(getUserProfileAppPath) ~= "function" then
        return nil
    end

    return getUserProfileAppPath() .. "fs25AI_window.xml"
end

function FS25AIWindowSettings.load(defaultX, defaultY)
    local path = FS25AIWindowSettings.getPath()

    if path == nil or XMLFile == nil or XMLFile.load == nil then
        return defaultX, defaultY
    end

    local file = XMLFile.load("fs25AIWindowSettings", path)

    if file == nil then
        return defaultX, defaultY
    end

    local x = file:getFloat("fs25AI.window#x", defaultX)
    local y = file:getFloat("fs25AI.window#y", defaultY)
    file:delete()

    return x, y
end

function FS25AIWindowSettings.save(x, y)
    local path = FS25AIWindowSettings.getPath()

    if path == nil or XMLFile == nil or XMLFile.create == nil then
        return false
    end

    local file = XMLFile.create("fs25AIWindowSettings", path, "fs25AI")

    if file == nil then
        return false
    end

    file:setFloat("fs25AI.window#x", x)
    file:setFloat("fs25AI.window#y", y)
    file:save()
    file:delete()

    return true
end
