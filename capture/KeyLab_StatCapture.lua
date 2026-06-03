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

local function StoreStatValue(stats, statKey, value)
    if type(value) == "number" then
        stats[statKey] = value
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
                values = { UnitStat("player", 1) }
            elseif statKey == "agility" and UnitStat then
                values = { UnitStat("player", 2) }
            elseif statKey == "stamina" and UnitStat then
                values = { UnitStat("player", 3) }
            elseif statKey == "intellect" and UnitStat then
                values = { UnitStat("player", 4) }
            elseif statKey == "crit" and GetCritChance then
                values = { GetCritChance() }
            elseif statKey == "haste" and GetHaste then
                values = { GetHaste() }
            elseif statKey == "mastery" and GetMasteryEffect then
                values = { GetMasteryEffect() }
            elseif statKey == "versatility" and GetCombatRatingBonus and CR_VERSATILITY_DAMAGE_DONE then
                values = { GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) }
            elseif statKey == "leech" and GetLifesteal then
                values = { GetLifesteal() }
            elseif statKey == "avoidance" and GetAvoidance then
                values = { GetAvoidance() }
            elseif statKey == "speed" and GetSpeed then
                values = { GetSpeed() }
            elseif statKey == "dodge" and GetDodgeChance then
                values = { GetDodgeChance() }
            elseif statKey == "parry" and GetParryChance then
                values = { GetParryChance() }
            elseif statKey == "block" and GetBlockChance then
                values = { GetBlockChance() }
            elseif statKey == "armor" and UnitArmor then
                values = { UnitArmor("player") }
            end

            local value = PickValue(values, info.resultIndex)
            StoreStatValue(stats, info.keylabKey or statKey, value)
        end
    end

    return stats
end
