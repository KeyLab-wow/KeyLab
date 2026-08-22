local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.TierSetDB = KeyLab.TierSetDB or {}
local TierSetDB = KeyLab.TierSetDB

local TIER_SLOTS = { "Head", "Shoulders", "Chest", "Hands", "Legs" }
local VALID_SLOTS = {}
for _, slotName in ipairs(TIER_SLOTS) do VALID_SLOTS[slotName] = true end

function TierSetDB.GetCurrentSeason()
    local db = KeyLab.GearLootDatabase
    return tonumber(db and (db.mnSeason or db.season)) or 1
end

function TierSetDB.GetSlots()
    local out = {}
    for _, slotName in ipairs(TIER_SLOTS) do table.insert(out, slotName) end
    return out
end

local function GetEquippedTierSlots(equippedSlots)
    if type(equippedSlots) == "table" then return equippedSlots end
    local capture = KeyLab.GearCapture
    if capture and capture.GetEquippedSlots then
        return capture.GetEquippedSlots(TIER_SLOTS, false) or {}
    end
    return {}
end

function TierSetDB.GetState(season, equippedSlots)
    local classification = KeyLab.ItemClassificationDB
    local slots = {}
    local items = {}
    local count = 0
    equippedSlots = GetEquippedTierSlots(equippedSlots)

    for _, slotName in ipairs(TIER_SLOTS) do
        local slot = equippedSlots[slotName]
        local itemID = tonumber(slot and slot.itemID)
        local tierItem = classification and classification.GetNativeTierItem
            and classification.GetNativeTierItem(itemID) or nil
        local equipped = tierItem and tierItem.countsTowardSet == true and tierItem.slot == slotName or false
        slots[slotName] = equipped
        if equipped then
            count = count + 1
            items[slotName] = tierItem
        end
    end

    return {
        season = tonumber(season or TierSetDB.GetCurrentSeason()) or 1,
        slots = slots,
        items = items,
        count = count,
        twoPieceActive = count >= 2,
        complete = count >= 4,
        fourPieceActive = count >= 4,
    }
end

function TierSetDB.GetStatusText(stateOrCount)
    local count = type(stateOrCount) == "table" and tonumber(stateOrCount.count) or tonumber(stateOrCount)
    count = count or 0
    if count <= 0 then return "No Tier Pieces Equipped — 2-Piece is Next" end
    if count == 1 then return "1 Tier Piece Equipped — 1/4" end
    if count == 2 then return "2-Piece Tier Set Active — 2/4" end
    if count == 3 then return "3 Tier Pieces Equipped — One More for 4-Piece" end
    if count == 4 then return "4-Piece Tier Set Complete" end
    return "5 Tier Pieces Equipped — 4-Piece Complete"
end

function TierSetDB.IsChecked(slotName, season, equippedSlots)
    if not VALID_SLOTS[slotName] then return false end
    local state = TierSetDB.GetState(season, equippedSlots)
    return state.slots[slotName] == true
end

function TierSetDB.GetCheckedCount(season, equippedSlots)
    return TierSetDB.GetState(season, equippedSlots).count
end

function TierSetDB.IsFourPieceComplete(season, equippedSlots)
    return TierSetDB.GetState(season, equippedSlots).complete
end

-- Compatibility shims for older saved settings and callers. Tier progress is
-- now read from equipped item IDs, so manual changes are intentionally ignored.
function TierSetDB.SetChecked()
    return false, "Tier progress is detected automatically from equipped items."
end

function TierSetDB.Toggle()
    return false, "Tier progress is detected automatically from equipped items."
end

return TierSetDB
