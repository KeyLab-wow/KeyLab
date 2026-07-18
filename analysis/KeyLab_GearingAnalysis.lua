-- KeyLab_GearingAnalysis.lua
-- Builds the Gear Dashboard from equipped gear, manual Tier choices, and saved targets.

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

local function GetEquippedSlots()
    local names = {}
    for _, slotName in ipairs(Analysis.LeftSlots) do table.insert(names, slotName) end
    for _, slotName in ipairs(Analysis.RightSlots) do table.insert(names, slotName) end
    if Capture().GetEquippedSlots then return Capture().GetEquippedSlots(names) or {} end
    local out = {}
    for _, slotName in ipairs(names) do
        out[slotName] = Capture().GetEquippedSlot and Capture().GetEquippedSlot(slotName) or EmptySlot(slotName)
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
    item = item or { itemID = record.itemID, name = "Item " .. tostring(record.itemID) }
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
            if descriptor then table.insert(out, descriptor) end
        end
    end
    return out
end

local function IsMasterDatabaseItem(itemID)
    itemID = tonumber(itemID)
    if not itemID then return false end
    local db = KeyLab and KeyLab.GearLootDatabase
    if not db or type(db.items) ~= "table" then return nil end
    return db.items[itemID] ~= nil
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
    if level and track and track ~= "" then return tostring(math.floor(level + 0.5)) .. " " .. tostring(track) end
    if level then return tostring(math.floor(level + 0.5)) end
    return tostring(track or "")
end

local function RankText(slot)
    local rank = tonumber(slot and slot.upgradeRank)
    local maxRank = tonumber(slot and (slot.upgradeMaxRank or slot.upgradeMax))
    if rank and maxRank then return tostring(rank) .. "/" .. tostring(maxRank) end
    return ""
end

local function BuildSlotPlan(slotName, slot, target, tierState, specID, season, offHandBlocked)
    slot = slot or EmptySlot(slotName)
    local tierEligible = TIER_SLOTS[slotName] == true
    local tierChecked = tierEligible and tierState.slots and tierState.slots[slotName] == true or false
    local tierNeeded = tierEligible and not tierChecked and not tierState.complete
    local targetEquipped = target and tonumber(target.itemID) == tonumber(slot.itemID) or false
    local masterDatabaseItem = IsMasterDatabaseItem(slot.itemID)
    local craftedItem = slot.itemID and (slot.isCrafted == true or slot.craftedDetected == true or masterDatabaseItem == false) or false
    local voidforgedItem = slot.voidforgedDetected == true or slot.ascendantVoidforgedDetected == true
    local voidforgeAvailable = not voidforgedItem and slot.voidforgeCandidate == true
    local isMythTrack = tostring(slot.upgradeTrack or slot.trackName or "") == "Myth"
    local upgradeAction = UpgradeAction(slot)
    local action

    if offHandBlocked then
        action = "Not used with equipped weapon"
    elseif tierNeeded then
        action = slot.itemID and "Catalyst for Tier" or "Find a Tier base item"
    elseif tierChecked then
        action = upgradeAction or ""
    elseif craftedItem then
        action = "Crafted Item"
    elseif voidforgedItem then
        action = "Ascendant Voidforged"
    elseif voidforgeAvailable then
        action = "Ascendant Voidforge Available"
    elseif upgradeAction then
        action = upgradeAction
    elseif target then
        action = targetEquipped and "Target Equipped" or ("Target: " .. ShortName(target.name or target.itemNameClean, 24))
    elseif slot.itemID then
        action = "No saved target"
    else
        action = "No item equipped"
    end

    local guidanceSources = {}
    local sourceLabel = ""
    if tierNeeded then
        guidanceSources = TierSources(specID, slotName, season)
        sourceLabel = "Tier Sources:"
    elseif not tierChecked and not craftedItem and not isMythTrack and target then
        guidanceSources = target.sourcesForDashboard or {}
        sourceLabel = #guidanceSources == 1 and "Target Source:" or "Target Sources:"
    end

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
        actionText = action,
        tierEligible = tierEligible,
        tierChecked = tierChecked,
        tierNeeded = tierNeeded,
        tierBadge = tierChecked and "Tier" or (tierNeeded and "Need Tier" or ""),
        target = target,
        targetEquipped = targetEquipped,
        masterDatabaseItem = masterDatabaseItem,
        craftedItem = craftedItem,
        voidforgedItem = voidforgedItem,
        voidforgeAvailable = voidforgeAvailable,
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

local function BuildDashboardState()
    local specID, specName = CurrentSpec()
    local season = CurrentSeason()
    local tierState = TierDB().GetState and TierDB().GetState(season) or { slots = {}, count = 0, complete = false }
    local slotsByName = GetEquippedSlots()
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
            slotName == "Off Hand" and mainHandBlocksOffHand
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
        alternatives = BuildAlternatives(specID),
        progress = BuildProgress(specID, slotsByName),
    }
end

function Analysis.GetDashboardState()
    if dashboardStateBusy then return lastDashboardState or EmptyDashboardState("Refreshing") end
    dashboardStateBusy = true
    local ok, state = pcall(BuildDashboardState)
    dashboardStateBusy = false
    if ok and type(state) == "table" then
        lastDashboardState = state
        return state
    end
    return lastDashboardState or EmptyDashboardState("Gear Dashboard could not refresh yet.")
end

function Analysis.InvalidateCache()
    lastDashboardState = nil
    dashboardStateBusy = false
end

function Analysis.GetTrackRank(trackName)
    return GearingDB().GetTrackRank and GearingDB().GetTrackRank(trackName) or 0
end

function Analysis.GetLogicSummary()
    return {
        "The dashboard uses equipped gear, saved Targets, saved Alternatives, and the manual Tier Set checklist.",
        "Tier guidance has source priority until four manually selected Tier slots are complete.",
        "Checked Tier slots show only their remaining track upgrade, without Target or Catalyst source guidance.",
        "Items outside the Master Item Database are treated as crafted and do not receive track-upgrade guidance.",
        "Ascendant Voidforged weapons and trinkets retain their Hero or Myth base track at the upgraded item level.",
        "Saved Target sources are shown after Tier guidance is complete or not relevant, and are hidden once the equipped item is Myth track.",
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
            action = row.actionText,
            craftedItem = row.craftedItem,
            voidforgedItem = row.voidforgedItem,
            voidforgeAvailable = row.voidforgeAvailable,
            sourceCount = #(row.guidanceSources or {}),
        })
    end
    local printFn = KeyLab.Print or print
    printFn("Gear Dashboard debug saved to KeyLabDB.gearDashboardDebug.")
end

return Analysis
