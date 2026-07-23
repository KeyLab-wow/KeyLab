local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.MythicPlusPreviewData = KeyLab.MythicPlusPreviewData or {}
local Preview = KeyLab.MythicPlusPreviewData

local PREVIEW_PREFIX = "keylab-preview-mplus-"

local DUNGEONS = {
    { mapID = 558, name = "Magisters' Terrace", timeLimit = 2040, bosses = { "Arcanotron Custos", "Seranel Sunlash", "Gemellus", "Degentrius" } },
    { mapID = 560, name = "Maisara Caverns", timeLimit = 1980, bosses = { "Muro'jin and Nekraxx", "Vordaza", "Rak'tul, Vessel of Souls" } },
    { mapID = 559, name = "Nexus-Point Xenas", timeLimit = 1800, bosses = { "Chief Corewright Kasreth", "Corewarden Nysarra", "Lothraxion" } },
    { mapID = 557, name = "Windrunner Spire", timeLimit = 1980, bosses = { "Emberdawn", "Derelict Duo", "Commander Kroluk", "The Restless Heart" } },
    { mapID = 161, name = "Skyreach", timeLimit = 1680, bosses = { "Ranjit", "Araknath", "Rukhran", "High Sage Viryx" } },
    { mapID = 402, name = "Algeth'ar Academy", timeLimit = 1860, bosses = { "Vexamus", "Overgrown Ancient", "Crawth", "Echo of Doragosa" } },
    { mapID = 556, name = "Pit of Saron", timeLimit = 1800, bosses = { "Forgemaster Garfrost", "Krick and Ick", "Scourgelord Tyrannus" } },
    { mapID = 583, name = "Seat of the Triumvirate", timeLimit = 2040, bosses = { "Zuraal the Ascended", "Saprish", "Viceroy Nezhar", "L'ura" } },
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
    { keyLevel = 7, durationMultiplier = 1.035, timed = false, upgrades = 0, daysAgo = 34 },
    { keyLevel = 8, durationMultiplier = 0.978, timed = true, upgrades = 1, daysAgo = 26 },
    { keyLevel = 9, durationMultiplier = 0.924, timed = true, upgrades = 1, daysAgo = 18 },
    { keyLevel = 10, durationMultiplier = 0.872, timed = true, upgrades = 1, daysAgo = 10 },
    { keyLevel = 11, durationMultiplier = 0.824, timed = true, upgrades = 1, daysAgo = 2 },
}

local PREVIEW_AFFIXES = { 148, 153, 158, 162, 159 }

local GEAR_SLOTS = {
    "Head", "Neck", "Shoulders", "Back", "Chest", "Wrist", "Hands", "Waist",
    "Legs", "Feet", "Finger 1", "Finger 2", "Trinket 1", "Trinket 2", "Main Hand", "Off Hand",
}

local function BuildGearProfile(variantIndex, progressionIndex)
    local slots, signature = {}, {}
    local level = 256 + ((progressionIndex or 1) * 2) + variantIndex
    for slotIndex, slotName in ipairs(GEAR_SLOTS) do
        local itemID = 990000 + ((progressionIndex or 1) * 1000) + (variantIndex * 100) + slotIndex
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
        groupDeaths = { rank = 1, total = 1 },
    }
end

local function BuildCombatSessions(dungeon, dungeonIndex, runIndex, baseDPS, baseHPS, damagePressure)
    local sessions = {}
    local localDeaths, groupDeaths = 0, 0
    local bossByPull = {}
    for bossIndex, bossName in ipairs(dungeon.bosses or {}) do
        local pullIndex = math.floor(((bossIndex * 12) / #dungeon.bosses) + 0.5)
        bossByPull[pullIndex] = bossName
    end

    local groupDeathSchedule = {
        [1] = { [5] = 2, [8] = 2, [11] = 3 },
        [2] = { [6] = 2, [10] = 2 },
        [3] = { [7] = 1, [11] = 1 },
        [4] = { [9] = 1 },
        [5] = {},
    }

    for pullIndex = 1, 12 do
        local bossName = bossByPull[pullIndex]
        local isBoss = bossName ~= nil
        local duration = isBoss and (92 + pullIndex * 4) or (42 + ((pullIndex * 13) % 39))
        local performance = 0.82 + (((pullIndex * 17) % 31) / 100)
        local dps = math.floor(baseDPS * performance * (isBoss and 0.93 or 1.08))
        local hps = math.floor(baseHPS * (0.80 + (((pullIndex * 11) % 31) / 100)))
        local damageTaken = math.floor((damagePressure + pullIndex * 310000 + dungeonIndex * 190000) * (1.10 - runIndex * 0.045))
        local playerDied = ((runIndex == 1 and (pullIndex == 8 or pullIndex == 11)) or (runIndex == 2 and pullIndex == 10) or (runIndex == 3 and pullIndex == 11) or (runIndex == 4 and dungeonIndex % 4 == 0 and pullIndex == 9)) and 1 or 0
        local groupDied = (groupDeathSchedule[runIndex] and groupDeathSchedule[runIndex][pullIndex]) or 0
        if runIndex == 5 and dungeonIndex % 3 == 0 and pullIndex == 10 then groupDied = 1 end

        localDeaths = localDeaths + playerDied
        groupDeaths = groupDeaths + groupDied

        table.insert(sessions, {
            sessionID = (dungeonIndex * 1000) + (runIndex * 100) + pullIndex,
            sessionName = isBoss
                and tostring(bossName)
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
    local role = tostring(player and (player.role or player.blizzardRole) or "DAMAGER"):upper()

    for dungeonIndex, dungeon in ipairs(DUNGEONS) do
        for runIndex, timing in ipairs(RUN_TIMING) do
            local timestamp = now - ((timing.daysAgo * 86400) + ((dungeonIndex - 1) * 3 * 3600))
            local durationVariance = ((((dungeonIndex * 7) + (runIndex * 3)) % 5) - 2) * 0.006
            local duration = math.floor(dungeon.timeLimit * (timing.durationMultiplier + durationVariance))
            local timeDelta = dungeon.timeLimit - duration
            local dungeonVariance = (((dungeonIndex * 37) % 9) - 4) * 12000
            local baseDPS, baseHPS, damagePressure, absorbShare
            if role == "HEALER" then
                baseDPS = 245000 + dungeonVariance + runIndex * 28000
                baseHPS = 735000 + dungeonIndex * 16000 + runIndex * 52000
                damagePressure = 4900000
                absorbShare = 0.19
            elseif role == "TANK" then
                baseDPS = 425000 + dungeonVariance + runIndex * 36000
                baseHPS = 255000 + dungeonIndex * 9000 + runIndex * 24000
                damagePressure = 11600000
                absorbShare = 0.10
            else
                baseDPS = 690000 + dungeonVariance + runIndex * 57000
                baseHPS = 28000 + dungeonIndex * 1800 + runIndex * 4200
                damagePressure = 6200000
                absorbShare = 0.035
            end
            local sessions, localDeaths, groupDeaths = BuildCombatSessions(dungeon, dungeonIndex, runIndex, baseDPS, baseHPS, damagePressure)
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
                    dungeonName = dungeon.name,
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
                gear = BuildGearProfile(variantIndex, runIndex),
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
                    absorbs = math.floor(totalHealing * absorbShare),
                    interrupts = 17 + runIndex * 2 + (dungeonIndex % 5),
                    dispels = 2 + runIndex + (dungeonIndex % 3),
                    damageTaken = math.floor((damagePressure * 11.5) * (1.10 - runIndex * 0.055) + dungeonIndex * 640000),
                    avoidableDamageTaken = math.floor((damagePressure * 2.35) * (1.14 - runIndex * 0.12) + dungeonIndex * 180000),
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
