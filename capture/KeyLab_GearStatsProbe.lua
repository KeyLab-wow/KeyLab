-- KeyLab_GearStatsProbe.lua
--
-- Temporary/manual probe for discovering exactly what WoW exposes for the
-- Gear Dashboard. Capture only: no recommendations, scoring, or UI layout.

local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.GearStatsProbe = KeyLab.GearStatsProbe or {}
local Probe = KeyLab.GearStatsProbe

local MAX_SAVED_CAPTURES = 10

local PRIMARY_STATS = {
    { key = "strength", label = "Strength" },
    { key = "agility", label = "Agility" },
    { key = "intellect", label = "Intellect" },
}

local SECONDARY_STATS = {
    { key = "crit", label = "Critical Strike", aliases = { "critical strike", "crit" } },
    { key = "haste", label = "Haste", aliases = { "haste" } },
    { key = "mastery", label = "Mastery", aliases = { "mastery" } },
    { key = "versatility", label = "Versatility", aliases = { "versatility", "vers" } },
}

local TOOLTIP_TRACKS = { "Myth", "Hero", "Champion", "Veteran", "Adventurer" }

local DEFAULT_SLOTS = {
    { name = "Head", slotID = 1 },
    { name = "Neck", slotID = 2 },
    { name = "Shoulders", slotID = 3 },
    { name = "Back", slotID = 15 },
    { name = "Chest", slotID = 5 },
    { name = "Wrist", slotID = 9 },
    { name = "Hands", slotID = 10 },
    { name = "Waist", slotID = 6 },
    { name = "Legs", slotID = 7 },
    { name = "Feet", slotID = 8 },
    { name = "Finger 1", slotID = 11 },
    { name = "Finger 2", slotID = 12 },
    { name = "Trinket 1", slotID = 13 },
    { name = "Trinket 2", slotID = 14 },
    { name = "Main Hand", slotID = 16 },
    { name = "Off Hand", slotID = 17 },
}

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d = pcall(fn, ...)
    if ok then return a, b, c, d end
    return nil
end

local function SafeNumber(value)
    value = tonumber(value)
    if type(value) ~= "number" then return nil end
    if value ~= value then return nil end
    if not (value < math.huge and value > -math.huge) then return nil end
    return value
end

local function CleanLine(text)
    text = tostring(text or "")
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    text = text:gsub("|H.-|h(.-)|h", "%1")
    return text
end

local function CountSocketedGems(itemLink)
    local text = tostring(itemLink or "")
    local _, gem1, gem2, gem3, gem4 = text:match("item:%d+:(%d*):(%d*):(%d*):(%d*):(%d*)")
    local count = 0

    for _, gemID in ipairs({ gem1, gem2, gem3, gem4 }) do
        if tonumber(gemID) and tonumber(gemID) > 0 then
            count = count + 1
        end
    end

    return count
end

local function CopySlotDefs()
    local source = KeyLab.GearingDatabase and KeyLab.GearingDatabase.InventorySlots or DEFAULT_SLOTS
    local out = {}
    for _, slot in ipairs(source or {}) do
        table.insert(out, {
            name = slot.name,
            slotID = slot.slotID,
        })
    end
    return out
end

local function GetItemIDFromLink(link)
    return tonumber(tostring(link or ""):match("item:(%d+)"))
end

local function GetItemLevel(link)
    if not link then return nil end
    local itemLevel = SafeCall(C_Item and C_Item.GetDetailedItemLevelInfo, link)
    if itemLevel then return SafeNumber(itemLevel) end
    itemLevel = SafeCall(GetDetailedItemLevelInfo, link)
    return SafeNumber(itemLevel)
end

local function TooltipLineToRecord(line)
    if type(line) ~= "table" then return nil end
    local record = {
        leftText = line.leftText and CleanLine(line.leftText) or nil,
        rightText = line.rightText and CleanLine(line.rightText) or nil,
        type = line.type,
    }

    if type(line.args) == "table" then
        record.args = {}
        for _, arg in ipairs(line.args) do
            if type(arg) == "table" and arg.stringVal and arg.stringVal ~= "" then
                table.insert(record.args, CleanLine(arg.stringVal))
            end
        end
        if #record.args == 0 then record.args = nil end
    end

    return record
end

local function ReadInventoryTooltip(slotID, link)
    local rawLines = {}
    local structuredLines = {}

    local ok, tooltip
    if C_TooltipInfo and C_TooltipInfo.GetInventoryItem and slotID then
        ok, tooltip = pcall(C_TooltipInfo.GetInventoryItem, "player", slotID)
    end
    if (not ok or not tooltip or type(tooltip.lines) ~= "table" or #tooltip.lines == 0) and C_TooltipInfo and C_TooltipInfo.GetHyperlink and link then
        ok, tooltip = pcall(C_TooltipInfo.GetHyperlink, link)
    end

    if ok and tooltip and type(tooltip.lines) == "table" then
        for _, line in ipairs(tooltip.lines or {}) do
            local record = TooltipLineToRecord(line)
            if record then
                table.insert(structuredLines, record)
                if record.leftText and record.leftText ~= "" then table.insert(rawLines, record.leftText) end
                if record.rightText and record.rightText ~= "" then table.insert(rawLines, record.rightText) end
                for _, argText in ipairs(record.args or {}) do
                    table.insert(rawLines, argText)
                end
            end
        end
    end

    return rawLines, structuredLines
end

local function ParseUpgradeTrack(lines)
    for _, line in ipairs(lines or {}) do
        local text = CleanLine(line)
        for _, trackName in ipairs(TOOLTIP_TRACKS) do
            local rank, maxRank = text:match(trackName .. "%s+(%d+)/(%d+)")
            if rank and maxRank then
                return {
                    track = trackName,
                    rank = tonumber(rank),
                    maxRank = tonumber(maxRank),
                    rawLine = text,
                }
            end
        end
    end
    return {
        track = nil,
        rank = nil,
        maxRank = nil,
        rawLine = nil,
    }
end

local function ExtractStatLines(lines, statDefs)
    local found = {}
    for _, line in ipairs(lines or {}) do
        local clean = CleanLine(line)
        local lower = string.lower(clean)
        for _, stat in ipairs(statDefs or {}) do
            for _, alias in ipairs(stat.aliases or { stat.label }) do
                if string.find(lower, string.lower(alias), 1, true) then
                    table.insert(found, {
                        key = stat.key,
                        label = stat.label,
                        value = SafeNumber((clean:gsub(",", ""):match("([%+%-]?%d+%.?%d*)%s+" .. stat.label)))
                            or SafeNumber((clean:gsub(",", ""):match("([%+%-]?%d+%.?%d*)"))),
                        rawLine = clean,
                    })
                    break
                end
            end
        end
    end
    return found
end

local function ExtractPrimaryStatLines(lines)
    local defs = {}
    for _, stat in ipairs(PRIMARY_STATS) do
        table.insert(defs, {
            key = stat.key,
            label = stat.label,
            aliases = { stat.label },
        })
    end
    table.insert(defs, {
        key = "stamina",
        label = "Stamina",
        aliases = { "Stamina" },
    })
    return ExtractStatLines(lines, defs)
end

local function AnalyzeTooltipLines(lines, itemLink)
    local enchantLines = {}
    local gemLines = {}
    local craftedLines = {}
    local tierLines = {}
    local explicitEmptySocketCount = 0
    local genericSocketCount = 0
    local socketedGemCount = CountSocketedGems(itemLink)

    for _, line in ipairs(lines or {}) do
        local clean = CleanLine(line)
        local lower = string.lower(clean)

        if lower:match("^enchanted:") and not lower:find("illusory", 1, true) then
            table.insert(enchantLines, clean)
        end

        local isSocketLine = lower:find("socket", 1, true) ~= nil
        local ignoreSocketLine = lower:find("socket bonus", 1, true)
            or lower:find("add a socket", 1, true)
            or lower:find("socketed", 1, true)
        local isExplicitEmptySocket = isSocketLine
            and not ignoreSocketLine
            and (
                lower:find("empty socket", 1, true)
                or lower:match("empty[%a%s%-]*socket") ~= nil
            )
        local socketLooksEmpty = isSocketLine
            and not ignoreSocketLine
            and lower:match("^%s*[%a%s%-]+socket%s*$") ~= nil

        if isExplicitEmptySocket then
            explicitEmptySocketCount = explicitEmptySocketCount + 1
            table.insert(gemLines, clean)
        elseif socketLooksEmpty then
            genericSocketCount = genericSocketCount + 1
            table.insert(gemLines, clean)
        elseif isSocketLine or lower:find("gem", 1, true) then
            table.insert(gemLines, clean)
        end

        if lower:find("crafted by", 1, true)
            or lower:find("spark", 1, true)
            or lower:find("embellished", 1, true)
            or lower:find("made by", 1, true)
            or lower:find("radiance crafted", 1, true)
            or lower:find("quality:", 1, true) then
            table.insert(craftedLines, clean)
        end

        if lower:find("set:", 1, true)
            or lower:find("class set", 1, true)
            or lower:find("2 set", 1, true)
            or lower:find("4 set", 1, true) then
            table.insert(tierLines, clean)
        end
    end

    return {
        enchantDetected = #enchantLines > 0,
        enchantLines = enchantLines,
        gemsDetected = #gemLines > 0,
        gemLines = gemLines,
        emptySocketCount = explicitEmptySocketCount + math.max(0, genericSocketCount - socketedGemCount),
        socketedGemCount = socketedGemCount,
        craftedIndicatorVisible = #craftedLines > 0,
        craftedLines = craftedLines,
        tierIndicatorVisible = #tierLines > 0,
        tierLines = tierLines,
        primaryStatsShown = ExtractPrimaryStatLines(lines),
        secondaryStatsShown = ExtractStatLines(lines, SECONDARY_STATS),
    }
end

local function GetClassAndSpec()
    local className, classFile, classID = SafeCall(UnitClass, "player")
    local specID, specName
    local specIndex = SafeCall(GetSpecialization)
    if specIndex and GetSpecializationInfo then
        specID, specName = GetSpecializationInfo(specIndex)
    end

    return {
        className = className,
        classFile = classFile,
        classID = classID,
        specID = specID,
        specName = specName,
    }
end

local function GetUnitStatValue(statIndex)
    local base, effective, posBuff, negBuff = SafeCall(UnitStat, "player", statIndex)
    return {
        base = SafeNumber(base),
        effective = SafeNumber(effective),
        positiveBuff = SafeNumber(posBuff),
        negativeBuff = SafeNumber(negBuff),
    }
end

local function PickPrimaryStat(rawPrimaryStats)
    local best
    for _, stat in ipairs(PRIMARY_STATS) do
        local value = rawPrimaryStats and rawPrimaryStats[stat.key] and rawPrimaryStats[stat.key].effective
        if value and (not best or value > best.value) then
            best = {
                key = stat.key,
                label = stat.label,
                value = value,
            }
        end
    end
    return best
end

local function GetCurrentStats()
    local rawPrimaryStats = {
        strength = GetUnitStatValue(1),
        agility = GetUnitStatValue(2),
        intellect = GetUnitStatValue(4),
    }

    local stats = {
        primaryStat = PickPrimaryStat(rawPrimaryStats),
        rawPrimaryStats = rawPrimaryStats,
        stamina = GetUnitStatValue(3),
        critPercent = SafeNumber(SafeCall(GetCritChance)),
        hastePercent = SafeNumber(SafeCall(GetHaste)),
        masteryPercent = SafeNumber(SafeCall(GetMasteryEffect)),
        versatilityPercent = CR_VERSATILITY_DAMAGE_DONE and SafeNumber(SafeCall(GetCombatRatingBonus, CR_VERSATILITY_DAMAGE_DONE)) or nil,
        leech = SafeNumber(SafeCall(GetLifesteal)),
        speed = SafeNumber(SafeCall(GetSpeed)),
        avoidance = SafeNumber(SafeCall(GetAvoidance)),
    }

    return stats
end

local function GetEquippedItemLevel()
    local overall, equipped = SafeCall(GetAverageItemLevel)
    return {
        overall = SafeNumber(overall),
        equipped = SafeNumber(equipped or overall),
    }
end

local function CapturePlayer()
    local name, realm = SafeCall(UnitFullName, "player")
    if not name or name == "" then name = SafeCall(UnitName, "player") end
    if not realm or realm == "" then realm = SafeCall(GetRealmName) end

    local classSpec = GetClassAndSpec()
    return {
        name = name,
        realm = realm,
        level = SafeNumber(SafeCall(UnitLevel, "player")),
        class = {
            name = classSpec.className,
            file = classSpec.classFile,
            id = classSpec.classID,
        },
        specID = classSpec.specID,
        specName = classSpec.specName,
        equippedItemLevel = GetEquippedItemLevel(),
    }
end

local function CaptureGearSlot(slotDef)
    local slotID = slotDef and slotDef.slotID
    local link = slotID and SafeCall(GetInventoryItemLink, "player", slotID) or nil
    local itemID = GetItemIDFromLink(link)
    local rawLines, structuredLines = ReadInventoryTooltip(slotID, link)
    local upgrade = ParseUpgradeTrack(rawLines)
    local tooltipAnalysis = AnalyzeTooltipLines(rawLines, link)

    local equipLoc, icon
    if itemID and GetItemInfoInstant then
        local _, _, _, itemEquipLoc, itemIcon = GetItemInfoInstant(itemID)
        equipLoc = itemEquipLoc
        icon = itemIcon
    end
    if not icon and slotID and GetInventoryItemTexture then
        icon = GetInventoryItemTexture("player", slotID)
    end

    return {
        slotName = slotDef and slotDef.name,
        slotID = slotID,
        itemLink = link,
        itemID = itemID,
        itemLevel = GetItemLevel(link),
        equipLoc = equipLoc,
        icon = icon,
        upgradeTrack = upgrade.track,
        upgradeRank = upgrade.rank,
        upgradeMaxRank = upgrade.maxRank,
        upgradeRawLine = upgrade.rawLine,
        tooltipLinesRaw = rawLines,
        tooltipLinesStructured = structuredLines,
        enchantDetected = tooltipAnalysis.enchantDetected,
        enchantLines = tooltipAnalysis.enchantLines,
        gemsDetected = tooltipAnalysis.gemsDetected,
        gemLines = tooltipAnalysis.gemLines,
        emptySocketCount = tooltipAnalysis.emptySocketCount,
        socketedGemCount = tooltipAnalysis.socketedGemCount,
        craftedIndicatorVisible = tooltipAnalysis.craftedIndicatorVisible,
        craftedLines = tooltipAnalysis.craftedLines,
        tierIndicatorVisible = tooltipAnalysis.tierIndicatorVisible,
        tierLines = tooltipAnalysis.tierLines,
        primaryStatsShown = tooltipAnalysis.primaryStatsShown,
        secondaryStatsShown = tooltipAnalysis.secondaryStatsShown,
    }
end

local function CaptureEquippedGear()
    local slots = {}
    for _, slotDef in ipairs(CopySlotDefs()) do
        table.insert(slots, CaptureGearSlot(slotDef))
    end
    return slots
end

local function EnsureDB()
    KeyLabGearStatsProbeDB = KeyLabGearStatsProbeDB or {}
    KeyLabGearStatsProbeDB.captures = KeyLabGearStatsProbeDB.captures or {}
    return KeyLabGearStatsProbeDB
end

local function SaveCapture(record)
    local db = EnsureDB()
    db.latest = record
    table.insert(db.captures, 1, record)
    while #db.captures > MAX_SAVED_CAPTURES do
        table.remove(db.captures)
    end
end

local function Print(message)
    if KeyLab.Print then
        KeyLab.Print(message)
    else
        print("|cffd4af37KeyLab:|r " .. tostring(message))
    end
end

function Probe.CaptureNow(reason)
    local timestamp = time and time() or 0
    local record = {
        schemaVersion = 1,
        capturedAt = timestamp,
        capturedAtText = date and date("%Y-%m-%d %H:%M:%S", timestamp) or tostring(timestamp),
        reason = reason or "manual",
        player = CapturePlayer(),
        currentStats = GetCurrentStats(),
        equippedGear = CaptureEquippedGear(),
    }

    SaveCapture(record)
    Print("Gear stats probe captured " .. tostring(#(record.equippedGear or {})) .. " slots. Use /reload or log out to write KeyLabGearStatsProbeDB.")
    return record
end

SLASH_KEYLABGEARSTATSPROBE1 = "/keylabgearstatsprobe"
SLASH_KEYLABGEARSTATSPROBE2 = "/klgearstats"
SLASH_KEYLABGEARSTATSPROBE3 = "/klgsp"
SlashCmdList["KEYLABGEARSTATSPROBE"] = function(msg)
    Probe.CaptureNow(msg and msg ~= "" and msg or "slash")
end

return Probe
