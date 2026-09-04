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
local EQUIPMENT_PRIMARY_STATS = { Agi = true, Int = true, Str = true }
local INTELLECT_SPECS = {
    [62] = true, [63] = true, [64] = true, [65] = true, [102] = true, [105] = true,
    [256] = true, [257] = true, [258] = true, [262] = true, [264] = true,
    [265] = true, [266] = true, [267] = true, [270] = true,
    [1467] = true, [1468] = true, [1473] = true, [1480] = true,
}
local AGILITY_SPECS = {
    [103] = true, [104] = true, [253] = true, [254] = true, [255] = true,
    [259] = true, [260] = true, [261] = true, [263] = true, [268] = true,
    [269] = true, [577] = true, [581] = true,
}
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

local function RaidAcronym(raidName)
    local letters = {}
    for word in tostring(raidName or ""):gmatch("%S+") do
        local letter = word:match("[%w]")
        if letter then table.insert(letters, string.upper(letter)) end
    end
    return table.concat(letters)
end

local function RaidDropDisplayName(item, sourceID, source)
    if not item or not source or source.sourceType ~= "Raid" then return nil end
    sourceID = tonumber(sourceID)
    local itemSource = sourceID and item.sources and item.sources[sourceID]
    local encounterIDs = itemSource and itemSource.encounterIDs or {}
    if #encounterIDs == 0 then return nil end

    local raidMapping = KeyLab.Mapping and KeyLab.Mapping.Raids
    local instanceID = tonumber(source.instanceID) or tonumber(source.sourceID) or sourceID
    local raid = raidMapping and raidMapping.GetInstance and raidMapping.GetInstance(instanceID)
    if not raid then return nil end

    local raidName = raid.name or source.sourceName or source.name or tostring(sourceID or "")
    local acronym = RaidAcronym(raidName)
    local labels, seen = {}, {}
    for _, encounterID in ipairs(encounterIDs) do
        local bossName = raid.encounterNames and raid.encounterNames[tonumber(encounterID)]
        if bossName then
            local label = tostring(bossName) .. (acronym ~= "" and (" - " .. acronym) or "")
            if not seen[label] then
                seen[label] = true
                table.insert(labels, label)
            end
        end
    end
    table.sort(labels)
    return #labels > 0 and table.concat(labels, ", ") or nil
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

local function ItemHasEncounter(item, sourceID, encounterID)
    sourceID = tonumber(sourceID)
    encounterID = tonumber(encounterID)
    if not item or not encounterID then return false end

    for candidateSourceID, itemSource in pairs(item.sources or {}) do
        candidateSourceID = tonumber(candidateSourceID)
        if not sourceID or candidateSourceID == sourceID then
            for _, candidateEncounterID in ipairs(itemSource and itemSource.encounterIDs or {}) do
                if tonumber(candidateEncounterID) == encounterID then return true end
            end
        end
    end
    return false
end

function Mapping.ItemHasEncounter(itemOrItemID, sourceID, encounterID)
    local db = DB()
    local item = type(itemOrItemID) == "table" and itemOrItemID or (db and db.items and db.items[tonumber(itemOrItemID)])
    return ItemHasEncounter(item, sourceID, encounterID)
end

function Mapping.GetRaidBossListForSpec(specID)
    local db = DB()
    local indexes = Mapping.BuildIndexes()
    specID = tonumber(specID)
    if not db or not indexes or not specID then return {} end

    local out = {}
    local raidMapping = KeyLab.Mapping and KeyLab.Mapping.Raids
    for _, sourceID in ipairs(indexes.raidsBySpec[specID] or {}) do
        local source = db.sources and db.sources[sourceID]
        local instanceID = source and (tonumber(source.instanceID) or tonumber(source.sourceID)) or tonumber(sourceID)
        local raid = raidMapping and raidMapping.GetInstance and raidMapping.GetInstance(instanceID)
        if raid then
            local encounterHasLoot = {}
            for _, itemID in ipairs((db.bySpec and db.bySpec[specID] and db.bySpec[specID][sourceID]) or {}) do
                local item = db.items and db.items[tonumber(itemID)]
                local itemSource = item and item.sources and item.sources[sourceID]
                for _, encounterID in ipairs(itemSource and itemSource.encounterIDs or {}) do
                    encounterHasLoot[tonumber(encounterID)] = true
                end
            end

            for encounterID, bossName in pairs(raid.encounterNames or {}) do
                encounterID = tonumber(encounterID)
                if encounterHasLoot[encounterID] then
                    local raidName = raid.name or source.sourceName or source.name or tostring(sourceID)
                    table.insert(out, {
                        sourceID = tonumber(sourceID),
                        instanceID = instanceID,
                        encounterID = encounterID,
                        bossName = bossName,
                        raidName = raidName,
                        text = tostring(bossName) .. " - " .. tostring(raidName),
                    })
                end
            end
        end
    end

    table.sort(out, function(a, b)
        if tostring(a.raidName or "") ~= tostring(b.raidName or "") then
            return tostring(a.raidName or "") < tostring(b.raidName or "")
        end
        if tostring(a.bossName or "") ~= tostring(b.bossName or "") then
            return tostring(a.bossName or "") < tostring(b.bossName or "")
        end
        return tonumber(a.encounterID or 0) < tonumber(b.encounterID or 0)
    end)
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

local function ClassLootList(classID, method, sourceType)
    local out, seen = {}, {}
    for _, spec in ipairs(Mapping.GetSpecList(classID)) do
        for _, row in ipairs(method(spec.specID, sourceType)) do
            local key = tostring(row.sourceID) .. ":" .. tostring(row.encounterID or "")
            if not seen[key] then seen[key]=true; table.insert(out,row) end
        end
    end
    table.sort(out, function(a,b) return tostring(a.text or a.sourceName or a.name) < tostring(b.text or b.sourceName or b.name) end)
    return out
end

function Mapping.GetSourceListForClass(classID, sourceType)
    return ClassLootList(classID, Mapping.GetSourceListForSpec, sourceType)
end

function Mapping.GetRaidBossListForClass(classID)
    return ClassLootList(classID, Mapping.GetRaidBossListForSpec)
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

-- Loot eligibility and a player's saved plan are different questions. Keep
-- IsItemEligibleForSpec remains unchanged for captured loot filters.
function Mapping.GetLootSpecsForClass(itemOrItemID, specID)
    local db = DB()
    local item = type(itemOrItemID) == "table" and itemOrItemID or (db and db.items and db.items[tonumber(itemOrItemID)])
    local classID = GetClassIDForSpec(specID)
    local out = {}
    if not item or not classID then return out end
    for id, eligible in pairs(item.specs or {}) do
        if eligible == true and GetClassIDForSpec(id) == classID then
            table.insert(out, {specID=tonumber(id), name=GetSpecName(id) or tostring(id)})
        end
    end
    table.sort(out, function(a,b) return a.name < b.name end)
    return out
end

function Mapping.GetLootSpecGuidance(itemOrItemID, specID)
    local specs = Mapping.GetLootSpecsForClass(itemOrItemID, specID)
    if #specs == 0 then return nil end -- No captured eligibility is not a claim about in-game loot.
    local lootID
    if GetLootSpecialization then
        local ok, value = pcall(GetLootSpecialization)
        if ok and not (issecretvalue and issecretvalue(value)) and type(value) == "number" then
            lootID = value == 0 and tonumber(specID) or value
        end
    end
    local names, matches = {}, false
    for _, spec in ipairs(specs) do
        names[#names+1] = spec.name
        if spec.specID == lootID then matches = true end
    end
    local warning = lootID and not matches or false
    local text = "Captured loot specs: " .. table.concat(names, ", ") .. "."
    text = text .. (lootID and ("\nCurrent loot spec: " .. (GetSpecName(lootID) or tostring(lootID)) .. ".")
        or "\nYour current loot specialization could not be read. Check it before seeking this item.")
    if warning then text = text .. "\nFor spec-filtered loot, choose one of the listed loot specs before seeking this item." end
    text = text .. "\nRight-click your character portrait > Loot Specialization. This does not change your active talents."
        .. "\nLoot eligibility is not a recommendation for your active spec. Check the item's stats and effects; raid loot rules may differ."
    return {warning=warning, names=table.concat(names, ", "), text=text, lootSpecID=lootID}
end

function Mapping.IsCurrentSeasonItem(itemOrItemID, season)
    local db = DB()
    local item = type(itemOrItemID) == "table" and itemOrItemID or (db and db.items and db.items[tonumber(itemOrItemID)])
    season = tonumber(season or (db and (db.mnSeason or db.season)))
    if not item or not season then return false end
    return tonumber(item.mnSeason or db.mnSeason or db.season) == season
end

function Mapping.GetPrimaryStatForSpec(specID)
    specID = tonumber(specID)
    if not specID then return nil end
    if INTELLECT_SPECS[specID] then return "Int" end
    if AGILITY_SPECS[specID] then return "Agi" end
    return "Str"
end

local function NormalizePrimaryStats(stats, specID)
    if type(stats) ~= "table" then return {} end
    local expected = Mapping.GetPrimaryStatForSpec(specID)
    if not expected then return stats end

    local primaryValue = 0
    for stat in pairs(EQUIPMENT_PRIMARY_STATS) do
        primaryValue = math.max(primaryValue, tonumber(stats[stat]) or 0)
    end
    if primaryValue <= 0 then return stats end
    if (tonumber(stats[expected]) or 0) == primaryValue then
        local alreadyCorrect = true
        for stat in pairs(EQUIPMENT_PRIMARY_STATS) do
            if stat ~= expected and (tonumber(stats[stat]) or 0) > 0 then alreadyCorrect = false end
        end
        if alreadyCorrect then return stats end
    end

    local normalized = CopyTable(stats)
    for stat in pairs(EQUIPMENT_PRIMARY_STATS) do normalized[stat] = nil end
    normalized[expected] = primaryValue
    return normalized
end

function Mapping.GetItemStats(itemOrItemID, specID)
    local db = DB()
    local itemID = type(itemOrItemID) == "table" and tonumber(itemOrItemID.itemID) or tonumber(itemOrItemID)
    specID = tonumber(specID)
    if db and db.statsBySpec and itemID and specID and db.statsBySpec[itemID] then
        return NormalizePrimaryStats(db.statsBySpec[itemID][specID] or {}, specID)
    end
    local item = type(itemOrItemID) == "table" and itemOrItemID or (db and db.items and db.items[itemID])
    return NormalizePrimaryStats(item and item.stats or {}, specID)
end

function Mapping.GetDisplayStatText(itemOrItemID, specID)
    local db = DB()
    local itemID = type(itemOrItemID) == "table" and tonumber(itemOrItemID.itemID) or tonumber(itemOrItemID)
    specID = tonumber(specID)
    local text
    if db and db.statTextBySpec and itemID and specID and db.statTextBySpec[itemID] then
        text = db.statTextBySpec[itemID][specID]
    end
    local item = type(itemOrItemID) == "table" and itemOrItemID or (db and db.items and db.items[itemID])
    if not text or text == "" then text = item and item.statText or "" end

    local stats = Mapping.GetItemStats(itemOrItemID, specID)
    local expected = Mapping.GetPrimaryStatForSpec(specID)
    if expected and (tonumber(stats and stats[expected]) or 0) > 0 then
        local parts, sawPrimary = {}, false
        for token in tostring(text or ""):gmatch("[^,]+") do
            token = token:gsub("^%s+", ""):gsub("%s+$", "")
            local shortToken = token == "Agility" and "Agi"
                or token == "Intellect" and "Int"
                or token == "Strength" and "Str"
                or token
            if EQUIPMENT_PRIMARY_STATS[shortToken] then
                if not sawPrimary then
                    table.insert(parts, expected)
                    sawPrimary = true
                end
            elseif token ~= "" then
                table.insert(parts, token)
            end
        end
        if not sawPrimary then table.insert(parts, 1, expected) end
        text = table.concat(parts, ", ")
    end

    return text and text ~= "" and text or "-"
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

function Mapping.GetTargetSlotInstances(itemOrItemID, specID)
    local db = DB()
    local item = type(itemOrItemID) == "table" and itemOrItemID or (db and db.items and db.items[tonumber(itemOrItemID)])
    if not item then return {} end
    if item.sourceType == "Owned" then return Mapping.GetEligibleSlotInstances(item, specID) end
    local classID = GetClassIDForSpec(specID)
    if not classID or not Mapping.IsItemEligibleForClass(item, classID) then return {} end
    local slot = Mapping.NormalizeSlotName(item.slot)
    if slot == "Finger" then return {"Finger 1", "Finger 2"} end
    if slot == "Trinket" then return {"Trinket 1", "Trinket 2"} end
    if slot == "One-Hand" or slot == "Two-Hand" then
        if Mapping.IsTargetDualWieldEligible(item, specID) then return {"Main Hand", "Off Hand"} end
        return {"Main Hand"}
    end
    if slot == "Ranged" then return {"Main Hand"} end
    -- In particular, do not reinterpret an explicitly Main-Hand-only item.
    return slot ~= "" and {slot} or {}
end

function Mapping.IsTargetDualWieldEligible(itemOrItemID, specID)
    if Mapping.IsDualWieldEligible(itemOrItemID, specID) then return true end
    local db = DB()
    local item = type(itemOrItemID) == "table" and itemOrItemID or (db and db.items and db.items[tonumber(itemOrItemID)])
    if not item then return false end
    local slot = Mapping.NormalizeSlotName(item.slot)
    -- The existing captured rules already establish which specs dual-wield.
    -- Extend that ability to generic one-hand items available to their class,
    -- without granting it to a healer/caster just because another spec has it.
    if slot == "One-Hand" and (not item.equipLoc or item.equipLoc == "INVTYPE_WEAPON") then
        for id, specs in pairs(db.dualWieldBySpec or {}) do
            local known = db.items[id]
            if specs[tonumber(specID)] and known and Mapping.NormalizeSlotName(known.slot) == "One-Hand" then return true end
        end
    end
    -- Fury's Titan's Grip also supports polearms, absent from the captured
    -- off-hand map. Class-wide planning and matching share this slot rule.
    return tonumber(specID) == 72 and slot == "Two-Hand" and item.armorType == "Polearm"
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

    local sourceNames, displaySourceNames, sourceIDs, sourceTypes = {}, {}, {}, {}
    local nameSeen, displayNameSeen, idSeen, typeSeen = {}, {}, {}, {}
    for _, source in ipairs(sources) do
        local id = tonumber(source.sourceID or source.mapID or source.instanceID)
        local name = source.sourceName or source.name or tostring(id or "")
        AddUnique(sourceNames, nameSeen, name)
        AddUnique(displaySourceNames, displayNameSeen, RaidDropDisplayName(item, id, source) or name)
        AddUniqueNumber(sourceIDs, idSeen, id)
        AddUnique(sourceTypes, typeSeen, source.sourceType)
    end
    table.sort(sourceNames)
    table.sort(displaySourceNames)
    SortNumbers(sourceIDs)
    table.sort(sourceTypes)
    out.sourceNames = sourceNames
    out.displaySourceNames = displaySourceNames
    out.sourceIDs = sourceIDs
    out.sourceTypes = sourceTypes
    out.sourceName = table.concat(sourceNames, ", ")
    out.displaySourceName = table.concat(displaySourceNames, ", ")
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
    if not item and KeyLab.GuideRecommendations then
        item = KeyLab.GuideRecommendations.GetSupplementalItem(itemID)
        if item and Mapping.IsItemEligibleForSpec(item, displaySpecID) then return item end
        return nil
    end
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
    local displaySpecID = specID
    if filters.browseClass then specID = nil end
    local classID = tonumber(filters.classID)
    local sourceID = tonumber(filters.sourceID or filters.mapID)
    local encounterID = tonumber(filters.encounterID)
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
        if encounterID and not ItemHasEncounter(item, sourceID, encounterID) then return end
        if sourceType and not ItemHasSourceType(itemID, specID, sourceType) then return end
        local normalizedSlot = Mapping.NormalizeSlotName(item.slot)
        if slot and slot ~= "" and slot ~= "All" and normalizedSlot ~= slot then return end
        if not includeNonGear and ItemIsNonGear(item) then return end
        if not ItemMatchesSearch(item, filters.searchText) then return end
        if not SelectedStatsMatch(item, displaySpecID or specID, primaryStats, secondaryStats) then return end
        seen[itemID] = true
        local display = WithDisplaySource(item, sourceID, displaySpecID or specID, classID, sourceType)
        if filters.browseClass and displaySpecID and db.statsBySpec and db.statsBySpec[itemID]
            and not db.statsBySpec[itemID][displaySpecID] then
            display.displayStatText = "Check tooltip"
            display.statText = display.displayStatText
            display.statsNotCapturedForSpec = true
        end
        table.insert(out, display)
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

-- The matcher scores secondary stats, not another spec's primary stat. Use a
-- recorded same-class stat capture when this spec has no capture for the item.
-- Keep ordinary item/tooltip stat resolution untouched.
function Mapping.GetMatcherItemStats(item, specID)
    local db=DB()
    local classID=GetClassIDForSpec(specID)
    if not item or not classID or not Mapping.IsItemEligibleForClass(item,classID) then return {} end
    local captures=db.statsBySpec and db.statsBySpec[tonumber(item.itemID)]
    local stats=captures and captures[tonumber(specID)]
    if not stats and captures then
        for _,spec in ipairs(Mapping.GetLootSpecsForClass(item,specID)) do
            if captures[spec.specID] then stats=captures[spec.specID]; break end
        end
    end
    stats=stats or (db.items[tonumber(item.itemID)] or item).stats or {}
    local out={}
    for key in pairs(SECONDARY_STATS) do out[key]=tonumber(stats[key]) or 0 end
    return out
end

local MATCHER_ADAPTIVE_ARMOR = {
    Head=true, Shoulders=true, Back=true, Chest=true, Wrist=true,
    Hands=true, Waist=true, Legs=true, Feet=true,
}

local MATCHER_WEAPON_SETUPS = {
    [70] = { fixed = "two_hand", label = "Two-Handed Required" }, -- Retribution
    [71] = { fixed = "two_hand", label = "Two-Handed Required" }, -- Arms
    [252] = { fixed = "two_hand", label = "Two-Handed Required" }, -- Unholy
    [255] = { fixed = "two_hand", label = "Two-Handed Required" }, -- Survival
    [263] = { fixed = "dual_wield", label = "Dual Wield Required" }, -- Enhancement
    [251] = { choices = { "two_hand", "dual_wield" } }, -- Frost
    [268] = { choices = { "two_hand", "dual_wield" } }, -- Brewmaster
    [269] = { choices = { "two_hand", "dual_wield" } }, -- Windwalker
}

function Mapping.GetMatcherWeaponSetupConfig(specID)
    return MATCHER_WEAPON_SETUPS[tonumber(specID)]
end

function Mapping.GetMatcherWeaponSetupLabel(setup)
    return setup == "two_hand" and "Two-Handed"
        or setup == "dual_wield" and "Dual Wield" or nil
end

function Mapping.ResolveMatcherWeaponSetup(specID, selected)
    local config = Mapping.GetMatcherWeaponSetupConfig(specID)
    if not config then return nil, true end
    if config.fixed then return config.fixed, true end
    for _, value in ipairs(config.choices or {}) do
        if selected == value then return value, true end
    end
    return nil, false, "Choose Two-Handed or Dual Wield before starting the matcher."
end

-- Do not use GetItemStats here: its display normalization can relabel a
-- captured primary stat. Fixed-stat weapons must retain their real stat type.
-- Confirmed in game: this weapon adapts between Agility and Strength even
-- though its saved captures were all taken in the Strength state.
local MATCHER_ADAPTIVE_WEAPON_PRIMARIES = {
    [268209] = { Agi = true, Str = true }, -- Aman'muso, Warlord's Vengeance
}

function Mapping.MatchesMatcherPrimaryStat(item, specID, primaryStat)
    if not primaryStat or primaryStat == "none" then return true end
    if primaryStat ~= Mapping.GetPrimaryStatForSpec(specID) then return false, "different_spec_primary" end
    local db = DB()
    item = type(item) == "table" and item or db and db.items and db.items[tonumber(item)]
    if not item then return false, "unverified_primary" end
    local slot = Mapping.NormalizeSlotName(item.slot)
    -- These slots and the existing advisory trinket path are unchanged.
    if slot == "Finger" or slot == "Neck" or slot == "Trinket" then return true end
    local adaptivePrimaries = MATCHER_ADAPTIVE_WEAPON_PRIMARIES[tonumber(item.itemID)]
    if adaptivePrimaries then return adaptivePrimaries[primaryStat] == true, "different_primary" end
    local known = db and db.items and db.items[tonumber(item.itemID)]
    local available = {}
    local function Read(stats)
        for _, key in ipairs({"Agi", "Int", "Str"}) do
            if (tonumber(stats and stats[key]) or 0) > 0 then available[key] = true end
        end
    end
    if item.ownedPrimaryStats and item.ownedPrimaryStats.known then
        Read(item.ownedPrimaryStats)
    else
        Read(known and known.stats or item.stats)
        local captures = db and db.statsBySpec and db.statsBySpec[tonumber(item.itemID)]
        for _, spec in ipairs(Mapping.GetLootSpecsForClass(known or item, specID)) do
            Read(captures and captures[spec.specID])
        end
    end
    if available[primaryStat] then return true end
    -- Shared seasonal armor was often captured on another spec. Only adapt
    -- known armor recorded for this spec, never an arbitrary weapon or bag item.
    if next(available) and MATCHER_ADAPTIVE_ARMOR[slot] and known
        and Mapping.IsItemEligibleForSpec(known, specID) then return true end
    return false, next(available) and "different_primary" or "unverified_primary"
end

function Mapping.GetMatcherCandidates(specID, itemType, season, primaryStat)
    specID = tonumber(specID)
    local classID=GetClassIDForSpec(specID)
    if not classID then return {} end
    local out = {}
    for _, item in ipairs(Mapping.GetFilteredItems({
        specID = specID,
        classID = classID,
        browseClass = true,
        itemType = itemType,
        season = season,
        includeNonGear = false,
    })) do
        local stats = Mapping.GetMatcherItemStats(item, specID)
        local secondaryTotal = 0
        for stat in pairs(SECONDARY_STATS) do secondaryTotal = secondaryTotal + (tonumber(stats and stats[stat]) or 0) end
        if secondaryTotal > 0 then
            item.matcherStats = stats
            item.eligibleSlotInstances = Mapping.GetTargetSlotInstances(item, specID)
            item.dualWieldEligible = Mapping.IsTargetDualWieldEligible(item, specID)
            if #item.eligibleSlotInstances>0 and Mapping.MatchesMatcherPrimaryStat(item, specID, primaryStat) then table.insert(out, item) end
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
