local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Capture = KeyLab.Capture or {}
KeyLab.Capture.Talents = KeyLab.Capture.Talents or {}

local TalentCapture = KeyLab.Capture.Talents

--[[
KeyLab_TalentCapture.lua

Purpose:
- Captures active talent import string.
- Stores exact string unchanged.
]]

local function SafeCall(func, ...)
    if type(func) ~= "function" then
        return false, nil
    end

    local ok, a = pcall(func, ...)
    if not ok then
        return false, tostring(a)
    end

    return true, a
end

function TalentCapture.GetSnapshot()
    local talentString = nil

    if C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_Traits and C_Traits.GenerateImportString then
        local okConfig, configID = SafeCall(C_ClassTalents.GetActiveConfigID)
        if okConfig and configID then
            local okString, importString = SafeCall(C_Traits.GenerateImportString, configID)
            if okString and type(importString) == "string" then
                talentString = importString
            end
        end
    end

    return {
        talentString = talentString,
    }
end
