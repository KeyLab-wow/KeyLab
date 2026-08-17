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
- Keep UI tabs from needing to know every supported storage shape.
- Keep metric names aligned with KeyLab.Mapping.Metrics keylabKey values.
]]

local function CopyTable(source)
    if type(source) ~= "table" then return {} end

    local out = {}
    for key, value in pairs(source) do
        out[key] = value
    end
    return out
end

local function GetSavedCombatSessions(encounter)
    if type(encounter) ~= "table" then return {} end
    if type(encounter.combatSessions) == "table" then return encounter.combatSessions end
    if type(encounter.damageMeterSessions) == "table" then return encounter.damageMeterSessions end
    if type(encounter.runCombatSessions) == "table" then return encounter.runCombatSessions end
    return {}
end

local function GetBoundedCombatSessions(encounter)
    local saved = GetSavedCombatSessions(encounter)
    local bounded = {}

    for _, session in ipairs(saved) do
        table.insert(bounded, session)
        if type(session) == "table" and session.isAggregateSession == true then
            break
        end
    end

    return bounded
end

local function GetSavedDurationSeconds(encounter)
    local challenge = type(encounter) == "table" and encounter.challenge or nil
    local duration = tonumber(challenge and challenge.durationSeconds)
    if duration and duration > 0 then
        return duration
    end

    for _, session in ipairs(GetSavedCombatSessions(encounter)) do
        duration = tonumber(session and session.durationSeconds)
        if type(session) == "table" and session.isAggregateSession == true and duration and duration > 0 then
            return duration
        end
    end

    return nil
end

local function GetPullSessionDeathTotals(encounter)
    local localDeaths = 0
    local groupDeaths = 0
    local hasLocalDeaths = false
    local hasGroupDeaths = false

    for _, session in ipairs(GetBoundedCombatSessions(encounter)) do
        if type(session) == "table"
            and session.isAggregateSession ~= true
            and type(session.metrics) == "table"
        then
            local deaths = tonumber(session.metrics.deaths)
            local sessionGroupDeaths = tonumber(session.metrics.groupDeaths)

            if deaths ~= nil then
                localDeaths = localDeaths + deaths
                hasLocalDeaths = true
            end

            if sessionGroupDeaths ~= nil then
                groupDeaths = groupDeaths + sessionGroupDeaths
                hasGroupDeaths = true
            end
        end
    end

    return localDeaths, groupDeaths, hasLocalDeaths, hasGroupDeaths
end

local function NormalizeDeathsMetric(encounter, metrics)
    local pullDeaths, pullGroupDeaths, hasPullDeaths, hasPullGroupDeaths = GetPullSessionDeathTotals(encounter)
    local officialGroupDeaths = tonumber(
        encounter
        and encounter.capture
        and (
            encounter.capture.officialChallengeDeaths
            or (encounter.capture.deathAudit and encounter.capture.deathAudit.officialGroupDeaths)
        )
    )

    if hasPullDeaths or hasPullGroupDeaths or officialGroupDeaths ~= nil then
        local out = CopyTable(metrics)
        if hasPullDeaths then
            out.deaths = pullDeaths
        end
        if officialGroupDeaths ~= nil then
            out.groupDeaths = officialGroupDeaths
        elseif hasPullGroupDeaths then
            out.groupDeaths = pullGroupDeaths
        end
        return out
    end

    return metrics
end

local function NormalizeAggregateMetrics(encounter, metrics)
    local out = CopyTable(metrics)
    local availability = type(encounter) == "table" and encounter.metricAvailability or nil
    local metricMap = KeyLab.Mapping and KeyLab.Mapping.Metrics or {}

    for _, info in pairs(metricMap) do
        local key = type(info) == "table" and info.store == true and info.keylabKey or nil
        if key and out[key] == nil then
            if type(availability) ~= "table" or availability[key] == true then
                out[key] = 0
            end
        end
    end

    return out
end

local function MetricNumber(metrics, metricKey)
    if type(metrics) ~= "table" then return nil end
    return tonumber(metrics[metricKey])
end

local function HealingDoneWithAbsorbs(metrics)
    local healing = MetricNumber(metrics, "healingDone")
    local absorbs = MetricNumber(metrics, "absorbs")

    if healing == nil and not (absorbs and absorbs > 0) then
        return nil
    end

    return (healing or 0) + (absorbs or 0)
end

local function HpsWithAbsorbs(metrics, durationSeconds)
    local hps = MetricNumber(metrics, "hps")
    local absorbs = MetricNumber(metrics, "absorbs")
    local duration = tonumber(durationSeconds)

    if hps == nil and not (absorbs and absorbs > 0 and duration and duration > 0) then
        return nil
    end

    local absorbHps = 0
    if absorbs and absorbs > 0 and duration and duration > 0 then
        absorbHps = absorbs / duration
    end

    return (hps or 0) + absorbHps
end

local function AddDerivedHealingMetrics(metrics, durationSeconds)
    local out = CopyTable(metrics)
    local healingWithAbsorbs = HealingDoneWithAbsorbs(metrics)
    local hpsWithAbsorbs = HpsWithAbsorbs(metrics, durationSeconds)

    if healingWithAbsorbs ~= nil then
        out.healingDoneWithAbsorbs = healingWithAbsorbs
    end
    if hpsWithAbsorbs ~= nil then
        out.hpsWithAbsorbs = hpsWithAbsorbs
    end

    return out
end

local function IsBoolean(value)
    return value == true or value == false
end

local function IsTrustedTimingSource(value)
    value = tostring(value or "")
    return value == "challengeModeChallengeCompletionInfo"
        or value == "challengeModeCompletionInfo"
        or value == "challengeModeRemainingAtCompletion"
        or value == "authorSampleData"
end

local function HasOfficialTiming(challenge)
    if type(challenge) ~= "table" then return false end

    return IsTrustedTimingSource(challenge.completionInfoSource)
        or IsTrustedTimingSource(challenge.durationSource)
        or IsTrustedTimingSource(challenge.timingSource)
        or IsTrustedTimingSource(challenge.timedSource)
        or IsTrustedTimingSource(challenge.remainingSource)
end

local function HasStoredCompletedResultSignal(encounter)
    if type(encounter) ~= "table" then return false end
    if encounter.completed == true or encounter.isComplete == true then return true end
    if encounter.result == "Completed" or encounter.result == "Complete" then return true end
    if encounter.result == "Timed" or encounter.result == "Untimed" or encounter.result == "Depleted" then return true end
    return false
end

local function GetChallengeFrom(value)
    if type(value) == "table" and type(value.challenge) == "table" then
        return value.challenge
    end
    return value
end

local function TableHasAnyValue(tbl)
    if type(tbl) ~= "table" then return false end
    return next(tbl) ~= nil
end

local function HasCompletedResultSignal(encounter)
    if HasStoredCompletedResultSignal(encounter) then return true end
    if EncounterData.GetTimed(encounter) ~= nil then return true end
    return false
end

function EncounterData.HasSavedPerformanceData(encounter)
    if type(encounter) ~= "table" then return false end
    if TableHasAnyValue(encounter.metrics) then return true end
    if TableHasAnyValue(encounter.metricRanks) then return true end
    if TableHasAnyValue(encounter.combatSessions) then return true end
    if TableHasAnyValue(encounter.damageMeterSessions) then return true end
    if TableHasAnyValue(encounter.runCombatSessions) then return true end
    return false
end

function EncounterData.IsCompletedEncounter(encounter)
    if type(encounter) ~= "table" then return false end

    if encounter.status == "capture_failed" then return false end
    if HasCompletedResultSignal(encounter) then return true end

    local flags = encounter.flags or {}
    if flags.interrupted == true or encounter.interrupted == true then return false end
    if flags.excludedFromComparisons == true or encounter.excludeFromComparisons == true then return false end

    return EncounterData.HasSavedPerformanceData(encounter)
end

function EncounterData.GetChallenge(encounter)
    if type(encounter) == "table" and type(encounter.challenge) == "table" then
        return encounter.challenge
    end
    return {}
end

function EncounterData.GetTimingDurationSeconds(value)
    local challenge = GetChallengeFrom(value)
    local duration = tonumber(challenge and challenge.durationSeconds)
    if duration and duration > 0 then
        return duration
    end

    return nil
end

function EncounterData.GetTimeLimitSeconds(value)
    local challenge = GetChallengeFrom(value)
    local limit = tonumber(challenge and challenge.timeLimitSeconds)
    if limit and limit > 0 then
        return limit
    end

    local mapID = challenge and challenge.mapID
    if not mapID and type(value) == "table" then
        mapID = value.mapID
    end

    if KeyLab.Mapping and KeyLab.Mapping.GetMapTimerSeconds then
        return KeyLab.Mapping.GetMapTimerSeconds(mapID)
    end

    return nil
end

function EncounterData.GetTimed(encounter)
    local challenge = EncounterData.GetChallenge(encounter)
    if not HasOfficialTiming(challenge) then
        return nil
    end

    if IsBoolean(challenge.timed) then
        return challenge.timed
    end

    local duration = EncounterData.GetTimingDurationSeconds(encounter)
    local limit = EncounterData.GetTimeLimitSeconds(encounter)
    if duration and limit then
        return duration <= limit
    end

    return nil
end

function EncounterData.GetResultText(encounter)
    local result = type(encounter) == "table" and encounter.result or nil
    if type(result) == "string" and result ~= "" and result ~= "Completed" and result ~= "Complete" then
        return result
    end

    local timed = EncounterData.GetTimed(encounter)
    if timed ~= nil then
        return timed and "Timed" or "Untimed"
    end

    if type(result) == "string" and result ~= "" then
        return result
    end

    local flags = type(encounter) == "table" and encounter.flags or nil
    if type(flags) == "table" and flags.interrupted == true then
        return "Interrupted"
    end
    if type(encounter) == "table" and encounter.interrupted == true then
        return "Interrupted"
    end

    if EncounterData.HasSavedPerformanceData(encounter) then
        return "Completed"
    end

    if type(encounter) == "table" and type(encounter.challenge) == "table" then
        return "Partial Capture"
    end

    return "Completed"
end

function EncounterData.GetUpgradeLevels(value)
    local challenge = GetChallengeFrom(value)
    local levels = tonumber(challenge and challenge.keystoneUpgradeLevels)
    if levels and (
        HasOfficialTiming(challenge)
        or IsTrustedTimingSource(challenge and challenge.keystoneUpgradeLevelsSource)
    ) then
        return math.max(0, math.floor(levels))
    end

    if KeyLab.Mapping and KeyLab.Mapping.GetTimerUpgradeLevels
        and HasOfficialTiming(challenge)
    then
        local timed = nil
        if type(value) == "table" and type(value.challenge) == "table" then
            timed = EncounterData.GetTimed(value)
        elseif type(challenge) == "table" and IsBoolean(challenge.timed) then
            timed = challenge.timed
        end

        return KeyLab.Mapping.GetTimerUpgradeLevels(
            EncounterData.GetTimingDurationSeconds(value),
            EncounterData.GetTimeLimitSeconds and EncounterData.GetTimeLimitSeconds(value) or (challenge and challenge.timeLimitSeconds),
            timed
        )
    end

    return nil
end

function EncounterData.GetChestText(value)
    local levels = EncounterData.GetUpgradeLevels(value)
    if levels and levels > 0 then
        if levels == 1 then return "+" end
        if levels == 2 then return "++" end
        return "+++"
    end

    local timed = nil
    if type(value) == "table" and type(value.challenge) == "table" then
        timed = EncounterData.GetTimed(value)
    elseif type(value) == "table" and IsBoolean(value.timed) then
        timed = value.timed
    end
    if timed == false then return "Untimed" end
    if timed == true then return "Timed" end
    return "-"
end

function EncounterData.GetTimeDelta(value)
    local challenge = GetChallengeFrom(value)
    local storedDelta = tonumber(challenge and (challenge.timeDeltaSeconds or challenge.remainingSeconds))
    if not HasOfficialTiming(challenge) then
        return nil
    end
    if storedDelta then return storedDelta end

    local duration = EncounterData.GetTimingDurationSeconds(value)
    local limit = EncounterData.GetTimeLimitSeconds and EncounterData.GetTimeLimitSeconds(value)
    if not duration or not limit then return nil end
    return limit - duration
end

function EncounterData.CountExactUpgradeLevels(encounters, exactLevel)
    local count = 0
    local tracked = 0

    for _, encounter in ipairs(encounters or {}) do
        local levels = EncounterData.GetUpgradeLevels(encounter)
        if levels then
            tracked = tracked + 1
            if levels == exactLevel then
                count = count + 1
            end
        end
    end

    return count, tracked
end

function EncounterData.GetKeyLevel(encounter)
    local challenge = EncounterData.GetChallenge(encounter)
    local keyLevel = tonumber(challenge.keyLevel)
        or tonumber(type(encounter) == "table" and encounter.keyLevel)
        or tonumber(type(encounter) == "table" and encounter.level)
    return keyLevel
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
        local metrics = NormalizeAggregateMetrics(encounter, encounter.metrics)
        metrics = NormalizeDeathsMetric(encounter, metrics)
        return AddDerivedHealingMetrics(metrics, GetSavedDurationSeconds(encounter))
    end
    return {}
end

function EncounterData.GetMetricValueFromMetrics(metrics, metricKey, durationSeconds)
    if metricKey == "healingDoneWithAbsorbs" then
        return HealingDoneWithAbsorbs(metrics)
    end
    if metricKey == "hpsWithAbsorbs" then
        return HpsWithAbsorbs(metrics, durationSeconds)
    end
    return MetricNumber(metrics, metricKey)
end

function EncounterData.GetMetricValue(encounter, metricKey)
    local metrics = EncounterData.GetMetrics(encounter)
    return EncounterData.GetMetricValueFromMetrics(metrics, metricKey, GetSavedDurationSeconds(encounter))
end

function EncounterData.GetSessionMetric(session, metricKey)
    if type(session) ~= "table" then return nil end
    local value = EncounterData.GetMetricValueFromMetrics(session.metrics, metricKey, session.durationSeconds)
    if value ~= nil then return value end

    local availability = session.metricAvailability
    if type(availability) ~= "table" then
        -- Older saved sessions predate explicit API-call availability tracking.
        -- They stored only local-player rows with values, so an absent row in
        -- an otherwise valid session represents zero rather than missing data.
        return 0
    end

    local available = availability[metricKey] == true
    if metricKey == "healingDoneWithAbsorbs" then
        available = availability.healingDone == true and availability.absorbs == true
    elseif metricKey == "hpsWithAbsorbs" then
        available = availability.hps == true and availability.absorbs == true
    elseif metricKey == "groupDeaths" then
        available = availability.deaths == true
    end

    return available and 0 or nil
end

function EncounterData.GetMetricInfoByType(metricType)
    return KeyLab.Mapping
        and KeyLab.Mapping.Metrics
        and KeyLab.Mapping.Metrics[metricType]
end

function EncounterData.GetMetricInfoByKey(metricKey)
    local metrics = KeyLab.Mapping and KeyLab.Mapping.Metrics
    local virtualMetrics = KeyLab.Mapping and KeyLab.Mapping.VirtualMetrics

    if type(metrics) == "table" then
        for _, info in pairs(metrics) do
            if info.keylabKey == metricKey and info.store == true then
                return info
            end
        end
    end

    local virtualInfo = type(virtualMetrics) == "table" and virtualMetrics[metricKey]
    if virtualInfo and virtualInfo.store == true then
        return virtualInfo
    end

    return nil
end

function EncounterData.GetMetricLabel(metricKey)
    local info = EncounterData.GetMetricInfoByKey(metricKey)
    return info and info.label or metricKey or "Metric"
end

function EncounterData.GetCurrentClassIdentity()
    if not UnitClass then return nil, nil, nil end
    return UnitClass("player")
end

function EncounterData.EncounterMatchesCurrentClass(encounter, options)
    if type(encounter) ~= "table" then return false end
    local currentName, currentFile, currentID = EncounterData.GetCurrentClassIdentity()
    local player = EncounterData.GetPlayer and EncounterData.GetPlayer(encounter) or encounter.player or {}
    local savedName = player.class or player.className
    local savedFile = player.classFile or player.classFilename
    local savedID = tonumber(player.classID)

    if currentID and savedID then return tonumber(currentID) == savedID end
    if currentFile and savedFile and savedFile ~= "" then
        return tostring(currentFile):upper() == tostring(savedFile):upper()
    end
    if currentName and savedName and savedName ~= "" then
        return tostring(currentName):lower() == tostring(savedName):lower()
    end
    return options and options.allowMissingClass == true
end

function EncounterData.GetEncounterList(options)
    options = type(options) == "table" and options or {}

    local raw = {}
    if KeyLab.DB and KeyLab.DB.Encounters and KeyLab.DB.Encounters.GetAll then
        raw = KeyLab.DB.Encounters.GetAll()
    elseif KeyLab.DB and KeyLab.DB.Encounters and KeyLab.DB.Encounters.GetFiltered then
        raw = KeyLab.DB.Encounters.GetFiltered({
            includeInterrupted = options.includeInterrupted == true,
            includeExcluded = options.includeExcluded == true,
        })
    end

    local list = {}
    local seasonKey = options.seasonKey
        or (KeyLab.SeasonData and KeyLab.SeasonData.GetSelectedSeasonKey and KeyLab.SeasonData.GetSelectedSeasonKey())
    for _, encounter in pairs(raw or {}) do
        local flags = encounter and encounter.flags or {}
        local hasCompletedResult = encounter and encounter.status ~= "capture_failed" and HasCompletedResultSignal(encounter)
        local keep = true

        if keep and seasonKey and KeyLab.SeasonData and KeyLab.SeasonData.Matches then
            keep = KeyLab.SeasonData.Matches(encounter, seasonKey)
        end

        if keep and options.includeInterrupted ~= true then
            keep = hasCompletedResult or (flags.interrupted ~= true and not (encounter and encounter.interrupted == true))
        end

        if keep and options.includeExcluded ~= true then
            keep = hasCompletedResult or (flags.excludedFromComparisons ~= true and not (encounter and encounter.excludeFromComparisons == true))
        end

        if keep and options.completedOnly == true then
            keep = EncounterData.IsCompletedEncounter(encounter)
        end

        if keep and options.currentCharacterOnly ~= false then
            keep = EncounterData.EncounterMatchesCurrentCharacter(encounter, {
                allowMissingIdentity = options.allowMissingIdentity == true,
            })
        end

        if keep and options.currentClassOnly ~= false then
            keep = EncounterData.EncounterMatchesCurrentClass(encounter, {
                allowMissingClass = options.allowMissingClass ~= false,
            })
        end

        if keep then
            table.insert(list, encounter)
        end
    end

    table.sort(list, function(a, b)
        return (tonumber(a and a.timestamp) or 0) > (tonumber(b and b.timestamp) or 0)
    end)

    return list
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
    return GetBoundedCombatSessions(encounter)
end

function EncounterData.GetPullSessions(encounter)
    local pulls = {}
    for _, session in ipairs(GetBoundedCombatSessions(encounter)) do
        if type(session) == "table"
            and session.isAggregateSession ~= true
            and (tonumber(session.durationSeconds) or 0) > 0
        then
            table.insert(pulls, session)
        end
    end
    return pulls
end

function EncounterData.GetAggregateSession(encounter)
    for _, session in ipairs(EncounterData.GetCombatSessions(encounter)) do
        if type(session) == "table" and session.isAggregateSession == true then
            return session
        end
    end

    return nil
end

function EncounterData.GetDurationSeconds(encounter)
    local challenge = EncounterData.GetChallenge(encounter)
    if not HasOfficialTiming(challenge) then return nil end
    return EncounterData.GetTimingDurationSeconds(encounter)
end

function EncounterData.GetAggregateSessionRanks(encounter)
    local sessions = EncounterData.GetCombatSessions(encounter)

    for _, session in ipairs(sessions) do
        if type(session) == "table" and session.isAggregateSession == true and EncounterData.RankTableHasData(session.ranks) then
            return session.ranks
        end
    end

    local challengeDuration = EncounterData.GetDurationSeconds(encounter)
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
