local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.SeasonData = KeyLab.SeasonData or {}
local SeasonData = KeyLab.SeasonData

local MIGRATION_VERSION = 1
local CUTOFF_TIMESTAMP = 1786456800 -- 2026-08-11 14:00 UTC / 7:00 AM PDT / 10:00 AM EDT
local CURRENT_SEASON_KEY = "MN_S2"
local SEASON_NUMBER = { MN_S1 = 1, MN_S2 = 2 }
local OPTIONS = {
    { value = "MN_S1", label = "MN S1" },
    { value = "MN_S2", label = "MN S2" },
}

local function GetDB()
    if KeyLab.DB and KeyLab.DB.Get then return KeyLab.DB.Get() end
    KeyLabDB = type(KeyLabDB) == "table" and KeyLabDB or {}
    KeyLabDB.settings = type(KeyLabDB.settings) == "table" and KeyLabDB.settings or {}
    return KeyLabDB
end

function SeasonData.NormalizeSeasonKey(value, fallback)
    if value == 1 or value == "1" or value == "MN S1" or value == "MN_S1" then return "MN_S1" end
    if value == 2 or value == "2" or value == "MN S2" or value == "MN_S2" then return "MN_S2" end
    return fallback
end

function SeasonData.GetCutoffTimestamp() return CUTOFF_TIMESTAMP end
function SeasonData.GetCurrentSeasonKey() return CURRENT_SEASON_KEY end
function SeasonData.GetSeasonNumber(seasonKey) return SEASON_NUMBER[SeasonData.NormalizeSeasonKey(seasonKey)] end

function SeasonData.GetOptions()
    local out = {}
    for _, option in ipairs(OPTIONS) do table.insert(out, { value = option.value, label = option.label }) end
    return out
end

function SeasonData.GetLabel(seasonKey)
    return SeasonData.NormalizeSeasonKey(seasonKey, CURRENT_SEASON_KEY) == "MN_S1" and "MN S1" or "MN S2"
end

function SeasonData.GetSelectedSeasonKey()
    local db = GetDB()
    db.settings = type(db.settings) == "table" and db.settings or {}
    local selected = SeasonData.NormalizeSeasonKey(db.settings.selectedSeasonKey, CURRENT_SEASON_KEY)
    db.settings.selectedSeasonKey = selected
    return selected
end

function SeasonData.SetSelectedSeasonKey(seasonKey)
    seasonKey = SeasonData.NormalizeSeasonKey(seasonKey, CURRENT_SEASON_KEY)
    local db = GetDB()
    db.settings = type(db.settings) == "table" and db.settings or {}
    db.settings.selectedSeasonKey = seasonKey
    return seasonKey
end

function SeasonData.GetTimestamp(record, explicitTimestamp)
    local timestamp = tonumber(explicitTimestamp)
    if timestamp then return timestamp end
    if type(record) ~= "table" then return nil end
    for _, key in ipairs({ "timestamp", "savedAt", "completedAt", "endTime", "endedAt", "updatedAt", "startTime", "startedAt" }) do
        timestamp = tonumber(record[key])
        if timestamp then return timestamp end
    end
    return nil
end

function SeasonData.GetSeasonKeyForTimestamp(timestamp, missingFallback)
    timestamp = tonumber(timestamp)
    if not timestamp or timestamp <= 0 then
        return SeasonData.NormalizeSeasonKey(missingFallback, CURRENT_SEASON_KEY)
    end
    return timestamp < CUTOFF_TIMESTAMP and "MN_S1" or "MN_S2"
end

function SeasonData.GetRecordSeasonKey(record, missingFallback)
    if type(record) ~= "table" then
        return SeasonData.NormalizeSeasonKey(missingFallback, CURRENT_SEASON_KEY)
    end
    return SeasonData.NormalizeSeasonKey(record.seasonKey)
        or SeasonData.NormalizeSeasonKey(record.mnSeason)
        or SeasonData.GetSeasonKeyForTimestamp(SeasonData.GetTimestamp(record), missingFallback)
end

function SeasonData.LabelRecord(record, explicitTimestamp, missingFallback)
    if type(record) ~= "table" then return nil end
    local seasonKey
    if explicitTimestamp ~= nil then
        seasonKey = SeasonData.GetSeasonKeyForTimestamp(explicitTimestamp, missingFallback)
    else
        seasonKey = SeasonData.NormalizeSeasonKey(record.seasonKey)
            or SeasonData.NormalizeSeasonKey(record.mnSeason)
            or SeasonData.GetSeasonKeyForTimestamp(SeasonData.GetTimestamp(record), missingFallback)
    end
    record.seasonKey = seasonKey
    record.mnSeason = SEASON_NUMBER[seasonKey]
    return seasonKey
end

function SeasonData.Matches(record, seasonKey)
    seasonKey = SeasonData.NormalizeSeasonKey(seasonKey, SeasonData.GetSelectedSeasonKey())
    return SeasonData.GetRecordSeasonKey(record, "MN_S1") == seasonKey
end

local function LabelList(list, timestampKey)
    for _, record in ipairs(type(list) == "table" and list or {}) do
        if type(record) == "table" then
            local seasonKey = SeasonData.GetSeasonKeyForTimestamp(
                timestampKey and record[timestampKey] or SeasonData.GetTimestamp(record),
                "MN_S1"
            )
            record.seasonKey = seasonKey
            record.mnSeason = SEASON_NUMBER[seasonKey]
        end
    end
end

function SeasonData.Initialize()
    local db = GetDB()
    if (tonumber(db.midnightSeasonDataVersion) or 0) >= MIGRATION_VERSION then return false end
    LabelList(db.encounters, "timestamp")
    LabelList(db.raidEncounters, "timestamp")
    LabelList(db.raidNights, "endTime")
    LabelList(db.practiceSessions, "timestamp")
    LabelList(db.builds, "timestamp")
    db.midnightSeasonDataVersion = MIGRATION_VERSION
    db.midnightSeasonCutoff = CUTOFF_TIMESTAMP
    return true
end

local function RemoveSeasonFromList(list, seasonKey, timestampKey)
    if type(list) ~= "table" then return 0 end
    local removed = 0
    for index = #list, 1, -1 do
        local record = list[index]
        local recordSeason = type(record) == "table"
            and (SeasonData.NormalizeSeasonKey(record.seasonKey)
                or SeasonData.NormalizeSeasonKey(record.mnSeason)
                or SeasonData.GetSeasonKeyForTimestamp(timestampKey and record[timestampKey] or SeasonData.GetTimestamp(record), "MN_S1"))
            or "MN_S1"
        if recordSeason == seasonKey then table.remove(list, index); removed = removed + 1 end
    end
    return removed
end

function SeasonData.EraseSeason1()
    SeasonData.Initialize()
    local db = GetDB()
    local report = {
        encounters = RemoveSeasonFromList(db.encounters, "MN_S1", "timestamp"),
        raidEncounters = RemoveSeasonFromList(db.raidEncounters, "MN_S1", "timestamp"),
        raidNights = RemoveSeasonFromList(db.raidNights, "MN_S1", "endTime"),
        practiceSessions = RemoveSeasonFromList(db.practiceSessions, "MN_S1", "timestamp"),
        builds = RemoveSeasonFromList(db.builds, "MN_S1", "timestamp"),
        gearAssignments = 0,
        matcherResults = 0,
    }

    if KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.ClearSeasonForAllCharacters then
        report.gearAssignments = KeyLab.LootTargetsDB.ClearSeasonForAllCharacters("MN_S1") or 0
    end
    -- These timestamp-free legacy tables are migration backups from MN S1.
    db.lootTargets, db.lootTargetStatuses, db.gearTargets = {}, {}, {}

    if KeyLab.StatGoalMatcher and KeyLab.StatGoalMatcher.ClearSeasonResults then
        report.matcherResults = KeyLab.StatGoalMatcher.ClearSeasonResults("MN_S1") or 0
    elseif type(db.statGoalMatcherResults) == "table" then
        local bucket = db.statGoalMatcherResults.MN_S1
        if type(bucket) == "table" then for _ in pairs(bucket) do report.matcherResults = report.matcherResults + 1 end end
        db.statGoalMatcherResults.MN_S1 = {}
    end

    -- Rebuild derived counts and permanent best-result summaries from the
    -- remaining MN S2 encounters so erased Season 1 runs cannot linger in
    -- Home totals or performance summaries.
    db.activityCounts = {}
    if KeyLab.DB and KeyLab.DB.ActivityCounters and KeyLab.DB.ActivityCounters.Initialize then
        KeyLab.DB.ActivityCounters.Initialize()
    end
    db.performanceLeaderboards = {}
    db.seasonJournalSchemaVersion = nil
    if KeyLab.DB and KeyLab.DB.SeasonJournal and KeyLab.DB.SeasonJournal.Initialize then
        KeyLab.DB.SeasonJournal.Initialize()
    end

    db.seasonOneErasedAt = time and time() or 0
    db.seasonOneEraseReport = report
    SeasonData.SetSelectedSeasonKey(CURRENT_SEASON_KEY)
    return report
end

return SeasonData
