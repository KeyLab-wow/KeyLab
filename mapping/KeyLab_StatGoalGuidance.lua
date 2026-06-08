local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.StatGoalGuidance = KeyLab.StatGoalGuidance or {}
local Guidance = KeyLab.StatGoalGuidance

local STAT_LABELS = {
    crit = "Crit",
    haste = "Haste",
    mastery = "Mastery",
    versatility = "Versatility",
}

local ITEM_STAT_KEYS = {
    crit = "Crit",
    haste = "Haste",
    mastery = "Mastery",
    versatility = "Vers",
}

local function safeNumber(value)
    if KeyLab.Utils and KeyLab.Utils.SafeNumber then
        return KeyLab.Utils.SafeNumber(value)
    end

    local ok, result = pcall(function()
        local n = tonumber(value)
        if type(n) ~= "number" then return nil end
        local copy = n + 0
        if copy ~= copy then return nil end
        if not (copy < math.huge and copy > -math.huge) then return nil end
        return copy
    end)

    if ok and type(result) == "number" then
        return result
    end

    return nil
end

local function safeCallNumber(fn, ...)
    if type(fn) ~= "function" then
        return 0
    end

    local ok, value = pcall(fn, ...)
    if not ok then
        return 0
    end

    return safeNumber(value) or 0
end

local function round1(value)
    value = safeNumber(value) or 0
    return math.floor((value * 10) + 0.5) / 10
end

local function formatPercent(value)
    return string.format("%.1f%%", round1(value))
end

local function copyTable(tbl)
    local out = {}
    for key, value in pairs(tbl or {}) do
        out[key] = value
    end
    return out
end

function Guidance.GetStatLabel(statKey)
    return STAT_LABELS[statKey] or tostring(statKey or "")
end

function Guidance.GetCurrentStats()
    if KeyLab.Capture and KeyLab.Capture.Stats and KeyLab.Capture.Stats.GetSnapshot then
        local stats = KeyLab.Capture.Stats.GetSnapshot() or {}
        return {
            crit = safeNumber(stats.crit) or 0,
            haste = safeNumber(stats.haste) or 0,
            mastery = safeNumber(stats.mastery) or 0,
            versatility = safeNumber(stats.versatility) or 0,
        }
    end

    return {
        crit = safeCallNumber(GetCritChance),
        haste = safeCallNumber(GetHaste),
        mastery = safeCallNumber(GetMasteryEffect),
        versatility = CR_VERSATILITY_DAMAGE_DONE and safeCallNumber(GetCombatRatingBonus, CR_VERSATILITY_DAMAGE_DONE) or 0,
    }
end

function Guidance.BuildContext(specID)
    local goals = KeyLab.StatGoalsDB and KeyLab.StatGoalsDB.GetGoals and KeyLab.StatGoalsDB.GetGoals(specID) or {}
    local priority = {}
    for _, statKey in ipairs(goals.priority or {}) do
        table.insert(priority, statKey)
    end

    if #priority == 0 and KeyLab.StatGoalsDB and KeyLab.StatGoalsDB.GetDefaultPriority then
        priority = KeyLab.StatGoalsDB.GetDefaultPriority()
    end

    local targets = copyTable(goals.targets or {})
    local currentStats = Guidance.GetCurrentStats()
    local below, above, configured = {}, {}, false

    for _, statKey in ipairs(priority) do
        local target = safeNumber(targets[statKey]) or 0
        local current = safeNumber(currentStats[statKey]) or 0
        if target > 0 then
            configured = true
            if current < (target - 0.1) then
                below[statKey] = target - current
            elseif current > (target + 0.1) then
                above[statKey] = current - target
            end
        end
    end

    return {
        goals = goals,
        priority = priority,
        targets = targets,
        currentStats = currentStats,
        below = below,
        above = above,
        configured = configured,
    }
end

function Guidance.GetSummaryLines(context)
    context = context or Guidance.BuildContext()
    local lines = {}
    local prioritize, cautious = {}, {}

    if not context.configured then
        return {
            "Set target percentages to start labeling items.",
            "Priority order still controls how useful stats are weighted.",
        }
    end

    for _, statKey in ipairs(context.priority or {}) do
        local label = Guidance.GetStatLabel(statKey)
        local target = safeNumber(context.targets and context.targets[statKey]) or 0
        local current = safeNumber(context.currentStats and context.currentStats[statKey]) or 0
        if target > 0 then
            if context.below and context.below[statKey] then
                table.insert(lines, label .. " is below goal (" .. formatPercent(current) .. " / " .. formatPercent(target) .. ")")
                table.insert(prioritize, label)
            elseif context.above and context.above[statKey] then
                table.insert(lines, label .. " is already above goal (" .. formatPercent(current) .. " / " .. formatPercent(target) .. ")")
                table.insert(cautious, label)
            else
                table.insert(lines, label .. " is near goal (" .. formatPercent(current) .. " / " .. formatPercent(target) .. ")")
            end
        end
    end

    if #prioritize > 0 then
        table.insert(lines, "Prioritize gear with " .. table.concat(prioritize, " and/or "))
    end
    if #cautious > 0 then
        table.insert(lines, "Be cautious with gear that mainly adds " .. table.concat(cautious, " or "))
    end

    return lines
end

function Guidance.GetItemGuidance(item, context)
    context = context or Guidance.BuildContext()

    if not context.configured then
        return {
            label = "Temporary Option",
            color = "muted",
            reason = "Set stat targets for stronger guidance.",
            score = 0,
        }
    end

    if not item or type(item.stats) ~= "table" then
        return {
            label = "Avoid for Goal",
            color = "warning",
            reason = "No useful secondary stats for this goal.",
            score = -1,
        }
    end

    local helpCount, riskCount, neutralCount, score = 0, 0, 0, 0
    local helpful, risky = {}, {}

    for rank, statKey in ipairs(context.priority or {}) do
        local itemStatKey = ITEM_STAT_KEYS[statKey]
        local hasStat = itemStatKey and item.stats[itemStatKey] ~= nil
        local weight = math.max(1, 5 - rank)

        if hasStat then
            if context.below and context.below[statKey] then
                helpCount = helpCount + 1
                score = score + (weight * 2)
                table.insert(helpful, Guidance.GetStatLabel(statKey))
            elseif context.above and context.above[statKey] then
                riskCount = riskCount + 1
                score = score - weight
                table.insert(risky, Guidance.GetStatLabel(statKey))
            else
                neutralCount = neutralCount + 1
                score = score + weight
            end
        end
    end

    if helpCount >= 2 or score >= 8 then
        return {
            label = "Best Target",
            color = "green",
            reason = "Helps " .. table.concat(helpful, " and "),
            score = score,
        }
    end

    if helpCount >= 1 and score >= 3 then
        return {
            label = "Good Backup",
            color = "blue",
            reason = "Useful for " .. table.concat(helpful, " and "),
            score = score,
        }
    end

    if riskCount > 0 and helpCount == 0 then
        return {
            label = "Avoid for Goal",
            color = "warning",
            reason = "Mostly supports " .. table.concat(risky, " and "),
            score = score,
        }
    end

    if helpCount > 0 or neutralCount > 0 then
        return {
            label = "Temporary Option",
            color = "muted",
            reason = "Usable, but not a strong goal match.",
            score = score,
        }
    end

    return {
        label = "Avoid for Goal",
        color = "warning",
        reason = "Does not support the current goal.",
        score = score,
    }
end

return Guidance
