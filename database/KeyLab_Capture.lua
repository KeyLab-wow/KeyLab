local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Capture = KeyLab.Capture or {}

local Capture = KeyLab.Capture
local Sessions = KeyLab.Capture.Sessions
local ChallengeTimer = KeyLab.Capture.ChallengeTimer
local DamageMeter = KeyLab.Capture.DamageMeter
local PlayerCapture = KeyLab.Capture.Player
local StatCapture = KeyLab.Capture.Stats
local TalentCapture = KeyLab.Capture.Talents
local GearCapture = KeyLab.GearCapture

local METRICS_PENDING_REASON = "Blizzard damage meter totals are not ready"
local FINALIZE_RETRY_DELAYS = { 3, 8, 15, 30 }
local RECOVERY_RETRY_DELAYS = { 5, 15, 30 }

--[[
KeyLab_Capture.lua

Purpose:
- Coordinates Mythic+ run capture.
- Builds final encounter records from separate capture modules.
- Saves final records through EncountersDB.
- Does NOT format UI text.
- Does NOT create UI cards/buttons.
]]

local function Print(msg)
    print("|cffd4af37KeyLab:|r " .. tostring(msg))
end

local function EnsureCaptureDB()
    return Sessions.EnsureCaptureDB()
end

local function ResetCaptureDB()
    return Sessions.ResetCaptureDB(true)
end

local function HasPerformanceMetrics(metrics)
    if type(metrics) ~= "table" then return false end
    return metrics.damageDone ~= nil
        or metrics.dps ~= nil
        or metrics.healingDone ~= nil
        or metrics.hps ~= nil
end

local function SumPullDeathMetrics(combatSessions)
    local localDeaths = 0
    local groupDeaths = 0
    local hasLocalDeaths = false
    local hasGroupDeaths = false
    local deathPullCount = 0

    if type(combatSessions) ~= "table" then
        return localDeaths, groupDeaths, hasLocalDeaths, hasGroupDeaths, deathPullCount
    end

    for _, session in ipairs(combatSessions) do
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

            if (deaths and deaths > 0) or (sessionGroupDeaths and sessionGroupDeaths > 0) then
                deathPullCount = deathPullCount + 1
            end
        end
    end

    return localDeaths, groupDeaths, hasLocalDeaths, hasGroupDeaths, deathPullCount
end

local function BuildDeathAudit(officialGroupDeaths, aggregateLocalDeaths, aggregateGroupDeaths, pullDeaths, pullGroupDeaths, hasPullDeaths, hasPullGroupDeaths)
    local audit = {
        officialGroupDeaths = officialGroupDeaths,
        aggregateLocalDeaths = aggregateLocalDeaths,
        aggregateGroupDeaths = aggregateGroupDeaths,
        pullSessionLocalDeaths = hasPullDeaths and pullDeaths or nil,
        pullSessionGroupDeaths = hasPullGroupDeaths and pullGroupDeaths or nil,
        localDeathSource = hasPullDeaths and "pullSessions" or (aggregateLocalDeaths ~= nil and "aggregateSession" or nil),
        groupDeathSource = officialGroupDeaths ~= nil and "challengeModeDeathCount"
            or (hasPullGroupDeaths and "pullSessions")
            or (aggregateGroupDeaths ~= nil and "aggregateSession" or nil),
    }

    if officialGroupDeaths ~= nil and hasPullGroupDeaths then
        audit.officialMatchesPullSessions = officialGroupDeaths == pullGroupDeaths
    end

    if officialGroupDeaths ~= nil and aggregateGroupDeaths ~= nil then
        audit.officialMatchesAggregate = officialGroupDeaths == aggregateGroupDeaths
    end

    return audit
end

local function BuildEncounterRecord()
    local captureDB = EnsureCaptureDB()
    local context = captureDB.challenge or Sessions.GetChallengeContext()

    if captureDB.completedSeen == true and ChallengeTimer and ChallengeTimer.Complete then
        context = ChallengeTimer.Complete(context)
        captureDB.challenge = context
    end

    local okContext, contextReason = Sessions.IsAllowedChallengeContext(context)
    if not okContext then
        return nil, contextReason
    end

    local metrics, metricError, metricRanks = DamageMeter.GetSnapshot(context)
    if not HasPerformanceMetrics(metrics) then
        return nil, metricError or METRICS_PENDING_REASON
    end

    local aggregateMeterDeaths = tonumber(metrics.deaths)
    local aggregateMeterGroupDeaths = tonumber(metrics.groupDeaths)

    local combatSessions, combatSessionError = {}, nil
    if DamageMeter.GetCombatSessionsSnapshot then
        combatSessions, combatSessionError = DamageMeter.GetCombatSessionsSnapshot(context)
    end

    local pullDeaths, pullGroupDeaths, hasPullDeaths, hasPullGroupDeaths, deathPullCount = SumPullDeathMetrics(combatSessions)
    if hasPullDeaths then
        metrics.deaths = pullDeaths
    end

    local officialGroupDeaths = nil
    if context.deathCountSource == "challengeModeDeathCount" or context.officialDeathCount ~= nil then
        officialGroupDeaths = tonumber(context.officialDeathCount or context.deathCount)
    end
    if officialGroupDeaths ~= nil then
        metrics.groupDeaths = officialGroupDeaths
    elseif hasPullGroupDeaths then
        metrics.groupDeaths = pullGroupDeaths
    end

    local timestamp = time()
    local durationSeconds = context.durationSeconds

    local timed = context.timed
    local captureInterrupted = captureDB.interrupted == true and captureDB.completedSeen ~= true
    local resultText = context.result
        or (timed ~= nil and (timed and "Timed" or "Untimed"))
        or (captureDB.completedSeen == true and "Completed" or "Interrupted")
    local deathAudit = BuildDeathAudit(
        officialGroupDeaths,
        aggregateMeterDeaths,
        aggregateMeterGroupDeaths,
        pullDeaths,
        pullGroupDeaths,
        hasPullDeaths,
        hasPullGroupDeaths
    )

    local encounter = {
        id = Sessions.MakeEncounterID(context),
        timestamp = timestamp,
        dateText = date("%Y-%m-%d %H:%M:%S", timestamp),
        result = resultText,

        challenge = {
            mapID = context.mapID,
            dungeonName = context.dungeonName,
            keyLevel = context.keyLevel,
            affixIDs = Sessions.CopyArray(context.affixIDs),
            durationSeconds = durationSeconds,
            timeLimitSeconds = context.timeLimitSeconds,
            timeDeltaSeconds = context.timeDeltaSeconds,
            remainingSeconds = context.remainingSeconds,
            timed = timed,
            timingSource = context.timingSource,
            durationSource = context.durationSource,
            timedSource = context.timedSource,
            remainingSource = context.remainingSource,
            timeLimitSource = context.timeLimitSource,
            keystoneUpgradeLevels = context.keystoneUpgradeLevels,
            keystoneUpgradeLevelsSource = context.keystoneUpgradeLevelsSource,
            deathCount = context.deathCount,
            officialDeathCount = context.officialDeathCount,
            deathCountSource = context.deathCountSource,
        },

        player = captureDB.playerSnapshot or PlayerCapture.GetSnapshot(),
        talents = captureDB.talentSnapshot or TalentCapture.GetSnapshot(),
        stats = captureDB.statSnapshot or StatCapture.GetSnapshot(),
        gear = captureDB.gearSnapshot or (GearCapture and GearCapture.GetProfileSnapshot and GearCapture.GetProfileSnapshot()) or {},
        metrics = metrics,
        metricRanks = metricRanks,
        combatSessions = combatSessions,
        capture = {
            damageMeterDeaths = tonumber(metrics.deaths),
            groupDeaths = tonumber(metrics.groupDeaths),
            officialChallengeDeaths = officialGroupDeaths,
            aggregateDamageMeterDeaths = aggregateMeterDeaths,
            aggregateGroupDeaths = aggregateMeterGroupDeaths,
            pullSessionDeaths = hasPullDeaths and pullDeaths or nil,
            pullSessionGroupDeaths = hasPullGroupDeaths and pullGroupDeaths or nil,
            deathPullCount = deathPullCount,
            deathMetricSource = hasPullDeaths and "pullSessions" or (aggregateMeterDeaths ~= nil and "aggregateSession" or nil),
            groupDeathMetricSource = officialGroupDeaths ~= nil and "challengeModeDeathCount"
                or (hasPullGroupDeaths and "pullSessions")
                or (aggregateMeterGroupDeaths ~= nil and "aggregateSession" or nil),
            deathAudit = deathAudit,
        },

        flags = {
            interrupted = captureInterrupted,
            excludedFromComparisons = captureInterrupted,
        },
    }

    if combatSessionError then
        encounter.captureNotes = encounter.captureNotes or {}
        encounter.captureNotes.combatSessions = combatSessionError
    end
    if deathAudit.officialMatchesPullSessions == false or deathAudit.officialMatchesAggregate == false then
        encounter.captureNotes = encounter.captureNotes or {}
        encounter.captureNotes.deathAudit = "Death totals differed between available sources; KeyLab kept source details for review."
    end

    return encounter, nil
end

local function SamePlayer(encounterPlayer, currentPlayer)
    if type(encounterPlayer) ~= "table" or type(currentPlayer) ~= "table" then return false end
    if tostring(encounterPlayer.playerName or "") ~= tostring(currentPlayer.playerName or "") then return false end
    local encounterRealm = tostring(encounterPlayer.realm or "")
    local currentRealm = tostring(currentPlayer.realm or "")
    return encounterRealm == "" or currentRealm == "" or encounterRealm == currentRealm
end

function Capture.RepairLatestIncompleteEncounter()
    if not DamageMeter or not DamageMeter.GetSnapshot then return false, "Damage meter capture unavailable" end
    local encounters = KeyLab.DB and KeyLab.DB.Encounters and KeyLab.DB.Encounters.GetAll and KeyLab.DB.Encounters.GetAll() or nil
    if type(encounters) ~= "table" then return false, "Encounter database unavailable" end

    local currentPlayer = PlayerCapture and PlayerCapture.GetSnapshot and PlayerCapture.GetSnapshot() or {}
    local now = time()
    local candidate = nil
    for _, encounter in ipairs(encounters) do
        local timestamp = tonumber(encounter and encounter.timestamp) or 0
        local isRecent = timestamp > 0 and now >= timestamp and (now - timestamp) <= (12 * 60 * 60)
        if isRecent
            and type(encounter.challenge) == "table"
            and SamePlayer(encounter.player, currentPlayer)
            and not HasPerformanceMetrics(encounter.metrics)
            and (not candidate or timestamp > (tonumber(candidate.timestamp) or 0))
        then
            candidate = encounter
        end
    end
    if not candidate then return false, "No recent incomplete encounter found" end

    local metrics, metricError, metricRanks = DamageMeter.GetSnapshot(candidate.challenge)
    if not HasPerformanceMetrics(metrics) then return false, metricError or METRICS_PENDING_REASON end

    candidate.metrics = type(candidate.metrics) == "table" and candidate.metrics or {}
    for key, value in pairs(metrics) do candidate.metrics[key] = value end
    candidate.metricRanks = type(metricRanks) == "table" and metricRanks or {}

    if DamageMeter.GetCombatSessionsSnapshot then
        local combatSessions = DamageMeter.GetCombatSessionsSnapshot(candidate.challenge)
        if type(combatSessions) == "table" and next(combatSessions) ~= nil then
            candidate.combatSessions = combatSessions
            local pullDeaths, pullGroupDeaths, hasPullDeaths, hasPullGroupDeaths = SumPullDeathMetrics(combatSessions)
            if hasPullDeaths then candidate.metrics.deaths = pullDeaths end
            local officialGroupDeaths = tonumber(candidate.challenge.officialDeathCount or candidate.challenge.deathCount)
            if officialGroupDeaths ~= nil then
                candidate.metrics.groupDeaths = officialGroupDeaths
            elseif hasPullGroupDeaths then
                candidate.metrics.groupDeaths = pullGroupDeaths
            end
        end
    end

    candidate.capture = type(candidate.capture) == "table" and candidate.capture or {}
    candidate.capture.metricsRecovered = true
    candidate.capture.metricsRecoveredAt = now
    return true, candidate
end

function Capture.StartChallenge()
    local captureDB = ResetCaptureDB()
    local context = Sessions.GetChallengeContext()

    if ChallengeTimer and ChallengeTimer.Start then
        context = ChallengeTimer.Start(context)
    end

    local okContext, reason = Sessions.IsAllowedChallengeContext(context)

    captureDB.active = okContext == true
    captureDB.startedAt = time()
    captureDB.startedAtText = date("%Y-%m-%d %H:%M:%S", captureDB.startedAt)
    captureDB.completedSeen = false
    captureDB.interrupted = false
    captureDB.challenge = context
    captureDB.lastStartReason = reason

    captureDB.playerSnapshot = PlayerCapture.GetSnapshot()
    captureDB.talentSnapshot = TalentCapture.GetSnapshot()
    captureDB.statSnapshot = StatCapture.GetSnapshot()
    captureDB.gearSnapshot = GearCapture and GearCapture.GetProfileSnapshot and GearCapture.GetProfileSnapshot() or {}

    if okContext then
        Print("Started tracking " .. tostring(context.dungeonName or context.mapID) .. " +" .. tostring(context.keyLevel))

        if C_Timer and ChallengeTimer and ChallengeTimer.RefineStart then
            C_Timer.After(10, function()
                local activeCapture = EnsureCaptureDB()
                if activeCapture.active == true and activeCapture.completedSeen ~= true and activeCapture.interrupted ~= true then
                    activeCapture.challenge = ChallengeTimer.RefineStart(activeCapture.challenge)
                end
            end)
        end
    else
        Print("Challenge start ignored: " .. tostring(reason))
    end
end

function Capture.MarkCompleted()
    local captureDB = EnsureCaptureDB()

    captureDB.completedSeen = true
    captureDB.interrupted = false
    captureDB.interruptedReason = nil
    captureDB.completedAt = time()
    captureDB.completedAtText = date("%Y-%m-%d %H:%M:%S", captureDB.completedAt)

    local completionContext = Sessions.GetCompletionContext and Sessions.GetCompletionContext(captureDB.challenge) or Sessions.GetChallengeContext()
    if type(completionContext) == "table" then
        captureDB.challenge = captureDB.challenge or {}
        for key, value in pairs(completionContext) do
            if value ~= nil then
                captureDB.challenge[key] = value
            end
        end
    end

    Print("Challenge completion seen. Finalizing shortly.")
end

function Capture.MarkInterrupted(reason)
    local captureDB = EnsureCaptureDB()

    if captureDB.active == true and captureDB.completedSeen ~= true then
        captureDB.interrupted = true
        captureDB.interruptedAt = time()
        captureDB.interruptedAtText = date("%Y-%m-%d %H:%M:%S", captureDB.interruptedAt)
        captureDB.interruptedReason = reason or "unknown"
        Print("Active capture marked interrupted: " .. tostring(captureDB.interruptedReason))
    end
end

function Capture.Finalize(reason)
    local captureDB = EnsureCaptureDB()

    if captureDB.active ~= true and captureDB.completedSeen ~= true then
        return false, "No active/completed capture to finalize"
    end

    local encounter, buildError = BuildEncounterRecord()

    if not encounter then
        captureDB.lastFinalizeError = buildError or "Unknown finalize error"
        captureDB.lastFinalizeReason = reason
        captureDB.lastFinalizeAt = date("%Y-%m-%d %H:%M:%S")
        if captureDB.lastFinalizeError == METRICS_PENDING_REASON then
            Print("Waiting for Blizzard damage meter totals before saving this run.")
        else
            Print("Finalize failed: " .. tostring(captureDB.lastFinalizeError))
        end
        return false, captureDB.lastFinalizeError
    end

    local ok, result
    if KeyLab.DB and KeyLab.DB.Encounters and KeyLab.DB.Encounters.AddEncounter then
        ok, result = KeyLab.DB.Encounters.AddEncounter(encounter)
    else
        if type(KeyLabDB) ~= "table" then KeyLabDB = {} end
        if type(KeyLabDB.encounters) ~= "table" then KeyLabDB.encounters = {} end
        table.insert(KeyLabDB.encounters, encounter)
        ok = true
        result = encounter
    end

    if not ok then
        captureDB.lastFinalizeError = result or "AddEncounter failed"
        Print("Finalize failed: " .. tostring(captureDB.lastFinalizeError))
        return false, captureDB.lastFinalizeError
    end

    ResetCaptureDB()
    Print("Encounter saved. Total encounters: " .. tostring(KeyLab.DB and KeyLab.DB.CountEncounters and KeyLab.DB.CountEncounters() or "?"))

    return true, encounter
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("CHALLENGE_MODE_START")
frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
frame:RegisterEvent("CHALLENGE_MODE_RESET")
frame:RegisterEvent("PLAYER_LOGOUT")

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == ADDON_NAME then
            EnsureCaptureDB()
            if KeyLab.DB and KeyLab.DB.Initialize then
                KeyLab.DB.Initialize()
            end
            if C_Timer and C_Timer.After then
                for _, delaySeconds in ipairs(RECOVERY_RETRY_DELAYS) do
                    local retryDelay = delaySeconds
                    C_Timer.After(retryDelay, function()
                        local repaired, encounter = Capture.RepairLatestIncompleteEncounter()
                        if repaired then
                            Print("Recovered Blizzard damage meter totals for " .. tostring(encounter.challenge and encounter.challenge.dungeonName or "the latest Mythic+ run") .. ".")
                            if KeyLab.UI and KeyLab.UI.RefreshSelectedTab then KeyLab.UI:RefreshSelectedTab() end
                        end
                    end)
                end
            end
        end
        return
    end

    if event == "CHALLENGE_MODE_START" then
        Capture.StartChallenge()
        return
    end

    if event == "CHALLENGE_MODE_COMPLETED" then
        Capture.MarkCompleted()

        for _, delaySeconds in ipairs(FINALIZE_RETRY_DELAYS) do
            local retryDelay = delaySeconds
            C_Timer.After(retryDelay, function()
                local captureDB = EnsureCaptureDB()
                if captureDB.completedSeen == true then
                    Capture.Finalize("CHALLENGE_MODE_COMPLETED + " .. tostring(retryDelay) .. "s")
                end
            end)
        end

        return
    end

    if event == "CHALLENGE_MODE_RESET" then
        Capture.MarkInterrupted("CHALLENGE_MODE_RESET")
        return
    end

    if event == "PLAYER_LOGOUT" then
        Capture.MarkInterrupted("PLAYER_LOGOUT")
        return
    end
end)

SLASH_KEYLABCAPTURE1 = "/keylabcapture"
SlashCmdList["KEYLABCAPTURE"] = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")

    if msg == "count" then
        local count = KeyLab.DB and KeyLab.DB.CountEncounters and KeyLab.DB.CountEncounters() or 0
        Print("Encounter count: " .. tostring(count))
        return
    end

    if msg == "finalize" then
        Capture.Finalize("manual /keylabcapture finalize")
        return
    end

    if msg == "resetcapture" then
        ResetCaptureDB()
        Print("Temporary capture DB reset.")
        return
    end

    if msg == "capturestatus" or msg == "status" then
        local captureDB = EnsureCaptureDB()
        Print(
            "active=" .. tostring(captureDB.active)
            .. " completedSeen=" .. tostring(captureDB.completedSeen)
            .. " interrupted=" .. tostring(captureDB.interrupted)
            .. " lastError=" .. tostring(captureDB.lastFinalizeError)
        )
        return
    end

    Print("Commands: /keylabcapture count, /keylabcapture finalize, /keylabcapture status, /keylabcapture resetcapture")
end
