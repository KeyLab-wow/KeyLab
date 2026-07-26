local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

--[[
KeyLab_GearLootMapping.lua

Generic dungeon-and-raid lookup layer for the approved master item database.
All indexes are runtime-only. Saved target ownership lives in LootTargetsDB.
Legacy dungeon-named functions remain available for the LFG target window.
]]

local Mapping = KeyLab.GearLootMapping or {}
KeyLab.GearLootMapping = Mapping

local SECONDARY_STATS = { Crit = true, Haste = true, Mastery = true, Vers = true }
local PRIMARY_STATS = { Agi = true, Int = true, Str = true, Stam = true }
local CATALYST_SLOT_BASES = {
    Head = true, Shoulders = true, Back = true, Chest = true, Wrist = true,
    Hands = true, Waist = true, Legs = true, Feet = true,
}

local function DB()
    return KeyLab and KeyLab.GearLootDatabase or nil
end

local function CleanText(value)
    value = tostring(value or "")
    value = value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    return value:gsub("^%s+", ""):gsub("%s+$", "")
end

local function SearchText(value)
    return string.lower(CleanText(value))
end

local function AddUnique(list, seen, value)
    if value == nil or value == "" or seen[value] then return end
    seen[value] = true
    table.insert(list, value)
end

local function AddUniqueNumber(list, seen, value)
    value = tonumber(value)
    if not value or seen[value] then return end
    seen[value] = true
    table.insert(list, value)
end

local function SortNumbers(list)
    table.sort(list, function(a, b) return tonumber(a or 0) < tonumber(b or 0) end)
end

local function SortByName(list)
    table.sort(list, function(a, b)
        local nameA = tostring(a and (a.name or a.sourceName or a.specName or a.className) or "")
        local nameB = tostring(b and (b.name or b.sourceName or b.specName or b.className) or "")
        if nameA ~= nameB then return nameA < nameB end
        return tonumber(a and (a.sourceID or a.specID) or 0) < tonumber(b and (b.sourceID or b.specID) or 0)
    end)
end

local function CopyTable(source)
    local out = {}
    for key, value in pairs(source or {}) do out[key] = value end
    return out
end

local function NormalizeSourceType(value)
    value = string.lower(tostring(value or ""))
    if value == "dungeon" or value == "dungeons" or value == "dungeon items" or value == "dungeon items only" then
        return "Dungeon"
    end
    if value == "raid" or value == "raids" or value == "raid items" or value == "raid items only" then
        return "Raid"
    end
    return nil
end

function Mapping.NormalizeSlotName(slotName)
    slotName = tostring(slotName or "")
    local aliases = {
        ["Shoulder"] = "Shoulders",
        ["Finger"] = "Finger",
        ["Trinket"] = "Trinket",
        ["Held In Off-hand"] = "Off Hand",
        ["Held In Off-Hand"] = "Off Hand",
        ["Off-Hand"] = "Off Hand",
        ["Main-Hand"] = "Main Hand",
    }
    return aliases[slotName] or slotName
end

function Mapping.GetBaseSlotName(slotName)
    slotName = Mapping.NormalizeSlotName(slotName)
    if slotName == "Finger 1" or slotName == "Finger 2" then return "Finger" end
    if slotName == "Trinket 1" or slotName == "Trinket 2" then return "Trinket" end
    if slotName == "Main Hand" or slotName == "Off Hand" then return "Weapon" end
    return slotName
end

local function GetSpecInfo(specID)
    local db = DB()
    specID = tonumber(specID)
    return db and db.specs and specID and db.specs[specID] or nil
end

local function GetClassIDForSpec(specID)
    local spec = GetSpecInfo(specID)
    return spec and tonumber(spec.classID) or nil
end

local function GetSpecName(specID)
    local spec = GetSpecInfo(specID)
    return spec and (spec.specName or spec.name) or nil
end

local function IsItemInSpecSource(itemID, specID, sourceID)
    local db = DB()
    itemID = tonumber(itemID)
    specID = tonumber(specID)
    sourceID = tonumber(sourceID)
    if not db or not itemID or not specID or not sourceID then return false end
    for _, candidateID in ipairs((db.bySpec and db.bySpec[specID] and db.bySpec[specID][sourceID]) or {}) do
        if tonumber(candidateID) == itemID then return true end
    end
    return false
end

function Mapping.BuildIndexes(force)
    local db = DB()
    if not db then return nil end
    if Mapping.indexes and not force then return Mapping.indexes end

    local indexes = {
        sourcesBySpec = {},
        dungeonsBySpec = {},
        raidsBySpec = {},
        slotsBySpec = {},
        itemsBySource = {},
        itemToSpecs = {},
        itemToSources = {},
        itemToDungeons = {},
        itemSourcesBySpec = {},
        specsByClass = {},
        sourceList = {},
        dungeonList = {},
        raidList = {},
        specList = {},
        slotList = {},
    }

    for sourceID, source in pairs(db.sources or {}) do
        sourceID = tonumber(sourceID)
        local entry = {
            sourceID = sourceID,
            name = source.name or source.sourceName or tostring(sourceID),
            sourceName = source.sourceName or source.name or tostring(sourceID),
            sourceType = source.sourceType,
            mapID = source.mapID,
            instanceID = source.instanceID,
            ejID = source.ejID,
            repeatable = source.repeatable == true,
        }
        table.insert(indexes.sourceList, entry)
        if source.sourceType == "Dungeon" then
            entry.mapID = tonumber(source.mapID) or sourceID
            table.insert(indexes.dungeonList, entry)
        elseif source.sourceType == "Raid" then
            entry.instanceID = tonumber(source.instanceID) or sourceID
            table.insert(indexes.raidList, entry)
        end
    end
    SortByName(indexes.sourceList)
    SortByName(indexes.dungeonList)
    SortByName(indexes.raidList)

    for specID, spec in pairs(db.specs or {}) do
        specID = tonumber(specID)
        local classID = tonumber(spec.classID) or 0
        indexes.specsByClass[classID] = indexes.specsByClass[classID] or {}
        table.insert(indexes.specsByClass[classID], spec)
        table.insert(indexes.specList, spec)
        indexes.sourcesBySpec[specID] = {}
        indexes.dungeonsBySpec[specID] = {}
        indexes.raidsBySpec[specID] = {}
        indexes.slotsBySpec[specID] = {}
        indexes.itemSourcesBySpec[specID] = {}
    end
    SortByName(indexes.specList)
    for _, specs in pairs(indexes.specsByClass) do SortByName(specs) end

    local slotSeen = {}
    for specID, sourceItems in pairs(db.bySpec or {}) do
        specID = tonumber(specID)
        local specSourceSeen, specDungeonSeen, specRaidSeen, specSlotSeen = {}, {}, {}, {}
        indexes.sourcesBySpec[specID] = indexes.sourcesBySpec[specID] or {}
        indexes.dungeonsBySpec[specID] = indexes.dungeonsBySpec[specID] or {}
        indexes.raidsBySpec[specID] = indexes.raidsBySpec[specID] or {}
        indexes.slotsBySpec[specID] = indexes.slotsBySpec[specID] or {}
        indexes.itemSourcesBySpec[specID] = indexes.itemSourcesBySpec[specID] or {}

        for sourceID, itemIDs in pairs(sourceItems or {}) do
            sourceID = tonumber(sourceID)
            local source = db.sources and db.sources[sourceID]
            AddUniqueNumber(indexes.sourcesBySpec[specID], specSourceSeen, sourceID)
            if source and source.sourceType == "Dungeon" then
                AddUniqueNumber(indexes.dungeonsBySpec[specID], specDungeonSeen, sourceID)
            elseif source and source.sourceType == "Raid" then
                AddUniqueNumber(indexes.raidsBySpec[specID], specRaidSeen, sourceID)
            end
            indexes.itemsBySource[sourceID] = indexes.itemsBySource[sourceID] or {}

            for _, itemID in ipairs(itemIDs or {}) do
                itemID = tonumber(itemID)
                local item = db.items and db.items[itemID]
                if item then
                    indexes.itemsBySource[sourceID][itemID] = true
                    indexes.itemToSpecs[itemID] = indexes.itemToSpecs[itemID] or {}
                    indexes.itemToSources[itemID] = indexes.itemToSources[itemID] or {}
                    indexes.itemToDungeons[itemID] = indexes.itemToDungeons[itemID] or {}
                    indexes.itemSourcesBySpec[specID][itemID] = indexes.itemSourcesBySpec[specID][itemID] or {}

                    local specSeen, sourceSeen, dungeonSeen, itemSpecSourceSeen = {}, {}, {}, {}
                    for _, value in ipairs(indexes.itemToSpecs[itemID]) do specSeen[value] = true end
                    for _, value in ipairs(indexes.itemToSources[itemID]) do sourceSeen[value] = true end
                    for _, value in ipairs(indexes.itemToDungeons[itemID]) do dungeonSeen[value] = true end
                    for _, value in ipairs(indexes.itemSourcesBySpec[specID][itemID]) do itemSpecSourceSeen[value] = true end
                    AddUniqueNumber(indexes.itemToSpecs[itemID], specSeen, specID)
                    AddUniqueNumber(indexes.itemToSources[itemID], sourceSeen, sourceID)
                    AddUniqueNumber(indexes.itemSourcesBySpec[specID][itemID], itemSpecSourceSeen, sourceID)
                    if source and source.sourceType == "Dungeon" then
                        AddUniqueNumber(indexes.itemToDungeons[itemID], dungeonSeen, sourceID)
                    end

                    local slot = Mapping.NormalizeSlotName(item.slot)
                    AddUnique(indexes.slotsBySpec[specID], specSlotSeen, slot)
                    AddUnique(indexes.slotList, slotSeen, slot)
                end
            end
        end

        SortNumbers(indexes.sourcesBySpec[specID])
        SortNumbers(indexes.dungeonsBySpec[specID])
        SortNumbers(indexes.raidsBySpec[specID])
        table.sort(indexes.slotsBySpec[specID])
        for _, sourceIDs in pairs(indexes.itemSourcesBySpec[specID]) do SortNumbers(sourceIDs) end
    end

    for _, values in pairs(indexes.itemToSpecs) do SortNumbers(values) end
    for _, values in pairs(indexes.itemToSources) do SortNumbers(values) end
    for _, values in pairs(indexes.itemToDungeons) do SortNumbers(values) end
    table.sort(indexes.slotList)
    Mapping.indexes = indexes
    return indexes
end

function Mapping.ClearIndexes()
    Mapping.indexes = nil
end

function Mapping.GetSeasonInfo()
    local db = DB()
    if not db then return nil end
    return {
        expansion = db.expansion,
        expansionID = db.expansionID,
        season = db.season,
        mnSeason = db.mnSeason or db.season,
        seasonName = db.seasonName,
        seasonKey = db.seasonKey,
        schemaVersion = db.schemaVersion,
    }
end

function Mapping.GetSource(sourceID)
    local db = DB()
    sourceID = tonumber(sourceID)
    return db and db.sources and sourceID and db.sources[sourceID] or nil
end

function Mapping.GetSourceList(sourceType)
    local indexes = Mapping.BuildIndexes()
    if not indexes then return {} end
    sourceType = NormalizeSourceType(sourceType)
    if sourceType == "Dungeon" then return indexes.dungeonList end
    if sourceType == "Raid" then return indexes.raidList end
    return indexes.sourceList
end

function Mapping.GetSourceListForSpec(specID, sourceType)
    local db = DB()
    local indexes = Mapping.BuildIndexes()
    specID = tonumber(specID)
    if not db or not indexes or not specID then return {} end
    sourceType = NormalizeSourceType(sourceType)
    local out = {}
    for _, sourceID in ipairs(indexes.sourcesBySpec[specID] or {}) do
        local source = db.sources and db.sources[sourceID]
        if source and (not sourceType or source.sourceType == sourceType) then
            table.insert(out, {
                sourceID = sourceID,
                name = source.name or source.sourceName or tostring(sourceID),
                sourceName = source.sourceName or source.name or tostring(sourceID),
                sourceType = source.sourceType,
                mapID = source.mapID,
                instanceID = source.instanceID,
                repeatable = source.repeatable == true,
            })
        end
    end
    SortByName(out)
    return out
end

function Mapping.GetDungeonList()
    return Mapping.GetSourceList("Dungeon")
end

function Mapping.GetRaidList()
    return Mapping.GetSourceList("Raid")
end

function Mapping.GetDungeonListForSpec(specID)
    local out = Mapping.GetSourceListForSpec(specID, "Dungeon")
    for _, source in ipairs(out) do source.mapID = tonumber(source.mapID) or tonumber(source.sourceID) end
    return out
end

function Mapping.GetSpecList(classID)
    local indexes = Mapping.BuildIndexes()
    if not indexes then return {} end
    classID = tonumber(classID)
    return classID and (indexes.specsByClass[classID] or {}) or (indexes.specList or {})
end

function Mapping.GetSlotList(specID, classID)
    local indexes = Mapping.BuildIndexes()
    if not indexes then return {} end
    specID = tonumber(specID)
    classID = tonumber(classID)
    if specID and indexes.slotsBySpec[specID] then return indexes.slotsBySpec[specID] end
    if classID and indexes.specsByClass[classID] then
        local out, seen = {}, {}
        for _, spec in ipairs(indexes.specsByClass[classID]) do
            for _, slot in ipairs(indexes.slotsBySpec[tonumber(spec.specID)] or {}) do AddUnique(out, seen, slot) end
        end
        table.sort(out)
        return out
    end
    return indexes.slotList or {}
end

function Mapping.IsItemEligibleForSpec(itemOrItemID, specID)
    local db = DB()
    local item = type(itemOrItemID) == "table" and itemOrItemID or (db and db.items and db.items[tonumber(itemOrItemID)])
    specID = tonumber(specID)
    if not item then return false end
    if not specID or specID == 0 then return true end
    return type(item.specs) ~= "table" or item.specs[specID] == true
end

function Mapping.IsItemEligibleForClass(itemOrItemID, classID)
    local db = DB()
    local item = type(itemOrItemID) == "table" and itemOrItemID or (db and db.items and db.items[tonumber(itemOrItemID)])
    classID = tonumber(classID)
    if not item then return false end
    if not classID or classID == 0 then return true end
    if item.classIDs and item.classIDs[classID] == true then return true end
    for specID in pairs(item.specs or {}) do
        local spec = db and db.specs and db.specs[specID]
        if spec and tonumber(spec.classID) == classID then return true end
    end
    return false
end

function Mapping.IsCurrentSeasonItem(itemOrItemID, season)
    local db = DB()
    local item = type(itemOrItemID) == "table" and itemOrItemID or (db and db.items and db.items[tonumber(itemOrItemID)])
    season = tonumber(season or (db and (db.mnSeason or db.season)))
    if not item or not season then return false end
    return tonumber(item.mnSeason or db.mnSeason or db.season) == season
end

function Mapping.GetItemStats(itemOrItemID, specID)
    local db = DB()
    local itemID = type(itemOrItemID) == "table" and tonumber(itemOrItemID.itemID) or tonumber(itemOrItemID)
    specID = tonumber(specID)
    if db and db.statsBySpec and itemID and specID and db.statsBySpec[itemID] then
        return db.statsBySpec[itemID][specID] or {}
    end
    local item = type(itemOrItemID) == "table" and itemOrItemID or (db and db.items and db.items[itemID])
    return item and item.stats or {}
end

function Mapping.GetDisplayStatText(itemOrItemID, specID)
    local db = DB()
    local itemID = type(itemOrItemID) == "table" and tonumber(itemOrItemID.itemID) or tonumber(itemOrItemID)
    specID = tonumber(specID)
    if db and db.statTextBySpec and itemID and specID and db.statTextBySpec[itemID] then
        local text = db.statTextBySpec[itemID][specID]
        if text and text ~= "" then return text end
    end
    local item = type(itemOrItemID) == "table" and itemOrItemID or (db and db.items and db.items[itemID])
    return item and item.statText and item.statText ~= "" and item.statText or "-"
end

function Mapping.ResolvePrimaryStat(itemOrItemID, specID)
    local stats = Mapping.GetItemStats(itemOrItemID, specID)
    for _, stat in ipairs({ "Agi", "Int", "Str" }) do
        if tonumber(stats and stats[stat]) and tonumber(stats[stat]) > 0 then return stat end
    end
    return nil
end

function Mapping.IsDualWieldEligible(itemOrItemID, specID)
    local db = DB()
    local itemID = type(itemOrItemID) == "table" and tonumber(itemOrItemID.itemID) or tonumber(itemOrItemID)
    specID = tonumber(specID)
    return db and db.dualWieldBySpec and itemID and specID
        and db.dualWieldBySpec[itemID] and db.dualWieldBySpec[itemID][specID] == true or false
end

function Mapping.GetEligibleSlotInstances(itemOrItemID, specID)
    local db = DB()
    local item = type(itemOrItemID) == "table" and itemOrItemID or (db and db.items and db.items[tonumber(itemOrItemID)])
    if not item or not Mapping.IsItemEligibleForSpec(item, specID) then return {} end
    local slot = Mapping.NormalizeSlotName(item.slot)
    if slot == "Finger" then return { "Finger 1", "Finger 2" } end
    if slot == "Trinket" then return { "Trinket 1", "Trinket 2" } end
    if slot == "Off Hand" then return { "Off Hand" } end
    if slot == "One-Hand" or slot == "Two-Hand" then
        if Mapping.IsDualWieldEligible(item, specID) then return { "Main Hand", "Off Hand" } end
        return { "Main Hand" }
    end
    if slot == "Ranged" then return { "Main Hand" } end
    if slot == "Shoulders" then return { "Shoulders" } end
    return slot ~= "" and { slot } or {}
end

function Mapping.GetItemSpecs(itemID)
    local indexes = Mapping.BuildIndexes()
    return indexes and indexes.itemToSpecs and indexes.itemToSpecs[tonumber(itemID)] or {}
end

function Mapping.GetItemSources(itemID, specID, sourceType)
    local db = DB()
    local indexes = Mapping.BuildIndexes()
    itemID = tonumber(itemID)
    specID = tonumber(specID)
    sourceType = NormalizeSourceType(sourceType)
    if not db or not indexes or not itemID then return {} end
    local sourceIDs = specID and indexes.itemSourcesBySpec[specID] and indexes.itemSourcesBySpec[specID][itemID]
        or indexes.itemToSources[itemID] or {}
    local out = {}
    for _, sourceID in ipairs(sourceIDs) do
        local source = db.sources and db.sources[sourceID]
        if source and (not sourceType or source.sourceType == sourceType) then
            table.insert(out, source)
        end
    end
    SortByName(out)
    return out
end

function Mapping.GetItemDungeons(itemID)
    local indexes = Mapping.BuildIndexes()
    return indexes and indexes.itemToDungeons and indexes.itemToDungeons[tonumber(itemID)] or {}
end

local function WithDisplaySource(item, sourceID, specID, classID, sourceType)
    if not item then return nil end
    local db = DB()
    local out = CopyTable(item)
    out.slot = Mapping.NormalizeSlotName(item.slot)
    out.resolvedSpecID = tonumber(specID)
    out.resolvedClassID = tonumber(classID) or GetClassIDForSpec(specID)
    out.specID = tonumber(specID)
    out.specName = GetSpecName(specID)
    out.classID = out.resolvedClassID
    out.displayStatText = Mapping.GetDisplayStatText(item, specID)
    out.statText = out.displayStatText
    out.stats = Mapping.GetItemStats(item, specID)
    out.resolvedPrimaryStat = Mapping.ResolvePrimaryStat(item, specID)
    out.dualWieldEligible = Mapping.IsDualWieldEligible(item, specID)
    out.mnSeason = tonumber(item.mnSeason or (db and (db.mnSeason or db.season)))

    sourceID = tonumber(sourceID)
    sourceType = NormalizeSourceType(sourceType)
    local sources = {}
    if sourceID and item.sources and item.sources[sourceID] then
        local source = db and db.sources and db.sources[sourceID]
        if source then table.insert(sources, source) end
    else
        sources = Mapping.GetItemSources(item.itemID, specID, sourceType)
    end

    local sourceNames, sourceIDs, sourceTypes = {}, {}, {}
    local nameSeen, idSeen, typeSeen = {}, {}, {}
    for _, source in ipairs(sources) do
        local id = tonumber(source.sourceID or source.mapID or source.instanceID)
        local name = source.sourceName or source.name or tostring(id or "")
        AddUnique(sourceNames, nameSeen, name)
        AddUniqueNumber(sourceIDs, idSeen, id)
        AddUnique(sourceTypes, typeSeen, source.sourceType)
    end
    table.sort(sourceNames)
    SortNumbers(sourceIDs)
    table.sort(sourceTypes)
    out.sourceNames = sourceNames
    out.sourceIDs = sourceIDs
    out.sourceTypes = sourceTypes
    out.sourceName = table.concat(sourceNames, ", ")
    out.sourceID = #sourceIDs == 1 and sourceIDs[1] or sourceID
    out.sourceType = #sourceTypes == 1 and sourceTypes[1] or nil
    out.sourceNameNormalized = out.sourceName
    out.sourceTypeNormalized = out.sourceType
    out.dungeonName = out.sourceName -- compatibility until the Gear Targets UI is rebuilt
    if out.sourceType == "Raid" then out.raidName = out.sourceName end
    return out
end

function Mapping.GetItem(itemID, displaySpecID, classID, sourceID)
    local db = DB()
    local item = db and db.items and db.items[tonumber(itemID)]
    return item and WithDisplaySource(item, sourceID, displaySpecID, classID) or nil
end

function Mapping.GetItemsForSpecSource(specID, sourceID)
    local db = DB()
    specID = tonumber(specID)
    sourceID = tonumber(sourceID)
    if not db or not specID or not sourceID then return {} end
    local out = {}
    for _, itemID in ipairs((db.bySpec and db.bySpec[specID] and db.bySpec[specID][sourceID]) or {}) do
        local item = db.items and db.items[itemID]
        if item then table.insert(out, WithDisplaySource(item, sourceID, specID)) end
    end
    table.sort(out, function(a, b)
        if tostring(a.slot or "") ~= tostring(b.slot or "") then return tostring(a.slot or "") < tostring(b.slot or "") end
        return SearchText(a.name) < SearchText(b.name)
    end)
    return out
end

function Mapping.GetItemsForSpecDungeon(specID, mapID)
    return Mapping.GetItemsForSpecSource(specID, mapID)
end

local function SelectedStatsMatch(item, specID, primaryStats, secondaryStats)
    local stats = Mapping.GetItemStats(item, specID)
    for stat, enabled in pairs(primaryStats or {}) do
        if enabled and PRIMARY_STATS[stat] and (tonumber(stats and stats[stat]) or 0) <= 0 then return false end
    end
    for stat, enabled in pairs(secondaryStats or {}) do
        if enabled and SECONDARY_STATS[stat] and (tonumber(stats and stats[stat]) or 0) <= 0 then return false end
    end
    return true
end

local function ItemMatchesSearch(item, searchText)
    local search = SearchText(searchText)
    if search == "" then return true end
    return string.find(SearchText(item and item.name), search, 1, true) ~= nil
        or string.find(SearchText(item and item.itemNameClean), search, 1, true) ~= nil
        or string.find(SearchText(item and item.link), search, 1, true) ~= nil
end

local function ItemHasSourceType(itemID, specID, sourceType)
    if not sourceType then return true end
    for _, source in ipairs(Mapping.GetItemSources(itemID, specID, sourceType)) do
        if source.sourceType == sourceType then return true end
    end
    return false
end

local function ItemIsNonGear(item)
    if not item then return true end
    if item.equipLoc == "INVTYPE_NON_EQUIP_IGNORE" then return true end
    return item.slot == nil or item.slot == ""
end

function Mapping.GetFilteredItems(filters)
    local db = DB()
    local indexes = Mapping.BuildIndexes()
    if not db or not indexes then return {} end
    filters = filters or {}

    local specID = tonumber(filters.specID)
    local classID = tonumber(filters.classID)
    local sourceID = tonumber(filters.sourceID or filters.mapID)
    local sourceType = NormalizeSourceType(filters.sourceType or filters.itemType)
    local season = tonumber(filters.mnSeason or filters.season or db.mnSeason or db.season)
    local slot = Mapping.NormalizeSlotName(filters.slot)
    local primaryStats = filters.primaryStats or {}
    if filters.primaryStat and filters.primaryStat ~= "" and filters.primaryStat ~= "All" then
        primaryStats = CopyTable(primaryStats)
        primaryStats[filters.primaryStat] = true
    end
    local secondaryStats = filters.secondaryStats or {}
    local includeNonGear = filters.includeNonGear ~= false
    local out, seen = {}, {}

    local function Consider(itemID)
        itemID = tonumber(itemID)
        if not itemID or seen[itemID] then return end
        local item = db.items and db.items[itemID]
        if not item then return end
        if specID and not Mapping.IsItemEligibleForSpec(item, specID) then return end
        if classID and not specID and not Mapping.IsItemEligibleForClass(item, classID) then return end
        if season and not Mapping.IsCurrentSeasonItem(item, season) then return end
        if sourceID and not (item.sources and item.sources[sourceID]) then return end
        if sourceType and not ItemHasSourceType(itemID, specID, sourceType) then return end
        local normalizedSlot = Mapping.NormalizeSlotName(item.slot)
        if slot and slot ~= "" and slot ~= "All" and normalizedSlot ~= slot then return end
        if not includeNonGear and ItemIsNonGear(item) then return end
        if not ItemMatchesSearch(item, filters.searchText) then return end
        if not SelectedStatsMatch(item, specID, primaryStats, secondaryStats) then return end
        seen[itemID] = true
        table.insert(out, WithDisplaySource(item, sourceID, specID, classID, sourceType))
    end

    if specID and sourceID then
        for _, itemID in ipairs((db.bySpec and db.bySpec[specID] and db.bySpec[specID][sourceID]) or {}) do Consider(itemID) end
    elseif specID then
        for candidateSourceID, itemIDs in pairs((db.bySpec and db.bySpec[specID]) or {}) do
            local source = db.sources and db.sources[tonumber(candidateSourceID)]
            if not sourceType or (source and source.sourceType == sourceType) then
                for _, itemID in ipairs(itemIDs or {}) do Consider(itemID) end
            end
        end
    elseif classID then
        for _, spec in ipairs(indexes.specsByClass[classID] or {}) do
            local candidateSpecID = tonumber(spec.specID)
            if sourceID then
                for _, itemID in ipairs((db.bySpec[candidateSpecID] and db.bySpec[candidateSpecID][sourceID]) or {}) do Consider(itemID) end
            else
                for candidateSourceID, itemIDs in pairs(db.bySpec[candidateSpecID] or {}) do
                    local source = db.sources and db.sources[tonumber(candidateSourceID)]
                    if not sourceType or (source and source.sourceType == sourceType) then
                        for _, itemID in ipairs(itemIDs or {}) do Consider(itemID) end
                    end
                end
            end
        end
    elseif sourceID then
        for itemID in pairs(indexes.itemsBySource[sourceID] or {}) do Consider(itemID) end
    else
        for itemID in pairs(db.items or {}) do Consider(itemID) end
    end

    table.sort(out, function(a, b)
        if tostring(a.sourceName or "") ~= tostring(b.sourceName or "") then return tostring(a.sourceName or "") < tostring(b.sourceName or "") end
        if tostring(a.slot or "") ~= tostring(b.slot or "") then return tostring(a.slot or "") < tostring(b.slot or "") end
        return SearchText(a.name) < SearchText(b.name)
    end)
    return out
end

function Mapping.GetMatcherCandidates(specID, itemType, season)
    specID = tonumber(specID)
    if not specID then return {} end
    local out = {}
    for _, item in ipairs(Mapping.GetFilteredItems({
        specID = specID,
        itemType = itemType,
        season = season,
        includeNonGear = false,
    })) do
        local stats = Mapping.GetItemStats(item, specID)
        local secondaryTotal = 0
        for stat in pairs(SECONDARY_STATS) do secondaryTotal = secondaryTotal + (tonumber(stats and stats[stat]) or 0) end
        if secondaryTotal > 0 then
            item.matcherStats = stats
            item.eligibleSlotInstances = Mapping.GetEligibleSlotInstances(item, specID)
            table.insert(out, item)
        end
    end
    return out
end

function Mapping.GetCatalystSourcesForSlot(specID, slotInstance, season)
    local db = DB()
    specID = tonumber(specID)
    season = tonumber(season or (db and (db.mnSeason or db.season)))
    local baseSlot = Mapping.GetBaseSlotName(slotInstance)
    if not db or not specID or not CATALYST_SLOT_BASES[baseSlot] then return {} end
    local wantedSlot = baseSlot == "Shoulders" and "Shoulders" or baseSlot
    local out, seen = {}, {}
    -- Dungeon items can become Tier through the Catalyst, while Raid items
    -- can provide direct Hero/Myth replacements. Keep both visible.
    for _, source in ipairs(Mapping.GetSourceListForSpec(specID)) do
        for _, item in ipairs(Mapping.GetItemsForSpecSource(specID, source.sourceID)) do
            if Mapping.NormalizeSlotName(item.slot) == wantedSlot and Mapping.IsCurrentSeasonItem(item, season) then
                if not seen[source.sourceID] then
                    seen[source.sourceID] = true
                    table.insert(out, source)
                end
                break
            end
        end
    end
    SortByName(out)
    return out
end

function Mapping.IsItemForSpecSource(itemID, specID, sourceID)
    return IsItemInSpecSource(itemID, specID, sourceID)
end

function Mapping.IsItemForSpecDungeon(itemID, specID, mapID)
    return IsItemInSpecSource(itemID, specID, mapID)
end

function Mapping.GetTargetSummaryForDungeon(trackedItems, mapID, specID)
    local summary = { thisDungeon = {}, otherDungeons = {}, totalTargets = 0 }
    if type(trackedItems) ~= "table" then return summary end
    local db = DB()
    local indexes = Mapping.BuildIndexes()
    mapID = tonumber(mapID)
    specID = tonumber(specID)
    if not db or not indexes or not mapID then return summary end
    local otherCounts = {}

    for itemID, enabled in pairs(trackedItems) do
        itemID = tonumber(itemID)
        if enabled and itemID then
            local item = db.items and db.items[itemID]
            if item then
                summary.totalTargets = summary.totalTargets + 1
                local belongs = IsItemInSpecSource(itemID, specID, mapID)
                if belongs then table.insert(summary.thisDungeon, WithDisplaySource(item, mapID, specID)) end
                for _, otherMapID in ipairs(indexes.itemToDungeons[itemID] or {}) do
                    if otherMapID ~= mapID and (not specID or IsItemInSpecSource(itemID, specID, otherMapID)) then
                        local source = db.dungeons and db.dungeons[otherMapID]
                        local name = source and (source.name or source.sourceName) or tostring(otherMapID)
                        otherCounts[name] = (otherCounts[name] or 0) + 1
                    end
                end
            end
        end
    end

    for dungeonName, count in pairs(otherCounts) do
        table.insert(summary.otherDungeons, { dungeonName = dungeonName, count = count })
    end
    table.sort(summary.thisDungeon, function(a, b) return SearchText(a.name) < SearchText(b.name) end)
    table.sort(summary.otherDungeons, function(a, b) return tostring(a.dungeonName) < tostring(b.dungeonName) end)
    return summary
end

Mapping.BuildIndexes()
return Mapping
