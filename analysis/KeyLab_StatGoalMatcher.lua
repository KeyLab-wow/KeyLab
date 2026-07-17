local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.StatGoalMatcher = KeyLab.StatGoalMatcher or {}
local Matcher = KeyLab.StatGoalMatcher

Matcher.Config = Matcher.Config or {
    exactCombinationLimit = 150000,
    beamWidth = 1200,
    workPerFrame = 500,
}

local EXACT_COMBINATION_LIMIT = tonumber(Matcher.Config.exactCombinationLimit) or 150000
local BEAM_WIDTH = tonumber(Matcher.Config.beamWidth) or 1200
local WORK_PER_FRAME = tonumber(Matcher.Config.workPerFrame) or 500

local SLOT_ORDER = {
    "Head", "Neck", "Shoulders", "Back", "Chest", "Wrist", "Hands", "Waist",
    "Legs", "Feet", "Finger 1", "Finger 2", "Trinket 1", "Trinket 2", "Main Hand", "Off Hand",
}

local SECONDARY = { "Crit", "Haste", "Mastery", "Vers" }
local GOAL_KEYS = { Crit = "crit", Haste = "haste", Mastery = "mastery", Vers = "versatility" }
local activeJob

local function GetSavedResults()
    KeyLabDB = type(KeyLabDB) == "table" and KeyLabDB or {}
    if type(KeyLabDB.statGoalMatcherResults) ~= "table" then KeyLabDB.statGoalMatcherResults = {} end
    return KeyLabDB.statGoalMatcherResults
end

local function ZeroStats()
    return { Crit = 0, Haste = 0, Mastery = 0, Vers = 0 }
end

local function CopyStats(source)
    local out = ZeroStats()
    for _, key in ipairs(SECONDARY) do out[key] = tonumber(source and source[key]) or 0 end
    return out
end

local function AddStats(left, right)
    local out = ZeroStats()
    for _, key in ipairs(SECONDARY) do out[key] = (tonumber(left and left[key]) or 0) + (tonumber(right and right[key]) or 0) end
    return out
end

local function StatsTotal(stats)
    local total = 0
    for _, key in ipairs(SECONDARY) do total = total + (tonumber(stats and stats[key]) or 0) end
    return total
end

local function StatsSignature(stats)
    return table.concat({
        tostring(tonumber(stats and stats.Crit) or 0),
        tostring(tonumber(stats and stats.Haste) or 0),
        tostring(tonumber(stats and stats.Mastery) or 0),
        tostring(tonumber(stats and stats.Vers) or 0),
    }, ":")
end

local function CopyTable(source)
    local out = {}
    for key, value in pairs(source or {}) do out[key] = value end
    return out
end

local function CopyArray(source)
    local out = {}
    for _, value in ipairs(source or {}) do table.insert(out, value) end
    return out
end

local function GetGoals(specID)
    local saved = KeyLab.StatGoalsDB and KeyLab.StatGoalsDB.GetGoals and KeyLab.StatGoalsDB.GetGoals(specID) or {}
    local goals = {}
    for _, key in ipairs(SECONDARY) do goals[key] = tonumber(saved.targets and saved.targets[GOAL_KEYS[key]]) or 0 end
    return goals
end

local function Score(stats, goals)
    local total = StatsTotal(stats)
    if total <= 0 then return math.huge, math.huge end
    local difference, largest = 0, 0
    for _, key in ipairs(SECONDARY) do
        local share = ((tonumber(stats[key]) or 0) / total) * 100
        local deviation = math.abs(share - (tonumber(goals[key]) or 0))
        difference = difference + deviation
        if deviation > largest then largest = deviation end
    end
    return difference, largest
end

local function IsBetter(candidate, current, goals)
    if not candidate then return false end
    if not current then return true end
    local candidateDifference, candidateLargest = Score(candidate.stats, goals)
    local currentDifference, currentLargest = Score(current.stats, goals)
    if math.abs(candidateDifference - currentDifference) > 0.000001 then return candidateDifference < currentDifference end
    if math.abs(candidateLargest - currentLargest) > 0.000001 then return candidateLargest < currentLargest end
    return tostring(candidate.key or "") < tostring(current.key or "")
end

local function ItemStats(item, specID)
    local mapping = KeyLab.GearLootMapping
    return mapping and mapping.GetItemStats and CopyStats(mapping.GetItemStats(item, specID)) or ZeroStats()
end

local function AddUniqueID(list, seen, itemID)
    itemID = tonumber(itemID)
    if not itemID or seen[itemID] then return end
    seen[itemID] = true
    table.insert(list, itemID)
end

local function SortIDs(list)
    table.sort(list, function(a, b) return tonumber(a or 0) < tonumber(b or 0) end)
end

local function GroupSingleSlotItems(slotInstance, items, specID)
    local groups = {}
    for _, item in ipairs(items or {}) do
        local stats = ItemStats(item, specID)
        if StatsTotal(stats) > 0 then
            local signature = StatsSignature(stats)
            local group = groups[signature]
            if not group then
                group = {
                    stats = stats,
                    itemIDs = {},
                    itemSeen = {},
                    sourceID = item.sourceID,
                }
                groups[signature] = group
            end
            AddUniqueID(group.itemIDs, group.itemSeen, item.itemID)
        end
    end

    local options = {}
    for signature, group in pairs(groups) do
        SortIDs(group.itemIDs)
        local representative = group.itemIDs[1]
        table.insert(options, {
            stats = group.stats,
            key = slotInstance .. ":" .. signature .. ":" .. tostring(representative),
            assignments = {
                {
                    slotInstance = slotInstance,
                    itemID = representative,
                    sourceID = group.sourceID,
                    equivalentItemIDs = group.itemIDs,
                },
            },
        })
    end
    table.sort(options, function(a, b) return tostring(a.key) < tostring(b.key) end)
    return options
end

local function GetLiveItemStats(itemLink, tooltipLines)
    local out = ZeroStats()
    if itemLink and C_Item and C_Item.GetItemStats then
        local ok, values = pcall(C_Item.GetItemStats, itemLink)
        if ok and type(values) == "table" then
            for rawKey, rawValue in pairs(values) do
                local key = string.upper(tostring(rawKey or ""))
                local value = tonumber(rawValue) or 0
                if key:find("CRIT", 1, true) and key:find("RATING", 1, true) then out.Crit = math.max(out.Crit, value) end
                if key:find("HASTE", 1, true) and key:find("RATING", 1, true) then out.Haste = math.max(out.Haste, value) end
                if key:find("MASTERY", 1, true) and key:find("RATING", 1, true) then out.Mastery = math.max(out.Mastery, value) end
                if key:find("VERSATILITY", 1, true) and key:find("RATING", 1, true) then out.Vers = math.max(out.Vers, value) end
            end
        end
    end

    local labels = {
        Crit = { "critical strike", "crit" },
        Haste = { "haste" },
        Mastery = { "mastery" },
        Vers = { "versatility" },
    }
    for _, line in ipairs(tooltipLines or {}) do
        local clean = tostring(line or ""):gsub(",", "")
        local lower = string.lower(clean)
        local amount = tonumber(clean:match("([%+%-]?%d+)%s")) or 0
        if amount > 0 then
            for statKey, aliases in pairs(labels) do
                for _, alias in ipairs(aliases) do
                    if lower:find(alias, 1, true) then
                        out[statKey] = math.max(out[statKey], amount)
                        break
                    end
                end
            end
        end
    end
    return out
end

local function CurrentSpecID()
    return KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.GetCurrentSpecID and KeyLab.LootTargetsDB.GetCurrentSpecID() or 0
end

local function ScanEquipment(specID)
    local capture = KeyLab.GearCapture
    local mapping = KeyLab.GearLootMapping
    local snapshot = {
        slots = {},
        lockedStats = ZeroStats(),
        recognized = {},
    }

    for _, slotInstance in ipairs(SLOT_ORDER) do
        local slot = capture and capture.GetEquippedSlot and capture.GetEquippedSlot(slotInstance, true) or { slotName = slotInstance }
        snapshot.slots[slotInstance] = slot
        if slot and slot.itemID then
            snapshot.lockedStats = AddStats(snapshot.lockedStats, GetLiveItemStats(slot.itemLink or slot.link, slot.tooltipLinesRaw))
            local item = mapping and mapping.GetItem and mapping.GetItem(slot.itemID, specID) or nil
            if item and mapping.IsItemEligibleForSpec(item, specID) and mapping.IsCurrentSeasonItem(item) then
                table.insert(snapshot.recognized, {
                    itemID = tonumber(slot.itemID),
                    slotInstance = slotInstance,
                    sourceID = item.sourceID,
                })
            end
        end
    end
    return snapshot
end

local function SyncRecognizedTargets(specID, recognized)
    local targets = KeyLab.LootTargetsDB
    if not targets or not targets.SetTargetForSlot then return end
    for _, record in ipairs(recognized or {}) do
        targets.SetTargetForSlot(specID, record.itemID, record.slotInstance, record.sourceID, true)
    end
end

local function ItemCanFill(item, slotInstance)
    for _, eligible in ipairs(item.eligibleSlotInstances or {}) do
        if eligible == slotInstance then return true end
    end
    return false
end

local function PartitionCandidates(specID, itemType)
    local mapping = KeyLab.GearLootMapping
    local candidates = mapping and mapping.GetMatcherCandidates and mapping.GetMatcherCandidates(specID, itemType) or {}
    local bySlot = {}
    local mainWeapons, offHandItems, dualWeapons = {}, {}, {}
    for _, item in ipairs(candidates) do
        for _, slotInstance in ipairs(item.eligibleSlotInstances or {}) do
            bySlot[slotInstance] = bySlot[slotInstance] or {}
            table.insert(bySlot[slotInstance], item)
        end
        if item.slot == "One-Hand" or item.slot == "Two-Hand" or item.slot == "Ranged" then
            table.insert(mainWeapons, item)
            if item.dualWieldEligible then table.insert(dualWeapons, item) end
        elseif item.slot == "Off Hand" then
            table.insert(offHandItems, item)
        end
    end
    return bySlot, mainWeapons, offHandItems, dualWeapons
end

local function CompactWeaponItems(items, specID, category)
    local groups = {}
    for _, item in ipairs(items or {}) do
        local stats = ItemStats(item, specID)
        if StatsTotal(stats) > 0 then
            local signature = tostring(category or item.slot) .. ":" .. tostring(item.slot) .. ":" .. tostring(item.dualWieldEligible == true) .. ":" .. StatsSignature(stats)
            local group = groups[signature]
            if not group then
                group = { item = item, stats = stats, itemIDs = {}, seen = {} }
                groups[signature] = group
            end
            AddUniqueID(group.itemIDs, group.seen, item.itemID)
            if tonumber(item.itemID) < tonumber(group.item.itemID) then group.item = item end
        end
    end
    local out = {}
    for signature, group in pairs(groups) do
        SortIDs(group.itemIDs)
        group.signature = signature
        table.insert(out, group)
    end
    table.sort(out, function(a, b) return tostring(a.signature) < tostring(b.signature) end)
    return out
end

local function WeaponAssignment(slotInstance, group)
    return {
        slotInstance = slotInstance,
        itemID = tonumber(group.item.itemID),
        sourceID = group.item.sourceID,
        equivalentItemIDs = group.itemIDs,
    }
end

local function BuildWeaponOptions(specID, snapshot, mainWeapons, offHandItems, dualWeapons)
    local mainEquipped = snapshot.slots["Main Hand"] and snapshot.slots["Main Hand"].itemID
    local offEquipped = snapshot.slots["Off Hand"] and snapshot.slots["Off Hand"].itemID
    if mainEquipped and offEquipped then return nil end

    local mapping = KeyLab.GearLootMapping
    local compactMain = CompactWeaponItems(mainWeapons, specID, "main")
    local compactOff = CompactWeaponItems(offHandItems, specID, "off")
    local compactDual = CompactWeaponItems(dualWeapons, specID, "dual")
    local options = {}

    if mainEquipped and not offEquipped then
        local mainSlot = snapshot.slots["Main Hand"]
        local knownDual = mapping and mapping.IsDualWieldEligible and mapping.IsDualWieldEligible(mainEquipped, specID)
        local closesOffHand = mainSlot and KeyLab.GearCapture and KeyLab.GearCapture.IsTwoHandOrRangedWeapon
            and KeyLab.GearCapture.IsTwoHandOrRangedWeapon(mainSlot) and not knownDual
        if closesOffHand then return nil end
        for _, group in ipairs(compactOff) do
            table.insert(options, {
                stats = group.stats,
                key = "offitem:" .. group.signature,
                assignments = { WeaponAssignment("Off Hand", group) },
            })
        end
        if knownDual then
            for _, group in ipairs(compactDual) do
                table.insert(options, {
                    stats = group.stats,
                    key = "offweapon:" .. group.signature,
                    assignments = { WeaponAssignment("Off Hand", group) },
                })
            end
        end
        -- Dual-wield support is optional. Keeping the equipped Main Hand by
        -- itself remains a valid complete weapon configuration.
        table.insert(options, { stats = ZeroStats(), key = "keep-main-only", assignments = {} })
    elseif not mainEquipped and offEquipped then
        local offKnownDual = mapping and mapping.IsDualWieldEligible and mapping.IsDualWieldEligible(offEquipped, specID)
        for _, group in ipairs(compactMain) do
            if group.item.slot == "One-Hand" or (offKnownDual and group.item.dualWieldEligible) then
                table.insert(options, {
                    stats = group.stats,
                    key = "mainkeeper:" .. group.signature,
                    assignments = { WeaponAssignment("Main Hand", group) },
                })
            end
        end
    else
        for _, group in ipairs(compactMain) do
            table.insert(options, {
                stats = group.stats,
                key = "mainonly:" .. group.signature,
                assignments = { WeaponAssignment("Main Hand", group) },
            })
        end
        local oneHandMain = {}
        for _, group in ipairs(compactMain) do if group.item.slot == "One-Hand" then table.insert(oneHandMain, group) end end
        for _, mainGroup in ipairs(oneHandMain) do
            for _, offGroup in ipairs(compactOff) do
                table.insert(options, {
                    stats = AddStats(mainGroup.stats, offGroup.stats),
                    key = "mainoff:" .. mainGroup.signature .. ":" .. offGroup.signature,
                    assignments = {
                        WeaponAssignment("Main Hand", mainGroup),
                        WeaponAssignment("Off Hand", offGroup),
                    },
                })
            end
        end
        for mainIndex, mainGroup in ipairs(compactDual) do
            for offIndex = mainIndex, #compactDual do
                local offGroup = compactDual[offIndex]
                table.insert(options, {
                    stats = AddStats(mainGroup.stats, offGroup.stats),
                    key = "dual:" .. mainGroup.signature .. ":" .. offGroup.signature,
                    assignments = {
                        WeaponAssignment("Main Hand", mainGroup),
                        WeaponAssignment("Off Hand", offGroup),
                    },
                })
            end
        end
    end

    table.sort(options, function(a, b) return tostring(a.key) < tostring(b.key) end)
    if #options == 0 then return nil end
    return { name = "Weapon Configuration", options = options, visibleOrder = 15 }
end

local function CountDistinctItems(firstList, secondList)
    local seen, count = {}, 0
    for _, list in ipairs({ firstList or {}, secondList or {} }) do
        for _, item in ipairs(list) do
            local itemID = tonumber(item and item.itemID)
            if itemID and not seen[itemID] then
                seen[itemID] = true
                count = count + 1
            end
        end
    end
    return count
end

local function BuildPositions(specID, itemType, snapshot)
    local bySlot, mainWeapons, offHandItems, dualWeapons = PartitionCandidates(specID, itemType)
    local positions, unmatchedSlots, skipSlot = {}, {}, {}

    -- Two open ring or trinket slots normally share the same candidate list.
    -- If the selected pool contains only one distinct item, filling the second
    -- slot would reject every otherwise-valid combination as a duplicate.
    for _, pair in ipairs({ { "Finger 1", "Finger 2" }, { "Trinket 1", "Trinket 2" } }) do
        local first, second = pair[1], pair[2]
        local firstOpen = not (snapshot.slots[first] and snapshot.slots[first].itemID)
        local secondOpen = not (snapshot.slots[second] and snapshot.slots[second].itemID)
        if firstOpen and secondOpen and CountDistinctItems(bySlot[first], bySlot[second]) == 1 then
            skipSlot[second] = true
        end
    end

    for order, slotInstance in ipairs(SLOT_ORDER) do
        if slotInstance ~= "Main Hand" and slotInstance ~= "Off Hand" then
            local equipped = snapshot.slots[slotInstance] and snapshot.slots[slotInstance].itemID
            if not equipped then
                if skipSlot[slotInstance] then
                    table.insert(unmatchedSlots, slotInstance)
                else
                    local options = GroupSingleSlotItems(slotInstance, bySlot[slotInstance], specID)
                    if #options > 0 then
                        table.insert(positions, { name = slotInstance, options = options, visibleOrder = order })
                    else
                        table.insert(unmatchedSlots, slotInstance)
                    end
                end
            end
        end
    end
    local weaponPosition = BuildWeaponOptions(specID, snapshot, mainWeapons, offHandItems, dualWeapons)
    if weaponPosition then table.insert(positions, weaponPosition) end
    local mainOpen = not (snapshot.slots["Main Hand"] and snapshot.slots["Main Hand"].itemID)
    if mainOpen and not weaponPosition then table.insert(unmatchedSlots, "Main Hand") end
    table.sort(positions, function(a, b)
        if #a.options ~= #b.options then return #a.options < #b.options end
        return tonumber(a.visibleOrder or 99) < tonumber(b.visibleOrder or 99)
    end)
    return positions, unmatchedSlots
end

local function EstimateCombinations(positions)
    local total = 1
    for _, position in ipairs(positions or {}) do
        total = total * math.max(1, #position.options)
        if total > 1000000000 then return 1000000000 end
    end
    return total
end

local function AssignmentKind(slotInstance)
    if slotInstance == "Finger 1" or slotInstance == "Finger 2" then return "Finger" end
    if slotInstance == "Trinket 1" or slotInstance == "Trinket 2" then return "Trinket" end
    return nil
end

local function ResolveOption(state, option)
    local assignments = {}
    local usedJewelry = CopyTable(state.usedJewelry)
    for _, sourceAssignment in ipairs(option.assignments or {}) do
        local assignment = CopyTable(sourceAssignment)
        assignment.equivalentItemIDs = CopyArray(sourceAssignment.equivalentItemIDs)
        local kind = AssignmentKind(assignment.slotInstance)
        if kind then
            usedJewelry[kind] = CopyTable(usedJewelry[kind])
            local chosen
            for _, itemID in ipairs(assignment.equivalentItemIDs or {}) do
                if not usedJewelry[kind][tonumber(itemID)] then chosen = tonumber(itemID); break end
            end
            if not chosen then return nil end
            assignment.itemID = chosen
            usedJewelry[kind][chosen] = true
        end
        table.insert(assignments, assignment)
    end
    return assignments, usedJewelry
end

local function CombineState(state, option)
    local assignments, usedJewelry = ResolveOption(state, option)
    if not assignments then return nil end
    local combinedAssignments = CopyArray(state.assignments)
    for _, assignment in ipairs(assignments) do table.insert(combinedAssignments, assignment) end
    return {
        stats = AddStats(state.stats, option.stats),
        assignments = combinedAssignments,
        usedJewelry = usedJewelry,
        key = tostring(state.key or "") .. "|" .. tostring(option.key or ""),
    }
end

local function YieldWork(job, completed, total, mode)
    job.operations = (job.operations or 0) + 1
    if job.cancelled then error("cancelled") end
    if job.operations % WORK_PER_FRAME == 0 then
        coroutine.yield({ completed = completed or job.operations, total = total, mode = mode })
    end
end

local function RunExact(job, positions, initialState, goals, estimate)
    local best
    local completed = 0
    local function Walk(index, state)
        if index > #positions then
            completed = completed + 1
            if IsBetter(state, best, goals) then best = state end
            YieldWork(job, completed, estimate, "Exact")
            return
        end
        for _, option in ipairs(positions[index].options) do
            local nextState = CombineState(state, option)
            if nextState then Walk(index + 1, nextState) end
        end
    end
    Walk(1, initialState)
    return best
end

local function RunBeam(job, positions, initialState, goals)
    local states = { initialState }
    for positionIndex, position in ipairs(positions) do
        local nextStates = {}
        local function Trim(limit)
            table.sort(nextStates, function(a, b) return IsBetter(a, b, goals) end)
            while #nextStates > limit do table.remove(nextStates) end
        end
        for _, state in ipairs(states) do
            for _, option in ipairs(position.options) do
                local nextState = CombineState(state, option)
                if nextState then table.insert(nextStates, nextState) end
                if #nextStates >= BEAM_WIDTH * 4 then Trim(BEAM_WIDTH * 2) end
                YieldWork(job, positionIndex, #positions, "Bounded")
            end
        end
        Trim(BEAM_WIDTH)
        states = nextStates
        coroutine.yield({ completed = positionIndex, total = #positions, mode = "Bounded" })
    end
    local best
    for _, state in ipairs(states) do if IsBetter(state, best, goals) then best = state end end
    return best
end

local function BuildResult(specID, itemType, best, goals, estimate, mode, positions, unmatchedSlots)
    if not best then return nil end
    local matchedItems = {}
    for _, assignment in ipairs(best.assignments or {}) do
        for _, itemID in ipairs(assignment.equivalentItemIDs or { assignment.itemID }) do matchedItems[tonumber(itemID)] = true end
    end
    local difference, largest = Score(best.stats, goals)
    return {
        specID = specID,
        itemType = itemType,
        completedAt = time and time() or 0,
        matchedItems = matchedItems,
        assignments = best.assignments,
        finalStats = best.stats,
        difference = difference,
        largestDeviation = largest,
        estimatedCombinations = estimate,
        mode = mode,
        openPositionCount = #positions,
        matchedSlotCount = #(best.assignments or {}),
        unmatchedOpenSlots = CopyArray(unmatchedSlots),
    }
end

local function RunJob(job)
    local specID = job.specID
    local valid, message = KeyLab.StatGoalsDB and KeyLab.StatGoalsDB.Validate and KeyLab.StatGoalsDB.Validate(specID)
    if not valid then return { ok = false, message = message or "Stat goals must total exactly 100%." } end

    local snapshot = ScanEquipment(specID)
    local positions, unmatchedSlots = BuildPositions(specID, job.itemType, snapshot)
    if #positions == 0 then
        if #unmatchedSlots > 0 then
            return {
                ok = false,
                message = "The selected item pool has no eligible candidates for: " .. table.concat(unmatchedSlots, ", ") .. ". Try Dungeon & Raid Items or unequip a different slot.",
            }
        end
        return { ok = false, message = "Unequip one or more eligible items to open slots for the Stat Goal Matcher." }
    end

    SyncRecognizedTargets(specID, snapshot.recognized)
    local goals = GetGoals(specID)
    local estimate = EstimateCombinations(positions)
    local initialState = { stats = snapshot.lockedStats, assignments = {}, usedJewelry = {}, key = "" }
    local mode = estimate <= EXACT_COMBINATION_LIMIT and "Exact" or "Bounded"
    local best
    if mode == "Exact" then
        best = RunExact(job, positions, initialState, goals, estimate)
    else
        best = RunBeam(job, positions, initialState, goals)
    end
    if job.cancelled then return { ok = false, cancelled = true, message = "Matcher cancelled." } end
    local result = BuildResult(specID, job.itemType, best, goals, estimate, mode, positions, unmatchedSlots)
    if not result then return { ok = false, message = "No valid item combination was found for the open slots." } end
    return { ok = true, result = result }
end

function Matcher.Start(options, onProgress, onComplete)
    options = options or {}
    if activeJob then return false, "The Stat Goal Matcher is already calculating." end
    local specID = tonumber(options.specID or CurrentSpecID()) or 0
    local job = {
        specID = specID,
        itemType = options.itemType,
        onProgress = onProgress,
        onComplete = onComplete,
        operations = 0,
        cancelled = false,
    }
    activeJob = job
    job.thread = coroutine.create(function() return RunJob(job) end)

    local function Finish(payload)
        activeJob = nil
        if payload and payload.ok and payload.result then GetSavedResults()[specID] = payload.result end
        if job.onComplete then job.onComplete(payload or { ok = false, message = "Matcher stopped unexpectedly." }) end
    end

    local function Step()
        if activeJob ~= job then return end
        local ok, payload = coroutine.resume(job.thread)
        if not ok then
            if tostring(payload) == "cancelled" or job.cancelled then
                Finish({ ok = false, cancelled = true, message = "Matcher cancelled." })
            else
                Finish({ ok = false, message = "The Stat Goal Matcher could not finish: " .. tostring(payload) })
            end
            return
        end
        if coroutine.status(job.thread) == "dead" then Finish(payload); return end
        if job.onProgress then job.onProgress(payload or {}) end
        if C_Timer and C_Timer.After then C_Timer.After(0, Step) else Step() end
    end

    Step()
    return true
end

function Matcher.Cancel()
    if not activeJob then return false end
    activeJob.cancelled = true
    return true
end

function Matcher.IsRunning()
    return activeJob ~= nil
end

function Matcher.GetResult(specID)
    return GetSavedResults()[tonumber(specID or CurrentSpecID()) or 0]
end

function Matcher.GetCurrentShares()
    local capture = KeyLab.GearCapture
    local equipped = capture and capture.GetEquippedSlots and capture.GetEquippedSlots(SLOT_ORDER) or {}
    local stats = ZeroStats()
    for _, slotInstance in ipairs(SLOT_ORDER) do
        local slot = equipped[slotInstance]
        if slot and slot.itemID then
            stats = AddStats(stats, GetLiveItemStats(slot.itemLink or slot.link, slot.tooltipLinesRaw))
        end
    end
    local total = StatsTotal(stats)
    local shares = { crit = 0, haste = 0, mastery = 0, versatility = 0 }
    if total > 0 then
        shares.crit = (stats.Crit / total) * 100
        shares.haste = (stats.Haste / total) * 100
        shares.mastery = (stats.Mastery / total) * 100
        shares.versatility = (stats.Vers / total) * 100
    end
    return shares, stats, total
end

function Matcher.IsGoalMatch(itemID, specID)
    local result = Matcher.GetResult(specID)
    return result and result.matchedItems and result.matchedItems[tonumber(itemID)] == true or false
end

function Matcher.ClearResult(specID)
    GetSavedResults()[tonumber(specID or CurrentSpecID()) or 0] = nil
end

function Matcher.ClearAllResults()
    KeyLabDB = type(KeyLabDB) == "table" and KeyLabDB or {}
    KeyLabDB.statGoalMatcherResults = {}
end

function Matcher.GetConstants()
    return {
        exactCombinationLimit = EXACT_COMBINATION_LIMIT,
        beamWidth = BEAM_WIDTH,
        workPerFrame = WORK_PER_FRAME,
    }
end

local eventFrame = CreateFrame and CreateFrame("Frame") or nil
if eventFrame then
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:SetScript("OnEvent", function(_, _, unit)
        if not unit or unit == "player" then
            Matcher.Cancel()
        end
    end)
end

return Matcher
