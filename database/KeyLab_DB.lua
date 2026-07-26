local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.DB = KeyLab.DB or {}

local DB = KeyLab.DB

--[[
KeyLab_DB.lua

Purpose:
- Creates and protects the main SavedVariables structure.
- Owns general database setup only.
- Does NOT capture Blizzard data.
- Does NOT format UI text.
- Does NOT create UI cards/buttons.

SavedVariables:
- KeyLabDB
]]

local DB_VERSION = "0.1.6"
local RELEASE_SNAPSHOT_LIMIT = 3

local DEFAULT_SETTINGS = {
    completedMythicPlusOnly = true,
    contentMode = "mplus",
}

local function EnsureTable(parent, key)
    if type(parent[key]) ~= "table" then
        parent[key] = {}
    end

    return parent[key]
end

local function DeepCopy(value, seen)
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

    local copy = {}
    for key, child in pairs(value) do
        local keyCopy = DeepCopy(key, seen)
        local childCopy = DeepCopy(child, seen)
        if keyCopy ~= nil and childCopy ~= nil then
            copy[keyCopy] = childCopy
        end
    end

    seen[value] = nil
    return copy
end

local function CopyJournalWithoutSafetyArchive(db)
    local copy = {}
    for key, value in pairs(db or {}) do
        if key ~= "dataSafety" then
            local keyCopy = DeepCopy(key)
            local valueCopy = DeepCopy(value)
            if keyCopy ~= nil and valueCopy ~= nil then
                copy[keyCopy] = valueCopy
            end
        end
    end
    return copy
end

local function GetReleaseVersion()
    return tostring(KeyLab.version or DB_VERSION)
end

local function HasJournalData(db)
    for key, value in pairs(db or {}) do
        if key ~= "dataSafety" then
            if type(value) == "table" and next(value) ~= nil then
                return true
            end
            if key == "trackingSince" and value ~= nil then
                return true
            end
        end
    end
    return false
end

local function CountList(value)
    return type(value) == "table" and #value or 0
end

function DB.PreserveCurrentData(reason)
    if type(KeyLabDB) ~= "table" or not HasJournalData(KeyLabDB) then
        return false, "No existing journal data needed a safety snapshot."
    end

    local safety = EnsureTable(KeyLabDB, "dataSafety")
    local snapshots = EnsureTable(safety, "releaseSnapshots")
    local order = EnsureTable(safety, "releaseOrder")
    local releaseVersion = GetReleaseVersion()
    local snapshotKey = "before-" .. releaseVersion

    if type(snapshots[snapshotKey]) == "table" then
        return true, snapshotKey
    end

    snapshots[snapshotKey] = {
        releaseVersion = releaseVersion,
        createdAt = time and time() or 0,
        createdAtText = date and date("%Y-%m-%d %H:%M:%S") or "Unknown",
        reason = reason or ("Before KeyLab " .. releaseVersion .. " initialization"),
        counts = {
            encounters = CountList(KeyLabDB.encounters),
            raidEncounters = CountList(KeyLabDB.raidEncounters),
            raidNights = CountList(KeyLabDB.raidNights),
            practiceSessions = CountList(KeyLabDB.practiceSessions),
        },
        journal = CopyJournalWithoutSafetyArchive(KeyLabDB),
    }
    table.insert(order, snapshotKey)

    while #order > RELEASE_SNAPSHOT_LIMIT do
        local expiredKey = table.remove(order, 1)
        if expiredKey and expiredKey ~= snapshotKey then
            snapshots[expiredKey] = nil
        end
    end

    safety.lastProtectedRelease = releaseVersion
    safety.lastSnapshotKey = snapshotKey
    return true, snapshotKey
end

function DB.GetReleaseSnapshots()
    if type(KeyLabDB) ~= "table" or type(KeyLabDB.dataSafety) ~= "table" then
        return {}, {}
    end
    return KeyLabDB.dataSafety.releaseSnapshots or {}, KeyLabDB.dataSafety.releaseOrder or {}
end

function DB.Initialize()
    if type(KeyLabDB) ~= "table" then
        KeyLabDB = {}
    end

    DB.PreserveCurrentData("Automatic safety copy before release initialization and migrations")

    KeyLabDB.version = KeyLabDB.version or DB_VERSION
    KeyLabDB.trackingSince = KeyLabDB.trackingSince or date("%B %Y")

    EnsureTable(KeyLabDB, "settings")
    EnsureTable(KeyLabDB, "encounters")
    EnsureTable(KeyLabDB, "raidEncounters")
    EnsureTable(KeyLabDB, "raidNights")
    EnsureTable(KeyLabDB, "builds")
    EnsureTable(KeyLabDB, "lootTargets")
    EnsureTable(KeyLabDB, "lootTargetStatuses")
    EnsureTable(KeyLabDB, "gearTargets")
    EnsureTable(KeyLabDB, "tierSets")
    EnsureTable(KeyLabDB, "statGoals")
    EnsureTable(KeyLabDB, "statGoalMatcherResults")
    EnsureTable(KeyLabDB, "practiceSessions")

    for key, value in pairs(DEFAULT_SETTINGS) do
        if KeyLabDB.settings[key] == nil then
            KeyLabDB.settings[key] = value
        end
    end

    return KeyLabDB
end

function DB.Get()
    if type(KeyLabDB) ~= "table" then
        DB.Initialize()
    end

    return KeyLabDB
end

function DB.GetSettings()
    local db = DB.Get()
    return db.settings
end

function DB.GetVersion()
    local db = DB.Get()
    return db.version
end

function DB.GetTrackingSince()
    local db = DB.Get()
    return db.trackingSince
end

function DB.CountEncounters()
    local db = DB.Get()
    local encounters = db.encounters

    if type(encounters) ~= "table" then
        return 0
    end

    return #encounters
end

function DB.CountBuilds()
    local db = DB.Get()
    local builds = db.builds

    if type(builds) ~= "table" then
        return 0
    end

    return #builds
end

function DB.ResetAll()
    KeyLabDB = {
        version = DB_VERSION,
        trackingSince = date("%B %Y"),
        settings = {},
        encounters = {},
        raidEncounters = {},
        raidNights = {},
        builds = {},
        lootTargets = {},
        lootTargetStatuses = {},
        gearTargets = {},
        tierSets = {},
        statGoals = {},
        statGoalMatcherResults = {},
        practiceSessions = {},
    }

    for key, value in pairs(DEFAULT_SETTINGS) do
        KeyLabDB.settings[key] = value
    end

    return KeyLabDB
end
