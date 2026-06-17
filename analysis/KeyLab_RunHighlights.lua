local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.RunHighlights = KeyLab.RunHighlights or {}
local Highlights = KeyLab.RunHighlights

--[[
KeyLab_RunHighlights.lua

Purpose:
- Analyze completed-run totals and normalized C_DamageMeter combat sessions.
- Use Blizzard session names exactly as captured.
- Do not parse combat logs.
- Do not reconstruct pull names from creature IDs.
- Do not create UI.
]]

local RUN_RULES = {
    { key = "bestRunDps", label = "Overall Best DPS", metricKey = "dps", mode = "max" },
    { key = "bestRunHps", label = "Overall Best HPS", metricKey = "hps", mode = "max" },
    { key = "leastRunAvoidable", label = "Lowest Avoidable Damage Taken", metricKey = "avoidableDamageTaken", mode = "min" },
    { key = "leastRunDamageTaken", label = "Lowest Damage Taken", metricKey = "damageTaken", mode = "min" },
    { key = "mostRunInterrupts", label = "Most Interrupts", metricKey = "interrupts", mode = "max" },
    { key = "mostRunDispels", label = "Most Dispels", metricKey = "dispels", mode = "max" },
}

local SEGMENT_RULES = {
    { key = "bestDpsSession", label = "Best DPS Segment", metricKey = "dps", mode = "max" },
    { key = "bestDamageSession", label = "Biggest Damage Segment", metricKey = "damageDone", mode = "max" },
    { key = "bestHpsSession", label = "Best HPS Segment", metricKey = "hps", mode = "max" },
    { key = "bestHealingSession", label = "Biggest Healing Segment", metricKey = "healingDone", mode = "max" },
    { key = "bestAbsorbSession", label = "Best Absorb Segment", metricKey = "absorbs", mode = "max" },
    { key = "bestInterruptSession", label = "Most Interrupts", metricKey = "interrupts", mode = "max" },
    { key = "bestDispelSession", label = "Most Dispels", metricKey = "dispels", mode = "max" },
    { key = "lowestAvoidableSession", label = "Lowest Avoidable Damage Taken", metricKey = "avoidableDamageTaken", mode = "min" },
    { key = "highestAvoidableSession", label = "Highest Avoidable Damage Taken", metricKey = "avoidableDamageTaken", mode = "max" },
    { key = "bestBossDpsSession", label = "Best Boss DPS", metricKey = "dps", mode = "max", bossOnly = true },
    { key = "bestTrashDpsSession", label = "Best Trash DPS", metricKey = "dps", mode = "max", trashOnly = true },
}

local function SafeNumber(value)
    local n = tonumber(value)
    if type(n) ~= "number" then return nil end
    if n ~= n then return nil end
    if not (n < math.huge and n > -math.huge) then return nil end
    return n
end

local function GetChallenge(encounter)
    return encounter and encounter.challenge or {}
end

local function GetSessions(encounter)
    if type(encounter) ~= "table" then return {} end
    return encounter.combatSessions
        or encounter.damageMeterSessions
        or encounter.runCombatSessions
        or {}
end

local function GetEncounterMetrics(encounter)
    return encounter and encounter.metrics or {}
end

local function GetMetrics(session)
    return session and session.metrics or {}
end

local function IsBossSession(session)
    if type(session) ~= "table" then return false end
    if session.isBossSession ~= nil then return session.isBossSession == true end
    return string.find(tostring(session.sessionName or session.name or ""), "%(!%)") ~= nil
end

local function IsTrashSession(session)
    if type(session) ~= "table" then return false end
    if session.isTrashSession ~= nil then return session.isTrashSession == true end
    return not IsBossSession(session)
end

local function IsUsableSegment(session)
    if type(session) ~= "table" then return false end
    if session.isAggregateSession == true then return false end
    return (tonumber(session.durationSeconds) or 0) > 0
end

local function RuleAllowsSession(rule, session)
    if not IsUsableSegment(session) then return false end
    if rule.bossOnly and not IsBossSession(session) then return false end
    if rule.trashOnly and not IsTrashSession(session) then return false end
    return true
end

local function BetterValue(rule, value, currentValue)
    if currentValue == nil then return true end
    if rule.mode == "min" then
        return value < currentValue
    end
    return value > currentValue
end

local function BuildResult(rule, encounter, session, value)
    local challenge = GetChallenge(encounter)
    return {
        key = rule.key,
        label = rule.label,
        metricKey = rule.metricKey,
        value = value,
        encounter = encounter,
        encounterID = encounter and encounter.id,
        dungeonName = challenge.dungeonName or (encounter and encounter.dungeonName),
        keyLevel = challenge.keyLevel or (encounter and encounter.keyLevel),
        sessionID = session and session.sessionID,
        sessionName = (session and (session.sessionName or session.name)) or "Unknown Segment",
        durationSeconds = session and session.durationSeconds,
        isBossSession = IsBossSession(session),
        isTrashSession = IsTrashSession(session),
    }
end

local function BuildRunResult(rule, encounter, value)
    local challenge = GetChallenge(encounter)
    return {
        key = rule.key,
        label = rule.label,
        metricKey = rule.metricKey,
        value = value,
        encounter = encounter,
        encounterID = encounter and encounter.id,
        dungeonName = challenge.dungeonName or (encounter and encounter.dungeonName),
        keyLevel = challenge.keyLevel or (encounter and encounter.keyLevel),
        timestamp = encounter and encounter.timestamp,
        isRunHighlight = true,
    }
end

local function FindBestRun(rule, encounters)
    local best = nil
    local bestValue = nil

    for _, encounter in ipairs(encounters or {}) do
        local value = SafeNumber(GetEncounterMetrics(encounter)[rule.metricKey])
        if value ~= nil and BetterValue(rule, value, bestValue) then
            bestValue = value
            best = BuildRunResult(rule, encounter, value)
        end
    end

    return best
end

local function FindBest(rule, encounters)
    local best = nil
    local bestValue = nil

    for _, encounter in ipairs(encounters or {}) do
        for _, session in ipairs(GetSessions(encounter)) do
            if RuleAllowsSession(rule, session) then
                local value = SafeNumber(GetMetrics(session)[rule.metricKey])
                if value ~= nil and BetterValue(rule, value, bestValue) then
                    bestValue = value
                    best = BuildResult(rule, encounter, session, value)
                end
            end
        end
    end

    return best
end

function Highlights.GetRules()
    return Highlights.GetSegmentRules()
end

function Highlights.GetRunRules()
    local out = {}
    for _, rule in ipairs(RUN_RULES) do
        table.insert(out, rule)
    end
    return out
end

function Highlights.GetSegmentRules()
    local out = {}
    for _, rule in ipairs(SEGMENT_RULES) do
        table.insert(out, rule)
    end
    return out
end

function Highlights.BuildEncounterHighlights(encounter)
    return Highlights.BuildHighlightsForEncounters({ encounter })
end

function Highlights.BuildHighlightsForEncounters(encounters)
    local result = {
        list = {},
        byKey = {},
        runList = {},
        runByKey = {},
        segmentList = {},
        segmentByKey = {},
        hasRunData = false,
        hasSessionData = false,
    }

    for _, encounter in ipairs(encounters or {}) do
        if next(GetEncounterMetrics(encounter)) ~= nil then
            result.hasRunData = true
            break
        end
    end

    for _, encounter in ipairs(encounters or {}) do
        if #GetSessions(encounter) > 0 then
            result.hasSessionData = true
            break
        end
    end

    for _, rule in ipairs(RUN_RULES) do
        local highlight = FindBestRun(rule, encounters)
        if highlight then
            result.runByKey[rule.key] = highlight
            table.insert(result.runList, highlight)
        end
    end

    for _, rule in ipairs(SEGMENT_RULES) do
        local highlight = FindBest(rule, encounters)
        if highlight then
            result.segmentByKey[rule.key] = highlight
            table.insert(result.segmentList, highlight)
        end
    end

    result.byKey = result.segmentByKey
    result.list = result.segmentList

    return result
end

return Highlights
