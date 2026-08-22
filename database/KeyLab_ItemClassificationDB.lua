local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

--[[
KeyLab_ItemClassificationDB.lua

Classifies equipped items from known item IDs. Native Season 2 tier records
come from the tier workbook integrated into the master loot database. The
five Set ID slots count toward the 2/4-piece bonus; the other four matching
class-themed pieces are native tier off-pieces only.
]]

KeyLab.ItemClassificationDB = KeyLab.ItemClassificationDB or {}
local ClassificationDB = KeyLab.ItemClassificationDB

ClassificationDB.Categories = {
    EMPTY = "EMPTY",
    TIER_SET = "TIER_SET",
    NATIVE_TIER_OFFPIECE = "NATIVE_TIER_OFFPIECE",
    CRAFTED = "CRAFTED",
    MASTER = "MASTER",
    OTHER = "OTHER",
}

local SLOT_BY_OFFSET = {
    [0] = { slot = "Back", equipLoc = "INVTYPE_CLOAK", countsTowardSet = false },
    [1] = { slot = "Wrist", equipLoc = "INVTYPE_WRIST", countsTowardSet = false },
    [2] = { slot = "Waist", equipLoc = "INVTYPE_WAIST", countsTowardSet = false },
    [3] = { slot = "Shoulders", equipLoc = "INVTYPE_SHOULDER", countsTowardSet = true },
    [4] = { slot = "Legs", equipLoc = "INVTYPE_LEGS", countsTowardSet = true },
    [5] = { slot = "Head", equipLoc = "INVTYPE_HEAD", countsTowardSet = true },
    [6] = { slot = "Hands", equipLoc = "INVTYPE_HAND", countsTowardSet = true },
    [7] = { slot = "Feet", equipLoc = "INVTYPE_FEET", countsTowardSet = false },
    [8] = { slot = "Chest", equipLoc = "INVTYPE_CHEST", countsTowardSet = true },
}

local TIER_GROUPS = {
    { firstItemID = 271469, classID = 6, classFile = "DEATHKNIGHT", className = "Death Knight", setID = 2055 },
    { firstItemID = 271559, classID = 8, classFile = "MAGE", className = "Mage", setID = 2060 },
    { firstItemID = 271460, classID = 2, classFile = "PALADIN", className = "Paladin", setID = 2062 },
    { firstItemID = 271478, classID = 13, classFile = "EVOKER", className = "Evoker", setID = 2065 },
    { firstItemID = 271523, classID = 11, classFile = "DRUID", className = "Druid", setID = 2057 },
    { firstItemID = 271487, classID = 3, classFile = "HUNTER", className = "Hunter", setID = 2059 },
    { firstItemID = 271550, classID = 5, classFile = "PRIEST", className = "Priest", setID = 2063 },
    { firstItemID = 271451, classID = 1, classFile = "WARRIOR", className = "Warrior", setID = 2067 },
    { firstItemID = 271505, classID = 4, classFile = "ROGUE", className = "Rogue", setID = 2064 },
    { firstItemID = 271514, classID = 10, classFile = "MONK", className = "Monk", setID = 2061 },
    { firstItemID = 271541, classID = 9, classFile = "WARLOCK", className = "Warlock", setID = 2066 },
    { firstItemID = 271532, classID = 12, classFile = "DEMONHUNTER", className = "Demon Hunter", setID = 2056 },
    { firstItemID = 271496, classID = 7, classFile = "SHAMAN", className = "Shaman", setID = 2058 },
}

local nativeTierItems = {}
for _, group in ipairs(TIER_GROUPS) do
    for offset = 0, 8 do
        local slotInfo = SLOT_BY_OFFSET[offset]
        local itemID = group.firstItemID + offset
        nativeTierItems[itemID] = {
            itemID = itemID,
            classID = group.classID,
            classFile = group.classFile,
            className = group.className,
            slot = slotInfo.slot,
            equipLoc = slotInfo.equipLoc,
            setID = slotInfo.countsTowardSet and group.setID or nil,
            countsTowardSet = slotInfo.countsTowardSet,
            nativeTier = true,
            sourceID = 1320,
            sourceName = "The Venomous Abyss",
            sourceType = "Raid",
            mnSeason = 2,
        }
    end
end

local craftedItems = {}
for recipeID, recipe in pairs((KeyLab.CraftedRecipeDatabase and KeyLab.CraftedRecipeDatabase.recipes) or {}) do
    local itemID = tonumber(recipe and recipe.itemID)
    if itemID and (recipe.isEquipmentOutput == true or tostring(recipe.equipLoc or ""):find("^INVTYPE_")) then
        craftedItems[itemID] = craftedItems[itemID] or {
            itemID = itemID,
            recipeID = tonumber(recipeID),
            name = recipe.name,
            slot = recipe.slot,
            equipLoc = recipe.equipLoc,
            professionID = recipe.professionID,
        }
    end
end

-- The generated master database now contains the full tier rows, including
-- scaled stats and legal specs. Add the tier meaning here without duplicating
-- those large records or creating a second source list.
local masterDB = KeyLab.GearLootDatabase
if masterDB then
    masterDB.items = masterDB.items or {}
    masterDB.nativeTierItems = nativeTierItems
    for itemID, tierRecord in pairs(nativeTierItems) do
        local item = masterDB.items[itemID]
        if not item then
            item = {
                itemID = itemID,
                name = tierRecord.className .. " Native Tier " .. tierRecord.slot,
                itemNameClean = tierRecord.className .. " Native Tier " .. tierRecord.slot,
                slot = tierRecord.slot,
                equipLoc = tierRecord.equipLoc,
                mnSeason = tierRecord.mnSeason,
                sources = {},
            }
            masterDB.items[itemID] = item
        end
        item.nativeTier = true
        item.tierClassID = tierRecord.classID
        item.tierClassFile = tierRecord.classFile
        item.tierSetID = tierRecord.setID
        item.countsTowardTierSet = tierRecord.countsTowardSet
    end
end

function ClassificationDB.GetNativeTierItem(itemID)
    return nativeTierItems[tonumber(itemID)]
end

function ClassificationDB.IsTierSetPiece(itemID)
    local item = ClassificationDB.GetNativeTierItem(itemID)
    return item and item.countsTowardSet == true or false
end

function ClassificationDB.IsNativeTierOffPiece(itemID)
    local item = ClassificationDB.GetNativeTierItem(itemID)
    return item and item.countsTowardSet ~= true or false
end

function ClassificationDB.GetCraftedItem(itemID)
    return craftedItems[tonumber(itemID)]
end

function ClassificationDB.IsCraftedItem(itemID)
    return ClassificationDB.GetCraftedItem(itemID) ~= nil
end

function ClassificationDB.IsMasterItem(itemID)
    itemID = tonumber(itemID)
    return itemID and masterDB and masterDB.items and masterDB.items[itemID] ~= nil or false
end

function ClassificationDB.ClassifyItem(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return { key = ClassificationDB.Categories.EMPTY, label = "", itemID = nil, known = false }
    end

    local tierItem = nativeTierItems[itemID]
    if tierItem then
        return {
            key = tierItem.countsTowardSet and ClassificationDB.Categories.TIER_SET
                or ClassificationDB.Categories.NATIVE_TIER_OFFPIECE,
            label = tierItem.countsTowardSet and "Tier Set Piece" or "Native Tier Off-piece",
            itemID = itemID,
            known = true,
            tier = tierItem,
        }
    end

    local craftedItem = craftedItems[itemID]
    if craftedItem then
        return {
            key = ClassificationDB.Categories.CRAFTED,
            label = "Crafted Item",
            itemID = itemID,
            known = true,
            crafted = craftedItem,
        }
    end

    if ClassificationDB.IsMasterItem(itemID) then
        return {
            key = ClassificationDB.Categories.MASTER,
            label = "Master Database Item",
            itemID = itemID,
            known = true,
        }
    end

    return {
        key = ClassificationDB.Categories.OTHER,
        label = "Other Item",
        itemID = itemID,
        known = false,
    }
end

function ClassificationDB.GetCounts()
    local tierCount, tierSetCount, tierOffPieceCount, craftedCount = 0, 0, 0, 0
    for _, item in pairs(nativeTierItems) do
        tierCount = tierCount + 1
        if item.countsTowardSet then tierSetCount = tierSetCount + 1 else tierOffPieceCount = tierOffPieceCount + 1 end
    end
    for _ in pairs(craftedItems) do craftedCount = craftedCount + 1 end
    return {
        nativeTier = tierCount,
        tierSet = tierSetCount,
        tierOffPiece = tierOffPieceCount,
        crafted = craftedCount,
    }
end

return ClassificationDB
