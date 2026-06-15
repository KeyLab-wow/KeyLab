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
        if target > 0 then
            if context.below and context.below[statKey] then
                table.insert(prioritize, label)
            elseif context.above and context.above[statKey] then
                table.insert(cautious, label)
            end
        end
    end

    if #prioritize > 0 then
        table.insert(lines, "Focus gear with: " .. table.concat(prioritize, ", ") .. ".")
    else
        table.insert(lines, "Focus gear with your highest-priority useful stats.")
    end

    if #cautious > 0 then
        table.insert(lines, "Avoid over-stacking: " .. table.concat(cautious, ", ") .. ".")
    else
        table.insert(lines, "No over-stacked goal stats right now.")
    end

    table.insert(lines, "Use labels to choose targets and personal BIS overrides.")

    return lines
end

function Guidance.GetItemGuidance(item, context, status)
    context = context or Guidance.BuildContext()
    if KeyLab.ItemAnalysis and KeyLab.ItemAnalysis.GetItemGuidance then
        return KeyLab.ItemAnalysis.GetItemGuidance(item, context, context.currentStats, status)
    end

    return {
        label = "Temporary Option",
        color = "muted",
        reason = "Item analysis is unavailable.",
        score = 0,
    }
end

return Guidance
