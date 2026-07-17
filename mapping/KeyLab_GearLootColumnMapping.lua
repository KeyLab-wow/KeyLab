local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

--[[
Exact bridge between the "Filtered Items" workbook headers and the normalized
runtime database. Tabs should use these definitions instead of guessing where a
spreadsheet column landed. Audit-only capture coordinates remain in the workbook.
]]

local Schema = KeyLab.GearLootColumnMapping or {}
KeyLab.GearLootColumnMapping = Schema

Schema.columnOrder = {
    "sourceTypeNormalized", "sourceNameNormalized", "raidName", "dungeonName", "difficultyID",
    "difficultyName", "minimumItemLevel", "includeRule", "duplicateLevelRule", "itemLevel",
    "highestItemLevelForDuplicateName", "itemID", "itemNameClean", "name", "link", "equipLoc",
    "slot", "armorType", "subclassName", "classID", "lootClassName", "lootClassFile", "specID",
    "specName", "filterMode", "statText", "stats_Agi", "stats_Int", "stats_Str", "stats_Stam",
    "stats_Crit", "stats_Haste", "stats_Mastery", "stats_Vers", "itemQuality", "quality",
    "filterType", "icon", "mapID", "ejID", "instanceID", "encounterID", "visibleIndex", "index",
    "source", "sourceName", "sourceType", "captureIndex", "rowIndex", "className", "statSet",
    "mnSeason", "dualWieldEligible",
}

Schema.columns = {
    sourceTypeNormalized = { scope = "itemSource", path = "items[itemID].sources[sourceID].sourceType", runtime = true },
    sourceNameNormalized = { scope = "itemSource", path = "items[itemID].sources[sourceID].sourceName", runtime = true },
    raidName = { scope = "source", path = "sources[sourceID].raidName", runtime = true },
    dungeonName = { scope = "source", path = "sources[sourceID].dungeonName", runtime = true },
    difficultyID = { scope = "itemSource", path = "items[itemID].sources[sourceID].difficultyID", runtime = true },
    difficultyName = { scope = "itemSource", path = "items[itemID].sources[sourceID].difficultyName", runtime = true },
    minimumItemLevel = { scope = "database", path = "minimumItemLevel", runtime = true },
    includeRule = { scope = "database", path = "buildRules.includeRule", runtime = true },
    duplicateLevelRule = { scope = "database", path = "buildRules.duplicateLevelRule", runtime = true },
    itemLevel = { scope = "itemSource", path = "items[itemID].sources[sourceID].itemLevel", fallback = "items[itemID].itemLevel", runtime = true },
    highestItemLevelForDuplicateName = { scope = "itemSource", path = "items[itemID].sources[sourceID].highestItemLevelForDuplicateName", runtime = true },
    itemID = { scope = "item", path = "items[itemID].itemID", runtime = true },
    itemNameClean = { scope = "item", path = "items[itemID].itemNameClean", runtime = true },
    name = { scope = "item", path = "items[itemID].coloredName", fallback = "items[itemID].name", runtime = true },
    link = { scope = "item", path = "items[itemID].link", runtime = true },
    equipLoc = { scope = "item", path = "items[itemID].equipLoc", runtime = true },
    slot = { scope = "item", path = "items[itemID].slot", runtime = true },
    armorType = { scope = "item", path = "items[itemID].armorType", runtime = true },
    subclassName = { scope = "item", path = "items[itemID].subclassName", runtime = true },
    classID = { scope = "spec", path = "specs[specID].classID", fallback = "items[itemID].classIDs", runtime = true },
    lootClassName = { scope = "spec", path = "specs[specID].className", runtime = true },
    lootClassFile = { scope = "spec", path = "specs[specID].classFile", runtime = true },
    specID = { scope = "spec", path = "specs[specID].specID", runtime = true },
    specName = { scope = "spec", path = "specs[specID].specName", runtime = true },
    filterMode = { scope = "spec", path = "specs[specID].filterMode", runtime = true },
    statText = { scope = "itemSpec", path = "statTextBySpec[itemID][specID]", fallback = "items[itemID].statText", runtime = true },
    stats_Agi = { scope = "itemSpecStat", stat = "Agi", path = "statsBySpec[itemID][specID].Agi", runtime = true },
    stats_Int = { scope = "itemSpecStat", stat = "Int", path = "statsBySpec[itemID][specID].Int", runtime = true },
    stats_Str = { scope = "itemSpecStat", stat = "Str", path = "statsBySpec[itemID][specID].Str", runtime = true },
    stats_Stam = { scope = "itemSpecStat", stat = "Stam", path = "statsBySpec[itemID][specID].Stam", runtime = true },
    stats_Crit = { scope = "itemSpecStat", stat = "Crit", path = "statsBySpec[itemID][specID].Crit", runtime = true },
    stats_Haste = { scope = "itemSpecStat", stat = "Haste", path = "statsBySpec[itemID][specID].Haste", runtime = true },
    stats_Mastery = { scope = "itemSpecStat", stat = "Mastery", path = "statsBySpec[itemID][specID].Mastery", runtime = true },
    stats_Vers = { scope = "itemSpecStat", stat = "Vers", path = "statsBySpec[itemID][specID].Vers", runtime = true },
    itemQuality = { scope = "item", path = "items[itemID].itemQuality", runtime = true },
    quality = { scope = "item", path = "items[itemID].quality", runtime = true },
    filterType = { scope = "item", path = "items[itemID].filterType", runtime = true },
    icon = { scope = "item", path = "items[itemID].icon", runtime = true },
    mapID = { scope = "source", path = "sources[sourceID].mapID", runtime = true },
    ejID = { scope = "source", path = "sources[sourceID].ejID", runtime = true },
    instanceID = { scope = "source", path = "sources[sourceID].instanceID", runtime = true },
    encounterID = { scope = "itemSource", path = "items[itemID].sources[sourceID].encounterIDs", returns = "list", runtime = true },
    visibleIndex = { scope = "workbookOnly", path = "Filtered Items.visibleIndex", runtime = false },
    index = { scope = "workbookOnly", path = "Filtered Items.index", runtime = false },
    source = { scope = "itemSource", path = "items[itemID].sources[sourceID].sourceMethods", returns = "list", runtime = true },
    sourceName = { scope = "itemSource", path = "items[itemID].sources[sourceID].sourceName", runtime = true },
    sourceType = { scope = "itemSource", path = "items[itemID].sources[sourceID].sourceType", runtime = true },
    captureIndex = { scope = "workbookOnly", path = "Filtered Items.captureIndex", runtime = false },
    rowIndex = { scope = "workbookOnly", path = "Filtered Items.rowIndex", runtime = false },
    className = { scope = "item", path = "items[itemID].className", runtime = true },
    statSet = { scope = "item", path = "items[itemID].statSet", returns = "set", runtime = true },
    mnSeason = { scope = "itemSource", path = "items[itemID].sources[sourceID].mnSeason", fallback = "items[itemID].mnSeason", runtime = true },
    dualWieldEligible = { scope = "itemSpec", path = "dualWieldBySpec[itemID][specID]", runtime = true },
}

Schema.headerAliases = {
    ["MN Season"] = "mnSeason",
    ["Dual Wield"] = "dualWieldEligible",
}

function Schema.GetColumnDefinition(header)
    header = header and (Schema.headerAliases[header] or header)
    return header and Schema.columns[header] or nil
end

function Schema.GetValue(header, itemID, specID, sourceID)
    header = header and (Schema.headerAliases[header] or header)
    local definition = Schema.GetColumnDefinition(header)
    local db = KeyLab and KeyLab.GearLootDatabase
    if not definition or not definition.runtime or not db then return nil end

    itemID = tonumber(itemID)
    specID = tonumber(specID)
    sourceID = tonumber(sourceID)
    local item = itemID and db.items and db.items[itemID] or nil
    local spec = specID and db.specs and db.specs[specID] or nil
    local source = sourceID and db.sources and db.sources[sourceID] or nil
    local itemSource = item and sourceID and item.sources and item.sources[sourceID] or nil

    if header == "minimumItemLevel" then return db.minimumItemLevel end
    if header == "includeRule" then return db.buildRules and db.buildRules.includeRule end
    if header == "duplicateLevelRule" then return db.buildRules and db.buildRules.duplicateLevelRule end
    if header == "classID" then return (spec and spec.classID) or (item and item.classIDs) end
    if header == "lootClassName" then return spec and spec.className end
    if header == "lootClassFile" then return spec and spec.classFile end
    if header == "specID" then return spec and spec.specID end
    if header == "specName" then return spec and spec.specName end
    if header == "filterMode" then return spec and spec.filterMode end
    if header == "mnSeason" then
        return (itemSource and itemSource.mnSeason) or (item and item.mnSeason) or db.mnSeason or db.season
    end
    if header == "dualWieldEligible" then
        return itemID and specID and db.dualWieldBySpec and db.dualWieldBySpec[itemID]
            and db.dualWieldBySpec[itemID][specID] == true or false
    end
    if header == "statText" then
        return (itemID and specID and db.statTextBySpec and db.statTextBySpec[itemID] and db.statTextBySpec[itemID][specID])
            or (item and item.statText)
    end
    if definition.scope == "itemSpecStat" then
        return itemID and specID and db.statsBySpec and db.statsBySpec[itemID]
            and db.statsBySpec[itemID][specID] and db.statsBySpec[itemID][specID][definition.stat] or nil
    end

    local itemFields = {
        itemID = "itemID", itemNameClean = "itemNameClean", name = "coloredName", link = "link",
        equipLoc = "equipLoc", slot = "slot", armorType = "armorType", subclassName = "subclassName",
        itemQuality = "itemQuality", quality = "quality", filterType = "filterType", icon = "icon",
        className = "className", statSet = "statSet",
    }
    if itemFields[header] then
        local value = item and item[itemFields[header]]
        if header == "name" and not value then value = item and item.name end
        return value
    end

    local sourceFields = { raidName = "raidName", dungeonName = "dungeonName", mapID = "mapID", ejID = "ejID", instanceID = "instanceID" }
    if sourceFields[header] then return source and source[sourceFields[header]] end

    local itemSourceFields = {
        sourceTypeNormalized = "sourceType", sourceNameNormalized = "sourceName", difficultyID = "difficultyID",
        difficultyName = "difficultyName", itemLevel = "itemLevel",
        highestItemLevelForDuplicateName = "highestItemLevelForDuplicateName", encounterID = "encounterIDs",
        source = "sourceMethods", sourceName = "sourceName", sourceType = "sourceType",
    }
    if itemSourceFields[header] then
        local value = itemSource and itemSource[itemSourceFields[header]]
        if header == "itemLevel" and value == nil then value = item and item.itemLevel end
        return value
    end
    return nil
end

return Schema
