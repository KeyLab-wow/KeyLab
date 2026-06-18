local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Mapping = KeyLab.Mapping or {}

--[[
KeyLab Map Mapping

Purpose:
- Defines allowed Challenge Mode mapIDs.
- KeyLab only records runs whose activeChallengeMapID exists here.
- UI uses this list for dungeon names.
]]

KeyLab.Mapping.Maps = {
    [402] = { keylabKey = "map402", name = "Algeth'ar Academy", store = true },
    [503] = { keylabKey = "map503", name = "Ara-Kara, City of Echoes", store = true },
    [244] = { keylabKey = "map244", name = "Atal'Dazar", store = true },
    [164] = { keylabKey = "map164", name = "Auchindoun", store = true },
    [199] = { keylabKey = "map199", name = "Black Rook Hold", store = true },
    [163] = { keylabKey = "map163", name = "Bloodmaul Slag Mines", store = true },
    [405] = { keylabKey = "map405", name = "Brackenhide Hollow", store = true },
    [233] = { keylabKey = "map233", name = "Cathedral of Eternal Night", store = true },
    [506] = { keylabKey = "map506", name = "Cinderbrew Meadery", store = true },
    [502] = { keylabKey = "map502", name = "City of Threads", store = true },
    [210] = { keylabKey = "map210", name = "Court of Stars", store = true },
    [504] = { keylabKey = "map504", name = "Darkflame Cleft", store = true },
    [198] = { keylabKey = "map198", name = "Darkheart Thicket", store = true },
    [463] = { keylabKey = "map463", name = "Dawn of the Infinite: Galakrond's Fall", store = true },
    [464] = { keylabKey = "map464", name = "Dawn of the Infinite: Murozond's Rise", store = true },
    [377] = { keylabKey = "map377", name = "De Other Side", store = true },
    [542] = { keylabKey = "map542", name = "Eco-Dome Al'dani", store = true },
    [197] = { keylabKey = "map197", name = "Eye of Azshara", store = true },
    [245] = { keylabKey = "map245", name = "Freehold", store = true },
    [57]  = { keylabKey = "map57",  name = "Gate of the Setting Sun", store = true },
    [507] = { keylabKey = "map507", name = "Grim Batol", store = true },
    [166] = { keylabKey = "map166", name = "Grimrail Depot", store = true },
    [378] = { keylabKey = "map378", name = "Halls of Atonement", store = true },
    [406] = { keylabKey = "map406", name = "Halls of Infusion", store = true },
    [200] = { keylabKey = "map200", name = "Halls of Valor", store = true },
    [169] = { keylabKey = "map169", name = "Iron Docks", store = true },
    [249] = { keylabKey = "map249", name = "Kings' Rest", store = true },
    [558] = { keylabKey = "map558", name = "Magisters' Terrace", store = true },
    [560] = { keylabKey = "map560", name = "Maisara Caverns", store = true },
    [208] = { keylabKey = "map208", name = "Maw of Souls", store = true },
    [375] = { keylabKey = "map375", name = "Mists of Tirna Scithe", store = true },
    [60]  = { keylabKey = "map60",  name = "Mogu'shan Palace", store = true },
    [206] = { keylabKey = "map206", name = "Neltharion's Lair", store = true },
    [404] = { keylabKey = "map404", name = "Neltharus", store = true },
    [559] = { keylabKey = "map559", name = "Nexus-Point Xenas", store = true },
    [525] = { keylabKey = "map525", name = "Operation: Floodgate", store = true },
    [369] = { keylabKey = "map369", name = "Operation: Mechagon - Junkyard", store = true },
    [370] = { keylabKey = "map370", name = "Operation: Mechagon - Workshop", store = true },
    [556] = { keylabKey = "map556", name = "Pit of Saron", store = true },
    [379] = { keylabKey = "map379", name = "Plaguefall", store = true },
    [499] = { keylabKey = "map499", name = "Priory of the Sacred Flame", store = true },
    [227] = { keylabKey = "map227", name = "Return to Karazhan: Lower", store = true },
    [234] = { keylabKey = "map234", name = "Return to Karazhan: Upper", store = true },
    [399] = { keylabKey = "map399", name = "Ruby Life Pools", store = true },
    [380] = { keylabKey = "map380", name = "Sanguine Depths", store = true },
    [77]  = { keylabKey = "map77",  name = "Scarlet Halls", store = true },
    [78]  = { keylabKey = "map78",  name = "Scarlet Monastery", store = true },
    [76]  = { keylabKey = "map76",  name = "Scholomance", store = true },
    [239] = { keylabKey = "map239", name = "Seat of the Triumvirate", store = true },
    [583] = { keylabKey = "map583", name = "Seat of the Triumvirate", store = true },
    [58]  = { keylabKey = "map58",  name = "Shado-Pan Monastery", store = true },
    [165] = { keylabKey = "map165", name = "Shadowmoon Burial Grounds", store = true },
    [252] = { keylabKey = "map252", name = "Shrine of the Storm", store = true },
    [353] = { keylabKey = "map353", name = "Siege of Boralus", store = true },
    [59]  = { keylabKey = "map59",  name = "Siege of Niuzao Temple", store = true },
    [161] = { keylabKey = "map161", name = "Skyreach", store = true },
    [381] = { keylabKey = "map381", name = "Spires of Ascension", store = true },
    [56]  = { keylabKey = "map56",  name = "Stormstout Brewery", store = true },
    [392] = { keylabKey = "map392", name = "Tazavesh: So'leah's Gambit", store = true },
    [391] = { keylabKey = "map391", name = "Tazavesh: Streets of Wonder", store = true },
    [250] = { keylabKey = "map250", name = "Temple of Sethraliss", store = true },
    [2]   = { keylabKey = "map2",   name = "Temple of the Jade Serpent", store = true },
    [209] = { keylabKey = "map209", name = "The Arcway", store = true },
    [401] = { keylabKey = "map401", name = "The Azure Vault", store = true },
    [505] = { keylabKey = "map505", name = "The Dawnbreaker", store = true },
    [168] = { keylabKey = "map168", name = "The Everbloom", store = true },
    [247] = { keylabKey = "map247", name = "The MOTHERLODE!!", store = true },
    [376] = { keylabKey = "map376", name = "The Necrotic Wake", store = true },
    [400] = { keylabKey = "map400", name = "The Nokhud Offensive", store = true },
    [500] = { keylabKey = "map500", name = "The Rookery", store = true },
    [541] = { keylabKey = "map541", name = "The Stonecore", store = true },
    [501] = { keylabKey = "map501", name = "The Stonevault", store = true },
    [251] = { keylabKey = "map251", name = "The Underrot", store = true },
    [438] = { keylabKey = "map438", name = "The Vortex Pinnacle", store = true },
    [382] = { keylabKey = "map382", name = "Theater of Pain", store = true },
    [456] = { keylabKey = "map456", name = "Throne of the Tides", store = true },
    [246] = { keylabKey = "map246", name = "Tol Dagor", store = true },
    [403] = { keylabKey = "map403", name = "Uldaman: Legacy of Tyr", store = true },
    [167] = { keylabKey = "map167", name = "Upper Blackrock Spire", store = true },
    [207] = { keylabKey = "map207", name = "Vault of the Wardens", store = true },
    [248] = { keylabKey = "map248", name = "Waycrest Manor", store = true },
    [557] = { keylabKey = "map557", name = "Windrunner Spire", store = true },
}

KeyLab.Mapping.MythicPlusTimerSeconds = {
    [558] = 34 * 60, -- Magisters' Terrace
    [560] = 33 * 60, -- Maisara Caverns
    [559] = 30 * 60, -- Nexus-Point Xenas
    [557] = 33 * 60, -- Windrunner Spire
    [402] = 31 * 60, -- Algeth'ar Academy
    [556] = 30 * 60, -- Pit of Saron
    [239] = 34 * 60, -- Seat of the Triumvirate
    [583] = 34 * 60, -- Seat of the Triumvirate
    [161] = 28 * 60, -- Skyreach
}

KeyLab.Mapping.MythicPlusChestRules = {
    twoChestRemainingRatio = 0.20,
    threeChestRemainingRatio = 0.40,
}

function KeyLab.Mapping.IsAllowedChallengeMap(mapID)
    return mapID and KeyLab.Mapping.Maps[mapID] and KeyLab.Mapping.Maps[mapID].store == true
end

function KeyLab.Mapping.GetMapName(mapID)
    local entry = mapID and KeyLab.Mapping.Maps[mapID]
    return entry and entry.name or nil
end

function KeyLab.Mapping.GetMapTimerSeconds(mapID)
    mapID = tonumber(mapID)
    return mapID and KeyLab.Mapping.MythicPlusTimerSeconds[mapID] or nil
end

function KeyLab.Mapping.GetTimerUpgradeLevels(durationSeconds, timeLimitSeconds, timed)
    if timed ~= true then return nil end

    local duration = tonumber(durationSeconds)
    local limit = tonumber(timeLimitSeconds)
    if not duration or not limit or limit <= 0 then return nil end

    local remainingRatio = (limit - duration) / limit
    if remainingRatio < 0 then return nil end

    local rules = KeyLab.Mapping.MythicPlusChestRules or {}
    if remainingRatio >= (tonumber(rules.threeChestRemainingRatio) or 0.40) then
        return 3
    end
    if remainingRatio >= (tonumber(rules.twoChestRemainingRatio) or 0.20) then
        return 2
    end
    return 1
end
