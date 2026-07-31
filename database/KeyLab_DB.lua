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

local DB_VERSION = "0.1.8"

local DEFAULT_SETTINGS = {
    completedMythicPlusOnly = true,
    contentMode = "mplus",
    autoShowGroupFinderHelper = true,
}

local function EnsureTable(parent, key)
    if type(parent[key]) ~= "table" then
        parent[key] = {}
    end

    return parent[key]
end

function DB.Initialize()
    if type(KeyLabDB) ~= "table" then
        KeyLabDB = {}
    end

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
    EnsureTable(KeyLabDB, "performanceLeaderboards")
    EnsureTable(KeyLabDB, "activityCounts")

    for key, value in pairs(DEFAULT_SETTINGS) do
        if KeyLabDB.settings[key] == nil then
            KeyLabDB.settings[key] = value
        end
    end

    if DB.ActivityCounters and DB.ActivityCounters.Initialize then
        DB.ActivityCounters.Initialize()
    end

    if DB.SeasonJournal and DB.SeasonJournal.Initialize then
        DB.SeasonJournal.Initialize()
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

function DB.GetSetting(key, defaultValue)
    local settings = DB.GetSettings()
    local value = settings[key]
    if value == nil then return defaultValue end
    return value
end

function DB.SetSetting(key, value)
    local settings = DB.GetSettings()
    settings[key] = value
    return value
end

function DB.GetSettingTable(key)
    local settings = DB.GetSettings()
    if type(settings[key]) ~= "table" then
        settings[key] = {}
    end
    return settings[key]
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
        performanceLeaderboards = {},
        activityCounts = { schemaVersion = 1, characters = {} },
        seasonJournalSchemaVersion = 1,
    }

    for key, value in pairs(DEFAULT_SETTINGS) do
        KeyLabDB.settings[key] = value
    end

    return KeyLabDB
end
