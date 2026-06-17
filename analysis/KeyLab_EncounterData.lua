local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Analysis = KeyLab.Analysis or {}
KeyLab.Analysis.EncounterData = KeyLab.Analysis.EncounterData or {}

local EncounterData = KeyLab.Analysis.EncounterData

--[[
KeyLab_EncounterData.lua

Purpose:
- Centralize read-only access to saved encounter tables.
- Keep UI tabs from needing to know every legacy/fallback storage location.
- Keep metric names aligned with KeyLab.Mapping.Metrics keylabKey values.
]]

function EncounterData.GetChallenge(encounter)
    if type(encounter) == "table" and type(encounter.challenge) == "table" then
        return encounter.challenge
    end
    return {}
end

function EncounterData.GetPlayer(encounter)
    if type(encounter) == "table" and type(encounter.player) == "table" then
        return encounter.player
    end
    return {}
end

function EncounterData.GetStats(encounter)
    if type(encounter) == "table" and type(encounter.stats) == "table" then
        return encounter.stats
    end
    return {}
end

function EncounterData.GetTalents(encounter)
    if type(encounter) == "table" and type(encounter.talents) == "table" then
        return encounter.talents
    end
    return {}
end

function EncounterData.GetMetrics(encounter)
    if type(encounter) == "table" and type(encounter.metrics) == "table" then
        return encounter.metrics
    end
    return {}
end

function EncounterData.GetMetricValue(encounter, metricKey)
    local metrics = EncounterData.GetMetrics(encounter)
    return metrics and metrics[metricKey]
end

function EncounterData.GetMetricInfoByType(metricType)
    return KeyLab.Mapping
        and KeyLab.Mapping.Metrics
        and KeyLab.Mapping.Metrics[metricType]
end

function EncounterData.GetMetricInfoByKey(metricKey)
    local metrics = KeyLab.Mapping and KeyLab.Mapping.Metrics
    if type(metrics) ~= "table" then return nil end

    for _, info in pairs(metrics) do
        if info.keylabKey == metricKey and info.store == true then
            return info
        end
    end

    return nil
end

function EncounterData.GetMetricLabel(metricKey)
    local info = EncounterData.GetMetricInfoByKey(metricKey)
    return info and info.label or metricKey or "Metric"
end

function EncounterData.GetMetricList()
    local list = {}
    local order = KeyLab.Mapping and KeyLab.Mapping.MetricOrder or {}

    for _, metricType in ipairs(order) do
        local info = EncounterData.GetMetricInfoByType(metricType)
        if info and info.store == true and info.keylabKey then
            table.insert(list, info)
        end
    end

    return list
end

function EncounterData.NormalizeCharacterKey(value)
    value = tostring(value or "")
    value = value:gsub("%s+", "")
    value = value:gsub("'", "")
    value = value:gsub("%-+", "-")
    return string.lower(value)
end

function EncounterData.GetCurrentCharacterIdentity()
    local name, realm

    if UnitFullName then
        name, realm = UnitFullName("player")
    end

    if not name or name == "" then
        name = UnitName and UnitName("player") or nil
    end

    if (not realm or realm == "") and GetRealmName then
        realm = GetRealmName()
    end

    return name, realm
end

function EncounterData.EncounterMatchesCurrentCharacter(encounter, options)
    if type(encounter) ~= "table" then
        return false
    end

    local currentName, currentRealm = EncounterData.GetCurrentCharacterIdentity()
    if not currentName or currentName == "" then
        return true
    end

    local player = encounter.player or {}
    local character = encounter.character or {}
    local context = encounter.context or {}
    local capture = encounter.capture or {}

    local encounterName =
        player.name
        or player.characterName
        or player.character
        or player.playerName
        or character.name
        or character.characterName
        or context.characterName
        or context.playerName
        or capture.characterName
        or capture.playerName
        or encounter.characterName
        or encounter.playerName
        or encounter.character
        or encounter.name

    local encounterRealm =
        player.realm
        or player.realmName
        or player.server
        or character.realm
        or character.realmName
        or context.realm
        or context.realmName
        or capture.realm
        or capture.realmName
        or encounter.realm
        or encounter.realmName
        or encounter.server

    local encounterFull =
        player.fullName
        or player.characterFullName
        or character.fullName
        or character.characterFullName
        or context.characterFullName
        or context.fullName
        or capture.characterFullName
        or capture.fullName
        or encounter.characterFullName
        or encounter.fullName

    local currentNameKey = EncounterData.NormalizeCharacterKey(currentName)
    local currentRealmKey = EncounterData.NormalizeCharacterKey(currentRealm)
    local currentFullKey = currentNameKey
    if currentRealmKey ~= "" then
        currentFullKey = currentFullKey .. "-" .. currentRealmKey
    end

    if encounterFull and encounterFull ~= "" then
        local fullKey = EncounterData.NormalizeCharacterKey(encounterFull)
        if fullKey == currentFullKey or fullKey == currentNameKey then
            return true
        end
    end

    if not encounterName or encounterName == "" then
        return options and options.allowMissingIdentity == true
    end

    if EncounterData.NormalizeCharacterKey(encounterName) ~= currentNameKey then
        return false
    end

    if encounterRealm and encounterRealm ~= "" and currentRealmKey ~= "" then
        return EncounterData.NormalizeCharacterKey(encounterRealm) == currentRealmKey
    end

    return true
end

function EncounterData.RankTableHasData(ranks)
    if type(ranks) ~= "table" then return false end

    for _, rank in pairs(ranks) do
        if type(rank) == "table" and tonumber(rank.rank) and tonumber(rank.total) then
            return true
        end
    end

    return false
end

function EncounterData.GetCombatSessions(encounter)
    if type(encounter) ~= "table" then return {} end
    if type(encounter.combatSessions) == "table" then return encounter.combatSessions end
    if type(encounter.damageMeterSessions) == "table" then return encounter.damageMeterSessions end
    if type(encounter.runCombatSessions) == "table" then return encounter.runCombatSessions end
    return {}
end

function EncounterData.GetAggregateSessionRanks(encounter)
    local sessions = EncounterData.GetCombatSessions(encounter)

    for _, session in ipairs(sessions) do
        if type(session) == "table" and session.isAggregateSession == true and EncounterData.RankTableHasData(session.ranks) then
            return session.ranks
        end
    end

    local challenge = EncounterData.GetChallenge(encounter)
    local challengeDuration = tonumber(challenge and challenge.durationSeconds)
    if not challengeDuration or challengeDuration <= 0 then
        return {}
    end

    for _, session in ipairs(sessions) do
        local sessionDuration = tonumber(session and session.durationSeconds)
        if sessionDuration and sessionDuration >= (challengeDuration * 0.80) and EncounterData.RankTableHasData(session.ranks) then
            return session.ranks
        end
    end

    return {}
end

function EncounterData.GetMetricRanks(encounter)
    if EncounterData.RankTableHasData(encounter and encounter.metricRanks) then
        return encounter.metricRanks
    end

    return EncounterData.GetAggregateSessionRanks(encounter)
end

function EncounterData.GetMetricRank(encounter, metricKey)
    local ranks = EncounterData.GetMetricRanks(encounter)
    return ranks and ranks[metricKey]
end

function EncounterData.AverageRank(encounters, metricKey)
    local totalRank = 0
    local totalPlayers = 0
    local count = 0

    for _, encounter in ipairs(encounters or {}) do
        local rank = EncounterData.GetMetricRank(encounter, metricKey)
        if type(rank) == "table" and tonumber(rank.rank) and tonumber(rank.total) then
            totalRank = totalRank + tonumber(rank.rank)
            totalPlayers = totalPlayers + tonumber(rank.total)
            count = count + 1
        end
    end

    if count == 0 then return nil end
    return totalRank / count, totalPlayers / count, count
end

return EncounterData
