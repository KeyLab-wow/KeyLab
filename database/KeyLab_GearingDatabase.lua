-- KeyLab_GearingDatabase.lua
-- Shared slot, track, source-code, and capture metadata for gearing features.

local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.GearingDatabase = KeyLab.GearingDatabase or {}
local GearingDB = KeyLab.GearingDatabase

GearingDB.Season = {
    name = "Midnight Season 1",
    note = "Used for Gear Dashboard display and current-season source guidance.",
}

-- Track IDs are display ordering only. The dashboard does not calculate a score.
GearingDB.Tracks = {
    { id = 0, name = "Unranked" },
    { id = 1, name = "Adventurer" },
    { id = 2, name = "Veteran" },
    { id = 3, name = "Champion" },
    { id = 4, name = "Hero" },
    { id = 5, name = "Myth" },
}

GearingDB.DashboardSlots = {
    left = { "Head", "Neck", "Shoulders", "Back", "Chest", "Wrist", "Main Hand", "Off Hand" },
    right = { "Hands", "Waist", "Legs", "Feet", "Finger 1", "Finger 2", "Trinket 1", "Trinket 2" },
}

GearingDB.DisplaySlotLabels = {
    ["Main Hand"] = "Main Hand",
    ["Off Hand"] = "Off Hand",
}

GearingDB.DungeonCodes = {
    ["Skyreach"] = "SKY",
    ["Algeth'ar Academy"] = "AA",
    ["Pit of Saron"] = "POS",
    ["Windrunner Spire"] = "WS",
    ["Magisters' Terrace"] = "MT",
    ["Nexus-Point Xenas"] = "NPX",
    ["Maisara Caverns"] = "MC",
    ["Seat of the Triumvirate"] = "SEAT",
}

GearingDB.RaidCodes = {
    ["Sporefall"] = "SF",
    ["The Voidspire"] = "VS",
    ["Voidspire"] = "VS",
    ["March on Quel'Danas"] = "MQD",
    ["Dreamrift"] = "DR",
    ["The Dreamrift"] = "DR",
}

GearingDB.TwoHandOrRangedEquipLocs = {
    INVTYPE_2HWEAPON = true,
    INVTYPE_RANGED = true,
    INVTYPE_RANGEDRIGHT = true,
    INVTYPE_THROWN = true,
}

GearingDB.TierSlots = {
    Head = true,
    Shoulders = true,
    Chest = true,
    Hands = true,
    Legs = true,
}

GearingDB.InventorySlots = {
    { name = "Head", slotID = 1 },
    { name = "Neck", slotID = 2 },
    { name = "Shoulders", slotID = 3 },
    { name = "Back", slotID = 15 },
    { name = "Chest", slotID = 5 },
    { name = "Wrist", slotID = 9 },
    { name = "Hands", slotID = 10 },
    { name = "Waist", slotID = 6 },
    { name = "Legs", slotID = 7 },
    { name = "Feet", slotID = 8 },
    { name = "Finger 1", slotID = 11 },
    { name = "Finger 2", slotID = 12 },
    { name = "Trinket 1", slotID = 13 },
    { name = "Trinket 2", slotID = 14 },
    { name = "Main Hand", slotID = 16 },
    { name = "Off Hand", slotID = 17 },
}

-- Gear capture still exposes these raw values for diagnostics and future cards.
GearingDB.GreatVaultSlots = {
    mythicPlus = {
        { slot = 1, required = 1, label = "Complete 1 M+ Dungeon" },
        { slot = 2, required = 4, label = "Complete 4 M+ Dungeons" },
        { slot = 3, required = 8, label = "Complete 8 M+ Dungeons" },
    },
}

GearingDB.CurrencyKeys = {
    championCrests = { type = "currency", id = 3343, label = "Champion Crests" },
    heroCrests = { type = "currency", id = 3345, label = "Hero Crests" },
    mythCrests = { type = "currency", id = 3347, label = "Myth Crests" },
    catalystCharges = { type = "currency", id = 3378, label = "Catalyst" },
    dawnlightManaflux = { type = "currency", id = 3378, label = "Catalyst" },
    nebulousVoidcores = { type = "currency", id = 3418, label = "Voidcore Rolls" },
    nebulousVoidcore = { type = "currency", id = 3418, label = "Voidcore Rolls" },
    radiantSparkDust = { type = "currency", id = 3212, label = "Spark Dust" },
    ascendantVoidcore = { type = "item", id = 268552, label = "Ascendant Voidcore" },
    radiantJewelbinder = { type = "item", id = 263897, label = "Radiant Jewelbinder" },
}

GearingDB.Voidforge = {
    ascendantVoidcoreItemID = 268552,
    craftedWeaponSlotID = 16,
    trinketSlotIDs = { [13] = true, [14] = true },
    eligibleTracks = { Hero = true, Myth = true },
    requiredRank = 6,
    requiredMaxRank = 6,
}

local function CopyEntry(entry)
    if type(entry) ~= "table" then return entry end
    local out = {}
    for key, value in pairs(entry) do out[key] = value end
    return out
end

local function CopyList(list)
    local out = {}
    for _, entry in ipairs(list or {}) do table.insert(out, CopyEntry(entry)) end
    return out
end

function GearingDB.GetDashboardSlots(side)
    return CopyList(GearingDB.DashboardSlots and GearingDB.DashboardSlots[side])
end

function GearingDB.GetDisplaySlotLabel(slotName)
    return (GearingDB.DisplaySlotLabels and GearingDB.DisplaySlotLabels[slotName]) or slotName or "-"
end

function GearingDB.GetTrackByName(trackName)
    for _, track in ipairs(GearingDB.Tracks or {}) do
        if track.name == trackName then return track end
    end
    return nil
end

function GearingDB.GetTrackRank(trackName)
    local track = GearingDB.GetTrackByName(trackName)
    return track and tonumber(track.id) or 0
end

function GearingDB.GetDungeonCode(dungeonName)
    return (GearingDB.DungeonCodes and GearingDB.DungeonCodes[dungeonName]) or dungeonName
end

function GearingDB.GetSourceCode(sourceName, sourceType)
    if sourceType == "Raid" then
        return (GearingDB.RaidCodes and GearingDB.RaidCodes[sourceName]) or sourceName
    end
    return GearingDB.GetDungeonCode(sourceName)
end

function GearingDB.IsTwoHandOrRangedEquipLoc(equipLoc)
    return GearingDB.TwoHandOrRangedEquipLocs and GearingDB.TwoHandOrRangedEquipLocs[equipLoc or ""] == true
end

return GearingDB
