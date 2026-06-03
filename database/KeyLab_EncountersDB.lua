local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.DB = KeyLab.DB or {}
KeyLab.DB.Encounters = KeyLab.DB.Encounters or {}

local EncountersDB = KeyLab.DB.Encounters

--[[
KeyLab_EncountersDB.lua

Purpose:
- Stores and retrieves individual run records.
- Owns encounter sorting, filtering, and paging helpers.
- Does NOT capture Blizzard data.
- Does NOT format UI text.
- Does NOT create UI cards/buttons.

Expected encounter shape:

encounter = {
    id = "unique-id",
    timestamp = 1234567890,
    dateText = "2026-05-25 12:34:56",

    challenge = {
        mapID = 402,
        dungeonName = "Algeth'ar Academy",
        keyLevel = 12,
        affixIDs = { 10, 152, 160 },
    },

    player = {
        playerName = "Brione",
        realm = "Stormrage",
        class = "Priest",
        spec = "Discipline",
    },

    talents = {
        talentString = "...",
    },

    stats = {
        crit = 18.5,
        haste = 28.5,
    },

    metrics = {
        damageDone = 123456,
        dps = 12345,
    },

    flags = {
        interrupted = false,
        excludedFromComparisons = false,
    },
}
]]

local function GetDB()
    if KeyLab.DB and KeyLab.DB.Get then
        return KeyLab.DB.Get()
    end

    if type(KeyLabDB) ~= "table" then
        KeyLabDB = {}
    end

    if type(KeyLabDB.encounters) ~= "table" then
        KeyLabDB.encounters = {}
    end

    return KeyLabDB
end

local function GetEncountersTable()
    local db = GetDB()

    if type(db.encounters) ~= "table" then
        db.encounters = {}
    end

    return db.encounters
end

local function CopyList(list)
    local copy = {}

    if type(list) ~= "table" then
        return copy
    end

    for i, value in ipairs(list) do
        copy[i] = value
    end

    return copy
end

local function MatchesFilters(encounter, filters)
    if type(filters) ~= "table" then
        return true
    end

    if filters.includeInterrupted ~= true then
        if encounter.flags and encounter.flags.interrupted == true then
            return false
        end
    end

    if filters.includeExcluded ~= true then
        if encounter.flags and encounter.flags.excludedFromComparisons == true then
            return false
        end
    end

    if filters.mapID and encounter.challenge and encounter.challenge.mapID ~= filters.mapID then
        return false
    end

    if filters.keyLevel and encounter.challenge and encounter.challenge.keyLevel ~= filters.keyLevel then
        return false
    end

    if filters.playerName and encounter.player and encounter.player.playerName ~= filters.playerName then
        return false
    end

    if filters.class and encounter.player and encounter.player.class ~= filters.class then
        return false
    end

    if filters.spec and encounter.player and encounter.player.spec ~= filters.spec then
        return false
    end

    return true
end

function EncountersDB.AddEncounter(encounter)
    if type(encounter) ~= "table" then
        return false, "encounter was not a table"
    end

    local encounters = GetEncountersTable()

    encounter.timestamp = encounter.timestamp or time()
    encounter.id = encounter.id or ("encounter-" .. tostring(encounter.timestamp) .. "-" .. tostring(#encounters + 1))

    table.insert(encounters, encounter)

    return true, encounter
end

function EncountersDB.GetAll()
    return GetEncountersTable()
end

function EncountersDB.Count(filters)
    local encounters = GetEncountersTable()
    local count = 0

    for _, encounter in ipairs(encounters) do
        if MatchesFilters(encounter, filters) then
            count = count + 1
        end
    end

    return count
end

function EncountersDB.GetFiltered(filters)
    local encounters = GetEncountersTable()
    local results = {}

    for _, encounter in ipairs(encounters) do
        if MatchesFilters(encounter, filters) then
            table.insert(results, encounter)
        end
    end

    table.sort(results, function(a, b)
        return (a.timestamp or 0) > (b.timestamp or 0)
    end)

    return results
end

function EncountersDB.GetPage(filters, page, pageSize)
    page = page or 1
    pageSize = pageSize or 5

    if page < 1 then
        page = 1
    end

    local results = EncountersDB.GetFiltered(filters)
    local total = #results
    local totalPages = math.max(1, math.ceil(total / pageSize))

    if page > totalPages then
        page = totalPages
    end

    local startIndex = ((page - 1) * pageSize) + 1
    local endIndex = math.min(startIndex + pageSize - 1, total)

    local pageResults = {}

    for i = startIndex, endIndex do
        if results[i] then
            table.insert(pageResults, results[i])
        end
    end

    return pageResults, {
        page = page,
        pageSize = pageSize,
        total = total,
        totalPages = totalPages,
        hasPrevious = page > 1,
        hasNext = page < totalPages,
    }
end

function EncountersDB.FindByID(encounterID)
    if not encounterID then
        return nil
    end

    local encounters = GetEncountersTable()

    for _, encounter in ipairs(encounters) do
        if encounter.id == encounterID then
            return encounter
        end
    end

    return nil
end

function EncountersDB.DeleteByID(encounterID)
    if not encounterID then
        return false
    end

    local encounters = GetEncountersTable()

    for i, encounter in ipairs(encounters) do
        if encounter.id == encounterID then
            table.remove(encounters, i)
            return true
        end
    end

    return false
end

function EncountersDB.SetExcluded(encounterID, excluded)
    local encounter = EncountersDB.FindByID(encounterID)

    if not encounter then
        return false
    end

    encounter.flags = encounter.flags or {}
    encounter.flags.excludedFromComparisons = excluded == true

    return true
end

function EncountersDB.GetRecent(limit)
    limit = limit or 5

    local results = EncountersDB.GetFiltered({
        includeInterrupted = false,
        includeExcluded = true,
    })

    local recent = {}

    for i = 1, math.min(limit, #results) do
        recent[i] = results[i]
    end

    return recent
end