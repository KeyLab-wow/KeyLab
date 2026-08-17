-- KeyLab_Season2GearInfo.lua
-- Static Midnight Season 2 gearing reference used by Gear Planning.

local ADDON_NAME, KeyLab = ...

KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

local Data = {
    season = "MN S2",
    title = "Midnight Season 2 Gear Guide",
    description = "See where gear comes from, which upgrade track it uses, and what the Great Vault can reward.",
}

KeyLab.Season2GearInfo = Data

Data.tracks = {
    {
        id = "unranked",
        label = "Unranked and Not Upgradeable",
        ribbonLabel = "UNRANKED",
        range = "201–263",
        itemLevels = { "201–214", "256", "259", "263" },
        note = "These items do not use an upgrade track.",
        showInRibbon = false,
    },
    {
        id = "adventurer",
        label = "Adventurer",
        ribbonLabel = "ADVENTURER",
        range = "266–276",
        itemLevels = { "266", "269", "272", "276" },
        showInRibbon = true,
    },
    {
        id = "veteran",
        label = "Veteran",
        ribbonLabel = "VETERAN",
        range = "279–289",
        itemLevels = { "279", "282", "285", "289" },
        showInRibbon = true,
    },
    {
        id = "champion",
        label = "Champion",
        ribbonLabel = "CHAMPION",
        range = "292–302",
        itemLevels = { "292", "295", "298", "302" },
        showInRibbon = true,
    },
    {
        id = "hero",
        label = "Hero",
        ribbonLabel = "HERO",
        range = "305–315",
        itemLevels = { "305", "308", "311", "315" },
        showInRibbon = true,
    },
    {
        id = "myth",
        label = "Myth",
        ribbonLabel = "MYTH",
        range = "318–344",
        itemLevels = { "318", "321", "324", "328", "331", "334", "337", "341", "344" },
        showInRibbon = true,
    },
}

local standardColumns = {
    { key = "activity", label = "Activity", weight = 0.58 },
    { key = "itemLevel", label = "Item Level", weight = 0.18 },
    { key = "track", label = "Track", weight = 0.24 },
}

local difficultyColumns = {
    { key = "activity", label = "Difficulty", weight = 0.58 },
    { key = "itemLevel", label = "Item Level", weight = 0.18 },
    { key = "track", label = "Track", weight = 0.24 },
}

local rangeColumns = {
    { key = "activity", label = "Difficulty", weight = 0.55 },
    { key = "itemLevel", label = "Item-Level Range", weight = 0.21 },
    { key = "track", label = "Track", weight = 0.24 },
}

local delveColumns = {
    { key = "activity", label = "Delve Tier", weight = 0.58 },
    { key = "itemLevel", label = "Item Level", weight = 0.18 },
    { key = "track", label = "Track", weight = 0.24 },
}

local requirementColumns = {
    { key = "activity", label = "Requirement", weight = 0.58 },
    { key = "itemLevel", label = "Item Level", weight = 0.18 },
    { key = "track", label = "Track", weight = 0.24 },
}

Data.rewardSourceOrder = {
    "dungeons", "raids", "delves", "outdoor", "lairs", "prey", "pvp", "crafted",
}

Data.rewardSources = {
    dungeons = {
        label = "Dungeons",
        title = "Dungeons",
        description = "Compare direct dungeon drops with the separate Great Vault and Nebulous Voidcore reward brackets.",
        sections = {
            {
                id = "dungeon-drops",
                title = "Dungeon Drops",
                columns = standardColumns,
                rows = {
                    { activity = "Normal / Follower", itemLevel = "259", track = "unranked" },
                    { activity = "Heroic", itemLevel = "276", track = "adventurer" },
                    { activity = "Mythic / M0", itemLevel = "292", track = "champion" },
                    { activity = "Mythic +2–3", itemLevel = "295", track = "champion" },
                    { activity = "Mythic +4", itemLevel = "298", track = "champion" },
                    { activity = "Mythic +5", itemLevel = "302", track = "champion" },
                    { activity = "Mythic +6–7", itemLevel = "305", track = "hero" },
                    { activity = "Mythic +8–9", itemLevel = "308", track = "hero" },
                    { activity = "Mythic +10 or higher", itemLevel = "311", track = "hero" },
                },
            },
            {
                id = "dungeon-vault",
                title = "Dungeon Great Vault and Nebulous Voidcore Bonus Roll",
                columns = standardColumns,
                greatVault = true,
                rows = {
                    { activity = "Heroic", itemLevel = "289", track = "veteran" },
                    { activity = "Mythic +2–3", itemLevel = "305", track = "hero" },
                    { activity = "Mythic +4–5", itemLevel = "308", track = "hero" },
                    { activity = "Mythic +6", itemLevel = "311", track = "hero" },
                    { activity = "Mythic +7–9", itemLevel = "315", track = "hero" },
                    { activity = "Mythic +10 or higher", itemLevel = "318", track = "myth" },
                },
            },
        },
    },
    raids = {
        label = "Raids",
        title = "Raids",
        description = "Raid drops use boss-dependent ranges, while Great Vault and Nebulous Voidcore rewards use their own values.",
        sections = {
            {
                id = "raid-drops",
                title = "Raid Drops",
                columns = rangeColumns,
                rows = {
                    { activity = "Raid Finder / LFR", itemLevel = "279–289", track = "veteran" },
                    { activity = "Normal", itemLevel = "292–302", track = "champion" },
                    { activity = "Heroic", itemLevel = "305–315", track = "hero" },
                    { activity = "Most Mythic bosses", itemLevel = "318–341", track = "myth" },
                    { activity = "Last 2 Mythic bosses", itemLevel = "344", track = "myth" },
                },
            },
            {
                id = "raid-vault",
                title = "Raid Great Vault and Nebulous Voidcore Bonus Roll",
                columns = difficultyColumns,
                greatVault = true,
                rows = {
                    { activity = "Raid Finder / LFR", itemLevel = "292", track = "champion" },
                    { activity = "Normal", itemLevel = "305", track = "hero" },
                    { activity = "Heroic", itemLevel = "318", track = "myth" },
                    { activity = "Most Mythic bosses", itemLevel = "334", track = "myth" },
                    { activity = "Last 2 Mythic bosses", itemLevel = "344", track = "myth" },
                },
            },
        },
    },
    delves = {
        label = "Delves",
        title = "Delves",
        description = "Bountiful Coffers, Trovehunter’s Bounty, and the Delve Great Vault use separate tier progressions.",
        sections = {
            {
                id = "bountiful-coffers",
                title = "Bountiful Coffers",
                columns = delveColumns,
                rows = {
                    { activity = "Tier 1", itemLevel = "266", track = "adventurer" },
                    { activity = "Tier 2", itemLevel = "269", track = "adventurer" },
                    { activity = "Tier 3", itemLevel = "272", track = "adventurer" },
                    { activity = "Tier 4", itemLevel = "276", track = "adventurer" },
                    { activity = "Tier 5", itemLevel = "279", track = "veteran" },
                    { activity = "Tier 6", itemLevel = "282", track = "veteran" },
                    { activity = "Tier 7", itemLevel = "292", track = "champion" },
                    { activity = "Tiers 8–11", itemLevel = "295", track = "champion" },
                },
            },
            {
                id = "trovehunters-bounty",
                title = "Trovehunter’s Bounty",
                columns = delveColumns,
                rows = {
                    { activity = "Tier 4", itemLevel = "282", track = "veteran" },
                    { activity = "Tier 5", itemLevel = "289", track = "veteran" },
                    { activity = "Tier 6", itemLevel = "292", track = "champion" },
                    { activity = "Tier 7", itemLevel = "295", track = "champion" },
                    { activity = "Tiers 8–11", itemLevel = "305", track = "hero" },
                },
            },
            {
                id = "delve-vault",
                title = "Delve Great Vault",
                columns = delveColumns,
                greatVault = true,
                rows = {
                    { activity = "Tier 1", itemLevel = "279", track = "veteran" },
                    { activity = "Tier 2", itemLevel = "282", track = "veteran" },
                    { activity = "Tier 3", itemLevel = "285", track = "veteran" },
                    { activity = "Tier 4", itemLevel = "289", track = "veteran" },
                    { activity = "Tier 5", itemLevel = "292", track = "champion" },
                    { activity = "Tier 6", itemLevel = "298", track = "champion" },
                    { activity = "Tier 7", itemLevel = "302", track = "champion" },
                    { activity = "Tiers 8–11", itemLevel = "305", track = "hero" },
                },
            },
        },
    },
    outdoor = {
        label = "Outdoor & Quests",
        title = "Outdoor and Quests",
        description = "Campaign, world, accolade, cache, and fragment rewards available across Season 2 outdoor content.",
        sections = {
            {
                id = "outdoor-quests",
                title = "Outdoor and Quest Rewards",
                columns = standardColumns,
                rows = {
                    { activity = "Leveling Campaign and Side Quests", itemLevel = "201–214", track = "unranked" },
                    { activity = "12.1 Campaign", itemLevel = "256", track = "unranked" },
                    { activity = "World Quests", itemLevel = "266–276", track = "adventurer" },
                    { activity = "500/750 Field Accolades", itemLevel = "279", track = "veteran" },
                    { activity = "Pinnacle Cache", itemLevel = "285", track = "veteran" },
                    { activity = "2 Atal’Utek Fragments", itemLevel = "292", track = "champion" },
                },
            },
        },
    },
    lairs = {
        label = "Lairs",
        title = "Lairs",
        description = "The Tidebound Grotto Lair Boss rewards a different track at each difficulty.",
        sections = {
            {
                id = "tidebound-grotto",
                title = "Tidebound Grotto Lair Boss",
                columns = difficultyColumns,
                rows = {
                    { activity = "World Difficulty", itemLevel = "279", track = "veteran" },
                    { activity = "Normal Difficulty", itemLevel = "292", track = "champion" },
                    { activity = "Heroic Difficulty", itemLevel = "305", track = "hero" },
                    { activity = "Mythic Difficulty", itemLevel = "318", track = "myth" },
                },
            },
        },
    },
    prey = {
        label = "Prey",
        title = "Prey",
        description = "Prey Hunts award direct gear and contribute to a separate Great Vault progression.",
        note = "Prey Hunts can be completed twice per difficulty each week.",
        sections = {
            {
                id = "prey-rewards",
                title = "Prey Hunt Rewards",
                columns = difficultyColumns,
                rows = {
                    { activity = "Normal", itemLevel = "266", track = "adventurer" },
                    { activity = "Hard", itemLevel = "279", track = "veteran" },
                    { activity = "Nightmare", itemLevel = "292", track = "champion" },
                },
            },
            {
                id = "prey-vault",
                title = "Prey Great Vault",
                columns = requirementColumns,
                greatVault = true,
                rows = {
                    { activity = "Normal", itemLevel = "279", track = "veteran" },
                    { activity = "Hard", itemLevel = "292", track = "champion" },
                    { activity = "Nightmare — T11, Journey 9", itemLevel = "305", track = "hero" },
                },
            },
        },
    },
    pvp = {
        label = "PvP",
        title = "PvP",
        description = "PvP items have a normal base item level and a separate item level while in Arenas and Battlegrounds.",
        note = "Arena/BG Item Level is the PvP-scaled value, not the item’s normal base item level.",
        sections = {
            {
                id = "pvp-rewards",
                title = "PvP Rewards",
                columns = {
                    { key = "activity", label = "Source", weight = 0.40 },
                    { key = "itemLevel", label = "Base Item Level", weight = 0.18 },
                    { key = "pvpItemLevel", label = "Arena/BG Item Level", weight = 0.22 },
                    { key = "track", label = "Track", weight = 0.20 },
                },
                rows = {
                    { activity = "Honor", itemLevel = "263", pvpItemLevel = "331", track = "unranked" },
                    { activity = "War Mode", itemLevel = "289", pvpItemLevel = "331", track = "veteran" },
                    { activity = "Conquest", itemLevel = "292", pvpItemLevel = "344", track = "champion" },
                },
            },
        },
    },
    crafted = {
        label = "Crafted",
        title = "Crafted Equipment",
        description = "Crafted item levels progress through crest additions, with Ascendant Venomstone upgrades unavailable until later in the season.",
        sections = {
            {
                id = "crafted-progression",
                title = "Crafted Equipment Progression",
                columns = {
                    { key = "activity", label = "Crafted Method", weight = 0.56 },
                    { key = "itemLevel", label = "Resulting Item-Level Range", weight = 0.22 },
                    { key = "track", label = "Track", weight = 0.22 },
                },
                rows = {
                    { activity = "Blues + 80 Adventurer Crests", itemLevel = "266–279", track = "adventurer", trackLabel = "Adventurer into Veteran" },
                    { activity = "Blues + 80 Veteran Crests", itemLevel = "279–292", track = "veteran", trackLabel = "Veteran into Champion" },
                    { activity = "Spark of Tides", itemLevel = "292–305", track = "champion", trackLabel = "Champion into Hero" },
                    { activity = "Add 80 Hero Crests", itemLevel = "305–318", track = "hero", trackLabel = "Hero into Myth" },
                    { activity = "Add 80 Myth Crests", itemLevel = "318–331", track = "myth", trackLabel = "Myth" },
                },
            },
            {
                id = "ascendant-venomstone",
                title = "Ascendant Venomstone Boost",
                notice = "Not available until later in the season.",
                columns = {
                    { key = "activity", label = "Upgrade", weight = 0.58 },
                    { key = "itemLevel", label = "Item Level", weight = 0.18 },
                    { key = "track", label = "Track", weight = 0.24 },
                },
                rows = {
                    { activity = "Ascended Hero Craft", itemLevel = "324", track = "myth" },
                    { activity = "Ascended Hero", itemLevel = "328", track = "myth" },
                    { activity = "Ascended Myth Craft", itemLevel = "337", track = "myth" },
                    { activity = "Ascended Myth", itemLevel = "341", track = "myth" },
                },
            },
        },
    },
}

Data.greatVaultSourceOrder = { "prey", "delves", "dungeons", "raids" }
Data.weeklyRewards = {
    heading = "WEEKLY REWARDS",
    body = "Great Vault rewards are earned from this week’s activities and claimed after the next weekly reset. Nebulous Voidcore bonus rolls follow their own availability and unlock rules.",
}

function Data.GetTrack(trackID)
    for _, track in ipairs(Data.tracks) do
        if track.id == trackID then return track end
    end
end

function Data.GetRewardSource(sourceID)
    return Data.rewardSources[sourceID]
end

function Data.GetGreatVaultSections(sourceID)
    local source = Data.rewardSources[sourceID]
    local sections = {}
    for _, section in ipairs(source and source.sections or {}) do
        if section.greatVault then sections[#sections + 1] = section end
    end
    return sections
end

return Data
