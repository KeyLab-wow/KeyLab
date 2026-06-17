local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.LastRunAnalysis = KeyLab.LastRunAnalysis or {}
local Analysis = KeyLab.LastRunAnalysis

--[[
KeyLab_LastRunAnalysis.lua

Purpose:
- Find the newest completed run for the current character.
- Package saved totals, ranks, timer status, and run highlights for UI display.
- No frame creation or visual layout.
]]

local function NormalizeName(value)
    value = tostring(value or "")
    value = value:gsub("%s+", "")
    value = value:gsub("'", "")
    value = value:gsub("%-+", "-")
    return string.lower(value)
end

local function CurrentCharacter()
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

local function EncounterMatchesCurrentCharacter(encounter)
    local currentName, currentRealm = CurrentCharacter()
    if not currentName or currentName == "" then return true end

    local player = encounter and encounter.player or {}
    local character = encounter and encounter.character or {}
    local context = encounter and encounter.context or {}
    local capture = encounter and encounter.capture or {}

    local encounterName =
        player.playerName
        or player.name
        or character.name
        or context.playerName
        or capture.playerName
        or encounter.playerName
        or encounter.name

    local encounterRealm =
        player.realm
        or character.realm
        or context.realm
        or capture.realm
        or encounter.realm
        or encounter.realmName

    if not encounterName or encounterName == "" then return false end
    if NormalizeName(encounterName) ~= NormalizeName(currentName) then return false end
    if encounterRealm and encounterRealm ~= "" and currentRealm and currentRealm ~= "" then
        return NormalizeName(encounterRealm) == NormalizeName(currentRealm)
    end
    return true
end

local function IsCompletedEncounter(encounter)
    if type(encounter) ~= "table" then return false end
    local flags = encounter.flags or {}
    if flags.interrupted == true or encounter.interrupted == true then return false end
    if flags.excludedFromComparisons == true or encounter.excludeFromComparisons == true then return false end
    if encounter.status == "capture_failed" then return false end
    if encounter.completed == true or encounter.isComplete == true then return true end
    if encounter.result == "Completed" or encounter.result == "Complete" then return true end
    if encounter.result == "Timed" or encounter.result == "Untimed" or encounter.result == "Depleted" then return true end
    return type(encounter.challenge) == "table" or type(encounter.metrics) == "table"
end

local function GetAllEncounters()
    if KeyLab.DB and KeyLab.DB.Encounters and KeyLab.DB.Encounters.GetFiltered then
        return KeyLab.DB.Encounters.GetFiltered({
            includeInterrupted = false,
            includeExcluded = false,
        })
    end
    return KeyLabDB and KeyLabDB.encounters or {}
end

local function GetChallenge(encounter)
    return encounter and encounter.challenge or {}
end

local function GetMetrics(encounter)
    return encounter and encounter.metrics or {}
end

local function GetMetricRanks(encounter)
    return encounter and encounter.metricRanks or {}
end

local function FindLatestEncounter()
    local latest = nil

    for _, encounter in ipairs(GetAllEncounters() or {}) do
        if EncounterMatchesCurrentCharacter(encounter) and IsCompletedEncounter(encounter) then
            if not latest or (tonumber(encounter.timestamp) or 0) > (tonumber(latest.timestamp) or 0) then
                latest = encounter
            end
        end
    end

    return latest
end

local function GetResultText(encounter)
    local challenge = GetChallenge(encounter)
    if encounter and encounter.result and encounter.result ~= "" then return encounter.result end
    if challenge.timed ~= nil then return challenge.timed and "Timed" or "Untimed" end
    return "Completed"
end

local function GetUpgradeLevels(challenge)
    local value = tonumber(challenge and challenge.keystoneUpgradeLevels)
    if value then return math.max(0, math.floor(value)) end

    local duration = tonumber(challenge and challenge.durationSeconds)
    local limit = tonumber(challenge and challenge.timeLimitSeconds)
    if challenge and challenge.timed == true and duration and limit and limit > 0 then
        local remainingRatio = (limit - duration) / limit
        if remainingRatio >= 0.40 then return 3 end
        if remainingRatio >= 0.20 then return 2 end
        if remainingRatio >= 0 then return 1 end
    end

    return nil
end

local function GetChestText(challenge)
    local levels = GetUpgradeLevels(challenge)
    if levels and levels > 0 then
        if levels == 1 then return "+" end
        if levels == 2 then return "++" end
        return "+++"
    end
    if challenge and challenge.timed == false then return "Untimed" end
    if challenge and challenge.timed == true then return "Timed" end
    return "-"
end

local function TimeDelta(challenge)
    local duration = tonumber(challenge and challenge.durationSeconds)
    local limit = tonumber(challenge and challenge.timeLimitSeconds)
    if not duration or not limit then return nil end
    return limit - duration
end

function Analysis.GetLatestRun()
    return FindLatestEncounter()
end

function Analysis.BuildState()
    local encounter = FindLatestEncounter()
    if not encounter then
        return { hasRun = false }
    end

    local challenge = GetChallenge(encounter)
    local highlights = KeyLab.RunHighlights and KeyLab.RunHighlights.BuildEncounterHighlights and KeyLab.RunHighlights.BuildEncounterHighlights(encounter) or nil

    return {
        hasRun = true,
        encounter = encounter,
        challenge = challenge,
        player = encounter.player or {},
        stats = encounter.stats or {},
        metrics = GetMetrics(encounter),
        ranks = GetMetricRanks(encounter),
        highlights = highlights,
        resultText = GetResultText(encounter),
        chestText = GetChestText(challenge),
        keystoneUpgradeLevels = GetUpgradeLevels(challenge),
        dungeonName = challenge.dungeonName or encounter.dungeonName or "Unknown Dungeon",
        keyLevel = challenge.keyLevel or encounter.keyLevel or 0,
        durationSeconds = challenge.durationSeconds,
        timeLimitSeconds = challenge.timeLimitSeconds,
        timeDeltaSeconds = TimeDelta(challenge),
        timed = challenge.timed,
        timestamp = encounter.timestamp,
        dateText = encounter.dateText,
    }
end

return Analysis
