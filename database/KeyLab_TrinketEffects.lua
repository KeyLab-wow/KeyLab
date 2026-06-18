local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

-- Known trinket effect tags for loot rows where saved item stats only carry
-- passive primary stats. Live tooltip keyword detection in KeyLab_ItemAnalysis
-- still runs first; this table keeps known item effects visible when tooltip
-- data is not loaded yet or is too sparse.
KeyLab.TrinketEffectsDB = KeyLab.TrinketEffectsDB or {}
local TrinketEffectsDB = KeyLab.TrinketEffectsDB

local EFFECTS_BY_ITEM_ID = {
    [50259] = { tags = { "Crit" }, note = "Nevermelting Ice Crystal" },
    [151307] = { tags = { "Damage" }, note = "Void Stalker's Contract" },
    [151310] = { tags = { "Damage" }, note = "Reality Breacher" },
    [151312] = { tags = { "Absorb", "Defensive" }, note = "Ampoule of Pure Void" },
    [151340] = { tags = { "Healing" }, note = "Echo of L'ura" },
    [193701] = { tags = { "Mastery" }, note = "Algeth'ar Puzzle Box" },
    [193718] = { tags = { "Healing" }, note = "Emerald Coach's Whistle" },
    [193719] = { tags = { "Damage" }, note = "Dragon Games Equipment" },
    [250144] = { tags = { "Damage" }, note = "Emberwing Feather" },
    [250223] = { tags = { "Damage" }, note = "Soulcatcher's Charm" },
    [250226] = { tags = { "Damage" }, note = "Latch's Crooked Hook" },
    [250227] = { tags = { "Damage" }, note = "Kroluk's Warbanner" },
    [250241] = { tags = { "Damage" }, note = "Mark of Light" },
    [250242] = { tags = { "Absorb", "Defensive" }, note = "Jelly Replicator" },
    [250246] = { tags = { "Healing" }, note = "Refueling Orb" },
    [250253] = { tags = { "Healing" }, note = "Whisper of the Duskwraith" },
    [250256] = { tags = { "Haste", "Damage" }, note = "Heart of Wind" },
    [250257] = { tags = { "Damage" }, note = "Eye of the Drowning Void" },
    [250258] = { tags = { "Damage" }, note = "Vessel of Tortured Souls" },
    [252411] = { tags = { "Healing" }, note = "Radiant Sunstone" },
    [252418] = { tags = { "Damage" }, note = "Solar Core Igniter" },
    [252420] = { tags = { "Damage" }, note = "Solarflare Prism" },
    [252421] = { tags = { "Damage" }, note = "Rotting Globule" },
}

local function CopyTags(tags)
    local out = {}
    for _, tag in ipairs(tags or {}) do
        table.insert(out, tag)
    end
    return out
end

function TrinketEffectsDB.GetTags(itemID)
    itemID = tonumber(itemID)
    local data = itemID and EFFECTS_BY_ITEM_ID[itemID] or nil
    return data and CopyTags(data.tags) or {}
end

function TrinketEffectsDB.GetEffectInfo(itemID)
    itemID = tonumber(itemID)
    return itemID and EFFECTS_BY_ITEM_ID[itemID] or nil
end

return TrinketEffectsDB
