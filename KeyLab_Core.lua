local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.addonName = ADDON_NAME

local function GetInstalledAddonVersion()
    local getter = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    if type(getter) == "function" then
        local ok, version = pcall(getter, ADDON_NAME, "Version")
        if ok and type(version) == "string" and version ~= "" then
            return version
        end
    end
    return nil
end

KeyLab.version = GetInstalledAddonVersion() or KeyLab.version or "1.8.60"

KeyLab.UI = KeyLab.UI or {}
KeyLab.Tabs = KeyLab.Tabs or {}
KeyLab.RegisteredTabs = KeyLab.RegisteredTabs or {}

--[[
KeyLab_Core.lua

Purpose:
- Final startup coordinator.
- Initializes the database.
- Provides slash commands.
- Opens/closes the UI.
- Provides tab registration for UI tab files.
- Does NOT capture Blizzard data directly.
- Does NOT build UI cards directly.
]]

function KeyLab.RegisterTab(name, createFunc)
    if not name or not createFunc then return end

    KeyLab.RegisteredTabs = KeyLab.RegisteredTabs or {}

    table.insert(KeyLab.RegisteredTabs, {
        name = name,
        createFunc = createFunc,
    })
end

function KeyLab.Print(message)
    if KeyLab.Utils and KeyLab.Utils.Print then
        KeyLab.Utils.Print(message)
    else
        print("|cffd4af37KeyLab:|r " .. tostring(message))
    end
end

function KeyLab.Debug(message)
    if KeyLabDB and KeyLabDB.settings and KeyLabDB.settings.debugMode == true then
        KeyLab.Print("Debug: " .. tostring(message))
    end
end

function KeyLab.RefreshTabs()
    if KeyLab.UI and KeyLab.UI.RefreshSelectedTab then
        KeyLab.UI:RefreshSelectedTab()
    end
end

local function Print(msg)
    KeyLab.Print(msg)
end

function KeyLab.ResetGearingRuntimeState(preserveMatcherResults)
    if KeyLab.StatGoalMatcher then
        if KeyLab.StatGoalMatcher.Cancel then KeyLab.StatGoalMatcher.Cancel() end
        if not preserveMatcherResults and KeyLab.StatGoalMatcher.ClearAllResults then KeyLab.StatGoalMatcher.ClearAllResults() end
    end
    if KeyLab.GearCapture and KeyLab.GearCapture.MarkAllSlotsChanged then
        KeyLab.GearCapture.MarkAllSlotsChanged()
    end
    if KeyLab.GearingAnalysis and KeyLab.GearingAnalysis.InvalidateCache then
        KeyLab.GearingAnalysis.InvalidateCache()
    end
end

local function RunGearDebug()
    KeyLabDB = KeyLabDB or {}

    local analysis = KeyLab and KeyLab.GearingAnalysis
    if not analysis then
        KeyLabDB.gearDashboardDebugError = "KeyLab.GearingAnalysis is not loaded."
        Print("Gear Dashboard debug is not loaded. Try /reload; if this repeats, send me the Lua error.")
        return
    end

    if type(analysis.PrintGearDebug) ~= "function" then
        KeyLabDB.gearDashboardDebugError = "PrintGearDebug is missing."
        Print("Gear Dashboard debug helper is missing.")
        return
    end

    local ok, err = pcall(analysis.PrintGearDebug)
    if not ok then
        KeyLabDB.gearDashboardDebugError = tostring(err)
        Print("Gear Dashboard debug failed: " .. tostring(err))
    end
end

local function Initialize()
    if KeyLab.DB and KeyLab.DB.Initialize then
        KeyLab.DB.Initialize()
    else
        if type(KeyLabDB) ~= "table" then KeyLabDB = {} end
        KeyLabDB.version = KeyLabDB.version or KeyLab.version
        KeyLabDB.trackingSince = KeyLabDB.trackingSince or date("%B %Y")
        KeyLabDB.settings = KeyLabDB.settings or {}
        KeyLabDB.encounters = KeyLabDB.encounters or {}
        KeyLabDB.raidEncounters = KeyLabDB.raidEncounters or {}
        KeyLabDB.raidNights = KeyLabDB.raidNights or {}
        KeyLabDB.builds = KeyLabDB.builds or {}
        KeyLabDB.lootTargets = KeyLabDB.lootTargets or {}
        KeyLabDB.lootTargetStatuses = KeyLabDB.lootTargetStatuses or {}
        KeyLabDB.gearTargets = KeyLabDB.gearTargets or {}
        KeyLabDB.tierSets = KeyLabDB.tierSets or {}
        KeyLabDB.statGoals = KeyLabDB.statGoals or {}
        KeyLabDB.activityCounts = KeyLabDB.activityCounts or {}
    end

    if KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.MigrateLegacy then
        KeyLab.LootTargetsDB.MigrateLegacy()
    end
    if KeyLab.StatGoalsDB and KeyLab.StatGoalsDB.CleanupLegacy then
        KeyLab.StatGoalsDB.CleanupLegacy()
    end

    if KeyLab.Capture and KeyLab.Capture.Sessions and KeyLab.Capture.Sessions.EnsureCaptureDB then
        KeyLab.Capture.Sessions.EnsureCaptureDB()
    else
        KeyLabCaptureDB = KeyLabCaptureDB or {}
        KeyLabCaptureDB.version = KeyLabCaptureDB.version or KeyLab.version
    end
end

local function ResetAll()
    if KeyLab.SequencerLibrary and KeyLab.SequencerLibrary.PrepareForAddonReset then
        KeyLab.SequencerLibrary.PrepareForAddonReset()
    end
    if KeyLab.SequencerPrototype and KeyLab.SequencerPrototype.PrepareForAddonReset then
        KeyLab.SequencerPrototype.PrepareForAddonReset()
    end

    if KeyLab.DB and KeyLab.DB.ResetAll then
        KeyLab.DB.ResetAll()
    else
        KeyLabDB = {
            version = KeyLab.version or "0.1.4",
            trackingSince = date("%B %Y"),
            settings = { completedMythicPlusOnly = true, contentMode = "mplus" },
            encounters = {},
            raidEncounters = {},
            raidNights = {},
            builds = {},
            lootTargets = {},
            lootTargetStatuses = {},
            gearTargets = {},
            tierSets = {},
            statGoals = {},
            statGoalMatcherResults = {},
            activityCounts = { schemaVersion = 1, characters = {} },
        }
    end

    KeyLab.ResetGearingRuntimeState()

    if KeyLab.Capture and KeyLab.Capture.Sessions and KeyLab.Capture.Sessions.ResetCaptureDB then
        KeyLab.Capture.Sessions.ResetCaptureDB()
    else
        KeyLabCaptureDB = {
            version = KeyLab.version or "0.1.4",
            active = false,
            completedSeen = false,
            interrupted = false,
        }
    end

    KeyLab.RefreshTabs()
    Print("All KeyLab data reset.")
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName == ADDON_NAME then
        Initialize()
        Print("Loaded. Use /keylab to open.")
    end
end)

SLASH_KEYLAB1 = "/keylab"
SlashCmdList["KEYLAB"] = function(msg)
    msg = tostring(msg or "")
    msg = msg:lower()
    msg = msg:gsub("^%s+", "")
    msg = msg:gsub("%s+$", "")

    if msg == "" or msg == "show" or msg == "open" or msg == "toggle" then
        if KeyLab.UI and KeyLab.UI.Toggle then
            KeyLab.UI:Toggle()
        else
            Print("UI is not available.")
        end
        return
    end

    if msg == "hide" or msg == "close" then
        if KeyLab.UI and KeyLab.UI.Hide then
            KeyLab.UI:Hide()
        else
            Print("UI is not available.")
        end
        return
    end

    if msg == "minimap" then
        if KeyLab.Minimap and KeyLab.Minimap.ToggleHidden then
            KeyLab.Minimap.ToggleHidden()
        else
            Print("Minimap icon is not available.")
        end
        return
    end

    if msg == "count" then
        local count = 0

        if KeyLab.DB and KeyLab.DB.CountEncounters then
            count = KeyLab.DB.CountEncounters()
        elseif KeyLabDB and type(KeyLabDB.encounters) == "table" then
            count = #KeyLabDB.encounters
        end

        Print("Encounter count: " .. tostring(count))
        return
    end

    if msg == "status" or msg == "capturestatus" then
        local captureDB = KeyLabCaptureDB or {}

        Print(
            "active=" .. tostring(captureDB.active)
            .. " completedSeen=" .. tostring(captureDB.completedSeen)
            .. " interrupted=" .. tostring(captureDB.interrupted)
            .. " lastError=" .. tostring(captureDB.lastFinalizeError)
        )
        return
    end

    if msg == "finalize" then
        if KeyLab.Capture and KeyLab.Capture.Finalize then
            KeyLab.Capture.Finalize("manual /keylab finalize")
        else
            Print("Capture finalize is not available.")
        end
        return
    end

    if msg == "resetcapture" then
        if KeyLab.Capture and KeyLab.Capture.Sessions and KeyLab.Capture.Sessions.ResetCaptureDB then
            KeyLab.Capture.Sessions.ResetCaptureDB()
            Print("Temporary capture DB reset.")
        else
            KeyLabCaptureDB = {
                version = KeyLab.version or "0.1.4",
                active = false,
                completedSeen = false,
                interrupted = false,
            }
            Print("Temporary capture DB reset.")
        end
        return
    end

    if msg == "reset" then
        ResetAll()
        return
    end

    if msg == "geardebug" or msg == "gear debug" or msg == "gear-debug" then
        RunGearDebug()
        return
    end

    if msg == "raidprobe" or msg == "raid probe" or msg == "raid-probe"
        or msg == "raidprobe on" or msg == "raid probe on" or msg == "raid-probe on"
    then
        if KeyLab.Capture and KeyLab.Capture.Raid and KeyLab.Capture.Raid.SetProbeEnabled then
            KeyLab.Capture.Raid.SetProbeEnabled(true)
        else
            Print("Raid Probe is not available. Try /reload; if this repeats, send me the Lua error.")
        end
        return
    end


    if msg == "raidprobe off" or msg == "raid probe off" or msg == "raid-probe off" then
        if KeyLab.Capture and KeyLab.Capture.Raid and KeyLab.Capture.Raid.SetProbeEnabled then
            KeyLab.Capture.Raid.SetProbeEnabled(false)
        else
            Print("Raid Probe is not available. Try /reload; if this repeats, send me the Lua error.")
        end
        return
    end

    if msg == "raidprobe status" or msg == "raid probe status" or msg == "raid-probe status" then
        local enabled = KeyLab.Capture and KeyLab.Capture.Raid and KeyLab.Capture.Raid.IsProbeEnabled
            and KeyLab.Capture.Raid.IsProbeEnabled()
        Print("Raid Probe is " .. (enabled and "enabled." or "disabled."))
        return
    end

    if msg == "debug" then
        KeyLabDB = KeyLabDB or {}
        KeyLabDB.settings = KeyLabDB.settings or {}
        KeyLabDB.settings.debugMode = not KeyLabDB.settings.debugMode

        Print("Debug mode " .. (KeyLabDB.settings.debugMode and "enabled." or "disabled."))
        return
    end

    Print("Commands: /keylab, /keylab count, /keylab status, /keylab finalize, /keylab resetcapture, /keylab reset, /keylab geardebug, /keylab raidprobe, /keylab debug")
end

SLASH_KEYLABGEARDEBUG1 = "/keylabgeardebug"
SLASH_KEYLABGEARDEBUG2 = "/klgeardebug"
SlashCmdList["KEYLABGEARDEBUG"] = function()
    RunGearDebug()
end
