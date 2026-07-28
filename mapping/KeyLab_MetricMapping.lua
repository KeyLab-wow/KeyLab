local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Mapping = KeyLab.Mapping or {}

--[[
KeyLab Metric Mapping

Purpose:
- Defines the C_DamageMeter metric types KeyLab keeps.
- Blizzard provides metricType numbers.
- KeyLab stores only metrics 0 through 9.
- Metric 10 Enemy Damage Taken is intentionally excluded.

Rule:
If a metric is not listed with store = true, KeyLab does not store/display it.
]]

KeyLab.Mapping.MetricOrder = {
    0, -- Damage Done
    1, -- DPS
    2, -- Healing Done
    3, -- HPS
    4, -- Absorbs
    5, -- Interrupts
    6, -- Dispels
    7, -- Damage Taken
    8, -- Avoidable Damage Taken
    9, -- Deaths
}

-- Talent Builds, Stat Profiles, and Gear Profiles compare complete setups.
-- DPS and HPS are the only performance choices used by those comparison tabs.
KeyLab.Mapping.ProfileComparisonMetricKeys = {
    "dps",
    "hps",
}

KeyLab.Mapping.Metrics = {
    [0] = {
        metricType = 0,
        keylabKey = "damageDone",
        label = "Damage Done",
        displayType = "number",
        valueField = "totalAmount",
        higherIsBetter = true,
        store = true,
    },

    [1] = {
        metricType = 1,
        keylabKey = "dps",
        label = "DPS",
        displayType = "number",
        valueField = "amountPerSecond",
        higherIsBetter = true,
        store = true,
    },

    [2] = {
        metricType = 2,
        keylabKey = "healingDone",
        label = "Healing Done",
        displayType = "number",
        valueField = "totalAmount",
        higherIsBetter = true,
        store = true,
    },

    [3] = {
        metricType = 3,
        keylabKey = "hps",
        label = "HPS",
        displayType = "number",
        valueField = "amountPerSecond",
        higherIsBetter = true,
        store = true,
    },

    [4] = {
        metricType = 4,
        keylabKey = "absorbs",
        label = "Absorbs",
        displayType = "number",
        valueField = "totalAmount",
        higherIsBetter = true,
        store = true,
    },

    [5] = {
        metricType = 5,
        keylabKey = "interrupts",
        label = "Interrupts",
        displayType = "number",
        valueField = "totalAmount",
        higherIsBetter = true,
        store = true,
    },

    [6] = {
        metricType = 6,
        keylabKey = "dispels",
        label = "Dispels",
        displayType = "number",
        valueField = "totalAmount",
        higherIsBetter = true,
        store = true,
    },

    [7] = {
        metricType = 7,
        keylabKey = "damageTaken",
        label = "Damage Taken",
        displayType = "number",
        valueField = "totalAmount",
        higherIsBetter = false,
        store = true,
    },

    [8] = {
        metricType = 8,
        keylabKey = "avoidableDamageTaken",
        label = "Avoidable Damage Taken",
        displayType = "number",
        valueField = "totalAmount",
        higherIsBetter = false,
        store = true,
    },

    [9] = {
        metricType = 9,
        keylabKey = "deaths",
        label = "Deaths",
        displayType = "number",
        valueField = "totalAmount",
        higherIsBetter = false,
        store = true,
    },

    [10] = {
        metricType = 10,
        keylabKey = "enemyDamageTaken",
        label = "Enemy Damage Taken",
        displayType = "number",
        valueField = "totalAmount",
        higherIsBetter = true,
        store = false,
        note = "Blizzard provides this, but KeyLab intentionally excludes it.",
    },
}

KeyLab.Mapping.VirtualMetrics = {
    groupDeaths = {
        keylabKey = "groupDeaths",
        label = "Group Deaths",
        displayType = "number",
        higherIsBetter = false,
        store = true,
        note = "Derived from captured pull death events.",
    },
    healingDoneWithAbsorbs = {
        keylabKey = "healingDoneWithAbsorbs",
        label = "Healing Done",
        displayType = "number",
        higherIsBetter = true,
        store = true,
        note = "Display metric that includes absorbs when absorb data is captured.",
    },
    hpsWithAbsorbs = {
        keylabKey = "hpsWithAbsorbs",
        label = "HPS",
        displayType = "number",
        higherIsBetter = true,
        store = true,
        note = "Display metric that includes absorbs per second when absorb data is captured.",
    },
}
