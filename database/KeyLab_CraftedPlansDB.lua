local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.CraftedPlansDB = KeyLab.CraftedPlansDB or {}
local CraftedPlansDB = KeyLab.CraftedPlansDB

--[[
KeyLab_CraftedPlansDB.lua

Owns the player's crafted-gear plans only. Recipe facts live in the generated
recipe database and shopping-list calculations live in the analysis layer.

KeyLabDB.craftedPlans[characterKey][specID] = {
    schemaVersion = 3,
    recipes = {
        [recipeID] = {
            recipeID, itemID, savedAt, slotInstance,
            choices = { [reagentSlotIndex] = { kind = "item", id = itemID } },
        },
    },
}
]]

local SCHEMA_VERSION = 3

local function CharacterKey()
    local name, realm
    if UnitFullName then name, realm = UnitFullName("player") end
    if not name or name == "" then name = UnitName and UnitName("player") or "Unknown" end
    if not realm or realm == "" then realm = GetRealmName and GetRealmName() or "Unknown" end
    return tostring(name or "Unknown") .. "-" .. tostring(realm or "Unknown")
end

local function CurrentSpecID()
    if GetSpecialization and GetSpecializationInfo then
        local index = GetSpecialization()
        if index then
            -- GetSpecializationInfo returns several values. Capture only the
            -- first one so the specialization name is never passed to
            -- tonumber as its optional number-base argument.
            local specID = GetSpecializationInfo(index)
            return tonumber(specID) or 0
        end
    end
    return 0
end

local function EnsureRoot()
    if KeyLab.DB and KeyLab.DB.Get then KeyLab.DB.Get() end
    KeyLabDB = KeyLabDB or {}
    KeyLabDB.craftedPlans = KeyLabDB.craftedPlans or {}
    return KeyLabDB.craftedPlans
end

local function Recipe(recipeID)
    local database = KeyLab.CraftedRecipeDatabase
    return database and database.recipes and database.recipes[tonumber(recipeID)] or nil
end

local function Store(specID, create)
    local root = EnsureRoot()
    local characterKey = CharacterKey()
    specID = tonumber(specID) or CurrentSpecID()
    if create then
        root[characterKey] = root[characterKey] or {}
        root[characterKey][specID] = root[characterKey][specID] or {
            schemaVersion = SCHEMA_VERSION,
            recipes = {},
        }
    end
    local store = root[characterKey] and root[characterKey][specID] or nil
    if store and create then
        store.schemaVersion = SCHEMA_VERSION
        store.recipes = store.recipes or {}
    end
    return store
end

local function IsChoiceValid(slot, choice)
    if type(choice) ~= "table" or not slot then return false end
    local values = choice.kind == "currency" and slot.currencies or slot.items
    for _, id in ipairs(values or {}) do
        if tonumber(id) == tonumber(choice.id) then return true end
    end
    return false
end

local function IsPlayerChoiceSlot(slot)
    local text = string.lower(tostring(slot and slot.text or ""))
    return text == "add embellishment"
        or text == "customize secondary stats"
        or text == "amplify secondary stat"
end

local function NormalizePlan(plan, recipe)
    if not plan or not recipe then return nil end
    plan.recipeID = tonumber(recipe.recipeID or plan.recipeID)
    plan.itemID = tonumber(recipe.itemID or plan.itemID)
    plan.choices = plan.choices or {}
    for index, slot in ipairs(recipe.reagentSlots or {}) do
        if not IsPlayerChoiceSlot(slot) or not IsChoiceValid(slot, plan.choices[index]) then
            plan.choices[index] = nil
        end
    end
    return plan
end

function CraftedPlansDB.GetCurrentCharacterKey() return CharacterKey() end
function CraftedPlansDB.GetCurrentSpecID() return CurrentSpecID() end

function CraftedPlansDB.GetPlan(recipeID, specID)
    local store = Store(specID, false)
    local plan = store and store.recipes and store.recipes[tonumber(recipeID)] or nil
    return NormalizePlan(plan, Recipe(recipeID))
end

function CraftedPlansDB.IsPlanned(recipeID, specID)
    return CraftedPlansDB.GetPlan(recipeID, specID) ~= nil
end

function CraftedPlansDB.Add(recipeID, specID, slotInstance, approval)
    local recipe = Recipe(recipeID)
    if not recipe then return nil, "That crafted item is not in the current recipe database." end
    specID = tonumber(specID) or CurrentSpecID()
    local slot, reason, details = CraftedPlansDB.PrepareSave(recipeID, specID, slotInstance, approval)
    if not slot then return nil, reason, details end
    local store = Store(specID, true)
    local id = tonumber(recipeID)
    store.recipes[id] = store.recipes[id] or {
        recipeID = id,
        itemID = tonumber(recipe.itemID),
        savedAt = time and time() or 0,
        choices = {},
    }
    NormalizePlan(store.recipes[id], recipe)
    store.recipes[id].slotInstance = slot
    CraftedPlansDB.ApplyConflicts(details, specID)
    return store.recipes[id]
end

function CraftedPlansDB.Remove(recipeID, specID)
    local store = Store(specID, false)
    if not store or not store.recipes then return false end
    local id = tonumber(recipeID)
    local existed = store.recipes[id] ~= nil
    store.recipes[id] = nil
    return existed
end

-- The guide entry path edits a draft until the player explicitly saves it.
-- The ordinary Crafted Gear editor retains its existing immediate-save flow.
function CraftedPlansDB.SaveGuideDraft(recipeID, specID, choices, slotInstance, approval)
    if specID ~= CurrentSpecID() then return false, "Your specialization changed. Reopen the crafted item for this spec." end
    if InCombatLockdown and InCombatLockdown() then return false, "Wait until combat ends." end
    local recipe = Recipe(recipeID)
    if not recipe then return false, "That crafted item is not in the recipe database." end
    local checked = {}
    for slotIndex, choice in pairs(choices or {}) do
        local slot = recipe.reagentSlots[slotIndex]
        if not IsPlayerChoiceSlot(slot) or not IsChoiceValid(slot,choice) then return false, "An optional reagent is no longer valid. Please select it again." end
        checked[slotIndex] = {kind=choice.kind,id=choice.id}
    end
    local plan, reason, details = CraftedPlansDB.Add(recipeID, specID, slotInstance, approval)
    if not plan then return false, reason, details end
    plan.choices, plan.savedAt = checked, time and time() or 0
    return true
end

function CraftedPlansDB.Toggle(recipeID, specID)
    if CraftedPlansDB.IsPlanned(recipeID, specID) then
        CraftedPlansDB.Remove(recipeID, specID)
        return false
    end
    CraftedPlansDB.Add(recipeID, specID)
    return CraftedPlansDB.IsPlanned(recipeID, specID)
end

function CraftedPlansDB.SetChoice(recipeID, slotIndex, kind, id, specID)
    local plan = CraftedPlansDB.GetPlan(recipeID, specID) or CraftedPlansDB.Add(recipeID, specID)
    local recipe = Recipe(recipeID)
    local slot = recipe and recipe.reagentSlots and recipe.reagentSlots[tonumber(slotIndex)]
    if not plan or not slot or not IsPlayerChoiceSlot(slot) then return false end
    if kind == nil or id == nil then
        plan.choices[tonumber(slotIndex)] = nil
        plan.savedAt = time and time() or plan.savedAt
        return true
    end
    local choice = { kind = tostring(kind), id = tonumber(id) }
    if not IsChoiceValid(slot, choice) then return false end
    plan.choices[tonumber(slotIndex)] = choice
    plan.savedAt = time and time() or plan.savedAt
    return true
end

function CraftedPlansDB.GetPlans(specID)
    local store = Store(specID, false)
    local plans = {}
    for recipeID, plan in pairs(store and store.recipes or {}) do
        local recipe = Recipe(recipeID)
        if recipe then
            NormalizePlan(plan, recipe)
            table.insert(plans, plan)
        end
    end
    table.sort(plans, function(a, b)
        local recipeA, recipeB = Recipe(a.recipeID), Recipe(b.recipeID)
        return tostring(recipeA and recipeA.name or "") < tostring(recipeB and recipeB.name or "")
    end)
    return plans
end

function CraftedPlansDB.GetSlotOptions(recipeID, specID)
    local recipe = Recipe(recipeID)
    if not recipe then return {} end
    local slot = recipe.slot
    if slot == "Finger" then return {"Finger 1", "Finger 2"} end
    if slot == "Trinket" then return {"Trinket 1", "Trinket 2"} end
    if slot == "One-Hand" or slot == "Two-Hand" then
        local mapping = KeyLab.GearLootMapping
        local dual = mapping and mapping.IsTargetDualWieldEligible and mapping.IsTargetDualWieldEligible(recipe, specID)
        -- Reuse captured weapon subtype rules for crafted two-hand weapons.
        if not dual and slot == "Two-Hand" then
            local db = KeyLab.GearLootDatabase or {}
            local weaponNames = {[1]="Axe", [5]="Mace", [6]="Polearm", [8]="Sword", [10]="Staff"}
            local weaponName = weaponNames[recipe.subclassID]
            for id, specs in pairs(db.dualWieldBySpec or {}) do
                local known = db.items and db.items[id]
                if specs[tonumber(specID)] and known and known.slot == slot
                    and weaponName and known.armorType == weaponName then dual = true; break end
            end
            if tonumber(specID) == 72 and weaponName == "Polearm" then dual = true end
        end
        return dual and {"Main Hand", "Off Hand"} or {"Main Hand"}
    end
    if slot == "Ranged" then return {"Main Hand"} end
    return slot and {slot} or {}
end

local function PlanOccupies(plan, slot, specID)
    if plan.slotInstance then return plan.slotInstance == slot end
    -- Old paired-slot plans remain intact until the player assigns their slot.
    for _, candidate in ipairs(CraftedPlansDB.GetSlotOptions(plan.recipeID, specID)) do
        if candidate == slot then return true end
    end
    return false
end

function CraftedPlansDB.GetPlansForSlot(specID, slot)
    local out = {}
    for _, plan in ipairs(CraftedPlansDB.GetPlans(specID)) do
        if PlanOccupies(plan, slot, specID) then out[#out+1] = plan end
    end
    return out
end

function CraftedPlansDB.ClosesOffHand(recipeID, specID)
    local recipe = Recipe(recipeID)
    return recipe and (recipe.slot == "Two-Hand" or recipe.slot == "Ranged")
        and #CraftedPlansDB.GetSlotOptions(recipeID, specID) == 1 or false
end

function CraftedPlansDB.GetConflicts(specID, slot, exceptRecipe, closesOffHand, includeTargets)
    local affected = {[slot]=true}
    if slot == "Main Hand" and closesOffHand then affected["Off Hand"] = true end
    local out = {}
    for _, plan in ipairs(CraftedPlansDB.GetPlans(specID)) do
        if plan.recipeID ~= exceptRecipe then
            local conflict = false
            for candidate in pairs(affected) do if PlanOccupies(plan, candidate, specID) then conflict = true end end
            if slot == "Off Hand" and PlanOccupies(plan, "Main Hand", specID)
                and CraftedPlansDB.ClosesOffHand(plan.recipeID, specID) then conflict = true end
            if conflict then out[#out+1] = {kind="crafted", id=plan.recipeID, name=Recipe(plan.recipeID).name, slot=plan.slotInstance or Recipe(plan.recipeID).slot, savedAt=plan.savedAt} end
        end
    end
    local targets = KeyLab.LootTargetsDB
    if includeTargets and targets then
        local main = targets.GetTargetForSlot(specID, "Main Hand", "MN_S2")
        if slot == "Off Hand" and main and main.closesOffHand then affected["Main Hand"] = true end
        for candidate in pairs(affected) do
            local target = targets.GetTargetForSlot(specID, candidate, "MN_S2")
            if target then out[#out+1] = {kind="target", id=target.itemID, name=target.itemName or ("Item "..target.itemID), slot=candidate, savedAt=target.savedAt} end
        end
    end
    table.sort(out, function(a,b) return a.kind..a.slot..a.id < b.kind..b.slot..b.id end)
    return out
end

function CraftedPlansDB.ConflictDetails(conflicts)
    local lines, keys = {}, {}
    for _, conflict in ipairs(conflicts) do
        lines[#lines+1] = conflict.slot .. ": " .. conflict.name .. (conflict.kind == "crafted" and " (Crafted Plan)" or " (Target)")
        keys[#keys+1] = conflict.kind..":"..conflict.slot..":"..conflict.id..":"..tostring(conflict.savedAt or 0)
    end
    return {text=table.concat(lines,"\n"), token=table.concat(keys,"|"), conflicts=conflicts}
end

function CraftedPlansDB.ApplyConflicts(details, specID)
    for _, conflict in ipairs(details and details.conflicts or {}) do
        if conflict.kind == "crafted" then CraftedPlansDB.Remove(conflict.id, specID)
        elseif KeyLab.LootTargetsDB then KeyLab.LootTargetsDB.ClearTargetForCraft(specID, conflict.slot) end
    end
end

function CraftedPlansDB.PrepareSave(recipeID, specID, slot, approval)
    if tonumber(specID) ~= CurrentSpecID() then return nil, "Your specialization changed. Reopen this plan." end
    if InCombatLockdown and InCombatLockdown() then return nil, "Wait until combat ends." end
    local options = CraftedPlansDB.GetSlotOptions(recipeID, specID)
    local previous = CraftedPlansDB.GetPlan(recipeID, specID)
    slot = slot or (previous and previous.slotInstance) or (#options == 1 and options[1])
    local valid = false
    for _, candidate in ipairs(options) do if candidate == slot then valid = true end end
    if not valid then return nil, "Choose the exact equipment slot for this crafted item." end
    local details = CraftedPlansDB.ConflictDetails(CraftedPlansDB.GetConflicts(specID, slot, tonumber(recipeID), CraftedPlansDB.ClosesOffHand(recipeID, specID), true))
    if #details.conflicts > 0 and approval ~= details.token then return nil, "plan_conflict", details end
    return slot, nil, details
end

return CraftedPlansDB
