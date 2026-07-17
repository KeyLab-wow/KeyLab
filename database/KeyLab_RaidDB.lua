local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.DB = KeyLab.DB or {}
KeyLab.DB.Raids = KeyLab.DB.Raids or {}

local Raids = KeyLab.DB.Raids

-- Raid boss pulls and raid-night summaries intentionally live outside the
-- Mythic+ encounters table. This keeps all existing M+ consumers isolated.

local function GetDB()
    if KeyLab.DB and KeyLab.DB.Get then
        return KeyLab.DB.Get()
    end

    KeyLabDB = type(KeyLabDB) == "table" and KeyLabDB or {}
    return KeyLabDB
end

local function GetTable(key)
    local db = GetDB()
    if type(db[key]) ~= "table" then
        db[key] = {}
    end
    return db[key]
end

local function CopyAndSort(source, timestampKey)
    local out = {}
    for _, value in ipairs(source) do
        table.insert(out, value)
    end
    table.sort(out, function(a, b)
        return (tonumber(a and a[timestampKey]) or 0) > (tonumber(b and b[timestampKey]) or 0)
    end)
    return out
end

function Raids.AddEncounter(encounter)
    if type(encounter) ~= "table" then
        return false, "raid encounter was not a table"
    end
    if encounter.contentType ~= "raid" then
        return false, "raid encounter contentType was not raid"
    end
    if not encounter.raid or not encounter.raid.encounterID then
        return false, "raid encounterID was missing"
    end
    if KeyLab.Mapping and KeyLab.Mapping.Raids and KeyLab.Mapping.Raids.IsAllowedRuntimeEncounter
        and not KeyLab.Mapping.Raids.IsAllowedRuntimeEncounter(encounter.raid.instanceID, encounter.raid.encounterID)
    then
        return false, "raid pull was not from a supported raid instance"
    end

    local encounters = GetTable("raidEncounters")
    encounter.timestamp = encounter.timestamp or time()
    encounter.id = encounter.id or ("raid-encounter-" .. tostring(encounter.timestamp) .. "-" .. tostring(#encounters + 1))
    table.insert(encounters, encounter)
    return true, encounter
end

function Raids.AddNight(night)
    if type(night) ~= "table" then
        return false, "raid night was not a table"
    end
    if night.contentType ~= "raid" then
        return false, "raid night contentType was not raid"
    end

    local nights = GetTable("raidNights")
    night.endTime = night.endTime or time()
    night.id = night.id or ("raid-night-" .. tostring(night.endTime) .. "-" .. tostring(#nights + 1))

    -- Raid-night checkpoints use the same ID so /reload and reconnects can
    -- resume and update one summary instead of creating partial duplicates.
    for index, existing in ipairs(nights) do
        if type(existing) == "table" and existing.id == night.id then
            nights[index] = night
            return true, night
        end
    end

    table.insert(nights, night)
    return true, night
end

function Raids.GetEncounters(filters)
    filters = type(filters) == "table" and filters or {}
    local out = {}

    for _, encounter in ipairs(GetTable("raidEncounters")) do
        local raid = encounter.raid or {}
        local include = encounter.contentType == "raid"
        if include and filters.encounterID and raid.encounterID ~= filters.encounterID then include = false end
        if include and filters.raidNightID and raid.raidNightID ~= filters.raidNightID then include = false end
        if include and filters.instanceID and raid.instanceID ~= filters.instanceID then include = false end
        if include and filters.difficultyID and raid.difficultyID ~= filters.difficultyID then include = false end
        if include and filters.killed ~= nil and raid.killed ~= filters.killed then include = false end
        if include then table.insert(out, encounter) end
    end

    return CopyAndSort(out, "timestamp")
end

function Raids.GetNights()
    return CopyAndSort(GetTable("raidNights"), "endTime")
end

function Raids.GetLatestNight()
    return Raids.GetNights()[1]
end

function Raids.GetLatestNightForCurrentCharacter()
    local encounterData = KeyLab.EncounterData or (KeyLab.Analysis and KeyLab.Analysis.EncounterData)
    for _, night in ipairs(Raids.GetNights()) do
        local wrapper = { player = night.player }
        local characterMatches = not (encounterData and encounterData.EncounterMatchesCurrentCharacter)
            or encounterData.EncounterMatchesCurrentCharacter(wrapper, { allowMissingIdentity = false })
        local classMatches = not (encounterData and encounterData.EncounterMatchesCurrentClass)
            or encounterData.EncounterMatchesCurrentClass(wrapper, { allowMissingClass = true })
        if characterMatches and classMatches then return night end
    end
    return nil
end

function Raids.FindEncounterByID(id)
    if not id then return nil end
    for _, encounter in ipairs(GetTable("raidEncounters")) do
        if encounter.id == id then return encounter end
    end
    return nil
end

function Raids.GetNightEncounters(night)
    if type(night) ~= "table" then return {} end

    local out = {}
    local wanted = {}
    for _, id in ipairs(night.pullIDs or {}) do wanted[id] = true end

    for _, encounter in ipairs(GetTable("raidEncounters")) do
        if wanted[encounter.id] or (encounter.raid and encounter.raid.raidNightID == night.id) then
            table.insert(out, encounter)
        end
    end

    table.sort(out, function(a, b)
        return (tonumber(a and a.timestamp) or 0) < (tonumber(b and b.timestamp) or 0)
    end)
    return out
end

function Raids.CountEncounters()
    return #GetTable("raidEncounters")
end

return Raids
