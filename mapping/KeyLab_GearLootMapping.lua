local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

--[[
KeyLab_GearLootMapping.lua
Helper/index layer for database/KeyLab_GearLootDatabase.lua.

Purpose:
- Keep the master loot database as static addon data.
- Give UI files simple lookup functions for Gear Targets filters and LFG summaries.
- Do not store any of this derived data in SavedVariables.

Load order:
1. database/KeyLab_GearLootDatabase.lua
2. mapping/KeyLab_GearLootMapping.lua
]]

local Mapping = KeyLab.GearLootMapping or {}
KeyLab.GearLootMapping = Mapping

local PRIMARY_STATS = {
    Int = true,
    Agi = true,
    Str = true,
}

local SECONDARY_STATS = {
    Crit = true,
    Haste = true,
    Mastery = true,
    Vers = true,
}

local function getDB()
    return KeyLab and KeyLab.GearLootDatabase or nil
end

local function wipeTable(tbl)
    if not tbl then return {} end
    for key in pairs(tbl) do
        tbl[key] = nil
    end
    return tbl
end

local function addUniqueNumber(list, value)
    if value == nil then return end
    for _, existing in ipairs(list) do
        if existing == value then return end
    end
    table.insert(list, value)
end

local function addUniqueString(list, value)
    if value == nil or value == "" then return end
    for _, existing in ipairs(list) do
        if existing == value then return end
    end
    table.insert(list, value)
end

local function sortNumberList(list)
    table.sort(list, function(a, b) return tonumber(a or 0) < tonumber(b or 0) end)
end

local function sortByName(list)
    table.sort(list, function(a, b)
        local nameA = (a and (a.name or a.specName or a.className)) or ""
        local nameB = (b and (b.name or b.specName or b.className)) or ""
        return tostring(nameA) < tostring(nameB)
    end)
end

local function normalizeItemName(name)
    if type(name) ~= "string" then return name end
    return name:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end

local function getDungeonNameForItem(item, mapID)
    local db = getDB()
    if not item then return "" end

    if mapID and item.sources and item.sources[mapID] then
        local source = item.sources[mapID]
        local dungeon = db and db.dungeons and db.dungeons[mapID]
        return source.dungeonName or (dungeon and dungeon.name) or tostring(mapID)
    end

    if item.dungeonName and item.dungeonName ~= "" then
        return item.dungeonName
    end

    local names, seen = {}, {}
    for sourceMapID, source in pairs(item.sources or {}) do
        local dungeon = db and db.dungeons and db.dungeons[sourceMapID]
        local name = source.dungeonName or (dungeon and dungeon.name) or tostring(sourceMapID)
        if name and name ~= "" and not seen[name] then
            seen[name] = true
            table.insert(names, name)
        end
    end

    table.sort(names)
    return table.concat(names, ", ")
end

local function withDisplayDungeon(item, mapID)
    if not item then return nil end
    local out = {}
    for key, value in pairs(item) do
        out[key] = value
    end
    out.dungeonName = getDungeonNameForItem(item, mapID)
    return out
end

local function hasSelectedStat(item, selected)
    if not selected then return true end

    local hasAny = false
    for stat, enabled in pairs(selected) do
        if enabled then
            hasAny = true
            if item and item.stats and item.stats[stat] ~= nil then
                return true
            end
            if item and item.statSet and item.statSet[stat] then
                return true
            end
        end
    end

    return not hasAny
end

local function itemMatchesPrimary(item, primaryStat)
    if not primaryStat or primaryStat == "" or primaryStat == "All" then
        return true
    end
    return hasSelectedStat(item, { [primaryStat] = true })
end

local function itemMatchesSecondaries(item, secondaryStats)
    return hasSelectedStat(item, secondaryStats)
end

local function itemIsNonGear(item)
    if not item then return false end
    if item.equipLoc == "INVTYPE_NON_EQUIP_IGNORE" then return true end
    if item.className == "Recipe" or item.className == "Housing" or item.className == "Miscellaneous" then
        if item.slot == nil or item.slot == "" then return true end
    end
    return false
end

function Mapping.BuildIndexes(force)
    local db = getDB()
    if not db then return nil end

    if Mapping.indexes and not force then
        return Mapping.indexes
    end

    local indexes = {
        dungeonsBySpec = {},
        slotsBySpec = {},
        itemsByDungeon = {},
        itemToSpecs = {},
        itemToDungeons = {},
        specsByClass = {},
        slotList = {},
        dungeonList = {},
        specList = {},
    }

    for mapID, dungeon in pairs(db.dungeons or {}) do
        table.insert(indexes.dungeonList, {
            mapID = mapID,
            name = dungeon.name or tostring(mapID),
        })
    end
    sortByName(indexes.dungeonList)

    for specID, spec in pairs(db.specs or {}) do
        local classID = spec.classID or 0
        indexes.specsByClass[classID] = indexes.specsByClass[classID] or {}
        table.insert(indexes.specsByClass[classID], spec)
        table.insert(indexes.specList, spec)
    end
    sortByName(indexes.specList)
    for _, specs in pairs(indexes.specsByClass) do
        sortByName(specs)
    end

    for specID, dungeonItems in pairs(db.bySpec or {}) do
        indexes.dungeonsBySpec[specID] = indexes.dungeonsBySpec[specID] or {}
        indexes.slotsBySpec[specID] = indexes.slotsBySpec[specID] or {}

        for mapID, itemIDs in pairs(dungeonItems or {}) do
            addUniqueNumber(indexes.dungeonsBySpec[specID], mapID)
            indexes.itemsByDungeon[mapID] = indexes.itemsByDungeon[mapID] or {}

            for _, itemID in ipairs(itemIDs or {}) do
                local item = db.items and db.items[itemID]
                if item then
                    indexes.itemsByDungeon[mapID][itemID] = true
                    indexes.itemToSpecs[itemID] = indexes.itemToSpecs[itemID] or {}
                    indexes.itemToDungeons[itemID] = indexes.itemToDungeons[itemID] or {}

                    addUniqueNumber(indexes.itemToSpecs[itemID], specID)
                    addUniqueNumber(indexes.itemToDungeons[itemID], mapID)
                    addUniqueString(indexes.slotsBySpec[specID], item.slot)
                    addUniqueString(indexes.slotList, item.slot)
                end
            end
        end

        sortNumberList(indexes.dungeonsBySpec[specID])
        table.sort(indexes.slotsBySpec[specID])
    end

    table.sort(indexes.slotList)
    Mapping.indexes = indexes
    return indexes
end

function Mapping.GetSeasonInfo()
    local db = getDB()
    if not db then return nil end
    return {
        expansion = db.expansion,
        expansionID = db.expansionID,
        season = db.season,
        seasonName = db.seasonName,
        seasonKey = db.seasonKey,
        build = db.build,
        tocVersion = db.tocVersion,
    }
end

function Mapping.GetDungeonList()
    local indexes = Mapping.BuildIndexes()
    return indexes and indexes.dungeonList or {}
end

function Mapping.GetSpecList(classID)
    local indexes = Mapping.BuildIndexes()
    if not indexes then return {} end
    if classID then
        return indexes.specsByClass[classID] or {}
    end
    return indexes.specList or {}
end

function Mapping.GetSlotList(specID, classID)
    local indexes = Mapping.BuildIndexes()
    if not indexes then return {} end
    if specID and indexes.slotsBySpec[specID] then
        return indexes.slotsBySpec[specID]
    end

    if classID and indexes.specsByClass and indexes.specsByClass[classID] then
        local seen, out = {}, {}
        for _, spec in ipairs(indexes.specsByClass[classID] or {}) do
            for _, slot in ipairs(indexes.slotsBySpec[spec.specID] or {}) do
                if slot and slot ~= "" and not seen[slot] then
                    seen[slot] = true
                    table.insert(out, slot)
                end
            end
        end
        table.sort(out)
        return out
    end

    return indexes.slotList or {}
end

function Mapping.GetDungeonListForSpec(specID)
    local db = getDB()
    local indexes = Mapping.BuildIndexes()
    local out = {}
    if not db or not indexes or not specID then return out end

    for _, mapID in ipairs(indexes.dungeonsBySpec[specID] or {}) do
        local dungeon = db.dungeons and db.dungeons[mapID]
        table.insert(out, {
            mapID = mapID,
            name = (dungeon and dungeon.name) or tostring(mapID),
        })
    end
    sortByName(out)
    return out
end

function Mapping.GetItem(itemID)
    local db = getDB()
    return db and db.items and withDisplayDungeon(db.items[itemID]) or nil
end

function Mapping.GetItemSpecs(itemID)
    local indexes = Mapping.BuildIndexes()
    return indexes and indexes.itemToSpecs and indexes.itemToSpecs[itemID] or {}
end

function Mapping.GetItemDungeons(itemID)
    local indexes = Mapping.BuildIndexes()
    return indexes and indexes.itemToDungeons and indexes.itemToDungeons[itemID] or {}
end

function Mapping.GetItemsForSpecDungeon(specID, mapID)
    local db = getDB()
    if not db or not specID or not mapID then return {} end

    local itemIDs = db.bySpec and db.bySpec[specID] and db.bySpec[specID][mapID]
    local out = {}
    for _, itemID in ipairs(itemIDs or {}) do
        local item = db.items and db.items[itemID]
        if item then table.insert(out, withDisplayDungeon(item, mapID)) end
    end
    table.sort(out, function(a, b)
        local slotA = tostring(a.slot or "")
        local slotB = tostring(b.slot or "")
        if slotA ~= slotB then return slotA < slotB end
        return tostring(normalizeItemName(a.name) or "") < tostring(normalizeItemName(b.name) or "")
    end)
    return out
end

function Mapping.GetFilteredItems(filters)
    local db = getDB()
    if not db then return {} end
    filters = filters or {}

    local specID = filters.specID
    local classID = filters.classID
    local mapID = filters.mapID
    local slot = filters.slot
    local primaryStat = filters.primaryStat
    local secondaryStats = filters.secondaryStats
    local includeNonGear = filters.includeNonGear ~= false

    local out = {}
    local seen = {}

    local function considerItem(itemID)
        if seen[itemID] then return end
        local item = db.items and db.items[itemID]
        if not item then return end
        if slot and slot ~= "" and slot ~= "All" and item.slot ~= slot then return end
        if not includeNonGear and itemIsNonGear(item) then return end
        if not itemMatchesPrimary(item, primaryStat) then return end
        if not itemMatchesSecondaries(item, secondaryStats) then return end
        seen[itemID] = true
        table.insert(out, withDisplayDungeon(item, mapID))
    end

    if specID and mapID then
        for _, itemID in ipairs((db.bySpec and db.bySpec[specID] and db.bySpec[specID][mapID]) or {}) do
            considerItem(itemID)
        end
    elseif specID then
        for _, itemIDs in pairs((db.bySpec and db.bySpec[specID]) or {}) do
            for _, itemID in ipairs(itemIDs or {}) do
                considerItem(itemID)
            end
        end
    elseif classID then
        local indexes = Mapping.BuildIndexes()
        for _, spec in ipairs((indexes and indexes.specsByClass and indexes.specsByClass[classID]) or {}) do
            if mapID then
                for _, itemID in ipairs((db.bySpec and db.bySpec[spec.specID] and db.bySpec[spec.specID][mapID]) or {}) do
                    considerItem(itemID)
                end
            else
                for _, itemIDs in pairs((db.bySpec and db.bySpec[spec.specID]) or {}) do
                    for _, itemID in ipairs(itemIDs or {}) do
                        considerItem(itemID)
                    end
                end
            end
        end
    elseif mapID then
        local indexes = Mapping.BuildIndexes()
        for itemID in pairs((indexes and indexes.itemsByDungeon and indexes.itemsByDungeon[mapID]) or {}) do
            considerItem(itemID)
        end
    else
        for itemID in pairs(db.items or {}) do
            considerItem(itemID)
        end
    end

    table.sort(out, function(a, b)
        local dungeonA = tostring(a.dungeonName or "")
        local dungeonB = tostring(b.dungeonName or "")
        if dungeonA ~= dungeonB then return dungeonA < dungeonB end
        local slotA = tostring(a.slot or "")
        local slotB = tostring(b.slot or "")
        if slotA ~= slotB then return slotA < slotB end
        return tostring(normalizeItemName(a.name) or "") < tostring(normalizeItemName(b.name) or "")
    end)

    return out
end

function Mapping.IsItemForSpecDungeon(itemID, specID, mapID)
    local db = getDB()
    if not db or not itemID or not specID or not mapID then return false end
    for _, id in ipairs((db.bySpec and db.bySpec[specID] and db.bySpec[specID][mapID]) or {}) do
        if id == itemID then return true end
    end
    return false
end

function Mapping.GetTargetSummaryForDungeon(trackedItems, mapID, specID)
    local summary = {
        thisDungeon = {},
        otherDungeons = {},
        totalTargets = 0,
    }

    if type(trackedItems) ~= "table" then return summary end

    local db = getDB()
    local indexes = Mapping.BuildIndexes()
    if not db or not indexes then return summary end

    local otherCounts = {}

    for itemID, enabled in pairs(trackedItems) do
        if enabled then
            local item = db.items and db.items[itemID]
            if item then
                summary.totalTargets = summary.totalTargets + 1
                local dungeons = indexes.itemToDungeons[itemID] or {}
                local belongsToThisDungeon = false
                for _, itemMapID in ipairs(dungeons) do
                    if itemMapID == mapID then
                        belongsToThisDungeon = true
                    else
                        local dungeon = db.dungeons and db.dungeons[itemMapID]
                        local name = (dungeon and dungeon.name) or item.dungeonName or tostring(itemMapID)
                        otherCounts[name] = (otherCounts[name] or 0) + 1
                    end
                end

                if belongsToThisDungeon and (not specID or Mapping.IsItemForSpecDungeon(itemID, specID, mapID)) then
                    table.insert(summary.thisDungeon, item)
                end
            end
        end
    end

    for dungeonName, count in pairs(otherCounts) do
        table.insert(summary.otherDungeons, {
            dungeonName = dungeonName,
            count = count,
        })
    end

    table.sort(summary.thisDungeon, function(a, b)
        return tostring(normalizeItemName(a.name) or "") < tostring(normalizeItemName(b.name) or "")
    end)
    table.sort(summary.otherDungeons, function(a, b)
        return tostring(a.dungeonName) < tostring(b.dungeonName)
    end)

    return summary
end

function Mapping.ClearIndexes()
    Mapping.indexes = nil
end

-- Build lazily on first use. This explicit call is harmless and catches early load-order problems.
Mapping.BuildIndexes()
