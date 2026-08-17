local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.RaidAnalysis = KeyLab.RaidAnalysis or {}
local RaidAnalysis = KeyLab.RaidAnalysis
-- EncounterData lives under KeyLab.Analysis.  Keep the legacy fallback only for
-- older installs that may have exposed it at the root table.
local EncounterData = (KeyLab.Analysis and KeyLab.Analysis.EncounterData) or KeyLab.EncounterData or {}

local STAT_KEYS = { "crit", "haste", "mastery", "versatility" }
local STAT_TIE_ORDER = { crit = 1, haste = 2, mastery = 3, versatility = 4 }

local TREND_METRICS = {
    { value = "damageDone", label = "Damage Done", rateLabel = "DPS", rateKey = "dps", higherIsBetter = true },
    { value = "healingDone", label = "Healing Done", rateLabel = "HPS", rateKey = "hps", higherIsBetter = true },
    { value = "damageTaken", label = "Damage Taken", rateLabel = "Damage Taken / Min", perMinute = true, higherIsBetter = false },
    { value = "avoidableDamageTaken", label = "Avoidable Damage", rateLabel = "Avoidable Damage / Min", perMinute = true, higherIsBetter = false },
    { value = "interrupts", label = "Interrupts", rateLabel = "Interrupts / Min", perMinute = true, higherIsBetter = true },
    { value = "dispels", label = "Dispels", rateLabel = "Dispels / Min", perMinute = true, higherIsBetter = true },
    { value = "deaths", label = "Deaths", higherIsBetter = false },
}

local TREND_METRIC_BY_KEY = {}
for _, metric in ipairs(TREND_METRICS) do TREND_METRIC_BY_KEY[metric.value] = metric end

local ACTIVITY_METRICS = { interrupts = true, dispels = true }
local CONTEXT_METRICS = { deaths = true }

local function Number(value)
    local number = tonumber(value)
    if number == nil or number ~= number then return nil end
    return number
end

local function PlayerMatches(encounter)
    if EncounterData.EncounterMatchesCurrentCharacter then
        local characterMatches = EncounterData.EncounterMatchesCurrentCharacter(encounter, { allowMissingIdentity = false })
        local classMatches = not EncounterData.EncounterMatchesCurrentClass
            or EncounterData.EncounterMatchesCurrentClass(encounter, { allowMissingClass = false })
        return characterMatches and classMatches
    end
    return true
end

function RaidAnalysis.GetEncounters()
    local list = {}
    local source = KeyLab.DB and KeyLab.DB.Raids and KeyLab.DB.Raids.GetEncounters and KeyLab.DB.Raids.GetEncounters() or {}
    local seasonKey = KeyLab.SeasonData and KeyLab.SeasonData.GetSelectedSeasonKey
        and KeyLab.SeasonData.GetSelectedSeasonKey() or nil
    for _, encounter in ipairs(source) do
        local raid = encounter and encounter.raid or {}
        local seasonMatches = not seasonKey or not KeyLab.SeasonData or not KeyLab.SeasonData.Matches
            or KeyLab.SeasonData.Matches(encounter, seasonKey)
        if seasonMatches and encounter.contentType == "raid" and raid.encounterID and PlayerMatches(encounter) then
            table.insert(list, encounter)
        end
    end
    table.sort(list, function(a, b)
        return (Number(a and a.timestamp) or 0) > (Number(b and b.timestamp) or 0)
    end)
    return list
end

function RaidAnalysis.GetRaid(encounter)
    return type(encounter) == "table" and type(encounter.raid) == "table" and encounter.raid or {}
end

function RaidAnalysis.GetPlayer(encounter)
    return type(encounter) == "table" and type(encounter.player) == "table" and encounter.player or {}
end

function RaidAnalysis.GetSpecName(encounter)
    local player = RaidAnalysis.GetPlayer(encounter)
    return player.spec or player.specName or "Unknown Spec"
end

function RaidAnalysis.GetMetricInfo(metricKey)
    if EncounterData.GetMetricInfoByKey then return EncounterData.GetMetricInfoByKey(metricKey) end
    for _, info in pairs(KeyLab.Mapping and KeyLab.Mapping.Metrics or {}) do
        if info.keylabKey == metricKey and info.store == true then return info end
    end
    return nil
end

function RaidAnalysis.GetMetricOptions()
    local options = {}
    for _, metricType in ipairs(KeyLab.Mapping and KeyLab.Mapping.MetricOrder or {}) do
        local info = KeyLab.Mapping and KeyLab.Mapping.Metrics and KeyLab.Mapping.Metrics[metricType]
        if info and info.store == true and info.keylabKey then
            table.insert(options, { value = info.keylabKey, label = info.label or info.keylabKey })
        end
    end
    return options
end

function RaidAnalysis.GetTrendMetricOptions()
    local options = {}
    for _, metric in ipairs(TREND_METRICS) do
        table.insert(options, { value = metric.value, label = metric.label })
    end
    return options
end

function RaidAnalysis.GetTrendMetricInfo(metricKey)
    return TREND_METRIC_BY_KEY[metricKey] or TREND_METRIC_BY_KEY.damageDone
end

function RaidAnalysis.GetMetricValue(encounter, metricKey)
    if EncounterData.GetMetricValue then return EncounterData.GetMetricValue(encounter, metricKey) end
    return Number(encounter and encounter.metrics and encounter.metrics[metricKey])
end

function RaidAnalysis.HigherIsBetter(metricKey)
    local info = RaidAnalysis.GetMetricInfo(metricKey)
    return not (info and info.higherIsBetter == false)
end

local function PullDuration(encounter)
    return Number(RaidAnalysis.GetRaid(encounter).durationSeconds)
end

function RaidAnalysis.GetTrendMetricTotalValue(encounter, metricKey)
    return RaidAnalysis.GetMetricValue(encounter, metricKey)
end

function RaidAnalysis.GetTrendMetricRateValue(encounter, metricKey)
    local info = RaidAnalysis.GetTrendMetricInfo(metricKey)
    local duration = PullDuration(encounter)
    local total = RaidAnalysis.GetTrendMetricTotalValue(encounter, metricKey)
    if info.rateKey then
        local value = RaidAnalysis.GetMetricValue(encounter, info.rateKey)
        if value ~= nil then return value end
        return total and duration and duration > 0 and (total / duration) or nil
    elseif info.perMinute then
        return total and duration and duration > 0 and (total / duration * 60) or nil
    end
    return nil
end

function RaidAnalysis.GetTrendMetricValue(encounter, metricKey)
    return RaidAnalysis.GetTrendMetricRateValue(encounter, metricKey)
        or RaidAnalysis.GetTrendMetricTotalValue(encounter, metricKey)
end

function RaidAnalysis.TrendHigherIsBetter(metricKey)
    local info = RaidAnalysis.GetTrendMetricInfo(metricKey)
    return info.higherIsBetter ~= false
end

function RaidAnalysis.GetRaidOptions(encounters)
    local seen = {}
    local options = {{ value = nil, label = "All Raids" }}
    for _, encounter in ipairs(encounters or {}) do
        local raid = RaidAnalysis.GetRaid(encounter)
        local id = Number(raid.instanceID)
        if id and not seen[id] then
            seen[id] = true
            table.insert(options, {
                value = id,
                label = raid.instanceName or ("Raid " .. tostring(id)),
            })
        end
    end
    table.sort(options, function(a, b)
        if a.value == nil then return b.value ~= nil end
        if b.value == nil then return false end
        return tostring(a.label) < tostring(b.label)
    end)
    return options
end

function RaidAnalysis.GetBossOptions(encounters, instanceID)
    local seen, options = {}, {}
    for _, encounter in ipairs(encounters or {}) do
        local raid = RaidAnalysis.GetRaid(encounter)
        local id = Number(raid.encounterID)
        if (not instanceID or Number(raid.instanceID) == Number(instanceID)) and id and not seen[id] then
            seen[id] = true
            table.insert(options, { value = id, label = raid.encounterName or ("Encounter " .. tostring(id)) })
        end
    end
    table.sort(options, function(a, b) return tostring(a.label) < tostring(b.label) end)
    return options
end

function RaidAnalysis.GetDifficultyOptions(encounters, encounterID)
    local seen = {}
    local options = {{ value = nil, label = "All Difficulties" }}
    for _, encounter in ipairs(encounters or {}) do
        local raid = RaidAnalysis.GetRaid(encounter)
        local difficultyID = Number(raid.difficultyID)
        if raid.encounterID == encounterID and difficultyID and not seen[difficultyID] then
            seen[difficultyID] = true
            table.insert(options, {
                value = difficultyID,
                label = raid.difficultyName or ("Difficulty " .. tostring(difficultyID)),
            })
        end
    end
    table.sort(options, function(a, b)
        if a.value == nil then return b.value ~= nil end
        if b.value == nil then return false end
        return tostring(a.label) < tostring(b.label)
    end)
    return options
end

function RaidAnalysis.GetSpecOptions(encounters, encounterID, difficultyID)
    local seen = {}
    local options = {{ value = nil, label = "All Specs" }}
    for _, encounter in ipairs(encounters or {}) do
        local raid = RaidAnalysis.GetRaid(encounter)
        if raid.encounterID == encounterID and (not difficultyID or raid.difficultyID == difficultyID) then
            local spec = RaidAnalysis.GetSpecName(encounter)
            if spec ~= "Unknown Spec" and not seen[spec] then
                seen[spec] = true
                table.insert(options, { value = spec, label = spec })
            end
        end
    end
    table.sort(options, function(a, b)
        if a.value == nil then return b.value ~= nil end
        if b.value == nil then return false end
        return tostring(a.label) < tostring(b.label)
    end)
    return options
end

function RaidAnalysis.Filter(encounters, encounterID, difficultyID, spec, instanceID)
    local filtered = {}
    if not encounterID then return filtered end
    for _, encounter in ipairs(encounters or {}) do
        local raid = RaidAnalysis.GetRaid(encounter)
        local matches = raid.encounterID == encounterID
        if matches and instanceID then matches = Number(raid.instanceID) == Number(instanceID) end
        if matches and difficultyID then matches = raid.difficultyID == difficultyID end
        if matches and spec then matches = RaidAnalysis.GetSpecName(encounter) == spec end
        if matches then table.insert(filtered, encounter) end
    end
    return filtered
end

local function IsBetter(value, current, higherIsBetter)
    if value == nil then return false end
    if current == nil then return true end
    if higherIsBetter then return value > current end
    return value < current
end

function RaidAnalysis.BuildTalentGroups(encounters, metricKey)
    local groups = {}
    local higherIsBetter = RaidAnalysis.HigherIsBetter(metricKey)
    for _, encounter in ipairs(encounters or {}) do
        local talentString = encounter.talents and encounter.talents.talentString
        local metricValue = RaidAnalysis.GetMetricValue(encounter, metricKey)
        if type(talentString) == "string" and talentString ~= "" and metricValue ~= nil then
            local spec = RaidAnalysis.GetSpecName(encounter)
            local key = spec .. "|" .. talentString
            local group = groups[key]
            if not group then
                group = {
                    spec = spec,
                    talentString = talentString,
                    pullCount = 0,
                    metricTotal = 0,
                    bestValue = nil,
                    bestEncounter = nil,
                }
                groups[key] = group
            end
            group.pullCount = group.pullCount + 1
            group.metricTotal = group.metricTotal + metricValue
            group.metricAverage = group.metricTotal / group.pullCount
            if IsBetter(metricValue, group.bestValue, higherIsBetter) then
                group.bestValue = metricValue
                group.bestEncounter = encounter
            end
        end
    end
    local result = {}
    for _, group in pairs(groups) do table.insert(result, group) end
    table.sort(result, function(a, b)
        if a.bestValue == b.bestValue then return a.pullCount > b.pullCount end
        return IsBetter(a.bestValue, b.bestValue, higherIsBetter)
    end)
    return result
end

function RaidAnalysis.GetStatPriority(encounter)
    local stats = encounter and encounter.stats or {}
    local priority = {}
    for _, key in ipairs(STAT_KEYS) do
        local value = Number(stats[key])
        if value == nil then return nil end
        table.insert(priority, { key = key, value = value })
    end
    table.sort(priority, function(a, b)
        if a.value == b.value then return STAT_TIE_ORDER[a.key] < STAT_TIE_ORDER[b.key] end
        return a.value > b.value
    end)
    return priority
end

function RaidAnalysis.GetStatLabel(statKey)
    local info = KeyLab.Mapping and KeyLab.Mapping.Stats and KeyLab.Mapping.Stats[statKey]
    return info and info.label or statKey
end

function RaidAnalysis.GetPriorityText(priority)
    local parts = {}
    for _, stat in ipairs(priority or {}) do table.insert(parts, RaidAnalysis.GetStatLabel(stat.key)) end
    return table.concat(parts, " > ")
end

function RaidAnalysis.BuildStatGroups(encounters, metricKey)
    local groups = {}
    local higherIsBetter = RaidAnalysis.HigherIsBetter(metricKey)
    for _, encounter in ipairs(encounters or {}) do
        local priority = RaidAnalysis.GetStatPriority(encounter)
        local metricValue = RaidAnalysis.GetMetricValue(encounter, metricKey)
        if priority and metricValue ~= nil then
            local priorityKeys = {}
            for _, stat in ipairs(priority) do table.insert(priorityKeys, stat.key) end
            local spec = RaidAnalysis.GetSpecName(encounter)
            local key = spec .. "|" .. table.concat(priorityKeys, ">")
            local group = groups[key]
            if not group then
                group = {
                    spec = spec,
                    priority = priority,
                    priorityText = RaidAnalysis.GetPriorityText(priority),
                    pullCount = 0,
                    metricTotal = 0,
                    bestValue = nil,
                    bestEncounter = nil,
                }
                groups[key] = group
            end
            group.pullCount = group.pullCount + 1
            group.metricTotal = group.metricTotal + metricValue
            group.metricAverage = group.metricTotal / group.pullCount
            if IsBetter(metricValue, group.bestValue, higherIsBetter) then
                group.bestValue = metricValue
                group.bestEncounter = encounter
                group.bestPriority = priority
            end
        end
    end
    local result = {}
    for _, group in pairs(groups) do table.insert(result, group) end
    table.sort(result, function(a, b)
        if a.metricAverage == b.metricAverage then return a.pullCount > b.pullCount end
        return IsBetter(a.metricAverage, b.metricAverage, higherIsBetter)
    end)
    return result
end

local function DeltaPercent(current, previous)
    if current == nil or previous == nil or previous == 0 then return nil end
    return ((current - previous) / math.abs(previous)) * 100
end

local function Median(values)
    if type(values) ~= "table" or #values == 0 then return nil end
    local ordered = {}
    for _, value in ipairs(values) do
        value = Number(value)
        if value ~= nil then table.insert(ordered, value) end
    end
    if #ordered == 0 then return nil end
    table.sort(ordered)
    local middle = math.floor(#ordered / 2)
    if #ordered % 2 == 1 then return ordered[middle + 1] end
    return (ordered[middle] + ordered[middle + 1]) / 2
end

local function MetricValues(encounters, metricKey)
    local values = {}
    for _, encounter in ipairs(encounters or {}) do
        local value = RaidAnalysis.GetTrendMetricValue(encounter, metricKey)
        if value ~= nil then table.insert(values, value) end
    end
    return values
end

local function BuildSignal(earlierPulls, recentPulls, metricKey)
    local info = RaidAnalysis.GetTrendMetricInfo(metricKey)
    local earlierValue = Median(MetricValues(earlierPulls, metricKey))
    local recentValue = Median(MetricValues(recentPulls, metricKey))
    local signal = {
        metricKey = metricKey,
        metricInfo = info,
        earlierValue = earlierValue,
        recentValue = recentValue,
        activityOnly = ACTIVITY_METRICS[metricKey] == true,
        contextOnly = CONTEXT_METRICS[metricKey] == true,
        state = "unavailable",
        score = 0,
    }
    if recentValue == nil then return signal end
    if earlierValue == nil then
        signal.state = "baseline"
        return signal
    end

    signal.delta = recentValue - earlierValue
    signal.deltaPercent = DeltaPercent(recentValue, earlierValue)
    local threshold = 5
    local stable = signal.delta == 0
        or signal.deltaPercent ~= nil and math.abs(signal.deltaPercent) <= threshold
        or signal.deltaPercent == nil and math.abs(signal.delta) < 0.5
    if stable then
        signal.state = "stable"
        return signal
    end

    local increased = signal.delta > 0
    local improved = info.higherIsBetter ~= false and increased
        or info.higherIsBetter == false and not increased
    signal.state = improved and "improving" or "declining"
    if not signal.activityOnly and not signal.contextOnly then
        signal.score = improved and 1 or -1
    end
    return signal
end

local function BuildConsistency(encounters, metricKey)
    local values = MetricValues(encounters, metricKey)
    if #values < 2 then return { label = "Building Baseline", sampleSize = #values } end
    local middle = Median(values)
    if middle == nil or middle == 0 then return { label = "Building Baseline", sampleSize = #values } end
    local deviations = {}
    for _, value in ipairs(values) do table.insert(deviations, math.abs(value - middle)) end
    local spread = (Median(deviations) or 0) / math.abs(middle) * 100
    local label = spread <= 5 and "Steady" or spread <= 12 and "Some Variation" or "Variable"
    return { label = label, spreadPercent = spread, sampleSize = #values }
end

local function OrderedEncounters(encounters)
    local ordered = {}
    for _, encounter in ipairs(encounters or {}) do table.insert(ordered, encounter) end
    table.sort(ordered, function(a, b)
        return (Number(a and a.timestamp) or 0) < (Number(b and b.timestamp) or 0)
    end)
    return ordered
end

function RaidAnalysis.BuildBossPerformance(encounters, metricKey)
    local ordered = OrderedEncounters(encounters)
    local result = {
        metricKey = metricKey,
        metricInfo = RaidAnalysis.GetTrendMetricInfo(metricKey),
        totalPulls = #ordered,
        comparablePulls = {},
        earlierPulls = {},
        recentPulls = {},
        status = "Building Baseline",
        confidence = "No comparison yet",
    }
    if #ordered == 0 then return result end

    -- Never mix difficulties or specializations. When an All filter is used,
    -- use the latest pull's context and explain the smaller comparison sample.
    local latest = ordered[#ordered]
    local latestRaid = RaidAnalysis.GetRaid(latest)
    local latestDifficultyID = Number(latestRaid.difficultyID)
    local latestSpec = RaidAnalysis.GetSpecName(latest)
    result.difficultyID = latestDifficultyID
    result.difficultyName = latestRaid.difficultyName or "Unknown Difficulty"
    result.spec = latestSpec

    local contextPulls = {}
    for _, encounter in ipairs(ordered) do
        local raid = RaidAnalysis.GetRaid(encounter)
        if Number(raid.difficultyID) == latestDifficultyID and RaidAnalysis.GetSpecName(encounter) == latestSpec then
            table.insert(contextPulls, encounter)
        end
    end
    result.contextPulls = contextPulls
    result.excludedContextPulls = #ordered - #contextPulls

    -- Pull duration is only used to find a comparable group. Performance
    -- itself always uses DPS, HPS, or a per-minute value where appropriate.
    local referenceDuration = PullDuration(contextPulls[#contextPulls])
    local comparable = {}
    if referenceDuration and referenceDuration > 0 then
        for _, encounter in ipairs(contextPulls) do
            local duration = PullDuration(encounter)
            if duration and duration >= 30 and duration >= referenceDuration * 0.70 and duration <= referenceDuration * 1.30 then
                table.insert(comparable, encounter)
            end
        end
    end
    if #comparable < 2 then
        comparable = {}
        for _, encounter in ipairs(contextPulls) do
            if RaidAnalysis.GetTrendMetricValue(encounter, metricKey) ~= nil then table.insert(comparable, encounter) end
        end
        result.comparisonMode = "normalized"
    else
        result.comparisonMode = "similar duration"
    end
    result.comparablePulls = comparable

    local comparableCount = #comparable
    local windowSize = math.min(3, math.floor(comparableCount / 2))
    if windowSize > 0 then
        for index = comparableCount - (windowSize * 2) + 1, comparableCount - windowSize do
            table.insert(result.earlierPulls, comparable[index])
        end
        for index = comparableCount - windowSize + 1, comparableCount do
            table.insert(result.recentPulls, comparable[index])
        end
    elseif comparableCount == 1 then
        table.insert(result.recentPulls, comparable[1])
    end

    result.selectedSignal = BuildSignal(result.earlierPulls, result.recentPulls, metricKey)
    local executionKey = metricKey == "avoidableDamageTaken" and "damageTaken" or "avoidableDamageTaken"
    result.executionSignal = BuildSignal(result.earlierPulls, result.recentPulls, executionKey)

    local consistencyPulls = {}
    for index = math.max(1, comparableCount - 4), comparableCount do
        if comparable[index] then table.insert(consistencyPulls, comparable[index]) end
    end
    result.consistency = BuildConsistency(consistencyPulls, metricKey)

    local earlierDurations, recentDurations = {}, {}
    for _, encounter in ipairs(result.earlierPulls) do
        local duration = PullDuration(encounter)
        if duration then table.insert(earlierDurations, duration) end
    end
    for _, encounter in ipairs(result.recentPulls) do
        local duration = PullDuration(encounter)
        if duration then table.insert(recentDurations, duration) end
    end
    result.earlierDuration = Median(earlierDurations)
    result.recentDuration = Median(recentDurations)
    result.durationDelta = result.earlierDuration and result.recentDuration and (result.recentDuration - result.earlierDuration) or nil

    if comparableCount < 2 then
        result.status = "Building Baseline"
        result.confidence = "One comparable pull"
    elseif result.selectedSignal.activityOnly then
        result.status = "Activity Snapshot"
        result.confidence = comparableCount < 4 and "Early signal" or comparableCount < 6 and "Developing pattern" or "Established pattern"
    elseif result.selectedSignal.contextOnly then
        result.status = "Pull Context"
        result.confidence = comparableCount < 4 and "Early signal" or comparableCount < 6 and "Developing pattern" or "Established pattern"
    else
        local selectedScore = result.selectedSignal.score or 0
        local executionScore = result.executionSignal.score or 0
        if selectedScore >= 0 and executionScore >= 0 and (selectedScore > 0 or executionScore > 0) then
            result.status = "Improving"
        elseif selectedScore <= 0 and executionScore <= 0 and (selectedScore < 0 or executionScore < 0) then
            result.status = "Needs Attention"
        elseif selectedScore == 0 and executionScore == 0 then
            result.status = "Stable"
        else
            result.status = "Mixed Results"
        end
        result.confidence = comparableCount < 4 and "Early signal" or comparableCount < 6 and "Developing pattern" or "Established pattern"
    end
    return result
end

function RaidAnalysis.BuildTrend(encounters, metricKey)
    local ordered = {}
    for _, encounter in ipairs(encounters or {}) do
        table.insert(ordered, encounter)
    end
    table.sort(ordered, function(a, b)
        return (Number(a and a.timestamp) or 0) < (Number(b and b.timestamp) or 0)
    end)

    local result = {
        encounters = ordered,
        totalPulls = #ordered,
        kills = 0,
        wipes = 0,
        metricKey = metricKey,
        metricInfo = RaidAnalysis.GetTrendMetricInfo(metricKey),
        rows = {},
    }
    local firstKillSeen = false
    for index, encounter in ipairs(ordered) do
        local raid = RaidAnalysis.GetRaid(encounter)
        local duration = PullDuration(encounter)
        local row = {
            index = index,
            encounter = encounter,
            raid = raid,
            killed = raid.killed == true,
            result = raid.killed == true and "Kill" or "Wipe",
            duration = duration,
            totalValue = RaidAnalysis.GetTrendMetricTotalValue(encounter, metricKey),
            rateValue = RaidAnalysis.GetTrendMetricRateValue(encounter, metricKey),
        }

        if raid.killed == true then
            result.kills = result.kills + 1
            if not firstKillSeen then
                firstKillSeen = true
                result.firstKillPull = index
                row.isFirstKill = true
            end
        else
            result.wipes = result.wipes + 1
        end

        local previous = result.rows[index - 1]
        if previous then
            if row.totalValue ~= nil and previous.totalValue ~= nil then
                row.totalDelta = row.totalValue - previous.totalValue
                row.totalDeltaPercent = DeltaPercent(row.totalValue, previous.totalValue)
            end
            if row.rateValue ~= nil and previous.rateValue ~= nil then
                row.rateDelta = row.rateValue - previous.rateValue
                row.rateDeltaPercent = DeltaPercent(row.rateValue, previous.rateValue)
            end
            if row.duration ~= nil and previous.duration ~= nil then
                row.durationDelta = row.duration - previous.duration
            end

            local previousComparison
            if result.metricInfo.rateLabel then
                row.comparisonValue = row.rateValue
                previousComparison = previous.rateValue
            else
                row.comparisonValue = row.totalValue
                previousComparison = previous.totalValue
            end
            if row.comparisonValue ~= nil and previousComparison ~= nil then
                row.comparisonDelta = row.comparisonValue - previousComparison
                row.comparisonDeltaPercent = DeltaPercent(row.comparisonValue, previousComparison)
                local aboutTheSame = row.comparisonDelta == 0
                    or (row.comparisonDeltaPercent ~= nil and math.abs(row.comparisonDeltaPercent) <= 3)
                if aboutTheSame then
                    row.direction = "About the Same"
                    row.isImprovement = nil
                elseif row.comparisonDelta > 0 then
                    row.direction = "Higher Than Previous Pull"
                    row.isImprovement = result.metricInfo.higherIsBetter ~= false
                else
                    row.direction = "Lower Than Previous Pull"
                    row.isImprovement = result.metricInfo.higherIsBetter == false
                end
            else
                row.direction = "Comparison Not Available"
            end
        else
            row.direction = "First Saved Pull — Baseline"
        end

        table.insert(result.rows, row)
    end
    result.killRate = result.totalPulls > 0 and (result.kills / result.totalPulls) or 0
    result.latest = result.rows[#result.rows]
    result.previous = result.rows[#result.rows - 1]
    return result
end

return RaidAnalysis
