local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.DB = KeyLab.DB or {}
KeyLab.DB.Builds = KeyLab.DB.Builds or {}

local BuildsDB = KeyLab.DB.Builds

--[[
KeyLab_BuildDB.lua

Purpose:
- Groups encounters by exact talent string.
- Compares builds only within the same dungeon + key level context.
- Uses metric mapping to decide whether higher or lower is better.
- Does NOT capture Blizzard data.
- Does NOT create UI.
]]

local function GetEncounters()
    if KeyLab.DB and KeyLab.DB.Encounters and KeyLab.DB.Encounters.GetFiltered then
        return KeyLab.DB.Encounters.GetFiltered({
            includeInterrupted = false,
            includeExcluded = false,
        })
    end

    return {}
end

local function GetMetricInfo(metricKey)
    local metrics = KeyLab.Mapping and KeyLab.Mapping.Metrics
    if type(metrics) ~= "table" then return nil end

    for _, info in pairs(metrics) do
        if info.keylabKey == metricKey and info.store == true then
            return info
        end
    end

    return nil
end

local function GetTalentString(encounter)
    return encounter
        and encounter.talents
        and encounter.talents.talentString
end

local function SameContext(encounter, filters)
    if type(filters) ~= "table" then return true end

    local challenge = encounter and encounter.challenge
    if type(challenge) ~= "table" then return false end

    if filters.mapID and challenge.mapID ~= filters.mapID then
        return false
    end

    if filters.keyLevel and challenge.keyLevel ~= filters.keyLevel then
        return false
    end

    return true
end

local function BetterValue(current, candidate, higherIsBetter)
    if type(candidate) ~= "number" then
        return current
    end

    if type(current) ~= "number" then
        return candidate
    end

    if higherIsBetter == false then
        return math.min(current, candidate)
    end

    return math.max(current, candidate)
end

function BuildsDB.GetBuildGroups(filters)
    local groups = {}
    local encounters = GetEncounters()

    for _, encounter in ipairs(encounters) do
        if SameContext(encounter, filters) then
            local talentString = GetTalentString(encounter)

            if talentString and talentString ~= "" then
                local group = groups[talentString]

                if not group then
                    group = {
                        talentString = talentString,
                        runCount = 0,
                        encounters = {},
                        mapIDs = {},
                        keyLevels = {},
                        metrics = {},
                        stats = {},
                    }

                    groups[talentString] = group
                end

                group.runCount = group.runCount + 1
                table.insert(group.encounters, encounter)

                if encounter.challenge then
                    if encounter.challenge.mapID then
                        group.mapIDs[encounter.challenge.mapID] = true
                    end

                    if encounter.challenge.keyLevel then
                        group.keyLevels[encounter.challenge.keyLevel] = true
                    end
                end
            end
        end
    end

    return groups
end

function BuildsDB.GetBuildCards(filters, metricKey)
    metricKey = metricKey or "damageDone"

    local metricInfo = GetMetricInfo(metricKey)
    local higherIsBetter = true

    if metricInfo and metricInfo.higherIsBetter == false then
        higherIsBetter = false
    end

    local groups = BuildsDB.GetBuildGroups(filters)
    local cards = {}

    for talentString, group in pairs(groups) do
        local bestValue = nil
        local bestEncounter = nil

        for _, encounter in ipairs(group.encounters) do
            local value = encounter.metrics and encounter.metrics[metricKey]

            local newBest = BetterValue(bestValue, value, higherIsBetter)
            if newBest ~= bestValue then
                bestValue = newBest
                bestEncounter = encounter
            end
        end

        table.insert(cards, {
            talentString = talentString,
            runCount = group.runCount,
            bestValue = bestValue,
            bestEncounter = bestEncounter,
            metricKey = metricKey,
            higherIsBetter = higherIsBetter,
            group = group,
        })
    end

    table.sort(cards, function(a, b)
        local av = a.bestValue
        local bv = b.bestValue

        if type(av) ~= "number" and type(bv) ~= "number" then
            return (a.runCount or 0) > (b.runCount or 0)
        elseif type(av) ~= "number" then
            return false
        elseif type(bv) ~= "number" then
            return true
        end

        if higherIsBetter == false then
            return av < bv
        end

        return av > bv
    end)

    return cards
end

function BuildsDB.GetPage(filters, metricKey, page, pageSize)
    page = page or 1
    pageSize = pageSize or 5

    if page < 1 then page = 1 end

    local cards = BuildsDB.GetBuildCards(filters, metricKey)
    local total = #cards
    local totalPages = math.max(1, math.ceil(total / pageSize))

    if page > totalPages then
        page = totalPages
    end

    local startIndex = ((page - 1) * pageSize) + 1
    local endIndex = math.min(startIndex + pageSize - 1, total)

    local pageCards = {}

    for i = startIndex, endIndex do
        if cards[i] then
            table.insert(pageCards, cards[i])
        end
    end

    return pageCards, {
        page = page,
        pageSize = pageSize,
        total = total,
        totalPages = totalPages,
        hasPrevious = page > 1,
        hasNext = page < totalPages,
    }
end