local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.CraftingAnalysis = KeyLab.CraftingAnalysis or {}
local Analysis = KeyLab.CraftingAnalysis

--[[
KeyLab_CraftingAnalysis.lua

Reads KeyLab's generated recipe catalog and the player's saved crafted plans.
This layer owns filtering, reagent-role rules, quality-name de-duplication,
owned counts, and shopping-list totals. The UI only renders these results.
]]

local SLOT_ORDER = {
    Head = 1, Neck = 2, Shoulders = 3, Back = 4, Chest = 5, Wrist = 6,
    Hands = 7, Waist = 8, Legs = 9, Feet = 10, Finger = 11, Trinket = 12,
    ["One-Hand"] = 13, ["Two-Hand"] = 14, Ranged = 15, ["Off Hand"] = 16,
}

local function Database() return KeyLab.CraftedRecipeDatabase or {} end
local function Lower(value) return string.lower(tostring(value or "")) end
local function Trim(value) return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "") end

local function RuntimeItemName(itemID)
    return (Database().itemNames and Database().itemNames[tonumber(itemID)])
        or ("Item " .. tostring(itemID))
end

local function RuntimeCurrencyName(currencyID)
    return (Database().currencyNames and Database().currencyNames[tonumber(currencyID)])
        or ("Currency " .. tostring(currencyID))
end

local function ItemCount(itemID)
    if C_Item and C_Item.GetItemCount then
        return tonumber(C_Item.GetItemCount(itemID, true, false, true)) or 0
    end
    if GetItemCount then return tonumber(GetItemCount(itemID, true)) or 0 end
    return 0
end

local function CurrencyCount(currencyID)
    local info = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo
        and C_CurrencyInfo.GetCurrencyInfo(currencyID) or nil
    return tonumber(info and info.quantity) or 0
end

local function IsUsableRecipe(recipe)
    if not recipe or not recipe.itemID then return false end
    local usable, noMana
    if C_Item and C_Item.IsUsableItem then usable, noMana = C_Item.IsUsableItem(recipe.itemID)
    elseif IsUsableItem then usable, noMana = IsUsableItem(recipe.itemID) end
    if usable == true then return true end
    if usable == false and noMana ~= nil then return false end
    return true
end

local function SlotText(slot) return Lower(slot and slot.text) end
local function IsAuthenticity(slot) return SlotText(slot):find("artisan's authenticity", 1, true) ~= nil end
local function IsPower(slot)
    local text = SlotText(slot)
    return text:find("infuse with power", 1, true) ~= nil or text == "empower"
end
local function IsHeraldry(slot) return SlotText(slot):find("heraldry", 1, true) ~= nil end
local function IsSelectableOptional(slot)
    local text = SlotText(slot)
    return text == "add embellishment"
        or text == "customize secondary stats"
        or text == "amplify secondary stat"
end

-- Reagent qualities use different item IDs but share one player-facing name.
-- Treat those IDs as one material everywhere in the planner.
local function ItemGroups(slot)
    local groups, byName = {}, {}
    for _, itemID in ipairs(slot and slot.items or {}) do
        local name = RuntimeItemName(itemID)
        local key = Lower(name)
        local group = byName[key]
        if not group then
            group = { name = name, ids = {}, id = tonumber(itemID) }
            byName[key] = group
            table.insert(groups, group)
        end
        table.insert(group.ids, tonumber(itemID))
    end
    return groups
end

local function GroupOwned(group)
    local count = 0
    for _, itemID in ipairs(group and group.ids or {}) do count = count + ItemCount(itemID) end
    return count
end

local function FindItemGroup(slot, itemID)
    for _, group in ipairs(ItemGroups(slot)) do
        for _, candidateID in ipairs(group.ids) do
            if tonumber(candidateID) == tonumber(itemID) then return group end
        end
    end
    return nil
end

function Analysis.GetRecipe(recipeID)
    return Database().recipes and Database().recipes[tonumber(recipeID)] or nil
end

function Analysis.GetRecipes(filters)
    filters = filters or {}
    local search = Lower(Trim(filters.search))
    local out = {}
    for recipeID, recipe in pairs(Database().recipes or {}) do
        local professionMatches = not filters.professionID
            or tonumber(recipe.professionID) == tonumber(filters.professionID)
        local slotMatches = not filters.slot or recipe.slot == filters.slot
        local weaponMatches = not filters.weaponType or recipe.weaponType == filters.weaponType
        local armorMatches = not filters.armorType or recipe.armorType == filters.armorType
        local levelMatches = not filters.iLvlMin or tonumber(recipe.iLvlMin) == tonumber(filters.iLvlMin)
        local pvpMatches = filters.isPvP == nil or recipe.isPvP == filters.isPvP
        local plannedMatches = not filters.plannedOnly
            or (KeyLab.CraftedPlansDB and KeyLab.CraftedPlansDB.IsPlanned
                and KeyLab.CraftedPlansDB.IsPlanned(recipeID))
        local searchMatches = search == "" or Lower(recipe.name):find(search, 1, true)
        local usableMatches = filters.currentCharacterOnly == false or IsUsableRecipe(recipe)
        if tonumber(recipe.iLvlMin) ~= 1 and professionMatches and slotMatches and weaponMatches
            and armorMatches and levelMatches and pvpMatches and plannedMatches
            and searchMatches and usableMatches then
            recipe.recipeID = tonumber(recipe.recipeID or recipeID)
            table.insert(out, recipe)
        end
    end
    table.sort(out, function(a, b)
        local slotA, slotB = SLOT_ORDER[a.slot] or 99, SLOT_ORDER[b.slot] or 99
        if slotA ~= slotB then return slotA < slotB end
        if tonumber(a.iLvlMin) ~= tonumber(b.iLvlMin) then return (tonumber(a.iLvlMin) or 0) > (tonumber(b.iLvlMin) or 0) end
        return tostring(a.name or "") < tostring(b.name or "")
    end)
    return out
end

function Analysis.GetSlotOptions()
    local seen, options = {}, {{ value = nil, label = "All Slots" }}
    for _, recipe in pairs(Database().recipes or {}) do seen[recipe.slot or "Other"] = true end
    local slots = {}
    for slot in pairs(seen) do table.insert(slots, slot) end
    table.sort(slots, function(a, b)
        local orderA, orderB = SLOT_ORDER[a] or 99, SLOT_ORDER[b] or 99
        if orderA ~= orderB then return orderA < orderB end
        return a < b
    end)
    for _, slot in ipairs(slots) do table.insert(options, { value = slot, label = slot }) end
    return options
end

function Analysis.GetProfessionOptions()
    local options = {{ value = nil, label = "All Professions" }}
    for professionID, name in pairs(Database().professionNames or {}) do
        table.insert(options, { value = tonumber(professionID), label = name })
    end
    table.sort(options, function(a, b)
        if a.value == nil then return true end
        if b.value == nil then return false end
        return tostring(a.label) < tostring(b.label)
    end)
    return options
end

function Analysis.GetWeaponTypeOptions()
    return {
        { value = nil, label = "All Weapon Types" },
        { value = "One-Handed", label = "One-Handed" },
        { value = "Two-Handed", label = "Two-Handed" },
        { value = "Ranged", label = "Ranged" },
        { value = "Miscellaneous", label = "Miscellaneous" },
    }
end

function Analysis.GetArmorTypeOptions()
    return {
        { value = nil, label = "All Armor Types" },
        { value = "Plate", label = "Plate" }, { value = "Mail", label = "Mail" },
        { value = "Leather", label = "Leather" }, { value = "Cloth", label = "Cloth" },
    }
end

function Analysis.GetItemLevelOptions()
    return {
        { value = nil, label = "All Item Levels" },
        { value = 246, label = "246" }, { value = 201, label = "201" },
        { value = 175, label = "175" }, { value = 165, label = "165" },
    }
end

function Analysis.GetPvPOptions()
    return {
        { value = nil, label = "All Items" },
        { value = true, label = "PvP Items" },
        { value = false, label = "Non-PvP Items" },
    }
end

function Analysis.GetPlanStatusOptions()
    return {
        { value = false, label = "All Items" },
        { value = true, label = "Planned Items" },
    }
end

function Analysis.GetChoiceOptions(recipeID, slotIndex, includeNone)
    local recipe = Analysis.GetRecipe(recipeID)
    local slot = recipe and recipe.reagentSlots and recipe.reagentSlots[tonumber(slotIndex)]
    local options = {}
    if not slot or not IsSelectableOptional(slot) then return options end
    if includeNone or not slot.required then table.insert(options, { value = "none", label = "None" }) end
    for _, group in ipairs(ItemGroups(slot)) do
        table.insert(options, {
            value = "item:" .. tostring(group.id), label = group.name,
            kind = "item", id = group.id, ids = group.ids,
        })
    end
    return options
end

function Analysis.GetChoiceValue(plan, slotIndex)
    local choice = plan and plan.choices and plan.choices[tonumber(slotIndex)]
    if not choice then return "none" end
    if choice.kind == "item" then
        local recipe = Analysis.GetRecipe(plan.recipeID)
        local slot = recipe and recipe.reagentSlots and recipe.reagentSlots[tonumber(slotIndex)]
        local group = FindItemGroup(slot, choice.id)
        if group then return "item:" .. tostring(group.id) end
    end
    return tostring(choice.kind) .. ":" .. tostring(choice.id)
end

local function CountsForItems(slot)
    local parts = {}
    for _, group in ipairs(ItemGroups(slot)) do
        table.insert(parts, group.name .. ": " .. tostring(GroupOwned(group)))
    end
    return parts
end

local function CountsForCurrencies(slot)
    local parts = {}
    for _, currencyID in ipairs(slot and slot.currencies or {}) do
        table.insert(parts, RuntimeCurrencyName(currencyID) .. ": " .. tostring(CurrencyCount(currencyID)))
    end
    return parts
end

function Analysis.GetRecipeDisplayRows(recipeID)
    local recipe = Analysis.GetRecipe(recipeID)
    local rows = {}
    if not recipe then return rows end
    for slotIndex, slot in ipairs(recipe.reagentSlots or {}) do
        if not IsAuthenticity(slot) then
            local quantity = tonumber(slot.quantity) or 0
            if IsPower(slot) then
                local parts = CountsForCurrencies(slot)
                table.insert(rows, {
                    kind = "power", slotIndex = slotIndex, title = slot.text,
                    quantity = quantity > 0 and quantity or 80,
                    detail = (#parts > 0 and table.concat(parts, "  |  ") or "Crest counts unavailable"),
                })
            elseif IsHeraldry(slot) then
                local parts = CountsForItems(slot)
                table.insert(rows, {
                    kind = "heraldry", slotIndex = slotIndex, title = "Competitor's Heraldry",
                    quantity = quantity, detail = table.concat(parts, "  |  "),
                })
            elseif IsSelectableOptional(slot) then
                table.insert(rows, {
                    kind = "optional", slotIndex = slotIndex, title = slot.text,
                    quantity = quantity, detail = "",
                })
            elseif slot.required then
                local groups = ItemGroups(slot)
                if #groups > 0 then
                    local names = {}
                    for _, group in ipairs(groups) do table.insert(names, group.name) end
                    table.insert(rows, {
                        kind = "required", slotIndex = slotIndex,
                        title = table.concat(names, " / "), quantity = quantity,
                        detail = "",
                    })
                elseif #(slot.currencies or {}) > 0 then
                    table.insert(rows, {
                        kind = "requiredCurrency", slotIndex = slotIndex,
                        title = slot.text or "Currency", quantity = quantity,
                        detail = table.concat(CountsForCurrencies(slot), "  |  "),
                    })
                end
            end
        end
    end
    return rows
end

local function AddGroupedItem(totals, group, quantity, slot, recipe)
    local key = "items:" .. Lower(group.name)
    local entry = totals[key]
    if not entry then
        entry = {
            key = key, kind = "items", ids = group.ids, name = group.name,
            required = 0, owned = 0, stillNeeded = 0,
            special = SlotText(slot):find("spark", 1, true) ~= nil or IsHeraldry(slot),
            recipes = {},
        }
        totals[key] = entry
    end
    local known = {}
    for _, itemID in ipairs(entry.ids or {}) do known[tonumber(itemID)] = true end
    for _, itemID in ipairs(group.ids or {}) do
        itemID = tonumber(itemID)
        if itemID and not known[itemID] then
            table.insert(entry.ids, itemID)
            known[itemID] = true
        end
    end
    entry.required = entry.required + (tonumber(quantity) or 0)
    entry.recipes[recipe.name or tostring(recipe.itemID)] = true
end

local function AddCurrency(totals, currencyID, quantity, recipe)
    local key = "currency:" .. tostring(currencyID)
    local entry = totals[key]
    if not entry then
        entry = {
            key = key, kind = "currency", id = tonumber(currencyID),
            name = RuntimeCurrencyName(currencyID), required = 0, owned = 0,
            stillNeeded = 0, special = true, recipes = {},
        }
        totals[key] = entry
    end
    entry.required = entry.required + (tonumber(quantity) or 0)
    entry.recipes[recipe.name or tostring(recipe.itemID)] = true
end

function Analysis.GetShoppingList(specID)
    local totals, resourceByRecipe = {}, {}
    local plans = KeyLab.CraftedPlansDB and KeyLab.CraftedPlansDB.GetPlans
        and KeyLab.CraftedPlansDB.GetPlans(specID) or {}

    local function ResourceEntry(recipe)
        local key = tonumber(recipe.recipeID) or tonumber(recipe.itemID) or tostring(recipe.name)
        local entry = resourceByRecipe[key]
        if not entry then
            entry = { name = recipe.name or "Crafted Item", lines = {} }
            resourceByRecipe[key] = entry
        end
        return entry
    end

    local hasCrests, hasHeraldry = false, false

    local function AddResourceLine(recipe, name, owned, required, kind)
        local entry = ResourceEntry(recipe)
        entry.kind = entry.kind and entry.kind ~= kind and "mixed" or (entry.kind or kind)
        if kind == "crest" then hasCrests = true end
        if kind == "heraldry" then hasHeraldry = true end
        table.insert(entry.lines, {
            name = name or "Crafting Resource",
            owned = tonumber(owned) or 0,
            required = tonumber(required) or 0,
        })
    end

    for _, plan in ipairs(plans) do
        local recipe = Analysis.GetRecipe(plan.recipeID)
        if recipe then
            for slotIndex, slot in ipairs(recipe.reagentSlots or {}) do
                if IsPower(slot) then
                    local quantity = tonumber(slot.quantity) or 80
                    for _, currencyID in ipairs(slot.currencies or {}) do
                        currencyID = tonumber(currencyID)
                        AddResourceLine(recipe, RuntimeCurrencyName(currencyID), CurrencyCount(currencyID), quantity, "crest")
                    end
                elseif not IsAuthenticity(slot) then
                    if slot.required then
                        if IsHeraldry(slot) then
                            local quantity = tonumber(slot.quantity) or 1
                            for _, group in ipairs(ItemGroups(slot)) do
                                AddResourceLine(recipe, group.name, GroupOwned(group), quantity, "heraldry")
                            end
                        else
                            for _, group in ipairs(ItemGroups(slot)) do
                                AddGroupedItem(totals, group, slot.quantity, slot, recipe)
                            end
                            for _, currencyID in ipairs(slot.currencies or {}) do
                                AddCurrency(totals, currencyID, slot.quantity, recipe)
                            end
                        end
                    elseif IsSelectableOptional(slot) then
                        local choice = plan.choices and plan.choices[slotIndex]
                        local group = choice and choice.kind == "item" and FindItemGroup(slot, choice.id) or nil
                        if group then AddGroupedItem(totals, group, slot.quantity, slot, recipe) end
                    end
                end
            end
        end
    end

    local requiredMaterials, ownedMaterials, resourceRequirements = {}, {}, {}
    for _, entry in pairs(totals) do
        if entry.kind == "currency" then entry.owned = CurrencyCount(entry.id)
        else
            entry.owned = 0
            for _, itemID in ipairs(entry.ids or {}) do entry.owned = entry.owned + ItemCount(itemID) end
        end
        entry.stillNeeded = math.max(0, entry.required - entry.owned)

        table.insert(requiredMaterials, {
            kind = "requiredMaterial",
            name = entry.name,
            required = entry.required or 0,
            owned = entry.owned or 0,
            summary = "",
            complete = false,
        })

        if entry.kind == "items" and (entry.owned or 0) > 0 then
            local qualityCount = #(entry.ids or {})
            for qualityIndex, itemID in ipairs(entry.ids or {}) do
                local owned = ItemCount(itemID)
                if owned > 0 then
                    table.insert(ownedMaterials, {
                        kind = "ownedMaterial",
                        name = entry.name,
                        owned = owned,
                        totalOwned = entry.owned or 0,
                        required = entry.required or 0,
                        qualityIndex = qualityIndex,
                        qualityCount = qualityCount,
                        summary = qualityCount > 1 and ("Quality " .. tostring(qualityIndex)) or "",
                        complete = (entry.owned or 0) >= (entry.required or 0),
                    })
                end
            end
        end
    end

    for _, entry in pairs(resourceByRecipe) do
        local lines = {}
        for _, line in ipairs(entry.lines or {}) do
            table.insert(lines, string.format("%s  %d / %d", line.name, line.owned, line.required))
        end
        table.insert(resourceRequirements, {
            kind = "resourceRequirement",
            name = entry.name,
            summary = table.concat(lines, "\n"),
            lines = entry.lines,
            lineCount = #lines,
            complete = false,
        })
    end

    local function Sort(list)
        table.sort(list, function(a, b)
            if tostring(a.name) ~= tostring(b.name) then return tostring(a.name) < tostring(b.name) end
            return (tonumber(a.qualityIndex) or 0) < (tonumber(b.qualityIndex) or 0)
        end)
    end
    Sort(requiredMaterials)
    Sort(ownedMaterials)
    Sort(resourceRequirements)
    return {
        planCount = #plans,
        requiredMaterials = requiredMaterials,
        resourceRequirements = resourceRequirements,
        ownedMaterials = ownedMaterials,
        resourceTitle = hasCrests and hasHeraldry and "Crests & Heraldry Needed"
            or (hasHeraldry and "Heraldry Needed" or "Crests Needed"),
        -- Compatibility aliases for any code that has not refreshed yet.
        auctionHouse = requiredMaterials,
        resources = resourceRequirements,
        alreadyOwned = ownedMaterials,
        special = {}, unresolved = {},
    }
end

return Analysis
