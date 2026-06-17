local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Mapping = KeyLab.Mapping or {}

local ClassSpecs = {}
KeyLab.Mapping.ClassSpecs = ClassSpecs

local function Normalize(value)
    value = tostring(value or "")
    value = value:gsub("%s+", "")
    value = value:gsub("'", "")
    value = value:gsub("%-+", "")
    return string.lower(value)
end

local bySpecID = {}
local byName = {}

local function Add(specID, className, specName, role, aliases)
    local entry = {
        specID = tonumber(specID),
        className = className,
        specName = specName,
        role = role,
    }

    if entry.specID then
        bySpecID[entry.specID] = entry
    end

    local classKey = Normalize(className)
    byName[classKey .. ":" .. Normalize(specName)] = entry

    for _, alias in ipairs(aliases or {}) do
        byName[classKey .. ":" .. Normalize(alias)] = entry
    end
end

Add(62, "Mage", "Arcane", "Ranged")
Add(63, "Mage", "Fire", "Ranged")
Add(64, "Mage", "Frost", "Ranged")
Add(65, "Paladin", "Holy", "Healer")
Add(66, "Paladin", "Protection", "Tank")
Add(70, "Paladin", "Retribution", "Melee")
Add(71, "Warrior", "Arms", "Melee")
Add(72, "Warrior", "Fury", "Melee")
Add(73, "Warrior", "Protection", "Tank")
Add(102, "Druid", "Balance", "Ranged")
Add(103, "Druid", "Feral", "Melee")
Add(104, "Druid", "Guardian", "Tank")
Add(105, "Druid", "Restoration", "Healer")
Add(250, "Death Knight", "Blood", "Tank")
Add(251, "Death Knight", "Frost", "Melee")
Add(252, "Death Knight", "Unholy", "Melee")
Add(253, "Hunter", "Beast Mastery", "Ranged")
Add(254, "Hunter", "Marksmanship", "Ranged", { "Markmanship" })
Add(255, "Hunter", "Survival", "Melee")
Add(256, "Priest", "Discipline", "Healer")
Add(257, "Priest", "Holy", "Healer")
Add(258, "Priest", "Shadow", "Ranged")
Add(259, "Rogue", "Assassination", "Melee")
Add(260, "Rogue", "Outlaw", "Melee")
Add(261, "Rogue", "Subtlety", "Melee", { "Sublety" })
Add(262, "Shaman", "Elemental", "Ranged")
Add(263, "Shaman", "Enhancement", "Melee")
Add(264, "Shaman", "Restoration", "Healer")
Add(265, "Warlock", "Affliction", "Ranged")
Add(266, "Warlock", "Demonology", "Ranged")
Add(267, "Warlock", "Destruction", "Ranged")
Add(268, "Monk", "Brewmaster", "Tank")
Add(269, "Monk", "Windwalker", "Melee")
Add(270, "Monk", "Mistweaver", "Healer")
Add(577, "Demon Hunter", "Havoc", "Melee")
Add(581, "Demon Hunter", "Vengeance", "Tank")
Add(1467, "Evoker", "Devastation", "Ranged")
Add(1468, "Evoker", "Preservation", "Healer")
Add(1473, "Evoker", "Augmentation", "Ranged")
Add(1480, "Demon Hunter", "Devourer", "Melee")

function ClassSpecs.Normalize(value)
    return Normalize(value)
end

function ClassSpecs.GetSpec(specID, className, specName)
    specID = tonumber(specID)
    if specID and bySpecID[specID] then
        return bySpecID[specID]
    end

    local classKey = Normalize(className)
    local specKey = Normalize(specName)
    if classKey ~= "" and specKey ~= "" then
        return byName[classKey .. ":" .. specKey]
    end

    return nil
end

function ClassSpecs.GetRole(specID, className, specName)
    local entry = ClassSpecs.GetSpec(specID, className, specName)
    return entry and entry.role or nil
end

function ClassSpecs.GetGraphProfile(specID, className, specName)
    local role = ClassSpecs.GetRole(specID, className, specName)

    if role == "Healer" then
        return {
            role = role,
            title = "HPS by Pull",
            subtitle = "Healing performance for each captured combat session in this run.",
            metrics = { "hps" },
        }
    end

    if role == "Tank" then
        return {
            role = role,
            title = "Damage Taken by Pull",
            subtitle = "Tank pressure for each captured combat session in this run.",
            metrics = { "damageTaken", "avoidableDamageTaken" },
        }
    end

    return {
        role = role or "Damage",
        title = "DPS by Pull",
        subtitle = "Damage performance for each captured combat session in this run.",
        metrics = { "dps" },
    }
end

return ClassSpecs
