local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.LFGTooltips = KeyLab.LFGTooltips or {}
local LFGTooltips = KeyLab.LFGTooltips

--[[
KeyLab_LFGTooltips.lua

Purpose:
- Opens/updates the KeyLab Gear Targets window while browsing Premade Group dungeon listings.
- Does not create a competing GameTooltip.
]]

local hooked = false

local function NormalizeName(value)
    value = tostring(value or "")
    value = value:gsub("[%p%c%s]+", "")
    return string.lower(value)
end

local function AddName(list, seen, value)
    if type(value) ~= "string" or value == "" then return end
    local key = NormalizeName(value)
    if key == "" or seen[key] then return end
    seen[key] = true
    table.insert(list, value)
end

local function ReadTooltipText()
    local parts = {}
    if not GameTooltip or not GameTooltip.GetName then return parts end
    local tooltipName = GameTooltip:GetName()
    if not tooltipName then return parts end
    for i = 1, GameTooltip:NumLines() do
        local left = _G[tooltipName .. "TextLeft" .. i]
        local right = _G[tooltipName .. "TextRight" .. i]
        if left and left.GetText then AddName(parts, {}, left:GetText()) end
        if right and right.GetText then AddName(parts, {}, right:GetText()) end
    end
    return parts
end

local function GetActivityNames(activityID, names, seen)
    if not activityID then return end
    if C_LFGList and C_LFGList.GetActivityInfoTable then
        local activityInfo = C_LFGList.GetActivityInfoTable(activityID)
        if type(activityInfo) == "table" then
            AddName(names, seen, activityInfo.fullName)
            AddName(names, seen, activityInfo.shortName)
            AddName(names, seen, activityInfo.name)
        end
    end
    if C_LFGList and C_LFGList.GetActivityInfo then
        local ok, id, fullName, shortName = pcall(C_LFGList.GetActivityInfo, activityID)
        if ok then
            AddName(names, seen, fullName)
            AddName(names, seen, shortName)
            AddName(names, seen, id)
        end
    end
end

local function GetResultDungeonNames(resultID)
    local names, seen = {}, {}
    if C_LFGList and C_LFGList.GetSearchResultInfo and resultID then
        local ok, info = pcall(C_LFGList.GetSearchResultInfo, resultID)
        if ok and type(info) == "table" then
            AddName(names, seen, info.name)
            if type(info.activityIDs) == "table" then
                for _, activityID in ipairs(info.activityIDs) do
                    GetActivityNames(activityID, names, seen)
                end
            end
            GetActivityNames(info.activityID, names, seen)
        end
    end
    for _, text in ipairs(ReadTooltipText()) do AddName(names, seen, text) end
    return names
end

local function ResultIDFromArgs(...)
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if type(value) == "number" then
            return value
        elseif type(value) == "table" then
            if type(value.resultID) == "number" then return value.resultID end
            if value.GetParent then
                local parent = value:GetParent()
                if parent and type(parent.resultID) == "number" then return parent.resultID end
            end
        end
    end
    return nil
end

local function ShowForResultID(resultID)
    if not resultID or not KeyLab.GearTargetsWindow or not KeyLab.GearTargetsWindow.ShowForLFG then return end
    local names = GetResultDungeonNames(resultID)
    if #names > 0 then
        KeyLab.GearTargetsWindow.ShowForLFG(names)
    end
end

local function HookFunction(functionName)
    if type(_G[functionName]) ~= "function" then return false end
    hooksecurefunc(functionName, function(...)
        local resultID = ResultIDFromArgs(...)
        if resultID then ShowForResultID(resultID) end
    end)
    return true
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
