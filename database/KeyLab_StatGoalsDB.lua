local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.StatGoalsDB = KeyLab.StatGoalsDB or {}
local StatGoalsDB = KeyLab.StatGoalsDB

local DEFAULT_TARGETS = {
    mastery = 0,
    haste = 0,
    crit = 0,
    versatility = 0,
}

local VALID_STATS = {
    crit = true,
    haste = true,
    mastery = true,
    versatility = true,
}

local DEFAULT_DISPLAY_ORDER = { "crit", "mastery", "haste", "versatility" }

local function NormalizeDisplayOrder(order)
    local normalized, seen = {}, {}
    for _, statKey in ipairs(type(order) == "table" and order or {}) do
        if VALID_STATS[statKey] and not seen[statKey] then
            seen[statKey] = true
            table.insert(normalized, statKey)
        end
    end
    for _, statKey in ipairs(DEFAULT_DISPLAY_ORDER) do
        if not seen[statKey] then table.insert(normalized, statKey) end
    end
    return normalized
end

local function EnsureRoot()
    if KeyLab.DB and KeyLab.DB.Get then
        KeyLab.DB.Get()
    end

    KeyLabDB = KeyLabDB or {}
    KeyLabDB.statGoals = KeyLabDB.statGoals or {}
    return KeyLabDB
end

local function CurrentCharacterKey()
    local name, realm
    if UnitFullName then
        name, realm = UnitFullName("player")
    end
    if not name or name == "" then
        name = UnitName and UnitName("player") or "Unknown"
    end
    if not realm or realm == "" then
        realm = GetRealmName and GetRealmName() or "Unknown"
    end
    return tostring(name or "Unknown") .. "-" .. tostring(realm or "Unknown")
end

local function CurrentSpecID()
    if KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.GetCurrentSpecID then
        return KeyLab.LootTargetsDB.GetCurrentSpecID()
    end

    local specIndex = GetSpecialization and GetSpecialization()
    if specIndex and GetSpecializationInfo then
        local specID = GetSpecializationInfo(specIndex)
        if specID then return specID end
    end
    return 0
end

local function EnsureGoals(specID)
    local db = EnsureRoot()
    local characterKey = CurrentCharacterKey()
    specID = tonumber(specID or CurrentSpecID()) or 0

    db.statGoals[characterKey] = db.statGoals[characterKey] or {}
    db.statGoals[characterKey][specID] = db.statGoals[characterKey][specID] or {}

    local goals = db.statGoals[characterKey][specID]
    local legacyPriority = goals.priority
    goals.priority = nil
    goals.targets = goals.targets or {}
    goals.displayOrder = NormalizeDisplayOrder(goals.displayOrder or legacyPriority)

    for statKey, defaultValue in pairs(DEFAULT_TARGETS) do
        goals.targets[statKey] = tonumber(goals.targets[statKey]) or defaultValue
    end

    return goals
end

function StatGoalsDB.CleanupLegacy()
    local db = EnsureRoot()
    for _, characterGoals in pairs(db.statGoals or {}) do
        if type(characterGoals) == "table" then
            for _, goals in pairs(characterGoals) do
                if type(goals) == "table" then
                    goals.displayOrder = NormalizeDisplayOrder(goals.displayOrder or goals.priority)
                    goals.priority = nil
                end
            end
        end
    end
end

function StatGoalsDB.GetGoals(specID)
    return EnsureGoals(specID)
end

function StatGoalsDB.GetDisplayOrder(specID)
    local goals = EnsureGoals(specID)
    local copy = {}
    for _, statKey in ipairs(goals.displayOrder or DEFAULT_DISPLAY_ORDER) do table.insert(copy, statKey) end
    return copy
end

function StatGoalsDB.MoveDisplayStat(specID, statKey, direction)
    if not VALID_STATS[statKey] then return false end
    local goals = EnsureGoals(specID)
    local order = goals.displayOrder
    local currentIndex
    for index, key in ipairs(order) do
        if key == statKey then currentIndex = index; break end
    end
    if not currentIndex then return false end
    local targetIndex = direction == "up" and currentIndex - 1 or direction == "down" and currentIndex + 1 or currentIndex
    if targetIndex < 1 or targetIndex > #order or targetIndex == currentIndex then return false end
    order[currentIndex], order[targetIndex] = order[targetIndex], order[currentIndex]
    return true
end

function StatGoalsDB.SetTarget(specID, statKey, value)
    if not VALID_STATS[statKey] then return false end

    value = tonumber(value) or 0
    if value < 0 then value = 0 end
    if value > 100 then value = 100 end

    local goals = EnsureGoals(specID)
    local changed = tonumber(goals.targets[statKey]) ~= value
    goals.targets[statKey] = value
    if changed and KeyLab.StatGoalMatcher and KeyLab.StatGoalMatcher.ClearResult then
        KeyLab.StatGoalMatcher.ClearResult(specID, "goals_changed")
    end
    return true
end

function StatGoalsDB.GetTotal(specID)
    local goals = EnsureGoals(specID)
    local total = 0
    for statKey in pairs(VALID_STATS) do total = total + (tonumber(goals.targets[statKey]) or 0) end
    return total
end

function StatGoalsDB.Validate(specID)
    local goals = EnsureGoals(specID)
    local total = 0
    for statKey in pairs(VALID_STATS) do
        local value = tonumber(goals.targets[statKey])
        if value == nil or value < 0 or value > 100 then return false, "Each stat goal must be from 0% to 100%." end
        total = total + value
    end
    if math.abs(total - 100) > 0.001 then
        return false, "Crit, Haste, Mastery, and Versatility must total exactly 100%."
    end
    return true, nil, total
end

function StatGoalsDB.IsValidStat(statKey)
    return VALID_STATS[statKey] == true
end

return StatGoalsDB
