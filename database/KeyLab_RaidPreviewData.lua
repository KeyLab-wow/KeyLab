local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.RaidPreviewData = KeyLab.RaidPreviewData or {}
local Preview = KeyLab.RaidPreviewData

local PREVIEW_PREFIX = "keylab-preview-raid-"

local RAID_DEFINITIONS = {
    {
        instanceID = 1307,
        instanceName = "Voidspire",
        difficultyID = 15,
        difficultyName = "Heroic",
        daysAgo = 0,
        latestPreview = true,
        bosses = {
            { encounterID = 2733, encounterName = "[Preview] Voidspire Boss 1", pulls = 4, killPull = 4, offset = 60000 },
            { encounterID = 2734, encounterName = "[Preview] Voidspire Boss 2", pulls = 8, killPull = 8, offset = 120000 },
            { encounterID = 2735, encounterName = "[Preview] Voidspire Boss 3", pulls = 25, killPull = 25, offset = 180000 },
            { encounterID = 2736, encounterName = "[Preview] Voidspire Boss 4", pulls = 6, killPull = 6, offset = 240000 },
            { encounterID = 2737, encounterName = "[Preview] Voidspire Boss 5", pulls = 50, killPull = 50, offset = 300000 },
            { encounterID = 2738, encounterName = "[Preview] Voidspire Boss 6", pulls = 9, killPull = 9, offset = 360000 },
        },
    },
    {
        instanceID = 1314,
        instanceName = "Dreamrift",
        difficultyID = 14,
        difficultyName = "Normal",
        daysAgo = 3,
        bosses = {
            { encounterID = 2795, encounterName = "[Preview] Dreamrift Boss", pulls = 5, killPull = 5, offset = 90000 },
        },
    },
}

local TALENT_VARIANTS = {
    "KEYLAB-PREVIEW-TALENT-BUILD-A",
    "KEYLAB-PREVIEW-TALENT-BUILD-B",
    "KEYLAB-PREVIEW-TALENT-BUILD-C",
}

local STAT_VARIANTS = {
    { crit = 24.2, haste = 31.8, mastery = 18.6, versatility = 12.4 },
    { crit = 29.7, haste = 26.4, mastery = 20.1, versatility = 11.8 },
    { crit = 21.5, haste = 25.2, mastery = 32.1, versatility = 10.9 },
}

local GEAR_SLOTS = {
    "Head", "Neck", "Shoulders", "Back", "Chest", "Wrist", "Hands", "Waist",
    "Legs", "Feet", "Finger 1", "Finger 2", "Trinket 1", "Trinket 2", "Main Hand", "Off Hand",
}

local function BuildGearProfile(variantIndex)
    local slots, signature = {}, {}
    local level = 264 + (variantIndex * 2)
    for slotIndex, slotName in ipairs(GEAR_SLOTS) do
        local itemID = 991000 + (variantIndex * 100) + slotIndex
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
    KeyLabDB.raidEncounters = type(KeyLabDB.raidEncounters) == "table" and KeyLabDB.raidEncounters or {}
    KeyLabDB.raidNights = type(KeyLabDB.raidNights) == "table" and KeyLabDB.raidNights or {}
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
    return {
        playerName = UnitName and UnitName("player") or "Preview Player",
        realm = GetRealmName and GetRealmName() or "Preview Realm",
        class = UnitClass and UnitClass("player") or "Preview Class",
        spec = "Preview Spec",
    }
end

local function BuildMetrics(pullIndex, bossOffset, duration, killed)
    local wave = (((pullIndex * 7) + math.floor(bossOffset / 60000)) % 11) - 5
    local dps = 820000 + bossOffset + (pullIndex * 18000) + (wave * 22000) + (killed and 85000 or 0)
    local hps = 155000 + math.floor(bossOffset * 0.12) + (pullIndex * 3500) + (wave * 6000)
    local damageTaken = math.max(12000000, 27000000 + (duration * 115000) + (wave * 1100000) + bossOffset * 8)
    local avoidableShare = math.max(0.07, 0.27 - (math.min(pullIndex, 24) * 0.007) + (wave * 0.004))
    return {
        damageDone = dps * duration,
        dps = dps,
        healingDone = hps * duration,
        hps = hps,
        absorbs = math.floor(hps * duration * 0.16),
        interrupts = (pullIndex % 4) + 1,
        dispels = pullIndex % 3,
        damageTaken = damageTaken,
        avoidableDamageTaken = math.floor(damageTaken * avoidableShare),
        deaths = killed and 0 or (pullIndex % 3),
    }
end

local function BuildRanks(pullIndex, bossIndex)
    local sway = ((pullIndex * 3 + bossIndex) % 5) - 2
    local improvement = math.floor((pullIndex - 1) / 6)
    local function ClampRank(value) return math.max(1, math.min(20, math.floor(value))) end
    local damageRank = ClampRank(9 + sway - improvement)
    local healingRank = ClampRank(7 - math.floor(improvement / 2) - sway)
    local pressureRank = ClampRank(5 + math.abs(sway) + (pullIndex % 3))
    return {
        damageDone = { rank = damageRank, total = 20 },
        dps = { rank = damageRank, total = 20 },
        healingDone = { rank = healingRank, total = 20 },
        hps = { rank = healingRank, total = 20 },
        absorbs = { rank = ClampRank(healingRank + 1), total = 20 },
        interrupts = { rank = ClampRank(4 + (pullIndex % 6)), total = 20 },
        dispels = { rank = ClampRank(3 + (pullIndex % 5)), total = 20 },
        damageTaken = { rank = pressureRank, total = 20 },
        avoidableDamageTaken = { rank = ClampRank(12 - improvement + math.abs(sway)), total = 20 },
        deaths = { rank = ClampRank(5 + (pullIndex % 4)), total = 20 },
    }
end

local function BuildNightRanks(player, metrics, groupSize)
    local role = player and (player.role or player.blizzardRole)
    local damageRank = (role == "Healer" or role == "HEALER") and 14 or ((role == "Tank" or role == "TANK") and 8 or 3)
    local healingRank = (role == "Healer" or role == "HEALER") and 2 or 12
    local tankRank = (role == "Tank" or role == "TANK") and 2 or 7
    local rankByMetric = {
        damageDone = damageRank,
        dps = damageRank,
        healingDone = healingRank,
        hps = healingRank,
        absorbs = math.max(1, healingRank - 1),
        interrupts = 5,
        dispels = 4,
        damageTaken = tankRank,
        avoidableDamageTaken = 6,
        deaths = 3,
    }
    local lowerIsBetter = { damageTaken = true, avoidableDamageTaken = true, deaths = true }
    local ranks = {}
    for metricKey, rank in pairs(rankByMetric) do
        local value = tonumber(metrics[metricKey]) or 0
        ranks[metricKey] = {
            rank = math.min(groupSize, rank),
            total = groupSize,
            value = value,
            bestValue = lowerIsBetter[metricKey] and value * 0.55 or value * 1.42,
            higherIsBetter = not lowerIsBetter[metricKey],
            calculation = "boss pulls only",
        }
    end
    return ranks
end

local function PreviewDuration(pullIndex, bossIndex, killed)
    return 60 + (((pullIndex - 1) % 8) * 14) + (bossIndex * 6) + (killed and 35 or 0)
end

local function DefinitionElapsed(definition)
    local elapsed = 0
    for bossIndex, boss in ipairs(definition.bosses or {}) do
        for pullIndex = 1, boss.pulls do
            elapsed = elapsed + PreviewDuration(pullIndex, bossIndex, boss.killPull == pullIndex) + 45
        end
    end
    return elapsed
end

local function AddEncounter(record)
    if KeyLab.DB and KeyLab.DB.Raids and KeyLab.DB.Raids.AddEncounter then
        return KeyLab.DB.Raids.AddEncounter(record)
    end
    table.insert(GetDB().raidEncounters, record)
    return true, record
end

local function AddNight(record)
    if KeyLab.DB and KeyLab.DB.Raids and KeyLab.DB.Raids.AddNight then
        return KeyLab.DB.Raids.AddNight(record)
    end
    table.insert(GetDB().raidNights, record)
    return true, record
end

function Preview.HasData()
    local db = GetDB()
    for _, encounter in ipairs(db.raidEncounters or {}) do
        if IsPreviewRecord(encounter) then return true end
    end
    for _, night in ipairs(db.raidNights or {}) do
        if IsPreviewRecord(night) then return true end
    end
    return false
end

function Preview.Remove()
    local db = GetDB()
    local removedEncounters, removedNights = 0, 0
    for index = #(db.raidEncounters or {}), 1, -1 do
        if IsPreviewRecord(db.raidEncounters[index]) then
            table.remove(db.raidEncounters, index)
            removedEncounters = removedEncounters + 1
        end
    end
    for index = #(db.raidNights or {}), 1, -1 do
        if IsPreviewRecord(db.raidNights[index]) then
            table.remove(db.raidNights, index)
            removedNights = removedNights + 1
        end
    end
    RefreshUI()
    return removedEncounters, removedNights
end

function Preview.Add()
    if Preview.HasData() then return false, "Raid preview data is already loaded." end

    local player = PlayerSnapshot()
    local now = time()
    local totalPulls, totalNights = 0, 0

    for raidIndex, definition in ipairs(RAID_DEFINITIONS) do
        local startOffset = definition.latestPreview and (DefinitionElapsed(definition) + 300) or 10800
        local nightStart = now - (definition.daysAgo * 86400) - startOffset
        local nightID = PREVIEW_PREFIX .. "night-" .. tostring(raidIndex)
        local pullIDs, bossAttempts, bossKills = {}, {}, {}
        local killPulls = 0
        local elapsed = 0
        local nightMetrics = {}
        local totalBossSeconds = 0

        for bossIndex, boss in ipairs(definition.bosses) do
            for pullIndex = 1, boss.pulls do
                local killed = boss.killPull ~= nil and pullIndex == boss.killPull
                local duration = PreviewDuration(pullIndex, bossIndex, killed)
                local endedAt = nightStart + elapsed + duration
                elapsed = elapsed + duration + 45
                local pullID = string.format("%spull-%d-%d-%d", PREVIEW_PREFIX, raidIndex, bossIndex, pullIndex)
                local variantIndex = ((pullIndex + bossIndex - 2) % #TALENT_VARIANTS) + 1
                local stats = STAT_VARIANTS[variantIndex]
                local metrics = BuildMetrics(pullIndex, boss.offset, duration, killed)
                totalBossSeconds = totalBossSeconds + duration
                for metricKey, value in pairs(metrics) do
                    if metricKey ~= "dps" and metricKey ~= "hps" then
                        nightMetrics[metricKey] = (tonumber(nightMetrics[metricKey]) or 0) + (tonumber(value) or 0)
                    end
                end

                local encounter = {
                    id = pullID,
                    previewData = true,
                    contentType = "raid",
                    recordType = "bossPull",
                    timestamp = endedAt,
                    dateText = date("%Y-%m-%d %H:%M:%S", endedAt),
                    result = killed and "Kill" or "Wipe",
                    raid = {
                        raidNightID = nightID,
                        encounterID = boss.encounterID,
                        encounterName = boss.encounterName,
                        instanceID = definition.instanceID,
                        instanceName = definition.instanceName,
                        difficultyID = definition.difficultyID,
                        difficultyName = definition.difficultyName,
                        groupSize = 20,
                        killed = killed,
                        startedAt = endedAt - duration,
                        endedAt = endedAt,
                        durationSeconds = duration,
                        pullNumber = pullIndex,
                        nightPullNumber = #pullIDs + 1,
                    },
                    player = player,
                    talents = { talentString = TALENT_VARIANTS[variantIndex] },
                    gear = BuildGearProfile(variantIndex),
                    stats = {
                        crit = stats.crit,
                        haste = stats.haste,
                        mastery = stats.mastery,
                        versatility = stats.versatility,
                    },
                    metrics = metrics,
                    metricRanks = BuildRanks(pullIndex, bossIndex),
                    flags = { interrupted = false, excludedFromComparisons = false, previewData = true },
                }

                local ok = AddEncounter(encounter)
                if ok then
                    table.insert(pullIDs, pullID)
                    totalPulls = totalPulls + 1
                    bossAttempts[tostring(boss.encounterID)] = pullIndex
                    if killed then bossKills[tostring(boss.encounterID)] = true; killPulls = killPulls + 1 end
                end
            end
        end

        local bossesAttempted, bossesKilled = 0, 0
        for _ in pairs(bossAttempts) do bossesAttempted = bossesAttempted + 1 end
        for _ in pairs(bossKills) do bossesKilled = bossesKilled + 1 end
        local nightEnd = nightStart + elapsed
        nightMetrics.dps = totalBossSeconds > 0 and ((tonumber(nightMetrics.damageDone) or 0) / totalBossSeconds) or 0
        nightMetrics.hps = totalBossSeconds > 0 and ((tonumber(nightMetrics.healingDone) or 0) / totalBossSeconds) or 0
        nightMetrics.damageTaken = totalBossSeconds > 0 and (((tonumber(nightMetrics.damageTaken) or 0) / totalBossSeconds) * 60) or 0
        nightMetrics.avoidableDamageTaken = totalBossSeconds > 0 and (((tonumber(nightMetrics.avoidableDamageTaken) or 0) / totalBossSeconds) * 60) or 0
        local night = {
            id = nightID,
            previewData = true,
            contentType = "raid",
            recordType = "raidNight",
            startTime = nightStart,
            endTime = nightEnd,
            dateText = date("%Y-%m-%d %H:%M:%S", nightEnd),
            closeReason = "preview data",
            instanceID = definition.instanceID,
            instanceName = definition.instanceName,
            difficultyID = definition.difficultyID,
            difficultyName = definition.difficultyName,
            maxPlayers = 20,
            player = player,
            pullIDs = pullIDs,
            totalPulls = #pullIDs,
            bossesAttempted = bossesAttempted,
            bossesKilled = bossesKilled,
            bossAttempts = bossAttempts,
            bossKills = bossKills,
            killPulls = killPulls,
            wipes = #pullIDs - killPulls,
            nightMetrics = nightMetrics,
            nightMetricRanks = BuildNightRanks(player, nightMetrics, definition.maxPlayers or 20),
        }
        local ok = AddNight(night)
        if ok then totalNights = totalNights + 1 end
    end

    RefreshUI()
    return true, { pulls = totalPulls, nights = totalNights }
end

return Preview
