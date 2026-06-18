local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.ItemAnalysis = KeyLab.ItemAnalysis or {}
local Analysis = KeyLab.ItemAnalysis

local PRIMARY_STATS = {
    Int = true,
    Agi = true,
    Str = true,
    Stam = true,
}

local SECONDARY_STATS = {
    Crit = true,
    Haste = true,
    Mastery = true,
    Vers = true,
}

local SECONDARY_BY_GOAL_KEY = {
    crit = "Crit",
    haste = "Haste",
    mastery = "Mastery",
    versatility = "Vers",
}

local STAT_LABELS = {
    crit = "Crit",
    haste = "Haste",
    mastery = "Mastery",
    versatility = "Versatility",
}

local STAT_TEXT_KEYS = {
    crit = { "crit", "critical strike" },
    haste = { "haste" },
    mastery = { "mastery" },
    versatility = { "versatility", "vers" },
}

local PRIMARY_BY_CLASS_ID = {
    [1] = "Str",  -- Warrior
    [3] = "Agi",  -- Hunter
    [4] = "Agi",  -- Rogue
    [5] = "Int",  -- Priest
    [6] = "Str",  -- Death Knight
    [8] = "Int",  -- Mage
    [9] = "Int",  -- Warlock
    [12] = "Agi", -- Demon Hunter
    [13] = "Int", -- Evoker
}

local PRIMARY_BY_SPEC_ID = {
    [62] = "Int", [63] = "Int", [64] = "Int",
    [65] = "Int", [66] = "Str", [70] = "Str",
    [71] = "Str", [72] = "Str", [73] = "Str",
    [102] = "Int", [103] = "Agi", [104] = "Agi", [105] = "Int",
    [250] = "Str", [251] = "Str", [252] = "Str",
    [253] = "Agi", [254] = "Agi", [255] = "Agi",
    [256] = "Int", [257] = "Int", [258] = "Int",
    [259] = "Agi", [260] = "Agi", [261] = "Agi",
    [262] = "Int", [263] = "Agi", [264] = "Int",
    [265] = "Int", [266] = "Int", [267] = "Int",
    [268] = "Agi", [269] = "Agi", [270] = "Int",
    [577] = "Agi", [581] = "Agi",
    [1467] = "Int", [1468] = "Int", [1473] = "Int", [1480] = "Agi",
}

local DISPLAY_STAT_ORDER = { "Stam", "Crit", "Haste", "Mastery", "Vers" }

local TRINKET_EFFECT_TAGS = {
    { tag = "Crit", words = { "critical strike", "crit" } },
    { tag = "Haste", words = { "haste" } },
    { tag = "Mastery", words = { "mastery" } },
    { tag = "Vers", words = { "versatility", "vers" } },
    { tag = "Agi", words = { "agility" } },
    { tag = "Str", words = { "strength" } },
    { tag = "Int", words = { "intellect" } },
    { tag = "Stam", words = { "stamina" } },
    { tag = "Damage", words = { "damage" } },
    { tag = "Healing", words = { "healing", "heal" } },
    { tag = "Absorb", words = { "absorb", "shield" } },
    { tag = "Defensive", words = { "defensive" } },
}

local TRINKET_PRIMARY_TAG_WORDS = {
    Agi = { "agility" },
    Str = { "strength" },
    Int = { "intellect" },
}

local TRINKET_GENERIC_EFFECT_WORDS = {
    "damage",
    "healing",
    "heal",
    "absorb",
    "shield",
    "defensive",
}

local TRINKET_USEFUL_WORDS = {
    "crit",
    "critical strike",
    "haste",
    "mastery",
    "versatility",
    "damage",
    "healing",
    "heal",
    "absorb",
    "shield",
    "intellect",
    "agility",
    "strength",
    "stamina",
    "primary stat",
    "defensive",
}

local MIXED_PRIMARY_CLASSES = {
    [2] = true,  -- Paladin
    [7] = true,  -- Shaman
    [10] = true, -- Monk
    [11] = true, -- Druid
}

local CLASS_NAME_TO_ID = {
    warrior = 1,
    paladin = 2,
    hunter = 3,
    rogue = 4,
    priest = 5,
    deathknight = 6,
    death_knight = 6,
    ["death knight"] = 6,
    shaman = 7,
    mage = 8,
    warlock = 9,
    monk = 10,
    druid = 11,
    demonhunter = 12,
    demon_hunter = 12,
    ["demon hunter"] = 12,
    evoker = 13,
}

local function getDB()
    return KeyLab and KeyLab.GearLootDatabase or nil
end

local function cleanText(text)
    if type(text) ~= "string" then return "" end
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    text = text:gsub("|H.-|h(.-)|h", "%1")
    return string.lower(text)
end

local function addUnique(list, value)
    if not value or value == "" then return end
    for _, existing in ipairs(list or {}) do
        if existing == value then return end
    end
    table.insert(list, value)
end

local function containsAny(text, words)
    if type(text) ~= "string" or text == "" then return false end
    for _, word in ipairs(words or {}) do
        if string.find(text, word, 1, true) then return true end
    end
    return false
end

local function normalizeClassID(playerClass)
    if type(playerClass) == "number" then return playerClass end
    if type(playerClass) == "string" then
        local text = cleanText(playerClass):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
        return CLASS_NAME_TO_ID[text] or CLASS_NAME_TO_ID[text:gsub("%s+", "")]
    end
    return nil
end

local function itemHasRawStat(item, stat)
    if not item or not stat then return false end
    if item.stats and item.stats[stat] ~= nil then return true end
    if item.statSet and item.statSet[stat] then return true end
    return false
end

local function isTrinket(item)
    return item and (item.slot == "Trinket" or item.equipLoc == "INVTYPE_TRINKET")
end

local function getSpecInfo(specID)
    local db = getDB()
    specID = tonumber(specID)
    return db and db.specs and specID and db.specs[specID] or nil
end

local function getPrimaryFromSpecName(playerClass, playerSpecName)
    local classID = normalizeClassID(playerClass)
    local specName = cleanText(playerSpecName or "")
    if specName == "" then return nil end

    if classID == 2 then
        if specName == "holy" then return "Int" end
        if specName == "protection" or specName == "retribution" then return "Str" end
    elseif classID == 7 then
        if specName == "enhancement" then return "Agi" end
        if specName == "elemental" or specName == "restoration" then return "Int" end
    elseif classID == 10 then
        if specName == "mistweaver" then return "Int" end
        if specName == "brewmaster" or specName == "windwalker" then return "Agi" end
    elseif classID == 11 then
        if specName == "balance" or specName == "restoration" then return "Int" end
        if specName == "feral" or specName == "guardian" then return "Agi" end
    end

    return nil
end

local function getPrimaryForPlayer(playerClass, playerSpecID, playerSpecName)
    playerSpecID = tonumber(playerSpecID)
    if playerSpecID and PRIMARY_BY_SPEC_ID[playerSpecID] then
        return PRIMARY_BY_SPEC_ID[playerSpecID]
    end

    local primary = getPrimaryFromSpecName(playerClass, playerSpecName)
    if primary then return primary end

    local classID = normalizeClassID(playerClass)
    if classID and not MIXED_PRIMARY_CLASSES[classID] then
        return PRIMARY_BY_CLASS_ID[classID]
    end

    local spec = getSpecInfo(playerSpecID)
    if spec and spec.classID and not MIXED_PRIMARY_CLASSES[spec.classID] then
        return PRIMARY_BY_CLASS_ID[spec.classID]
    end

    return nil
end

local tooltipTextLookupBusy = false

local function getTooltipText(item)
    if KeyLab and KeyLab.GearCapture and KeyLab.GearCapture.GetItemTooltipText then
        if tooltipTextLookupBusy then
            return ""
        end

        tooltipTextLookupBusy = true
        local ok, text = pcall(KeyLab.GearCapture.GetItemTooltipText, item)
        tooltipTextLookupBusy = false

        if ok then
            return text or ""
        end
    end

    return ""
end

local function getItemTextBlob(item)
    if not item then return "" end
    return cleanText(table.concat({
        tostring(item.name or ""),
        tostring(item.statText or ""),
        tostring(item.displayStatText or ""),
        tostring(item.description or ""),
        tostring(item.tooltip or ""),
        tostring(item.tooltipText or ""),
        tostring(item.effect or ""),
        tostring(item.equipText or ""),
        tostring(item.useText or ""),
        tostring(getTooltipText(item) or ""),
    }, " "))
end

local function getKnownTrinketTags(item)
    if not isTrinket(item) then return {} end
    local db = KeyLab and KeyLab.TrinketEffectsDB
    if not db or not db.GetTags then return {} end
    return db.GetTags(item and item.itemID)
end

local function getSpecStatText(item, playerSpecID)
    local db = getDB()
    local itemID = item and tonumber(item.itemID)
    playerSpecID = tonumber(playerSpecID)
    if not db or not itemID or not playerSpecID then return nil end
    return db.statTextBySpec and db.statTextBySpec[itemID] and db.statTextBySpec[itemID][playerSpecID] or nil
end

local function statTextToList(text)
    local list = {}
    if type(text) ~= "string" or text == "" then return list end
    for part in string.gmatch(text, "([^,]+)") do
        part = tostring(part or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if part == "Versatility" then part = "Vers" end
        addUnique(list, part)
    end
    return list
end

local function statTextHasStat(text, stat)
    if not stat then return false end
    for _, value in ipairs(statTextToList(text)) do
        if value == stat then return true end
    end
    return false
end

local function addSecondaryTags(found, tags)
    for _, tag in ipairs(tags or {}) do
        if SECONDARY_STATS[tag] then
            addUnique(found, tag)
        end
    end
end

local function getPrimaryFromStatText(text)
    local found
    for _, stat in ipairs({ "Int", "Agi", "Str" }) do
        if statTextHasStat(text, stat) then
            if found then return nil end
            found = stat
        end
    end
    return found
end

local function normalizePrimaryInStatList(parts, resolvedPrimary)
    if not resolvedPrimary then return parts or {} end
    local out = {}
    local insertedPrimary = false

    for _, stat in ipairs(parts or {}) do
        if stat == "Int" or stat == "Agi" or stat == "Str" then
            if not insertedPrimary then
                addUnique(out, resolvedPrimary)
                insertedPrimary = true
            end
        else
            addUnique(out, stat)
        end
    end

    return out
end

local function makeSet(list)
    local set = {}
    for _, value in ipairs(list or {}) do
        set[value] = true
    end
    return set
end

local function getContext(statGoals, currentStats)
    local context = statGoals or {}
    if context.currentStats or context.below or context.above or context.configured ~= nil then
        return context
    end

    local goals = statGoals or {}
    local priority = goals.priority or { "mastery", "haste", "crit", "versatility" }
    local targets = goals.targets or goals
    local stats = currentStats or {}
    local below, above, configured = {}, {}, false

    for _, statKey in ipairs(priority or {}) do
        local target = tonumber(targets and targets[statKey]) or 0
        local current = tonumber(stats and stats[statKey]) or 0
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
        currentStats = stats,
        below = below,
        above = above,
        configured = configured,
    }
end

local function statLabel(statKey)
    return STAT_LABELS[statKey] or tostring(statKey or "")
end

local function hasPrimaryStat(item)
    for stat in pairs(PRIMARY_STATS) do
        if stat ~= "Stam" and itemHasRawStat(item, stat) then return true end
    end
    return false
end

local function getPrimaryWords(primary)
    local words = {}
    if primary == "Int" then
        words = { "int", "intellect" }
    elseif primary == "Agi" then
        words = { "agi", "agility" }
    elseif primary == "Str" then
        words = { "str", "strength" }
    end
    return words
end

local function collectMentionedStats(item, context, bucket)
    local text = getItemTextBlob(item)
    local found = {}
    for _, statKey in ipairs((context and context.priority) or {}) do
        if context[bucket] and context[bucket][statKey] and containsAny(text, STAT_TEXT_KEYS[statKey]) then
            table.insert(found, statLabel(statKey))
        end
    end
    return found, text
end

local function getTrinketGuidance(item, context, result)
    result = result or {}

    if (result.helpCount or 0) >= 2 or (result.score or 0) >= 8 then
        return {
            label = "Best Target",
            color = "green",
            reason = "Trinket helps " .. table.concat(result.helpful or {}, " and "),
            score = result.score or 0,
        }
    end

    if (result.helpCount or 0) >= 1 and (result.score or 0) >= 3 then
        return {
            label = "Good Backup",
            color = "blue",
            reason = "Trinket is useful for " .. table.concat(result.helpful or {}, " and "),
            score = result.score or 0,
        }
    end

    local helpfulMentions, text = collectMentionedStats(item, context, "below")
    local riskyMentions = collectMentionedStats(item, context, "above")
    local effectTags = makeSet(Analysis.ExtractTrinketTags and Analysis.ExtractTrinketTags(item) or {})
    local hasGenericEffect = containsAny(text, TRINKET_GENERIC_EFFECT_WORDS)
        or effectTags.Damage
        or effectTags.Healing
        or effectTags.Absorb
        or effectTags.Defensive

    if #helpfulMentions >= 2 then
        return {
            label = "Best Target",
            color = "green",
            reason = "Trinket effect mentions goal stats: " .. table.concat(helpfulMentions, " and "),
            score = 8,
        }
    end

    if #helpfulMentions >= 1 then
        return {
            label = "Good Backup",
            color = "blue",
            reason = "Trinket effect mentions " .. table.concat(helpfulMentions, " and "),
            score = 4,
        }
    end

    if #riskyMentions > 0 and not hasGenericEffect then
        return {
            label = "Avoid for Goal",
            color = "warning",
            reason = "Trinket appears to boost over-goal stats: " .. table.concat(riskyMentions, " and "),
            score = -1,
        }
    end

    if hasGenericEffect then
        return {
            label = "Good Backup",
            color = "blue",
            reason = "Trinket has a useful stat or combat effect. Review the tooltip for your build.",
            score = 2,
        }
    end

    if containsAny(text, TRINKET_USEFUL_WORDS) then
        return {
            label = "Temporary Option",
            color = "muted",
            reason = "Trinket has a potentially useful effect. Review the tooltip for your build.",
            score = 1,
        }
    end

    if hasPrimaryStat(item) or (result.neutralCount or 0) > 0 then
        return {
            label = "Temporary Option",
            color = "muted",
            reason = "Trinket has useful baseline stats, but its effect needs player review.",
            score = result.score or 0,
        }
    end

    if (result.riskCount or 0) > 0 then
        return {
            label = "Review Trinket",
            color = "warning",
            reason = "Trinket mostly shows over-goal stats, but its effect may still matter.",
            score = result.score or 0,
        }
    end

    return {
        label = "Review Trinket",
        color = "muted",
        reason = "KeyLab cannot confidently evaluate this trinket from saved stats alone.",
        score = 0,
    }
end

function Analysis.IsItemEligibleForSpec(item, selectedSpecID, selectedSpecName)
    if not item then return false end
    selectedSpecID = tonumber(selectedSpecID)
    if not selectedSpecID or selectedSpecID == 0 then return true end

    if type(item.specs) == "table" then
        return item.specs[selectedSpecID] == true
    end

    local specName = cleanText(selectedSpecName or "")
    if specName ~= "" and type(item.specNames) == "table" then
        for _, itemSpecName in ipairs(item.specNames) do
            if cleanText(itemSpecName) == specName then return true end
        end
    end

    return true
end

function Analysis.IsItemEligibleForClass(item, playerClass)
    if not item then return false end
    local classID = normalizeClassID(playerClass)
    if not classID or classID == 0 then return true end
    if type(item.specs) ~= "table" then return true end

    local db = getDB()
    for specID in pairs(item.specs or {}) do
        local spec = db and db.specs and db.specs[specID]
        if spec and spec.classID == classID then return true end
    end

    return false
end

function Analysis.ChooseDisplaySpecID(item, preferredSpecID, playerClass)
    preferredSpecID = tonumber(preferredSpecID)
    if preferredSpecID and Analysis.IsItemEligibleForSpec(item, preferredSpecID) then
        return preferredSpecID
    end

    local classID = normalizeClassID(playerClass)
    if classID and type(item and item.specs) == "table" then
        local db = getDB()
        for specID in pairs(item.specs) do
            local spec = db and db.specs and db.specs[specID]
            if spec and spec.classID == classID then
                return specID
            end
        end
    end

    return preferredSpecID
end

function Analysis.ResolvePrimaryStat(item, playerClass, playerSpecID, playerSpecName)
    if not item then return nil end
    local primary = getPrimaryForPlayer(playerClass, playerSpecID, playerSpecName)
    local capturedStatText = getSpecStatText(item, playerSpecID)
    local capturedPrimary = getPrimaryFromStatText(capturedStatText)

    -- Adaptive primary-stat items can carry several raw primaries in static data.
    -- Resolve the primary through the player's class/spec so BM Hunter sees Agi,
    -- Ret Paladin sees Str, and caster specs see Int even if a captured link was adaptive.
    if primary and (capturedPrimary or itemHasRawStat(item, primary)) then
        return primary
    end

    if capturedPrimary then return capturedPrimary end

    if primary and itemHasRawStat(item, primary) then
        return primary
    end

    local text = getItemTextBlob(item)
    if primary and containsAny(text, getPrimaryWords(primary)) then
        return primary
    end

    local found
    for _, stat in ipairs({ "Int", "Agi", "Str" }) do
        if itemHasRawStat(item, stat) then
            if found then return nil end
            found = stat
        end
    end

    return found
end

function Analysis.GetSecondaryStats(item, playerSpecID)
    local found = {}
    local capturedStatText = getSpecStatText(item, playerSpecID)
    local displayStatText = item and item.displayStatText
    local exactStatText = capturedStatText or displayStatText

    for _, stat in ipairs(statTextToList(exactStatText)) do
        if SECONDARY_STATS[stat] then
            addUnique(found, stat)
        end
    end

    if exactStatText and exactStatText ~= "" then
        -- Trinkets can display secondary tags from tooltip text even when the
        -- captured stat line only has primary/stamina data.
        if isTrinket(item) and Analysis.ExtractTrinketTags then
            addSecondaryTags(found, Analysis.ExtractTrinketTags(item))
        end
        return found
    end

    local text = getItemTextBlob(item)
    for _, stat in ipairs({ "Crit", "Haste", "Mastery", "Vers" }) do
        if itemHasRawStat(item, stat) then
            addUnique(found, stat)
        end
    end

    if containsAny(text, STAT_TEXT_KEYS.crit) then addUnique(found, "Crit") end
    if containsAny(text, STAT_TEXT_KEYS.haste) then addUnique(found, "Haste") end
    if containsAny(text, STAT_TEXT_KEYS.mastery) then addUnique(found, "Mastery") end
    if containsAny(text, STAT_TEXT_KEYS.versatility) then addUnique(found, "Vers") end
    if isTrinket(item) and Analysis.ExtractTrinketTags then
        addSecondaryTags(found, Analysis.ExtractTrinketTags(item))
    end

    return found
end

function Analysis.MatchesSecondaryStatFilter(item, selectedSecondaryStats, playerClass, playerSpecID, playerSpecName)
    local itemStats

    for stat, enabled in pairs(selectedSecondaryStats or {}) do
        if enabled and SECONDARY_STATS[stat] then
            itemStats = itemStats or makeSet(Analysis.GetSecondaryStats(item, playerSpecID))
            if not itemStats[stat] then return false end
        end
    end

    return true
end

function Analysis.MatchesPrimaryStatFilter(item, primaryStat, playerClass, playerSpecID, playerSpecName)
    if not primaryStat or primaryStat == "" or primaryStat == "All" then return true end
    if not PRIMARY_STATS[primaryStat] then return true end
    if primaryStat == "Stam" then return itemHasRawStat(item, "Stam") end

    local resolvedPrimary = Analysis.ResolvePrimaryStat(item, playerClass, playerSpecID, playerSpecName)
    if resolvedPrimary then return resolvedPrimary == primaryStat end
    return itemHasRawStat(item, primaryStat)
end

function Analysis.ExtractTrinketTags(item, playerClass, playerSpecID, playerSpecName)
    if not isTrinket(item) then return {} end

    -- Trinket value is often stored in tooltip/equip/use text instead of item.stats.
    -- Keep this keyword pass simple and transparent; it only creates display tags.
    -- Adaptive primary effects are resolved through the selected spec so a trinket
    -- that can grant Strength/Agility/Intellect only displays the relevant one.
    local text = getItemTextBlob(item)
    local tags = {}

    for _, data in ipairs(TRINKET_EFFECT_TAGS) do
        if not TRINKET_PRIMARY_TAG_WORDS[data.tag] and containsAny(text, data.words) then
            addUnique(tags, data.tag)
        end
    end

    local mentionedPrimaries = {}
    for primary, words in pairs(TRINKET_PRIMARY_TAG_WORDS) do
        if containsAny(text, words) then
            table.insert(mentionedPrimaries, primary)
        end
    end

    local hasAdaptivePrimaryText = #mentionedPrimaries > 0 or containsAny(text, { "primary stat" })
    if hasAdaptivePrimaryText then
        local resolvedPrimary = Analysis.ResolvePrimaryStat(item, playerClass, playerSpecID, playerSpecName)
        if not resolvedPrimary then
            resolvedPrimary = getPrimaryForPlayer(playerClass, playerSpecID, playerSpecName)
        end

        if resolvedPrimary then
            addUnique(tags, resolvedPrimary)
        elseif #mentionedPrimaries == 1 then
            addUnique(tags, mentionedPrimaries[1])
        end
    end

    for _, tag in ipairs(getKnownTrinketTags(item)) do
        -- Known effect tags should never reintroduce the wrong adaptive primary.
        -- Primary stat display is handled by ResolvePrimaryStat above.
        if not TRINKET_PRIMARY_TAG_WORDS[tag] then
            addUnique(tags, tag)
        end
    end

    return tags
end

function Analysis.GetDisplayStats(item, playerClass, playerSpecID, playerSpecName)
    if not item then return "-" end
    local capturedStatText = getSpecStatText(item, playerSpecID)
    if capturedStatText and capturedStatText ~= "" then
        local parts = normalizePrimaryInStatList(statTextToList(capturedStatText), Analysis.ResolvePrimaryStat(item, playerClass, playerSpecID, playerSpecName))
        if isTrinket(item) then
            for _, tag in ipairs(Analysis.ExtractTrinketTags(item, playerClass, playerSpecID, playerSpecName)) do
                addUnique(parts, tag)
            end
        end
        return table.concat(parts, ", ")
    end

    local parts = {}
    local resolvedPrimary = Analysis.ResolvePrimaryStat(item, playerClass, playerSpecID, playerSpecName)
    if resolvedPrimary then
        addUnique(parts, resolvedPrimary)
    else
        for _, stat in ipairs({ "Int", "Agi", "Str" }) do
            if itemHasRawStat(item, stat) then addUnique(parts, stat) end
        end
    end

    for _, stat in ipairs(DISPLAY_STAT_ORDER) do
        if stat == "Stam" then
            if itemHasRawStat(item, stat) then addUnique(parts, stat) end
        elseif SECONDARY_STATS[stat] then
            if itemHasRawStat(item, stat) then addUnique(parts, stat) end
        end
    end

    if isTrinket(item) then
        for _, tag in ipairs(Analysis.ExtractTrinketTags(item, playerClass, playerSpecID, playerSpecName)) do
            addUnique(parts, tag)
        end
    end

    if #parts > 0 then return table.concat(parts, ", ") end
    if item.statText and item.statText ~= "" then return item.statText end
    return item.className or "-"
end

function Analysis.GetItemGuidance(item, statGoals, currentStats, status)
    status = status and tostring(status):lower() or nil
    if status == "bis" then
        return {
            label = "BIS",
            color = "gold",
            reason = "Manually marked as BIS. This overrides stat-goal avoidance.",
            score = 99,
        }
    end

    local context = getContext(statGoals, currentStats)
    if not context.configured then
        return {
            label = "Temporary Option",
            color = "muted",
            reason = "Set stat targets for stronger guidance.",
            score = 0,
        }
    end

    if not item or type(item.stats) ~= "table" then
        if isTrinket(item) then
            return getTrinketGuidance(item, context, {})
        end

        return {
            label = "Avoid for Goal",
            color = "warning",
            reason = "No useful secondary stats for this goal.",
            score = -1,
        }
    end

    local itemSecondaries = makeSet(Analysis.GetSecondaryStats(item))
    local helpCount, riskCount, neutralCount, score = 0, 0, 0, 0
    local helpful, risky = {}, {}

    for rank, statKey in ipairs(context.priority or {}) do
        local itemStatKey = SECONDARY_BY_GOAL_KEY[statKey]
        local hasStat = itemStatKey and itemSecondaries[itemStatKey]
        local weight = math.max(1, 5 - rank)

        if hasStat then
            if context.below and context.below[statKey] then
                helpCount = helpCount + 1
                score = score + (weight * 2)
                table.insert(helpful, statLabel(statKey))
            elseif context.above and context.above[statKey] then
                riskCount = riskCount + 1
                score = score - weight
                table.insert(risky, statLabel(statKey))
            else
                neutralCount = neutralCount + 1
                score = score + weight
            end
        end
    end

    if isTrinket(item) then
        return getTrinketGuidance(item, context, {
            helpCount = helpCount,
            riskCount = riskCount,
            neutralCount = neutralCount,
            score = score,
            helpful = helpful,
            risky = risky,
        })
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

function Analysis.EnrichItemForDisplay(item, playerClass, playerSpecID, playerSpecName)
    if not item then return nil end
    local out = {}
    for key, value in pairs(item) do
        out[key] = value
    end
    out.resolvedPrimaryStat = Analysis.ResolvePrimaryStat(item, playerClass, playerSpecID, playerSpecName)
    out.trinketEffectTags = Analysis.ExtractTrinketTags(item, playerClass, playerSpecID, playerSpecName)
    out.displayStatText = Analysis.GetDisplayStats(item, playerClass, playerSpecID, playerSpecName)
    return out
end

return Analysis
