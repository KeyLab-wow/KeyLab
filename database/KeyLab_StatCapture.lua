local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Capture = KeyLab.Capture or {}
KeyLab.Capture.Stats = KeyLab.Capture.Stats or {}

local StatCapture = KeyLab.Capture.Stats

--[[
KeyLab_StatCapture.lua

Purpose:
- Captures approved stats only, based on KeyLab_StatMapping.lua.
- Stores raw selected Blizzard values.
- Does NOT round, format, or convert percentages.
]]

local function PickValue(values, resultIndex)
    if type(values) ~= "table" then
        return nil
    end

    return values[resultIndex or 1]
end

local function SafeNumber(value)
    if KeyLab.Utils and KeyLab.Utils.SafeNumber then
        return KeyLab.Utils.SafeNumber(value)
    end

    local ok, result = pcall(function()
        local n = tonumber(value)
        if type(n) ~= "number" then return nil end
        local copy = n + 0
        if copy ~= copy then return nil end
        if not (copy < math.huge and copy > -math.huge) then return nil end
        return copy
    end)

    if ok and type(result) == "number" then
        return result
    end

    return nil
end

local function CaptureValues(fn, ...)
    if type(fn) ~= "function" then
        return nil
    end

    local ok, a, b, c, d = pcall(fn, ...)
    if not ok then
        return nil
    end

    return { a, b, c, d }
end

local function StoreStatValue(stats, statKey, value)
    local safeValue = SafeNumber(value)
    if safeValue ~= nil then
        stats[statKey] = safeValue
    end
end

function StatCapture.GetSnapshot()
    local stats = {}

    local mapping = KeyLab.Mapping and KeyLab.Mapping.Stats
    local order = KeyLab.Mapping and KeyLab.Mapping.StatOrder

    if type(mapping) ~= "table" or type(order) ~= "table" then
        return stats
    end

    for _, statKey in ipairs(order) do
        local info = mapping[statKey]

        if info and info.store == true then
            local values = nil

            if statKey == "strength" and UnitStat then
                values = CaptureValues(UnitStat, "player", 1)
            elseif statKey == "agility" and UnitStat then
                values = CaptureValues(UnitStat, "player", 2)
            elseif statKey == "stamina" and UnitStat then
                values = CaptureValues(UnitStat, "player", 3)
            elseif statKey == "intellect" and UnitStat then
                values = CaptureValues(UnitStat, "player", 4)
            elseif statKey == "crit" and GetCritChance then
                values = CaptureValues(GetCritChance)
            elseif statKey == "haste" and GetHaste then
                values = CaptureValues(GetHaste)
            elseif statKey == "mastery" and GetMasteryEffect then
                values = CaptureValues(GetMasteryEffect)
            elseif statKey == "versatility" and GetCombatRatingBonus and CR_VERSATILITY_DAMAGE_DONE then
                values = CaptureValues(GetCombatRatingBonus, CR_VERSATILITY_DAMAGE_DONE)
            elseif statKey == "leech" and GetLifesteal then
                values = CaptureValues(GetLifesteal)
            elseif statKey == "avoidance" and GetAvoidance then
                values = CaptureValues(GetAvoidance)
            elseif statKey == "speed" and GetSpeed then
                values = CaptureValues(GetSpeed)
            elseif statKey == "dodge" and GetDodgeChance then
                values = CaptureValues(GetDodgeChance)
            elseif statKey == "parry" and GetParryChance then
                values = CaptureValues(GetParryChance)
            elseif statKey == "block" and GetBlockChance then
                values = CaptureValues(GetBlockChance)
            elseif statKey == "armor" and UnitArmor then
                values = CaptureValues(UnitArmor, "player")
            end

            local value = PickValue(values, info.resultIndex)
            StoreStatValue(stats, info.keylabKey or statKey, value)
        end
    end

    return stats
end
