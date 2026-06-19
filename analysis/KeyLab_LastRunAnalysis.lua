local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.LastRunAnalysis = KeyLab.LastRunAnalysis or {}
local Analysis = KeyLab.LastRunAnalysis
local EncounterData = KeyLab.Analysis and KeyLab.Analysis.EncounterData or {}

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
    if EncounterData.EncounterMatchesCurrentCharacter then
        return EncounterData.EncounterMatchesCurrentCharacter(encounter, { allowMissingIdentity = false })
    end

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
    if EncounterData.IsCompletedEncounter then
        return EncounterData.IsCompletedEncounter(encounter)
    end

    if type(encounter) ~= "table" then return false end
    local flags = encounter.flags or {}
    if flags.interrupted == true or encounter.interrupted == true then return false end
    if flags.excludedFromComparisons == true or encounter.excludeFromComparisons == true then return false end
    if encounter.status == "capture_failed" then return false end
    if encounter.completed == true or encounter.isComplete == true then return true end
    if encounter.result == "Completed" or encounter.result == "Complete" then return true end
    if encounter.result == "Timed" or encounter.result == "Untimed" or encounter.result == "Depleted" then return true end
    return type(encounter.metrics) == "table" and next(encounter.metrics) ~= nil
end

local function HasSavedPerformanceData(encounter)
    if EncounterData.HasSavedPerformanceData then
        return EncounterData.HasSavedPerformanceData(encounter)
    end

    if type(encounter) ~= "table" then return false end
    if type(encounter.metrics) == "table" and next(encounter.metrics) ~= nil then return true end
    if type(encounter.metricRanks) == "table" and next(encounter.metricRanks) ~= nil then return true end
    if type(encounter.combatSessions) == "table" and next(encounter.combatSessions) ~= nil then return true end
    if type(encounter.damageMeterSessions) == "table" and next(encounter.damageMeterSessions) ~= nil then return true end
    if type(encounter.runCombatSessions) == "table" and next(encounter.runCombatSessions) ~= nil then return true end
    return false
end

local function IsDisplayableLastRun(encounter)
    if IsCompletedEncounter(encounter) then
        return true
    end

    if type(encounter) ~= "table" then return false end
    if HasSavedPerformanceData(encounter) then return true end

    local challenge = encounter.challenge or {}
    if type(challenge) == "table" then
        return challenge.dungeonName ~= nil
            or challenge.mapID ~= nil
            or challenge.keyLevel ~= nil
    end

    return false
end

local function GetAllEncounters()
    if EncounterData.GetEncounterList then
        return EncounterData.GetEncounterList({
            includeInterrupted = true,
            includeExcluded = true,
            currentCharacterOnly = false,
        })
    end

    if KeyLab.DB and KeyLab.DB.Encounters and KeyLab.DB.Encounters.GetFiltered then
        return KeyLab.DB.Encounters.GetFiltered({
            includeInterrupted = true,
            includeExcluded = true,
        })
    end
    return KeyLabDB and KeyLabDB.encounters or {}
end

local function GetChallenge(encounter)
    if EncounterData.GetChallenge then
        return EncounterData.GetChallenge(encounter)
    end
    return encounter and encounter.challenge or {}
end

local function GetMetrics(encounter)
    if EncounterData.GetMetrics then
        return EncounterData.GetMetrics(encounter)
    end
    return encounter and encounter.metrics or {}
end

local function GetPlayer(encounter)
    if EncounterData.GetPlayer then
        return EncounterData.GetPlayer(encounter)
    end
    return encounter and encounter.player or {}
end

local function GetStats(encounter)
    if EncounterData.GetStats then
        return EncounterData.GetStats(encounter)
    end
    return encounter and encounter.stats or {}
end

local function GetMetricRanks(encounter)
    if EncounterData.GetMetricRanks then
        return EncounterData.GetMetricRanks(encounter)
    end
    return encounter and encounter.metricRanks or {}
end

local function FindLatestEncounter()
    local latest = nil

    for _, encounter in ipairs(GetAllEncounters() or {}) do
        if EncounterMatchesCurrentCharacter(encounter) and IsDisplayableLastRun(encounter) then
            if not latest or (tonumber(encounter.timestamp) or 0) > (tonumber(latest.timestamp) or 0) then
                latest = encounter
            end
        end
    end

    return latest
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
    return {
        hasRun = true,
        encounter = encounter,
        challenge = challenge,
        player = GetPlayer(encounter),
        stats = GetStats(encounter),
        metrics = GetMetrics(encounter),
        ranks = GetMetricRanks(encounter),
        resultText = EncounterData.GetResultText(encounter),
        chestText = EncounterData.GetChestText(encounter),
        keystoneUpgradeLevels = EncounterData.GetUpgradeLevels(encounter),
        dungeonName = challenge.dungeonName or encounter.dungeonName or "Unknown Dungeon",
        keyLevel = challenge.keyLevel or encounter.keyLevel or 0,
        durationSeconds = EncounterData.GetDurationSeconds and EncounterData.GetDurationSeconds(encounter) or challenge.durationSeconds,
        timeLimitSeconds = EncounterData.GetTimeLimitSeconds and EncounterData.GetTimeLimitSeconds(encounter) or challenge.timeLimitSeconds,
        timeDeltaSeconds = EncounterData.GetTimeDelta(encounter),
        timed = EncounterData.GetTimed(encounter),
        timestamp = encounter.timestamp,
        dateText = encounter.dateText,
    }
end

return Analysis
