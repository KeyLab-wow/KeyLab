local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Mapping = KeyLab.Mapping or {}

--[[
KeyLab Stat Mapping

Purpose:
- Defines ONLY the player stats KeyLab wants to keep.
- Capture stores the raw selected Blizzard value.
- Formatting happens later in KeyLab_Formatters.lua.
- UI should read these labels/order instead of hardcoding stat names.

Rule:
If a stat is not listed here, KeyLab does not store/display it.
]]

KeyLab.Mapping.StatOrder = {
    -- Primary stats
    "strength",
    "agility",
    "stamina",
    "intellect",

    -- Secondary stats
    "crit",
    "haste",
    "mastery",
    "versatility",

    -- Tertiary / defensive stats
    "leech",
    "avoidance",
    "speed",
    "dodge",
    "parry",
    "block",
    "armor",
}

KeyLab.Mapping.Stats = {
    strength = {
        blizzardAPI = "UnitStat('player', 1)",
        keylabKey = "strength",
        label = "Strength",
        category = "primary",
        resultIndex = 2, -- effectiveStat
        displayType = "number",
        store = true,
    },

    agility = {
        blizzardAPI = "UnitStat('player', 2)",
        keylabKey = "agility",
        label = "Agility",
        category = "primary",
        resultIndex = 2, -- effectiveStat
        displayType = "number",
        store = true,
    },

    stamina = {
        blizzardAPI = "UnitStat('player', 3)",
        keylabKey = "stamina",
        label = "Stamina",
        category = "primary",
        resultIndex = 2, -- effectiveStat
        displayType = "number",
        store = true,
    },

    intellect = {
        blizzardAPI = "UnitStat('player', 4)",
        keylabKey = "intellect",
        label = "Intellect",
        category = "primary",
        resultIndex = 2, -- effectiveStat
        displayType = "number",
        store = true,
    },

    crit = {
        blizzardAPI = "GetCritChance()",
        keylabKey = "crit",
        label = "Critical Strike",
        category = "secondary",
        resultIndex = 1,
        displayType = "percent",
        store = true,
    },

    haste = {
        blizzardAPI = "GetHaste()",
        keylabKey = "haste",
        label = "Haste",
        category = "secondary",
        resultIndex = 1,
        displayType = "percent",
        store = true,
    },

    mastery = {
        blizzardAPI = "GetMasteryEffect()",
        keylabKey = "mastery",
        label = "Mastery",
        category = "secondary",
        resultIndex = 1,
        displayType = "percent",
        store = true,
    },

    versatility = {
        blizzardAPI = "GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE)",
        keylabKey = "versatility",
        label = "Versatility",
        category = "secondary",
        resultIndex = 1,
        displayType = "percent",
        store = true,
    },

    leech = {
        blizzardAPI = "GetLifesteal()",
        keylabKey = "leech",
        label = "Leech",
        category = "tertiary",
        resultIndex = 1,
        displayType = "percent",
        store = true,
    },

    avoidance = {
        blizzardAPI = "GetAvoidance()",
        keylabKey = "avoidance",
        label = "Avoidance",
        category = "tertiary",
        resultIndex = 1,
        displayType = "percent",
        store = true,
    },

    speed = {
        blizzardAPI = "GetSpeed()",
        keylabKey = "speed",
        label = "Speed",
        category = "tertiary",
        resultIndex = 1,
        displayType = "percent",
        store = true,
    },

    dodge = {
        blizzardAPI = "GetDodgeChance()",
        keylabKey = "dodge",
        label = "Dodge",
        category = "tertiary",
        resultIndex = 1,
        displayType = "percent",
        store = true,
    },

    parry = {
        blizzardAPI = "GetParryChance()",
        keylabKey = "parry",
        label = "Parry",
        category = "tertiary",
        resultIndex = 1,
        displayType = "percent",
        store = true,
    },

    block = {
        blizzardAPI = "GetBlockChance()",
        keylabKey = "block",
        label = "Block",
        category = "tertiary",
        resultIndex = 1,
        displayType = "percent",
        store = true,
    },

    armor = {
        blizzardAPI = "UnitArmor('player')",
        keylabKey = "armor",
        label = "Armor",
        category = "tertiary",
        resultIndex = 2, -- effectiveArmor
        displayType = "number",
        store = true,
    },
}