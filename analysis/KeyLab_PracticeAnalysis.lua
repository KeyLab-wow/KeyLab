local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Analysis = KeyLab.Analysis or {}
KeyLab.Analysis.Practice = KeyLab.Analysis.Practice or {}

local PracticeAnalysis = KeyLab.Analysis.Practice

--[[
KeyLab_PracticeAnalysis.lua

Purpose:
- Read and compare saved practice sessions.
- Keep practice UI display-only.
- Reuse shared encounter metric helpers where possible.
]]

local METRIC_OPTIONS = {
    { key = "damageDone", label = "Damage Done" },
    { key = "dps", label = "DPS" },
    { key = "healingDoneWithAbsorbs", label = "Healing Done" },
    { key = "hpsWithAbsorbs", label = "HPS" },
}

local TEST_TYPE_OPTIONS = {
    { key = "ST", label = "ST" },
    { key = "MT", label = "MT" },
    { key = "Party Healing", label = "Party Heal" },
    { key = "Group Healing", label = "Group Heal" },
}

local function DB()
    return KeyLab.DB and KeyLab.DB.Practice or {}
end

local function EncounterData()
    return KeyLab.Analysis and KeyLab.Analysis.EncounterData or {}
end

local function CurrentIdentity()
    if EncounterData().GetCurrentCharacterIdentity then
        return EncounterData().GetCurrentCharacterIdentity()
    end
    return UnitName and UnitName("player") or nil, GetRealmName and GetRealmName() or nil
end

local function CurrentPlayer()
    local capture = KeyLab.Capture and KeyLab.Capture.Player
    if capture and capture.GetSnapshot then
        local ok, player = pcall(capture.GetSnapshot)
        if ok and type(player) == "table" then
            return player
        end
    end

    local player = {}
    if UnitClass then
        player.class, player.classFile, player.classID = UnitClass("player")
    end

    if GetSpecialization and GetSpecializationInfo then
        local specIndex = GetSpecialization()
        if specIndex then
            player.specID, player.spec = GetSpecializationInfo(specIndex)
        end
    end

    return player
end

local function Normalize(value)
    value = tostring(value or "")
    value = value:gsub("%s+", "")
    value = value:gsub("'", "")
    value = value:gsub("%-+", "-")
    return string.lower(value)
end

local function MatchesCurrentCharacter(session)
    local currentName, currentRealm = CurrentIdentity()
    currentName = Normalize(currentName)
    currentRealm = Normalize(currentRealm)

    local player = session and session.player or {}
    local sessionName = Normalize(player.playerName or player.name)
    local sessionRealm = Normalize(player.realm)

    if currentName == "" or sessionName == "" then
        return true
    end

    if sessionName ~= currentName then
        return false
    end

    if currentRealm ~= "" and sessionRealm ~= "" then
        return sessionRealm == currentRealm
    end

    return true
end

local function MatchesCurrentSpec(session)
    local current = CurrentPlayer()
    local player = session and session.player or {}

    local currentSpecID = tonumber(current.specID)
    local sessionSpecID = tonumber(player.specID)
    if currentSpecID and sessionSpecID then
        return currentSpecID == sessionSpecID
    end

    local currentSpec = Normalize(current.spec or current.specName)
    local sessionSpec = Normalize(player.spec or player.specName)
    if currentSpec == "" then
        return true
    end
    if sessionSpec == "" or sessionSpec ~= currentSpec then
        return false
    end

    local currentClassFile = Normalize(current.classFile)
    local sessionClassFile = Normalize(player.classFile)
    if currentClassFile ~= "" and sessionClassFile ~= "" then
        return currentClassFile == sessionClassFile
    end

    local currentClass = Normalize(current.class or current.className)
    local sessionClass = Normalize(player.class or player.className)
    if currentClass ~= "" and sessionClass ~= "" then
        return currentClass == sessionClass
    end

    return true
end

function PracticeAnalysis.GetMetricOptions()
    return METRIC_OPTIONS
end

function PracticeAnalysis.GetTestTypeOptions()
    return TEST_TYPE_OPTIONS
end

function PracticeAnalysis.GetMetricLabel(metricKey)
    for _, option in ipairs(METRIC_OPTIONS) do
        if option.key == metricKey then
            return option.label
        end
    end

    if EncounterData().GetMetricLabel then
        return EncounterData().GetMetricLabel(metricKey)
    end

    return metricKey or "Metric"
end

function PracticeAnalysis.GetMetricValue(session, metricKey)
    if type(session) ~= "table" then return nil end
    if EncounterData().GetMetricValueFromMetrics then
        return EncounterData().GetMetricValueFromMetrics(session.metrics, metricKey, session.durationSeconds)
    end
    return tonumber(session.metrics and session.metrics[metricKey])
end

function PracticeAnalysis.GetAllSessions()
    local raw = DB().GetAll and DB().GetAll() or {}
    local sessions = {}

    for _, session in ipairs(raw or {}) do
        if type(session) == "table" then
            table.insert(sessions, session)
        end
    end

    table.sort(sessions, function(a, b)
        return (tonumber(a.timestamp) or 0) > (tonumber(b.timestamp) or 0)
    end)

    return sessions
end

function PracticeAnalysis.GetSessions()
    local sessions = {}
    local raw = PracticeAnalysis.GetAllSessions()

    for _, session in ipairs(raw or {}) do
        if type(session) == "table" and MatchesCurrentCharacter(session) and MatchesCurrentSpec(session) then
            table.insert(sessions, session)
        end
    end

    table.sort(sessions, function(a, b)
        return (tonumber(a.timestamp) or 0) > (tonumber(b.timestamp) or 0)
    end)

    return sessions
end

function PracticeAnalysis.GetSpecOptions(sessions)
    local seen = {}
    local options = {
        { value = nil, text = "All Specs" },
    }

    for _, session in ipairs(sessions or {}) do
        local spec = session and session.player and session.player.spec
        if spec and spec ~= "" and not seen[spec] then
            seen[spec] = true
            table.insert(options, { value = spec, text = spec })
        end
    end

    return options
end

function PracticeAnalysis.FilterSessions(sessions, filters)
    filters = type(filters) == "table" and filters or {}
    local out = {}

    for _, session in ipairs(sessions or {}) do
        local keep = true

        if filters.spec and (not session.player or session.player.spec ~= filters.spec) then
            keep = false
        end

        if filters.testType and session.testType ~= filters.testType then
            keep = false
        end

        if filters.duration == "manual" then
            if tonumber(session.targetDurationSeconds) then keep = false end
        elseif tonumber(filters.duration) then
            if tonumber(session.targetDurationSeconds) ~= tonumber(filters.duration) then keep = false end
        end

        if filters.status == "unmarked" then
            if session.status ~= nil then
                keep = false
            end
        elseif filters.status and filters.status ~= "all" and session.status ~= filters.status then
            keep = false
        end

        if keep then
            table.insert(out, session)
        end
    end

    return out
end

function PracticeAnalysis.SortSessionsByMetric(sessions, metricKey)
    table.sort(sessions, function(a, b)
        local av = PracticeAnalysis.GetMetricValue(a, metricKey)
        local bv = PracticeAnalysis.GetMetricValue(b, metricKey)
        if av ~= nil and bv ~= nil and av ~= bv then
            return av > bv
        end
        if av ~= nil and bv == nil then return true end
        if av == nil and bv ~= nil then return false end
        return (tonumber(a.timestamp) or 0) > (tonumber(b.timestamp) or 0)
    end)
end

function PracticeAnalysis.GetBestSession(sessions, metricKey)
    local bestSession = nil
    local bestValue = nil

    for _, session in ipairs(sessions or {}) do
        local value = PracticeAnalysis.GetMetricValue(session, metricKey)
        if value ~= nil and (bestValue == nil or value > bestValue) then
            bestValue = value
            bestSession = session
        end
    end

    return bestSession, bestValue
end

return PracticeAnalysis
