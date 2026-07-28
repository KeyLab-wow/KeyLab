local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.DB = KeyLab.DB or {}
KeyLab.DB.SeasonJournal = KeyLab.DB.SeasonJournal or {}

local Journal = KeyLab.DB.SeasonJournal

local SCHEMA_VERSION = 1
local ENCOUNTER_LIMIT = 50
local DETAIL_LIMIT = 10
local LEADERBOARD_LIMIT = 5
local PRACTICE_LIMIT = 25

local STAT_KEYS = { "crit", "haste", "mastery", "versatility" }
local STAT_TIE_ORDER = { crit = 1, haste = 2, mastery = 3, versatility = 4 }
local METRIC_KEYS = { "dps", "hps" }
local PROFILE_TYPES = { "talent", "stats", "gear" }

local BULKY_DETAIL_KEYS = {
    combatSessions = true,
    damageMeterSessions = true,
    runCombatSessions = true,
}

local WINNER_OMIT_KEYS = {
    combatSessions = true,
    damageMeterSessions = true,
    runCombatSessions = true,
    groupMetrics = true,
    metricRanks = true,
    capture = true,
    rawDamageMeter = true,
    damageMeterSnapshot = true,
}

local function Trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function Normalize(value)
    return Trim(value):lower()
end

local function DeepCopy(value, seen, omit)
    local valueType = type(value)
    if valueType ~= "table" then
        if valueType == "string" or valueType == "number" or valueType == "boolean" then
            return value
        end
        return nil
    end

    seen = seen or {}
    if seen[value] then return nil end
    seen[value] = true

    local out = {}
    for key, child in pairs(value) do
        if not (omit and omit[key]) then
            local keyCopy = DeepCopy(key, seen)
            local childCopy = DeepCopy(child, seen, omit)
            if keyCopy ~= nil and childCopy ~= nil then
                out[keyCopy] = childCopy
            end
        end
    end

    seen[value] = nil
    return out
end

local function GetPlayer(encounter)
    return type(encounter) == "table" and type(encounter.player) == "table" and encounter.player or {}
end

local function GetCharacterKey(encounter)
    local player = GetPlayer(encounter)
    local character = type(encounter.character) == "table" and encounter.character or {}
    local context = type(encounter.context) == "table" and encounter.context or {}
    local capture = type(encounter.capture) == "table" and encounter.capture or {}
    local fullName = player.fullName or player.characterFullName or character.fullName or character.characterFullName
        or context.characterFullName or context.fullName or capture.characterFullName or capture.fullName
        or encounter.characterFullName or encounter.fullName
    local name = player.playerName or player.name or player.characterName or player.character or player.unitName
        or character.name or character.characterName or context.characterName or context.playerName
        or capture.characterName or capture.playerName or encounter.playerName or encounter.characterName
        or (type(encounter.character) == "string" and encounter.character or nil) or encounter.name
    local realm = player.realm or player.playerRealm or player.realmName or player.server
        or character.realm or character.realmName or context.realm or context.realmName
        or capture.realm or capture.realmName or encounter.realm or encounter.playerRealm
        or encounter.realmName or encounter.server
    if fullName and fullName ~= "" then
        local fullNamePart, fullRealmPart = tostring(fullName):match("^(.+)%-(.+)$")
        name = name or fullNamePart or fullName
        realm = realm or fullRealmPart
    end
    name = Normalize(name)
    realm = Normalize(realm):gsub("[%s%-]", "")
    if name == "" then name = "unknown-character" end
    if realm == "" then realm = "unknown-realm" end
    return name .. "-" .. realm
end

local function GetSpecKey(encounter)
    local player = GetPlayer(encounter)
    local character = type(encounter.character) == "table" and encounter.character or {}
    local context = type(encounter.context) == "table" and encounter.context or {}
    local capture = type(encounter.capture) == "table" and encounter.capture or {}
    local specID = tonumber(player.specID or player.specializationID or character.specID
        or context.specID or capture.specID or encounter.specID or encounter.specializationID)
    if specID then return "id:" .. tostring(specID) end
    local specName = Normalize(player.spec or player.specName or player.specialization or character.spec
        or character.specName or context.spec or context.specName or capture.spec or capture.specName
        or encounter.spec or encounter.specName or encounter.specialization)
    return "name:" .. (specName ~= "" and specName or "unknown-spec")
end

local function GetCollectionKey(encounter)
    return GetCharacterKey(encounter) .. "|" .. GetSpecKey(encounter)
end

local function GetCurrentIdentity()
    local playerName, realmName
    if UnitFullName then playerName, realmName = UnitFullName("player") end
    if not playerName and UnitName then playerName = UnitName("player") end
    if not realmName and GetNormalizedRealmName then realmName = GetNormalizedRealmName() end
    if not realmName and GetRealmName then realmName = GetRealmName() end

    local specID, specName
    if GetSpecialization and GetSpecializationInfo then
        local index = GetSpecialization()
        if index then specID, specName = GetSpecializationInfo(index) end
    end

    local wrapper = {
        player = {
            playerName = playerName,
            realm = realmName,
            specID = specID,
            spec = specName,
        },
    }
    return GetCharacterKey(wrapper), GetSpecKey(wrapper), specName
end

local function GetMetrics(encounter)
    return type(encounter) == "table" and type(encounter.metrics) == "table" and encounter.metrics or {}
end

local function GetTalentString(encounter)
    local talents = type(encounter) == "table" and type(encounter.talents) == "table" and encounter.talents or {}
    return Trim(talents.talentString or talents.importString or talents.loadoutString
        or encounter.talentString or encounter.talentsString)
end

local function GetStatProfileKey(encounter)
    local stats = type(encounter) == "table" and type(encounter.stats) == "table" and encounter.stats or {}
    local priority = {}
    for _, statKey in ipairs(STAT_KEYS) do
        local value = tonumber(stats[statKey])
        if value == nil then return nil end
        table.insert(priority, { key = statKey, value = value })
    end
    table.sort(priority, function(a, b)
        if a.value == b.value then
            return STAT_TIE_ORDER[a.key] < STAT_TIE_ORDER[b.key]
        end
        return a.value > b.value
    end)
    local parts = {}
    for _, stat in ipairs(priority) do table.insert(parts, stat.key) end
    return table.concat(parts, ">")
end

local function GetGearProfileKey(encounter)
    local gear = type(encounter) == "table" and type(encounter.gear) == "table" and encounter.gear or {}
    if type(gear.signature) == "string" and gear.signature ~= "" then return gear.signature end
    if type(gear.slots) ~= "table" then return nil end

    local slotNames = {}
    for slotName in pairs(gear.slots) do table.insert(slotNames, tostring(slotName)) end
    table.sort(slotNames)
    local parts = {}
    local found = false
    for _, slotName in ipairs(slotNames) do
        local slot = gear.slots[slotName]
        if type(slot) == "table" then
            local item = slot.itemLink or slot.itemID or "empty"
            if slot.itemLink or slot.itemID then found = true end
            table.insert(parts, slotName .. ":" .. tostring(item))
        end
    end
    return found and table.concat(parts, "|") or nil
end

local function GetProfileKey(profileType, encounter)
    if profileType == "talent" then
        local value = GetTalentString(encounter)
        return value ~= "" and value or nil
    elseif profileType == "stats" then
        return GetStatProfileKey(encounter)
    elseif profileType == "gear" then
        return GetGearProfileKey(encounter)
    end
    return nil
end

local function EnsureLeaderboards(db)
    if type(db.performanceLeaderboards) ~= "table" then db.performanceLeaderboards = {} end
    return db.performanceLeaderboards
end

local function EnsureList(db, characterKey, specKey, contentType, profileType, metricKey)
    local root = EnsureLeaderboards(db)
    root[characterKey] = type(root[characterKey]) == "table" and root[characterKey] or {}
    root[characterKey][specKey] = type(root[characterKey][specKey]) == "table" and root[characterKey][specKey] or {}
    root[characterKey][specKey][contentType] = type(root[characterKey][specKey][contentType]) == "table"
        and root[characterKey][specKey][contentType] or {}
    root[characterKey][specKey][contentType][profileType] =
        type(root[characterKey][specKey][contentType][profileType]) == "table"
        and root[characterKey][specKey][contentType][profileType] or {}
    local parent = root[characterKey][specKey][contentType][profileType]
    parent[metricKey] = type(parent[metricKey]) == "table" and parent[metricKey] or {}
    return parent[metricKey]
end

local function SortAndTrimLeaderboard(list)
    table.sort(list, function(a, b)
        local av, bv = tonumber(a and a.value) or 0, tonumber(b and b.value) or 0
        if av == bv then
            return (tonumber(a and a.updatedAt) or 0) > (tonumber(b and b.updatedAt) or 0)
        end
        return av > bv
    end)
    while #list > LEADERBOARD_LIMIT do table.remove(list) end
end

local function RecordProfile(db, encounter, contentType, profileType, metricKey)
    local value = tonumber(GetMetrics(encounter)[metricKey])
    local profileKey = GetProfileKey(profileType, encounter)
    if value == nil or not profileKey then return false end

    local characterKey, specKey = GetCharacterKey(encounter), GetSpecKey(encounter)
    local list = EnsureList(db, characterKey, specKey, contentType, profileType, metricKey)
    local existing
    for _, entry in ipairs(list) do
        if entry.profileKey == profileKey then existing = entry break end
    end
    if existing and tonumber(existing.value) and tonumber(existing.value) >= value then
        return false
    end

    local winner = DeepCopy(encounter, nil, WINNER_OMIT_KEYS)
    local entry = existing or {}
    entry.profileKey = profileKey
    entry.value = value
    entry.updatedAt = tonumber(encounter.timestamp) or (time and time() or 0)
    entry.encounter = winner
    entry.contentType = contentType
    entry.profileType = profileType
    entry.metricKey = metricKey
    if not existing then table.insert(list, entry) end
    SortAndTrimLeaderboard(list)
    return true
end

function Journal.RecordEncounter(encounter, contentType)
    if type(encounter) ~= "table" then return false end
    local db = KeyLab.DB and KeyLab.DB.Get and KeyLab.DB.Get() or KeyLabDB
    if type(db) ~= "table" then return false end
    contentType = contentType == "raid" and "raid" or "mplus"
    local changed = false
    for _, profileType in ipairs(PROFILE_TYPES) do
        for _, metricKey in ipairs(METRIC_KEYS) do
            if RecordProfile(db, encounter, contentType, profileType, metricKey) then changed = true end
        end
    end
    return changed
end

local function StripBulkyDetails(encounter)
    if type(encounter) ~= "table" then return end
    for key in pairs(BULKY_DETAIL_KEYS) do encounter[key] = nil end
    encounter.detailsRetained = false
end

local function ApplyEncounterLimits(list)
    if type(list) ~= "table" then return end
    local groups = {}
    for _, encounter in ipairs(list) do
        local key = GetCollectionKey(encounter)
        groups[key] = groups[key] or {}
        table.insert(groups[key], encounter)
    end

    local keep = {}
    for _, group in pairs(groups) do
        table.sort(group, function(a, b)
            return (tonumber(a and a.timestamp) or 0) > (tonumber(b and b.timestamp) or 0)
        end)
        for index, encounter in ipairs(group) do
            if index <= ENCOUNTER_LIMIT then
                keep[encounter] = true
                if index <= DETAIL_LIMIT then
                    encounter.detailsRetained = true
                else
                    StripBulkyDetails(encounter)
                end
            end
        end
    end

    for index = #list, 1, -1 do
        if not keep[list[index]] then table.remove(list, index) end
    end
end

local function PruneRaidNights(db)
    if type(db.raidNights) ~= "table" then return end
    local referenced = {}
    for _, encounter in ipairs(db.raidEncounters or {}) do
        local raid = type(encounter.raid) == "table" and encounter.raid or {}
        if raid.raidNightID then referenced[tostring(raid.raidNightID)] = true end
    end
    for index = #db.raidNights, 1, -1 do
        local night = db.raidNights[index]
        if not referenced[tostring(night and night.id or "")] then
            table.remove(db.raidNights, index)
        end
    end
end

local function IsProtectedPracticeSession(session)
    local status = Normalize(session and session.status)
    return status ~= "" and status ~= "unmarked" and status ~= "none"
end

local function ApplyPracticeLimits(db)
    if type(db.practiceSessions) ~= "table" then return end
    local groups = {}
    for _, session in ipairs(db.practiceSessions) do
        local key = GetCollectionKey(session)
        groups[key] = groups[key] or {}
        table.insert(groups[key], session)
    end

    local keep = {}
    for _, group in pairs(groups) do
        table.sort(group, function(a, b)
            local ap, bp = IsProtectedPracticeSession(a), IsProtectedPracticeSession(b)
            if ap ~= bp then return ap end
            return (tonumber(a and a.timestamp) or 0) > (tonumber(b and b.timestamp) or 0)
        end)
        for index = 1, math.min(PRACTICE_LIMIT, #group) do keep[group[index]] = true end
    end
    for index = #db.practiceSessions, 1, -1 do
        if not keep[db.practiceSessions[index]] then table.remove(db.practiceSessions, index) end
    end
end

function Journal.ApplyRetention()
    local db = KeyLab.DB and KeyLab.DB.Get and KeyLab.DB.Get() or KeyLabDB
    if type(db) ~= "table" then return end
    ApplyEncounterLimits(db.encounters)
    ApplyEncounterLimits(db.raidEncounters)
    PruneRaidNights(db)
    ApplyPracticeLimits(db)
end

function Journal.CanAddPracticeSession(session)
    local db = KeyLab.DB and KeyLab.DB.Get and KeyLab.DB.Get() or KeyLabDB
    local wantedKey = GetCollectionKey(session)
    local count, unprotected = 0, 0
    for _, existing in ipairs(type(db) == "table" and db.practiceSessions or {}) do
        if GetCollectionKey(existing) == wantedKey then
            count = count + 1
            if not IsProtectedPracticeSession(existing) then unprotected = unprotected + 1 end
        end
    end
    if count >= PRACTICE_LIMIT and unprotected == 0 then
        return false, "You already have 25 saved practice sessions for this specialization. Remove or unmark one before saving another."
    end
    return true
end

function Journal.GetLeaderboard(contentType, profileType, metricKey, characterKey, specKey)
    local db = KeyLab.DB and KeyLab.DB.Get and KeyLab.DB.Get() or KeyLabDB
    if type(db) ~= "table" then return {} end
    if not characterKey or not specKey then characterKey, specKey = GetCurrentIdentity() end
    local root = db.performanceLeaderboards
    local list = root and root[characterKey] and root[characterKey][specKey]
        and root[characterKey][specKey][contentType]
        and root[characterKey][specKey][contentType][profileType]
        and root[characterKey][specKey][contentType][profileType][metricKey]
    return type(list) == "table" and list or {}
end

function Journal.GetCurrentIdentity()
    return GetCurrentIdentity()
end

function Journal.GetCharacterKey(encounter)
    return GetCharacterKey(encounter)
end

function Journal.GetLimits()
    return {
        encounters = ENCOUNTER_LIMIT,
        details = DETAIL_LIMIT,
        leaderboard = LEADERBOARD_LIMIT,
        practice = PRACTICE_LIMIT,
    }
end

function Journal.Initialize()
    local db = type(KeyLabDB) == "table" and KeyLabDB or {}
    EnsureLeaderboards(db)
    if tonumber(db.seasonJournalSchemaVersion) ~= SCHEMA_VERSION then
        -- Seed permanent best-result lists before any old encounter is pruned.
        for _, encounter in ipairs(db.encounters or {}) do Journal.RecordEncounter(encounter, "mplus") end
        for _, encounter in ipairs(db.raidEncounters or {}) do Journal.RecordEncounter(encounter, "raid") end
        ApplyEncounterLimits(db.encounters)
        ApplyEncounterLimits(db.raidEncounters)
        ApplyPracticeLimits(db)
        PruneRaidNights(db)
        db.dataSafety = nil
        db.seasonJournalSchemaVersion = SCHEMA_VERSION
    else
        -- Old automatic release snapshots are no longer part of the database.
        db.dataSafety = nil
    end
end

return Journal
