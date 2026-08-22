-- KeyLab_GearingAnalysis.lua
-- Builds the Gear Dashboard from equipped gear, automatic item classification, and saved targets.

local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.GearingAnalysis = KeyLab.GearingAnalysis or {}
local Analysis = KeyLab.GearingAnalysis

local DEFAULT_LEFT_SLOTS = { "Head", "Neck", "Shoulders", "Back", "Chest", "Wrist", "Main Hand", "Off Hand" }
local DEFAULT_RIGHT_SLOTS = { "Hands", "Waist", "Legs", "Feet", "Finger 1", "Finger 2", "Trinket 1", "Trinket 2" }
local TIER_SLOTS = { Head = true, Shoulders = true, Chest = true, Hands = true, Legs = true }

local dashboardStateBusy = false
local lastDashboardState

local function GearingDB()
    return KeyLab and KeyLab.GearingDatabase or {}
end

local function Capture()
    return KeyLab and KeyLab.GearCapture or {}
end

local function Targets()
    return KeyLab and KeyLab.LootTargetsDB or {}
end

local function TierDB()
    return KeyLab and KeyLab.TierSetDB or {}
end

local function ClassificationDB()
    return KeyLab and KeyLab.ItemClassificationDB or {}
end

local function Mapping()
    return KeyLab and KeyLab.GearLootMapping or {}
end

local function CopySlots(side, fallback)
    if GearingDB().GetDashboardSlots then
        local slots = GearingDB().GetDashboardSlots(side)
        if slots and #slots > 0 then return slots end
    end
    local out = {}
    for _, slotName in ipairs(fallback) do table.insert(out, slotName) end
    return out
end

Analysis.LeftSlots = CopySlots("left", DEFAULT_LEFT_SLOTS)
Analysis.RightSlots = CopySlots("right", DEFAULT_RIGHT_SLOTS)

local function CurrentSpec()
    local specIndex = GetSpecialization and GetSpecialization()
    if specIndex and GetSpecializationInfo then
        local specID, specName = GetSpecializationInfo(specIndex)
        return tonumber(specID) or 0, specName or "Current Spec"
    end
    return 0, "Current Spec"
end

local function CurrentSeason()
    if TierDB().GetCurrentSeason then return TierDB().GetCurrentSeason() end
    local db = KeyLab.GearLootDatabase
    return tonumber(db and (db.mnSeason or db.season)) or 1
end

local function DisplaySlotName(slotName)
    return slotName or "-"
end

local function EmptySlot(slotName)
    return {
        slotName = slotName,
        displayName = DisplaySlotName(slotName),
        itemID = nil,
        itemLink = nil,
        itemLevel = nil,
        icon = nil,
        texture = nil,
        upgradeTrack = nil,
        upgradeRank = nil,
        upgradeMaxRank = nil,
        equipLoc = nil,
    }
end

local function GetEquippedSlots(force)
    local names = {}
    for _, slotName in ipairs(Analysis.LeftSlots) do table.insert(names, slotName) end
    for _, slotName in ipairs(Analysis.RightSlots) do table.insert(names, slotName) end
    if Capture().GetEquippedSlots then return Capture().GetEquippedSlots(names, force == true) or {} end
    local out = {}
    for _, slotName in ipairs(names) do
        out[slotName] = Capture().GetEquippedSlot and Capture().GetEquippedSlot(slotName, force == true) or EmptySlot(slotName)
    end
    return out
end

local function GetEquippedItemLevel()
    if Capture().GetEquippedItemLevel then return Capture().GetEquippedItemLevel() end
    if GetAverageItemLevel then
        local _, equipped = GetAverageItemLevel()
        return tonumber(equipped)
    end
    return nil
end

local function ShortName(value, maxLength)
    value = tostring(value or "")
    maxLength = tonumber(maxLength) or 24
    if #value <= maxLength then return value end
    return value:sub(1, math.max(1, maxLength - 3)) .. "..."
end

local function SourceDescriptor(source)
    if type(source) ~= "table" then return nil end
    local name = source.sourceName or source.name or source.dungeonName or source.raidName
    if not name or name == "" then return nil end
    local sourceType = source.sourceType or (source.raidName and "Raid") or "Dungeon"
    local code = GearingDB().GetSourceCode and GearingDB().GetSourceCode(name, sourceType)
        or (GearingDB().GetDungeonCode and GearingDB().GetDungeonCode(name)) or name
    return {
        sourceID = tonumber(source.sourceID or source.mapID or source.instanceID),
        name = name,
        code = tostring(code or name),
        sourceType = sourceType,
        weekly = sourceType == "Raid",
    }
end

local function GetItemSources(itemID, specID, sourceID)
    local out, seen = {}, {}
    if sourceID and Mapping().GetSource then
        local descriptor = SourceDescriptor(Mapping().GetSource(sourceID))
        if descriptor then table.insert(out, descriptor) end
        return out
    end
    if Mapping().GetItemSources then
        for _, source in ipairs(Mapping().GetItemSources(itemID, specID) or {}) do
            local descriptor = SourceDescriptor(source)
            local key = descriptor and (descriptor.sourceType .. ":" .. descriptor.name)
            if descriptor and not seen[key] then
                seen[key] = true
                table.insert(out, descriptor)
            end
        end
    end
    table.sort(out, function(a, b)
        if a.sourceType ~= b.sourceType then return a.sourceType == "Dungeon" end
        return tostring(a.name) < tostring(b.name)
    end)
    return out
end

local function GetTarget(specID, slotName)
    if not Targets().GetTargetForSlot then return nil end
    local record = Targets().GetTargetForSlot(specID, slotName)
    if not record then return nil end
    local item = Mapping().GetItem and Mapping().GetItem(record.itemID, specID, nil, record.sourceID) or nil
    item = item or {
        itemID = record.itemID,
        name = record.itemName or ("Item " .. tostring(record.itemID)),
        itemLink = record.itemLink,
        link = record.itemLink,
        slot = record.itemSlot or slotName,
        sourceName = record.sourceName,
        sourceType = record.sourceType,
        upgradeTrack = record.upgradeTrack,
        upgradeRank = record.upgradeRank,
        upgradeMaxRank = record.upgradeMaxRank,
        itemLevel = record.itemLevel,
        projectedItemLevel = record.projectedItemLevel,
        ownedMatcherItem = record.ownedMatcherItem == true,
    }
    item.slotInstance = slotName
    item.sourceID = record.sourceID or item.sourceID
    item.sourcesForDashboard = GetItemSources(item.itemID, specID, record.sourceID)
    return item
end

local function TierSources(specID, slotName, season)
    local out = {}
    if Mapping().GetCatalystSourcesForSlot then
        for _, source in ipairs(Mapping().GetCatalystSourcesForSlot(specID, slotName, season) or {}) do
            local descriptor = SourceDescriptor(source)
            if descriptor and descriptor.sourceType == "Dungeon" then
                table.insert(out, descriptor)
            end
        end
    end
    return out
end

local function IsMasterDatabaseItem(itemID)
    itemID = tonumber(itemID)
    if not itemID then return false end
    if ClassificationDB().IsMasterItem then return ClassificationDB().IsMasterItem(itemID) end
    local db = KeyLab and KeyLab.GearLootDatabase
    if not db or type(db.items) ~= "table" then return nil end
    return db.items[itemID] ~= nil
end

local function ClassifyItem(itemID, tierFallback)
    if ClassificationDB().ClassifyItem then return ClassificationDB().ClassifyItem(itemID) end
    itemID = tonumber(itemID)
    if not itemID then return { key = "EMPTY", label = "", known = false } end
    if tierFallback then return { key = "TIER_SET", label = "Tier Set Piece", known = true } end
    if IsMasterDatabaseItem(itemID) then return { key = "MASTER", label = "Master Database Item", known = true } end
    return { key = "OTHER", label = "Other Item", known = false }
end

local function GetUpgradeResources()
    local voidforgeRules = GearingDB().Voidforge or {}
    local currencyKeys = GearingDB().CurrencyKeys or {}
    local nebulousID = tonumber(currencyKeys.nebulousVoidcore and currencyKeys.nebulousVoidcore.id) or 3418
    local ascendantItemID = tonumber(voidforgeRules.ascendantItemID)
    return {
        nebulousVoidcores = Capture().GetCurrencyAmount and (Capture().GetCurrencyAmount(nebulousID) or 0) or 0,
        ascendantUpgradeItems = ascendantItemID and Capture().GetBagItemCount
            and (Capture().GetBagItemCount(ascendantItemID) or 0)
            or 0,
    }
end

local function UpgradeAction(slot)
    if not slot or not slot.itemID then return nil end
    local track = tostring(slot.upgradeTrack or slot.trackName or "")
    if track == "Myth" then return nil end
    if track == "Hero" then return "Upgrade to Myth" end
    return "Upgrade to Hero"
end

local function TrackText(slot)
    if not slot or not slot.itemID then return "" end
    local level = tonumber(slot.itemLevel)
    local track = slot.upgradeTrack or slot.trackName
    local systemName = slot.upgradeSystem
    local system = systemName and GearingDB().SpecialUpgradeSystems
        and GearingDB().SpecialUpgradeSystems[systemName] or nil
    if system then
        return tostring(slot.upgradeSystemLabel or system.label or systemName) .. ": " .. tostring(track or "")
    end
    if level and track and track ~= "" then return tostring(math.floor(level + 0.5)) .. " " .. tostring(track) end
    if level then return tostring(math.floor(level + 0.5)) end
    return tostring(track or "")
end

local function RankText(slot)
    if slot and slot.upgradeSystem then return "" end
    local rank = tonumber(slot and slot.upgradeRank)
    local maxRank = tonumber(slot and (slot.upgradeMaxRank or slot.upgradeMax))
    if rank and maxRank then return tostring(rank) .. "/" .. tostring(maxRank) end
    return ""
end

local function BuildSlotPlan(slotName, slot, target, tierState, specID, season, offHandBlocked, resources)
    slot = slot or EmptySlot(slotName)
    resources = resources or {}
    local tierEligible = TIER_SLOTS[slotName] == true
    local tierFallback = not ClassificationDB().ClassifyItem
        and tierEligible and tierState.slots and tierState.slots[slotName] == true or false
    local classification = ClassifyItem(slot.itemID, tierFallback)
    local classificationKey = tostring(classification.key or "OTHER")
    local tierChecked = classificationKey == "TIER_SET"
    local nativeTierOffPiece = classificationKey == "NATIVE_TIER_OFFPIECE"
    local craftedItem = classificationKey == "CRAFTED"
    local otherItem = classificationKey == "OTHER"
    local tierNeeded = tierEligible and not tierChecked and not tierState.complete
        and (classificationKey == "EMPTY" or classificationKey == "MASTER")
    local targetEquipped = target and tonumber(target.itemID) == tonumber(slot.itemID) or false
    local masterDatabaseItem = IsMasterDatabaseItem(slot.itemID)
    local trackName = tostring(slot.upgradeTrack or slot.trackName or "")
    local upgradeRank = tonumber(slot.upgradeRank)
    local upgradeMaxRank = tonumber(slot.upgradeMaxRank or slot.upgradeMax)
    local catalystItem = false
    local voidforgedItem = slot.voidforgedDetected == true or slot.ascendantVoidforgedDetected == true
    local voidforgeRules = GearingDB().Voidforge or {}
    local ascendantItemName = tostring(voidforgeRules.ascendantItemName or "Ascendant upgrade item")
    local specialUpgradeSystem = tostring(slot.upgradeSystem or "")
    local specialUpgradeRules = specialUpgradeSystem ~= ""
        and GearingDB().SpecialUpgradeSystems
        and GearingDB().SpecialUpgradeSystems[specialUpgradeSystem] or nil
    local ascendantRankReady = upgradeRank == tonumber(voidforgeRules.requiredRank or 6)
        and upgradeMaxRank == tonumber(voidforgeRules.requiredMaxRank or 6)
    local voidforgeAvailable = not voidforgedItem
        and not craftedItem
        and not otherItem
        and not (specialUpgradeRules and specialUpgradeRules.ascendantUpgradeEligible == false)
        and slot.voidforgeCandidate == true
        and ascendantRankReady
        and (tonumber(resources.ascendantUpgradeItems) or 0) > 0
    local isHeroTrack = trackName == "Hero"
    local isMythTrack = trackName == "Myth"
    local nebulousAvailable = isHeroTrack
        and not craftedItem
        and not otherItem
        and (tonumber(resources.nebulousVoidcores) or 0) > 0
    local upgradeAction = UpgradeAction(slot)
    local action

    if offHandBlocked then
        action = "Not used with equipped weapon"
    elseif target then
        action = targetEquipped and "Target Equipped" or ("Target: " .. ShortName(target.name or target.itemNameClean, 24))
    elseif otherItem then
        action = "Other Item"
    elseif craftedItem then
        action = "Crafted Item"
    elseif tierNeeded then
        action = slot.itemID and "Catalyst for Tier" or "Find a Tier base item"
    elseif voidforgeAvailable then
        action = ascendantItemName .. " Avail - Upgrade Item"
    elseif nebulousAvailable then
        action = "Nebulous Voidcore Avail - Roll for Myth Item"
    elseif voidforgedItem then
        action = isHeroTrack and "Ascendant Voidforged - Upgrade to Myth" or "Ascendant Voidforged"
    elseif tierChecked then
        action = upgradeAction or "Tier Set Piece"
    elseif nativeTierOffPiece then
        action = upgradeAction or "Native Tier Off-piece"
    elseif catalystItem then
        action = upgradeAction or "Catalyst Item"
    elseif upgradeAction then
        action = upgradeAction
    elseif slot.itemID then
        action = "No saved target"
    else
        action = "No item equipped"
    end

    local guidanceSources = {}
    local sourceLabel = ""
    if target then
        guidanceSources = target.sourcesForDashboard or {}
        sourceLabel = #guidanceSources == 1 and "Target Source:" or "Target Sources:"
    elseif not otherItem and not craftedItem and (tierNeeded or (tierChecked and not isMythTrack)) then
        guidanceSources = TierSources(specID, slotName, season)
        sourceLabel = "Catalyst Sources:"
    end

    local tierBadge = ""
    if tierChecked then tierBadge = "Tier"
    elseif nativeTierOffPiece then tierBadge = "Off-piece"
    elseif craftedItem then tierBadge = "Crafted"
    elseif otherItem then tierBadge = "Other"
    elseif tierNeeded then tierBadge = "Need Tier"
    elseif catalystItem then tierBadge = "Catalyst" end

    return {
        slot = slotName,
        slotName = slotName,
        displayName = DisplaySlotName(slotName),
        itemID = slot.itemID,
        itemLink = slot.itemLink or slot.link,
        texture = slot.icon or slot.texture,
        blank = not slot.itemID,
        itemLevel = slot.itemLevel,
        trackName = slot.upgradeTrack or slot.trackName,
        trackLabel = TrackText(slot),
        rankText = RankText(slot),
        specialUpgradeSystem = specialUpgradeSystem ~= "" and specialUpgradeSystem or nil,
        actionText = action,
        tierEligible = tierEligible,
        tierChecked = tierChecked,
        tierNeeded = tierNeeded,
        tierBadge = tierBadge,
        classification = classification,
        classificationKey = classificationKey,
        target = target,
        targetEquipped = targetEquipped,
        masterDatabaseItem = masterDatabaseItem,
        craftedItem = craftedItem,
        nativeTierOffPiece = nativeTierOffPiece,
        otherItem = otherItem,
        catalystItem = catalystItem,
        voidforgedItem = voidforgedItem,
        voidforgeAvailable = voidforgeAvailable,
        nebulousAvailable = nebulousAvailable,
        isMythTrack = isMythTrack,
        sourceLabel = sourceLabel,
        guidanceSources = guidanceSources,
        offHandBlocked = offHandBlocked == true,
    }
end

local function BuildAlternatives(specID)
    local out = {}
    local list = Targets().GetAllAlternativesForSpec and Targets().GetAllAlternativesForSpec(specID) or {}
    for _, item in ipairs(list) do
        local sources = GetItemSources(item.itemID, specID, item.sourceID)
        local sourceNames = {}
        for _, source in ipairs(sources) do table.insert(sourceNames, source.name) end
        table.insert(out, {
            itemID = item.itemID,
            name = item.name or item.itemNameClean or ("Item " .. tostring(item.itemID)),
            displayName = ShortName(item.name or item.itemNameClean or ("Item " .. tostring(item.itemID)), 25),
            itemLink = item.link or item.itemLink,
            slotInstance = item.slotInstance,
            sources = sources,
            sourceText = #sourceNames > 0 and table.concat(sourceNames, ", ") or "Unknown",
        })
    end
    table.sort(out, function(a, b)
        if tostring(a.name) ~= tostring(b.name) then return tostring(a.name) < tostring(b.name) end
        return tostring(a.sourceText) < tostring(b.sourceText)
    end)
    return out
end

local function AddUniqueNumber(list, seen, value)
    value = tonumber(value)
    if not value or seen[value] then return end
    seen[value] = true
    table.insert(list, value)
end

local function GetSourceEncounterIDs(specID, sourceID, slotName, itemID)
    local out, seen = {}, {}
    sourceID = tonumber(sourceID)
    itemID = tonumber(itemID)
    if not sourceID then return out end

    local function AddFromItem(item)
        local source = item and item.sources and item.sources[sourceID]
        for _, encounterID in ipairs(source and source.encounterIDs or {}) do
            AddUniqueNumber(out, seen, encounterID)
        end
    end

    if itemID and Mapping().GetItem then
        AddFromItem(Mapping().GetItem(itemID, specID, nil, sourceID))
    elseif Mapping().GetItemsForSpecSource then
        local wantedSlot = Mapping().GetBaseSlotName and Mapping().GetBaseSlotName(slotName) or slotName
        for _, item in ipairs(Mapping().GetItemsForSpecSource(specID, sourceID) or {}) do
            local itemSlot = Mapping().GetBaseSlotName and Mapping().GetBaseSlotName(item.slot) or item.slot
            if itemSlot == wantedSlot then AddFromItem(item) end
        end
    end

    table.sort(out)
    return out
end

local function GetNebulousPlanSources(plan, specID, season)
    local out, seen = {}, {}
    local function AddSource(source)
        local descriptor = SourceDescriptor(source)
        local key = descriptor and tostring(descriptor.sourceID or "")
        if descriptor and descriptor.sourceID and not seen[key] then
            seen[key] = true
            table.insert(out, descriptor)
        end
    end

    for _, source in ipairs(plan.guidanceSources or {}) do AddSource(source) end

    if #out == 0 and plan.itemID and Mapping().GetItemSources then
        for _, source in ipairs(Mapping().GetItemSources(plan.itemID, specID) or {}) do AddSource(source) end
    end

    if #out == 0 and Mapping().GetCatalystSourcesForSlot then
        for _, source in ipairs(Mapping().GetCatalystSourcesForSlot(specID, plan.slotName, season) or {}) do
            AddSource(source)
        end
    end

    table.sort(out, function(a, b)
        if a.sourceType ~= b.sourceType then return a.sourceType == "Dungeon" end
        return tostring(a.name or "") < tostring(b.name or "")
    end)
    return out
end

local function NebulousItemLabel(plan)
    if plan.tierChecked then return "Tier Item", true end
    local target = plan.target
    local name = target and (target.name or target.itemNameClean)
    if name and name ~= "" then return tostring(name), false end
    return "Myth Item", false
end

local function BuildNebulousRollPlan(filters)
    filters = filters or {}
    local state = Analysis.GetDashboardState()
    local specID = tonumber(state and state.specID)
    local currencyCount = tonumber(state and state.resources and state.resources.nebulousVoidcores) or 0
    local sourceFilter = tonumber(filters.sourceID or filters.mapID or filters.instanceID)
    local encounterFilter = tonumber(filters.encounterID)
    local groupsByKey, groups = {}, {}

    if not specID or specID == 0 or currencyCount <= 0 then
        return {
            specID = specID or 0,
            specName = state and state.specName or "Current Spec",
            currencyCount = currencyCount,
            groups = groups,
            itemCount = 0,
        }
    end

    local slotOrder = {}
    for index, slotName in ipairs(Analysis.LeftSlots) do slotOrder[slotName] = index end
    local offset = #Analysis.LeftSlots
    for index, slotName in ipairs(Analysis.RightSlots) do slotOrder[slotName] = offset + index end

    local itemCount = 0
    local seenItems = {}
    local function AddRollItem(slotName, displaySlot, label, isTier, targetItemID, currentItemID, sources)
        local encounterItemID = isTier and nil or (targetItemID or currentItemID)
        for _, source in ipairs(sources or {}) do
            local descriptor = SourceDescriptor(source)
            local sourceID = descriptor and tonumber(descriptor.sourceID)
            if sourceID then
                local encounterIDs = GetSourceEncounterIDs(
                    specID,
                    sourceID,
                    slotName,
                    encounterItemID
                )
                local encounterMatches = not encounterFilter
                if encounterFilter then
                    for _, encounterID in ipairs(encounterIDs) do
                        if encounterID == encounterFilter then encounterMatches = true break end
                    end
                end

                if (not sourceFilter or sourceID == sourceFilter) and encounterMatches then
                    local groupKey = tostring(descriptor.sourceType or "Other") .. ":" .. tostring(sourceID)
                    local group = groupsByKey[groupKey]
                    if not group then
                        group = {
                            sourceID = sourceID,
                            sourceName = descriptor.name,
                            sourceType = descriptor.sourceType,
                            encounterIDs = {},
                            items = {},
                        }
                        groupsByKey[groupKey] = group
                        table.insert(groups, group)
                    end
                    local groupEncounterSeen = {}
                    for _, value in ipairs(group.encounterIDs) do groupEncounterSeen[value] = true end
                    for _, value in ipairs(encounterIDs) do AddUniqueNumber(group.encounterIDs, groupEncounterSeen, value) end

                    local itemKey = groupKey .. ":" .. tostring(slotName) .. ":" .. tostring(label)
                    if not seenItems[itemKey] then
                        seenItems[itemKey] = true
                        table.insert(group.items, {
                            slotName = slotName,
                            displaySlot = displaySlot or slotName,
                            itemName = label,
                            isTier = isTier,
                            targetItemID = targetItemID,
                            currentItemID = currentItemID,
                            encounterIDs = encounterIDs,
                        })
                        itemCount = itemCount + 1
                    end
                end
            end
        end
    end

    for slotName, plan in pairs(state.plansBySlot or {}) do
        if plan.nebulousAvailable == true and not plan.offHandBlocked then
            local label, isTier = NebulousItemLabel(plan)
            AddRollItem(
                plan.slotName,
                plan.displayName,
                label,
                isTier,
                plan.target and plan.target.itemID or nil,
                plan.itemID,
                GetNebulousPlanSources(plan, specID, state.season)
            )
        end
    end

    for _, owned in ipairs(filters.ownedHeroTargets or {}) do
        local slotName = owned.slotInstance or owned.slotName or owned.slot
        local itemID = tonumber(owned.itemID)
        local currentPlan = slotName and state.plansBySlot and state.plansBySlot[slotName]
        local alreadyRepresented = currentPlan
            and currentPlan.nebulousAvailable == true
            and tonumber(currentPlan.target and currentPlan.target.itemID) == itemID
        if slotName and itemID and not alreadyRepresented then
            local isTier = currentPlan and currentPlan.tierChecked == true or false
            local label = isTier and "Tier Item"
                or tostring(owned.name or owned.itemName or owned.itemNameClean or ("Item " .. tostring(itemID)))
            local sources = {}
            if owned.sourceID and Mapping().GetSource then
                local source = Mapping().GetSource(owned.sourceID)
                if source then sources = { source } end
            elseif isTier and Mapping().GetCatalystSourcesForSlot then
                sources = Mapping().GetCatalystSourcesForSlot(specID, slotName, state.season) or {}
            elseif Mapping().GetItemSources then
                sources = Mapping().GetItemSources(itemID, specID) or {}
            end
            AddRollItem(slotName, slotName, label, isTier, itemID, nil, sources)
        end
    end

    table.sort(groups, function(a, b)
        if a.sourceType ~= b.sourceType then return a.sourceType == "Dungeon" end
        return tostring(a.sourceName or "") < tostring(b.sourceName or "")
    end)
    for _, group in ipairs(groups) do
        table.sort(group.encounterIDs)
        table.sort(group.items, function(a, b)
            local orderA = slotOrder[a.slotName] or 99
            local orderB = slotOrder[b.slotName] or 99
            if orderA ~= orderB then return orderA < orderB end
            return tostring(a.itemName or "") < tostring(b.itemName or "")
        end)
    end

    return {
        specID = specID,
        specName = state.specName,
        currencyCount = currencyCount,
        groups = groups,
        itemCount = itemCount,
    }
end

local function GetSavedShoppingItems(getterName)
    local getter = Targets()[getterName]
    if not getter then return {} end
    local specID = select(1, CurrentSpec())
    local out = {}
    for _, item in ipairs(getter(specID) or {}) do
        if item.slotInstance then table.insert(out, item) end
    end
    return out
end

local function FindEquippedItemPlan(itemID, dashboardState)
    itemID = tonumber(itemID)
    if not itemID then return nil end
    for _, plan in pairs(dashboardState and dashboardState.plansBySlot or {}) do
        if tonumber(plan and plan.itemID) == itemID then return plan end
    end
    return nil
end

local function ShoppingItemIsOwned(item, dashboardState, bagItems)
    local itemID = tonumber(item and item.itemID)
    if not itemID then return false end
    if bagItems and bagItems[itemID] then return true end
    return FindEquippedItemPlan(itemID, dashboardState) ~= nil
end

local function BuildCatalystDungeonGroups(dashboardState)
    local groupsByKey, groups = {}, {}
    local slotOrder = {}
    for index, slotName in ipairs(Analysis.LeftSlots or {}) do slotOrder[slotName] = index end
    local offset = #(Analysis.LeftSlots or {})
    for index, slotName in ipairs(Analysis.RightSlots or {}) do slotOrder[slotName] = offset + index end

    for slotName, plan in pairs(dashboardState and dashboardState.plansBySlot or {}) do
        -- Match the Tier guidance used by the Gear Dashboard. Unchecked slots
        -- remain relevant until four pieces are chosen, and checked slots keep
        -- their replacement path while the equipped item is below Myth track.
        local needsTierSource = not plan.target and (plan.tierNeeded == true
            or (plan.tierChecked == true and plan.isMythTrack ~= true))
        if needsTierSource then
            for _, source in ipairs(TierSources(
                dashboardState.specID,
                slotName,
                dashboardState.season
            )) do
                if source.sourceType == "Dungeon" then
                    local key = source.sourceID and ("id:" .. tostring(source.sourceID))
                        or ("name:" .. tostring(source.name or "Dungeon"))
                    local group = groupsByKey[key]
                    if not group then
                        group = {
                            sourceID = source.sourceID,
                            sourceName = source.name,
                            sourceType = "Dungeon",
                            items = {},
                            slotsSeen = {},
                        }
                        groupsByKey[key] = group
                        table.insert(groups, group)
                    end
                    if not group.slotsSeen[slotName] then
                        group.slotsSeen[slotName] = true
                        table.insert(group.items, {
                            slotName = slotName,
                            displaySlot = plan.displayName or slotName,
                            tierChecked = plan.tierChecked == true,
                        })
                    end
                end
            end
        end
    end

    table.sort(groups, function(a, b)
        return tostring(a.sourceName or "") < tostring(b.sourceName or "")
    end)
    for _, group in ipairs(groups) do
        group.slotsSeen = nil
        table.sort(group.items, function(a, b)
            local orderA = slotOrder[a.slotName] or 99
            local orderB = slotOrder[b.slotName] or 99
            if orderA ~= orderB then return orderA < orderB end
            return tostring(a.displaySlot or "") < tostring(b.displaySlot or "")
        end)
    end
    return groups
end

local function BuildGearShoppingPlan(filters)
    filters = filters or {}
    -- The LFG shopping popup must always classify against what is equipped
    -- right now. This also avoids false "still needed" rows after WoW swaps
    -- interchangeable Finger or Trinket slot positions.
    local dashboardState = Analysis.GetDashboardState(true)
    local bagItems = Capture().GetOwnedBagItems and Capture().GetOwnedBagItems() or {}
    local allTargets = GetSavedShoppingItems("GetSavedTargetsForSpec")
    local allAlternatives = GetSavedShoppingItems("GetAllAlternativesForSpec")
    local targets, alternatives, ownedHeroTargets = {}, {}, {}

    for _, item in ipairs(allTargets) do
        if ShoppingItemIsOwned(item, dashboardState, bagItems) then
            local bagRecord = bagItems[tonumber(item.itemID)]
            local equippedPlan = FindEquippedItemPlan(item.itemID, dashboardState)
            -- What the player has equipped is the deciding copy. A lower-track
            -- duplicate in the bags must not make an equipped Myth Target look
            -- eligible for a Nebulous Voidcore roll.
            local ownedTrack = equippedPlan and equippedPlan.trackName
                or bagRecord and bagRecord.track
            if ownedTrack == "Hero" then
                table.insert(ownedHeroTargets, item)
            end
        else
            table.insert(targets, item)
        end
    end
    for _, item in ipairs(allAlternatives) do
        if not ShoppingItemIsOwned(item, dashboardState, bagItems) then
            table.insert(alternatives, item)
        end
    end

    local rollFilters = {}
    for key, value in pairs(filters) do rollFilters[key] = value end
    rollFilters.ownedHeroTargets = ownedHeroTargets

    return {
        specID = dashboardState and dashboardState.specID or 0,
        specName = dashboardState and dashboardState.specName or "Current Spec",
        targets = targets,
        alternatives = alternatives,
        bagItems = bagItems,
        catalystDungeonGroups = BuildCatalystDungeonGroups(dashboardState),
        nebulousRollPlan = BuildNebulousRollPlan(rollFilters),
        ownedTargetCount = #allTargets - #targets,
        ownedAlternativeCount = #allAlternatives - #alternatives,
    }
end

local function BuildProgress(specID, slotsByName)
    local total, equipped = 0, 0
    if not Targets().GetTargetForSlot then return { total = 0, equipped = 0 } end
    for _, slotName in ipairs(Targets().GetSlotOrder and Targets().GetSlotOrder() or {}) do
        local target = Targets().GetTargetForSlot(specID, slotName)
        if target then
            total = total + 1
            local slot = slotsByName[slotName]
            if slot and tonumber(slot.itemID) == tonumber(target.itemID) then equipped = equipped + 1 end
        end
    end
    return { total = total, equipped = equipped }
end

local function EmptyDashboardState(message)
    return {
        itemLevel = nil,
        specID = 0,
        specName = "Current Spec",
        plansBySlot = {},
        tier = { slots = {}, count = 0, complete = false },
        alternatives = {},
        progress = { total = 0, equipped = 0 },
        message = message,
    }
end

local function BuildDashboardState(forceEquipped)
    local specID, specName = CurrentSpec()
    local season = CurrentSeason()
    local resources = GetUpgradeResources()
    local slotsByName = GetEquippedSlots(forceEquipped == true)
    local tierState = TierDB().GetState and TierDB().GetState(season, slotsByName) or { slots = {}, count = 0, complete = false }
    local mainHand = slotsByName["Main Hand"] or EmptySlot("Main Hand")
    local mainHandBlocksOffHand = Capture().IsTwoHandOrRangedWeapon and Capture().IsTwoHandOrRangedWeapon(mainHand)
        and specID ~= 72 and not (slotsByName["Off Hand"] and slotsByName["Off Hand"].itemID)
    local plansBySlot = {}

    local function AnalyzeSlot(slotName)
        plansBySlot[slotName] = BuildSlotPlan(
            slotName,
            slotsByName[slotName] or EmptySlot(slotName),
            GetTarget(specID, slotName),
            tierState,
            specID,
            season,
            slotName == "Off Hand" and mainHandBlocksOffHand,
            resources
        )
    end

    for _, slotName in ipairs(Analysis.LeftSlots) do AnalyzeSlot(slotName) end
    for _, slotName in ipairs(Analysis.RightSlots) do AnalyzeSlot(slotName) end

    return {
        itemLevel = GetEquippedItemLevel(),
        specID = specID,
        specName = specName,
        season = season,
        plansBySlot = plansBySlot,
        slotStates = plansBySlot,
        tier = tierState,
        resources = resources,
        alternatives = BuildAlternatives(specID),
        progress = BuildProgress(specID, slotsByName),
    }
end

function Analysis.GetDashboardState(forceEquipped)
    if dashboardStateBusy then return lastDashboardState or EmptyDashboardState("Refreshing") end
    dashboardStateBusy = true
    local ok, state = pcall(BuildDashboardState, forceEquipped == true)
    dashboardStateBusy = false
    if ok and type(state) == "table" then
        lastDashboardState = state
        return state
    end
    return lastDashboardState or EmptyDashboardState("Gear Dashboard could not refresh yet.")
end

function Analysis.GetNebulousRollPlan(filters)
    return BuildNebulousRollPlan(filters)
end

function Analysis.GetGearShoppingPlan(filters)
    return BuildGearShoppingPlan(filters)
end

function Analysis.InvalidateCache()
    lastDashboardState = nil
    dashboardStateBusy = false
end

function Analysis.GetTrackRank(trackName)
    return GearingDB().GetTrackRank and GearingDB().GetTrackRank(trackName) or 0
end

function Analysis.GetLogicSummary()
    local ascendantItemName = tostring((GearingDB().Voidforge or {}).ascendantItemName or "Ascendant upgrade item")
    return {
        "The dashboard uses equipped gear, saved Targets, saved Alternatives, and automatic item-ID classification.",
        "Known native Tier set pieces automatically advance the 2/4-piece display; native Tier off-pieces do not count toward the set bonus.",
        "Hero-track Tier pieces keep broad Dungeon guidance or Target-specific Dungeon/Raid guidance until they reach Myth.",
        "Known crafted item IDs are labeled Crafted. Equipped IDs outside both databases are labeled Other Item.",
        "Other Items receive no upgrade, Catalyst, or Nebulous guidance; a saved Target may still show its specific source.",
        "Nebulous availability appears for eligible known non-crafted Hero-track items when a Nebulous Voidcore is owned, regardless of current upgrade rank.",
        "Ascendant availability appears only for a fully upgraded 6/6 Hero- or Myth-track eligible weapon or trinket when an " .. ascendantItemName .. " is owned.",
        "Ascendant Voidforged weapons and trinkets retain their Hero or Myth base track at the upgraded item level.",
        "A saved Target always overrides broad Catalyst-source guidance for its Tier slot and keeps its specific item and source visible on the dashboard.",
        "No item scoring, priority-slot scoring, polish reminders, or overall gear score is calculated.",
    }
end

function Analysis.GetGearDebugRows()
    local state = Analysis.GetDashboardState()
    local rows = {}
    for _, slotName in ipairs(Analysis.LeftSlots) do table.insert(rows, state.plansBySlot[slotName]) end
    for _, slotName in ipairs(Analysis.RightSlots) do table.insert(rows, state.plansBySlot[slotName]) end
    return rows, state
end

function Analysis.PrintGearDebug()
    local rows, state = Analysis.GetGearDebugRows()
    KeyLabDB = KeyLabDB or {}
    KeyLabDB.gearDashboardDebug = {
        capturedAt = time and time() or 0,
        itemLevel = state.itemLevel,
        specID = state.specID,
        tier = state.tier,
        progress = state.progress,
        rows = {},
    }
    for _, row in ipairs(rows) do
        table.insert(KeyLabDB.gearDashboardDebug.rows, {
            slotName = row.slotName,
            itemID = row.itemID,
            itemLevel = row.itemLevel,
            track = row.trackName,
            rank = row.rankText,
            tierBadge = row.tierBadge,
            classification = row.classificationKey,
            action = row.actionText,
            craftedItem = row.craftedItem,
            nativeTierOffPiece = row.nativeTierOffPiece,
            otherItem = row.otherItem,
            catalystItem = row.catalystItem,
            voidforgedItem = row.voidforgedItem,
            voidforgeAvailable = row.voidforgeAvailable,
            nebulousAvailable = row.nebulousAvailable,
            sourceCount = #(row.guidanceSources or {}),
        })
    end
    local printFn = KeyLab.Print or print
    printFn("Gear Dashboard debug saved to KeyLabDB.gearDashboardDebug.")
end

return Analysis
