local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

--[[
KeyLab_JournalData.lua

Purpose:
- Own the protected reset helper for saved KeyLab data.
- Keep the Settings reset button thin.
- Backup guidance lives in Settings. KeyLab does not export or import saved data.
]]

local function Print(message)
    if KeyLab.Print then
        KeyLab.Print(message)
    else
        print("|cffd4af37KeyLab:|r " .. tostring(message))
    end
end

local function EnsureJournalDefaults(db)
    db = type(db) == "table" and db or {}
    db.version = db.version or (KeyLab.version or "0.1.5")
    db.trackingSince = db.trackingSince or (date and date("%B %Y") or "Imported")

    if type(db.settings) ~= "table" then db.settings = {} end
    if db.settings.completedMythicPlusOnly == nil then
        db.settings.completedMythicPlusOnly = true
    end
    if db.settings.contentMode ~= "raid" then db.settings.contentMode = "mplus" end

    if type(db.encounters) ~= "table" then db.encounters = {} end
    if type(db.raidEncounters) ~= "table" then db.raidEncounters = {} end
    if type(db.raidNights) ~= "table" then db.raidNights = {} end
    if type(db.builds) ~= "table" then db.builds = {} end
    if type(db.lootTargets) ~= "table" then db.lootTargets = {} end
    if type(db.lootTargetStatuses) ~= "table" then db.lootTargetStatuses = {} end
    if type(db.gearTargets) ~= "table" then db.gearTargets = {} end
    if type(db.tierSets) ~= "table" then db.tierSets = {} end
    if type(db.statGoals) ~= "table" then db.statGoals = {} end
    if type(db.statGoalMatcherResults) ~= "table" then db.statGoalMatcherResults = {} end
    if type(db.practiceSessions) ~= "table" then db.practiceSessions = {} end
    if type(db.performanceLeaderboards) ~= "table" then db.performanceLeaderboards = {} end
    if type(db.activityCounts) ~= "table" then db.activityCounts = {} end
    db.dataSafety = nil
    db.activePracticeSession = nil

    return db
end

local function ResetCaptureDB()
    if KeyLab.Capture and KeyLab.Capture.Sessions and KeyLab.Capture.Sessions.ResetCaptureDB then
        KeyLab.Capture.Sessions.ResetCaptureDB()
    else
        KeyLabCaptureDB = {
            version = KeyLab.version or "0.1.5",
            active = false,
            completedSeen = false,
            interrupted = false,
        }
    end
end

local function RefreshAllUI()
    if KeyLab.RefreshTabs then
        KeyLab.RefreshTabs()
    end
    if KeyLab.UI and KeyLab.UI.RefreshSelectedTab then
        KeyLab.UI:RefreshSelectedTab()
    end
    if KeyLab.GearTargetsWindow and KeyLab.GearTargetsWindow.RefreshVisible then
        KeyLab.GearTargetsWindow.RefreshVisible()
    end
end

local function ResetGearingRuntimeState(preserveMatcherResults)
    if KeyLab.ResetGearingRuntimeState then
        KeyLab.ResetGearingRuntimeState(preserveMatcherResults)
        return
    end
    if KeyLab.StatGoalMatcher then
        if KeyLab.StatGoalMatcher.Cancel then KeyLab.StatGoalMatcher.Cancel() end
        if not preserveMatcherResults and KeyLab.StatGoalMatcher.ClearAllResults then KeyLab.StatGoalMatcher.ClearAllResults() end
    end
    if KeyLab.GearCapture and KeyLab.GearCapture.MarkAllSlotsChanged then KeyLab.GearCapture.MarkAllSlotsChanged() end
end

local function RaisePopupFrame(frame)
    if not frame then return end

    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(900)

    if frame.SetToplevel then
        frame:SetToplevel(true)
    end

    if frame.Raise then
        frame:Raise()
    end
end

local function ShowRaisedStaticPopup(name)
    local dialog = StaticPopup_Show(name)
    RaisePopupFrame(dialog)
    return dialog
end

local function RegisterResetConfirmPopup()
    if StaticPopupDialogs["KEYLAB_CONFIRM_RESET_JOURNAL_DATA"] then return end

    StaticPopupDialogs["KEYLAB_CONFIRM_RESET_JOURNAL_DATA"] = {
        text = "Permanently delete all saved KeyLab data for every character?\n\nThis includes encounters, Practice sessions, gear plans, settings, Macro Sequences, bindings, and the Recycle Bin. This cannot be undone.",
        button1 = YES,
        button2 = CANCEL,
        OnAccept = function()
            if KeyLab.ResetJournalData then
                KeyLab:ResetJournalData()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = STATICPOPUP_NUMDIALOGS,
    }
end

function KeyLab:ResetJournalData()
    if InCombatLockdown and InCombatLockdown() then
        Print("KeyLab data cannot be reset during combat.")
        return false
    end

    if KeyLab.SequencerLibrary and KeyLab.SequencerLibrary.PrepareForAddonReset then
        local prepared = KeyLab.SequencerLibrary.PrepareForAddonReset()
        if prepared == false then
            Print("KeyLab could not safely clear Macro Sequence bindings. Please try again outside combat.")
            return false
        end
    end

    if KeyLab.DB and KeyLab.DB.ResetAll then
        KeyLab.DB.ResetAll()
    else
        KeyLabDB = EnsureJournalDefaults({})
    end

    ResetGearingRuntimeState()
    ResetCaptureDB()
    RefreshAllUI()
    Print("All KeyLab data reset.")
    return true
end

function KeyLab:ShowResetJournalDataConfirmation()
    RegisterResetConfirmPopup()
    ShowRaisedStaticPopup("KEYLAB_CONFIRM_RESET_JOURNAL_DATA")
end

function KeyLab:RefreshSettingsTab()
    RefreshAllUI()
end

RegisterResetConfirmPopup()
