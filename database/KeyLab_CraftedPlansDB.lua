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
    schemaVersion = 2,
    recipes = {
        [recipeID] = {
            recipeID, itemID, savedAt,
            choices = { [reagentSlotIndex] = { kind = "item", id = itemID } },
        },
    },
}
]]

local SCHEMA_VERSION = 2

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

function CraftedPlansDB.Add(recipeID, specID)
    local recipe = Recipe(recipeID)
    if not recipe then return nil, "That crafted item is not in the current recipe database." end
    local store = Store(specID, true)
    local id = tonumber(recipeID)
    store.recipes[id] = store.recipes[id] or {
        recipeID = id,
        itemID = tonumber(recipe.itemID),
        savedAt = time and time() or 0,
        choices = {},
    }
    NormalizePlan(store.recipes[id], recipe)
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

function CraftedPlansDB.Toggle(recipeID, specID)
    if CraftedPlansDB.IsPlanned(recipeID, specID) then
        CraftedPlansDB.Remove(recipeID, specID)
        return false
    end
    CraftedPlansDB.Add(recipeID, specID)
    return true
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

return CraftedPlansDB
