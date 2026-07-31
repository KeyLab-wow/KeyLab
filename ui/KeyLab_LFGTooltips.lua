local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.LFGTooltips = KeyLab.LFGTooltips or {}
local LFGTooltips = KeyLab.LFGTooltips

--[[
KeyLab_LFGTooltips.lua

Purpose:
- Opens/updates the KeyLab Gear Targets window while browsing Premade Group dungeon and raid listings.
- Does not create a competing GameTooltip.
]]

local hookedFunctions = {}
local panelHooked = false
local rootHooked = false
local groupFinderSessionActive = false
local dismissedForCurrentSession = false

local function IsAutoShowEnabled()
    if KeyLab.DB and KeyLab.DB.GetSetting then
        return KeyLab.DB.GetSetting("autoShowGroupFinderHelper", true) ~= false
    end
    return not (KeyLabDB and KeyLabDB.settings
        and KeyLabDB.settings.autoShowGroupFinderHelper == false)
end

local function BeginGroupFinderSession()
    if groupFinderSessionActive then return end
    groupFinderSessionActive = true
    dismissedForCurrentSession = false
end

local function EndGroupFinderSession()
    groupFinderSessionActive = false
    dismissedForCurrentSession = false
    if KeyLab.GearTargetsWindow and KeyLab.GearTargetsWindow.HideAuto then
        KeyLab.GearTargetsWindow.HideAuto()
    end
end

local function ShowShoppingList()
    if not IsAutoShowEnabled() or dismissedForCurrentSession then return end
    BeginGroupFinderSession()
    if not KeyLab.GearTargetsWindow or not KeyLab.GearTargetsWindow.ShowForLFG then return end
    -- The popup is now a complete saved shopping list. It no longer tries to
    -- infer a result ID or hovered dungeon from Blizzard's LFG arguments.
    KeyLab.GearTargetsWindow.ShowForLFG()
end

local function HookFunction(functionName)
    if hookedFunctions[functionName] then return true end
    if type(_G[functionName]) ~= "function" then return false end
    hooksecurefunc(functionName, ShowShoppingList)
    hookedFunctions[functionName] = true
    return true
end

local function HookSearchPanel()
    if panelHooked then return end
    local searchPanel = _G.LFGListSearchPanel
        or (_G.LFGListFrame and _G.LFGListFrame.SearchPanel)
    if searchPanel and searchPanel.HookScript then
        searchPanel:HookScript("OnShow", function()
            BeginGroupFinderSession()
            ShowShoppingList()
        end)
        panelHooked = true
    end
end

local function HookLFGFrameSession()
    if rootHooked then return end
    local lfgFrame = _G.PVEFrame or _G.LFGListFrame
    if lfgFrame and lfgFrame.HookScript then
        lfgFrame:HookScript("OnShow", BeginGroupFinderSession)
        lfgFrame:HookScript("OnHide", EndGroupFinderSession)
        rootHooked = true
    end
end

function LFGTooltips.IsAutoShowEnabled()
    return IsAutoShowEnabled()
end

function LFGTooltips.IsGroupFinderSessionActive()
    return groupFinderSessionActive
end

function LFGTooltips.DismissForCurrentSession()
    if groupFinderSessionActive then
        dismissedForCurrentSession = true
    end
end

function LFGTooltips.SetAutoShowEnabled(enabled)
    enabled = enabled ~= false
    if KeyLab.DB and KeyLab.DB.SetSetting then
        KeyLab.DB.SetSetting("autoShowGroupFinderHelper", enabled)
    else
        KeyLabDB = type(KeyLabDB) == "table" and KeyLabDB or {}
        KeyLabDB.settings = type(KeyLabDB.settings) == "table" and KeyLabDB.settings or {}
        KeyLabDB.settings.autoShowGroupFinderHelper = enabled
    end

    if not enabled then
        if KeyLab.GearTargetsWindow and KeyLab.GearTargetsWindow.HideAuto then
            KeyLab.GearTargetsWindow.HideAuto()
        end
    elseif groupFinderSessionActive and not dismissedForCurrentSession then
        ShowShoppingList()
    end
    return enabled
end

function LFGTooltips.OpenManual()
    if KeyLab.GearTargetsWindow and KeyLab.GearTargetsWindow.ShowManual then
        KeyLab.GearTargetsWindow.ShowManual()
        return true
    end
    return false
end

function LFGTooltips.InstallHooks()
    HookFunction("LFGListUtil_SetSearchEntryTooltip")
    HookFunction("LFGListSearchEntry_OnEnter")
    HookFunction("LFGListSearchPanel_UpdateResultList")
    HookSearchPanel()
    HookLFGFrameSession()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "PLAYER_LOGIN" or addonName == "Blizzard_GroupFinder" then
        LFGTooltips.InstallHooks()
    end
end)

LFGTooltips.InstallHooks()
