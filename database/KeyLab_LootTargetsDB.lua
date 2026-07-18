local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.LootTargetsDB = KeyLab.LootTargetsDB or {}
local LootTargetsDB = KeyLab.LootTargetsDB

local TARGET_SCHEMA_VERSION = 2
local MIGRATION_VERSION = 2

local STATUS_LABELS = {
    target = "Target",
    alternative = "Alternative",
}

local STATUS_OPTIONS = {
    { value = nil, label = "Unmarked" },
    { value = "target", label = "Target" },
    { value = "alternative", label = "Alternative" },
}

local SLOT_ORDER = {
    "Head", "Neck", "Shoulders", "Back", "Chest", "Wrist",
    "Hands", "Waist", "Legs", "Feet", "Finger 1", "Finger 2",
    "Trinket 1", "Trinket 2", "Main Hand", "Off Hand",
}

local VALID_SLOTS = {}
for _, slotName in ipairs(SLOT_ORDER) do VALID_SLOTS[slotName] = true end

--[[
KeyLab_LootTargetsDB.lua

Owns saved Gear Target choices. The current model is character + spec + slot:

KeyLabDB.gearTargets[characterKey][specID] = {
    schemaVersion = 2,
    slots = {
        ["Head"] = {
            target = { itemID, sourceID, slotInstance, status, savedAt },
            alternatives = { [itemID] = { ... } },
        },
    },
    pending = { [itemID] = { ... } },
}

Pending records preserve legacy choices that could not be placed safely and
temporary choices made by the old UI before the slot picker is introduced.
The legacy lootTargets and lootTargetStatuses tables are kept as a backup.
]]

local function EnsureRoot()
    if KeyLab.DB and KeyLab.DB.Get then KeyLab.DB.Get() end
    KeyLabDB = KeyLabDB or {}
    KeyLabDB.gearTargets = KeyLabDB.gearTargets or {}
    KeyLabDB.lootTargets = KeyLabDB.lootTargets or {}
    KeyLabDB.lootTargetStatuses = KeyLabDB.lootTargetStatuses or {}
    return KeyLabDB
end

local function CurrentCharacterKey()
    local name, realm
    if UnitFullName then name, realm = UnitFullName("player") end
    if not name or name == "" then name = UnitName and UnitName("player") or "Unknown" end
    if not realm or realm == "" then realm = GetRealmName and GetRealmName() or "Unknown" end
    return tostring(name or "Unknown") .. "-" .. tostring(realm or "Unknown")
end

local function NormalizeStatus(status)
    if status == nil then return nil end
    status = string.lower(tostring(status))
    if status == "" or status == "none" or status == "unmarked" or status == "ignore" then return nil end
    if status == "target" or status == "wanted" or status == "bis" or status == "acquired" then return "target" end
    if status == "alternative" then return "alternative" end
    return nil
end

local function NormalizeLegacyStatus(status, selected)
    if status ~= nil then
        status = string.lower(tostring(status))
        if status == "wanted" or status == "target" or status == "bis" or status == "acquired" then
            return "target"
        end
        return nil
    end
    return selected == true and "target" or nil
end

local function GetSpecStoreForCharacter(characterKey, specID, create)
    local db = EnsureRoot()
    characterKey = tostring(characterKey or CurrentCharacterKey())
    specID = tonumber(specID) or 0
    if create then
        db.gearTargets[characterKey] = db.gearTargets[characterKey] or {}
        db.gearTargets[characterKey][specID] = db.gearTargets[characterKey][specID] or {
            schemaVersion = TARGET_SCHEMA_VERSION,
            slots = {},
            pending = {},
        }
    end
    local store = db.gearTargets[characterKey] and db.gearTargets[characterKey][specID] or nil
    if store and create then
        store.schemaVersion = TARGET_SCHEMA_VERSION
        store.slots = store.slots or {}
        store.pending = store.pending or {}
    end
    return store
end

local function GetLegacySpecBucket(root, characterKey, specID)
    local character = type(root) == "table" and root[characterKey] or nil
    if type(character) ~= "table" then return {} end
    return character[specID] or character[tostring(specID)] or {}
end

local function GetSlotStore(store, slotInstance, create)
    if not store or not VALID_SLOTS[slotInstance] then return nil end
    if create then
        store.slots[slotInstance] = store.slots[slotInstance] or { alternatives = {} }
        store.slots[slotInstance].alternatives = store.slots[slotInstance].alternatives or {}
    end
    return store.slots[slotInstance]
end

local function Mapping()
    return KeyLab and KeyLab.GearLootMapping or nil
end

local function GetItemID(itemOrItemID)
    if type(itemOrItemID) == "table" then return tonumber(itemOrItemID.itemID) end
    return tonumber(itemOrItemID)
end

local function GetEligibleSlots(itemID, specID)
    local mapping = Mapping()
    if mapping and mapping.GetEligibleSlotInstances then
        return mapping.GetEligibleSlotInstances(itemID, specID) or {}
    end
    return {}
end

local function Contains(list, wanted)
    for _, value in ipairs(list or {}) do
        if value == wanted then return true end
    end
    return false
end

local function NewRecord(itemID, sourceID, slotInstance, status, extra)
    local record = {
        itemID = tonumber(itemID),
        sourceID = tonumber(sourceID),
        slotInstance = slotInstance,
        status = status,
        savedAt = time and time() or 0,
    }
    for key, value in pairs(extra or {}) do record[key] = value end
    return record
end

local function RemoveItemEverywhere(store, itemID, specID)
    if not store then return end
    itemID = tonumber(itemID)
    for _, slotName in ipairs(SLOT_ORDER) do
        local slotStore = GetSlotStore(store, slotName, false)
        if slotStore then
            if slotStore.target and tonumber(slotStore.target.itemID) == itemID then
                slotStore.target = nil
                -- Alternatives belong to this exact Target slot. They cannot
                -- remain valid after its Target is removed.
                slotStore.alternatives = {}
                if slotName == "Main Hand" then
                    local offHand = GetSlotStore(store, "Off Hand", false)
                    local mapping = Mapping()
                    local offItem = offHand and offHand.target and mapping and mapping.GetItem
                        and mapping.GetItem(offHand.target.itemID, specID) or nil
                    if offItem and offItem.slot == "Off Hand" then
                        store.slots["Off Hand"] = nil
                    end
                end
            end
            if slotStore.alternatives then slotStore.alternatives[itemID] = nil end
        end
    end
    if store.pending then store.pending[itemID] = nil end
end

local function RemoveItemAlternatives(store, itemID)
    if not store then return end
    itemID = tonumber(itemID)
    for _, slotName in ipairs(SLOT_ORDER) do
        local slotStore = GetSlotStore(store, slotName, false)
        if slotStore and slotStore.alternatives then slotStore.alternatives[itemID] = nil end
    end
end

local function FindAssignments(store, itemID)
    local out = {}
    itemID = tonumber(itemID)
    for _, slotName in ipairs(SLOT_ORDER) do
        local slotStore = GetSlotStore(store, slotName, false)
        if slotStore and slotStore.target and tonumber(slotStore.target.itemID) == itemID then
            table.insert(out, slotStore.target)
        end
        if slotStore and slotStore.alternatives and slotStore.alternatives[itemID] then
            table.insert(out, slotStore.alternatives[itemID])
        end
    end
    if store and store.pending and store.pending[itemID] then table.insert(out, store.pending[itemID]) end
    return out
end

local function CanTargetMultipleSlots(itemID, specID)
    local slots = GetEligibleSlots(itemID, specID)
    return Contains(slots, "Main Hand") and Contains(slots, "Off Hand")
end

local function ItemClosesOffHand(itemID, specID)
    local mapping = Mapping()
    local item = mapping and mapping.GetItem and mapping.GetItem(itemID, specID) or nil
    local occupiesBoth = item and (item.slot == "Two-Hand" or item.slot == "Ranged")
    return occupiesBoth and not (mapping.IsDualWieldEligible and mapping.IsDualWieldEligible(itemID, specID)) or false
end

local function PruneInvalidAlternatives(slotStore, specID, slotInstance)
    local mapping = Mapping()
    if not slotStore or not slotStore.alternatives or not mapping then return end
    for itemID in pairs(slotStore.alternatives) do
        local validSlot = Contains(GetEligibleSlots(itemID, specID), slotInstance)
        local currentSeason = not mapping.IsCurrentSeasonItem or mapping.IsCurrentSeasonItem(itemID)
        if not validSlot or not currentSeason then slotStore.alternatives[itemID] = nil end
    end
end

function LootTargetsDB.GetCurrentSpecID()
    local specIndex = GetSpecialization and GetSpecialization()
    if specIndex and GetSpecializationInfo then
        local specID = GetSpecializationInfo(specIndex)
        if specID then return specID end
    end
    return 0
end

function LootTargetsDB.GetCurrentClassID()
    if UnitClass then
        local _, _, classID = UnitClass("player")
        return classID or 0
    end
    return 0
end

function LootTargetsDB.GetCurrentCharacterKey()
    return CurrentCharacterKey()
end

function LootTargetsDB.GetSpecName(specID)
    specID = tonumber(specID)
    if not specID or specID == 0 then return "Current Spec" end
    local database = KeyLab.GearLootDatabase
    if database and database.specs and database.specs[specID] then
        local spec = database.specs[specID]
        return spec.specName or spec.name or ("Spec " .. tostring(specID))
    end
    return "Spec " .. tostring(specID)
end

function LootTargetsDB.GetSlotOrder()
    local out = {}
    for _, slotName in ipairs(SLOT_ORDER) do table.insert(out, slotName) end
    return out
end

function LootTargetsDB.GetSpecStore(specID)
    specID = tonumber(specID or LootTargetsDB.GetCurrentSpecID()) or 0
    local store = GetSpecStoreForCharacter(CurrentCharacterKey(), specID, true)
    local mainHand = GetSlotStore(store, "Main Hand", false)
    if mainHand and mainHand.target then
        mainHand.target.closesOffHand = ItemClosesOffHand(mainHand.target.itemID, specID) == true
        if mainHand.target.closesOffHand then store.slots["Off Hand"] = nil end
    end
    return store
end

function LootTargetsDB.GetStatusOptions()
    local out = {}
    for _, option in ipairs(STATUS_OPTIONS) do table.insert(out, { value = option.value, label = option.label }) end
    return out
end

function LootTargetsDB.GetStatusLabel(status)
    status = NormalizeStatus(status)
    return status and STATUS_LABELS[status] or "Unmarked"
end

function LootTargetsDB.GetTargetForSlot(specID, slotInstance)
    local slotStore = GetSlotStore(LootTargetsDB.GetSpecStore(specID), slotInstance, false)
    return slotStore and slotStore.target or nil
end

function LootTargetsDB.GetAlternativesForSlot(specID, slotInstance)
    local slotStore = GetSlotStore(LootTargetsDB.GetSpecStore(specID), slotInstance, false)
    return slotStore and slotStore.alternatives or {}
end

function LootTargetsDB.GetPendingAssignments(specID)
    return LootTargetsDB.GetSpecStore(specID).pending
end

function LootTargetsDB.GetAssignmentsForItem(specID, itemOrItemID)
    return FindAssignments(LootTargetsDB.GetSpecStore(specID), GetItemID(itemOrItemID))
end

function LootTargetsDB.CanAssign(specID, itemOrItemID, status, slotInstance, replaceExisting)
    specID = tonumber(specID or LootTargetsDB.GetCurrentSpecID()) or 0
    local itemID = GetItemID(itemOrItemID)
    status = NormalizeStatus(status)
    if not itemID then return false, "invalid_item" end
    if not status then return true end
    if not VALID_SLOTS[slotInstance] then return false, "slot_required" end
    if not Contains(GetEligibleSlots(itemID, specID), slotInstance) then return false, "invalid_slot" end

    local store = LootTargetsDB.GetSpecStore(specID)
    local slotStore = GetSlotStore(store, slotInstance, true)
    if slotInstance == "Off Hand" then
        local mainHand = GetSlotStore(store, "Main Hand", false)
        if mainHand and mainHand.target and mainHand.target.closesOffHand == true then return false, "off_hand_closed" end
        local mapping = Mapping()
        local item = mapping and mapping.GetItem and mapping.GetItem(itemID, specID) or nil
        if item and item.slot == "Off Hand" then
            if not (mainHand and mainHand.target) then return false, "main_hand_required" end
            local mainItem = mapping.GetItem(mainHand.target.itemID, specID)
            if not mainItem or mainItem.slot ~= "One-Hand" then return false, "incompatible_main_hand" end
        end
    end
    if status == "alternative" then
        if not slotStore.target then return false, "target_required" end
        if tonumber(slotStore.target.itemID) == itemID then return false, "already_target" end
        for _, record in ipairs(FindAssignments(store, itemID)) do
            if record.status == "target" then return false, "already_targeted" end
        end
        return true
    end

    if not replaceExisting and slotStore.target and tonumber(slotStore.target.itemID) ~= itemID then
        return false, "slot_has_target"
    end
    if not CanTargetMultipleSlots(itemID, specID) then
        for _, record in ipairs(FindAssignments(store, itemID)) do
            if record.status == "target" and record.slotInstance and record.slotInstance ~= slotInstance then
                return false, "already_targeted"
            end
        end
    end
    return true
end

function LootTargetsDB.SetAssignment(specID, itemOrItemID, status, slotInstance, sourceID, replaceExisting)
    specID = tonumber(specID or LootTargetsDB.GetCurrentSpecID()) or 0
    local itemID = GetItemID(itemOrItemID)
    status = NormalizeStatus(status)
    if not itemID then return false, "invalid_item" end
    local store = LootTargetsDB.GetSpecStore(specID)
    if not status then
        RemoveItemEverywhere(store, itemID, specID)
        return true
    end

    local allowed, reason = LootTargetsDB.CanAssign(specID, itemID, status, slotInstance, replaceExisting)
    if not allowed then return false, reason end
    sourceID = tonumber(sourceID)
    store.pending[itemID] = nil
    local slotStore = GetSlotStore(store, slotInstance, true)
    local closesOffHand = status == "target" and slotInstance == "Main Hand" and ItemClosesOffHand(itemID, specID)
    local record = NewRecord(itemID, sourceID, slotInstance, status, {
        closesOffHand = closesOffHand == true,
    })
    if status == "target" then
        if closesOffHand then store.slots["Off Hand"] = nil end
        RemoveItemAlternatives(store, itemID)
        slotStore.alternatives[itemID] = nil
        slotStore.target = record
        if replaceExisting then PruneInvalidAlternatives(slotStore, specID, slotInstance) end
    else
        RemoveItemAlternatives(store, itemID)
        slotStore.alternatives[itemID] = record
    end
    return true, record
end


function LootTargetsDB.SetTargetForSlot(specID, itemOrItemID, slotInstance, sourceID, replaceExisting)
    return LootTargetsDB.SetAssignment(specID, itemOrItemID, "target", slotInstance, sourceID, replaceExisting == true)
end

function LootTargetsDB.SetAlternativeForSlot(specID, itemOrItemID, slotInstance, sourceID)
    return LootTargetsDB.SetAssignment(specID, itemOrItemID, "alternative", slotInstance, sourceID, false)
end

function LootTargetsDB.GetStatus(specID, itemOrItemID)
    local itemID = GetItemID(itemOrItemID)
    if not itemID then return nil end
    local best
    for _, record in ipairs(FindAssignments(LootTargetsDB.GetSpecStore(specID), itemID)) do
        if record.status == "target" then return "target" end
        if record.status == "alternative" then best = "alternative" end
    end
    return best
end

-- Compatibility entry point for the old Gear Targets list. The new UI calls
-- SetAssignment after the player chooses a slot. Until then, retain the choice
-- as pending instead of guessing a ring, trinket, or weapon slot.
function LootTargetsDB.SetStatus(specID, itemOrItemID, status, slotInstance, sourceID)
    specID = tonumber(specID or LootTargetsDB.GetCurrentSpecID()) or 0
    local itemID = GetItemID(itemOrItemID)
    status = NormalizeStatus(status)
    if not itemID then return false, "invalid_item" end
    if not status then return LootTargetsDB.SetAssignment(specID, itemID, nil) end
    if slotInstance then return LootTargetsDB.SetAssignment(specID, itemID, status, slotInstance, sourceID) end

    local store = LootTargetsDB.GetSpecStore(specID)
    RemoveItemEverywhere(store, itemID, specID)
    store.pending[itemID] = NewRecord(itemID, sourceID, nil, status, {
        requiresSlot = true,
    })
    return true, "slot_required"
end

function LootTargetsDB.SetTracked(specID, itemOrItemID, selected)
    if selected then return LootTargetsDB.SetStatus(specID, itemOrItemID, "target") end
    return LootTargetsDB.SetStatus(specID, itemOrItemID, nil)
end

function LootTargetsDB.ToggleTracked(specID, itemOrItemID)
    local selected = not LootTargetsDB.IsTracked(specID, GetItemID(itemOrItemID))
    LootTargetsDB.SetTracked(specID, itemOrItemID, selected)
    return selected
end

function LootTargetsDB.IsTracked(specID, itemOrItemID)
    return LootTargetsDB.GetStatus(specID, itemOrItemID) == "target"
end

function LootTargetsDB.GetTrackedTable(specID)
    local out = {}
    local store = LootTargetsDB.GetSpecStore(specID)
    for _, slotName in ipairs(SLOT_ORDER) do
        local target = LootTargetsDB.GetTargetForSlot(specID, slotName)
        if target and target.itemID then out[tonumber(target.itemID)] = true end
    end
    for itemID, record in pairs(store.pending or {}) do
        if record.status == "target" then out[tonumber(itemID)] = true end
    end
    return out
end

function LootTargetsDB.GetStatusBucket(specID)
    local out = {}
    local store = LootTargetsDB.GetSpecStore(specID)
    for _, slotName in ipairs(SLOT_ORDER) do
        local slotStore = GetSlotStore(store, slotName, false)
        if slotStore and slotStore.target then out[tonumber(slotStore.target.itemID)] = "target" end
        for itemID in pairs(slotStore and slotStore.alternatives or {}) do
            if not out[tonumber(itemID)] then out[tonumber(itemID)] = "alternative" end
        end
    end
    for itemID, record in pairs(store.pending or {}) do out[tonumber(itemID)] = record.status end
    return out
end

function LootTargetsDB.GetBucket(specID)
    return LootTargetsDB.GetTrackedTable(specID)
end

local function EnrichRecord(record, specID)
    local mapping = Mapping()
    local item = mapping and mapping.GetItem and mapping.GetItem(record.itemID, specID, nil, record.sourceID) or nil
    item = item or { itemID = record.itemID, name = "Item " .. tostring(record.itemID), slot = record.slotInstance or "" }
    item.status = record.status
    item.slotInstance = record.slotInstance
    item.sourceID = record.sourceID or item.sourceID
    item.requiresSlot = record.requiresSlot == true
    return item
end

function LootTargetsDB.GetAllTargetsForSpec(specID)
    specID = tonumber(specID or LootTargetsDB.GetCurrentSpecID()) or 0
    local out = {}
    local store = LootTargetsDB.GetSpecStore(specID)
    for _, slotName in ipairs(SLOT_ORDER) do
        local slotStore = GetSlotStore(store, slotName, false)
        if slotStore and slotStore.target then table.insert(out, EnrichRecord(slotStore.target, specID)) end
    end
    for _, record in pairs(store.pending or {}) do
        if record.status == "target" then table.insert(out, EnrichRecord(record, specID)) end
    end
    return out
end

function LootTargetsDB.GetAllAlternativesForSpec(specID)
    specID = tonumber(specID or LootTargetsDB.GetCurrentSpecID()) or 0
    local out = {}
    local store = LootTargetsDB.GetSpecStore(specID)
    for _, slotName in ipairs(SLOT_ORDER) do
        local slotStore = GetSlotStore(store, slotName, false)
        for _, record in pairs(slotStore and slotStore.alternatives or {}) do table.insert(out, EnrichRecord(record, specID)) end
    end
    for _, record in pairs(store.pending or {}) do
        if record.status == "alternative" then table.insert(out, EnrichRecord(record, specID)) end
    end
    return out
end

function LootTargetsDB.GetSavedTargetsForSpec(specID)
    local list = LootTargetsDB.GetAllTargetsForSpec(specID)
    table.sort(list, function(a, b)
        if tostring(a.sourceName or "") ~= tostring(b.sourceName or "") then
            return tostring(a.sourceName or "") < tostring(b.sourceName or "")
        end
        if tostring(a.slotInstance or a.slot or "") ~= tostring(b.slotInstance or b.slot or "") then
            return tostring(a.slotInstance or a.slot or "") < tostring(b.slotInstance or b.slot or "")
        end
        return tostring(a.name or a.itemID) < tostring(b.name or b.itemID)
    end)
    return list
end

function LootTargetsDB.ClearSpec(specID)
    local store = LootTargetsDB.GetSpecStore(specID)
    store.slots = {}
    store.pending = {}
end

function LootTargetsDB.MigrateLegacy()
    local db = EnsureRoot()
    local currentMigrationVersion = tonumber(db.gearTargetsMigrationVersion) or 0
    if currentMigrationVersion >= MIGRATION_VERSION then return db.gearTargetsMigrationReport end
    local report = { migrated = 0, assigned = 0, pending = 0, ignored = 0 }
    local characterKeys = {}
    for key in pairs(db.lootTargets or {}) do characterKeys[key] = true end
    for key in pairs(db.lootTargetStatuses or {}) do characterKeys[key] = true end

    for characterKey in pairs(characterKeys) do
        local specIDs = {}
        for specID in pairs((db.lootTargets or {})[characterKey] or {}) do specIDs[tonumber(specID) or specID] = true end
        for specID in pairs((db.lootTargetStatuses or {})[characterKey] or {}) do specIDs[tonumber(specID) or specID] = true end
        for specID in pairs(specIDs) do
            specID = tonumber(specID) or 0
            local selected = GetLegacySpecBucket(db.lootTargets, characterKey, specID)
            local statuses = GetLegacySpecBucket(db.lootTargetStatuses, characterKey, specID)
            local itemSet = {}
            for itemID in pairs(selected) do itemSet[tonumber(itemID) or itemID] = true end
            for itemID in pairs(statuses) do itemSet[tonumber(itemID) or itemID] = true end
            local itemIDs = {}
            for itemID in pairs(itemSet) do if tonumber(itemID) then table.insert(itemIDs, tonumber(itemID)) end end
            table.sort(itemIDs)
            local store = GetSpecStoreForCharacter(characterKey, specID, true)

            for _, itemID in ipairs(itemIDs) do
                local status = NormalizeLegacyStatus(statuses[itemID] or statuses[tostring(itemID)], selected[itemID] or selected[tostring(itemID)])
                if status ~= "target" then
                    report.ignored = report.ignored + 1
                elseif #FindAssignments(store, itemID) == 0 then
                    report.migrated = report.migrated + 1
                    local assigned = false
                    local closesOffHand = ItemClosesOffHand(itemID, specID)
                    for _, slotInstance in ipairs(GetEligibleSlots(itemID, specID)) do
                        local slotStore = GetSlotStore(store, slotInstance, true)
                        local mainHand = GetSlotStore(store, "Main Hand", false)
                        local offHand = GetSlotStore(store, "Off Hand", false)
                        local blockedByMain = slotInstance == "Off Hand" and mainHand and mainHand.target and mainHand.target.closesOffHand == true
                        local blocksExistingOffHand = slotInstance == "Main Hand" and closesOffHand and offHand and offHand.target
                        if not slotStore.target and not blockedByMain and not blocksExistingOffHand then
                            slotStore.target = NewRecord(itemID, nil, slotInstance, "target", {
                                migratedFrom = string.lower(tostring(statuses[itemID] or statuses[tostring(itemID)] or "selected")),
                                closesOffHand = closesOffHand == true,
                            })
                            report.assigned = report.assigned + 1
                            assigned = true
                            break
                        end
                    end
                    if not assigned then
                        store.pending[itemID] = NewRecord(itemID, nil, nil, "target", {
                            migratedFrom = string.lower(tostring(statuses[itemID] or statuses[tostring(itemID)] or "selected")),
                            requiresSlot = true,
                        })
                        report.pending = report.pending + 1
                    end
                end
            end
        end
    end

    db.gearTargetsMigrationVersion = MIGRATION_VERSION
    db.gearTargetsMigrationReport = report
    return report
end

return LootTargetsDB
