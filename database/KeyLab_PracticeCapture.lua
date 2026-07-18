local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Capture = KeyLab.Capture or {}
KeyLab.Capture.Practice = KeyLab.Capture.Practice or {}

local Practice = KeyLab.Capture.Practice

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

function Practice.GetActiveSession()
    return DB().GetActive and DB().GetActive() or nil
end

function Practice.IsActive()
    return Practice.GetActiveSession() ~= nil
end

function Practice.StartSession(testType, targetDurationSeconds)
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
        stats = StatCapture().GetSnapshot and StatCapture().GetSnapshot() or {},
        talents = TalentCapture().GetSnapshot and TalentCapture().GetSnapshot() or {},
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
        stats = CopyTable(active.stats or {}),
        talents = CopyTable(active.talents or {}),
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
    if type(session) ~= "table" or not session.capturePending then
        return false
    end

    local context = session.snapshotContext or {}
    local snapshot = nil
    snapshot = ReadPracticeSnapshot(context.baselineSessionIDs, context.startedAt or session.timestamp, context.stoppedAt or session.stoppedAt)

    if not snapshot then
        return false
    end

    if DB().UpdateSession then
        local durationSeconds = tonumber(snapshot.durationSeconds) or session.durationSeconds
        local normalizedMetrics = NormalizePracticeRates(snapshot.metrics, durationSeconds)
        local ok = DB().UpdateSession(sessionID, {
            metrics = normalizedMetrics,
            combatSessions = CopyTable(snapshot.combatSessions or {}),
            durationSeconds = durationSeconds,
            captureError = false,
            capturePending = false,
            capturePendingReason = false,
        })
        return ok == true
    end

    return false
end

function Practice.RetryPendingSessions()
    if InCombatLockdown and InCombatLockdown() then return false, 0 end
    local sessions = DB().GetAll and DB().GetAll() or {}
    local updated = 0
    for _, session in ipairs(sessions) do
        if type(session) == "table" and session.capturePending and session.id then
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
