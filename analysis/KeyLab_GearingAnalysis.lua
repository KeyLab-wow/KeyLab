-- KeyLab_GearingAnalysis.lua
-- Gear Dashboard decision helper.
--
-- Purpose:
-- - Receive normalized capture data.
-- - Produce one clean analyzed result per gear slot.
-- - Keep UI display-only.

local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.GearingAnalysis = KeyLab.GearingAnalysis or {}
local Analysis = KeyLab.GearingAnalysis

local DEFAULT_LEFT_SLOTS = { "Head", "Neck", "Shoulders", "Back", "Chest", "Wrist", "Main Hand", "Off Hand" }
local DEFAULT_RIGHT_SLOTS = { "Hands", "Waist", "Legs", "Feet", "Finger 1", "Finger 2", "Trinket 1", "Trinket 2" }
local TIER_SLOTS = { "Head", "Shoulders", "Chest", "Hands", "Legs" }

local STAT_LABELS = {
    crit = "Crit",
    haste = "Haste",
    mastery = "Mastery",
    versatility = "Vers",
}

local STAT_PRIORITY_KEYS = { "crit", "haste", "mastery", "versatility" }

local function DB()
    return KeyLab and KeyLab.GearingDatabase or {}
end

local function Capture()
    return KeyLab and KeyLab.GearCapture or {}
end

local function GetDashboardSlots(side, fallback)
    if DB().GetDashboardSlots then
        local slots = DB().GetDashboardSlots(side)
        if type(slots) == "table" and #slots > 0 then return slots end
    end
    return fallback
end

Analysis.LeftSlots = GetDashboardSlots("left", DEFAULT_LEFT_SLOTS)
Analysis.RightSlots = GetDashboardSlots("right", DEFAULT_RIGHT_SLOTS)

local function BaseSlotName(slotName)
    slotName = tostring(slotName or "")
    if slotName == "Finger 1" or slotName == "Finger 2" then return "Finger" end
    if slotName == "Trinket 1" or slotName == "Trinket 2" then return "Trinket" end
    return slotName
end

local function DisplaySlotName(slotName)
    if DB().GetDisplaySlotLabel then return DB().GetDisplaySlotLabel(slotName) end
    if slotName == "Main Hand" then return "Weapon" end
    if slotName == "Off Hand" then return "Off-Hand" end
    return slotName or "-"
end

local function TrackRank(trackName)
    if DB().GetTrackRank then return DB().GetTrackRank(trackName) end
    local ranks = { Unranked = 0, Adventurer = 1, Veteran = 2, Champion = 3, Hero = 4, Myth = 5 }
    return ranks[trackName or ""] or 0
end

local function TrackBaseScore(trackName)
    if DB().GetTrackBaseScore then return DB().GetTrackBaseScore(trackName) end
    local scores = { Unranked = 80, Adventurer = 80, Veteran = 60, Champion = 40, Hero = 20, Myth = 0 }
    return scores[trackName or ""] or 0
end

local function ShortTrackName(trackName)
    if trackName == "Adventurer" then return "Adv" end
    if trackName == "Veteran" then return "Vet" end
    if trackName == "Champion" then return "Champ" end
    return trackName or "Unranked"
end

local function TrackLabel(slot)
    if not slot or not slot.itemLink then return "-" end
    local itemLevel = tonumber(slot.itemLevel)
    if slot.craftedIndicatorVisible or slot.craftedDetected or slot.isCrafted then
        return itemLevel and (tostring(itemLevel) .. " Crafted") or "Crafted"
    end
    local track = ShortTrackName(slot.upgradeTrack or slot.trackName or "Unranked")
    if itemLevel then
        return tostring(itemLevel) .. " " .. track
    end
    return track
end

local function RankText(slot)
    local rank = tonumber(slot and slot.upgradeRank)
    local maxRank = tonumber(slot and (slot.upgradeMaxRank or slot.upgradeMax))
    if rank and maxRank then return tostring(rank) .. "/" .. tostring(maxRank) end
    return nil
end

local function IsEnchantableSlot(slot)
    local base = slot and (slot.baseName or BaseSlotName(slot.slotName or slot.name))
    if DB().IsEnchantableSlot then
        return DB().IsEnchantableSlot(base)
    end
    return base == "Head"
        or base == "Shoulders"
        or base == "Chest"
        or base == "Legs"
        or base == "Feet"
        or base == "Finger"
        or base == "Main Hand"
end

local function IsTwoHandOrRangedWeapon(slot)
    if Capture().IsTwoHandOrRangedWeapon then
        return Capture().IsTwoHandOrRangedWeapon(slot)
    end
    return false
end

local function AddBadge(slotState, key, label, kind)
    slotState.badges = slotState.badges or {}
    table.insert(slotState.badges, {
        key = key,
        label = label,
        kind = kind or "info",
    })
end

local function EmptyCapturedSlot(slotName)
    return {
        slotName = slotName,
        name = slotName,
        displayName = DisplaySlotName(slotName),
        baseName = BaseSlotName(slotName),
        itemLink = nil,
        link = nil,
        itemID = nil,
        itemLevel = nil,
        icon = nil,
        texture = nil,
        upgradeTrack = nil,
        trackName = nil,
        upgradeRank = nil,
        upgradeMaxRank = nil,
        enchantDetected = false,
        emptySocketCount = 0,
        tierEligible = DB().TierSlots and DB().TierSlots[BaseSlotName(slotName)] == true or false,
        tierIndicatorVisible = false,
        craftedIndicatorVisible = false,
        embellishedDetected = false,
        ascendantVoidforgedDetected = false,
        voidforgedDetected = false,
        voidforgeCandidate = false,
    }
end

local function GetEquippedSlot(slotName)
    if Capture().GetEquippedSlot then
        return Capture().GetEquippedSlot(slotName)
    end
    return EmptyCapturedSlot(slotName)
end

local function GetAllEquippedSlots()
    local allSlots = {}
    for _, slotName in ipairs(Analysis.LeftSlots or {}) do table.insert(allSlots, slotName) end
    for _, slotName in ipairs(Analysis.RightSlots or {}) do table.insert(allSlots, slotName) end

    if Capture().GetEquippedSlots then
        return Capture().GetEquippedSlots(allSlots)
    end

    local out = {}
    for _, slotName in ipairs(allSlots) do
        out[slotName] = GetEquippedSlot(slotName)
    end
    return out
end

local function GetEquippedItemLevel()
    if Capture().GetEquippedItemLevel then return Capture().GetEquippedItemLevel() end
    return nil
end

local function GetCurrentSpecID()
    if Capture().GetCurrentSpecID then return Capture().GetCurrentSpecID() end
    return 0
end

local function GetCurrentClassID()
    if Capture().GetCurrentClassID then return Capture().GetCurrentClassID() end
    return 0
end

local function GetPlayerLevel()
    if Capture().GetPlayerLevel then return Capture().GetPlayerLevel() end
    return nil
end

local function GetRunHistory()
    if Capture().GetRunHistory then return Capture().GetRunHistory() end
    return { completed = 0, highestCompleted = 0, highestTimed = 0 }
end

local function GetCurrencyState()
    if Capture().GetCurrencySnapshot then return Capture().GetCurrencySnapshot() or {} end
    local state = {}
    for key, entry in pairs(DB().CurrencyKeys or {}) do
        if entry.type ~= "item" and Capture().GetCurrencyAmount then
            state[key] = Capture().GetCurrencyAmount(entry.id) or 0
        end
    end
    return state
end

local function GetStatPriorityText(specID)
    if not KeyLab.StatGoalsDB or not KeyLab.StatGoalsDB.GetGoals then return "Set stat goals" end

    local goals = KeyLab.StatGoalsDB.GetGoals(specID)
    local out = {}
    for _, statKey in ipairs((goals and goals.priority) or {}) do
        table.insert(out, STAT_LABELS[statKey] or tostring(statKey))
    end
    if #out == 0 then return "Set stat goals" end
    return table.concat(out, " > ")
end

local function GetCurrentStatPriorityState(specID)
    local stats = KeyLab.StatGoalGuidance and KeyLab.StatGoalGuidance.GetCurrentStats and KeyLab.StatGoalGuidance.GetCurrentStats() or {}
    local ordered = {}
    local total = 0

    for index, statKey in ipairs(STAT_PRIORITY_KEYS) do
        local value = tonumber(stats[statKey]) or 0
        total = total + math.abs(value)
        table.insert(ordered, { key = statKey, value = value, index = index })
    end

    if total <= 0 then return { text = "Stats unavailable", mismatch = false } end

    table.sort(ordered, function(a, b)
        if a.value ~= b.value then return a.value > b.value end
        return a.index < b.index
    end)

    local labels, currentOrder = {}, {}
    for _, stat in ipairs(ordered) do
        table.insert(currentOrder, stat.key)
        table.insert(labels, STAT_LABELS[stat.key] or tostring(stat.key))
    end

    local mismatch = false
    local goals = KeyLab.StatGoalsDB and KeyLab.StatGoalsDB.GetGoals and KeyLab.StatGoalsDB.GetGoals(specID) or nil
    local configured = false
    for _, statKey in ipairs(STAT_PRIORITY_KEYS) do
        if goals and goals.targets and (tonumber(goals.targets[statKey]) or 0) > 0 then
            configured = true
            break
        end
    end

    if configured then
        for index, statKey in ipairs((goals and goals.priority) or {}) do
            if currentOrder[index] and currentOrder[index] ~= statKey then
                mismatch = true
                break
            end
        end
    end

    return { text = table.concat(labels, " > "), mismatch = mismatch }
end

local function NormalizeSlot(value)
    value = tostring(value or ""):lower()
    value = value:gsub("%s+", ""):gsub("%-", ""):gsub("'", "")
    return value
end

local function SlotMatchesItem(slotName, itemSlot)
    local base = BaseSlotName(slotName)
    local normalizedItem = NormalizeSlot(itemSlot)
    if base == "Finger" then return normalizedItem == "finger" end
    if base == "Trinket" then return normalizedItem == "trinket" end
    if base == "Shoulders" then return normalizedItem == "shoulder" or normalizedItem == "shoulders" end
    if base == "Main Hand" then
        return normalizedItem == "mainhand" or normalizedItem == "onehand" or normalizedItem == "twohand" or normalizedItem == "weapon"
    end
    if base == "Off Hand" then
        return normalizedItem == "offhand" or normalizedItem == "heldinoffhand" or normalizedItem == "shield"
    end
    return NormalizeSlot(base) == normalizedItem
end

local function AddUnique(list, seen, value)
    value = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if value == "" or seen[value] then return end
    seen[value] = true
    table.insert(list, value)
end

local function SplitSourceNames(sourceText, out, seen)
    sourceText = tostring(sourceText or "")
    for name in sourceText:gmatch("[^,]+") do
        AddUnique(out, seen, name)
    end
end

local function IsActiveTargetStatus(status)
    return status == "wanted" or status == "bis"
end

local function GetTargetSummary(slotName, specID, classID)
    local summary = {
        status = nil,
        targetCount = 0,
        bisCount = 0,
        acquiredCount = 0,
        openCount = 0,
        sources = {},
        sourceSeen = {},
    }

    local targetsDB = KeyLab.LootTargetsDB
    local mapping = KeyLab.GearLootMapping
    if not targetsDB or not mapping or not mapping.GetItem then return summary end

    local itemIDs = {}
    if targetsDB.GetTrackedTable then
        for itemID, enabled in pairs(targetsDB.GetTrackedTable(specID) or {}) do
            local numericID = tonumber(itemID)
            if enabled and numericID then itemIDs[numericID] = true end
        end
    end
    if targetsDB.GetStatusBucket then
        for itemID in pairs(targetsDB.GetStatusBucket(specID) or {}) do
            local numericID = tonumber(itemID)
            if numericID then itemIDs[numericID] = true end
        end
    end

    for itemID in pairs(itemIDs) do
        local status = targetsDB.GetStatus and targetsDB.GetStatus(specID, itemID) or nil
        if status and status ~= "ignore" then
            local item = mapping.GetItem(itemID, specID, classID)
            if item and SlotMatchesItem(slotName, item.slot) then
                if status == "acquired" then
                    summary.acquiredCount = summary.acquiredCount + 1
                elseif status == "bis" then
                    summary.bisCount = summary.bisCount + 1
                    summary.openCount = summary.openCount + 1
                else
                    summary.targetCount = summary.targetCount + 1
                    summary.openCount = summary.openCount + 1
                end

                -- Dungeon hints are controlled by Gear Targets. If the player
                -- marks an item as Target/BIS, keep showing its source even when
                -- the equipped item is already max rank or happens to match.
                if IsActiveTargetStatus(status) then
                    SplitSourceNames(item.dungeonName, summary.sources, summary.sourceSeen)
                end
            end
        end
    end

    table.sort(summary.sources)
    if summary.bisCount > 0 then
        summary.status = "bis"
    elseif summary.targetCount > 0 then
        summary.status = "target"
    elseif summary.acquiredCount > 0 then
        summary.status = "acquired"
    end
    return summary
end

local function ShortSourceText(sources, limit)
    local out = {}
    for index, source in ipairs(sources or {}) do
        if not limit or index <= limit then
            table.insert(out, (DB().GetDungeonCode and DB().GetDungeonCode(source)) or source)
        end
    end
    return table.concat(out, "/")
end

local function GetTargetProgress(specID)
    local progress = { total = 0, acquired = 0 }
    local targetsDB = KeyLab.LootTargetsDB
    if not targetsDB then return progress end

    local itemIDs = {}
    if targetsDB.GetTrackedTable then
        for itemID, enabled in pairs(targetsDB.GetTrackedTable(specID) or {}) do
            local numericID = tonumber(itemID)
            if enabled and numericID then itemIDs[numericID] = true end
        end
    end
    if targetsDB.GetStatusBucket then
        for itemID in pairs(targetsDB.GetStatusBucket(specID) or {}) do
            local numericID = tonumber(itemID)
            if numericID then itemIDs[numericID] = true end
        end
    end

    for itemID in pairs(itemIDs) do
        local status = targetsDB.GetStatus and targetsDB.GetStatus(specID, itemID) or nil
        if status and status ~= "ignore" then
            progress.total = progress.total + 1
            if status == "acquired" then progress.acquired = progress.acquired + 1 end
        end
    end

    return progress
end

local function CountTierPieces(slotsByName)
    local count = 0
    for _, slotName in ipairs(TIER_SLOTS) do
        local slot = slotsByName and slotsByName[slotName]
        if slot and (slot.tierIndicatorVisible or slot.tierDetected or slot.isTierPiece) then
            count = count + 1
        end
    end
    return count
end

local function DetermineCapability(history, playerLevel)
    local highestCompleted = tonumber(history and history.highestCompleted) or 0
    local highestTimed = tonumber(history and history.highestTimed) or 0
    local highest = math.max(highestCompleted, highestTimed)
    local trackName = "Entry"

    if playerLevel and playerLevel > 0 and playerLevel < 90 then
        return {
            trackName = "Entry",
            rank = TrackRank("Adventurer"),
            label = "Leveling",
            keyText = "Level 90",
            highestKey = 0,
            highestCompleted = highestCompleted,
            highestTimed = highestTimed,
        }
    end

    if highest >= 9 then
        trackName = "Myth"
    elseif highest >= 4 then
        trackName = "Hero"
    elseif highest >= 2 then
        trackName = "Champion"
    end

    local lane = DB().GetMythicPlusLane and DB().GetMythicPlusLane(trackName) or nil
    return {
        trackName = trackName,
        rank = TrackRank(trackName),
        label = (lane and lane.label) or "M+ lane",
        keyText = (lane and lane.keyText) or "M+",
        crestKey = lane and lane.crestKey or nil,
        crestName = lane and lane.crestName or nil,
        highestKey = highest,
        highestCompleted = highestCompleted,
        highestTimed = highestTimed,
    }
end

local function IsTierNeeded(slot, tierCount)
    if not slot or not slot.itemLink then return false end
    local tierEligible = slot.tierEligible or slot.isTierSlot or (DB().TierSlots and DB().TierSlots[slot.baseName or BaseSlotName(slot.slotName)])
    if not tierEligible then return false end
    if tierCount >= 4 then return false end
    if slot.tierIndicatorVisible or slot.tierDetected or slot.isTierPiece then return false end
    return TrackRank(slot.upgradeTrack or slot.trackName) >= TrackRank("Hero")
end

local function IsMissingEmbellishmentExpected(slot)
    if not slot or not slot.itemLink then return false end
    if not (slot.craftedIndicatorVisible or slot.craftedDetected or slot.isCrafted) then return false end
    if BaseSlotName(slot.slotName or slot.name) == "Trinket" then return false end
    if DB().IsEmbellishmentSlot and not DB().IsEmbellishmentSlot(slot.baseName or BaseSlotName(slot.slotName)) then return false end
    return not slot.embellishedDetected
end

local function PriorityColorForState(stateKey)
    if stateKey == "done" then return "green" end
    if stateKey == "missing" then return "red" end
    if stateKey == "target" or stateKey == "upgrade" then return "yellow" end
    if stateKey == "priority" then return "orange" end
    if stateKey == "na" then return "gray" end
    return "yellow"
end

local function StateKeyForScore(score, isMissing)
    score = tonumber(score) or 0
    if isMissing then return "missing" end
    if score >= 60 then return "priority" end
    if score > 0 then return "upgrade" end
    return "done"
end

local function UpgradeStatusForTrack(trackName)
    if trackName == "Unranked" or trackName == "Adventurer" then return "Upgrade to Veteran" end
    if trackName == "Veteran" then return "Upgrade to Champion" end
    if trackName == "Champion" then return "Upgrade to Hero" end
    if trackName == "Hero" then return "Upgrade to Myth" end
    return nil
end

local function CrestNeedForStatus(statusText)
    if statusText == "Upgrade to Champion" then
        return "championCrests", "Need Champion Crests: Run M+ 2-3"
    end
    if statusText == "Upgrade to Hero" then
        return "heroCrests", "Need Hero Crests: Run M+ 4-8"
    end
    if statusText == "Upgrade to Myth" then
        return "mythCrests", "Need Myth Crests: Run M+ 9+"
    end
    return nil, nil
end

local function BuildSlotState(slotName, capturedSlot, targetSummary, context)
    capturedSlot = capturedSlot or EmptyCapturedSlot(slotName)
    local slotState = {
        slotID = capturedSlot.slotID,
        slotName = slotName,
        slot = slotName,
        name = slotName,
        displayName = capturedSlot.displayName or DisplaySlotName(slotName),
        itemLink = capturedSlot.itemLink or capturedSlot.link,
        link = capturedSlot.itemLink or capturedSlot.link,
        itemID = capturedSlot.itemID,
        icon = capturedSlot.icon or capturedSlot.texture,
        texture = capturedSlot.icon or capturedSlot.texture,
        itemLevel = capturedSlot.itemLevel,
        upgradeTrack = capturedSlot.upgradeTrack or capturedSlot.trackName or "Unranked",
        trackName = capturedSlot.upgradeTrack or capturedSlot.trackName or "Unranked",
        upgradeRank = capturedSlot.upgradeRank,
        upgradeMaxRank = capturedSlot.upgradeMaxRank or capturedSlot.upgradeMax,
        badges = {},
        targetSources = targetSummary.sources or {},
        targetStatus = targetSummary.status,
        targetSummary = targetSummary,
        priorityScore = 0,
        priorityColor = "gray",
        isComplete = false,
        isNA = false,
        isCrafted = capturedSlot.craftedIndicatorVisible or capturedSlot.craftedDetected or capturedSlot.isCrafted,
        isTierPiece = capturedSlot.tierIndicatorVisible or capturedSlot.tierDetected or capturedSlot.isTierPiece,
        polishIssues = {},
        sourceText = ShortSourceText(targetSummary.sources, 3),
        centerSourceText = ShortSourceText(targetSummary.sources, 3),
        trackLabel = TrackLabel(capturedSlot),
        rankText = RankText(capturedSlot),
        itemLevelText = capturedSlot.itemLevel and ("ilvl " .. tostring(capturedSlot.itemLevel)) or "",
        debug = {},
    }

    if context.offHandBlocked then
        slotState.isNA = true
        slotState.isComplete = true
        slotState.trackName = ""
        slotState.upgradeTrack = ""
        slotState.trackLabel = ""
        slotState.statusText = ""
        slotState.reasonText = ""
        slotState.stateKey = "na"
        slotState.priorityColor = "gray"
        slotState.blank = true
        return slotState
    end

    local score = 0
    local baseScore = 0
    local isMissing = not slotState.itemLink
    local isMyth = TrackRank(slotState.upgradeTrack) >= TrackRank("Myth")
    local isAcquired = targetSummary.status == "acquired"
    local targetMissing = targetSummary.status == "target" or targetSummary.status == "bis"
    local tierNeeded = IsTierNeeded(capturedSlot, context.tierCount or 0)
    local enchantMissing = slotState.itemLink and IsEnchantableSlot(capturedSlot) and not capturedSlot.enchantDetected
    local gemMissing = slotState.itemLink and (tonumber(capturedSlot.emptySocketCount) or 0) > 0
    local voidforgeMissing = slotState.itemLink and capturedSlot.voidforgeCandidate and not (capturedSlot.ascendantVoidforgedDetected or capturedSlot.voidforgedDetected)
    local embellishmentMissing = IsMissingEmbellishmentExpected(capturedSlot)

    if isMissing then
        score = 100
    else
        baseScore = (isMyth or slotState.isCrafted) and 0 or TrackBaseScore(slotState.upgradeTrack)
        score = baseScore
    end

    if targetMissing then
        if not isMyth and not slotState.isCrafted then
            score = score + 15
        end
    end

    if tierNeeded then
        score = score + 30
    end

    if enchantMissing then
        AddBadge(slotState, "enchant", "Enchant", "missing")
        table.insert(slotState.polishIssues, { key = "enchant", label = "Enchant", text = "Missing enchant", score = 5 })
        score = score + 5
    end

    if gemMissing then
        AddBadge(slotState, "gem", "Gem", "missing")
        table.insert(slotState.polishIssues, { key = "gem", label = "Gem", text = "Empty gem socket", score = 5 })
        score = score + 5
    end

    if voidforgeMissing then
        table.insert(slotState.polishIssues, { key = "voidforge", label = "Voidforge", text = "Upgrade to Ascendant Voidforged", score = 10 })
        score = score + 10
    end

    if embellishmentMissing then
        AddBadge(slotState, "embellishment", "Embellish", "missing")
        table.insert(slotState.polishIssues, { key = "embellishment", label = "Embellish", text = "Missing embellishment", score = 5 })
        score = score + 5
    end

    local statusText
    local upgradeStatus = (not isMissing and not isMyth and not slotState.isCrafted) and UpgradeStatusForTrack(slotState.upgradeTrack) or nil
    if isMissing then
        statusText = "Missing Item"
    elseif upgradeStatus then
        statusText = upgradeStatus
    elseif tierNeeded then
        statusText = "Change to Tier"
    elseif targetSummary.status == "bis" then
        statusText = "Not BIS"
    elseif targetSummary.status == "target" then
        statusText = "Not Wanted"
    elseif voidforgeMissing then
        statusText = "Upgrade to Ascendant Voidforged"
    elseif isAcquired and #slotState.polishIssues == 0 and not tierNeeded and not voidforgeMissing then
        score = 0
        statusText = ""
    else
        statusText = ""
    end

    -- Myth gear can show target/polish/tier context, but target/BIS alone must
    -- not make it an Upgrade Priority Slot.
    if isMyth and targetMissing and #slotState.polishIssues == 0 and not tierNeeded and not voidforgeMissing then
        score = 0
    end

    local stateKey = StateKeyForScore(score, isMissing)
    slotState.isComplete = (score <= 0 and not isMissing)
    slotState.statusText = statusText
    slotState.reasonText = statusText
    slotState.stateKey = stateKey
    slotState.priorityScore = score
    slotState.includeInPriority = score > 0 and not slotState.isNA and not slotState.isComplete
    slotState.priorityColor = PriorityColorForState(stateKey)
    slotState.tierNeeded = tierNeeded
    slotState.enchantMissing = enchantMissing
    slotState.gemMissing = gemMissing
    slotState.voidforgeMissing = voidforgeMissing
    slotState.embellishmentMissing = embellishmentMissing
    slotState.debug = {
        trackRank = slotState.upgradeTrack,
        rank = slotState.upgradeRank,
        maxRank = slotState.upgradeMaxRank,
        enchantDetected = capturedSlot.enchantDetected == true,
        emptySocketCount = tonumber(capturedSlot.emptySocketCount) or 0,
        tierDetected = capturedSlot.tierIndicatorVisible == true or capturedSlot.tierDetected == true,
        craftedIndicatorVisible = capturedSlot.craftedIndicatorVisible == true,
        craftedDetected = slotState.isCrafted == true,
        embellishedDetected = capturedSlot.embellishedDetected == true,
        voidforgedDetected = capturedSlot.ascendantVoidforgedDetected == true or capturedSlot.voidforgedDetected == true,
        targetStatus = targetSummary.status,
        priorityScore = score,
    }

    return slotState
end

local function ComparePriority(a, b)
    if (a.priorityScore or 0) ~= (b.priorityScore or 0) then
        return (a.priorityScore or 0) > (b.priorityScore or 0)
    end
    if (a.itemLevel or 0) ~= (b.itemLevel or 0) then
        return (a.itemLevel or 0) < (b.itemLevel or 0)
    end
    return tostring(a.displayName or a.slotName) < tostring(b.displayName or b.slotName)
end

local function AddActivity(list, label, score, colorKey)
    if not label or label == "" or #list >= 4 then return end
    table.insert(list, {
        label = label,
        score = score or 3,
        colorKey = colorKey or "blue",
    })
end

local function AddJoinedActivity(list, prefix, names, score, colorKey, suffix)
    if type(names) ~= "table" or #names == 0 then return end
    AddActivity(list, prefix .. table.concat(names, ", ") .. (suffix or ""), score, colorKey)
end

local function BuildActivities(capability, currencyState, context)
    context = context or {}
    local activities = {}

    if context.blockedMessage then
        return activities
    end

    for _, need in ipairs(context.crestNeeds or {}) do
        AddActivity(activities, need, 5, "purple")
    end

    if context.hasCatalyst and ((tonumber(currencyState and currencyState.catalystCharges) or 0) > 0 or (tonumber(currencyState and currencyState.dawnlightManaflux) or 0) > 0) then
        AddJoinedActivity(activities, "Catalyst Available to make Tier of ", context.tierSlots, 4, "yellow", " available")
    end

    if context.hasVoidforge and (tonumber(currencyState and currencyState.ascendantVoidcore) or 0) > 0 then
        AddJoinedActivity(activities, "Ascendant Voidcore available to upgrade ", context.voidforgeSlots, 4, "yellow")
    end

    if context.craftCrestText and (tonumber(context.craftedCount) or 0) < 2 then
        AddActivity(activities, "No crafted items shown, you have enough " .. context.craftCrestText .. " available", 5, "green")
    end

    return activities
end

local function GetCraftWatch(currencyState)
    local crestCost = DB().CraftedGear and DB().CraftedGear.crestCost or 80
    local hero = tonumber(currencyState and currencyState.heroCrests) or 0
    local myth = tonumber(currencyState and currencyState.mythCrests) or 0
    local readyText
    if hero >= crestCost and myth >= crestCost then
        readyText = "hero and myth crests"
    elseif hero >= crestCost then
        readyText = "hero crests"
    elseif myth >= crestCost then
        readyText = "myth crests"
    end
    return {
        cost = crestCost,
        hero = hero,
        myth = myth,
        readyText = readyText,
        ready = hero >= crestCost or myth >= crestCost,
    }
end

local function BuildDebugRows(slotStates)
    local rows = {}
    for _, slotName in ipairs(Analysis.LeftSlots or {}) do
        local state = slotStates and slotStates[slotName]
        if state then table.insert(rows, state) end
    end
    for _, slotName in ipairs(Analysis.RightSlots or {}) do
        local state = slotStates and slotStates[slotName]
        if state then table.insert(rows, state) end
    end
    return rows
end

function Analysis.GetDashboardState()
    local itemLevel = GetEquippedItemLevel()
    local history = GetRunHistory()
    local specID = GetCurrentSpecID()
    local classID = GetCurrentClassID()
    local playerLevel = GetPlayerLevel()
    local currencyState = GetCurrencyState()
    local craftWatch = GetCraftWatch(currencyState)
    local progress = GetTargetProgress(specID)
    local blockedMessage = nil

    if playerLevel and playerLevel > 0 and playerLevel < 90 then
        blockedMessage = "Gear Dashboard becomes available at Level 90."
    elseif (tonumber(history.completed) or 0) == 0 then
        blockedMessage = "Complete at least one Mythic+ dungeon to unlock Gear Dashboard recommendations."
    elseif (tonumber(progress.total) or 0) == 0 then
        blockedMessage = "Save at least one gear target item to unlock Gear Dashboard recommendations in Gear Targets tab."
    end

    local capability = DetermineCapability(history, playerLevel)
    local slotsByName = GetAllEquippedSlots()
    local mainHand = slotsByName["Main Hand"]
    local tierCount = CountTierPieces(slotsByName)
    local plansBySlot = {}
    local priorityPlans = {}

    local function analyzeSlot(slotName)
        local capturedSlot = slotsByName[slotName] or EmptyCapturedSlot(slotName)
        local targetSummary = GetTargetSummary(slotName, specID, classID)
        local context = {
            tierCount = tierCount,
            offHandBlocked = slotName == "Off Hand" and IsTwoHandOrRangedWeapon(mainHand) and not capturedSlot.itemLink,
        }
        local slotState = BuildSlotState(slotName, capturedSlot, targetSummary, context)
        plansBySlot[slotName] = slotState
    end

    for _, slotName in ipairs(Analysis.LeftSlots or {}) do analyzeSlot(slotName) end
    for _, slotName in ipairs(Analysis.RightSlots or {}) do analyzeSlot(slotName) end

    for _, slotState in pairs(plansBySlot) do
        if slotState.includeInPriority then
            table.insert(priorityPlans, slotState)
        end
    end

    table.sort(priorityPlans, ComparePriority)
    for index, slotState in ipairs(priorityPlans) do
        if index <= 3 then slotState.priorityNumber = index end
    end

    local activityContext = {
        blockedMessage = blockedMessage,
        priorityPlans = priorityPlans,
        hasUpgradePlan = #priorityPlans > 0,
        activeTargetCount = 0,
        hasCatalyst = false,
        hasVoidforge = false,
        craftedCount = 0,
        craftCrestText = craftWatch.readyText,
        craftReady = craftWatch.ready == true,
        crestNeeds = {},
        crestNeedSeen = {},
        tierSlots = {},
        tierSlotSeen = {},
        voidforgeSlots = {},
        voidforgeSlotSeen = {},
    }

    for _, slotState in pairs(plansBySlot) do
        if slotState.isCrafted then
            activityContext.craftedCount = activityContext.craftedCount + 1
        end
        if slotState.targetStatus and slotState.targetStatus ~= "acquired" then
            activityContext.activeTargetCount = activityContext.activeTargetCount + 1
        end
        local _, crestNeed = CrestNeedForStatus(slotState.statusText)
        if crestNeed then
            AddUnique(activityContext.crestNeeds, activityContext.crestNeedSeen, crestNeed)
        end
        if slotState.tierNeeded then
            activityContext.hasCatalyst = true
            AddUnique(activityContext.tierSlots, activityContext.tierSlotSeen, slotState.displayName or slotState.slotName)
        end
        if slotState.voidforgeMissing then
            activityContext.hasVoidforge = true
            AddUnique(activityContext.voidforgeSlots, activityContext.voidforgeSlotSeen, slotState.displayName or slotState.slotName)
        end
    end

    local currentStatPriority = GetCurrentStatPriorityState(specID)
    local debugRows = BuildDebugRows(plansBySlot)

    return {
        itemLevel = itemLevel,
        history = history,
        capability = capability,
        specID = specID,
        statPriorityText = GetStatPriorityText(specID),
        currentStatPriorityText = currentStatPriority.text,
        statPriorityMismatch = currentStatPriority.mismatch,
        currencyState = currencyState,
        craftWatch = craftWatch,
        progress = progress,
        craftedCount = activityContext.craftedCount,
        slotStates = plansBySlot,
        plansBySlot = plansBySlot,
        priorityPlans = priorityPlans,
        activities = BuildActivities(capability, currencyState, activityContext),
        blockedMessage = blockedMessage,
        debugRows = debugRows,
    }
end

function Analysis.GetTrackRank(trackName)
    return TrackRank(trackName)
end

function Analysis.GetLogicSummary()
    return {
        "Capture reads equipped items and normalized tooltip fields.",
        "Analysis builds one slotState per dashboard slot.",
        "Missing items score 100 unless Off-Hand is blocked by a two-hand/ranged weapon.",
        "Track base score: Unranked/Adventurer 80, Veteran 60, Champion 40, Hero 20, Myth 0.",
        "Main status wording is Missing Item, Upgrade to track, Change to Tier, Not Wanted, Not BIS, or Upgrade to Ascendant Voidforged.",
        "Target/BIS missing adds 15 unless the equipped item is crafted or Myth track.",
        "Tier adds 30 only before 4-piece and only for eligible Hero/Myth pieces.",
        "Only missing Enchant, Gem, and crafted-item Embellishment are shown as small red item-card badges.",
        "Myth items are never priority slots only because target/BIS is missing.",
        "Next steps only show crest needs, catalyst opportunities, Ascendant Voidcore upgrades, and craft crest readiness.",
    }
end

local function DebugValue(value)
    if value == nil then return "-" end
    if value == true then return "true" end
    if value == false then return "false" end
    return tostring(value)
end

local function FormatDebugLine(slotState)
    local debug = slotState.debug or {}
    return string.format(
        "%s: %s %s ilvl=%s enchantDetected=%s emptySocketCount=%s tier=%s craftedIndicatorVisible=%s embellish=%s voidforged=%s target=%s score=%s",
        tostring(slotState.displayName or slotState.slotName or "-"),
        DebugValue(slotState.upgradeTrack),
        DebugValue(RankText(slotState)),
        DebugValue(slotState.itemLevel),
        DebugValue(debug.enchantDetected),
        DebugValue(debug.emptySocketCount),
        DebugValue(debug.tierDetected),
        DebugValue(debug.craftedIndicatorVisible),
        DebugValue(debug.embellishedDetected),
        DebugValue(debug.voidforgedDetected),
        DebugValue(debug.targetStatus),
        DebugValue(debug.priorityScore)
    )
end

function Analysis.GetGearDebugRows()
    local state = Analysis.GetDashboardState()
    return state.debugRows or {}, state
end

function Analysis.PrintGearDebug()
    local rows, state = Analysis.GetGearDebugRows()
    KeyLabDB = KeyLabDB or {}
    KeyLabDB.gearDashboardDebug = {
        capturedAt = time and time() or 0,
        itemLevel = state and state.itemLevel or nil,
        highestCompletedKey = state and state.history and state.history.highestCompleted or nil,
        highestTimedKey = state and state.history and state.history.highestTimed or nil,
        craftedCount = state and state.craftedCount or 0,
        craftWatch = state and state.craftWatch or nil,
        currencyState = state and state.currencyState or nil,
        rows = {},
    }

    local printFn = KeyLab.Print or print
    printFn("Gear Dashboard debug saved to KeyLabDB.gearDashboardDebug:")
    for _, slotState in ipairs(rows or {}) do
        local line = FormatDebugLine(slotState)
        table.insert(KeyLabDB.gearDashboardDebug.rows, {
            slotName = slotState.slotName,
            itemID = slotState.itemID,
            itemLevel = slotState.itemLevel,
            upgradeTrack = slotState.upgradeTrack,
            upgradeRank = slotState.upgradeRank,
            upgradeMaxRank = slotState.upgradeMaxRank,
            enchantDetected = slotState.debug and slotState.debug.enchantDetected,
            emptySocketCount = slotState.debug and slotState.debug.emptySocketCount,
            tierDetected = slotState.debug and slotState.debug.tierDetected,
            craftedIndicatorVisible = slotState.debug and slotState.debug.craftedIndicatorVisible,
            craftedDetected = slotState.debug and slotState.debug.craftedDetected,
            embellishedDetected = slotState.debug and slotState.debug.embellishedDetected,
            voidforgedDetected = slotState.debug and slotState.debug.voidforgedDetected,
            targetStatus = slotState.debug and slotState.debug.targetStatus,
            priorityScore = slotState.priorityScore,
            badges = slotState.badges,
            line = line,
        })
        printFn(line)
    end
end

return Analysis
