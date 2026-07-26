-- KeyLab_GearCapture.lua
--
-- Live data capture for gearing features.
-- This module reads WoW API state and tooltip text only. It does not score,
-- recommend, or build UI.

local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.GearCapture = KeyLab.GearCapture or {}
local Capture = KeyLab.GearCapture

local SLOT_DEF_CACHE
local SLOT_CACHE = {}
local DIRTY_SLOTS = {}
local DIRTY_ALL_SLOTS = true

local TRACK_NAMES = { "Myth", "Hero", "Champion", "Veteran", "Adventurer" }

local PRIMARY_STATS = {
    { key = "strength", label = "Strength", aliases = { "strength" } },
    { key = "agility", label = "Agility", aliases = { "agility" } },
    { key = "intellect", label = "Intellect", aliases = { "intellect" } },
    { key = "stamina", label = "Stamina", aliases = { "stamina" } },
}

local SECONDARY_STATS = {
    { key = "crit", label = "Critical Strike", aliases = { "critical strike", "crit" } },
    { key = "haste", label = "Haste", aliases = { "haste" } },
    { key = "mastery", label = "Mastery", aliases = { "mastery" } },
    { key = "versatility", label = "Versatility", aliases = { "versatility", "vers" } },
}

local function DB()
    return KeyLab and KeyLab.GearingDatabase or {}
end

local function CopyTable(source)
    if type(source) ~= "table" then return source end
    local out = {}
    for key, value in pairs(source) do
        if type(value) == "table" then
            out[key] = CopyTable(value)
        else
            out[key] = value
        end
    end
    return out
end

local function GetSlotDefs()
    if SLOT_DEF_CACHE then return SLOT_DEF_CACHE end
    SLOT_DEF_CACHE = {}
    for _, slotDef in ipairs(DB().InventorySlots or {}) do
        SLOT_DEF_CACHE[slotDef.name] = {
            name = slotDef.name,
            slotID = slotDef.slotID,
        }
    end
    return SLOT_DEF_CACHE
end

local function BaseSlotName(slotName)
    slotName = tostring(slotName or "")
    if slotName == "Finger 1" or slotName == "Finger 2" then return "Finger" end
    if slotName == "Trinket 1" or slotName == "Trinket 2" then return "Trinket" end
    return slotName
end

local function DisplaySlotName(slotName)
    if DB().GetDisplaySlotLabel then
        return DB().GetDisplaySlotLabel(slotName)
    end
    if slotName == "Main Hand" then return "Weapon" end
    if slotName == "Off Hand" then return "Off-Hand" end
    return slotName or "-"
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

local function GetItemIDFromLink(link)
    return tonumber(tostring(link or ""):match("item:(%d+)"))
end

local function TooltipDataToLines(data)
    local lines = {}
    if type(data) ~= "table" then return lines end

    for _, line in ipairs(data.lines or {}) do
        if line.leftText and line.leftText ~= "" then
            table.insert(lines, CleanLine(line.leftText))
        end
        if line.rightText and line.rightText ~= "" then
            table.insert(lines, CleanLine(line.rightText))
        end
        if type(line.args) == "table" then
            for _, arg in ipairs(line.args) do
                if type(arg) == "table" and arg.stringVal and arg.stringVal ~= "" then
                    table.insert(lines, CleanLine(arg.stringVal))
                end
            end
        end
    end

    return lines
end

local function ReadTooltip(slotID, itemLink)
    local tooltip

    if C_TooltipInfo and C_TooltipInfo.GetInventoryItem and slotID then
        local ok, data = pcall(C_TooltipInfo.GetInventoryItem, "player", slotID)
        if ok and data and type(data.lines) == "table" and #data.lines > 0 then
            tooltip = data
        end
    end

    if not tooltip and C_TooltipInfo and C_TooltipInfo.GetHyperlink and itemLink then
        local ok, data = pcall(C_TooltipInfo.GetHyperlink, itemLink)
        if ok and data then tooltip = data end
    end

    local lines = TooltipDataToLines(tooltip)
    return table.concat(lines, "\n"), lines
end

local function FindLine(lines, pattern, plain)
    for _, line in ipairs(lines or {}) do
        local text = CleanLine(line)
        local lower = text:lower()
        if plain then
            if lower:find(pattern, 1, true) then return text end
        elseif lower:find(pattern) then
            return text
        end
    end
    return nil
end

local function ParseUpgrade(lines)
    for _, line in ipairs(lines or {}) do
        local text = CleanLine(line)
        for _, trackName in ipairs(TRACK_NAMES) do
            local rank, maxRank = text:match(trackName .. "%s+(%d+)/(%d+)")
            if rank and maxRank then
                return {
                    rawLine = text,
                    track = trackName,
                    rank = tonumber(rank),
                    maxRank = tonumber(maxRank),
                }
            end
        end
    end

    return {
        rawLine = nil,
        track = nil,
        rank = nil,
        maxRank = nil,
    }
end

local function DetectEnchant(lines)
    local found = {}
    for _, line in ipairs(lines or {}) do
        local text = CleanLine(line)
        local lower = text:lower()
        if lower:match("^enchanted:") and not lower:find("illusory", 1, true) then
            table.insert(found, text)
        end
    end
    return #found > 0, found
end

local function DetectSockets(lines, itemLink)
    local explicitEmptyCount = 0
    local genericSocketCount = 0
    local socketedGemCount = CountSocketedGems(itemLink)
    local gemLines = {}

    for _, line in ipairs(lines or {}) do
        local text = CleanLine(line)
        local lower = text:lower()

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
            explicitEmptyCount = explicitEmptyCount + 1
            table.insert(gemLines, text)
        elseif socketLooksEmpty then
            genericSocketCount = genericSocketCount + 1
            table.insert(gemLines, text)
        elseif isSocketLine or lower:find("gem", 1, true) then
            table.insert(gemLines, text)
        end
    end

    local emptyCount = explicitEmptyCount + math.max(0, genericSocketCount - socketedGemCount)
    return emptyCount, gemLines
end

local function DetectTier(slotBaseName, lines)
    if not (DB().TierSlots and DB().TierSlots[slotBaseName]) then return false, {} end

    local tierLines = {}
    for _, line in ipairs(lines or {}) do
        local text = CleanLine(line)
        local lower = text:lower()
        if lower:find("set:", 1, true)
            or lower:find("class set", 1, true)
            or lower:find("2 set", 1, true)
            or lower:find("4 set", 1, true) then
            table.insert(tierLines, text)
        end
    end

    return #tierLines > 0, tierLines
end

local function DetectCrafted(lines)
    local craftedLines = {}
    for _, line in ipairs(lines or {}) do
        local text = CleanLine(line)
        local lower = text:lower()
        if lower:find("crafted by", 1, true)
            or lower:find("made by", 1, true)
            or lower:find("spark", 1, true)
            or lower:find("radiance crafted", 1, true)
            or lower:find("embellished", 1, true) then
            table.insert(craftedLines, text)
        end
    end
    return #craftedLines > 0, craftedLines
end

local function ParseCraftQuality(lines)
    for _, line in ipairs(lines or {}) do
        local text = CleanLine(line)
        local tier = text:match("Quality%-Tier(%d+)") or text:match("Quality:%s*.-Tier(%d+)") or text:match("Quality%s*:%s*(%d+)")
        if tier then return tonumber(tier), text end
    end
    return nil, nil
end

local function DetectEmbellishment(lines)
    local line = FindLine(lines, "unique%-equipped:%s*embellished", false)
    return line ~= nil, line
end

local function DetectVoidforged(lines)
    local line = FindLine(lines, "ascendant voidforged", true)
    return line ~= nil, line
end

local function ParseVoidforgeTrack(line)
    local lower = CleanLine(line):lower()
    local track = lower:match("ascendant voidforged:%s*([%a]+)")
    if track == "hero" then return "Hero" end
    if track == "myth" then return "Myth" end
    return nil
end

local function ExtractStats(lines, statDefs)
    local found = {}
    for _, line in ipairs(lines or {}) do
        local text = CleanLine(line)
        local lower = text:lower()
        for _, stat in ipairs(statDefs or {}) do
            for _, alias in ipairs(stat.aliases or {}) do
                if lower:find(alias, 1, true) then
                    table.insert(found, {
                        key = stat.key,
                        label = stat.label,
                        rawLine = text,
                    })
                    break
                end
            end
        end
    end
    return found
end

local function GetInventoryItemLevel(itemLink)
    if not itemLink then return nil end
    if C_Item and C_Item.GetDetailedItemLevelInfo then
        local ok, itemLevel = pcall(C_Item.GetDetailedItemLevelInfo, itemLink)
        if ok and itemLevel then return tonumber(itemLevel) end
    end
    if GetDetailedItemLevelInfo then
        local ok, itemLevel = pcall(GetDetailedItemLevelInfo, itemLink)
        if ok and itemLevel then return tonumber(itemLevel) end
    end
    return nil
end

local function GetItemTexture(slotID, itemID)
    if slotID and GetInventoryItemTexture then
        local texture = GetInventoryItemTexture("player", slotID)
        if texture then return texture end
    end
    if itemID and C_Item and C_Item.GetItemIconByID then
        local ok, texture = pcall(C_Item.GetItemIconByID, itemID)
        if ok and texture then return texture end
    end
    return nil
end

local function GetItemEquipLoc(itemID)
    if not itemID or not GetItemInfoInstant then return nil end
    local _, _, _, equipLoc = GetItemInfoInstant(itemID)
    return equipLoc
end

local function EmptySlot(slotName)
    local slotDef = GetSlotDefs()[slotName]
    return {
        slotID = slotDef and slotDef.slotID,
        slotName = slotName,
        name = slotName,
        displayName = DisplaySlotName(slotName),
        baseName = BaseSlotName(slotName),
        itemLink = nil,
        link = nil,
        itemID = nil,
        itemLevel = nil,
        icon = nil,
        texture = nil,
        equipLoc = nil,
        upgradeRawLine = nil,
        upgradeTrack = nil,
        upgradeRank = nil,
        upgradeMaxRank = nil,
        trackName = nil,
        enchantDetected = false,
        enchantLines = {},
        emptySocketCount = 0,
        socketedGemCount = 0,
        gemLines = {},
        tierEligible = DB().TierSlots and DB().TierSlots[BaseSlotName(slotName)] == true or false,
        tierIndicatorVisible = false,
        tierDetected = false,
        tierLines = {},
        craftedIndicatorVisible = false,
        craftedDetected = false,
        craftedLines = {},
        craftQualityTier = nil,
        craftQualityLine = nil,
        radianceCraftedDetected = false,
        embellishedDetected = false,
        embellishmentLine = nil,
        ascendantVoidforgedDetected = false,
        voidforgedDetected = false,
        voidforgeLine = nil,
        voidforgeTrack = nil,
        craftedWeaponVoidforgeCandidate = false,
        weaponVoidforgeCandidate = false,
        trinketVoidforgeCandidate = false,
        voidforgeCandidate = false,
        primaryStatsShown = {},
        secondaryStatsShown = {},
        tooltipText = "",
        tooltipLinesRaw = {},
        isTierSlot = DB().TierSlots and DB().TierSlots[BaseSlotName(slotName)] == true or false,
        isTierPiece = false,
        isCrafted = false,
        missingEnchant = false,
        missingGem = false,
        missingEmbellishment = false,
    }
end

local function ScanEquippedSlot(slotName)
    local slotDef = GetSlotDefs()[slotName]
    local info = EmptySlot(slotName)
    if not slotDef or not slotDef.slotID or not GetInventoryItemLink then return info end

    local itemLink = GetInventoryItemLink("player", slotDef.slotID)
    if not itemLink then return info end

    local itemID = GetItemIDFromLink(itemLink)
    local tooltipText, tooltipLines = ReadTooltip(slotDef.slotID, itemLink)
    local upgrade = ParseUpgrade(tooltipLines)
    local enchantDetected, enchantLines = DetectEnchant(tooltipLines)
    local emptySocketCount, gemLines = DetectSockets(tooltipLines, itemLink)
    local socketedGemCount = CountSocketedGems(itemLink)
    local tierDetected, tierLines = DetectTier(info.baseName, tooltipLines)
    local craftedDetected, craftedLines = DetectCrafted(tooltipLines)
    local craftQualityTier, craftQualityLine = ParseCraftQuality(tooltipLines)
    local embellishedDetected, embellishmentLine = DetectEmbellishment(tooltipLines)
    local voidforgedDetected, voidforgeLine = DetectVoidforged(tooltipLines)
    local equipLoc = GetItemEquipLoc(itemID)
    local itemLevel = GetInventoryItemLevel(itemLink)
    local radianceCraftedDetected = tooltipText:lower():find("radiance crafted", 1, true) ~= nil
    local craftedIndicatorVisible = craftedDetected == true or radianceCraftedDetected == true or craftQualityTier ~= nil
    local voidforgeRules = DB().Voidforge or {}
    local voidforgeTrack = ParseVoidforgeTrack(voidforgeLine)
    if not voidforgeTrack and voidforgedDetected and not craftedIndicatorVisible and itemLevel then
        local baseMax = voidforgeRules.baseMaxItemLevel or {}
        if tonumber(baseMax.Myth) and itemLevel > tonumber(baseMax.Myth) then
            voidforgeTrack = "Myth"
        elseif tonumber(baseMax.Hero) and itemLevel > tonumber(baseMax.Hero) then
            voidforgeTrack = "Hero"
        end
    end
    local trackName = upgrade.track or voidforgeTrack
    local upgradeRank = upgrade.rank
    local upgradeMaxRank = upgrade.maxRank
    if voidforgeTrack and not upgradeRank then
        upgradeRank = tonumber(voidforgeRules.requiredRank) or 6
        upgradeMaxRank = tonumber(voidforgeRules.requiredMaxRank) or 6
    end
    local isVoidforgeTrack = voidforgeRules.eligibleTracks and voidforgeRules.eligibleTracks[trackName] == true
    local isMaxRank = tonumber(upgradeRank) == tonumber(voidforgeRules.requiredRank or 6)
        and tonumber(upgradeMaxRank) == tonumber(voidforgeRules.requiredMaxRank or 6)
    -- Ascendant Voidcores apply only to eligible Hero/Myth-track Main Hand
    -- weapons and trinkets. Crafted items have no upgrade track.
    local craftedWeaponVoidforgeCandidate = false
    local weaponVoidforgeCandidate = voidforgeRules.weaponSlotIDs
        and voidforgeRules.weaponSlotIDs[tonumber(slotDef.slotID) or 0] == true
        and isVoidforgeTrack
        and isMaxRank
    local trinketVoidforgeCandidate = voidforgeRules.trinketSlotIDs
        and voidforgeRules.trinketSlotIDs[tonumber(slotDef.slotID) or 0] == true
        and isVoidforgeTrack
        and isMaxRank

    info.itemLink = itemLink
    info.link = itemLink
    info.itemID = itemID
    info.itemLevel = itemLevel
    info.icon = GetItemTexture(slotDef.slotID, itemID)
    info.texture = info.icon
    info.equipLoc = equipLoc
    info.upgradeRawLine = upgrade.rawLine
    info.upgradeTrack = trackName
    info.trackName = trackName
    info.upgradeRank = upgradeRank
    info.upgradeMaxRank = upgradeMaxRank
    info.upgradeMax = upgradeMaxRank
    info.enchantDetected = enchantDetected
    info.enchantLines = enchantLines
    info.emptySocketCount = emptySocketCount
    info.socketedGemCount = socketedGemCount
    info.gemLines = gemLines
    info.tierIndicatorVisible = tierDetected
    info.tierDetected = tierDetected
    info.tierLines = tierLines
    info.isTierPiece = tierDetected
    info.craftedIndicatorVisible = craftedIndicatorVisible
    info.craftedDetected = craftedIndicatorVisible
    info.isCrafted = craftedIndicatorVisible
    info.craftedLines = craftedLines
    info.craftQualityTier = craftQualityTier
    info.craftQualityLine = craftQualityLine
    info.radianceCraftedDetected = radianceCraftedDetected
    info.embellishedDetected = embellishedDetected
    info.embellishmentLine = embellishmentLine
    info.ascendantVoidforgedDetected = voidforgedDetected
    info.voidforgedDetected = voidforgedDetected
    info.voidforgeLine = voidforgeLine
    info.voidforgeTrack = voidforgeTrack
    info.craftedWeaponVoidforgeCandidate = craftedWeaponVoidforgeCandidate
    info.weaponVoidforgeCandidate = weaponVoidforgeCandidate
    info.trinketVoidforgeCandidate = trinketVoidforgeCandidate
    info.voidforgeCandidate = craftedWeaponVoidforgeCandidate or weaponVoidforgeCandidate or trinketVoidforgeCandidate
    info.primaryStatsShown = ExtractStats(tooltipLines, PRIMARY_STATS)
    info.secondaryStatsShown = ExtractStats(tooltipLines, SECONDARY_STATS)
    info.tooltipText = tooltipText
    info.tooltipLinesRaw = tooltipLines

    -- Compatibility fields for older callers. The analysis layer decides
    -- whether these become visible badges.
    info.missingGem = emptySocketCount > 0
    info.missingEnchant = false
    info.missingEmbellishment = false

    return info
end

function Capture.MarkAllSlotsChanged()
    DIRTY_ALL_SLOTS = true
end

function Capture.MarkSlotChanged(slotID)
    slotID = tonumber(slotID)
    if not slotID then
        Capture.MarkAllSlotsChanged()
        return
    end

    for slotName, slotDef in pairs(GetSlotDefs()) do
        if tonumber(slotDef.slotID) == slotID then
            DIRTY_SLOTS[slotName] = true
            return
        end
    end
end

function Capture.GetEquippedSlot(slotName, force)
    local shouldScan = force or DIRTY_ALL_SLOTS or DIRTY_SLOTS[slotName] or not SLOT_CACHE[slotName]
    if shouldScan then
        SLOT_CACHE[slotName] = ScanEquippedSlot(slotName)
        DIRTY_SLOTS[slotName] = nil
    end
    return CopyTable(SLOT_CACHE[slotName] or EmptySlot(slotName))
end

function Capture.GetEquippedSlots(slotNames)
    local forceAll = DIRTY_ALL_SLOTS
    local out = {}
    for _, slotName in ipairs(slotNames or {}) do
        out[slotName] = Capture.GetEquippedSlot(slotName, forceAll)
    end
    DIRTY_ALL_SLOTS = false
    return out
end

function Capture.GetItemTooltipText(item)
    if type(item) == "string" then
        local tooltipText = ReadTooltip(nil, item)
        return tooltipText or ""
    end
    if type(item) ~= "table" then return "" end

    local saved = table.concat({
        tostring(item.description or ""),
        tostring(item.tooltip or ""),
        tostring(item.tooltipText or ""),
        tostring(item.effect or ""),
        tostring(item.equipText or ""),
        tostring(item.useText or ""),
    }, "\n")
    if saved:gsub("%s+", "") ~= "" then return saved end

    local itemLink = item.itemLink or item.link
    if not itemLink or itemLink == "" then return "" end

    local tooltipText = ReadTooltip(nil, itemLink)
    return tooltipText or ""
end

function Capture.IsTwoHandOrRangedWeapon(slot)
    return slot and slot.itemLink and DB().IsTwoHandOrRangedEquipLoc and DB().IsTwoHandOrRangedEquipLoc(slot.equipLoc)
end

function Capture.GetEquippedItemLevel()
    if GetAverageItemLevel then
        local overall, equipped = GetAverageItemLevel()
        return tonumber(equipped or overall)
    end
    return nil
end

-- Lightweight equipment snapshot for encounter history. This intentionally
-- avoids tooltip scans at pull start; the Gear Dashboard keeps the deeper scan.
function Capture.GetProfileSnapshot()
    local snapshot = {
        capturedAt = time and time() or nil,
        averageItemLevel = Capture.GetEquippedItemLevel(),
        slots = {},
    }
    local signature = {}

    for _, slotDef in ipairs(DB().InventorySlots or {}) do
        local itemLink = GetInventoryItemLink and GetInventoryItemLink("player", slotDef.slotID) or nil
        local itemID = GetItemIDFromLink(itemLink)
        local itemName = nil
        if itemLink and GetItemInfo then itemName = GetItemInfo(itemLink) end
        local slot = {
            slotName = slotDef.name,
            slotID = slotDef.slotID,
            itemID = itemID,
            itemLink = itemLink,
            itemName = itemName,
            itemLevel = GetInventoryItemLevel(itemLink),
            icon = GetItemTexture(slotDef.slotID, itemID),
        }
        snapshot.slots[slotDef.name] = slot
        table.insert(signature, tostring(slotDef.slotID) .. ":" .. tostring(itemLink or "empty"))
    end

    snapshot.signature = table.concat(signature, "|")
    return snapshot
end

function Capture.GetCurrentSpecID()
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

function Capture.GetCurrentClassID()
    if KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.GetCurrentClassID then
        return KeyLab.LootTargetsDB.GetCurrentClassID()
    end
    if UnitClass then
        local _, _, classID = UnitClass("player")
        return classID or 0
    end
    return 0
end

function Capture.GetPlayerLevel()
    if UnitLevel then return tonumber(UnitLevel("player")) end
    return nil
end

function Capture.GetCurrencyAmount(currencyID)
    currencyID = tonumber(currencyID)
    if not currencyID or not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyInfo then return nil end
    local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, currencyID)
    if not ok or type(info) ~= "table" then return nil end
    return tonumber(info.quantity or info.totalEarned or info.maxQuantity) or 0
end

function Capture.GetItemCount(itemID)
    itemID = tonumber(itemID)
    if not itemID then return nil end
    if C_Item and C_Item.GetItemCount then
        local ok, count = pcall(C_Item.GetItemCount, itemID, true, false, true)
        if ok then return tonumber(count) or 0 end
    end
    if GetItemCount then
        local ok, count = pcall(GetItemCount, itemID, true, false, true)
        if ok then return tonumber(count) or 0 end
    end
    return nil
end

function Capture.GetBagItemCount(itemID)
    itemID = tonumber(itemID)
    if not itemID then return nil end
    if C_Item and C_Item.GetItemCount then
        local ok, count = pcall(C_Item.GetItemCount, itemID, false, false, false)
        if ok then return tonumber(count) or 0 end
    end
    if GetItemCount then
        local ok, count = pcall(GetItemCount, itemID, false, false, false)
        if ok then return tonumber(count) or 0 end
    end
    return nil
end

function Capture.GetCurrencySnapshot()
    local snapshot = {}
    for key, entry in pairs(DB().CurrencyKeys or {}) do
        if entry.type == "item" then
            snapshot[key] = Capture.GetItemCount(entry.id) or 0
        else
            snapshot[key] = Capture.GetCurrencyAmount(entry.id) or 0
        end
    end
    return snapshot
end

local function GreatVaultRequirements()
    local requirements = {}
    for _, entry in ipairs((DB().GreatVaultSlots and DB().GreatVaultSlots.mythicPlus) or {}) do
        local required = tonumber(entry.required)
        if required then table.insert(requirements, required) end
    end
    table.sort(requirements)
    return requirements
end

local function WeeklyRewardActivityTypes()
    local types = {}
    local seen = {}

    local function add(value)
        if value == nil or seen[value] then return end
        seen[value] = true
        table.insert(types, value)
    end

    local enum = Enum and Enum.WeeklyRewardChestThresholdType
    if type(enum) == "table" then
        add(enum.MythicPlus)
        add(enum.Activities)
        add(enum.Dungeons)
        add(enum.Dungeon)
    end

    return types
end

function Capture.GetGreatVaultMythicPlusProgress()
    local requirements = GreatVaultRequirements()
    if #requirements == 0 then return nil end

    local maxRequired = requirements[#requirements]
    local requirementSet = {}
    for _, required in ipairs(requirements) do
        requirementSet[required] = true
    end

    if not (C_WeeklyRewards and C_WeeklyRewards.GetActivities) then
        return nil
    end

    for _, activityType in ipairs(WeeklyRewardActivityTypes()) do
        local ok, activities = pcall(C_WeeklyRewards.GetActivities, activityType)
        if ok and type(activities) == "table" and #activities > 0 then
            local matchedThresholds = 0
            local progress = 0
            local unlockedSlots = 0

            for _, activity in ipairs(activities) do
                local threshold = tonumber(activity.threshold or activity.required or activity.requiredCount)
                local activityProgress = tonumber(activity.progress or activity.currentProgress)

                if threshold and requirementSet[threshold] then
                    matchedThresholds = matchedThresholds + 1
                end
                if activityProgress and activityProgress > progress then
                    progress = activityProgress
                end
                if threshold and activityProgress and activityProgress >= threshold then
                    unlockedSlots = unlockedSlots + 1
                end
            end

            if matchedThresholds > 0 then
                return {
                    progress = math.max(0, math.min(progress, maxRequired)),
                    required = maxRequired,
                    unlockedSlots = unlockedSlots,
                    totalSlots = #requirements,
                    source = "weeklyRewards",
                }
            end
        end
    end

    return nil
end

local function GetCurrentCharacterIdentity()
    local name, realm
    if UnitFullName then name, realm = UnitFullName("player") end
    if not name or name == "" then name = UnitName and UnitName("player") or nil end
    if (not realm or realm == "") and GetRealmName then realm = GetRealmName() end
    return name, realm
end

local function NormalizeName(value)
    value = tostring(value or "")
    value = value:gsub("%s+", ""):gsub("'", ""):lower()
    return value
end

local function EncounterMatchesCurrentCharacter(encounter)
    if type(encounter) ~= "table" then return false end
    local currentName, currentRealm = GetCurrentCharacterIdentity()
    if not currentName or currentName == "" then return true end

    local player = encounter.player or {}
    local character = encounter.character or {}
    local context = encounter.context or {}
    local capture = encounter.capture or {}
    local encounterName =
        player.name
        or player.characterName
        or character.name
        or character.characterName
        or context.characterName
        or capture.characterName
        or encounter.characterName
        or encounter.playerName
        or encounter.name
    local encounterRealm =
        player.realm
        or character.realm
        or context.realm
        or capture.realm
        or encounter.realm
        or encounter.realmName

    if not encounterName or encounterName == "" then return true end
    if NormalizeName(encounterName) ~= NormalizeName(currentName) then return false end
    if encounterRealm and encounterRealm ~= "" and currentRealm and currentRealm ~= "" then
        return NormalizeName(encounterRealm) == NormalizeName(currentRealm)
    end
    return true
end

local function IsCompletedEncounter(encounter)
    local encounterData = KeyLab.Analysis and KeyLab.Analysis.EncounterData
    if encounterData and encounterData.IsCompletedEncounter then
        return encounterData.IsCompletedEncounter(encounter)
    end

    if type(encounter) ~= "table" then return false end
    local flags = encounter.flags or {}
    if flags.interrupted == true or encounter.interrupted == true then return false end
    if encounter.status == "capture_failed" or encounter.excludeFromComparisons == true then return false end
    if encounter.completed == true or encounter.isComplete == true then return true end
    if encounter.result == "Completed" or encounter.result == "Complete" then return true end
    if encounter.result == "Timed" or encounter.result == "Untimed" or encounter.result == "Depleted" then return true end
    return type(encounter.metrics) == "table" and next(encounter.metrics) ~= nil
end

local function IsTimedEncounter(encounter)
    local encounterData = KeyLab.Analysis and KeyLab.Analysis.EncounterData
    if encounterData and encounterData.GetTimed then
        return encounterData.GetTimed(encounter) == true
    end

    local challenge = encounter and encounter.challenge or {}
    return encounter and challenge.timed == true
end

local function GetEncounterKeyLevel(encounter)
    local challenge = encounter and encounter.challenge or {}
    return tonumber(challenge.keyLevel or encounter.keyLevel or encounter.level or 0) or 0
end

function Capture.GetRunHistory()
    local encounterData = KeyLab.Analysis and KeyLab.Analysis.EncounterData
    local usedSharedList = false
    local db = KeyLabDB and KeyLabDB.encounters or {}
    if encounterData and encounterData.GetEncounterList then
        db = encounterData.GetEncounterList({
            includeInterrupted = false,
            includeExcluded = false,
            completedOnly = true,
            allowMissingIdentity = true,
        })
        usedSharedList = true
    end

    local summary = {
        completed = 0,
        highestCompleted = 0,
        highestTimed = 0,
    }

    for _, encounter in pairs(db or {}) do
        if usedSharedList or (EncounterMatchesCurrentCharacter(encounter) and IsCompletedEncounter(encounter)) then
            local keyLevel = GetEncounterKeyLevel(encounter)
            if keyLevel > 0 then
                summary.completed = summary.completed + 1
                if keyLevel > summary.highestCompleted then summary.highestCompleted = keyLevel end
                if IsTimedEncounter(encounter) and keyLevel > summary.highestTimed then summary.highestTimed = keyLevel end
            end
        end
    end

    return summary
end

return Capture
