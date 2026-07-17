local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.TierSetDB = KeyLab.TierSetDB or {}
local TierSetDB = KeyLab.TierSetDB

local TIER_SLOTS = { "Head", "Shoulders", "Chest", "Hands", "Legs" }
local VALID_SLOTS = {}
for _, slotName in ipairs(TIER_SLOTS) do VALID_SLOTS[slotName] = true end

local function EnsureRoot()
    if KeyLab.DB and KeyLab.DB.Get then KeyLab.DB.Get() end
    KeyLabDB = KeyLabDB or {}
    KeyLabDB.tierSets = KeyLabDB.tierSets or {}
    return KeyLabDB.tierSets
end

local function CurrentCharacterKey()
    if KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.GetCurrentCharacterKey then
        return KeyLab.LootTargetsDB.GetCurrentCharacterKey()
    end
    local name, realm
    if UnitFullName then name, realm = UnitFullName("player") end
    if not name or name == "" then name = UnitName and UnitName("player") or "Unknown" end
    if not realm or realm == "" then realm = GetRealmName and GetRealmName() or "Unknown" end
    return tostring(name or "Unknown") .. "-" .. tostring(realm or "Unknown")
end

function TierSetDB.GetCurrentSeason()
    local db = KeyLab.GearLootDatabase
    return tonumber(db and (db.mnSeason or db.season)) or 1
end

function TierSetDB.GetSlots()
    local out = {}
    for _, slotName in ipairs(TIER_SLOTS) do table.insert(out, slotName) end
    return out
end

function TierSetDB.GetStore(season)
    local root = EnsureRoot()
    local characterKey = CurrentCharacterKey()
    season = tonumber(season or TierSetDB.GetCurrentSeason()) or 1
    root[characterKey] = root[characterKey] or {}
    root[characterKey][season] = root[characterKey][season] or { slots = {} }
    root[characterKey][season].slots = root[characterKey][season].slots or {}
    return root[characterKey][season]
end

function TierSetDB.IsChecked(slotName, season)
    if not VALID_SLOTS[slotName] then return false end
    return TierSetDB.GetStore(season).slots[slotName] == true
end

function TierSetDB.SetChecked(slotName, checked, season)
    if not VALID_SLOTS[slotName] then return false end
    local store = TierSetDB.GetStore(season)
    store.slots[slotName] = checked == true or nil
    store.updatedAt = time and time() or 0
    return true
end

function TierSetDB.Toggle(slotName, season)
    local checked = not TierSetDB.IsChecked(slotName, season)
    TierSetDB.SetChecked(slotName, checked, season)
    return checked
end

function TierSetDB.GetCheckedCount(season)
    local count = 0
    for _, slotName in ipairs(TIER_SLOTS) do
        if TierSetDB.IsChecked(slotName, season) then count = count + 1 end
    end
    return count
end

function TierSetDB.IsFourPieceComplete(season)
    return TierSetDB.GetCheckedCount(season) >= 4
end

function TierSetDB.GetState(season)
    season = tonumber(season or TierSetDB.GetCurrentSeason()) or 1
    local slots = {}
    for _, slotName in ipairs(TIER_SLOTS) do slots[slotName] = TierSetDB.IsChecked(slotName, season) end
    local count = TierSetDB.GetCheckedCount(season)
    return {
        season = season,
        slots = slots,
        count = count,
        complete = count >= 4,
    }
end

return TierSetDB
