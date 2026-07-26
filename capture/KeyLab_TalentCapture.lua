local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Capture = KeyLab.Capture or {}
KeyLab.Capture.Talents = KeyLab.Capture.Talents or {}

local TalentCapture = KeyLab.Capture.Talents

--[[
KeyLab_TalentCapture.lua

Purpose:
- Captures the active talent import string and the player's loadout name.
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

local function CleanLoadoutName(value)
    if type(value) ~= "string" then return nil end
    local cleaned = value:match("^%s*(.-)%s*$")
    return cleaned ~= "" and cleaned or nil
end

local function GetCurrentSpecIdentity()
    local specIndex = GetSpecialization and GetSpecialization()
    if specIndex and GetSpecializationInfo then
        local specID, specName = GetSpecializationInfo(specIndex)
        return specID, CleanLoadoutName(specName)
    end
    return nil, nil
end

local function IsPlayerLoadoutName(loadoutName, specName)
    loadoutName = CleanLoadoutName(loadoutName)
    if not loadoutName then return false end
    if specName and loadoutName:lower() == specName:lower() then
        return false
    end
    return true
end

local function GetConfigSnapshot(configID)
    if not configID then return nil, nil end

    local talentString
    if C_Traits and C_Traits.GenerateImportString then
        local okString, importString = SafeCall(C_Traits.GenerateImportString, configID)
        if okString and type(importString) == "string" and importString ~= "" then
            talentString = importString
        end
    end

    local loadoutName
    if C_Traits and C_Traits.GetConfigInfo then
        local okInfo, configInfo = SafeCall(C_Traits.GetConfigInfo, configID)
        if okInfo and type(configInfo) == "table" then
            loadoutName = CleanLoadoutName(configInfo.name)
        end
    end

    return talentString, loadoutName
end

function TalentCapture.GetSnapshot()
    local talentString = nil
    local loadoutName = nil
    local configID = nil

    if C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_Traits and C_Traits.GenerateImportString then
        local okConfig, activeConfigID = SafeCall(C_ClassTalents.GetActiveConfigID)
        if okConfig and activeConfigID then
            configID = activeConfigID
            talentString, loadoutName = GetConfigSnapshot(configID)
        end
    end

    local _, specName = GetCurrentSpecIdentity()
    if not IsPlayerLoadoutName(loadoutName, specName) then
        loadoutName = nil
    end

    return {
        talentString = talentString,
        loadoutName = loadoutName,
        configID = configID,
    }
end

function TalentCapture.GetLoadoutNameMap()
    local namesByTalentString = {}
    if not (C_ClassTalents and C_ClassTalents.GetConfigIDsBySpecID) then
        return namesByTalentString
    end

    local specID, specName = GetCurrentSpecIdentity()
    if not specID then return namesByTalentString end

    local okConfigs, configIDs = SafeCall(C_ClassTalents.GetConfigIDsBySpecID, specID)
    if okConfigs and type(configIDs) == "table" then
        for _, savedConfigID in ipairs(configIDs) do
            local talentString, loadoutName = GetConfigSnapshot(savedConfigID)
            if talentString
                and IsPlayerLoadoutName(loadoutName, specName)
                and not namesByTalentString[talentString]
            then
                namesByTalentString[talentString] = loadoutName
            end
        end
    end

    local active = TalentCapture.GetSnapshot()
    if active.talentString and active.loadoutName then
        namesByTalentString[active.talentString] = active.loadoutName
    end

    return namesByTalentString
end
