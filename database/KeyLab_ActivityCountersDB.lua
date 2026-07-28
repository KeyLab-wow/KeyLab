local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.DB = KeyLab.DB or {}
KeyLab.DB.ActivityCounters = KeyLab.DB.ActivityCounters or {}

local Counters = KeyLab.DB.ActivityCounters
local SCHEMA_VERSION = 1

--[[
KeyLab_ActivityCountersDB.lua

Purpose:
- Keeps lightweight season activity totals independent of retained history.
- Stores totals per character across all of that character's specializations.
- Seeds old installs from the records still available during migration.
- Does NOT capture encounters, prune history, or create UI elements.
]]

local function GetDB()
    if KeyLab.DB and KeyLab.DB.Get then return KeyLab.DB.Get() end
    KeyLabDB = type(KeyLabDB) == "table" and KeyLabDB or {}
    return KeyLabDB
end

local function Normalize(value)
    value = tostring(value or ""):lower()
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    return value
end

local function FallbackCharacterKey(encounter)
    encounter = type(encounter) == "table" and encounter or {}
    local player = type(encounter.player) == "table" and encounter.player or {}
    local name = player.playerName or player.name or player.characterName
        or encounter.playerName or encounter.characterName
    local realm = player.realm or player.realmName or player.playerRealm
        or encounter.realm or encounter.realmName
    name = Normalize(name)
    realm = Normalize(realm):gsub("[%s%-]", "")
    if name == "" then name = "unknown-character" end
    if realm == "" then realm = "unknown-realm" end
    return name .. "-" .. realm
end

local function CharacterKey(encounter)
    local journal = KeyLab.DB and KeyLab.DB.SeasonJournal
    if journal and journal.GetCharacterKey then
        return journal.GetCharacterKey(encounter)
    end
    return FallbackCharacterKey(encounter)
end

local function CurrentCharacterKey()
    local journal = KeyLab.DB and KeyLab.DB.SeasonJournal
    if journal and journal.GetCurrentIdentity then
        local characterKey = journal.GetCurrentIdentity()
        if characterKey and characterKey ~= "" then return characterKey end
    end

    local playerName, realmName
    if UnitFullName then playerName, realmName = UnitFullName("player") end
    if not playerName and UnitName then playerName = UnitName("player") end
    if not realmName and GetNormalizedRealmName then realmName = GetNormalizedRealmName() end
    if not realmName and GetRealmName then realmName = GetRealmName() end
    return FallbackCharacterKey({ player = { playerName = playerName, realm = realmName } })
end

local function IsAuthorData(encounter)
    if type(encounter) ~= "table" then return true end
    local flags = type(encounter.flags) == "table" and encounter.flags or {}
    return flags.authorSampleData == true
        or encounter.previewData == true
        or encounter.keylabAuthorData ~= nil
end

local function EnsureRoot(db)
    if type(db.activityCounts) ~= "table" then db.activityCounts = {} end
    local root = db.activityCounts
    if type(root.characters) ~= "table" then root.characters = {} end
    return root
end

local function EnsureCharacter(root, characterKey)
    local characters = root.characters
    if type(characters[characterKey]) ~= "table" then
        characters[characterKey] = {
            mplusRuns = 0,
            raidBossPulls = 0,
        }
    end
    return characters[characterKey]
end

local function AddToTotal(root, encounter, contentType)
    if IsAuthorData(encounter) then return false end
    local bucket = EnsureCharacter(root, CharacterKey(encounter))
    if contentType == "raid" then
        bucket.raidBossPulls = (tonumber(bucket.raidBossPulls) or 0) + 1
    else
        bucket.mplusRuns = (tonumber(bucket.mplusRuns) or 0) + 1
    end
    return true
end

function Counters.Initialize()
    local db = GetDB()
    local root = EnsureRoot(db)
    if tonumber(root.schemaVersion) == SCHEMA_VERSION then return false end

    -- This runs before encounter retention so an older install keeps every
    -- count that is still present at the time of its first migration.
    root.characters = {}
    for _, encounter in ipairs(db.encounters or {}) do
        AddToTotal(root, encounter, "mplus")
    end
    for _, encounter in ipairs(db.raidEncounters or {}) do
        AddToTotal(root, encounter, "raid")
    end
    root.schemaVersion = SCHEMA_VERSION
    root.seededAt = time and time() or 0
    return true
end

function Counters.RecordEncounter(encounter, contentType)
    local migratedNow = Counters.Initialize()
    if IsAuthorData(encounter) then return false end

    -- When initialization occurs from inside the first save, that encounter
    -- is already in the database array and was included by the migration.
    if migratedNow then return true end

    local root = EnsureRoot(GetDB())
    local bucket = EnsureCharacter(root, CharacterKey(encounter))
    local isRaid = contentType == "raid"
    local lastIDKey = isRaid and "lastRaidEncounterID" or "lastMPlusEncounterID"
    local encounterID = encounter and encounter.id
    if encounterID and bucket[lastIDKey] == encounterID then return false end

    if isRaid then
        bucket.raidBossPulls = (tonumber(bucket.raidBossPulls) or 0) + 1
    else
        bucket.mplusRuns = (tonumber(bucket.mplusRuns) or 0) + 1
    end
    if encounterID then bucket[lastIDKey] = encounterID end
    bucket.lastUpdatedAt = tonumber(encounter and encounter.timestamp) or (time and time() or 0)
    return true
end

function Counters.GetCounts(characterKey)
    Counters.Initialize()
    local root = EnsureRoot(GetDB())
    characterKey = characterKey or CurrentCharacterKey()
    local bucket = root.characters[characterKey]
    return {
        mplusRuns = tonumber(bucket and bucket.mplusRuns) or 0,
        raidBossPulls = tonumber(bucket and bucket.raidBossPulls) or 0,
    }
end

function Counters.GetCurrentCounts()
    return Counters.GetCounts(CurrentCharacterKey())
end

return Counters
