local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.StatGoalMatcher = KeyLab.StatGoalMatcher or {}
local Matcher = KeyLab.StatGoalMatcher

Matcher.Config = Matcher.Config or {
    exactCombinationLimit = 150000,
    beamWidth = 1200,
    workPerFrame = 500,
}

local EXACT_COMBINATION_LIMIT = tonumber(Matcher.Config.exactCombinationLimit) or 150000
local BEAM_WIDTH = tonumber(Matcher.Config.beamWidth) or 1200
local WORK_PER_FRAME = tonumber(Matcher.Config.workPerFrame) or 500

local SLOT_ORDER = {
    "Head", "Neck", "Shoulders", "Back", "Chest", "Wrist", "Hands", "Waist",
    "Legs", "Feet", "Finger 1", "Finger 2", "Trinket 1", "Trinket 2", "Main Hand", "Off Hand",
}

local SECONDARY = { "Crit", "Haste", "Mastery", "Vers" }
local GOAL_KEYS = { Crit = "crit", Haste = "haste", Mastery = "mastery", Vers = "versatility" }
local INTERNAL_KEYS = { crit = "Crit", haste = "Haste", mastery = "Mastery", versatility = "Vers" }
local PRIORITY_WEIGHTS = { 1.75, 1.50, 1.25, 1.00 }
local CLOSE_RESULT_DIFFERENCE = 0.25
local GOAL_MATCH_TOLERANCE = 0.10
local ITEM_BUDGET_GROWTH_PER_15_LEVELS = 1.15
local TRACK_NAMES = { "Adventurer", "Veteran", "Champion", "Hero", "Myth" }

local function GetTrackMaximumItemLevel(trackName)
    local seasonLevels = KeyLab and KeyLab.GearingDatabase and KeyLab.GearingDatabase.TrackItemLevels
    local track = seasonLevels and seasonLevels[trackName]
    return tonumber(track and track.maximum)
end
local OWNED_SLOT_BY_EQUIP_LOC = {
    INVTYPE_HEAD = "Head", INVTYPE_NECK = "Neck", INVTYPE_SHOULDER = "Shoulders",
    INVTYPE_CLOAK = "Back", INVTYPE_CHEST = "Chest", INVTYPE_ROBE = "Chest",
    INVTYPE_WRIST = "Wrist", INVTYPE_HAND = "Hands", INVTYPE_WAIST = "Waist",
    INVTYPE_LEGS = "Legs", INVTYPE_FEET = "Feet", INVTYPE_FINGER = "Finger",
    INVTYPE_TRINKET = "Trinket", INVTYPE_WEAPON = "One-Hand",
    INVTYPE_WEAPONMAINHAND = "One-Hand", INVTYPE_WEAPONOFFHAND = "Off Hand",
    INVTYPE_2HWEAPON = "Two-Hand", INVTYPE_RANGED = "Ranged",
    INVTYPE_RANGEDRIGHT = "Ranged", INVTYPE_HOLDABLE = "Off Hand", INVTYPE_SHIELD = "Off Hand",
}
local DUAL_WIELD_SPECS = {
    [72] = true, [251] = true, [259] = true, [260] = true, [261] = true,
    [263] = true, [268] = true, [269] = true, [577] = true, [581] = true,
}
local activeJob

local function CurrentSeasonKey()
    return KeyLab.SeasonData and KeyLab.SeasonData.GetCurrentSeasonKey
        and KeyLab.SeasonData.GetCurrentSeasonKey() or "MN_S2"
end

local function NormalizeSeasonKey(value, fallback)
    if KeyLab.SeasonData and KeyLab.SeasonData.NormalizeSeasonKey then
        return KeyLab.SeasonData.NormalizeSeasonKey(value, fallback)
    end
    return value == "MN_S1" and "MN_S1" or fallback or "MN_S2"
end

local function GetSavedResults(seasonKey)
    KeyLabDB = type(KeyLabDB) == "table" and KeyLabDB or {}
    if type(KeyLabDB.statGoalMatcherResults) ~= "table" then KeyLabDB.statGoalMatcherResults = {} end
    if tonumber(KeyLabDB.statGoalMatcherSeasonVersion) ~= 1 then
        local migrated = { MN_S1 = {}, MN_S2 = {} }
        for specID, result in pairs(KeyLabDB.statGoalMatcherResults) do
            if tonumber(specID) and type(result) == "table" then
                local resultSeason = KeyLab.SeasonData and KeyLab.SeasonData.GetSeasonKeyForTimestamp
                    and KeyLab.SeasonData.GetSeasonKeyForTimestamp(result.completedAt, "MN_S1") or "MN_S1"
                result.seasonKey = resultSeason
                result.mnSeason = resultSeason == "MN_S1" and 1 or 2
                migrated[resultSeason][tonumber(specID)] = result
            end
        end
        KeyLabDB.statGoalMatcherResults = migrated
        KeyLabDB.statGoalMatcherSeasonVersion = 1
    end
    seasonKey = NormalizeSeasonKey(seasonKey, CurrentSeasonKey())
    KeyLabDB.statGoalMatcherResults[seasonKey] = KeyLabDB.statGoalMatcherResults[seasonKey] or {}
    return KeyLabDB.statGoalMatcherResults[seasonKey]
end

local function ZeroStats()
    return { Crit = 0, Haste = 0, Mastery = 0, Vers = 0 }
end

local function CopyStats(source)
    local out = ZeroStats()
    for _, key in ipairs(SECONDARY) do out[key] = tonumber(source and source[key]) or 0 end
    return out
end

local function AddStats(left, right)
    local out = ZeroStats()
    for _, key in ipairs(SECONDARY) do out[key] = (tonumber(left and left[key]) or 0) + (tonumber(right and right[key]) or 0) end
    return out
end

local function StatsTotal(stats)
    local total = 0
    for _, key in ipairs(SECONDARY) do total = total + (tonumber(stats and stats[key]) or 0) end
    return total
end

local function ScaleStats(stats, factor)
    local out = ZeroStats()
    factor = math.max(0, tonumber(factor) or 1)
    for _, key in ipairs(SECONDARY) do out[key] = (tonumber(stats and stats[key]) or 0) * factor end
    return out
end

local function Median(values)
    local sorted = {}
    for _, value in ipairs(values or {}) do
        value = tonumber(value)
        if value then table.insert(sorted, value) end
    end
    table.sort(sorted)
    if #sorted == 0 then return nil end
    local middle = math.floor((#sorted + 1) / 2)
    if #sorted % 2 == 1 then return sorted[middle] end
    return (sorted[middle] + sorted[middle + 1]) / 2
end

local function ItemBudgetScale(fromItemLevel, toItemLevel)
    fromItemLevel = tonumber(fromItemLevel)
    toItemLevel = tonumber(toItemLevel)
    if not fromItemLevel or not toItemLevel or fromItemLevel <= 0 or toItemLevel <= fromItemLevel then return 1 end
    return ITEM_BUDGET_GROWTH_PER_15_LEVELS ^ ((toItemLevel - fromItemLevel) / 15)
end

local RATING_KEYS = {
    Crit = CR_CRIT_SPELL or CR_CRIT_MELEE or 11,
    Haste = CR_HASTE_SPELL or CR_HASTE_MELEE or 20,
    Mastery = CR_MASTERY or 26,
    Vers = CR_VERSATILITY_DAMAGE_DONE or 29,
}

local function SafeCallNumber(func, ...)
    if type(func) ~= "function" then return nil end
    local ok, value = pcall(func, ...)
    return ok and tonumber(value) or nil
end

local function CurrentSheetPercentages()
    local masteryEffect, masteryCoefficient
    if type(GetMasteryEffect) == "function" then
        local ok, effect, coefficient = pcall(GetMasteryEffect)
        if ok then
            masteryEffect = tonumber(effect)
            masteryCoefficient = tonumber(coefficient)
        end
    end
    return {
        Crit = SafeCallNumber(GetCritChance),
        Haste = SafeCallNumber(GetHaste),
        Mastery = masteryEffect,
        Vers = SafeCallNumber(GetCombatRatingBonus, RATING_KEYS.Vers),
    }, masteryCoefficient
end

local function BuildProjectionContext(equippedItemStats, specID, matchStyle)
    local sheet, masteryCoefficient = CurrentSheetPercentages()
    local context = {
        baselineRatings = ZeroStats(),
        basePercentages = ZeroStats(),
        currentSheet = sheet,
        masteryCoefficient = tonumber(masteryCoefficient) or 1,
        bonusCache = { Crit = {}, Haste = {}, Mastery = {}, Vers = {} },
        matchStyle = matchStyle == "priority" and "priority" or "balanced",
        priorityWeights = {},
        priorityOrder = {},
    }
    local displayOrder = KeyLab.StatGoalsDB and KeyLab.StatGoalsDB.GetDisplayOrder and KeyLab.StatGoalsDB.GetDisplayOrder(specID) or {}
    local prioritySeen = {}
    for rank, statKey in ipairs(displayOrder) do
        local internalKey = INTERNAL_KEYS[statKey]
        if internalKey and not prioritySeen[internalKey] then
            context.priorityWeights[internalKey] = PRIORITY_WEIGHTS[rank] or 1
            context.priorityOrder[#context.priorityOrder + 1] = internalKey
            prioritySeen[internalKey] = true
        end
    end
    for _, key in ipairs(SECONDARY) do
        if not prioritySeen[key] then
            context.priorityWeights[key] = context.priorityWeights[key] or 1
            context.priorityOrder[#context.priorityOrder + 1] = key
            prioritySeen[key] = true
        end
    end
    for _, key in ipairs(SECONDARY) do
        local ratingIndex = RATING_KEYS[key]
        local currentRating = SafeCallNumber(GetCombatRating, ratingIndex) or tonumber(equippedItemStats and equippedItemStats[key]) or 0
        local currentBonus = SafeCallNumber(GetCombatRatingBonus, ratingIndex) or 0
        local sheetValue = tonumber(sheet[key]) or currentBonus
        local coefficient = key == "Mastery" and context.masteryCoefficient or 1
        context.baselineRatings[key] = math.max(0, currentRating - (tonumber(equippedItemStats and equippedItemStats[key]) or 0))
        context.basePercentages[key] = sheetValue - (currentBonus * coefficient)
    end
    return context
end

local function RatingBonusForValue(context, key, ratingValue)
    ratingValue = math.max(0, tonumber(ratingValue) or 0)
    local cache = context and context.bonusCache and context.bonusCache[key]
    local cacheKey = tostring(math.floor(ratingValue + 0.5))
    if cache and cache[cacheKey] ~= nil then return cache[cacheKey] end

    local ratingIndex = RATING_KEYS[key]
    local bonus = SafeCallNumber(GetCombatRatingBonusForCombatRatingValue, ratingIndex, ratingValue)
    if bonus == nil then
        local currentRating = SafeCallNumber(GetCombatRating, ratingIndex) or 0
        local currentBonus = SafeCallNumber(GetCombatRatingBonus, ratingIndex) or 0
        bonus = currentRating > 0 and (ratingValue * currentBonus / currentRating) or 0
    end
    if cache then cache[cacheKey] = bonus end
    return bonus
end

local function ProjectPercentages(itemStats, context)
    local projected = ZeroStats()
    if not context then return projected end
    for _, key in ipairs(SECONDARY) do
        local totalRating = (tonumber(context.baselineRatings and context.baselineRatings[key]) or 0)
            + (tonumber(itemStats and itemStats[key]) or 0)
        local coefficient = key == "Mastery" and (tonumber(context.masteryCoefficient) or 1) or 1
        projected[key] = (tonumber(context.basePercentages and context.basePercentages[key]) or 0)
            + (RatingBonusForValue(context, key, totalRating) * coefficient)
    end
    return projected
end

local function StatsSignature(stats)
    return table.concat({
        tostring(tonumber(stats and stats.Crit) or 0),
        tostring(tonumber(stats and stats.Haste) or 0),
        tostring(tonumber(stats and stats.Mastery) or 0),
        tostring(tonumber(stats and stats.Vers) or 0),
    }, ":")
end

local function ZeroPriority()
    return { myth = 0, primary = 0, stamina = 0, itemLevel = 0 }
end

local function CopyPriority(source)
    local out = ZeroPriority()
    for key in pairs(out) do out[key] = tonumber(source and source[key]) or 0 end
    return out
end

local function AddPriority(left, right)
    local out = ZeroPriority()
    for key in pairs(out) do out[key] = (tonumber(left and left[key]) or 0) + (tonumber(right and right[key]) or 0) end
    return out
end

local function PrioritySignature(priority)
    return table.concat({
        tostring(tonumber(priority and priority.myth) or 0),
        tostring(tonumber(priority and priority.primary) or 0),
        tostring(tonumber(priority and priority.stamina) or 0),
        tostring(tonumber(priority and priority.itemLevel) or 0),
    }, ":")
end

local function ComparePriority(left, right)
    for _, key in ipairs({ "myth", "primary", "stamina", "itemLevel" }) do
        local leftValue = tonumber(left and left[key]) or 0
        local rightValue = tonumber(right and right[key]) or 0
        if leftValue ~= rightValue then return leftValue > rightValue and 1 or -1 end
    end
    return 0
end

local function CopyTable(source)
    local out = {}
    for key, value in pairs(source or {}) do out[key] = value end
    return out
end

local function CopyArray(source)
    local out = {}
    for _, value in ipairs(source or {}) do table.insert(out, value) end
    return out
end

local function GetGoals(specID)
    local saved = KeyLab.StatGoalsDB and KeyLab.StatGoalsDB.GetGoals and KeyLab.StatGoalsDB.GetGoals(specID) or {}
    local goals = {}
    for _, key in ipairs(SECONDARY) do goals[key] = tonumber(saved.targets and saved.targets[GOAL_KEYS[key]]) or 0 end
    return goals
end

local function Score(stats, goals, projection)
    local percentages = ProjectPercentages(stats, projection)
    local difference, largest = 0, 0
    for _, key in ipairs(SECONDARY) do
        local projectedValue = tonumber(percentages[key]) or 0
        local goalValue = tonumber(goals[key]) or 0
        local deviation = math.abs(projectedValue - goalValue)
        local penalty = deviation
        if projection and projection.matchStyle == "priority" then
            local weight = tonumber(projection.priorityWeights and projection.priorityWeights[key]) or 1
            penalty = projectedValue < goalValue and (deviation * weight) or (deviation * 0.35)
        end
        difference = difference + penalty
        if deviation > largest then largest = deviation end
    end
    return difference, largest, percentages
end

-- Search states are immutable once they are created. Cache their projected
-- percentages and final score so table.sort does not rebuild the same values
-- for every comparison. Large bounded searches can compare one state dozens
-- of times, so this also avoids a considerable amount of temporary garbage.
local function EvaluateState(state, goals, projection)
    if state._evaluationGoals ~= goals or state._evaluationProjection ~= projection then
        local difference, largest, percentages = Score(state.stats, goals, projection)
        state._evaluationGoals = goals
        state._evaluationProjection = projection
        state._scoreDifference = difference
        state._scoreLargest = largest
        state._projectedPercentages = percentages
    end
    return state._scoreDifference, state._scoreLargest, state._projectedPercentages
end

local function GoalDeviation(percentages, goals, key)
    return math.abs((tonumber(percentages and percentages[key]) or 0) - (tonumber(goals and goals[key]) or 0))
end

local function PriorityOrder(projection)
    return projection and projection.priorityOrder and #projection.priorityOrder > 0
        and projection.priorityOrder or SECONDARY
end

local function IsBetter(candidate, current, goals, projection)
    if not candidate then return false end
    if not current then return true end
    if projection and projection.matchStyle == "priority" then
        local _, _, candidatePercentages = EvaluateState(candidate, goals, projection)
        local _, _, currentPercentages = EvaluateState(current, goals, projection)
        for _, key in ipairs(PriorityOrder(projection)) do
            local candidateDeviation = GoalDeviation(candidatePercentages, goals, key)
            local currentDeviation = GoalDeviation(currentPercentages, goals, key)
            if math.abs(candidateDeviation - currentDeviation) > 0.000001 then
                return candidateDeviation < currentDeviation
            end
        end
        local priorityComparison = ComparePriority(candidate.priority, current.priority)
        if priorityComparison ~= 0 then return priorityComparison > 0 end
        return tostring(candidate.key or "") < tostring(current.key or "")
    end
    local candidateDifference, candidateLargest = EvaluateState(candidate, goals, projection)
    local currentDifference, currentLargest = EvaluateState(current, goals, projection)
    if math.abs(candidateDifference - currentDifference) > CLOSE_RESULT_DIFFERENCE then
        return candidateDifference < currentDifference
    end
    local priorityComparison = ComparePriority(candidate.priority, current.priority)
    if priorityComparison ~= 0 then return priorityComparison > 0 end
    if math.abs(candidateDifference - currentDifference) > 0.000001 then return candidateDifference < currentDifference end
    if math.abs(candidateLargest - currentLargest) > 0.000001 then return candidateLargest < currentLargest end
    return tostring(candidate.key or "") < tostring(current.key or "")
end

local function ItemStats(item, specID)
    if type(item) == "table" and type(item.ownedStats) == "table" then return CopyStats(item.ownedStats) end
    if type(item) == "table" and type(item.matcherStats) == "table" then return CopyStats(item.matcherStats) end
    local mapping = KeyLab.GearLootMapping
    return mapping and mapping.GetItemStats and CopyStats(mapping.GetItemStats(item, specID)) or ZeroStats()
end

local function NormalizeMasterCandidates(candidates, specID)
    local cohorts = {}
    for _, item in ipairs(candidates or {}) do
        local slot = tostring(item.slot or "Unknown")
        local itemLevel = tonumber(item.itemLevel) or 0
        local stats = KeyLab.GearLootMapping and KeyLab.GearLootMapping.GetItemStats
            and CopyStats(KeyLab.GearLootMapping.GetItemStats(item, specID)) or CopyStats(item.stats)
        local total = StatsTotal(stats)
        if total > 0 then
            cohorts[slot] = cohorts[slot] or {}
            cohorts[slot][itemLevel] = cohorts[slot][itemLevel] or {}
            table.insert(cohorts[slot][itemLevel], total)
            item.originalMatcherStats = stats
        end
    end

    local cohortMedians, referenceBudgets = {}, {}
    for slot, levels in pairs(cohorts) do
        cohortMedians[slot] = {}
        local levelBudgets = {}
        for itemLevel, totals in pairs(levels) do
            local median = Median(totals)
            cohortMedians[slot][itemLevel] = median
            if median and median > 0 then table.insert(levelBudgets, median) end
        end
        referenceBudgets[slot] = Median(levelBudgets)
    end

    for _, item in ipairs(candidates or {}) do
        local slot = tostring(item.slot or "Unknown")
        local itemLevel = tonumber(item.itemLevel) or 0
        local original = CopyStats(item.originalMatcherStats or item.stats)
        local cohortBudget = cohortMedians[slot] and cohortMedians[slot][itemLevel]
        local referenceBudget = referenceBudgets[slot]
        local factor = cohortBudget and cohortBudget > 0 and referenceBudget and referenceBudget > 0
            and (referenceBudget / cohortBudget) or 1
        item.matcherStats = ScaleStats(original, factor)
        item.matchNormalization = {
            kind = "neutral_slot_budget",
            recordedItemLevel = itemLevel,
            originalStats = original,
            referenceBudget = referenceBudget,
            cohortBudget = cohortBudget,
            factor = factor,
        }
    end
    return candidates
end

local function AddUniqueID(list, seen, itemID)
    itemID = tonumber(itemID)
    if not itemID or seen[itemID] then return end
    seen[itemID] = true
    table.insert(list, itemID)
end

local function SortIDs(list)
    table.sort(list, function(a, b) return tonumber(a or 0) < tonumber(b or 0) end)
end

local function GroupSingleSlotItems(slotInstance, items, specID)
    local groups = {}
    for _, item in ipairs(items or {}) do
        local stats = ItemStats(item, specID)
        if StatsTotal(stats) > 0 then
            local priority = CopyPriority(item.matchPriority)
            local signature = StatsSignature(stats) .. (item.matchPriority and (":" .. PrioritySignature(priority)) or "")
            local group = groups[signature]
            if not group then
                group = {
                    stats = stats,
                    priority = priority,
                    item = item,
                    itemIDs = {},
                    itemSeen = {},
                    ownedCounts = {},
                    sourceID = item.sourceID,
                }
                groups[signature] = group
            end
            AddUniqueID(group.itemIDs, group.itemSeen, item.itemID)
            if tonumber(item.ownedCount) then group.ownedCounts[tonumber(item.itemID)] = tonumber(item.ownedCount) end
            if tonumber(item.itemID) < tonumber(group.item and group.item.itemID or item.itemID) then group.item = item end
        end
    end

    local options = {}
    for signature, group in pairs(groups) do
        SortIDs(group.itemIDs)
        local representative = group.itemIDs[1]
        table.insert(options, {
            stats = group.stats,
            priority = group.priority,
            key = slotInstance .. ":" .. signature .. ":" .. tostring(representative),
            assignments = {
                {
                    slotInstance = slotInstance,
                    itemID = representative,
                    sourceID = group.sourceID,
                    equivalentItemIDs = group.itemIDs,
                    ownedCounts = next(group.ownedCounts) and group.ownedCounts or nil,
                    matcherStats = CopyStats(group.stats),
                    name = group.item and group.item.name,
                    sourceName = group.item and group.item.sourceName,
                    itemLink = group.item and (group.item.itemLink or group.item.link),
                    upgradeTrack = group.item and group.item.upgradeTrack,
                    upgradeRank = group.item and group.item.upgradeRank,
                    upgradeMaxRank = group.item and group.item.upgradeMaxRank,
                    itemLevel = group.item and group.item.itemLevel,
                    projectedItemLevel = group.item and group.item.projectedItemLevel,
                    requiresUpgrade = group.item and group.item.requiresUpgrade == true,
                },
            },
        })
    end
    table.sort(options, function(a, b) return tostring(a.key) < tostring(b.key) end)
    return options
end

local function SecondaryKeyFromItemStat(rawKey)
    local key = string.upper(tostring(rawKey or ""))
    if key:find("VERSATILITY", 1, true) then return "Vers" end
    if not key:find("RATING", 1, true) then return nil end
    if key:find("CRIT", 1, true) then return "Crit" end
    if key:find("HASTE", 1, true) then return "Haste" end
    if key:find("MASTERY", 1, true) then return "Mastery" end
    return nil
end

local function GetLiveItemStats(itemLink, tooltipLines)
    local out = ZeroStats()
    local priority = ZeroPriority()
    local enhancements = ZeroStats()
    local hasItemStats = false
    local function ReadStatTable(values, target, addValues)
        if type(values) ~= "table" then return end
        for rawKey, rawValue in pairs(values) do
            local key = string.upper(tostring(rawKey or ""))
            local value = tonumber(rawValue) or 0
            local function Store(statKey)
                if addValues then target[statKey] = (tonumber(target[statKey]) or 0) + value
                else target[statKey] = math.max(tonumber(target[statKey]) or 0, value) end
            end
            local secondaryKey = SecondaryKeyFromItemStat(key)
            if secondaryKey then Store(secondaryKey) end
            if target == out and key:find("STAMINA", 1, true) then priority.stamina = math.max(priority.stamina, value) end
            if target == out and (key:find("STRENGTH", 1, true) or key:find("AGILITY", 1, true) or key:find("INTELLECT", 1, true)) then
                priority.primary = math.max(priority.primary, value)
            end
        end
    end
    if itemLink and C_Item and C_Item.GetItemStats then
        local ok, values = pcall(C_Item.GetItemStats, itemLink)
        if ok and type(values) == "table" then
            hasItemStats = true
            ReadStatTable(values, out, false)
        end
    end

    if itemLink and C_Item and C_Item.GetItemGem and C_Item.GetItemStats then
        for gemIndex = 1, 4 do
            local ok, _, gemLink = pcall(C_Item.GetItemGem, itemLink, gemIndex)
            if ok and gemLink then
                local statsOK, gemStats = pcall(C_Item.GetItemStats, gemLink)
                if statsOK then ReadStatTable(gemStats, enhancements, true) end
            end
        end
    end

    local labels = {
        Crit = { "critical strike", "crit" },
        Haste = { "haste" },
        Mastery = { "mastery" },
        Vers = { "versatility" },
    }
    for _, line in ipairs(tooltipLines or {}) do
        local clean = tostring(line or ""):gsub(",", "")
        local lower = string.lower(clean)
        local amount = tonumber(clean:match("([%+%-]?%d+)%s")) or 0
        local effectLine = lower:find("equip:", 1, true) or lower:find("use:", 1, true)
            or lower:find("chance to", 1, true) or lower:find("for %d+ sec")
        if amount > 0 then
            for statKey, aliases in pairs(labels) do
                for _, alias in ipairs(aliases) do
                    if lower:find(alias, 1, true) then
                        if lower:find("enchanted:", 1, true) then
                            enhancements[statKey] = math.max(enhancements[statKey], amount)
                        elseif not hasItemStats and not effectLine then
                            out[statKey] = math.max(out[statKey], amount)
                        end
                        break
                    end
                end
            end
        end
    end
    return out, priority, enhancements
end

local function GetBagTooltipLines(bagID, bagSlot, itemLink)
    local data
    if C_TooltipInfo and C_TooltipInfo.GetBagItem then
        local ok, result = pcall(C_TooltipInfo.GetBagItem, bagID, bagSlot)
        if ok then data = result end
    end
    if not data and C_TooltipInfo and C_TooltipInfo.GetHyperlink and itemLink then
        local ok, result = pcall(C_TooltipInfo.GetHyperlink, itemLink)
        if ok then data = result end
    end
    local lines = {}
    for _, line in ipairs(type(data) == "table" and data.lines or {}) do
        if line.leftText and line.leftText ~= "" then table.insert(lines, tostring(line.leftText)) end
        if line.rightText and line.rightText ~= "" then table.insert(lines, tostring(line.rightText)) end
    end
    return lines
end

local function ParseUpgradeTrack(tooltipLines)
    for _, line in ipairs(tooltipLines or {}) do
        local clean = tostring(line or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        local lower = string.lower(clean)
        for _, trackName in ipairs(TRACK_NAMES) do
            local rank, maxRank = lower:match(string.lower(trackName) .. "%s+(%d+)/(%d+)")
            if rank and maxRank then
                return {
                    track = trackName,
                    rank = tonumber(rank),
                    maxRank = tonumber(maxRank),
                    rawLine = clean,
                }
            end
        end
    end
    return { track = nil, rank = nil, maxRank = nil, rawLine = nil }
end

local function GetLiveItemLevel(itemLink)
    if itemLink and C_Item and C_Item.GetDetailedItemLevelInfo then
        local ok, value = pcall(C_Item.GetDetailedItemLevelInfo, itemLink)
        if ok then return tonumber(value) or 0 end
    end
    if itemLink and GetDetailedItemLevelInfo then
        local ok, value = pcall(GetDetailedItemLevelInfo, itemLink)
        if ok then return tonumber(value) or 0 end
    end
    return 0
end

local function ProjectOwnedItem(stats, priority, itemLevel, upgrade)
    local projectedStats = CopyStats(stats)
    local projectedPriority = CopyPriority(priority)
    local track = upgrade and upgrade.track
    local rank = tonumber(upgrade and upgrade.rank)
    local maxRank = tonumber(upgrade and upgrade.maxRank)
    local currentItemLevel = tonumber(itemLevel) or 0
    local trackMaximum = GetTrackMaximumItemLevel(track)
    local projectedItemLevel = trackMaximum and math.max(currentItemLevel, trackMaximum) or currentItemLevel
    local requiresUpgrade = trackMaximum and rank and maxRank and rank < maxRank and projectedItemLevel > currentItemLevel or false
    local factor = requiresUpgrade and ItemBudgetScale(currentItemLevel, projectedItemLevel) or 1
    if factor > 1 then
        projectedStats = ScaleStats(stats, factor)
        projectedPriority.primary = projectedPriority.primary * factor
        projectedPriority.stamina = projectedPriority.stamina * factor
    end
    projectedPriority.itemLevel = projectedItemLevel
    projectedPriority.myth = track == "Myth" and 1 or 0
    return projectedStats, projectedPriority, projectedItemLevel, requiresUpgrade, factor
end

local function OwnedSlotInstances(slot, itemID, specID)
    local mapping = KeyLab.GearLootMapping
    local known = mapping and mapping.GetItem and mapping.GetItem(itemID, specID) or nil
    if known and mapping.IsItemEligibleForSpec and not mapping.IsItemEligibleForSpec(known, specID) then return {} end
    if known and mapping.GetEligibleSlotInstances then
        local knownSlots = mapping.GetEligibleSlotInstances(known, specID)
        if #knownSlots > 0 then return knownSlots end
    end
    if slot == "Finger" then return { "Finger 1", "Finger 2" } end
    if slot == "Trinket" then return { "Trinket 1", "Trinket 2" } end
    if slot == "Off Hand" then return { "Off Hand" } end
    if slot == "One-Hand" then
        if DUAL_WIELD_SPECS[tonumber(specID)] then return { "Main Hand", "Off Hand" } end
        return { "Main Hand" }
    end
    if slot == "Two-Hand" then
        if tonumber(specID) == 72 then return { "Main Hand", "Off Hand" } end
        return { "Main Hand" }
    end
    if slot == "Ranged" then return { "Main Hand" } end
    return slot and slot ~= "" and { slot } or {}
end

local function OwnedStatText(stats)
    local parts = {}
    for _, key in ipairs(SECONDARY) do
        local value = tonumber(stats and stats[key]) or 0
        if value > 0 then table.insert(parts, key .. " " .. tostring(math.floor(value + 0.5))) end
    end
    return #parts > 0 and table.concat(parts, " / ") or "-"
end

local function GetOwnedBagCandidates(specID)
    local candidates, byID = {}, {}
    if not (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemLink) then
        return candidates, byID
    end

    local bagIDs, bagSeen = { 0 }, { [0] = true }
    local maxBag = tonumber(NUM_BAG_SLOTS) or 4
    for bagID = 1, maxBag do bagIDs[#bagIDs + 1] = bagID; bagSeen[bagID] = true end
    local reagentBag = Enum and Enum.BagIndex and tonumber(Enum.BagIndex.ReagentBag) or 5
    if reagentBag and not bagSeen[reagentBag] then bagIDs[#bagIDs + 1] = reagentBag end

    for _, bagID in ipairs(bagIDs) do
        local slotCount = tonumber(C_Container.GetContainerNumSlots(bagID)) or 0
        for bagSlot = 1, slotCount do
            local itemLink = C_Container.GetContainerItemLink(bagID, bagSlot)
            local itemID = C_Container.GetContainerItemID and C_Container.GetContainerItemID(bagID, bagSlot)
                or tonumber(tostring(itemLink or ""):match("item:(%d+)"))
            if itemLink and itemID and GetItemInfoInstant then
                local _, _, _, equipLoc, icon = GetItemInfoInstant(itemLink)
                local slot = OWNED_SLOT_BY_EQUIP_LOC[tostring(equipLoc or "")]
                local tooltipLines = slot and GetBagTooltipLines(bagID, bagSlot, itemLink) or {}
                local stats, priority, enhancements
                if slot then stats, priority, enhancements = GetLiveItemStats(itemLink, tooltipLines) end
                priority = CopyPriority(priority)
                local upgrade = ParseUpgradeTrack(tooltipLines)
                local currentItemLevel = GetLiveItemLevel(itemLink)
                local projectedBaseStats, projectedPriority, projectedItemLevel, requiresUpgrade, projectionFactor =
                    ProjectOwnedItem(stats, priority, currentItemLevel, upgrade)
                local currentStats = AddStats(stats, enhancements)
                local projectedStats = AddStats(projectedBaseStats, enhancements)
                priority = projectedPriority
                local eligibleSlots = slot and OwnedSlotInstances(slot, itemID, specID) or {}
                if slot and #eligibleSlots > 0 and StatsTotal(currentStats) > 0 then
                    local name, resolvedLink
                    if GetItemInfo then name, resolvedLink = GetItemInfo(itemLink) end
                    local known = KeyLab.GearLootMapping and KeyLab.GearLootMapping.GetItem
                        and KeyLab.GearLootMapping.GetItem(itemID, specID) or nil
                    local dualWield = known and KeyLab.GearLootMapping.IsDualWieldEligible
                        and KeyLab.GearLootMapping.IsDualWieldEligible(itemID, specID) or false
                    if not dualWield and equipLoc == "INVTYPE_WEAPON" and DUAL_WIELD_SPECS[tonumber(specID)] then dualWield = true end
                    if not dualWield and equipLoc == "INVTYPE_2HWEAPON" and tonumber(specID) == 72 then dualWield = true end
                    local record = {
                        itemID = tonumber(itemID),
                        name = name or (known and known.name) or ("Item " .. tostring(itemID)),
                        link = resolvedLink or itemLink,
                        itemLink = resolvedLink or itemLink,
                        icon = icon or (known and known.icon),
                        slot = slot,
                        equipLoc = equipLoc,
                        sourceName = upgrade.track and ("Bags - " .. upgrade.track) or "Bags",
                        sourceType = "Owned",
                        ownedLocation = "Bags",
                        currentOwnedStats = currentStats,
                        ownedStats = projectedStats,
                        stats = projectedStats,
                        matcherStats = projectedStats,
                        matchPriority = priority,
                        upgradeTrack = upgrade.track,
                        upgradeRank = upgrade.rank,
                        upgradeMaxRank = upgrade.maxRank,
                        itemLevel = currentItemLevel,
                        projectedItemLevel = projectedItemLevel,
                        requiresUpgrade = requiresUpgrade,
                        projectionFactor = projectionFactor,
                        statText = OwnedStatText(currentStats),
                        displayStatText = OwnedStatText(currentStats),
                        dualWieldEligible = dualWield,
                        eligibleSlotInstances = eligibleSlots,
                    }
                    local existing = byID[record.itemID]
                    if existing and StatsSignature(existing.ownedStats) == StatsSignature(record.ownedStats)
                        and PrioritySignature(existing.matchPriority) == PrioritySignature(record.matchPriority) then
                        existing.ownedCount = (tonumber(existing.ownedCount) or 1) + 1
                    elseif not existing or ComparePriority(record.matchPriority, existing.matchPriority) > 0
                        or ComparePriority(record.matchPriority, existing.matchPriority) == 0 and StatsTotal(record.ownedStats) > StatsTotal(existing.ownedStats) then
                        record.ownedCount = 1
                        byID[record.itemID] = record
                    end
                end
            end
        end
    end
    for _, record in pairs(byID) do table.insert(candidates, record) end
    table.sort(candidates, function(a, b)
        if tostring(a.slot or "") ~= tostring(b.slot or "") then return tostring(a.slot or "") < tostring(b.slot or "") end
        if tostring(a.name or "") ~= tostring(b.name or "") then return tostring(a.name or "") < tostring(b.name or "") end
        return tonumber(a.itemID or 0) < tonumber(b.itemID or 0)
    end)
    return candidates, byID
end

local function CurrentSpecID()
    return KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.GetCurrentSpecID and KeyLab.LootTargetsDB.GetCurrentSpecID() or 0
end

local function ScanEquipment(specID)
    local capture = KeyLab.GearCapture
    local mapping = KeyLab.GearLootMapping
    local snapshot = {
        slots = {},
        allEquippedStats = ZeroStats(),
        lockedStats = ZeroStats(),
        projectedLockedStats = ZeroStats(),
        upgradeAssumptions = {},
        recognized = {},
    }

    for _, slotInstance in ipairs(SLOT_ORDER) do
        local slot = capture and capture.GetEquippedSlot and capture.GetEquippedSlot(slotInstance, true) or { slotName = slotInstance }
        snapshot.slots[slotInstance] = slot
        if slot and slot.itemID then
            local stats, priority, enhancements = GetLiveItemStats(slot.itemLink or slot.link, slot.tooltipLinesRaw)
            local upgrade = {
                track = slot.upgradeTrack or slot.trackName,
                rank = slot.upgradeRank,
                maxRank = slot.upgradeMaxRank or slot.upgradeMax,
            }
            local projectedBaseStats, _, projectedItemLevel, requiresUpgrade, projectionFactor =
                ProjectOwnedItem(stats, priority, slot.itemLevel, upgrade)
            local currentStats = AddStats(stats, enhancements)
            local projectedStats = AddStats(projectedBaseStats, enhancements)
            local isTrinket = slotInstance == "Trinket 1" or slotInstance == "Trinket 2"
            snapshot.allEquippedStats = AddStats(snapshot.allEquippedStats, currentStats)
            if not isTrinket then
                snapshot.lockedStats = AddStats(snapshot.lockedStats, currentStats)
                snapshot.projectedLockedStats = AddStats(snapshot.projectedLockedStats, projectedStats)
            end
            if requiresUpgrade and not isTrinket then
                table.insert(snapshot.upgradeAssumptions, {
                    slotInstance = slotInstance,
                    itemID = tonumber(slot.itemID),
                    name = slot.name or slot.displayName or ("Item " .. tostring(slot.itemID)),
                    upgradeTrack = upgrade.track,
                    upgradeRank = upgrade.rank,
                    upgradeMaxRank = upgrade.maxRank,
                    itemLevel = tonumber(slot.itemLevel),
                    projectedItemLevel = projectedItemLevel,
                    projectionFactor = projectionFactor,
                    equipped = true,
                })
            end
            local item = mapping and mapping.GetItem and mapping.GetItem(slot.itemID, specID) or nil
            if item and mapping.IsItemEligibleForSpec(item, specID) and mapping.IsCurrentSeasonItem(item) then
                table.insert(snapshot.recognized, {
                    itemID = tonumber(slot.itemID),
                    slotInstance = slotInstance,
                    sourceID = item.sourceID,
                })
            end
        end
    end
    return snapshot
end

local function SyncRecognizedTargets(specID, recognized)
    local targets = KeyLab.LootTargetsDB
    if not targets or not targets.SetTargetForSlot then return end
    for _, record in ipairs(recognized or {}) do
        targets.SetTargetForSlot(specID, record.itemID, record.slotInstance, record.sourceID, true)
    end
end

local function ItemCanFill(item, slotInstance)
    for _, eligible in ipairs(item.eligibleSlotInstances or {}) do
        if eligible == slotInstance then return true end
    end
    return false
end

local function PartitionCandidates(specID, itemType, suppliedCandidates)
    local mapping = KeyLab.GearLootMapping
    local candidates = suppliedCandidates or (mapping and mapping.GetMatcherCandidates and mapping.GetMatcherCandidates(specID, itemType) or {})
    local bySlot = {}
    local mainWeapons, offHandItems, dualWeapons = {}, {}, {}
    for _, item in ipairs(candidates) do
        for _, slotInstance in ipairs(item.eligibleSlotInstances or {}) do
            bySlot[slotInstance] = bySlot[slotInstance] or {}
            table.insert(bySlot[slotInstance], item)
        end
        if item.slot == "One-Hand" or item.slot == "Two-Hand" or item.slot == "Ranged" then
            table.insert(mainWeapons, item)
            if item.dualWieldEligible then table.insert(dualWeapons, item) end
        elseif item.slot == "Off Hand" then
            table.insert(offHandItems, item)
        end
    end
    return bySlot, mainWeapons, offHandItems, dualWeapons
end

local function CompactWeaponItems(items, specID, category)
    local groups = {}
    for _, item in ipairs(items or {}) do
        local stats = ItemStats(item, specID)
        if StatsTotal(stats) > 0 then
            local priority = CopyPriority(item.matchPriority)
            local signature = tostring(category or item.slot) .. ":" .. tostring(item.slot) .. ":" .. tostring(item.dualWieldEligible == true) .. ":" .. StatsSignature(stats)
                .. (item.matchPriority and (":" .. PrioritySignature(priority)) or "")
            local group = groups[signature]
            if not group then
                group = { item = item, stats = stats, priority = priority, itemIDs = {}, seen = {}, ownedCounts = {} }
                groups[signature] = group
            end
            AddUniqueID(group.itemIDs, group.seen, item.itemID)
            if tonumber(item.ownedCount) then group.ownedCounts[tonumber(item.itemID)] = tonumber(item.ownedCount) end
            if tonumber(item.itemID) < tonumber(group.item.itemID) then group.item = item end
        end
    end
    local out = {}
    for signature, group in pairs(groups) do
        SortIDs(group.itemIDs)
        group.signature = signature
        table.insert(out, group)
    end
    table.sort(out, function(a, b) return tostring(a.signature) < tostring(b.signature) end)
    return out
end

local function WeaponAssignment(slotInstance, group)
    return {
        slotInstance = slotInstance,
        itemID = tonumber(group.item.itemID),
        sourceID = group.item.sourceID,
        equivalentItemIDs = group.itemIDs,
        ownedCounts = next(group.ownedCounts or {}) and group.ownedCounts or nil,
        matcherStats = CopyStats(group.stats),
        name = group.item.name,
        sourceName = group.item.sourceName,
        itemLink = group.item.itemLink or group.item.link,
        upgradeTrack = group.item.upgradeTrack,
        upgradeRank = group.item.upgradeRank,
        upgradeMaxRank = group.item.upgradeMaxRank,
        itemLevel = group.item.itemLevel,
        projectedItemLevel = group.item.projectedItemLevel,
        requiresUpgrade = group.item.requiresUpgrade == true,
    }
end

local function BuildWeaponOptions(specID, snapshot, mainWeapons, offHandItems, dualWeapons)
    local mainEquipped = snapshot.slots["Main Hand"] and snapshot.slots["Main Hand"].itemID
    local offEquipped = snapshot.slots["Off Hand"] and snapshot.slots["Off Hand"].itemID
    if mainEquipped and offEquipped then return nil end

    local mapping = KeyLab.GearLootMapping
    local compactMain = CompactWeaponItems(mainWeapons, specID, "main")
    local compactOff = CompactWeaponItems(offHandItems, specID, "off")
    local compactDual = CompactWeaponItems(dualWeapons, specID, "dual")
    local options = {}

    if mainEquipped and not offEquipped then
        local mainSlot = snapshot.slots["Main Hand"]
        local knownDual = mapping and mapping.IsDualWieldEligible and mapping.IsDualWieldEligible(mainEquipped, specID)
        local closesOffHand = mainSlot and KeyLab.GearCapture and KeyLab.GearCapture.IsTwoHandOrRangedWeapon
            and KeyLab.GearCapture.IsTwoHandOrRangedWeapon(mainSlot) and not knownDual
        if closesOffHand then return nil end
        for _, group in ipairs(compactOff) do
            table.insert(options, {
                stats = group.stats,
                priority = group.priority,
                key = "offitem:" .. group.signature,
                assignments = { WeaponAssignment("Off Hand", group) },
            })
        end
        if knownDual then
            for _, group in ipairs(compactDual) do
                table.insert(options, {
                    stats = group.stats,
                    priority = group.priority,
                    key = "offweapon:" .. group.signature,
                    assignments = { WeaponAssignment("Off Hand", group) },
                })
            end
        end
        -- Dual-wield support is optional. Keeping the equipped Main Hand by
        -- itself remains a valid complete weapon configuration.
        table.insert(options, { stats = ZeroStats(), priority = ZeroPriority(), key = "keep-main-only", assignments = {} })
    elseif not mainEquipped and offEquipped then
        local offKnownDual = mapping and mapping.IsDualWieldEligible and mapping.IsDualWieldEligible(offEquipped, specID)
        for _, group in ipairs(compactMain) do
            if group.item.slot == "One-Hand" or (offKnownDual and group.item.dualWieldEligible) then
                table.insert(options, {
                    stats = group.stats,
                    priority = group.priority,
                    key = "mainkeeper:" .. group.signature,
                    assignments = { WeaponAssignment("Main Hand", group) },
                })
            end
        end
    else
        for _, group in ipairs(compactMain) do
            table.insert(options, {
                stats = group.stats,
                priority = group.priority,
                key = "mainonly:" .. group.signature,
                assignments = { WeaponAssignment("Main Hand", group) },
            })
        end
        local oneHandMain = {}
        for _, group in ipairs(compactMain) do if group.item.slot == "One-Hand" then table.insert(oneHandMain, group) end end
        for _, mainGroup in ipairs(oneHandMain) do
            for _, offGroup in ipairs(compactOff) do
                table.insert(options, {
                    stats = AddStats(mainGroup.stats, offGroup.stats),
                    priority = AddPriority(mainGroup.priority, offGroup.priority),
                    key = "mainoff:" .. mainGroup.signature .. ":" .. offGroup.signature,
                    assignments = {
                        WeaponAssignment("Main Hand", mainGroup),
                        WeaponAssignment("Off Hand", offGroup),
                    },
                })
            end
        end
        for mainIndex, mainGroup in ipairs(compactDual) do
            for offIndex = mainIndex, #compactDual do
                local offGroup = compactDual[offIndex]
                table.insert(options, {
                    stats = AddStats(mainGroup.stats, offGroup.stats),
                    priority = AddPriority(mainGroup.priority, offGroup.priority),
                    key = "dual:" .. mainGroup.signature .. ":" .. offGroup.signature,
                    assignments = {
                        WeaponAssignment("Main Hand", mainGroup),
                        WeaponAssignment("Off Hand", offGroup),
                    },
                })
            end
        end
    end

    table.sort(options, function(a, b) return tostring(a.key) < tostring(b.key) end)
    if #options == 0 then return nil end
    return { name = "Weapon Configuration", options = options, visibleOrder = 15 }
end

local function CountDistinctItems(firstList, secondList)
    local seen, count = {}, 0
    for _, list in ipairs({ firstList or {}, secondList or {} }) do
        for _, item in ipairs(list) do
            local itemID = tonumber(item and item.itemID)
            if itemID and not seen[itemID] then
                seen[itemID] = true
                count = count + 1
            end
        end
    end
    return count
end

local function BuildPositions(specID, itemType, snapshot, suppliedCandidates)
    local bySlot, mainWeapons, offHandItems, dualWeapons = PartitionCandidates(specID, itemType, suppliedCandidates)
    local positions, unmatchedSlots, skipSlot = {}, {}, {}

    -- Two open ring slots normally share the same candidate list.
    -- If the selected pool contains only one distinct item, filling the second
    -- slot would reject every otherwise-valid combination as a duplicate.
    for _, pair in ipairs({ { "Finger 1", "Finger 2" } }) do
        local first, second = pair[1], pair[2]
        local firstOpen = not (snapshot.slots[first] and snapshot.slots[first].itemID)
        local secondOpen = not (snapshot.slots[second] and snapshot.slots[second].itemID)
        if firstOpen and secondOpen and CountDistinctItems(bySlot[first], bySlot[second]) == 1 then
            skipSlot[second] = true
        end
    end

    for order, slotInstance in ipairs(SLOT_ORDER) do
        if slotInstance ~= "Main Hand" and slotInstance ~= "Off Hand"
            and slotInstance ~= "Trinket 1" and slotInstance ~= "Trinket 2" then
            local equipped = snapshot.slots[slotInstance] and snapshot.slots[slotInstance].itemID
            if not equipped then
                if skipSlot[slotInstance] then
                    table.insert(unmatchedSlots, slotInstance)
                else
                    local options = GroupSingleSlotItems(slotInstance, bySlot[slotInstance], specID)
                    if #options > 0 then
                        table.insert(positions, { name = slotInstance, options = options, visibleOrder = order })
                    else
                        table.insert(unmatchedSlots, slotInstance)
                    end
                end
            end
        end
    end
    local weaponPosition = BuildWeaponOptions(specID, snapshot, mainWeapons, offHandItems, dualWeapons)
    if weaponPosition then table.insert(positions, weaponPosition) end
    local mainOpen = not (snapshot.slots["Main Hand"] and snapshot.slots["Main Hand"].itemID)
    if mainOpen and not weaponPosition then table.insert(unmatchedSlots, "Main Hand") end
    table.sort(positions, function(a, b)
        if #a.options ~= #b.options then return #a.options < #b.options end
        return tonumber(a.visibleOrder or 99) < tonumber(b.visibleOrder or 99)
    end)
    return positions, unmatchedSlots
end

local function PositionBounds(position)
    local minimum, maximum, available = {}, ZeroStats(), {}
    for _, key in ipairs(SECONDARY) do minimum[key] = nil end
    for _, option in ipairs(position and position.options or {}) do
        for _, key in ipairs(SECONDARY) do
            local value = tonumber(option.stats and option.stats[key]) or 0
            minimum[key] = minimum[key] == nil and value or math.min(minimum[key], value)
            maximum[key] = math.max(tonumber(maximum[key]) or 0, value)
            if value > 0 then available[key] = true end
        end
    end
    for _, key in ipairs(SECONDARY) do minimum[key] = tonumber(minimum[key]) or 0 end
    return minimum, maximum, available
end

local function AnalyzeAndSortPositions(positions, initialStats, goals, projection)
    local foundation = ProjectPercentages(initialStats, projection)
    for _, position in ipairs(positions or {}) do
        position.minimumStats, position.maximumStats, position.availableStats = PositionBounds(position)
        local opportunity = 0
        local maximumSet = AddStats(initialStats, position.maximumStats)
        local maximumPercentages = ProjectPercentages(maximumSet, projection)
        for _, key in ipairs(SECONDARY) do
            local deficit = math.max(0, (tonumber(goals[key]) or 0) - (tonumber(foundation[key]) or 0))
            local gain = math.max(0, (tonumber(maximumPercentages[key]) or 0) - (tonumber(foundation[key]) or 0))
            local weight = projection and projection.matchStyle == "priority"
                and (tonumber(projection.priorityWeights and projection.priorityWeights[key]) or 1) or 1
            opportunity = opportunity + (math.min(deficit, gain) * weight)
        end
        position.opportunity = opportunity
    end
    table.sort(positions, function(a, b)
        if #a.options ~= #b.options then return #a.options < #b.options end
        if math.abs((tonumber(a.opportunity) or 0) - (tonumber(b.opportunity) or 0)) > 0.000001 then
            return (tonumber(a.opportunity) or 0) > (tonumber(b.opportunity) or 0)
        end
        return tonumber(a.visibleOrder or 99) < tonumber(b.visibleOrder or 99)
    end)
end

local function BuildRemainingBounds(positions)
    local remaining = {}
    remaining[#positions + 1] = { minimum = ZeroStats(), maximum = ZeroStats() }
    for index = #positions, 1, -1 do
        local nextBounds = remaining[index + 1]
        local minimum = positions[index].minimumStats or PositionBounds(positions[index])
        local maximum = positions[index].maximumStats or select(2, PositionBounds(positions[index]))
        remaining[index] = {
            minimum = AddStats(minimum, nextBounds.minimum),
            maximum = AddStats(maximum, nextBounds.maximum),
        }
    end
    return remaining
end

local function ReachablePenalty(state, bounds, goals, projection)
    if not bounds then return EvaluateState(state, goals, projection) end
    if state._reachablePenaltyBounds == bounds
        and state._reachablePenaltyGoals == goals
        and state._reachablePenaltyProjection == projection then
        return state._reachablePenalty
    end
    local low = ProjectPercentages(AddStats(state.stats, bounds.minimum), projection)
    local high = ProjectPercentages(AddStats(state.stats, bounds.maximum), projection)
    local penalty = 0
    for _, key in ipairs(SECONDARY) do
        local goal = tonumber(goals[key]) or 0
        local lowValue = math.min(tonumber(low[key]) or 0, tonumber(high[key]) or 0)
        local highValue = math.max(tonumber(low[key]) or 0, tonumber(high[key]) or 0)
        local deviation = goal < lowValue and (lowValue - goal) or goal > highValue and (goal - highValue) or 0
        if projection and projection.matchStyle == "priority" then
            local weight = tonumber(projection.priorityWeights and projection.priorityWeights[key]) or 1
            deviation = goal > highValue and (deviation * weight) or (deviation * 0.35)
        end
        penalty = penalty + deviation
    end
    state._reachablePenaltyBounds = bounds
    state._reachablePenaltyGoals = goals
    state._reachablePenaltyProjection = projection
    state._reachablePenalty = penalty
    return penalty
end

local function ReachableDeviations(state, bounds, goals, projection)
    if not bounds then
        local _, _, percentages = EvaluateState(state, goals, projection)
        local deviations = {}
        for _, key in ipairs(PriorityOrder(projection)) do
            deviations[key] = GoalDeviation(percentages, goals, key)
        end
        return deviations
    end
    if state._reachableDeviationBounds == bounds
        and state._reachableDeviationGoals == goals
        and state._reachableDeviationProjection == projection then
        return state._reachableDeviations
    end
    local low = ProjectPercentages(AddStats(state.stats, bounds.minimum), projection)
    local high = ProjectPercentages(AddStats(state.stats, bounds.maximum), projection)
    local deviations = {}
    for _, key in ipairs(PriorityOrder(projection)) do
        local goal = tonumber(goals[key]) or 0
        local lowValue = math.min(tonumber(low[key]) or 0, tonumber(high[key]) or 0)
        local highValue = math.max(tonumber(low[key]) or 0, tonumber(high[key]) or 0)
        deviations[key] = goal < lowValue and (lowValue - goal) or goal > highValue and (goal - highValue) or 0
    end
    state._reachableDeviationBounds = bounds
    state._reachableDeviationGoals = goals
    state._reachableDeviationProjection = projection
    state._reachableDeviations = deviations
    return deviations
end

local function CompareReachablePriority(left, right, bounds, goals, projection)
    local leftDeviations = ReachableDeviations(left, bounds, goals, projection)
    local rightDeviations = ReachableDeviations(right, bounds, goals, projection)
    for _, key in ipairs(PriorityOrder(projection)) do
        local leftValue = tonumber(leftDeviations[key]) or 0
        local rightValue = tonumber(rightDeviations[key]) or 0
        if math.abs(leftValue - rightValue) > 0.000001 then return leftValue < rightValue and 1 or -1 end
    end
    return 0
end

local function EstimateCombinations(positions)
    local total = 1
    for _, position in ipairs(positions or {}) do
        total = total * math.max(1, #position.options)
        if total > 1000000000 then return 1000000000 end
    end
    return total
end

local function AssignmentKind(slotInstance)
    if slotInstance == "Finger 1" or slotInstance == "Finger 2" then return "Finger" end
    if slotInstance == "Trinket 1" or slotInstance == "Trinket 2" then return "Trinket" end
    return nil
end

local function ResolveOption(state, option)
    local assignments = {}
    local usedJewelry = CopyTable(state.usedJewelry)
    local usedOwned = CopyTable(state.usedOwned)
    for _, sourceAssignment in ipairs(option.assignments or {}) do
        local assignment = CopyTable(sourceAssignment)
        assignment.equivalentItemIDs = CopyArray(sourceAssignment.equivalentItemIDs)
        local kind = AssignmentKind(assignment.slotInstance)
        local chosen
        if type(assignment.ownedCounts) == "table" then
            for _, itemID in ipairs(assignment.equivalentItemIDs or {}) do
                itemID = tonumber(itemID)
                local available = tonumber(assignment.ownedCounts[itemID]) or 0
                local jewelryUsed = kind and usedJewelry[kind] and usedJewelry[kind][itemID]
                if itemID and (tonumber(usedOwned[itemID]) or 0) < available and not jewelryUsed then
                    chosen = itemID
                    break
                end
            end
            if not chosen then return nil end
            assignment.itemID = chosen
            usedOwned[chosen] = (tonumber(usedOwned[chosen]) or 0) + 1
        elseif kind then
            usedJewelry[kind] = CopyTable(usedJewelry[kind])
            for _, itemID in ipairs(assignment.equivalentItemIDs or {}) do
                if not usedJewelry[kind][tonumber(itemID)] then chosen = tonumber(itemID); break end
            end
            if not chosen then return nil end
            assignment.itemID = chosen
        end
        if kind then
            usedJewelry[kind] = CopyTable(usedJewelry[kind])
            usedJewelry[kind][chosen] = true
        end
        table.insert(assignments, assignment)
    end
    return assignments, usedJewelry, usedOwned
end

local function CombineState(state, option)
    local assignments, usedJewelry, usedOwned = ResolveOption(state, option)
    if not assignments then return nil end
    local combinedAssignments = CopyArray(state.assignments)
    for _, assignment in ipairs(assignments) do table.insert(combinedAssignments, assignment) end
    return {
        stats = AddStats(state.stats, option.stats),
        priority = AddPriority(state.priority, option.priority),
        assignments = combinedAssignments,
        usedJewelry = usedJewelry,
        usedOwned = usedOwned,
        key = tostring(state.key or "") .. "|" .. tostring(option.key or ""),
    }
end

local function YieldWork(job, completed, total, mode)
    job.operations = (job.operations or 0) + 1
    if job.cancelled then error("cancelled") end
    if job.operations % WORK_PER_FRAME == 0 then
        coroutine.yield({ completed = completed or job.operations, total = total, mode = mode })
    end
end

local function RunExact(job, positions, initialState, goals, projection, estimate)
    local best
    local completed = 0
    local function Walk(index, state)
        if index > #positions then
            completed = completed + 1
            if IsBetter(state, best, goals, projection) then best = state end
            YieldWork(job, completed, estimate, "Exact")
            return
        end
        for _, option in ipairs(positions[index].options) do
            local nextState = CombineState(state, option)
            if nextState then Walk(index + 1, nextState) end
        end
    end
    Walk(1, initialState)
    return best
end

local function RunBeam(job, positions, initialState, goals, projection)
    local states = { initialState }
    local remainingBounds = BuildRemainingBounds(positions)
    for positionIndex, position in ipairs(positions) do
        local nextStates = {}
        local function Trim(limit)
            local future = remainingBounds[positionIndex + 1]
            table.sort(nextStates, function(a, b)
                if projection and projection.matchStyle == "priority" then
                    local comparison = CompareReachablePriority(a, b, future, goals, projection)
                    if comparison ~= 0 then return comparison > 0 end
                    return IsBetter(a, b, goals, projection)
                end
                local aPenalty = ReachablePenalty(a, future, goals, projection)
                local bPenalty = ReachablePenalty(b, future, goals, projection)
                if math.abs(aPenalty - bPenalty) > 0.000001 then return aPenalty < bPenalty end
                return IsBetter(a, b, goals, projection)
            end)
            for index = #nextStates, limit + 1, -1 do nextStates[index] = nil end
        end
        for _, state in ipairs(states) do
            for _, option in ipairs(position.options) do
                local nextState = CombineState(state, option)
                if nextState then table.insert(nextStates, nextState) end
                if #nextStates >= BEAM_WIDTH * 4 then Trim(BEAM_WIDTH * 2) end
                YieldWork(job, positionIndex, #positions, "Bounded")
            end
        end
        Trim(BEAM_WIDTH)
        states = nextStates
        coroutine.yield({ completed = positionIndex, total = #positions, mode = "Bounded" })
    end
    local best
    for _, state in ipairs(states) do if IsBetter(state, best, goals, projection) then best = state end end
    return best
end

local STAT_LABELS = { Crit = "Critical Strike", Haste = "Haste", Mastery = "Mastery", Vers = "Versatility" }

local function ReducedEfficiencyAt(context, key, itemStats)
    if not context then return false end
    local totalRating = (tonumber(context.baselineRatings and context.baselineRatings[key]) or 0)
        + (tonumber(itemStats and itemStats[key]) or 0)
    if totalRating <= 0 then return false end
    local sample = math.max(25, math.min(100, totalRating * 0.10))
    local baseGain = RatingBonusForValue(context, key, sample) - RatingBonusForValue(context, key, 0)
    local lower = math.max(0, totalRating - sample)
    local localGain = RatingBonusForValue(context, key, totalRating) - RatingBonusForValue(context, key, lower)
    local localRange = totalRating - lower
    if baseGain <= 0 or localRange <= 0 then return false end
    local baseRate = baseGain / sample
    local localRate = localGain / localRange
    return localRate < (baseRate * 0.995)
end

local function BuildStatSupportItems(specID, candidates, best, goals, projection, openTrinketSlotCount, itemSource, ownedRecords)
    local supports, records, byID = {}, {}, {}
    if not best or (tonumber(openTrinketSlotCount) or 0) < 1 then return supports, records, byID end

    local corePercentages = ProjectPercentages(best.stats, projection)
    local deficitStats = {}
    for _, key in ipairs(SECONDARY) do
        if (tonumber(corePercentages[key]) or 0) < (tonumber(goals[key]) or 0) - GOAL_MATCH_TOLERANCE then
            deficitStats[key] = true
        end
    end
    if not next(deficitStats) then return supports, records, byID end

    for _, item in ipairs(candidates or {}) do
        local itemID = tonumber(item and item.itemID)
        if itemID and not byID[itemID] and (item.slot == "Trinket" or item.equipLoc == "INVTYPE_TRINKET") then
            local stats = ItemStats(item, specID)
            local withTrinket = AddStats(best.stats, stats)
            local withPercentages = ProjectPercentages(withTrinket, projection)
            local helpful, entersReducedEfficiency = {}, false
            for _, key in ipairs(SECONDARY) do
                if deficitStats[key] and (tonumber(stats[key]) or 0) > 0 then
                    local gain = (tonumber(withPercentages[key]) or 0) - (tonumber(corePercentages[key]) or 0)
                    if gain > 0.0001 then
                        if ReducedEfficiencyAt(projection, key, withTrinket) then
                            entersReducedEfficiency = true
                        else
                            table.insert(helpful, key)
                        end
                    end
                end
            end
            if #helpful > 0 and not entersReducedEfficiency then
                local sourceRecord = itemSource == "owned" and ownedRecords and ownedRecords[itemID] or item
                local support = {
                    itemID = itemID,
                    name = sourceRecord and sourceRecord.name or item.name or ("Item " .. tostring(itemID)),
                    sourceName = sourceRecord and sourceRecord.sourceName or item.sourceName or "",
                    itemLink = sourceRecord and (sourceRecord.itemLink or sourceRecord.link) or item.itemLink or item.link,
                    matcherStats = CopyStats(stats),
                    supportStats = CopyArray(helpful),
                    upgradeTrack = sourceRecord and sourceRecord.upgradeTrack or item.upgradeTrack,
                    upgradeRank = sourceRecord and sourceRecord.upgradeRank or item.upgradeRank,
                    upgradeMaxRank = sourceRecord and sourceRecord.upgradeMaxRank or item.upgradeMaxRank,
                    itemLevel = tonumber(sourceRecord and sourceRecord.itemLevel or item.itemLevel),
                    projectedItemLevel = tonumber(sourceRecord and sourceRecord.projectedItemLevel or item.projectedItemLevel),
                    requiresUpgrade = sourceRecord and sourceRecord.requiresUpgrade == true or item.requiresUpgrade == true,
                }
                table.insert(supports, support)
                byID[itemID] = true
                if itemSource == "owned" and sourceRecord then table.insert(records, CopyTable(sourceRecord)) end
            end
        end
    end
    table.sort(supports, function(a, b)
        if tostring(a.name or "") ~= tostring(b.name or "") then return tostring(a.name or "") < tostring(b.name or "") end
        return tonumber(a.itemID or 0) < tonumber(b.itemID or 0)
    end)
    table.sort(records, function(a, b)
        if tostring(a.name or "") ~= tostring(b.name or "") then return tostring(a.name or "") < tostring(b.name or "") end
        return tonumber(a.itemID or 0) < tonumber(b.itemID or 0)
    end)
    return supports, records, byID
end

local function BuildReachability(positions, initialStats, actualStats, finalStats, goals, projection)
    local minimumStats, maximumStats = CopyStats(initialStats), CopyStats(initialStats)
    local availabilityByStat = {}
    for _, key in ipairs(SECONDARY) do availabilityByStat[key] = { available = {}, unavailable = {} } end
    for _, position in ipairs(positions or {}) do
        local minimum = position.minimumStats or PositionBounds(position)
        local maximum = position.maximumStats or select(2, PositionBounds(position))
        minimumStats = AddStats(minimumStats, minimum)
        maximumStats = AddStats(maximumStats, maximum)
        for _, key in ipairs(SECONDARY) do
            local destination = position.availableStats and position.availableStats[key] and "available" or "unavailable"
            table.insert(availabilityByStat[key][destination], position.name)
        end
    end

    local currentPercentages = ProjectPercentages(actualStats, projection)
    local foundationPercentages = ProjectPercentages(initialStats, projection)
    local minimumPercentages = ProjectPercentages(minimumStats, projection)
    local maximumPercentages = ProjectPercentages(maximumStats, projection)
    local finalPercentages = ProjectPercentages(finalStats, projection)
    local stats, messages, exact = {}, {}, true
    for _, key in ipairs(SECONDARY) do
        local goal = tonumber(goals[key]) or 0
        local minimum = tonumber(minimumPercentages[key]) or 0
        local maximum = tonumber(maximumPercentages[key]) or 0
        local final = tonumber(finalPercentages[key]) or 0
        local current = tonumber(currentPercentages[key])
        local belowReach = goal > maximum + GOAL_MATCH_TOLERANCE
        local aboveFloor = goal < minimum - GOAL_MATCH_TOLERANCE
        local atGoal = math.abs(final - goal) <= GOAL_MATCH_TOLERANCE
        if not atGoal then exact = false end
        stats[key] = {
            goal = goal,
            current = tonumber(currentPercentages[key]),
            foundation = tonumber(foundationPercentages[key]) or 0,
            minimum = minimum,
            maximum = maximum,
            final = final,
            difference = final - goal,
            belowReach = belowReach,
            aboveFloor = aboveFloor,
            availableSlots = CopyArray(availabilityByStat[key].available),
            unavailableSlots = CopyArray(availabilityByStat[key].unavailable),
        }
        if current and current > goal + GOAL_MATCH_TOLERANCE then
            table.insert(messages, string.format("Your current %s is %.1f%%, which is already above your %.1f%% goal.", STAT_LABELS[key], current, goal))
        elseif final > goal + GOAL_MATCH_TOLERANCE then
            table.insert(messages, string.format("The matched set reaches %.1f%% %s, which is above your %.1f%% goal.", final, STAT_LABELS[key], goal))
        end
        if belowReach then
            table.insert(messages, string.format("The available items can reach up to %.1f%% %s, below your %.1f%% goal.", maximum, STAT_LABELS[key], goal))
            if #availabilityByStat[key].available == 0 then
                table.insert(messages, string.format("None of the available items for your unequipped slots provide %s.", STAT_LABELS[key]))
            end
        elseif aboveFloor then
            table.insert(messages, string.format("Your locked gear keeps %s at or above %.1f%%, which is already above your %.1f%% goal.", STAT_LABELS[key], minimum, goal))
        end
    end

    local diminishingReturns = {}
    for _, key in ipairs(SECONDARY) do
        local current = ReducedEfficiencyAt(projection, key, actualStats)
        local projected = ReducedEfficiencyAt(projection, key, finalStats)
        diminishingReturns[key] = { current = current, projected = projected, enters = not current and projected }
        if projected then
            table.insert(messages, (not current and "Projected " or "Current and projected ") .. STAT_LABELS[key]
                .. " is in a reduced-efficiency range. It still helps, but each new rating point adds less percentage.")
        end
    end

    if not exact then
        table.insert(messages, "This is the closest match KeyLab found. Opening more slots or changing crafted stats, gems, or enchants may bring the set closer to your goals.")
    end
    return {
        exact = exact,
        status = exact and "Exact Match" or "Closest Available Match",
        stats = stats,
        currentPercentages = currentPercentages,
        foundationPercentages = foundationPercentages,
        minimumPercentages = minimumPercentages,
        maximumPercentages = maximumPercentages,
        diminishingReturns = diminishingReturns,
        messages = messages,
    }
end

local function BuildSelectedItems(assignments, itemSource, ownedRecords, specID)
    local selected = {}
    local mapping = KeyLab.GearLootMapping
    for _, assignment in ipairs(assignments or {}) do
        local itemID = tonumber(assignment.itemID)
        local record = itemSource == "owned" and ownedRecords and ownedRecords[itemID]
            or mapping and mapping.GetItem and mapping.GetItem(itemID, specID, nil, assignment.sourceID)
        local requiresUpgrade = assignment.requiresUpgrade == true
        if record then requiresUpgrade = record.requiresUpgrade == true end
        table.insert(selected, {
            slotInstance = assignment.slotInstance,
            itemID = itemID,
            -- A search option can represent several items with an identical
            -- stat pattern. Resolve display details from the item ID that was
            -- actually assigned, not from the option's representative item.
            name = record and record.name or assignment.name or ("Item " .. tostring(itemID or "?")),
            sourceName = record and record.sourceName or assignment.sourceName or "",
            itemLink = record and (record.itemLink or record.link) or assignment.itemLink,
            matcherStats = CopyStats(assignment.matcherStats or record and record.matcherStats),
            currentStats = CopyStats(record and (record.currentOwnedStats or record.ownedStats) or assignment.matcherStats),
            upgradeTrack = record and record.upgradeTrack or assignment.upgradeTrack,
            upgradeRank = record and record.upgradeRank or assignment.upgradeRank,
            upgradeMaxRank = record and record.upgradeMaxRank or assignment.upgradeMaxRank,
            itemLevel = tonumber(record and record.itemLevel or assignment.itemLevel),
            projectedItemLevel = tonumber(record and record.projectedItemLevel or assignment.projectedItemLevel),
            requiresUpgrade = requiresUpgrade,
        })
    end
    table.sort(selected, function(a, b)
        local aOrder, bOrder = 99, 99
        for index, slot in ipairs(SLOT_ORDER) do
            if slot == a.slotInstance then aOrder = index end
            if slot == b.slotInstance then bOrder = index end
        end
        return aOrder == bOrder and tostring(a.name) < tostring(b.name) or aOrder < bOrder
    end)
    return selected
end

local function RefreshSelectedItemDetails(result)
    if type(result) ~= "table" or type(result.selectedItems) ~= "table" then return result end
    local recordsByID = {}
    for _, record in ipairs(result.matchedItemRecords or {}) do
        local itemID = tonumber(record and record.itemID)
        if itemID then recordsByID[itemID] = record end
    end
    local mapping = KeyLab.GearLootMapping
    for _, item in ipairs(result.selectedItems) do
        local itemID = tonumber(item and item.itemID)
        local record = itemID and recordsByID[itemID]
            or itemID and mapping and mapping.GetItem and mapping.GetItem(itemID, result.specID)
        if record then
            item.name = record.name or item.name
            item.sourceName = record.sourceName or item.sourceName
            item.itemLink = record.itemLink or record.link or item.itemLink
            item.upgradeTrack = record.upgradeTrack or item.upgradeTrack
            item.upgradeRank = record.upgradeRank or item.upgradeRank
            item.upgradeMaxRank = record.upgradeMaxRank or item.upgradeMaxRank
            item.itemLevel = tonumber(record.itemLevel) or item.itemLevel
            item.projectedItemLevel = tonumber(record.projectedItemLevel) or item.projectedItemLevel
            if record.requiresUpgrade ~= nil then item.requiresUpgrade = record.requiresUpgrade == true end
        end
    end
    return result
end

local function BuildResult(specID, itemType, itemSource, ownedRecords, best, goals, projection, estimate, mode, positions, unmatchedSlots, snapshot,
    statSupportItems, statSupportItemRecords, statSupportItemsByID, openTrinketSlotCount)
    if not best then return nil end
    local matchedItems, matchedItemRecords = {}, {}
    for _, assignment in ipairs(best.assignments or {}) do
        for _, itemID in ipairs(assignment.equivalentItemIDs or { assignment.itemID }) do
            itemID = tonumber(itemID)
            if itemID then
                matchedItems[itemID] = true
                if itemSource == "owned" and ownedRecords and ownedRecords[itemID] then
                    table.insert(matchedItemRecords, CopyTable(ownedRecords[itemID]))
                end
            end
        end
    end
    local difference, largest, finalPercentages = Score(best.stats, goals, projection)
    local selectedItems = BuildSelectedItems(best.assignments, itemSource, ownedRecords, specID)
    local upgradeAssumptions = CopyArray(snapshot and snapshot.upgradeAssumptions)
    for _, item in ipairs(selectedItems) do
        if item.requiresUpgrade then
            table.insert(upgradeAssumptions, {
                slotInstance = item.slotInstance,
                itemID = item.itemID,
                name = item.name,
                upgradeTrack = item.upgradeTrack,
                upgradeRank = item.upgradeRank,
                upgradeMaxRank = item.upgradeMaxRank,
                itemLevel = item.itemLevel,
                projectedItemLevel = item.projectedItemLevel,
                equipped = false,
            })
        end
    end
    local reachability = BuildReachability(
        positions,
        snapshot and snapshot.projectedLockedStats or ZeroStats(),
        snapshot and snapshot.lockedStats or ZeroStats(),
        best.stats,
        goals,
        projection
    )
    if #upgradeAssumptions > 0 then
        table.insert(reachability.messages, string.format(
            "This result assumes %d owned item%s will be upgraded to the highest rank of its known track.",
            #upgradeAssumptions,
            #upgradeAssumptions == 1 and "" or "s"
        ))
    end
    if #unmatchedSlots > 0 then
        table.insert(reachability.messages, "No different eligible item was available for: " .. table.concat(unmatchedSlots, ", ") .. ".")
    end
    table.insert(reachability.messages,
        "Trinket secondary stats are excluded from the goal projection. Stat Support suggestions are advisory and do not count toward reaching your goals.")
    return {
        specID = specID,
        itemType = itemType,
        itemSource = itemSource or "master",
        completedAt = time and time() or 0,
        seasonKey = CurrentSeasonKey(),
        mnSeason = 2,
        matchedItems = matchedItems,
        matchedItemRecords = matchedItemRecords,
        statSupportItems = statSupportItems or {},
        statSupportItemRecords = statSupportItemRecords or {},
        statSupportItemsByID = statSupportItemsByID or {},
        openTrinketSlotCount = tonumber(openTrinketSlotCount) or 0,
        trinketsExcludedFromProjection = true,
        assignments = best.assignments,
        selectedItems = selectedItems,
        upgradeAssumptions = upgradeAssumptions,
        goals = CopyStats(goals),
        finalStats = best.stats,
        finalPercentages = finalPercentages,
        currentPercentages = reachability.currentPercentages,
        reachability = reachability,
        resultStatus = reachability.status,
        resultMessages = reachability.messages,
        diminishingReturns = reachability.diminishingReturns,
        finalPriority = CopyPriority(best.priority),
        difference = difference,
        largestDeviation = largest,
        estimatedCombinations = estimate,
        mode = mode,
        openPositionCount = #positions,
        matchedSlotCount = #(best.assignments or {}),
        unmatchedOpenSlots = CopyArray(unmatchedSlots),
        scoringModel = "character_percent_slot_aware_v6",
        matchStyle = projection and projection.matchStyle or "balanced",
    }
end

local function RunJob(job)
    local specID = job.specID
    local valid, message = KeyLab.StatGoalsDB and KeyLab.StatGoalsDB.Validate and KeyLab.StatGoalsDB.Validate(specID)
    if not valid then return { ok = false, message = message or "Each stat goal must be from 0% to 100%." } end

    local snapshot = ScanEquipment(specID)
    local suppliedCandidates, ownedRecords
    if job.itemSource == "owned" then
        suppliedCandidates, ownedRecords = GetOwnedBagCandidates(specID)
    else
        local mapping = KeyLab.GearLootMapping
        suppliedCandidates = mapping and mapping.GetMatcherCandidates and mapping.GetMatcherCandidates(specID, job.itemType) or {}
        suppliedCandidates = NormalizeMasterCandidates(suppliedCandidates, specID)
    end
    local goals = GetGoals(specID)
    local matchStyle = job.matchStyle == "priority" and "priority" or "balanced"
    local projection = BuildProjectionContext(snapshot.allEquippedStats, specID, matchStyle)
    local positions, unmatchedSlots = BuildPositions(specID, job.itemType, snapshot, suppliedCandidates)
    AnalyzeAndSortPositions(positions, snapshot.projectedLockedStats, goals, projection)
    local openTrinketSlotCount = 0
    for _, slotInstance in ipairs({ "Trinket 1", "Trinket 2" }) do
        if not (snapshot.slots[slotInstance] and snapshot.slots[slotInstance].itemID) then
            openTrinketSlotCount = openTrinketSlotCount + 1
        end
    end
    if #positions == 0 then
        if #unmatchedSlots > 0 then
            return {
                ok = false,
                message = job.itemSource == "owned"
                    and ("No usable bag item was found for: " .. table.concat(unmatchedSlots, ", ") .. ". Put gear for those slots in your bags, or choose Master Item Database.")
                    or ("No matching database item was found for: " .. table.concat(unmatchedSlots, ", ") .. ". Try Dungeon and Raid Items or open a different slot."),
            }
        end
        if openTrinketSlotCount == 0 then
            return { ok = false, message = "Unequip at least one eligible item so KeyLab has a slot to fill." }
        end
    end

    SyncRecognizedTargets(specID, snapshot.recognized)
    local estimate = #positions > 0 and EstimateCombinations(positions) or 0
    local initialState = { stats = snapshot.projectedLockedStats, priority = ZeroPriority(), assignments = {}, usedJewelry = {}, usedOwned = {}, key = "" }
    local mode = #positions == 0 and "Advisory" or estimate <= EXACT_COMBINATION_LIMIT and "Exact" or "Bounded"
    local best
    if mode == "Advisory" then
        best = initialState
    elseif mode == "Exact" then
        best = RunExact(job, positions, initialState, goals, projection, estimate)
    else
        best = RunBeam(job, positions, initialState, goals, projection)
    end
    if job.cancelled then return { ok = false, cancelled = true, message = "Matcher cancelled." } end
    local statSupportItems, statSupportItemRecords, statSupportItemsByID = BuildStatSupportItems(
        specID, suppliedCandidates, best, goals, projection, openTrinketSlotCount, job.itemSource, ownedRecords)
    local result = BuildResult(specID, job.itemType, job.itemSource, ownedRecords, best, goals, projection, estimate, mode, positions, unmatchedSlots, snapshot,
        statSupportItems, statSupportItemRecords, statSupportItemsByID, openTrinketSlotCount)
    if not result then return { ok = false, message = "KeyLab could not find a valid item combination for the unequipped slots." } end
    return { ok = true, result = result }
end

function Matcher.Start(options, onProgress, onComplete)
    options = options or {}
    if activeJob then return false, "The Stat Goal Matcher is already calculating." end
    local specID = tonumber(options.specID or CurrentSpecID()) or 0
    local job = {
        specID = specID,
        itemType = options.itemType,
        itemSource = options.itemSource == "owned" and "owned" or "master",
        matchStyle = options.matchStyle == "priority" and "priority" or "balanced",
        onProgress = onProgress,
        onComplete = onComplete,
        operations = 0,
        cancelled = false,
    }
    activeJob = job
    job.thread = coroutine.create(function() return RunJob(job) end)

    local function Finish(payload)
        activeJob = nil
        if payload and payload.ok and payload.result then GetSavedResults()[specID] = payload.result end
        if job.onComplete then job.onComplete(payload or { ok = false, message = "Matcher stopped unexpectedly." }) end
    end

    local function Step()
        if activeJob ~= job then return end
        local ok, payload = coroutine.resume(job.thread)
        if not ok then
            if tostring(payload) == "cancelled" or job.cancelled then
                Finish({ ok = false, cancelled = true, message = "Matcher cancelled." })
            else
                Finish({ ok = false, message = "The Stat Goal Matcher could not finish: " .. tostring(payload) })
            end
            return
        end
        if coroutine.status(job.thread) == "dead" then Finish(payload); return end
        if job.onProgress then job.onProgress(payload or {}) end
        if C_Timer and C_Timer.After then C_Timer.After(0, Step) else Step() end
    end

    Step()
    return true
end

function Matcher.Cancel()
    if not activeJob then return false end
    activeJob.cancelled = true
    return true
end

function Matcher.IsRunning()
    return activeJob ~= nil
end

function Matcher.GetResult(specID)
    specID = tonumber(specID or CurrentSpecID()) or 0
    local result = GetSavedResults()[specID]
    return result and result.scoringModel == "character_percent_slot_aware_v6"
        and RefreshSelectedItemDetails(result) or nil
end

function Matcher.GetCurrentShares()
    local capture = KeyLab.GearCapture
    local equipped = capture and capture.GetEquippedSlots and capture.GetEquippedSlots(SLOT_ORDER) or {}
    local stats = ZeroStats()
    for _, slotInstance in ipairs(SLOT_ORDER) do
        local slot = equipped[slotInstance]
        if slot and slot.itemID and slotInstance ~= "Trinket 1" and slotInstance ~= "Trinket 2" then
            local itemStats, _, enhancements = GetLiveItemStats(slot.itemLink or slot.link, slot.tooltipLinesRaw)
            stats = AddStats(stats, AddStats(itemStats, enhancements))
        end
    end
    local total = StatsTotal(stats)
    local shares = { crit = 0, haste = 0, mastery = 0, versatility = 0 }
    if total > 0 then
        shares.crit = (stats.Crit / total) * 100
        shares.haste = (stats.Haste / total) * 100
        shares.mastery = (stats.Mastery / total) * 100
        shares.versatility = (stats.Vers / total) * 100
    end
    return shares, stats, total
end

function Matcher.GetCurrentCharacterPercentages()
    local specID = CurrentSpecID()
    local snapshot = ScanEquipment(specID)
    local matchStyle = KeyLab.StatGoalsDB and KeyLab.StatGoalsDB.GetMatchStyle and KeyLab.StatGoalsDB.GetMatchStyle(specID) or "balanced"
    local projection = BuildProjectionContext(snapshot.allEquippedStats, specID, matchStyle)
    local sheet = ProjectPercentages(snapshot.lockedStats, projection)
    return {
        crit = tonumber(sheet.Crit),
        haste = tonumber(sheet.Haste),
        mastery = tonumber(sheet.Mastery),
        versatility = tonumber(sheet.Vers),
    }
end

function Matcher.IsGoalMatch(itemID, specID)
    local result = Matcher.GetResult(specID)
    return result and result.matchedItems and result.matchedItems[tonumber(itemID)] == true or false
end

function Matcher.IsStatSupport(itemID, specID)
    local result = Matcher.GetResult(specID)
    return result and result.statSupportItemsByID and result.statSupportItemsByID[tonumber(itemID)] == true or false
end

function Matcher.ClearResult(specID)
    GetSavedResults()[tonumber(specID or CurrentSpecID()) or 0] = nil
end

function Matcher.ClearAllResults()
    KeyLabDB = type(KeyLabDB) == "table" and KeyLabDB or {}
    KeyLabDB.statGoalMatcherResults = { MN_S1 = {}, MN_S2 = {} }
    KeyLabDB.statGoalMatcherSeasonVersion = 1
end

function Matcher.ClearSeasonResults(seasonKey)
    seasonKey = NormalizeSeasonKey(seasonKey, "MN_S1")
    local bucket = GetSavedResults(seasonKey)
    local count = 0
    for _ in pairs(bucket) do count = count + 1 end
    KeyLabDB.statGoalMatcherResults[seasonKey] = {}
    return count
end

function Matcher.GetConstants()
    return {
        exactCombinationLimit = EXACT_COMBINATION_LIMIT,
        beamWidth = BEAM_WIDTH,
        workPerFrame = WORK_PER_FRAME,
    }
end

-- Development-only regression entry point. It is intentionally not called
-- during login or normal matching, so it cannot change player data or add work
-- to the live UI. It remains available for release checks from an in-game dump.
function Matcher.RunDevelopmentRegressionTests()
    local failures, passed = {}, 0
    local function Check(name, condition)
        if condition then passed = passed + 1 else table.insert(failures, name) end
    end
    local function Near(left, right, tolerance)
        return math.abs((tonumber(left) or 0) - (tonumber(right) or 0)) <= (tolerance or 0.0001)
    end

    local scaled = ScaleStats({ Crit = 80, Haste = 20 }, 1.5)
    Check("normalization preserves stat identity", Near(scaled.Crit, 120) and Near(scaled.Haste, 30) and Near(scaled.Mastery, 0))
    Check("normalization preserves stat proportions", Near(scaled.Crit / scaled.Haste, 4))
    Check("plain Versatility item key is recognized", SecondaryKeyFromItemStat("ITEM_MOD_VERSATILITY") == "Vers")
    Check("rated Versatility item key is recognized", SecondaryKeyFromItemStat("ITEM_MOD_VERSATILITY_RATING_SHORT") == "Vers")
    Check("non-rating primary key is not a secondary", SecondaryKeyFromItemStat("ITEM_MOD_AGILITY_SHORT") == nil)

    local unknownStats, unknownPriority, unknownLevel, unknownUpgrade = ProjectOwnedItem(
        { Crit = 50, Haste = 50 }, ZeroPriority(), 250, { track = nil, rank = nil, maxRank = nil }
    )
    Check("unknown owned track stays current", Near(unknownStats.Crit, 50) and unknownLevel == 250 and unknownUpgrade == false)
    local heroStats, _, heroLevel, heroUpgrade = ProjectOwnedItem(
        { Crit = 50, Haste = 50 }, unknownPriority, 305, { track = "Hero", rank = 1, maxRank = 6 }
    )
    Check("known owned track projects to maximum", heroStats.Crit > 50 and heroLevel == 315 and heroUpgrade == true)

    local unavailablePosition = {
        name = "Head",
        options = {
            { stats = { Crit = 20, Haste = 0, Mastery = 10, Vers = 0 } },
            { stats = { Crit = 0, Haste = 20, Mastery = 10, Vers = 0 } },
        },
    }
    local _, maximum, available = PositionBounds(unavailablePosition)
    Check("slot availability detects present stats", available.Crit == true and available.Haste == true and maximum.Crit == 20)
    Check("slot availability detects absent stats", available.Vers ~= true and maximum.Vers == 0)

    local projection = {
        baselineRatings = ZeroStats(),
        basePercentages = ZeroStats(),
        masteryCoefficient = 1,
        matchStyle = "balanced",
        priorityWeights = { Crit = 1, Haste = 1, Mastery = 1, Vers = 1 },
        bonusCache = { Crit = {}, Haste = {}, Mastery = {}, Vers = {} },
    }
    for _, key in ipairs(SECONDARY) do
        for rating = 0, 300 do projection.bonusCache[key][tostring(rating)] = rating / 10 end
    end
    local goals = { Crit = 1, Haste = 0, Mastery = 0, Vers = 0 }
    local goalFit = { stats = { Crit = 10 }, priority = ZeroPriority(), key = "fit" }
    local wrongMyth = { stats = { Crit = 100 }, priority = { myth = 1 }, key = "myth" }
    Check("goal fit defeats a wrong-stat Myth item", IsBetter(goalFit, wrongMyth, goals, projection) == true)
    local closeMyth = { stats = { Crit = 11 }, priority = { myth = 1 }, key = "close-myth" }
    Check("track remains a close-result preference", IsBetter(closeMyth, goalFit, goals, projection) == true)

    local priorityProjection = {
        baselineRatings = ZeroStats(),
        basePercentages = ZeroStats(),
        masteryCoefficient = 1,
        matchStyle = "priority",
        priorityWeights = { Mastery = 1.75, Crit = 1.50, Haste = 1.25, Vers = 1 },
        priorityOrder = { "Mastery", "Crit", "Haste", "Vers" },
        bonusCache = projection.bonusCache,
    }
    local priorityGoals = { Mastery = 4, Crit = 4, Haste = 0, Vers = 0 }
    local closerFirstStat = { stats = { Mastery = 30 }, priority = ZeroPriority(), key = "first-stat" }
    local strongerLowerStat = { stats = { Mastery = 20, Crit = 40 }, priority = ZeroPriority(), key = "lower-stat" }
    Check("priority matching protects the first stat before lower stats",
        IsBetter(closerFirstStat, strongerLowerStat, priorityGoals, priorityProjection) == true)

    local positions = {
        { name = "Head", visibleOrder = 1, options = {
            { stats = { Crit = 10 }, priority = ZeroPriority(), assignments = {}, key = "h1" },
            { stats = { Haste = 10 }, priority = ZeroPriority(), assignments = {}, key = "h2" },
        } },
        { name = "Feet", visibleOrder = 2, options = {
            { stats = { Crit = 10 }, priority = ZeroPriority(), assignments = {}, key = "f1" },
            { stats = { Haste = 10 }, priority = ZeroPriority(), assignments = {}, key = "f2" },
        } },
    }
    local searchGoals = { Crit = 1, Haste = 1, Mastery = 0, Vers = 0 }
    AnalyzeAndSortPositions(positions, ZeroStats(), searchGoals, projection)
    local initial = { stats = ZeroStats(), priority = ZeroPriority(), assignments = {}, usedJewelry = {}, usedOwned = {}, key = "" }
    local exact = RunExact({ operations = 0 }, positions, initial, searchGoals, projection, 4)
    local beam, beamError
    local thread = coroutine.create(function() return RunBeam({ operations = 0 }, positions, initial, searchGoals, projection) end)
    while coroutine.status(thread) ~= "dead" do
        local ok, payload = coroutine.resume(thread)
        if not ok then beamError = payload; break end
        if coroutine.status(thread) == "dead" then beam = payload end
    end
    Check("exact and bounded searches agree", not beamError and exact and beam and StatsSignature(exact.stats) == StatsSignature(beam.stats))

    local trinketOnlySnapshot = { slots = {} }
    for _, slotInstance in ipairs(SLOT_ORDER) do trinketOnlySnapshot.slots[slotInstance] = { itemID = 9000 } end
    trinketOnlySnapshot.slots["Trinket 1"] = {}
    trinketOnlySnapshot.slots["Trinket 2"] = {}
    local trinketPositions, trinketUnmatched = BuildPositions(1, nil, trinketOnlySnapshot, {
        { itemID = 7001, name = "Support Trinket", slot = "Trinket", equipLoc = "INVTYPE_TRINKET",
            eligibleSlotInstances = { "Trinket 1", "Trinket 2" }, matcherStats = { Crit = 20 } },
    })
    Check("trinkets are excluded from core match positions", #trinketPositions == 0 and #trinketUnmatched == 0)

    local supportCandidates = {
        { itemID = 7001, name = "Critical Support", slot = "Trinket", equipLoc = "INVTYPE_TRINKET", matcherStats = { Crit = 20 } },
        { itemID = 7002, name = "Unneeded Support", slot = "Trinket", equipLoc = "INVTYPE_TRINKET", matcherStats = { Haste = 20 } },
    }
    local supportItems = BuildStatSupportItems(1, supportCandidates,
        { stats = { Crit = 50 }, assignments = {} }, { Crit = 10, Haste = 0, Mastery = 0, Vers = 0 }, projection, 1, "master")
    Check("needed trinket stat becomes advisory support", #supportItems == 1 and supportItems[1].itemID == 7001)

    local reducedProjection = {
        baselineRatings = ZeroStats(),
        basePercentages = ZeroStats(),
        masteryCoefficient = 1,
        matchStyle = "balanced",
        priorityWeights = { Crit = 1, Haste = 1, Mastery = 1, Vers = 1 },
        bonusCache = { Crit = {}, Haste = {}, Mastery = {}, Vers = {} },
    }
    for _, key in ipairs(SECONDARY) do
        for rating = 0, 1000 do
            reducedProjection.bonusCache[key][tostring(rating)] = key == "Crit" and
                (rating <= 60 and rating / 10 or 6 + ((rating - 60) / 20)) or rating / 10
        end
    end
    local reducedSupports = BuildStatSupportItems(1, {
        { itemID = 7003, name = "Reduced Support", slot = "Trinket", equipLoc = "INVTYPE_TRINKET", matcherStats = { Crit = 30 } },
    }, { stats = { Crit = 50 }, assignments = {} }, { Crit = 10, Haste = 0, Mastery = 0, Vers = 0 }, reducedProjection, 1, "master")
    Check("trinket support is withheld in reduced efficiency", #reducedSupports == 0)

    local mapping = KeyLab.GearLootMapping
    if mapping and type(mapping.GetItemStats) == "function" then
        local originalGetItemStats = mapping.GetItemStats
        local normalizedOK, normalizedError = pcall(function()
            mapping.GetItemStats = function(item) return item.testStats end
            local candidates = {
                { itemID = 1, slot = "Head", itemLevel = 246, testStats = { Crit = 80, Haste = 20 } },
                { itemID = 2, slot = "Head", itemLevel = 272, testStats = { Crit = 120, Haste = 30 } },
            }
            NormalizeMasterCandidates(candidates, 1)
            Check("recorded levels normalize equivalent patterns", Near(StatsTotal(candidates[1].matcherStats), StatsTotal(candidates[2].matcherStats)))
        end)
        mapping.GetItemStats = originalGetItemStats
        Check("master normalization regression completed", normalizedOK == true)
        if not normalizedOK then table.insert(failures, "master normalization error: " .. tostring(normalizedError)) end
    end

    if mapping and type(mapping.GetItem) == "function" then
        local originalGetItem = mapping.GetItem
        local distinctOK, distinctError = pcall(function()
            mapping.GetItem = function(itemID)
                local records = {
                    [101] = { itemID = 101, name = "First Trinket", sourceName = "Dungeon One", itemLevel = 246 },
                    [202] = { itemID = 202, name = "Second Trinket", sourceName = "Dungeon Two", itemLevel = 276 },
                }
                return records[tonumber(itemID)]
            end
            local assignments = {
                { slotInstance = "Trinket 1", itemID = 101, name = "First Trinket", sourceName = "Dungeon One" },
                { slotInstance = "Trinket 2", itemID = 202, name = "First Trinket", sourceName = "Dungeon One" },
            }
            local chosen = BuildSelectedItems(assignments, "master", nil, 1)
            Check("duplicate-stat trinkets keep distinct names", chosen[1] and chosen[1].name == "First Trinket"
                and chosen[2] and chosen[2].name == "Second Trinket")
            Check("duplicate-stat trinkets keep distinct sources", chosen[2] and chosen[2].sourceName == "Dungeon Two")
        end)
        mapping.GetItem = originalGetItem
        Check("distinct trinket result regression completed", distinctOK == true)
        if not distinctOK then table.insert(failures, "distinct trinket result error: " .. tostring(distinctError)) end
    end

    return #failures == 0, string.format("%d passed, %d failed%s", passed, #failures,
        #failures > 0 and (": " .. table.concat(failures, "; ")) or ""), failures
end

local eventFrame = CreateFrame and CreateFrame("Frame") or nil
if eventFrame then
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:SetScript("OnEvent", function(_, _, unit)
        if not unit or unit == "player" then
            Matcher.Cancel()
        end
    end)
end

return Matcher
