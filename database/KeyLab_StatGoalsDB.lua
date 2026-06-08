local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.StatGoalsDB = KeyLab.StatGoalsDB or {}
local StatGoalsDB = KeyLab.StatGoalsDB

local DEFAULT_PRIORITY = { "mastery", "haste", "crit", "versatility" }
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

local function CopyPriority(priority)
    local out, used = {}, {}
    for _, statKey in ipairs(priority or {}) do
        if VALID_STATS[statKey] and not used[statKey] then
            used[statKey] = true
            table.insert(out, statKey)
        end
    end
    for _, statKey in ipairs(DEFAULT_PRIORITY) do
        if not used[statKey] then
            used[statKey] = true
            table.insert(out, statKey)
        end
    end
    return out
end

local function EnsureGoals(specID)
    local db = EnsureRoot()
    local characterKey = CurrentCharacterKey()
    specID = tonumber(specID or CurrentSpecID()) or 0

    db.statGoals[characterKey] = db.statGoals[characterKey] or {}
    db.statGoals[characterKey][specID] = db.statGoals[characterKey][specID] or {}

    local goals = db.statGoals[characterKey][specID]
    goals.priority = CopyPriority(goals.priority)
    goals.targets = goals.targets or {}

    for statKey, defaultValue in pairs(DEFAULT_TARGETS) do
        goals.targets[statKey] = tonumber(goals.targets[statKey]) or defaultValue
    end

    return goals
end

function StatGoalsDB.GetGoals(specID)
    return EnsureGoals(specID)
end

function StatGoalsDB.SetTarget(specID, statKey, value)
    if not VALID_STATS[statKey] then return false end

    value = tonumber(value) or 0
    if value < 0 then value = 0 end
    if value > 200 then value = 200 end

    local goals = EnsureGoals(specID)
    goals.targets[statKey] = value
    return true
end

function StatGoalsDB.MovePriority(specID, statKey, delta)
    if not VALID_STATS[statKey] then return false end

    local goals = EnsureGoals(specID)
    local priority = CopyPriority(goals.priority)
    local index

    for i, key in ipairs(priority) do
        if key == statKey then
            index = i
            break
        end
    end

    if not index then return false end

    local newIndex = index + (tonumber(delta) or 0)
    if newIndex < 1 then newIndex = 1 end
    if newIndex > #priority then newIndex = #priority end
    if newIndex == index then return false end

    table.remove(priority, index)
    table.insert(priority, newIndex, statKey)
    goals.priority = priority
    return true
end

function StatGoalsDB.GetDefaultPriority()
    return CopyPriority(DEFAULT_PRIORITY)
end

function StatGoalsDB.IsValidStat(statKey)
    return VALID_STATS[statKey] == true
end

return StatGoalsDB
