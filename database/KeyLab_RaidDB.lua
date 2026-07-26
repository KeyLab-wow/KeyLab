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
        return false, "raid session was not a table"
    end
    if night.contentType ~= "raid" then
        return false, "raid session contentType was not raid"
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

local function GetCurrentSpecIdentity()
    if not GetSpecialization or not GetSpecializationInfo then return nil, nil end
    local specializationIndex = GetSpecialization()
    if not specializationIndex then return nil, nil end
    local specID, specName = GetSpecializationInfo(specializationIndex)
    return tonumber(specID), specName
end

local function NightMatchesCurrentSpec(night)
    local currentSpecID, currentSpecName = GetCurrentSpecIdentity()
    if not currentSpecID and (not currentSpecName or currentSpecName == "") then return true end

    local player = type(night) == "table" and night.player or {}
    local savedSpecID = tonumber(player and player.specID)
    local savedSpecName = player and (player.spec or player.specName)
    if currentSpecID and savedSpecID then return currentSpecID == savedSpecID end
    if currentSpecName and currentSpecName ~= "" and savedSpecName and savedSpecName ~= "" then
        return tostring(currentSpecName):lower() == tostring(savedSpecName):lower()
    end
    return false
end

local function NightMatchesCurrentCharacter(night)
    local encounterData = KeyLab.EncounterData or (KeyLab.Analysis and KeyLab.Analysis.EncounterData)
    local wrapper = { player = type(night) == "table" and night.player or nil }
    local characterMatches = not (encounterData and encounterData.EncounterMatchesCurrentCharacter)
        or encounterData.EncounterMatchesCurrentCharacter(wrapper, { allowMissingIdentity = false })
    local classMatches = not (encounterData and encounterData.EncounterMatchesCurrentClass)
        or encounterData.EncounterMatchesCurrentClass(wrapper, { allowMissingClass = true })
    return characterMatches and classMatches
end

function Raids.GetLatestNightForCurrentCharacterAndSpec()
    for _, night in ipairs(Raids.GetNights()) do
        if NightMatchesCurrentCharacter(night) and NightMatchesCurrentSpec(night) then
            return night
        end
    end
    return nil
end

function Raids.GetRecentNightsForCurrentCharacter(days)
    local now = time and time() or 0
    local cutoff = now - ((tonumber(days) or 7) * 86400)
    local recent = {}
    for _, night in ipairs(Raids.GetNights()) do
        local timestamp = tonumber(night and (night.endTime or night.startTime)) or 0
        if timestamp >= cutoff
            and NightMatchesCurrentCharacter(night)
            and NightMatchesCurrentSpec(night)
        then
            table.insert(recent, night)
        end
    end
    return recent
end

function Raids.FindNightByID(id)
    if not id then return nil end
    for _, night in ipairs(Raids.GetNights()) do
        if night.id == id then return night end
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
