local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.LootTargetsDB = KeyLab.LootTargetsDB or {}
local LootTargetsDB = KeyLab.LootTargetsDB

local STATUS_LABELS = {
    wanted = "Wanted",
    backup = "Backup",
    temporary = "Temporary",
    bis = "BIS",
    ignore = "Ignore",
    acquired = "Acquired",
}

local STATUS_OPTIONS = {
    { value = nil, label = "Unmarked" },
    { value = "wanted", label = "Wanted" },
    { value = "backup", label = "Backup" },
    { value = "temporary", label = "Temporary" },
    { value = "bis", label = "BIS" },
    { value = "ignore", label = "Ignore" },
    { value = "acquired", label = "Acquired" },
}

local TRACKED_STATUSES = {
    wanted = true,
    backup = true,
    temporary = true,
    bis = true,
}

--[[
KeyLab_LootTargetsDB.lua

Purpose:
- Owns only the player's saved Gear Target selections.
- Static loot data lives in database/KeyLab_GearLootDatabase.lua.
- Lookup/filter helpers live in mapping/KeyLab_GearLootMapping.lua.
- This file does not scan or modify Blizzard's Adventure Guide.

Saved structure:
KeyLabDB.lootTargets[characterKey][specID][itemID] = true
]]

local function EnsureRoot()
    if KeyLab.DB and KeyLab.DB.Get then
        KeyLab.DB.Get()
    end

    KeyLabDB = KeyLabDB or {}
    KeyLabDB.lootTargets = KeyLabDB.lootTargets or {}
    KeyLabDB.lootTargetStatuses = KeyLabDB.lootTargetStatuses or {}
    return KeyLabDB
end

local function CurrentCharacterKey()
    local name, realm
    if UnitFullName then
        name, realm = UnitFullName("player")
    end
    if not name or name == "" then
        name = UnitName and UnitName("player") or "Unknown"
    end
    if not realm or realm == "" then
        realm = GetRealmName and GetRealmName() or "Unknown"
    end
    return tostring(name or "Unknown") .. "-" .. tostring(realm or "Unknown")
end

local function NormalizeStatus(status)
    if status == nil then return nil end
    status = tostring(status):lower()
    if status == "" or status == "none" or status == "unmarked" then
        return nil
    end
    if STATUS_LABELS[status] then return status end
    return nil
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

function LootTargetsDB.GetSpecName(specID)
    specID = tonumber(specID)
    if not specID or specID == 0 then return "Current Spec" end

    if KeyLab.GearLootDatabase and KeyLab.GearLootDatabase.specs and KeyLab.GearLootDatabase.specs[specID] then
        local spec = KeyLab.GearLootDatabase.specs[specID]
        return spec.specName or spec.name or ("Spec " .. tostring(specID))
    end

    local classID = LootTargetsDB.GetCurrentClassID()
    if classID and GetNumSpecializationsForClassID and GetSpecializationInfoForClassID then
        local count = GetNumSpecializationsForClassID(classID) or 0
        for i = 1, count do
            local id, name = GetSpecializationInfoForClassID(classID, i)
            if id == specID then return name end
        end
    end
    return "Spec " .. tostring(specID)
end

function LootTargetsDB.GetBucket(specID)
    local db = EnsureRoot()
    local characterKey = CurrentCharacterKey()
    specID = tonumber(specID or LootTargetsDB.GetCurrentSpecID()) or 0

    db.lootTargets[characterKey] = db.lootTargets[characterKey] or {}
    db.lootTargets[characterKey][specID] = db.lootTargets[characterKey][specID] or {}
    return db.lootTargets[characterKey][specID]
end

function LootTargetsDB.GetStatusBucket(specID)
    local db = EnsureRoot()
    local characterKey = CurrentCharacterKey()
    specID = tonumber(specID or LootTargetsDB.GetCurrentSpecID()) or 0

    db.lootTargetStatuses[characterKey] = db.lootTargetStatuses[characterKey] or {}
    db.lootTargetStatuses[characterKey][specID] = db.lootTargetStatuses[characterKey][specID] or {}
    return db.lootTargetStatuses[characterKey][specID]
end

function LootTargetsDB.GetStatusOptions()
    local out = {}
    for _, option in ipairs(STATUS_OPTIONS) do
        table.insert(out, { value = option.value, label = option.label })
    end
    return out
end

function LootTargetsDB.GetStatusLabel(status)
    status = NormalizeStatus(status)
    return status and STATUS_LABELS[status] or "Unmarked"
end

function LootTargetsDB.GetStatus(specID, itemID)
    itemID = tonumber(itemID)
    if not itemID then return nil end

    local statusBucket = LootTargetsDB.GetStatusBucket(specID or LootTargetsDB.GetCurrentSpecID())
    local status = NormalizeStatus(statusBucket[itemID])
    if status then return status end

    local bucket = LootTargetsDB.GetBucket(specID or LootTargetsDB.GetCurrentSpecID())
    if bucket[itemID] == true then return "wanted" end
    return nil
end

function LootTargetsDB.SetStatus(specID, itemOrItemID, status)
    specID = tonumber(specID or LootTargetsDB.GetCurrentSpecID()) or 0
    local itemID = itemOrItemID
    if type(itemOrItemID) == "table" then
        itemID = itemOrItemID.itemID
    end
    itemID = tonumber(itemID)
    if not itemID then return false end

    status = NormalizeStatus(status)
    local statusBucket = LootTargetsDB.GetStatusBucket(specID)
    local bucket = LootTargetsDB.GetBucket(specID)

    if status then
        statusBucket[itemID] = status
    else
        statusBucket[itemID] = nil
    end

    if status and TRACKED_STATUSES[status] then
        bucket[itemID] = true
    else
        bucket[itemID] = nil
    end

    return true
end

function LootTargetsDB.SetTracked(specID, itemOrItemID, selected)
    specID = tonumber(specID or LootTargetsDB.GetCurrentSpecID()) or 0
    local itemID = itemOrItemID
    if type(itemOrItemID) == "table" then
        itemID = itemOrItemID.itemID
    end
    itemID = tonumber(itemID)
    if not itemID then return false end

    local bucket = LootTargetsDB.GetBucket(specID)
    local statusBucket = LootTargetsDB.GetStatusBucket(specID)
    if selected then
        bucket[itemID] = true
        if not NormalizeStatus(statusBucket[itemID]) or NormalizeStatus(statusBucket[itemID]) == "ignore" then
            statusBucket[itemID] = "wanted"
        end
    else
        bucket[itemID] = nil
        statusBucket[itemID] = nil
    end
    return true
end

function LootTargetsDB.ToggleTracked(specID, itemOrItemID)
    specID = tonumber(specID or LootTargetsDB.GetCurrentSpecID()) or 0
    local itemID = itemOrItemID
    if type(itemOrItemID) == "table" then
        itemID = itemOrItemID.itemID
    end
    itemID = tonumber(itemID)
    if not itemID then return false end

    local bucket = LootTargetsDB.GetBucket(specID)
    local newValue = not bucket[itemID]
    LootTargetsDB.SetTracked(specID, itemID, newValue)
    return newValue
end

function LootTargetsDB.IsTracked(specID, itemID)
    itemID = tonumber(itemID)
    if not itemID then return false end
    local status = LootTargetsDB.GetStatus(specID or LootTargetsDB.GetCurrentSpecID(), itemID)
    if status == "ignore" then return false end
    if TRACKED_STATUSES[status] then return true end

    local bucket = LootTargetsDB.GetBucket(specID or LootTargetsDB.GetCurrentSpecID())
    return bucket[itemID] == true
end

function LootTargetsDB.GetTrackedTable(specID)
    local bucket = LootTargetsDB.GetBucket(specID or LootTargetsDB.GetCurrentSpecID())
    local statusBucket = LootTargetsDB.GetStatusBucket(specID or LootTargetsDB.GetCurrentSpecID())
    local out = {}
    for itemID, enabled in pairs(bucket or {}) do
        local status = NormalizeStatus(statusBucket[tonumber(itemID)])
        if enabled and status ~= "ignore" then out[tonumber(itemID)] = true end
    end
    for itemID, status in pairs(statusBucket or {}) do
        status = NormalizeStatus(status)
        if TRACKED_STATUSES[status] then out[tonumber(itemID)] = true end
    end
    return out
end

function LootTargetsDB.GetSavedTargetsForSpec(specID)
    specID = tonumber(specID or LootTargetsDB.GetCurrentSpecID()) or 0
    local bucket = LootTargetsDB.GetTrackedTable(specID)
    local list = {}

    for itemID, selected in pairs(bucket or {}) do
        if selected then
            local item = KeyLab.GearLootMapping and KeyLab.GearLootMapping.GetItem and KeyLab.GearLootMapping.GetItem(tonumber(itemID), specID)
            if item then
                table.insert(list, item)
            else
                table.insert(list, { itemID = tonumber(itemID), name = "Item " .. tostring(itemID), slot = "", dungeonName = "Unknown Source" })
            end
        end
    end

    table.sort(list, function(a, b)
        if tostring(a.dungeonName or "") ~= tostring(b.dungeonName or "") then
            return tostring(a.dungeonName or "") < tostring(b.dungeonName or "")
        end
        if tostring(a.slot or "") ~= tostring(b.slot or "") then
            return tostring(a.slot or "") < tostring(b.slot or "")
        end
        return tostring(a.name or a.itemID) < tostring(b.name or b.itemID)
    end)

    return list
end

function LootTargetsDB.ClearSpec(specID)
    local bucket = LootTargetsDB.GetBucket(specID or LootTargetsDB.GetCurrentSpecID())
    for itemID in pairs(bucket) do
        bucket[itemID] = nil
    end

    local statusBucket = LootTargetsDB.GetStatusBucket(specID or LootTargetsDB.GetCurrentSpecID())
    for itemID in pairs(statusBucket) do
        statusBucket[itemID] = nil
    end
end

return LootTargetsDB
