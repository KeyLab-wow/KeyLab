local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Capture = KeyLab.Capture or {}

local Capture = KeyLab.Capture
local Sessions = KeyLab.Capture.Sessions
local DamageMeter = KeyLab.Capture.DamageMeter
local PlayerCapture = KeyLab.Capture.Player
local StatCapture = KeyLab.Capture.Stats
local TalentCapture = KeyLab.Capture.Talents

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
    return Sessions.ResetCaptureDB()
end

local function BuildEncounterRecord()
    local captureDB = EnsureCaptureDB()
    local context = captureDB.challenge or Sessions.GetChallengeContext()

    local okContext, contextReason = Sessions.IsAllowedChallengeContext(context)
    if not okContext then
        return nil, contextReason
    end

    local metrics, metricError = DamageMeter.GetSnapshot()
    if type(metrics) ~= "table" or next(metrics) == nil then
        return nil, metricError or "No mapped local-player metric values found"
    end

    local timestamp = time()

    local encounter = {
        id = Sessions.MakeEncounterID(context),
        timestamp = timestamp,
        dateText = date("%Y-%m-%d %H:%M:%S", timestamp),

        challenge = {
            mapID = context.mapID,
            dungeonName = context.dungeonName,
            keyLevel = context.keyLevel,
            affixIDs = Sessions.CopyArray(context.affixIDs),
        },

        player = captureDB.playerSnapshot or PlayerCapture.GetSnapshot(),
        talents = captureDB.talentSnapshot or TalentCapture.GetSnapshot(),
        stats = captureDB.statSnapshot or StatCapture.GetSnapshot(),
        metrics = metrics,

        flags = {
            interrupted = captureDB.interrupted == true,
            excludedFromComparisons = captureDB.interrupted == true,
        },
    }

    return encounter, nil
end

function Capture.StartChallenge()
    local captureDB = ResetCaptureDB()
    local context = Sessions.GetChallengeContext()
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

    if okContext then
        Print("Started tracking " .. tostring(context.dungeonName or context.mapID) .. " +" .. tostring(context.keyLevel))
    else
        Print("Challenge start ignored: " .. tostring(reason))
    end
end

function Capture.MarkCompleted()
    local captureDB = EnsureCaptureDB()

    captureDB.completedSeen = true
    captureDB.completedAt = time()
    captureDB.completedAtText = date("%Y-%m-%d %H:%M:%S", captureDB.completedAt)

    local completionContext = Sessions.GetChallengeContext()
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
        Print("Finalize failed: " .. tostring(captureDB.lastFinalizeError))
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
        end
        return
    end

    if event == "CHALLENGE_MODE_START" then
        Capture.StartChallenge()
        return
    end

    if event == "CHALLENGE_MODE_COMPLETED" then
        Capture.MarkCompleted()

        C_Timer.After(3, function()
            Capture.Finalize("CHALLENGE_MODE_COMPLETED + 3s")
        end)

        C_Timer.After(8, function()
            local captureDB = EnsureCaptureDB()
            if captureDB.completedSeen == true then
                Capture.Finalize("CHALLENGE_MODE_COMPLETED + 8s retry")
            end
        end)

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
