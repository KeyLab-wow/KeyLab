local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Capture = KeyLab.Capture or {}
KeyLab.Capture.Practice = KeyLab.Capture.Practice or {}

local Practice = KeyLab.Capture.Practice
local pendingStatRepairs = {}

--[[
KeyLab_PracticeCapture.lua

Purpose:
- Coordinates manual training dummy / practice session capture.
- Saves practice records through PracticeDB.
- Reuses existing player/stat/talent/damage meter capture modules.
- Does NOT build UI.
]]

local function DB()
    return KeyLab.DB and KeyLab.DB.Practice or {}
end

local function PlayerCapture()
    return KeyLab.Capture and KeyLab.Capture.Player or {}
end

local function StatCapture()
    return KeyLab.Capture and KeyLab.Capture.Stats or {}
end

local function TalentCapture()
    return KeyLab.Capture and KeyLab.Capture.Talents or {}
end

local function PracticeDamageMeter()
    return KeyLab.Capture and KeyLab.Capture.PracticeDamageMeter or {}
end

local function SequencerLibrary()
    return KeyLab.SequencerLibrary or {}
end

local function Print(message)
    if KeyLab.Utils and KeyLab.Utils.Print then
        KeyLab.Utils.Print(message)
    elseif KeyLab.Print then
        KeyLab.Print(message)
    else
        print("|cffd6b35aKeyLab:|r " .. tostring(message))
    end
end

local function CopyTable(source)
    if type(source) ~= "table" then return source end
    local out = {}
    for key, value in pairs(source) do
        if type(value) == "table" then
            out[key] = CopyTable(value)
        else
            out[key] = value
        end
    end
    return out
end

local function NormalizePracticeRates(metrics, durationSeconds)
    local out = CopyTable(type(metrics) == "table" and metrics or {})
    local duration = tonumber(durationSeconds)
    if not duration or duration <= 0 then return out end

    local damageDone = tonumber(out.damageDone)
    if damageDone ~= nil then out.dps = damageDone / duration end

    local healingDone = tonumber(out.healingDone)
    if healingDone ~= nil then out.hps = healingDone / duration end

    return out
end

local function ReadSpellQueueWindow()
    if type(GetCVar) ~= "function" then return nil end
    local ok, value = pcall(GetCVar, "SpellQueueWindow")
    value = ok and tonumber(value) or nil
    if not value then return nil end
    return math.floor(value + 0.5)
end

local REQUIRED_SECONDARY_STATS = {
    "crit",
    "haste",
    "mastery",
    "versatility",
}

local function ReadStatSnapshot()
    local capture = StatCapture()
    if type(capture.GetSnapshot) ~= "function" then return {} end
    local ok, snapshot = pcall(capture.GetSnapshot)
    return ok and type(snapshot) == "table" and snapshot or {}
end

local function CountRequiredSecondaryStats(stats)
    if type(stats) ~= "table" then return 0 end
    local count = 0
    for _, key in ipairs(REQUIRED_SECONDARY_STATS) do
        if stats[key] ~= nil then count = count + 1 end
    end
    return count
end

local function HasRequiredSecondaryStats(stats)
    return CountRequiredSecondaryStats(stats) == #REQUIRED_SECONDARY_STATS
end

local function MergeMissingStats(primary, fallback)
    local merged = CopyTable(type(primary) == "table" and primary or {})
    for key, value in pairs(type(fallback) == "table" and fallback or {}) do
        if merged[key] == nil then merged[key] = value end
    end
    return merged
end

local function NewPracticeID(startedAt)
    local player = PlayerCapture().GetSnapshot and PlayerCapture().GetSnapshot() or {}
    return table.concat({
        "practice",
        tostring(startedAt or time()),
        tostring(player.playerName or "player"),
    }, "-")
end

local function ReadPracticeSnapshot(baselineSessionIDs, startedAt, stoppedAt)
    local snapshot, errorMessage = nil, nil
    if PracticeDamageMeter().GetPracticeSnapshot then
        local ok, result, err = pcall(PracticeDamageMeter().GetPracticeSnapshot, baselineSessionIDs, startedAt, stoppedAt)
        if ok then
            snapshot, errorMessage = result, err
        else
            errorMessage = tostring(result or "Practice damage meter capture failed.")
        end
    else
        errorMessage = "Practice damage meter capture is unavailable."
    end

    return snapshot, errorMessage
end

local function ReadSequencerUsageSnapshot()
    local library = SequencerLibrary()
    if not library.GetUsageSnapshot then return {} end
    local ok, snapshot = pcall(library.GetUsageSnapshot)
    return ok and type(snapshot) == "table" and snapshot or {}
end

local function DetectSequencerUsages(baseline)
    local library = SequencerLibrary()
    if library.GetUsagesSince then
        local ok, usages = pcall(library.GetUsagesSince, baseline)
        return ok and type(usages) == "table" and usages or {}
    end
    if not library.GetMostUsedSince then return {} end
    local ok, usage = pcall(library.GetMostUsedSince, baseline)
    return ok and type(usage) == "table" and { usage } or {}
end

function Practice.GetActiveSession()
    return DB().GetActive and DB().GetActive() or nil
end

function Practice.IsActive()
    return Practice.GetActiveSession() ~= nil
end

function Practice.StartSession(testType, targetDurationSeconds, sequenceUsage)
    if Practice.IsActive() then
        return false, "A practice session is already running."
    end

    local startedAt = time()
    local baselineSessionIDs = {}
    if PracticeDamageMeter().GetSessionBaseline then
        baselineSessionIDs = PracticeDamageMeter().GetSessionBaseline() or {}
    elseif PracticeDamageMeter().GetAvailableSessionIDMap then
        baselineSessionIDs = PracticeDamageMeter().GetAvailableSessionIDMap() or {}
    end

    targetDurationSeconds = tonumber(targetDurationSeconds)
    if not targetDurationSeconds or targetDurationSeconds <= 0 then
        targetDurationSeconds = nil
    end

    local active = {
        id = NewPracticeID(startedAt),
        startedAt = startedAt,
        startedAtText = date("%Y-%m-%d %H:%M:%S", startedAt),
        testType = testType or "ST",
        targetDurationSeconds = targetDurationSeconds,
        baselineSessionIDs = baselineSessionIDs,
        player = PlayerCapture().GetSnapshot and PlayerCapture().GetSnapshot() or {},
        stats = ReadStatSnapshot(),
        talents = TalentCapture().GetSnapshot and TalentCapture().GetSnapshot() or {},
        spellQueueWindow = ReadSpellQueueWindow(),
        sequenceUsage = type(sequenceUsage) == "table" and CopyTable(sequenceUsage) or nil,
        sequenceUsageAutoDetect = type(sequenceUsage) ~= "table",
        sequencerUsageBaseline = ReadSequencerUsageSnapshot(),
    }

    if DB().SetActive then
        DB().SetActive(active)
    end

    Print("Practice session started.")
    return true, active
end

function Practice.StopSession()
    local active = Practice.GetActiveSession()
    if not active then
        return false, "No practice session is running."
    end

    local stoppedAt = tonumber(active.stoppedAt)
    if not stoppedAt then
        stoppedAt = time()
        active.stoppedAt = stoppedAt
        active.stoppedAtText = date("%Y-%m-%d %H:%M:%S", stoppedAt)
        if DB().SetActive then
            DB().SetActive(active)
        end
    end

    local snapshot, errorMessage = ReadPracticeSnapshot(active.baselineSessionIDs, active.startedAt, stoppedAt)
    local capturePending = snapshot == nil
    local durationSeconds = snapshot and tonumber(snapshot.durationSeconds)
        or math.max(0, stoppedAt - (tonumber(active.startedAt) or stoppedAt))
    local normalizedMetrics = NormalizePracticeRates(snapshot and snapshot.metrics, durationSeconds)
    local sequenceUsage = type(active.sequenceUsage) == "table" and CopyTable(active.sequenceUsage) or nil
    local sequenceUsages = {}
    local sequenceUsageDetection = "manual"
    if type(sequenceUsage) == "table" then
        table.insert(sequenceUsages, CopyTable(sequenceUsage))
    elseif active.sequenceUsageAutoDetect then
        sequenceUsages = DetectSequencerUsages(active.sequencerUsageBaseline)
        sequenceUsage = sequenceUsages[1] and CopyTable(sequenceUsages[1]) or nil
        sequenceUsageDetection = #sequenceUsages > 0 and "automatic" or "none"
    else
        sequenceUsageDetection = "none"
    end
    local sessionStats = CopyTable(active.stats or {})
    if not HasRequiredSecondaryStats(sessionStats) then
        sessionStats = MergeMissingStats(sessionStats, ReadStatSnapshot())
    end
    local session = {
        id = active.id,
        timestamp = active.startedAt,
        dateText = active.startedAtText,
        stoppedAt = stoppedAt,
        stoppedAtText = date("%Y-%m-%d %H:%M:%S", stoppedAt),
        durationSeconds = durationSeconds,
        targetDurationSeconds = tonumber(active.targetDurationSeconds),
        testType = active.testType or "ST",
        player = CopyTable(active.player or {}),
        stats = sessionStats,
        talents = CopyTable(active.talents or {}),
        spellQueueWindow = tonumber(active.spellQueueWindow),
        sequenceUsage = CopyTable(sequenceUsage),
        sequenceUsages = CopyTable(sequenceUsages),
        sequenceUsageDetection = sequenceUsageDetection,
        metrics = normalizedMetrics,
        combatSessions = CopyTable(snapshot and snapshot.combatSessions or {}),
        captureError = false,
        capturePending = capturePending,
        capturePendingReason = capturePending and (errorMessage or "Waiting for Blizzard damage meter totals.") or nil,
        snapshotContext = {
            baselineSessionIDs = CopyTable(active.baselineSessionIDs or {}),
            startedAt = active.startedAt,
            stoppedAt = stoppedAt,
        },
        status = nil,
        source = "practice",
    }

    if DB().AddSession then
        local ok, savedOrError = DB().AddSession(session)
        if not ok then
            return false, savedOrError
        end
    end
    if not HasRequiredSecondaryStats(session.stats) then
        pendingStatRepairs[tostring(session.id)] = stoppedAt + 30
    end

    if DB().ClearActive then
        DB().ClearActive()
    end

    if capturePending then
        Print("Practice session stopped. Damage meter totals will be added when Blizzard releases them.")
    else
        Print("Practice session saved.")
    end
    return true, session
end

function Practice.TryUpdateSessionTotals(sessionID)
    local session = DB().GetByID and DB().GetByID(sessionID)
    if type(session) ~= "table" then
        pendingStatRepairs[tostring(sessionID or "")] = nil
        return false
    end

    local sessionKey = tostring(sessionID or "")
    local statRepairExpiresAt = pendingStatRepairs[sessionKey]
    if statRepairExpiresAt and time() > statRepairExpiresAt then
        pendingStatRepairs[sessionKey] = nil
        statRepairExpiresAt = nil
    end
    local needsDamageTotals = session.capturePending == true
    local needsStats = statRepairExpiresAt ~= nil and not HasRequiredSecondaryStats(session.stats)
    if statRepairExpiresAt and not needsStats then
        pendingStatRepairs[sessionKey] = nil
    end
    if not needsDamageTotals and not needsStats then return false end

    local updates = {}
    if needsStats then
        local beforeCount = CountRequiredSecondaryStats(session.stats)
        local mergedStats = MergeMissingStats(session.stats, ReadStatSnapshot())
        if CountRequiredSecondaryStats(mergedStats) > beforeCount then
            updates.stats = mergedStats
            if HasRequiredSecondaryStats(mergedStats) then
                pendingStatRepairs[sessionKey] = nil
            end
        end
    end

    if needsDamageTotals then
        local context = session.snapshotContext or {}
        local snapshot = ReadPracticeSnapshot(
            context.baselineSessionIDs,
            context.startedAt or session.timestamp,
            context.stoppedAt or session.stoppedAt
        )
        if snapshot then
            local durationSeconds = tonumber(snapshot.durationSeconds) or session.durationSeconds
            local normalizedMetrics = NormalizePracticeRates(snapshot.metrics, durationSeconds)
            updates.metrics = normalizedMetrics
            updates.combatSessions = CopyTable(snapshot.combatSessions or {})
            updates.durationSeconds = durationSeconds
            updates.captureError = false
            updates.capturePending = false
            updates.capturePendingReason = false
        end
    end

    if next(updates) ~= nil and DB().UpdateSession then
        local ok = DB().UpdateSession(sessionID, updates)
        return ok == true
    end

    return false
end

function Practice.RetryPendingSessions()
    if InCombatLockdown and InCombatLockdown() then return false, 0 end
    local sessions = DB().GetAll and DB().GetAll() or {}
    local updated = 0
    for _, session in ipairs(sessions) do
        local sessionID = type(session) == "table" and tostring(session.id or "") or ""
        local needsRetry = type(session) == "table"
            and (session.capturePending or pendingStatRepairs[sessionID])
        if needsRetry and sessionID ~= "" then
            local ok, result = pcall(Practice.TryUpdateSessionTotals, session.id)
            if ok and result == true then updated = updated + 1 end
        end
    end
    if updated > 0 then
        if KeyLab.RefreshTabs then KeyLab.RefreshTabs() end
        if KeyLab.UI and KeyLab.UI.RefreshSelectedTab then KeyLab.UI:RefreshSelectedTab() end
    end
    return updated > 0, updated
end

local function RetryPendingSoon()
    local retry = function() Practice.RetryPendingSessions() end
    if C_Timer and C_Timer.After then
        C_Timer.After(0.5, retry)
    else
        retry()
    end
end

if CreateFrame then
    local pendingMonitor = CreateFrame("Frame")
    for _, eventName in ipairs({ "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD", "DAMAGE_METER_COMBAT_SESSION_UPDATED" }) do
        pcall(pendingMonitor.RegisterEvent, pendingMonitor, eventName)
    end
    pendingMonitor:SetScript("OnEvent", function()
        if not (InCombatLockdown and InCombatLockdown()) then RetryPendingSoon() end
    end)
    Practice.pendingImportMonitor = pendingMonitor
end

return Practice
