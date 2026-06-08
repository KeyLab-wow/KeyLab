local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Utils = KeyLab.Utils or {}

local Utils = KeyLab.Utils

--[[
KeyLab_Utils.lua

Purpose:
- Shared safe helper functions.
- No capture logic.
- No UI creation.
- No DB structure decisions.
]]

function Utils.SafeNumber(value)
    local ok, result = pcall(function()
        local n = tonumber(value)
        if type(n) ~= "number" then
            return nil
        end

        -- Some live player stat APIs can briefly return protected "secret"
        -- numbers after talent/loadout changes. Any comparison against those
        -- values errors, so verify the number is usable before callers sort or
        -- format it.
        local copy = n + 0
        if copy ~= copy then
            return nil
        end

        if not (copy < math.huge and copy > -math.huge) then
            return nil
        end

        return copy
    end)

    if ok and type(result) == "number" then
        return result
    end

    return nil
end

function Utils.SafeText(value)
    if value == nil then
        return nil
    end

    local ok, result = pcall(function()
        return tostring(value)
    end)

    if ok then
        return result
    end

    return nil
end

function Utils.Round(value, digits)
    local n = Utils.SafeNumber(value)
    if not n then return nil end

    local mult = 10 ^ (digits or 0)
    return math.floor(n * mult + 0.5) / mult
end

function Utils.FormatDateTime(ts)
    ts = ts or time()
    return date("%Y-%m-%d %H:%M:%S", ts)
end

function Utils.EnsureTable(parent, key)
    if type(parent) ~= "table" then
        return nil
    end

    if type(parent[key]) ~= "table" then
        parent[key] = {}
    end

    return parent[key]
end

function Utils.ShallowCopy(source)
    local copy = {}

    if type(source) ~= "table" then
        return copy
    end

    for key, value in pairs(source) do
        copy[key] = value
    end

    return copy
end

function Utils.CopyArray(source)
    local copy = {}

    if type(source) ~= "table" then
        return copy
    end

    for i, value in ipairs(source) do
        copy[i] = value
    end

    return copy
end

function Utils.CountTable(tbl)
    if type(tbl) ~= "table" then
        return 0
    end

    local count = 0

    for _ in pairs(tbl) do
        count = count + 1
    end

    return count
end

function Utils.MakeEncounterID(context)
    context = context or {}

    local timestamp = context.timestamp or time()
    local mapID = context.mapID or 0
    local keyLevel = context.keyLevel or 0
    local player = context.playerName or UnitName("player") or "player"

    return string.format(
        "%s-%s-%s-%s",
        date("%Y%m%d%H%M%S", timestamp),
        tostring(mapID),
        tostring(keyLevel),
        tostring(player)
    )
end

function Utils.DebugPrint(...)
    if KeyLabDB and KeyLabDB.settings and KeyLabDB.settings.debugMode == true then
        print("|cffd6b35aKeyLab:|r", ...)
    end
end

function Utils.Print(...)
    print("|cffd6b35aKeyLab:|r", ...)
end
