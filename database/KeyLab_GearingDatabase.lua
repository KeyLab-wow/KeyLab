-- KeyLab_GearingDatabase.lua
-- Shared slot, track, source-code, and capture metadata for gearing features.

local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.GearingDatabase = KeyLab.GearingDatabase or {}
local GearingDB = KeyLab.GearingDatabase

GearingDB.Season = {
    name = "Midnight Season 2",
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

-- Season 2 upgrade-track boundaries. Analysis features use these values when
-- projecting an owned item to the maximum rank of its current track.
GearingDB.TrackItemLevels = {
    Adventurer = { minimum = 266, maximum = 276 },
    Veteran = { minimum = 279, maximum = 289 },
    Champion = { minimum = 292, maximum = 302 },
    Hero = { minimum = 305, maximum = 315 },
    Myth = { minimum = 318, maximum = 344 },
}

GearingDB.MythicPlusRewards = {
    directDrops = {
        [0] = 292,
        [2] = 295, [3] = 295,
        [4] = 298,
        [5] = 302,
        [6] = 305, [7] = 305,
        [8] = 308, [9] = 308,
        [10] = 311,
    },
    greatVault = {
        [2] = 305, [3] = 305,
        [4] = 308, [5] = 308,
        [6] = 311,
        [7] = 315, [8] = 315, [9] = 315,
        [10] = 318,
    },
    directDropMinimumTrack = "Champion",
    directDropMaximumTrack = "Hero",
    mythTrackFromGreatVaultOnly = true,
}

GearingDB.RaidRewards = {
    trackStarts = { Champion = 292, Hero = 305, Myth = 318 },
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
    ["Altar of Fangs"] = "AOF",
    ["Murder Row"] = "MR",
    ["Den of Nalorakk"] = "DON",
    ["The Blinding Vale"] = "TBV",
    ["Voidscar Arena"] = "VSA",
    ["Kings' Rest"] = "KR",
    ["King's Rest"] = "KR",
    ["Ruby Life Pools"] = "RLP",
    ["Temple of Sethraliss"] = "TOS",
}

GearingDB.RaidCodes = {
    ["The Venomous Abyss"] = "VA",
    ["Venomous Abyss"] = "VA",
    ["The Tidebound Grotto"] = "TG",
    ["Tidebound Grotto"] = "TG",
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

-- All armor positions that can be converted at the Catalyst. Only the five
-- TierSlots above can count toward the 2-piece and 4-piece set bonuses.
GearingDB.CatalystSlots = {
    Head = true,
    Shoulders = true,
    Back = true,
    Chest = true,
    Wrist = true,
    Hands = true,
    Waist = true,
    Legs = true,
    Feet = true,
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
    adventurerCrests = { type = "currency", id = 3442, label = "Adventurer Mistcrest" },
    veteranCrests = { type = "currency", id = 3443, label = "Veteran Mistcrest" },
    championCrests = { type = "currency", id = 3444, label = "Champion Mistcrest" },
    heroCrests = { type = "currency", id = 3445, label = "Hero Mistcrest" },
    mythCrests = { type = "currency", id = 3446, label = "Myth Mistcrest" },
    catalystCharges = { type = "currency", id = 3465, label = "Venomblight Manaflux" },
    venomblightManaflux = { type = "currency", id = 3465, label = "Venomblight Manaflux" },
    nebulousVoidcores = { type = "currency", id = 3418, label = "Nebulous Voidcores" },
    nebulousVoidcore = { type = "currency", id = 3418, label = "Nebulous Voidcores" },
    sparkOfTides = { type = "item", id = 274476, label = "Spark of Tides" },
    ascendantVenomstone = { type = "item", id = nil, label = "Ascendant Venomstone", pending = true },
    radiantJewelbinder = { type = "item", id = 263897, label = "Radiant Jewelbinder" },
}

GearingDB.Voidforge = {
    ascendantItemName = "Ascendant Venomstone",
    -- Add ascendantItemID after Blizzard releases the Season 2 item ID.
    ascendantItemID = nil,
    weaponSlotIDs = { [16] = true },
    trinketSlotIDs = { [13] = true, [14] = true },
    eligibleTracks = { Hero = true, Myth = true },
    baseMaxItemLevel = { Hero = 315, Myth = 344 },
    requiredRank = 6,
    requiredMaxRank = 6,
}

-- Mythic Venomous Abyss items in these lists cannot be upgraded. The same
-- Venomcursed item IDs remain upgradeable when they drop on LFR, Normal, or
-- Heroic tracks, so the item-level fallback begins at the Myth track floor.
GearingDB.SpecialUpgradeSystems = {
    Venomcursed = {
        label = "Venomcursed",
        tooltipPattern = "^%s*Venomcursed:%s*(Myth)%s*$",
        allowedTracks = { Myth = true },
        inferredTrack = "Myth",
        minimumItemLevel = 318,
        itemIDs = {
            [271875] = true, [271874] = true, [268265] = true,
            [271876] = true, [271878] = true, [268215] = true,
            [268202] = true, [268207] = true,
        },
        ascendantUpgradeEligible = false,
    },
    MythicLocked = {
        label = "Mythic - Not Upgradeable",
        allowedTracks = { Myth = true },
        inferredTrack = "Myth",
        minimumItemLevel = 318,
        itemIDs = {
            [270168] = true, [270169] = true, [270175] = true,
            [270173] = true, [268259] = true, [268256] = true,
            [268231] = true, [268222] = true, [268225] = true,
            [268237] = true, [268255] = true, [268211] = true,
            [268213] = true, [268209] = true, [271093] = true,
            [271092] = true, [268253] = true, [268243] = true,
        },
        ascendantUpgradeEligible = false,
    },
}

function GearingDB.ParseSpecialUpgradeLine(line)
    line = tostring(line or "")
    for systemName, rules in pairs(GearingDB.SpecialUpgradeSystems or {}) do
        local track = rules.tooltipPattern and line:match(rules.tooltipPattern) or nil
        if track and (not rules.allowedTracks or rules.allowedTracks[track] == true) then
            return {
                system = systemName,
                label = rules.label or systemName,
                track = track,
                rawLine = line,
            }
        end
    end
    return nil
end

function GearingDB.InferSpecialUpgrade(itemID, itemLevel)
    itemID = tonumber(itemID)
    itemLevel = tonumber(itemLevel)
    if not itemID or not itemLevel then return nil end

    for systemName, rules in pairs(GearingDB.SpecialUpgradeSystems or {}) do
        local track = rules.itemIDs and rules.itemIDs[itemID]
            and rules.itemLevelTracks and rules.itemLevelTracks[itemLevel] or nil
        if not track and rules.itemIDs and rules.itemIDs[itemID]
            and rules.inferredTrack
            and itemLevel >= (tonumber(rules.minimumItemLevel) or 0) then
            track = rules.inferredTrack
        end
        if track and (not rules.allowedTracks or rules.allowedTracks[track] == true) then
            return {
                system = systemName,
                label = rules.label or systemName,
                track = track,
                inferredFromItemLevel = true,
            }
        end
    end
    return nil
end

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
