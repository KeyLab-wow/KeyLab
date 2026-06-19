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
- Stores normalized combat sessions for Run Highlights.
- Uses Blizzard session names exactly as provided.
- Keeps metric 10 enemy rows only as debug/future data.
]]

local SESSION_METRIC_ORDER = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }

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
    if KeyLab.Utils and KeyLab.Utils.SafeNumber then
        local number = KeyLab.Utils.SafeNumber(value)
        if number ~= nil then
            return number
        end
    end

    local ok, number = pcall(function()
        local n = tonumber(value)
        if type(n) ~= "number" then return nil end
        if n ~= n then return nil end
        if not (n < math.huge and n > -math.huge) then return nil end
        return n
    end)

    if ok and type(number) == "number" then
        return number
    end

    return nil
end

local function SafeGreaterThanZero(value)
    local number = SafeNumber(value)
    if number == nil then return false end

    local ok, result = pcall(function()
        return number > 0
    end)

    return ok and result == true
end

local function SafeCompare(left, right, lowerIsBetter)
    left = SafeNumber(left)
    right = SafeNumber(right)
    if left == nil or right == nil then
        return nil
    end

    local ok, result = pcall(function()
        if lowerIsBetter then
            return left < right
        end
        return left > right
    end)

    if not ok then return nil end
    return result == true
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
        return sessionInfo.name or sessionInfo.sessionName
    end

    return nil
end

local function Trim(value)
    if type(value) ~= "string" then return "" end
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function GetExpectedAggregateSessionName(context)
    if type(context) ~= "table" then return nil end
    local dungeonName = Trim(tostring(context.dungeonName or ""))
    local keyLevel = tonumber(context.keyLevel)
    if dungeonName == "" or keyLevel == nil then return nil end
    return dungeonName .. " +" .. tostring(keyLevel)
end

local function FindAggregateSessionID(sessions, context)
    if type(sessions) ~= "table" then
        return nil, nil
    end

    local expectedName = GetExpectedAggregateSessionName(context)
    if expectedName then
        for _, sessionInfo in pairs(sessions) do
            local sessionID = GetSessionID(sessionInfo)
            local name = Trim(GetSessionName(sessionInfo))

            if sessionID ~= nil and name == expectedName then
                return sessionID, "challengeContext"
            end
        end
    end

    return nil, nil
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
        return SafeNumber(value)
    end

    return nil
end

local function IsPlayerSource(source)
    if type(source) ~= "table" then return false end
    if source.isLocalPlayer == true then return true end
    if type(source.sourceGUID) == "string" and string.find(source.sourceGUID, "^Player%-") then return true end
    return type(source.classFilename) == "string" and source.classFilename ~= ""
end

local function BuildLocalRank(rawSession, metricInfo)
    if type(rawSession) ~= "table" or type(rawSession.combatSources) ~= "table" or type(metricInfo) ~= "table" then
        return nil
    end
    if metricInfo.keylabKey == "deaths" then
        return nil
    end

    local valueField = metricInfo.valueField
    local lowerIsBetter = metricInfo.higherIsBetter == false
    local localValue = nil
    local values = {}

    for _, source in pairs(rawSession.combatSources) do
        local value = ReadSourceField(source, valueField)
        if value ~= nil and IsPlayerSource(source) then
            table.insert(values, value)
            if type(source) == "table" and source.isLocalPlayer == true then
                localValue = value
            end
        end
    end

    if localValue == nil or #values == 0 then
        return nil
    end

    local rank = 1
    local bestValue = localValue
    for _, value in ipairs(values) do
        local isBetterThanLocal = SafeCompare(value, localValue, lowerIsBetter)
        if isBetterThanLocal == nil then
            return nil
        end

        if isBetterThanLocal then
            rank = rank + 1
        end

        local isBetterThanBest = SafeCompare(value, bestValue, lowerIsBetter)
        if isBetterThanBest == nil then
            return nil
        end
        if isBetterThanBest then
            bestValue = value
        end
    end

    return {
        rank = rank,
        total = #values,
        value = localValue,
        bestValue = bestValue,
        higherIsBetter = not lowerIsBetter,
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

local function NormalizeSessionInfo(sessionInfo)
    local name = GetSessionName(sessionInfo) or ""

    return {
        sessionID = GetSessionID(sessionInfo),
        sessionName = name,
        name = name,
        durationSeconds = GetSessionDuration(sessionInfo),
        isBossSession = string.find(name, "%(!%)") ~= nil,
        isTrashSession = name ~= "" and string.find(name, "%(!%)") == nil,
    }
end

local function NormalizeLocalSource(source)
    if type(source) ~= "table" then return nil end

    return {
        isLocalPlayer = source.isLocalPlayer == true,
        sourceName = ReadAnySourceField(source, "name"),
        totalAmount = SafeNumber(ReadAnySourceField(source, "totalAmount")),
        amountPerSecond = SafeNumber(ReadAnySourceField(source, "amountPerSecond")),
        classFile = ReadAnySourceField(source, "classFilename"),
        sourceGUID = ReadAnySourceField(source, "sourceGUID"),
    }
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
    local out = {
        localDeaths = 0,
        groupDeaths = 0,
        localSource = nil,
        events = {},
    }

    if type(rawSession) ~= "table" or type(rawSession.combatSources) ~= "table" then
        return out
    end

    for _, source in pairs(rawSession.combatSources) do
        local value = GetDeathEventValue(source)
        if value then
            out.groupDeaths = out.groupDeaths + value

            if source.isLocalPlayer == true then
                out.localDeaths = out.localDeaths + value
                out.localSource = out.localSource or source
            end

            table.insert(out.events, {
                sourceName = ReadAnySourceField(source, "name"),
                classFile = ReadAnySourceField(source, "classFilename"),
                sourceGUID = ReadAnySourceField(source, "sourceGUID"),
                isLocalPlayer = source.isLocalPlayer == true,
                deathCount = value,
                deathRecapID = SafeNumber(ReadAnySourceField(source, "deathRecapID")),
                deathTimeSeconds = SafeNumber(ReadAnySourceField(source, "deathTimeSeconds")),
            })
        end
    end

    return out
end

local function NormalizeEnemyDamage(rawSession)
    local out = {
        totalAmount = SafeNumber(ReadAnySourceField(rawSession, "totalAmount")) or 0,
        sources = {},
    }

    if type(rawSession) ~= "table" or type(rawSession.combatSources) ~= "table" then
        return out
    end

    for _, source in pairs(rawSession.combatSources) do
        if type(source) == "table" then
            table.insert(out.sources, {
                creatureID = ReadAnySourceField(source, "sourceCreatureID"),
                classification = ReadAnySourceField(source, "classification"),
                enemyTotalAmount = SafeNumber(ReadAnySourceField(source, "totalAmount")),
            })
        end
    end

    return out
end

local function MetricOrderForSessions()
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

local function ReadMetricValue(rawSession, metricInfo, options)
    options = type(options) == "table" and options or {}
    if type(rawSession) ~= "table" or type(metricInfo) ~= "table" then return nil, nil end

    if metricInfo.keylabKey == "deaths" then
        local deathEvents = ReadDeathEvents(rawSession)
        return deathEvents.localDeaths, options.skipSources == true and nil or NormalizeLocalSource(deathEvents.localSource)
    end

    local source = FindLocalSource(rawSession)
    if source then
        local value = ReadSourceField(source, metricInfo.valueField)
        return value, options.skipSources == true and nil or NormalizeLocalSource(source)
    end

    if ZERO_WHEN_MISSING[metricInfo.keylabKey] and SafeNumber(rawSession.totalAmount) == 0 then
        return 0, nil
    end

    return nil, nil
end

local function ReadMetricsForSession(sessionID, options)
    local metrics = {}
    local sources = {}
    local ranks = {}
    local enemyDamageTaken = nil
    options = type(options) == "table" and options or {}

    if sessionID == nil or not C_DamageMeter or not C_DamageMeter.GetCombatSessionFromID then
        return metrics, sources, ranks, enemyDamageTaken
    end

    local metricMap = KeyLab.Mapping and KeyLab.Mapping.Metrics or {}

    for _, metricType in ipairs(MetricOrderForSessions()) do
        local metricInfo = metricMap[metricType]
        local okRaw, rawSession = SafeCall(C_DamageMeter.GetCombatSessionFromID, sessionID, metricType)

        if okRaw and type(rawSession) == "table" then
            if metricType == 10 then
                if options.skipEnemyDamage ~= true then
                    enemyDamageTaken = NormalizeEnemyDamage(rawSession)
                end
            elseif metricInfo and metricInfo.store == true and metricInfo.keylabKey then
                local value, source = ReadMetricValue(rawSession, metricInfo, options)
                if value ~= nil then
                    metrics[metricInfo.keylabKey] = value
                end
                if metricInfo.keylabKey == "deaths" then
                    local deathEvents = ReadDeathEvents(rawSession)
                    metrics.groupDeaths = deathEvents.groupDeaths
                    if options.skipSources ~= true then
                        sources.deathEvents = deathEvents.events
                    end
                end
                if source and options.skipSources ~= true then
                    sources[metricInfo.keylabKey] = source
                end
                if options.skipRanks ~= true then
                    local rank = BuildLocalRank(rawSession, metricInfo)
                    if rank then
                        ranks[metricInfo.keylabKey] = rank
                    end
                end
            end
        end
    end

    return metrics, sources, ranks, enemyDamageTaken
end

function DamageMeter.GetSnapshot(context)
    local metrics = {}
    local ranks = {}

    if not C_DamageMeter or not C_DamageMeter.GetAvailableCombatSessions or not C_DamageMeter.GetCombatSessionFromID then
        return metrics, "C_DamageMeter API unavailable"
    end

    local okSessions, sessions = SafeCall(C_DamageMeter.GetAvailableCombatSessions)

    if not okSessions or type(sessions) ~= "table" then
        return metrics, "GetAvailableCombatSessions did not return a table"
    end

    local aggregateSessionID = FindAggregateSessionID(sessions, context)

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
                local value = ReadMetricValue(rawSession, info)
                if value ~= nil then
                    metrics[info.keylabKey] = value
                end
                if info.keylabKey == "deaths" then
                    local deathEvents = ReadDeathEvents(rawSession)
                    metrics.groupDeaths = deathEvents.groupDeaths
                end

                local rank = BuildLocalRank(rawSession, info)
                if rank then
                    ranks[info.keylabKey] = rank
                end
            end
        end
    end

    return metrics, nil, ranks
end

function DamageMeter.GetCombatSessionsSnapshot(context)
    if not C_DamageMeter or not C_DamageMeter.GetAvailableCombatSessions or not C_DamageMeter.GetCombatSessionFromID then
        return {}, "C_DamageMeter API unavailable"
    end

    local okSessions, sessions = SafeCall(C_DamageMeter.GetAvailableCombatSessions)

    if not okSessions or type(sessions) ~= "table" then
        return {}, "GetAvailableCombatSessions did not return a table"
    end

    local out = {}
    local aggregateSessionID, aggregateSource = FindAggregateSessionID(sessions, context)

    for _, sessionInfo in pairs(sessions) do
        local normalized = NormalizeSessionInfo(sessionInfo)
        if normalized.sessionID ~= nil then
            normalized.metrics, normalized.sources, normalized.ranks, normalized.enemyDamageTaken = ReadMetricsForSession(normalized.sessionID)
            if aggregateSessionID ~= nil and normalized.sessionID == aggregateSessionID then
                normalized.isAggregateSession = true
                normalized.isTrashSession = false
                normalized.aggregateSource = aggregateSource
            end
            table.insert(out, normalized)
        end
    end

    table.sort(out, function(a, b)
        return (SafeNumber(a.sessionID) or 0) < (SafeNumber(b.sessionID) or 0)
    end)

    return out, nil
end

return DamageMeter
