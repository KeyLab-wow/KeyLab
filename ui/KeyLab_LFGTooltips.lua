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

local hooked = false
local panelHooked = false

local function ShowShoppingList()
    if not KeyLab.GearTargetsWindow or not KeyLab.GearTargetsWindow.ShowForLFG then return end
    -- The popup is now a complete saved shopping list. It no longer tries to
    -- infer a result ID or hovered dungeon from Blizzard's LFG arguments.
    KeyLab.GearTargetsWindow.ShowForLFG()
end

local function HookFunction(functionName)
    if type(_G[functionName]) ~= "function" then return false end
    hooksecurefunc(functionName, ShowShoppingList)
    return true
end

local function HookSearchPanel()
    if panelHooked then return end
    local searchPanel = _G.LFGListSearchPanel
        or (_G.LFGListFrame and _G.LFGListFrame.SearchPanel)
    if searchPanel and searchPanel.HookScript then
        searchPanel:HookScript("OnShow", ShowShoppingList)
        panelHooked = true
    end
end

local function HookLFGFrameHide()
    local lfgFrame = _G.LFGListFrame or _G.PVEFrame
    if lfgFrame and lfgFrame.HookScript then
        lfgFrame:HookScript("OnHide", function()
            if KeyLab.GearTargetsWindow and KeyLab.GearTargetsWindow.HideAuto then
                KeyLab.GearTargetsWindow.HideAuto()
            end
        end)
    end
end

function LFGTooltips.InstallHooks()
    if hooked then return end
    local didHook = false
    didHook = HookFunction("LFGListUtil_SetSearchEntryTooltip") or didHook
    didHook = HookFunction("LFGListSearchEntry_OnEnter") or didHook
    didHook = HookFunction("LFGListSearchPanel_UpdateResultList") or didHook
    HookSearchPanel()
    HookLFGFrameHide()
    if didHook then hooked = true end
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
