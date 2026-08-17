local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.RaidPreviewData = KeyLab.RaidPreviewData or {}
local Preview = KeyLab.RaidPreviewData

local DATA_MARKER = "keylab-author-screenshot-v2"
local DATA_PREFIX = "keylab-author-raid-"
local LEGACY_PREFIX = "keylab-preview-raid-"

local RAID_DEFINITIONS = {
    {
        instanceID = 1320,
        instanceName = "The Venomous Abyss",
        difficultyID = 15,
        difficultyName = "Heroic",
        daysAgo = 0,
        latestSample = true,
        bosses = {
            { encounterID = 2888, encounterName = "Nek'zali the Soulcoiler", pulls = 3, killPull = 3, offset = -25000 },
            { encounterID = 2874, encounterName = "Entombed Sentinels", pulls = 4, killPull = 4, offset = 15000 },
            { encounterID = 2894, encounterName = "The Lost Explorers", pulls = 7, killPull = 7, offset = 35000 },
            { encounterID = 2882, encounterName = "Vashnik the Malignant", pulls = 4, killPull = 4, offset = 60000 },
            { encounterID = 2871, encounterName = "Sszorak", pulls = 8, killPull = 8, offset = 20000 },
            { encounterID = 2887, encounterName = "The Twin Fangs", pulls = 9, killPull = 9, offset = 50000 },
            { encounterID = 2883, encounterName = "The Coiled Altar", pulls = 10, killPull = 10, offset = 65000 },
            { encounterID = 2895, encounterName = "Ula'tek", pulls = 12, killPull = 12, offset = 90000 },
        },
    },
    {
        instanceID = 1317,
        instanceName = "The Tidebound Grotto",
        difficultyID = 14,
        difficultyName = "Normal",
        daysAgo = 12,
        bosses = {
            { encounterID = 2849, encounterName = "Nymrissa Wavecaller", pulls = 8, killPull = 8, offset = 45000 },
        },
    },
}

local TALENT_VARIANTS = {
    "KEYLAB-AUTHOR-RAID-TALENT-BUILD-A",
    "KEYLAB-AUTHOR-RAID-TALENT-BUILD-B",
    "KEYLAB-AUTHOR-RAID-TALENT-BUILD-C",
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
    local level = 302 + (variantIndex * 3)
    for slotIndex, slotName in ipairs(GEAR_SLOTS) do
        local itemID = 991000 + (variantIndex * 100) + slotIndex
        local itemName = string.format("%s Setup %s", slotName, string.char(64 + variantIndex))
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

local function HasPrefix(value, prefix)
    return tostring(value or ""):sub(1, #prefix) == prefix
end

local function IsOwnedRecord(record)
    if type(record) ~= "table" then return false end
    local id = tostring(record.id or "")
    local current = record.keylabAuthorData == DATA_MARKER and HasPrefix(id, DATA_PREFIX)
    local legacy = record.previewData == true and HasPrefix(id, LEGACY_PREFIX)
    return current or legacy
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
        playerName = UnitName and UnitName("player") or "KeyLab Author",
        realm = GetRealmName and GetRealmName() or "Sample Realm",
        class = UnitClass and UnitClass("player") or "Sample Class",
        spec = "Sample Spec",
    }
end

local function BuildMetrics(player, pullIndex, bossOffset, duration, killed)
    local wave = (((pullIndex * 7) + math.floor(bossOffset / 60000)) % 11) - 5
    local progress = math.min(pullIndex - 1, 12)
    local role = tostring(player and (player.role or player.blizzardRole) or "DAMAGER"):upper()
    local dps, hps, damageTaken, absorbShare
    if role == "HEALER" then
        dps = 245000 + bossOffset + (progress * 9000) + (wave * 11000) + (killed and 28000 or 0)
        hps = 835000 + math.floor(bossOffset * 0.45) + (progress * 18000) + (wave * 24000)
        damageTaken = math.max(9000000, 15000000 + (duration * 68000) + (wave * 520000))
        absorbShare = 0.20
    elseif role == "TANK" then
        dps = 445000 + bossOffset + (progress * 12000) + (wave * 15000) + (killed and 40000 or 0)
        hps = 285000 + math.floor(bossOffset * 0.18) + (progress * 8000) + (wave * 9000)
        damageTaken = math.max(28000000, 42000000 + (duration * 185000) + (wave * 1300000))
        absorbShare = 0.11
    else
        dps = 760000 + bossOffset + (progress * 16000) + (wave * 19000) + (killed and 60000 or 0)
        hps = 34000 + math.floor(math.max(0, bossOffset) * 0.05) + (progress * 1800) + (wave * 2200)
        damageTaken = math.max(10000000, 19000000 + (duration * 82000) + (wave * 680000))
        absorbShare = 0.035
    end
    local avoidableShare = math.max(0.055, 0.25 - (progress * 0.012) + (wave * 0.004))
    local playerDeaths = killed and 0 or (((pullIndex + math.floor(math.abs(bossOffset) / 5000)) % 5 == 0) and 1 or 0)
    local groupDeaths = killed and 0 or math.max(1, math.min(20, 15 - progress + (wave % 4)))
    return {
        damageDone = dps * duration,
        dps = dps,
        healingDone = hps * duration,
        hps = hps,
        absorbs = math.floor(hps * duration * absorbShare),
        interrupts = (pullIndex % 4) + 1,
        dispels = pullIndex % 3,
        damageTaken = damageTaken,
        avoidableDamageTaken = math.floor(damageTaken * avoidableShare),
        deaths = playerDeaths,
        groupDeaths = groupDeaths,
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
        groupDeaths = { rank = 1, total = 1 },
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
        groupDeaths = 1,
    }
    local lowerIsBetter = { damageTaken = true, avoidableDamageTaken = true, deaths = true, groupDeaths = true }
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
        if IsOwnedRecord(encounter) then return true end
    end
    for _, night in ipairs(db.raidNights or {}) do
        if IsOwnedRecord(night) then return true end
    end
    return false
end

function Preview.Count()
    local db = GetDB()
    local pulls, nights = 0, 0
    for _, encounter in ipairs(db.raidEncounters or {}) do
        if IsOwnedRecord(encounter) then pulls = pulls + 1 end
    end
    for _, night in ipairs(db.raidNights or {}) do
        if IsOwnedRecord(night) then nights = nights + 1 end
    end
    return pulls, nights
end

function Preview.Remove()
    local db = GetDB()
    local removedEncounters, removedNights = 0, 0
    for index = #(db.raidEncounters or {}), 1, -1 do
        if IsOwnedRecord(db.raidEncounters[index]) then
            table.remove(db.raidEncounters, index)
            removedEncounters = removedEncounters + 1
        end
    end
    for index = #(db.raidNights or {}), 1, -1 do
        if IsOwnedRecord(db.raidNights[index]) then
            table.remove(db.raidNights, index)
            removedNights = removedNights + 1
        end
    end
    RefreshUI()
    return removedEncounters, removedNights
end

function Preview.Add()
    if Preview.HasData() then return false, "Raid screenshot data is already loaded." end

    local player = PlayerSnapshot()
    local now = time()
    local totalPulls, totalNights = 0, 0

    for raidIndex, definition in ipairs(RAID_DEFINITIONS) do
        local startOffset = definition.latestSample and (DefinitionElapsed(definition) + 300) or 10800
        local nightStart = now - (definition.daysAgo * 86400) - startOffset
        local nightID = DATA_PREFIX .. "night-" .. tostring(raidIndex)
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
                local pullID = string.format("%spull-%d-%d-%d", DATA_PREFIX, raidIndex, bossIndex, pullIndex)
                local variantIndex = ((pullIndex + bossIndex - 2) % #TALENT_VARIANTS) + 1
                local stats = STAT_VARIANTS[variantIndex]
                local metrics = BuildMetrics(player, pullIndex, boss.offset, duration, killed)
                totalBossSeconds = totalBossSeconds + duration
                for metricKey, value in pairs(metrics) do
                    if metricKey ~= "dps" and metricKey ~= "hps" then
                        nightMetrics[metricKey] = (tonumber(nightMetrics[metricKey]) or 0) + (tonumber(value) or 0)
                    end
                end

                local encounter = {
                    id = pullID,
                    keylabAuthorData = DATA_MARKER,
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
                    flags = { interrupted = false, excludedFromComparisons = false, authorSampleData = true },
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
            keylabAuthorData = DATA_MARKER,
            contentType = "raid",
            recordType = "raidNight",
            startTime = nightStart,
            endTime = nightEnd,
            dateText = date("%Y-%m-%d %H:%M:%S", nightEnd),
            closeReason = "author sample data",
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
