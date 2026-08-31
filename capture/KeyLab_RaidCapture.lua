local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Capture = KeyLab.Capture or {}
KeyLab.Capture.Raid = KeyLab.Capture.Raid or {}

local RaidCapture = KeyLab.Capture.Raid
local DamageMeter = KeyLab.Capture.DamageMeter
local PlayerCapture = KeyLab.Capture.Player
local StatCapture = KeyLab.Capture.Stats
local TalentCapture = KeyLab.Capture.Talents
local GearCapture = KeyLab.GearCapture

-- Raid capture is event-bound: only ENCOUNTER_START/END inside a raid creates
-- pulls. Combat sessions between those events (raid trash) are never stored.

local function Print(message)
    if KeyLab.Debug then KeyLab.Debug("Raid capture: " .. tostring(message)) end
end

local function EnsureState()
    KeyLabCaptureDB = type(KeyLabCaptureDB) == "table" and KeyLabCaptureDB or {}
    if type(KeyLabCaptureDB.raid) ~= "table" then KeyLabCaptureDB.raid = {} end
    return KeyLabCaptureDB.raid
end

local function Probe(message)
    local state = EnsureState()
    if state.probeEnabled == true and KeyLab.Print then
        KeyLab.Print("Raid Probe: " .. tostring(message))
    end
end

local function CountKeys(value)
    if type(value) ~= "table" then return 0 end
    local count = 0
    for _ in pairs(value) do count = count + 1 end
    return count
end

local function RequiredRoleMetricKeys(player)
    player = type(player) == "table" and player or {}
    local role = player.blizzardRole or player.role
    local classSpecs = KeyLab.Mapping and KeyLab.Mapping.ClassSpecs
    if classSpecs and classSpecs.GetRole then
        role = classSpecs.GetRole(player.specID, player.class or player.className, player.spec or player.specName) or role
    end

    if role == "Healer" or role == "HEALER" then
        return { "hps", "healingDone" }
    end
    if role == "Tank" or role == "TANK" then
        return { "damageTaken", "healingDone" }
    end
    return { "dps", "damageDone" }
end

local function MissingRoleMetricKeys(metrics, player)
    metrics = type(metrics) == "table" and metrics or {}
    local missing = {}
    for _, metricKey in ipairs(RequiredRoleMetricKeys(player)) do
        if metrics[metricKey] == nil then table.insert(missing, metricKey) end
    end
    return missing
end

local function SafeCall(func, ...)
    if type(func) ~= "function" then return false end
    return pcall(func, ...)
end

local function GetInstanceContext()
    local context = {}
    if not GetInstanceInfo then return context end

    local ok, name, instanceType, difficultyID, difficultyName, maxPlayers,
        dynamicDifficulty, isDynamic, instanceID, instanceGroupSize, lfgDungeonID = SafeCall(GetInstanceInfo)
    if not ok then return context end

    context.instanceName = name
    context.instanceType = instanceType
    context.difficultyID = difficultyID
    context.difficultyName = difficultyName
    context.maxPlayers = maxPlayers
    context.instanceID = instanceID
    context.instanceMapID = instanceID
    context.instanceGroupSize = instanceGroupSize
    context.lfgDungeonID = lfgDungeonID

    -- The raid list uses Encounter Journal instance IDs, while
    -- GetInstanceInfo returns the map instance ID. Convert when the client API
    -- can provide that relationship; encounter ID resolution below remains the
    -- reliable fallback.
    if context.instanceType == "raid" and instanceID and EJ_GetInstanceForMap then
        local journalOK, journalInstanceID = SafeCall(EJ_GetInstanceForMap, instanceID)
        journalInstanceID = journalOK and tonumber(journalInstanceID) or nil
        if journalInstanceID and journalInstanceID > 0 then
            context.instanceID = journalInstanceID
        end
    end
    return context
end

local function NormalizeRaidContext(context, encounterID)
    if type(context) ~= "table" or context.instanceType ~= "raid" then return context end

    local raids = KeyLab.Mapping and KeyLab.Mapping.Raids
    if not raids then return context end

    local configured = raids.GetInstance and raids.GetInstance(context.instanceID) or nil
    if not configured and encounterID and raids.GetInstanceForEncounter then
        configured = raids.GetInstanceForEncounter(encounterID)
    end
    if not configured and raids.GetInstanceByName then
        configured = raids.GetInstanceByName(context.instanceName)
    end

    if configured then
        context.instanceMapID = context.instanceMapID or context.instanceID
        context.instanceID = configured.instanceID
        context.instanceName = configured.name or context.instanceName
    end
    return context
end

local function IsSameRaid(night, context)
    if type(night) ~= "table" or type(context) ~= "table" or context.instanceType ~= "raid" then return false end
    if night.instanceID and context.instanceID then
        return night.instanceID == context.instanceID and night.difficultyID == context.difficultyID
    end
    return night.instanceName == context.instanceName and night.difficultyID == context.difficultyID
end

local function IsAllowedRaidInstance(context)
    return type(context) == "table"
        and context.instanceType == "raid"
        and KeyLab.Mapping
        and KeyLab.Mapping.Raids
        and KeyLab.Mapping.Raids.IsAllowedInstance
        and KeyLab.Mapping.Raids.IsAllowedInstance(context.instanceID)
end

local function MakeNightID(context, timestamp)
    local savedNights = KeyLab.DB and KeyLab.DB.Raids and KeyLab.DB.Raids.GetNights
        and KeyLab.DB.Raids.GetNights()
        or {}
    return string.format(
        "raid-night-%s-%s-%s-%s",
        date("%Y%m%d%H%M%S", timestamp),
        tostring(context.instanceID or 0),
        tostring(UnitName and UnitName("player") or "player"),
        tostring(#savedNights + 1)
    )
end

local function StartNight(context)
    local state = EnsureState()
    local startedAt = time()
    state.night = {
        id = MakeNightID(context, startedAt),
        startedAt = startedAt,
        instanceID = context.instanceID,
        instanceMapID = context.instanceMapID,
        instanceName = context.instanceName,
        difficultyID = context.difficultyID,
        difficultyName = context.difficultyName,
        maxPlayers = context.maxPlayers,
        pullIDs = {},
        bossAttempts = {},
        bossKills = {},
        killPulls = 0,
        groupMembers = {},
        groupMetricTotals = {},
        player = PlayerCapture and PlayerCapture.GetSnapshot and PlayerCapture.GetSnapshot() or {},
    }
    return state.night
end

local CloseNight
local FinalizePull

local function CopyValues(source)
    local out = {}
    for key, value in pairs(type(source) == "table" and source or {}) do out[key] = value end
    return out
end

local function DeepCopy(source, seen)
    if type(source) ~= "table" then return source end
    seen = seen or {}
    if seen[source] then return seen[source] end
    local out = {}
    seen[source] = out
    for key, value in pairs(source) do out[DeepCopy(key, seen)] = DeepCopy(value, seen) end
    return out
end

local function MetricInfo(metricKey)
    for _, info in pairs(KeyLab.Mapping and KeyLab.Mapping.Metrics or {}) do
        if type(info) == "table" and info.keylabKey == metricKey then return info end
    end
    return nil
end

local function AddGroupMetricRow(night, metricKey, row, durationSeconds)
    if type(row) ~= "table" or not row.sourceID then return end
    night.groupMembers = type(night.groupMembers) == "table" and night.groupMembers or {}
    night.groupMetricTotals = type(night.groupMetricTotals) == "table" and night.groupMetricTotals or {}
    night.groupMembers[row.sourceID] = true
    night.groupMetricTotals[metricKey] = type(night.groupMetricTotals[metricKey]) == "table" and night.groupMetricTotals[metricKey] or {}
    local aggregate = night.groupMetricTotals[metricKey][row.sourceID]
    if type(aggregate) ~= "table" then
        aggregate = { totalAmount = 0, activeSeconds = 0, pulls = 0 }
        night.groupMetricTotals[metricKey][row.sourceID] = aggregate
    end
    local totalAmount = tonumber(row.totalAmount) or 0
    local rate = tonumber(row.amountPerSecond)
    aggregate.totalAmount = (tonumber(aggregate.totalAmount) or 0) + totalAmount
    if rate and rate > 0 and totalAmount > 0 then
        aggregate.activeSeconds = (tonumber(aggregate.activeSeconds) or 0) + (totalAmount / rate)
    elseif (metricKey == "dps" or metricKey == "hps") and totalAmount > 0 then
        aggregate.activeSeconds = (tonumber(aggregate.activeSeconds) or 0) + (tonumber(durationSeconds) or 0)
    end
    aggregate.pulls = (tonumber(aggregate.pulls) or 0) + 1
end

local function AddGroupMetricsToNight(night, groupMetrics, durationSeconds)
    if type(night) ~= "table" or type(groupMetrics) ~= "table" then return end
    for metricKey, rows in pairs(groupMetrics) do
        for _, row in ipairs(type(rows) == "table" and rows or {}) do
            AddGroupMetricRow(night, metricKey, row, durationSeconds)
        end
    end
end

local function AggregatedMetricValue(metricKey, aggregate)
    aggregate = type(aggregate) == "table" and aggregate or {}
    local total = tonumber(aggregate.totalAmount) or 0
    if metricKey == "dps" or metricKey == "hps" then
        local activeSeconds = tonumber(aggregate.activeSeconds) or 0
        return activeSeconds > 0 and (total / activeSeconds) or 0
    end
    if metricKey == "damageTaken" or metricKey == "avoidableDamageTaken" then
        local activeSeconds = tonumber(aggregate.activeSeconds) or 0
        return activeSeconds > 0 and ((total / activeSeconds) * 60) or 0
    end
    return total
end

local function BuildNightMetricRanks(night)
    local ranks, localValues = {}, {}
    local members = type(night and night.groupMembers) == "table" and night.groupMembers or {}
    local totals = type(night and night.groupMetricTotals) == "table" and night.groupMetricTotals or {}
    local memberCount = 0
    for _ in pairs(members) do memberCount = memberCount + 1 end
    if memberCount == 0 or not members.player then return ranks, localValues end

    for metricKey, byMember in pairs(totals) do
        local info = MetricInfo(metricKey)
        local lowerIsBetter = info and info.higherIsBetter == false
        local playerValue = AggregatedMetricValue(metricKey, byMember.player)
        local rank, bestValue = 1, playerValue
        for sourceID in pairs(members) do
            local value = AggregatedMetricValue(metricKey, byMember[sourceID])
            if (lowerIsBetter and value < playerValue) or ((not lowerIsBetter) and value > playerValue) then rank = rank + 1 end
            if (lowerIsBetter and value < bestValue) or ((not lowerIsBetter) and value > bestValue) then bestValue = value end
        end
        ranks[metricKey] = {
            rank = rank,
            total = memberCount,
            value = playerValue,
            bestValue = bestValue,
            higherIsBetter = not lowerIsBetter,
            calculation = "boss pulls only",
        }
        localValues[metricKey] = playerValue
    end
    return ranks, localValues
end

local function CheckpointMatchesPlayer(checkpoint)
    local player = type(checkpoint) == "table" and checkpoint.player or {}
    local savedName = tostring(player.playerName or player.name or ""):lower()
    local currentName = tostring(UnitName and UnitName("player") or ""):lower()
    if savedName ~= "" and currentName ~= "" and savedName ~= currentName then return false end

    local savedRealm = tostring(player.realm or player.realmName or ""):lower():gsub("%s+", "")
    local currentRealm = tostring(GetRealmName and GetRealmName() or ""):lower():gsub("%s+", "")
    return savedRealm == "" or currentRealm == "" or savedRealm == currentRealm
end

local function ResumeNightFromCheckpoint(context)
    local state = EnsureState()
    if state.night then return state.night end
    if not (KeyLab.DB and KeyLab.DB.Raids and KeyLab.DB.Raids.GetNights) then return nil end

    for _, checkpoint in ipairs(KeyLab.DB.Raids.GetNights() or {}) do
        local checkpointTime = tonumber(checkpoint and checkpoint.endTime) or 0
        local recent = checkpointTime > 0 and (time() - checkpointTime) <= (12 * 60 * 60)
        if checkpoint and checkpoint.inProgress == true and recent
            and IsSameRaid(checkpoint, context) and CheckpointMatchesPlayer(checkpoint)
        then
            state.night = {
                id = checkpoint.id,
                startedAt = checkpoint.startTime,
                instanceID = checkpoint.instanceID,
                instanceMapID = checkpoint.instanceMapID,
                instanceName = checkpoint.instanceName,
                difficultyID = checkpoint.difficultyID,
                difficultyName = checkpoint.difficultyName,
                maxPlayers = checkpoint.maxPlayers,
                pullIDs = CopyValues(checkpoint.pullIDs),
                bossAttempts = CopyValues(checkpoint.bossAttempts),
                bossKills = CopyValues(checkpoint.bossKills),
                killPulls = tonumber(checkpoint.killPulls) or 0,
                player = CopyValues(checkpoint.player),
                groupMembers = DeepCopy(checkpoint.groupMembers),
                groupMetricTotals = DeepCopy(checkpoint.groupMetricTotals),
            }
            Probe("RESUMED raid session " .. tostring(checkpoint.id) .. " with " .. tostring(#state.night.pullIDs) .. " saved pull(s)")
            return state.night
        end
    end
    return nil
end

local function FinalizeOrphanedCheckpoint(context)
    if type(context) ~= "table" or context.instanceType == nil then return false end
    if not (KeyLab.DB and KeyLab.DB.Raids and KeyLab.DB.Raids.GetNights and KeyLab.DB.Raids.AddNight) then return false end

    for _, checkpoint in ipairs(KeyLab.DB.Raids.GetNights() or {}) do
        if checkpoint and checkpoint.inProgress == true and CheckpointMatchesPlayer(checkpoint) then
            if not IsSameRaid(checkpoint, context) then
                checkpoint.inProgress = false
                checkpoint.closeReason = "login outside raid"
                checkpoint.groupMembers = nil
                checkpoint.groupMetricTotals = nil
                KeyLab.DB.Raids.AddNight(checkpoint)
                Probe("FINALIZED saved raid checkpoint after login outside the raid")
                return true
            end
            return false
        end
    end
    return false
end

local function EnsureNight(context)
    local state = EnsureState()
    if state.night and not IsSameRaid(state.night, context) then
        CloseNight("new raid instance", true)
    end
    return state.night or ResumeNightFromCheckpoint(context) or StartNight(context)
end

local function AddPullToNight(night, encounter)
    local encounterID = encounter.raid.encounterID
    local key = tostring(encounterID)
    night.bossAttempts[key] = (tonumber(night.bossAttempts[key]) or 0) + 1
    if encounter.raid.killed then
        night.bossKills[key] = true
        night.killPulls = (tonumber(night.killPulls) or 0) + 1
    end
    table.insert(night.pullIDs, encounter.id)
    encounter.raid.pullNumber = night.bossAttempts[key]
    encounter.raid.nightPullNumber = #night.pullIDs
end

FinalizePull = function(finalAttempt, token)
    local state = EnsureState()
    local pull = state.activePull
    if type(pull) ~= "table" or pull.ended ~= true then
        Probe("FINALIZE stopped: no ended raid pull")
        return false, "no ended raid pull"
    end
    if token and pull.token ~= token then
        Probe("FINALIZE stopped: the active pull changed")
        return false, "raid pull changed"
    end

    local metrics, metricError, ranks, meterSession, groupMetrics = {}, nil, {}, nil, {}
    if DamageMeter and DamageMeter.GetRaidEncounterSnapshot then
        metrics, metricError, ranks, meterSession, groupMetrics = DamageMeter.GetRaidEncounterSnapshot(
            pull.encounterName,
            pull.previousSessionIDs
        )
    else
        metricError = "raid damage-meter capture unavailable"
    end

    Probe(
        "METER boss=" .. tostring(pull.encounterName)
        .. " metrics=" .. tostring(CountKeys(metrics))
        .. " session=" .. tostring(meterSession and meterSession.sessionID or "none")
        .. " finalAttempt=" .. tostring(finalAttempt == true)
        .. (metricError and (" note=" .. tostring(metricError)) or "")
    )

    local missingRoleMetrics = MissingRoleMetricKeys(metrics, pull.player)
    local incompleteRoleMetrics = #missingRoleMetrics > 0
    if (type(metrics) ~= "table" or next(metrics) == nil or incompleteRoleMetrics)
        and finalAttempt ~= true and C_Timer
    then
        Probe(
            "WAITING four more seconds for the boss Damage Meter session"
            .. (incompleteRoleMetrics and ("; missing " .. table.concat(missingRoleMetrics, ", ")) or "")
        )
        C_Timer.After(4, function() FinalizePull(true, pull.token) end)
        return false, metricError
    end

    local night = state.night
    if type(night) ~= "table" then return false, "raid session missing" end

    local endedAt = pull.endedAt or time()
    local durationSeconds = meterSession and tonumber(meterSession.durationSeconds) or nil
    if not durationSeconds or durationSeconds <= 0 then
        durationSeconds = math.max(0, endedAt - (pull.startedAt or endedAt))
    end

    local encounter = {
        id = string.format("raid-pull-%s-%s-%s", date("%Y%m%d%H%M%S", endedAt), tostring(pull.encounterID), tostring(#night.pullIDs + 1)),
        contentType = "raid",
        recordType = "bossPull",
        timestamp = endedAt,
        dateText = date("%Y-%m-%d %H:%M:%S", endedAt),
        result = pull.killed and "Kill" or "Wipe",
        raid = {
            raidNightID = night.id,
            encounterID = pull.encounterID,
            encounterName = pull.encounterName,
            instanceID = night.instanceID,
            instanceMapID = night.instanceMapID,
            instanceName = night.instanceName,
            difficultyID = pull.difficultyID or night.difficultyID,
            difficultyName = night.difficultyName,
            groupSize = pull.groupSize,
            killed = pull.killed == true,
            startedAt = pull.startedAt,
            endedAt = endedAt,
            durationSeconds = durationSeconds,
        },
        player = pull.player,
        talents = pull.talents,
        stats = pull.stats,
        gear = pull.gear,
        metrics = type(metrics) == "table" and metrics or {},
        metricRanks = type(ranks) == "table" and ranks or {},
        meterSession = meterSession,
        flags = { interrupted = false, excludedFromComparisons = false },
    }
    if metricError then
        encounter.captureNotes = { damageMeter = metricError }
    end
    if incompleteRoleMetrics then
        encounter.captureNotes = type(encounter.captureNotes) == "table" and encounter.captureNotes or {}
        encounter.captureNotes.rolePerformance = "Blizzard Damage Meter did not provide "
            .. table.concat(missingRoleMetrics, ", ") .. " after KeyLab retried this raid pull."
    end

    AddPullToNight(night, encounter)
    local ok, result = false, "raid database unavailable"
    if KeyLab.DB and KeyLab.DB.Raids and KeyLab.DB.Raids.AddEncounter then
        ok, result = KeyLab.DB.Raids.AddEncounter(encounter)
    end
    if not ok then
        table.remove(night.pullIDs)
        local key = tostring(pull.encounterID)
        night.bossAttempts[key] = math.max(0, (tonumber(night.bossAttempts[key]) or 1) - 1)
        if pull.killed then
            night.killPulls = math.max(0, (tonumber(night.killPulls) or 1) - 1)
            if night.bossAttempts[key] == 0 then night.bossKills[key] = nil end
        end
        Probe("SAVE FAILED: " .. tostring(result))
        return false, result
    end

    AddGroupMetricsToNight(night, groupMetrics, durationSeconds)

    state.activePull = nil
    local pendingCloseReason = state.pendingCloseReason
    local pendingClosePreserve = state.pendingClosePreserve == true
    state.pendingCloseReason = nil
    state.pendingClosePreserve = nil
    if KeyLab.RefreshTabs then KeyLab.RefreshTabs() end
    Print(tostring(pull.encounterName) .. " saved as " .. tostring(encounter.result))
    Probe(
        "SAVED " .. tostring(pull.encounterName)
        .. " as " .. tostring(encounter.result)
        .. " duration=" .. tostring(durationSeconds)
        .. "s metrics=" .. tostring(CountKeys(encounter.metrics))
    )
    if pendingCloseReason then
        CloseNight(pendingCloseReason, true, pendingClosePreserve)
    else
        -- Keep the live raid summary and its anonymous group accumulator
        -- checkpointed after every completed boss pull.
        CloseNight("raid in progress", false, true)
    end
    return true, result
end

CloseNight = function(reason, forcePullFinalize, preserveForResume)
    local state = EnsureState()
    if state.activePull and state.activePull.ended then
        state.pendingCloseReason = reason
        state.pendingClosePreserve = preserveForResume == true
        local saved = FinalizePull(forcePullFinalize == true, state.activePull.token)
        if state.night == nil then return true end
        if not saved then
            if forcePullFinalize ~= true then return false, "waiting for the boss combat session" end
            state.pendingCloseReason = nil
            state.pendingClosePreserve = nil
            return false, "the final boss pull could not be saved"
        end
    end

    local night = state.night
    if type(night) ~= "table" then return false, "no active raid session" end

    if #(night.pullIDs or {}) == 0 then
        if preserveForResume == true then
            return false, "raid session checkpoint had no completed boss pulls"
        end
        state.night = nil
        state.activePull = nil
        state.pendingCloseReason = nil
        state.pendingClosePreserve = nil
        return false, "raid session had no completed boss pulls"
    end

    local bossesAttempted, bossesKilled = 0, 0
    for _ in pairs(night.bossAttempts or {}) do bossesAttempted = bossesAttempted + 1 end
    for _ in pairs(night.bossKills or {}) do bossesKilled = bossesKilled + 1 end

    local endedAt = time()
    local killPulls = tonumber(night.killPulls) or bossesKilled
    local nightMetricRanks, nightMetrics = BuildNightMetricRanks(night)
    local summary = {
        id = night.id,
        contentType = "raid",
        recordType = "raidNight",
        startTime = night.startedAt,
        endTime = endedAt,
        dateText = date("%Y-%m-%d %H:%M:%S", endedAt),
        closeReason = reason,
        instanceID = night.instanceID,
        instanceMapID = night.instanceMapID,
        instanceName = night.instanceName,
        difficultyID = night.difficultyID,
        difficultyName = night.difficultyName,
        maxPlayers = night.maxPlayers,
        player = night.player,
        pullIDs = CopyValues(night.pullIDs),
        totalPulls = #night.pullIDs,
        bossesAttempted = bossesAttempted,
        bossesKilled = bossesKilled,
        bossAttempts = CopyValues(night.bossAttempts),
        bossKills = CopyValues(night.bossKills),
        killPulls = killPulls,
        wipes = #night.pullIDs - killPulls,
        nightMetricRanks = nightMetricRanks,
        nightMetrics = nightMetrics,
        groupMembers = preserveForResume == true and DeepCopy(night.groupMembers) or nil,
        groupMetricTotals = preserveForResume == true and DeepCopy(night.groupMetricTotals) or nil,
        inProgress = preserveForResume == true,
    }

    local ok, result = false, "raid database unavailable"
    if KeyLab.DB and KeyLab.DB.Raids and KeyLab.DB.Raids.AddNight then
        ok, result = KeyLab.DB.Raids.AddNight(summary)
    end

    if ok then
        if preserveForResume ~= true then
            state.night = nil
            state.activePull = nil
        end
        if KeyLab.RefreshTabs then KeyLab.RefreshTabs() end
        Print("raid session " .. (preserveForResume == true and "checkpoint saved: " or "closed: ") .. tostring(reason))
        Probe(
            (preserveForResume == true and "SUMMARY CHECKPOINT SAVED reason=" or "SUMMARY SAVED reason=") .. tostring(reason)
            .. " pulls=" .. tostring(summary.totalPulls)
            .. " kills=" .. tostring(summary.killPulls)
            .. " wipes=" .. tostring(summary.wipes)
        )
    else
        Probe("SUMMARY FAILED: " .. tostring(result))
    end
    return ok, result
end

function RaidCapture.StartEncounter(encounterID, encounterName, difficultyID, groupSize)
    local context = NormalizeRaidContext(GetInstanceContext(), encounterID)
    Probe(
        "START boss=" .. tostring(encounterName)
        .. " encounterID=" .. tostring(encounterID)
        .. " type=" .. tostring(context.instanceType)
        .. " mapID=" .. tostring(context.instanceMapID)
        .. " raidID=" .. tostring(context.instanceID)
        .. " difficultyID=" .. tostring(difficultyID)
    )
    if context.instanceType ~= "raid" then
        Probe("START REJECTED: location type was not raid")
        return false
    end
    if not (KeyLab.Mapping and KeyLab.Mapping.Raids and KeyLab.Mapping.Raids.IsAllowedRuntimeEncounter
        and KeyLab.Mapping.Raids.IsAllowedRuntimeEncounter(context.instanceID, encounterID))
    then
        Print("ignored encounterID " .. tostring(encounterID) .. " in instanceID " .. tostring(context.instanceID))
        Probe("START REJECTED: the encounter was not inside a supported raid")
        return false
    end

    local state = EnsureState()
    if state.activePull and state.activePull.ended then FinalizePull(true, state.activePull.token) end

    local night = EnsureNight(context)
    local startedAt = time()
    state.activePull = {
        token = tostring(encounterID) .. "-" .. tostring(startedAt),
        encounterID = encounterID,
        encounterName = encounterName,
        difficultyID = difficultyID,
        groupSize = groupSize,
        startedAt = startedAt,
        player = PlayerCapture and PlayerCapture.GetSnapshot and PlayerCapture.GetSnapshot() or {},
        talents = TalentCapture and TalentCapture.GetSnapshot and TalentCapture.GetSnapshot() or {},
        stats = StatCapture and StatCapture.GetSnapshot and StatCapture.GetSnapshot() or {},
        gear = GearCapture and GearCapture.GetProfileSnapshot and GearCapture.GetProfileSnapshot() or {},
        previousSessionIDs = DamageMeter and DamageMeter.GetAvailableSessionIDs and DamageMeter.GetAvailableSessionIDs() or {},
    }
    Print("started " .. tostring(encounterName) .. " (encounterID " .. tostring(encounterID) .. ")")
    Probe("START ACCEPTED: player, talents, stats, and gear captured")
    return night ~= nil
end

function RaidCapture.EndEncounter(encounterID, encounterName, difficultyID, groupSize, success)
    local state = EnsureState()
    local pull = state.activePull
    Probe(
        "END boss=" .. tostring(encounterName)
        .. " encounterID=" .. tostring(encounterID)
        .. " success=" .. tostring(success)
        .. " activeEncounterID=" .. tostring(type(pull) == "table" and pull.encounterID or "none")
    )
    if type(pull) ~= "table" or pull.encounterID ~= encounterID then
        Print("ignored unmatched ENCOUNTER_END for encounterID " .. tostring(encounterID))
        Probe("END REJECTED: no matching accepted START was active")
        return false
    end

    pull.encounterName = encounterName or pull.encounterName
    pull.difficultyID = difficultyID or pull.difficultyID
    pull.groupSize = groupSize or pull.groupSize
    pull.killed = success == 1 or success == true
    pull.ended = true
    pull.endedAt = time()

    if C_Timer then
        Probe("END ACCEPTED: checking the Damage Meter in two seconds")
        C_Timer.After(2, function() FinalizePull(false, pull.token) end)
    else
        FinalizePull(true, pull.token)
    end
    return true
end

function RaidCapture.CloseNight(reason)
    return CloseNight(reason or "manual", true)
end

function RaidCapture.SetProbeEnabled(enabled)
    local state = EnsureState()
    state.probeEnabled = enabled == true
    if KeyLab.Print then
        KeyLab.Print(
            "Raid Probe " .. (state.probeEnabled and "enabled. Run a raid boss pull and send the Raid Probe chat lines afterward."
                or "disabled.")
        )
    end
    return state.probeEnabled
end

function RaidCapture.IsProbeEnabled()
    return EnsureState().probeEnabled == true
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("ENCOUNTER_START")
frame:RegisterEvent("ENCOUNTER_END")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LOGOUT")

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == ADDON_NAME then EnsureState() end
        return
    end
    if event == "ENCOUNTER_START" then RaidCapture.StartEncounter(...) return end
    if event == "ENCOUNTER_END" then RaidCapture.EndEncounter(...) return end
    if event == "PLAYER_LOGOUT" then CloseNight("logout", true, true) return end
    if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
        local check = function()
            local currentState = EnsureState()
            local context = NormalizeRaidContext(GetInstanceContext())
            if currentState.night and not IsSameRaid(currentState.night, context) then
                CloseNight("zone change", false)
            end
            currentState = EnsureState()
            if not currentState.night and IsAllowedRaidInstance(context) then
                ResumeNightFromCheckpoint(context)
                if not EnsureState().night then StartNight(context) end
            elseif not currentState.night then
                FinalizeOrphanedCheckpoint(context)
            end
        end
        if C_Timer then C_Timer.After(1, check) else check() end
    end
end)

return RaidCapture
