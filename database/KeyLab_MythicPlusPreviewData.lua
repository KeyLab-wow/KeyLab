local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.MythicPlusPreviewData = KeyLab.MythicPlusPreviewData or {}
local Preview = KeyLab.MythicPlusPreviewData

local PREVIEW_PREFIX = "keylab-preview-mplus-"

local DUNGEONS = {
    { mapID = 558, name = "Magisters' Terrace", timeLimit = 2040 },
    { mapID = 560, name = "Maisara Caverns", timeLimit = 1980 },
    { mapID = 559, name = "Nexus-Point Xenas", timeLimit = 1800 },
    { mapID = 557, name = "Windrunner Spire", timeLimit = 1980 },
}

local TALENT_VARIANTS = {
    "KEYLAB-PREVIEW-MPLUS-TALENT-BUILD-A",
    "KEYLAB-PREVIEW-MPLUS-TALENT-BUILD-B",
    "KEYLAB-PREVIEW-MPLUS-TALENT-BUILD-C",
}

local STAT_VARIANTS = {
    { crit = 24.8, haste = 31.2, mastery = 18.9, versatility = 12.1 },
    { crit = 29.4, haste = 26.7, mastery = 20.3, versatility = 11.6 },
    { crit = 21.9, haste = 25.5, mastery = 31.6, versatility = 10.8 },
}

local RUN_TIMING = {
    { keyLevel = 9, durationMultiplier = 1.045, timed = false, upgrades = 0 },
    { keyLevel = 10, durationMultiplier = 0.885, timed = true, upgrades = 1 },
    { keyLevel = 11, durationMultiplier = 0.745, timed = true, upgrades = 2 },
    { keyLevel = 12, durationMultiplier = 0.555, timed = true, upgrades = 3 },
}

local PREVIEW_AFFIXES = { 148, 153, 158, 162 }

local GEAR_SLOTS = {
    "Head", "Neck", "Shoulders", "Back", "Chest", "Wrist", "Hands", "Waist",
    "Legs", "Feet", "Finger 1", "Finger 2", "Trinket 1", "Trinket 2", "Main Hand", "Off Hand",
}

local function BuildGearProfile(variantIndex)
    local slots, signature = {}, {}
    local level = 264 + (variantIndex * 2)
    for slotIndex, slotName in ipairs(GEAR_SLOTS) do
        local itemID = 990000 + (variantIndex * 100) + slotIndex
        local itemName = string.format("[Preview] %s Setup %s", slotName, string.char(64 + variantIndex))
        slots[slotName] = {
            slotName = slotName,
            itemID = itemID,
            itemName = itemName,
            itemLevel = level + (slotIndex % 3),
        }
        table.insert(signature, tostring(slotIndex) .. ":" .. tostring(itemID))
    end
    return { averageItemLevel = level, slots = slots, signature = table.concat(signature, "|") }
end

local function GetDB()
    if KeyLab.DB and KeyLab.DB.Get then return KeyLab.DB.Get() end
    KeyLabDB = type(KeyLabDB) == "table" and KeyLabDB or {}
    KeyLabDB.encounters = type(KeyLabDB.encounters) == "table" and KeyLabDB.encounters or {}
    return KeyLabDB
end

local function IsPreviewRecord(record)
    return type(record) == "table" and (
        record.previewData == true
        or tostring(record.id or ""):sub(1, #PREVIEW_PREFIX) == PREVIEW_PREFIX
    )
end

local function RefreshUI()
    if KeyLab.RefreshTabs then KeyLab.RefreshTabs() end
    if KeyLab.UI and KeyLab.UI.RefreshSelectedTab then KeyLab.UI:RefreshSelectedTab() end
end

local function PlayerSnapshot()
    if KeyLab.Capture and KeyLab.Capture.Player and KeyLab.Capture.Player.GetSnapshot then
        return KeyLab.Capture.Player.GetSnapshot()
    end

    local className, classFile, classID
    if UnitClass then className, classFile, classID = UnitClass("player") end
    return {
        playerName = UnitName and UnitName("player") or "Preview Player",
        realm = GetRealmName and GetRealmName() or "Preview Realm",
        class = className or "Preview Class",
        classFile = classFile,
        classID = classID,
        spec = "Preview Spec",
        role = "DAMAGER",
        blizzardRole = "DAMAGER",
    }
end

local function CopyPlayer(player)
    local copy = {}
    for key, value in pairs(player or {}) do copy[key] = value end
    return copy
end

local function BuildRanks(runIndex)
    local damageRank = math.max(1, 4 - runIndex)
    return {
        damageDone = { rank = damageRank, total = 5 },
        dps = { rank = damageRank, total = 5 },
        healingDone = { rank = 3, total = 5 },
        hps = { rank = 3, total = 5 },
        absorbs = { rank = 3, total = 5 },
        interrupts = { rank = 2, total = 5 },
        dispels = { rank = 2, total = 5 },
        damageTaken = { rank = 4, total = 5 },
        avoidableDamageTaken = { rank = math.max(1, 5 - runIndex), total = 5 },
        deaths = { rank = 1, total = 5 },
    }
end

local function BuildCombatSessions(dungeonIndex, runIndex, baseDPS, baseHPS)
    local sessions = {}
    local localDeaths, groupDeaths = 0, 0

    for pullIndex = 1, 12 do
        local isBoss = pullIndex == 4 or pullIndex == 8 or pullIndex == 12
        local duration = isBoss and (92 + pullIndex * 4) or (42 + ((pullIndex * 13) % 39))
        local performance = 0.78 + (((pullIndex * 17) % 37) / 100)
        local dps = math.floor(baseDPS * performance * (isBoss and 0.93 or 1.08))
        local hps = math.floor(baseHPS * (0.80 + (((pullIndex * 11) % 31) / 100)))
        local damageTaken = math.floor((7600000 + pullIndex * 470000 + dungeonIndex * 310000) * (1.12 - runIndex * 0.055))
        local playerDied = (runIndex <= 2 and pullIndex == 7) and 1 or 0
        local groupDied = 0
        if pullIndex % 5 == 0 then groupDied = 1 end
        if runIndex == 1 and pullIndex == 11 then groupDied = groupDied + 1 end

        localDeaths = localDeaths + playerDied
        groupDeaths = groupDeaths + groupDied

        table.insert(sessions, {
            sessionID = (dungeonIndex * 1000) + (runIndex * 100) + pullIndex,
            sessionName = isBoss
                and string.format("(!) [Preview] Boss %d", pullIndex / 4)
                or string.format("[Preview] Trash Pull %d", pullIndex),
            durationSeconds = duration,
            isAggregateSession = false,
            isBossSession = isBoss,
            isTrashSession = not isBoss,
            metrics = {
                damageDone = dps * duration,
                dps = dps,
                healingDone = hps * duration,
                hps = hps,
                absorbs = math.floor(hps * duration * 0.15),
                interrupts = isBoss and 1 or ((pullIndex % 3) + 1),
                dispels = pullIndex % 4 == 0 and 1 or 0,
                damageTaken = damageTaken,
                avoidableDamageTaken = math.floor(damageTaken * math.max(0.07, 0.24 - runIndex * 0.035)),
                deaths = playerDied,
                groupDeaths = groupDied,
            },
        })
    end

    return sessions, localDeaths, groupDeaths
end

local function AddEncounter(record)
    if KeyLab.DB and KeyLab.DB.Encounters and KeyLab.DB.Encounters.AddEncounter then
        return KeyLab.DB.Encounters.AddEncounter(record)
    end
    table.insert(GetDB().encounters, record)
    return true, record
end

function Preview.HasData()
    for _, encounter in ipairs(GetDB().encounters or {}) do
        if IsPreviewRecord(encounter) then return true end
    end
    return false
end

function Preview.Remove()
    local encounters = GetDB().encounters or {}
    local removed = 0
    for index = #encounters, 1, -1 do
        if IsPreviewRecord(encounters[index]) then
            table.remove(encounters, index)
            removed = removed + 1
        end
    end
    RefreshUI()
    return removed
end

function Preview.Add()
    if Preview.HasData() then return false, "M+ preview data is already loaded." end

    local player = PlayerSnapshot()
    local now = time()
    local totalRuns = 0

    for dungeonIndex, dungeon in ipairs(DUNGEONS) do
        for runIndex, timing in ipairs(RUN_TIMING) do
            local sequence = ((dungeonIndex - 1) * #RUN_TIMING) + (#RUN_TIMING - runIndex)
            local timestamp = now - ((sequence * 4 + 1) * 3600)
            local duration = math.floor(dungeon.timeLimit * timing.durationMultiplier)
            local timeDelta = dungeon.timeLimit - duration
            local baseDPS = 690000 + dungeonIndex * 38000 + runIndex * 72000
            local baseHPS = 128000 + dungeonIndex * 8500 + runIndex * 12500
            local sessions, localDeaths, groupDeaths = BuildCombatSessions(dungeonIndex, runIndex, baseDPS, baseHPS)
            local totalDamage = baseDPS * duration
            local totalHealing = baseHPS * duration
            local variantIndex = ((dungeonIndex + runIndex - 2) % #TALENT_VARIANTS) + 1
            local stats = STAT_VARIANTS[variantIndex]
            local encounterPlayer = CopyPlayer(player)

            if not encounterPlayer.spec or encounterPlayer.spec == "" then encounterPlayer.spec = "Preview Spec" end
            if not encounterPlayer.role or encounterPlayer.role == "" then encounterPlayer.role = "DAMAGER" end

            local encounter = {
                id = string.format("%srun-%d-%d", PREVIEW_PREFIX, dungeonIndex, runIndex),
                previewData = true,
                contentType = "mythicplus",
                recordType = "run",
                timestamp = timestamp,
                dateText = date("%Y-%m-%d %H:%M:%S", timestamp),
                completed = true,
                result = timing.timed and "Timed" or "Untimed",
                challenge = {
                    mapID = dungeon.mapID,
                    dungeonName = "[Preview] " .. dungeon.name,
                    keyLevel = timing.keyLevel,
                    affixIDs = { runIndex % 2 == 0 and 9 or 10, 152, PREVIEW_AFFIXES[runIndex] },
                    durationSeconds = duration,
                    timeLimitSeconds = dungeon.timeLimit,
                    timeDeltaSeconds = timeDelta,
                    remainingSeconds = timeDelta,
                    timed = timing.timed,
                    timingSource = "previewData",
                    durationSource = "previewData",
                    timedSource = "previewData",
                    remainingSource = "previewData",
                    timeLimitSource = "previewData",
                    keystoneUpgradeLevels = timing.upgrades,
                    keystoneUpgradeLevelsSource = "previewData",
                    deathCount = groupDeaths,
                    officialDeathCount = groupDeaths,
                    deathCountSource = "previewData",
                },
                player = encounterPlayer,
                talents = { talentString = TALENT_VARIANTS[variantIndex] },
                gear = BuildGearProfile(variantIndex),
                stats = {
                    crit = stats.crit,
                    haste = stats.haste,
                    mastery = stats.mastery,
                    versatility = stats.versatility,
                },
                metrics = {
                    damageDone = totalDamage,
                    dps = baseDPS,
                    healingDone = totalHealing,
                    hps = baseHPS,
                    absorbs = math.floor(totalHealing * 0.17),
                    interrupts = 18 + runIndex * 3 + dungeonIndex,
                    dispels = 4 + runIndex,
                    damageTaken = math.floor(92000000 * (1.10 - runIndex * 0.06) + dungeonIndex * 1800000),
                    avoidableDamageTaken = math.floor(17500000 * (1.12 - runIndex * 0.12) + dungeonIndex * 420000),
                    deaths = localDeaths,
                    groupDeaths = groupDeaths,
                },
                metricRanks = BuildRanks(runIndex),
                combatSessions = sessions,
                capture = {
                    officialChallengeDeaths = groupDeaths,
                    groupDeaths = groupDeaths,
                    pullSessionDeaths = localDeaths,
                    pullSessionGroupDeaths = groupDeaths,
                    deathMetricSource = "pullSessions",
                    groupDeathMetricSource = "previewData",
                },
                flags = {
                    interrupted = false,
                    excludedFromComparisons = false,
                    previewData = true,
                },
            }

            local ok = AddEncounter(encounter)
            if ok then totalRuns = totalRuns + 1 end
        end
    end

    RefreshUI()
    return true, { runs = totalRuns, dungeons = #DUNGEONS }
end

return Preview
