local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Capture = KeyLab.Capture or {}
KeyLab.Capture.DamageMeter = KeyLab.Capture.DamageMeter or {}

local DamageMeter = KeyLab.Capture.DamageMeter

--[[
KeyLab_DamageMeter.lua

Purpose:
- Reads mapped C_DamageMeter metrics only.
- Uses source.isLocalPlayer == true only.
- Never reads, compares, tostring(), or stores source.name.
- Excludes metric 10 through KeyLab_MetricMapping.lua store=false.
]]

local function SafeCall(func, ...)
    if type(func) ~= "function" then
        return false, nil
    end

    local ok, a, b, c, d, e = pcall(func, ...)
    if not ok then
        return false, tostring(a)
    end

    return true, a, b, c, d, e
end

local function GetSessionID(sessionInfo)
    if type(sessionInfo) == "table" then
        return sessionInfo.sessionID or sessionInfo.id or sessionInfo[1]
    end

    return sessionInfo
end

local function GetSessionDuration(sessionInfo)
    if type(sessionInfo) == "table" then
        return tonumber(sessionInfo.durationSeconds or sessionInfo.duration or 0) or 0
    end

    return 0
end

local function FindAggregateSessionID(sessions)
    if type(sessions) ~= "table" then
        return nil
    end

    -- Probe validation showed the full dungeon aggregate was the longest session.
    -- This avoids relying on session/source names.
    local bestSessionID = nil
    local bestDuration = -1

    for _, sessionInfo in pairs(sessions) do
        local sessionID = GetSessionID(sessionInfo)
        local duration = GetSessionDuration(sessionInfo)

        if sessionID ~= nil and duration > bestDuration then
            bestDuration = duration
            bestSessionID = sessionID
        end
    end

    return bestSessionID
end

local function FindLocalSource(rawSession)
    if type(rawSession) ~= "table" or type(rawSession.combatSources) ~= "table" then
        return nil
    end

    for _, source in pairs(rawSession.combatSources) do
        if type(source) == "table" and source.isLocalPlayer == true then
            return source
        end
    end

    return nil
end

local function ReadSourceField(source, fieldName)
    if type(source) ~= "table" or type(fieldName) ~= "string" then
        return nil
    end

    local ok, value = pcall(function()
        return source[fieldName]
    end)

    if ok and type(value) == "number" then
        return value
    end

    return nil
end

function DamageMeter.GetSnapshot()
    local metrics = {}

    if not C_DamageMeter or not C_DamageMeter.GetAvailableCombatSessions or not C_DamageMeter.GetCombatSessionFromID then
        return metrics, "C_DamageMeter API unavailable"
    end

    local okSessions, sessions = SafeCall(C_DamageMeter.GetAvailableCombatSessions)

    if not okSessions or type(sessions) ~= "table" then
        return metrics, "GetAvailableCombatSessions did not return a table"
    end

    local aggregateSessionID = FindAggregateSessionID(sessions)

    if aggregateSessionID == nil then
        return metrics, "No aggregate combat session found"
    end

    local metricOrder = KeyLab.Mapping and KeyLab.Mapping.MetricOrder
    local metricMap = KeyLab.Mapping and KeyLab.Mapping.Metrics

    if type(metricOrder) ~= "table" or type(metricMap) ~= "table" then
        return metrics, "Metric mapping missing"
    end

    for _, metricType in ipairs(metricOrder) do
        local info = metricMap[metricType]

        if info and info.store == true then
            local okRaw, rawSession = SafeCall(C_DamageMeter.GetCombatSessionFromID, aggregateSessionID, metricType)

            if okRaw and type(rawSession) == "table" then
                local source = FindLocalSource(rawSession)

                if source then
                    local value = ReadSourceField(source, info.valueField)

                    if value ~= nil then
                        metrics[info.keylabKey] = value
                    end
                end
            end
        end
    end

    return metrics, nil
end
