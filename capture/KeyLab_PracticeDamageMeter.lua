local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Capture = KeyLab.Capture or {}
KeyLab.Capture.PracticeDamageMeter = KeyLab.Capture.PracticeDamageMeter or {}

local PracticeMeter = KeyLab.Capture.PracticeDamageMeter

--[[
KeyLab_PracticeDamageMeter.lua

Purpose:
- Reads Blizzard damage meter sessions for manual Practice tests only.
- Compares the current session list against the IDs present when the test started.
- Returns plain practice totals for PracticeCapture to save.
- Does NOT capture Mythic+ run data.
- Does NOT build UI, sort practice rows, or decide tab display.
]]

local SESSION_METRIC_ORDER = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }

local ZERO_WHEN_MISSING = {
    absorbs = true,
    interrupts = true,
    dispels = true,
    damageTaken = true,
    avoidableDamageTaken = true,
    deaths = true,
}

local function SafeCall(func, ...)
    if type(func) ~= "function" then
        return false, nil
    end

    local ok, a, b, c, d, e = pcall(func, ...)
    if not ok then
        local okText, text = pcall(function()
            return tostring(a)
        end)
        return false, okText and text or "call failed"
    end

    return true, a, b, c, d, e
end

local function SafeNumber(value)
    local ok, number = pcall(function()
        local n = tonumber(value)
        if type(n) ~= "number" then return nil end

        local copy = n + 0
        if copy ~= copy then return nil end
        if not (copy < math.huge and copy > -math.huge) then return nil end

        return copy
    end)

    if ok and type(number) == "number" then
        return number
    end

    return nil
end

local function SafeText(value)
    if value == nil then
        return nil
    end

    local ok, text = pcall(function()
        return tostring(value)
    end)

    if ok and type(text) == "string" then
        return text
    end

    return nil
end

local function SafeStringFind(text, pattern)
    if type(text) ~= "string" then return false end

    local ok, found = pcall(function()
        return string.find(text, pattern) ~= nil
    end)

    return ok and found == true
end

local function SafeKey(value)
    local number = SafeNumber(value)
    if number ~= nil then
        return tostring(number)
    end

    return SafeText(value)
end

local function SafeGreaterThanZero(value)
    local number = SafeNumber(value)
    if number == nil then return false end

    local ok, result = pcall(function()
        return number > 0
    end)

    return ok and result == true
end

local function GetSessionID(sessionInfo)
    if type(sessionInfo) == "table" then
        return sessionInfo.sessionID or sessionInfo.id or sessionInfo[1]
    end

    return sessionInfo
end

local function GetSessionDuration(sessionInfo)
    if type(sessionInfo) == "table" then
        return SafeNumber(sessionInfo.durationSeconds or sessionInfo.duration or 0) or 0
    end

    return 0
end

local function GetSessionName(sessionInfo)
    if type(sessionInfo) == "table" then
        return SafeText(sessionInfo.name or sessionInfo.sessionName) or ""
    end

    return ""
end

local function NormalizeSessionInfo(sessionInfo)
    local name = GetSessionName(sessionInfo)

    return {
        sessionID = GetSessionID(sessionInfo),
        sessionName = name,
        name = name,
        durationSeconds = GetSessionDuration(sessionInfo),
        isBossSession = SafeStringFind(name, "%(!%)"),
        isTrashSession = name ~= "" and not SafeStringFind(name, "%(!%)"),
    }
end

local function ReadAnySourceField(source, fieldName)
    if type(source) ~= "table" or type(fieldName) ~= "string" then
        return nil
    end

    local ok, value = pcall(function()
        return source[fieldName]
    end)

    if ok then return value end
    return nil
end

local function ReadSourceField(source, fieldName)
    local value = ReadAnySourceField(source, fieldName)
    if value ~= nil then
        return SafeNumber(value)
    end

    return nil
end

local function IsPlayerSource(source)
    if type(source) ~= "table" then return false end
    if source.isLocalPlayer == true then return true end

    local guid = SafeText(ReadAnySourceField(source, "sourceGUID"))
    if SafeStringFind(guid, "^Player%-") then return true end

    local classFile = SafeText(ReadAnySourceField(source, "classFilename"))
    return classFile ~= nil and classFile ~= ""
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

local function GetDeathEventValue(source)
    if type(source) ~= "table" or not IsPlayerSource(source) then return nil end

    local total = ReadSourceField(source, "totalAmount")
    if SafeGreaterThanZero(total) then return total end

    local deathRecapID = ReadSourceField(source, "deathRecapID")
    local deathTimeSeconds = ReadSourceField(source, "deathTimeSeconds")
    if SafeGreaterThanZero(deathRecapID) or SafeGreaterThanZero(deathTimeSeconds) then
        return 1
    end

    return nil
end

local function ReadDeathEvents(rawSession)
    local localDeaths = 0
    local groupDeaths = 0

    if type(rawSession) ~= "table" or type(rawSession.combatSources) ~= "table" then
        return localDeaths, groupDeaths
    end

    for _, source in pairs(rawSession.combatSources) do
        local value = GetDeathEventValue(source)
        if value then
            groupDeaths = groupDeaths + value
            if source.isLocalPlayer == true then
                localDeaths = localDeaths + value
            end
        end
    end

    return localDeaths, groupDeaths
end

local function MetricOrderForPractice()
    local seen = {}
    local out = {}

    for _, metricType in ipairs(KeyLab.Mapping and KeyLab.Mapping.MetricOrder or {}) do
        if not seen[metricType] then
            seen[metricType] = true
            table.insert(out, metricType)
        end
    end

    for _, metricType in ipairs(SESSION_METRIC_ORDER) do
        if not seen[metricType] then
            seen[metricType] = true
            table.insert(out, metricType)
        end
    end

    return out
end

local function ReadMetricValue(rawSession, metricInfo)
    if type(rawSession) ~= "table" or type(metricInfo) ~= "table" then return nil end

    if metricInfo.keylabKey == "deaths" then
        local localDeaths = ReadDeathEvents(rawSession)
        return localDeaths
    end

    local source = FindLocalSource(rawSession)
    if source then
        return ReadSourceField(source, metricInfo.valueField)
    end

    if ZERO_WHEN_MISSING[metricInfo.keylabKey] and SafeNumber(rawSession.totalAmount) == 0 then
        return 0
    end

    return nil
end

local function ReadMetricsForSession(sessionID)
    local metrics = {}

    if sessionID == nil or not C_DamageMeter or not C_DamageMeter.GetCombatSessionFromID then
        return metrics
    end

    local metricMap = KeyLab.Mapping and KeyLab.Mapping.Metrics or {}

    for _, metricType in ipairs(MetricOrderForPractice()) do
        local metricInfo = metricMap[metricType]
        local okRaw, rawSession = SafeCall(C_DamageMeter.GetCombatSessionFromID, sessionID, metricType)

        if okRaw and type(rawSession) == "table" and metricInfo and metricInfo.store == true and metricInfo.keylabKey then
            local value = ReadMetricValue(rawSession, metricInfo)
            if value ~= nil then
                metrics[metricInfo.keylabKey] = value
            end
            if metricInfo.keylabKey == "deaths" then
                local _, groupDeaths = ReadDeathEvents(rawSession)
                metrics.groupDeaths = groupDeaths
            end
        end
    end

    return metrics
end

local function HasPracticeMetric(metrics)
    if type(metrics) ~= "table" then return false end
    for _, key in ipairs({ "damageDone", "healingDone", "absorbs", "dps", "hps" }) do
        if SafeGreaterThanZero(metrics[key]) then
            return true
        end
    end
    return false
end

local function MetricDelta(currentMetrics, baselineMetrics)
    local out = {}
    currentMetrics = type(currentMetrics) == "table" and currentMetrics or {}
    baselineMetrics = type(baselineMetrics) == "table" and baselineMetrics or {}

    for key, value in pairs(currentMetrics) do
        local current = SafeNumber(value)
        if current ~= nil then
            local baseline = SafeNumber(baselineMetrics[key]) or 0
            local delta = current - baseline

            -- A meter reset can make the current total lower than the baseline.
            -- In that case the current value already represents the new test.
            if delta < 0 then delta = current end
            out[key] = delta
        end
    end

    return out
end

local function SumPracticeMetrics(combatSessions)
    local metrics = {}
    local rates = {
        dps = { weightedTotal = 0, duration = 0, fallbackTotal = 0, count = 0 },
        hps = { weightedTotal = 0, duration = 0, fallbackTotal = 0, count = 0 },
    }

    for _, session in ipairs(combatSessions or {}) do
        local sessionDuration = SafeNumber(session and session.durationSeconds)
        for key, value in pairs(session.metrics or {}) do
            local number = SafeNumber(value)
            if number ~= nil then
                if rates[key] then
                    if sessionDuration and sessionDuration > 0 then
                        rates[key].weightedTotal = rates[key].weightedTotal + (number * sessionDuration)
                        rates[key].duration = rates[key].duration + sessionDuration
                    else
                        rates[key].fallbackTotal = rates[key].fallbackTotal + number
                        rates[key].count = rates[key].count + 1
                    end
                else
                    metrics[key] = (metrics[key] or 0) + number
                end
            end
        end
    end

    for key, rate in pairs(rates) do
        if rate.duration > 0 then
            metrics[key] = rate.weightedTotal / rate.duration
        elseif rate.count > 0 then
            metrics[key] = rate.fallbackTotal / rate.count
        end
    end

    return metrics
end

function PracticeMeter.GetAvailableSessionIDMap()
    local ids = {}

    if not C_DamageMeter or not C_DamageMeter.GetAvailableCombatSessions then
        return ids, "C_DamageMeter API unavailable"
    end

    local okSessions, sessions = SafeCall(C_DamageMeter.GetAvailableCombatSessions)
    if not okSessions or type(sessions) ~= "table" then
        return ids, "GetAvailableCombatSessions did not return a table"
    end

    for _, sessionInfo in pairs(sessions) do
        local sessionID = GetSessionID(sessionInfo)
        local sessionKey = SafeKey(sessionID)
        if sessionKey and sessionKey ~= "" then
            ids[sessionKey] = true
        end
    end

    return ids, nil
end

function PracticeMeter.GetSessionBaseline()
    local baseline = {}

    if not C_DamageMeter or not C_DamageMeter.GetAvailableCombatSessions or not C_DamageMeter.GetCombatSessionFromID then
        return baseline, "C_DamageMeter API unavailable"
    end

    local okSessions, sessions = SafeCall(C_DamageMeter.GetAvailableCombatSessions)
    if not okSessions or type(sessions) ~= "table" then
        return baseline, "GetAvailableCombatSessions did not return a table"
    end

    for _, sessionInfo in pairs(sessions) do
        local sessionID = GetSessionID(sessionInfo)
        local sessionKey = SafeKey(sessionID)
        if sessionID ~= nil and sessionKey and sessionKey ~= "" then
            baseline[sessionKey] = {
                metrics = ReadMetricsForSession(sessionID),
                durationSeconds = GetSessionDuration(sessionInfo),
                sessionName = GetSessionName(sessionInfo),
            }
        end
    end

    return baseline, nil
end

function PracticeMeter.GetPracticeSnapshot(baselineSessionIDs, startedAt, stoppedAt)
    if not C_DamageMeter or not C_DamageMeter.GetAvailableCombatSessions or not C_DamageMeter.GetCombatSessionFromID then
        return nil, "C_DamageMeter API unavailable"
    end

    local okSessions, sessions = SafeCall(C_DamageMeter.GetAvailableCombatSessions)
    if not okSessions or type(sessions) ~= "table" then
        return nil, "GetAvailableCombatSessions did not return a table"
    end

    local outSessions = {}
    baselineSessionIDs = type(baselineSessionIDs) == "table" and baselineSessionIDs or {}

    for _, sessionInfo in pairs(sessions) do
        local normalized = NormalizeSessionInfo(sessionInfo)
        local sessionKey = SafeKey(normalized.sessionID)

        if normalized.sessionID ~= nil and sessionKey then
            local baseline = baselineSessionIDs[sessionKey]
            normalized.metrics = ReadMetricsForSession(normalized.sessionID)

            if type(baseline) == "table" then
                normalized.metrics = MetricDelta(normalized.metrics, baseline.metrics or baseline)
            elseif baseline == true then
                -- Backward compatibility for sessions started before active
                -- meter baselines were introduced.
                normalized.metrics = nil
            end

            if HasPracticeMetric(normalized.metrics) then
                table.insert(outSessions, normalized)
            end
        end
    end

    table.sort(outSessions, function(a, b)
        return (SafeNumber(a.sessionID) or 0) < (SafeNumber(b.sessionID) or 0)
    end)

    local durationSeconds = (SafeNumber(stoppedAt) or 0) - (SafeNumber(startedAt) or 0)
    if durationSeconds <= 0 then
        durationSeconds = 0
        for _, session in ipairs(outSessions) do
            durationSeconds = durationSeconds + (SafeNumber(session.durationSeconds) or 0)
        end
    end

    local metrics = SumPracticeMetrics(outSessions)
    if not HasPracticeMetric(metrics) then
        return nil, "No new practice damage meter data found. Start the session before entering combat, then stop it after the test."
    end

    return {
        metrics = metrics,
        combatSessions = outSessions,
        durationSeconds = durationSeconds,
    }, nil
end

return PracticeMeter
