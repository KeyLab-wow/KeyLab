-- KeyLab_GearingDatabase.lua
-- Behind-the-scenes gearing rules used by the Gear Dashboard tab.

local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.GearingDatabase = KeyLab.GearingDatabase or {}
local GearingDB = KeyLab.GearingDatabase

GearingDB.Season = {
    name = "Midnight Season 1",
    note = "Used for Mythic+ dashboard visuals, reward references, and gearing recommendations.",
}

GearingDB.Tracks = {
    { id = 0, name = "Unranked", minItemLevel = 207, maxItemLevel = 220, source = "Not M+ focused" },
    { id = 1, name = "Adventurer", minItemLevel = 220, maxItemLevel = 230, source = "Not M+ focused" },
    { id = 2, name = "Veteran", minItemLevel = 233, maxItemLevel = 246, source = "Early M+ transition" },
    { id = 3, name = "Champion", minItemLevel = 246, maxItemLevel = 259, crestName = "Champion Dawncrest", currencyID = 3343, source = "M+1-5" },
    { id = 4, name = "Hero", minItemLevel = 259, maxItemLevel = 272, crestName = "Hero Dawncrest", currencyID = 3345, source = "M+6-9" },
    { id = 5, name = "Myth", minItemLevel = 272, maxItemLevel = 289, crestName = "Myth Dawncrest", currencyID = 3347, source = "M+10+" },
}

GearingDB.TrackOrder = { "Adventurer", "Veteran", "Champion", "Hero", "Myth" }

GearingDB.DashboardSlots = {
    left = { "Head", "Neck", "Shoulders", "Back", "Chest", "Wrist", "Main Hand", "Off Hand" },
    right = { "Hands", "Waist", "Legs", "Feet", "Finger 1", "Finger 2", "Trinket 1", "Trinket 2" },
}

GearingDB.DisplaySlotLabels = {
    ["Main Hand"] = "Weapon",
    ["Off Hand"] = "Off-Hand",
}

GearingDB.TrackBaseScores = {
    Unranked = 80,
    Adventurer = 80,
    Veteran = 60,
    Champion = 40,
    Hero = 20,
    Myth = 0,
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

GearingDB.EnchantableSlots = {
    Head = true,
    Shoulder = true,
    Shoulders = true,
    Chest = true,
    Legs = true,
    Feet = true,
    Finger = true,
    ["Main Hand"] = true,
}

GearingDB.EmbellishmentSlots = {
    Head = true,
    Shoulders = true,
    Chest = true,
    Waist = true,
    Legs = true,
    Feet = true,
    Wrist = true,
    Hands = true,
    Neck = true,
    Back = true,
    Finger = true,
    ["Main Hand"] = true,
    ["Off Hand"] = true,
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

GearingDB.MythicPlusActivityLanes = {
    Entry = {
        label = "M+ entry lane",
        keyText = "M+2-3",
        crestKey = "championCrests",
        crestName = "Champion Crests",
    },
    Champion = {
        label = "Champion M+ lane",
        keyText = "M+2-5",
        crestKey = "championCrests",
        crestName = "Champion Crests",
    },
    Hero = {
        label = "Hero M+ lane",
        keyText = "M+6-8",
        crestKey = "heroCrests",
        crestName = "Hero Crests",
    },
    Myth = {
        label = "Myth M+ lane",
        keyText = "M+9+",
        crestKey = "mythCrests",
        crestName = "Myth Crests",
    },
}

GearingDB.MythicPlusEndOfRun = {
    [2] = { label = "+2", track = "Champion", rank = "1/6", itemLevel = 246 },
    [3] = { label = "+3", track = "Champion", rank = "2/6", itemLevel = 250 },
    [4] = { label = "+4", track = "Champion", rank = "3/6", itemLevel = 253 },
    [5] = { label = "+5", track = "Champion", rank = "4/6", itemLevel = 256 },
    [6] = { label = "+6", track = "Hero", rank = "1/6", itemLevel = 259 },
    [7] = { label = "+7", track = "Hero", rank = "2/6", itemLevel = 263 },
    [8] = { label = "+8", track = "Hero", rank = "2/6", itemLevel = 263 },
    [9] = { label = "+9", track = "Hero", rank = "3/6", itemLevel = 266 },
    [10] = { label = "+10", track = "Hero", rank = "3/6", itemLevel = 266 },
}

GearingDB.MythicPlusVault = {
    [2] = { label = "+2", track = "Hero", rank = "1/6", itemLevel = 259 },
    [3] = { label = "+3", track = "Hero", rank = "1/6", itemLevel = 259 },
    [4] = { label = "+4", track = "Hero", rank = "2/6", itemLevel = 263 },
    [5] = { label = "+5", track = "Hero", rank = "2/6", itemLevel = 263 },
    [6] = { label = "+6", track = "Hero", rank = "3/6", itemLevel = 266 },
    [7] = { label = "+7", track = "Hero", rank = "4/6", itemLevel = 269 },
    [8] = { label = "+8", track = "Hero", rank = "4/6", itemLevel = 269 },
    [9] = { label = "+9", track = "Hero", rank = "4/6", itemLevel = 269 },
    [10] = { label = "+10+", track = "Myth", rank = "1/6", itemLevel = 272 },
}

GearingDB.MythicPlusCrests = {
    [2] = { crestType = "Champion", count = 10 },
    [3] = { crestType = "Champion", count = 12 },
    [4] = { crestType = "Hero", count = 10 },
    [5] = { crestType = "Hero", count = 12 },
    [6] = { crestType = "Hero", count = 14 },
    [7] = { crestType = "Hero", count = 16 },
    [8] = { crestType = "Hero", count = 18 },
    [9] = { crestType = "Myth", count = 10 },
    [10] = { crestType = "Myth", count = 12 },
    [11] = { crestType = "Myth", count = 14 },
    [12] = { crestType = "Myth", count = 16 },
}

GearingDB.MythicPlusCrestCurrencies = {
    championCrests = { name = "Champion Dawncrest", currencyID = 3343, source = "M+2-3", track = "Champion" },
    heroCrests = { name = "Hero Dawncrest", currencyID = 3345, source = "M+4-8", track = "Hero" },
    mythCrests = { name = "Myth Dawncrest", currencyID = 3347, source = "M+9+", track = "Myth" },
}

GearingDB.GreatVaultSlots = {
    mythicPlus = {
        { slot = 1, required = 1, label = "Complete 1 M+ Dungeon" },
        { slot = 2, required = 4, label = "Complete 4 M+ Dungeons" },
        { slot = 3, required = 8, label = "Complete 8 M+ Dungeons" },
    },
}

GearingDB.Currencies = {
    { name = "Dawnlight Manuflux", currencyID = 3378, use = "Catalyst charges for converting eligible slots into tier pieces." },
    { name = "Nebulous Voidcore", currencyID = 3418, use = "Seasonal source/reroll tracking." },
    { name = "Ascendant Voidcore", itemID = 268552, use = "Raises fully upgraded Hero/Myth track items and max-quality crafted items." },
    { name = "Radiant Spark Dust", currencyID = 3212, use = "Tracks sparks used for crafted gear." },
    { name = "Radiant Jewelbinder", itemID = 263897, use = "Socket/jewel-related upgrade item if available." },
    { name = "Champion Dawncrest", currencyID = 3343, use = "Champion-track upgrades from M+2-3." },
    { name = "Hero Dawncrest", currencyID = 3345, use = "Hero-track upgrades from M+4-8." },
    { name = "Myth Dawncrest", currencyID = 3347, use = "Myth-track upgrades from M+9+." },
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

GearingDB.CraftedGear = {
    crestCost = 80,
    crestNote = "Hero or Myth Dawncrests are required per crafted item.",
    sparksRequired = {
        weapon = 4,
        armor = 2,
        jewelry = 2,
    },
}

GearingDB.Catalyst = {
    tierSlots = { "Head", "Shoulders", "Chest", "Hands", "Legs" },
    note = "Catalyst can convert eligible gear into tier pieces when charges are available.",
}

GearingDB.Voidforge = {
    ascendantVoidcoreItemID = 268552,
    craftedWeaponSlotID = 16,
    trinketSlotIDs = {
        [13] = true,
        [14] = true,
    },
    eligibleTracks = {
        Hero = true,
        Myth = true,
    },
    requiredRank = 6,
    requiredMaxRank = 6,
}

GearingDB.PriorityFactors = {
    "Current equipped item level",
    "Current equipped track per slot",
    "Upgrade priority slots",
    "Gear Target status",
    "BIS / Crafted / Acquired status",
    "Recent M+ history from encounters",
    "Highest completed key",
    "Highest timed key",
    "Number of recent M+ runs",
    "Great Vault progress",
    "Crest needs",
    "Crafted, catalyst, polish, and voidforge signals",
}

local function CopyEntry(entry)
    if type(entry) ~= "table" then return nil end
    local out = {}
    for key, value in pairs(entry) do
        if type(value) == "table" then
            local nested = {}
            for nestedKey, nestedValue in pairs(value) do
                nested[nestedKey] = nestedValue
            end
            out[key] = nested
        else
            out[key] = value
        end
    end
    return out
end

local function CopyList(list)
    local out = {}
    for _, entry in ipairs(list or {}) do
        table.insert(out, CopyEntry(entry) or entry)
    end
    return out
end

function GearingDB.GetDashboardSlots(side)
    return CopyList(GearingDB.DashboardSlots and GearingDB.DashboardSlots[side])
end

function GearingDB.GetDisplaySlotLabel(slotName)
    return (GearingDB.DisplaySlotLabels and GearingDB.DisplaySlotLabels[slotName]) or slotName or "-"
end

function GearingDB.GetTrackRank(trackName)
    local track = GearingDB.GetTrackByName(trackName)
    return track and tonumber(track.id) or 0
end

function GearingDB.GetTrackBaseScore(trackName)
    return (GearingDB.TrackBaseScores and GearingDB.TrackBaseScores[trackName]) or 0
end

function GearingDB.GetTrackSource(trackName)
    local track = GearingDB.GetTrackByName(trackName)
    return track and track.source or nil
end

function GearingDB.GetDungeonCode(dungeonName)
    return (GearingDB.DungeonCodes and GearingDB.DungeonCodes[dungeonName]) or dungeonName
end

function GearingDB.IsEnchantableSlot(slotName)
    return GearingDB.EnchantableSlots and GearingDB.EnchantableSlots[slotName] == true
end

function GearingDB.IsEmbellishmentSlot(slotName)
    return GearingDB.EmbellishmentSlots and GearingDB.EmbellishmentSlots[slotName] == true
end

function GearingDB.IsTwoHandOrRangedEquipLoc(equipLoc)
    return GearingDB.TwoHandOrRangedEquipLocs and GearingDB.TwoHandOrRangedEquipLocs[equipLoc or ""] == true
end

function GearingDB.GetMythicPlusLane(trackName)
    local lanes = GearingDB.MythicPlusActivityLanes or {}
    return CopyEntry(lanes[trackName] or lanes.Entry)
end

function GearingDB.GetTrackByName(trackName)
    for _, track in ipairs(GearingDB.Tracks or {}) do
        if track.name == trackName then return track end
    end
    return nil
end

function GearingDB.GetTrackByItemLevel(itemLevel)
    itemLevel = tonumber(itemLevel)
    if not itemLevel then return nil end

    local previous
    for _, track in ipairs(GearingDB.Tracks or {}) do
        if itemLevel >= track.minItemLevel and itemLevel <= track.maxItemLevel then
            return track
        end
        if itemLevel < track.minItemLevel then
            return previous or track
        end
        previous = track
    end

    return previous
end

function GearingDB.GetNextTrack(trackName)
    local found = false
    for _, track in ipairs(GearingDB.Tracks or {}) do
        if found then return track end
        if track.name == trackName then found = true end
    end
    return nil
end

local function GetClosestKeyReward(tableRef, keyLevel)
    keyLevel = tonumber(keyLevel)
    if not keyLevel then return nil end
    local bestKey
    for level in pairs(tableRef or {}) do
        if level <= keyLevel and (not bestKey or level > bestKey) then
            bestKey = level
        end
    end
    return bestKey and CopyEntry(tableRef[bestKey]) or nil
end

function GearingDB.GetMythicPlusEndReward(keyLevel)
    return GetClosestKeyReward(GearingDB.MythicPlusEndOfRun, keyLevel)
end

function GearingDB.GetMythicPlusVaultReward(keyLevel)
    return GetClosestKeyReward(GearingDB.MythicPlusVault, keyLevel)
end

function GearingDB.GetMythicPlusCrestReward(keyLevel)
    return GetClosestKeyReward(GearingDB.MythicPlusCrests, keyLevel)
end

return GearingDB
