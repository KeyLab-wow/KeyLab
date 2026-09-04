local _, KeyLab = ...
local Guides = {}
KeyLab.GuideRecommendations = Guides

function Guides.CurrentSpec()
    return KeyLab.LootTargetsDB.GetCurrentSpecID()
end

function Guides.GetRecord(source, specID)
    specID = specID or Guides.CurrentSpec()
    for _, record in ipairs(KeyLab.GuideRecommendationsData.records) do
        if record.sourceID == source and record.specID == specID then return record end
    end
end

-- This approved BoE is a guide-only supplemental record, not a fabricated
-- stat/loot row in the master database. No boss or item level is invented.
function Guides.GetSupplementalItem(itemID)
    if tonumber(itemID) ~= 271444 then return nil end
    return {
        itemID = 271444, name = "Pauldrons of the Forgotten Sacrifice",
        slot = "Shoulder", equipLoc = "INVTYPE_SHOULDER", armorType = "Plate",
        mnSeason = 2, seasonKey = "MN_S2", sourceID = 1320, sourceType = "Raid",
        sourceName = "BoE Trash Drop - The Venomous Abyss",
        specs = { [65]=true,[66]=true,[70]=true,[71]=true,[72]=true,[73]=true,[250]=true,[251]=true,[252]=true },
        sources = { [1320] = {sourceID=1320, sourceType="Raid", sourceName="BoE Trash Drop - The Venomous Abyss", encounterIDs={}} },
        guideSupplemental = true,
    }
end

function Guides.GetItem(id, specID)
    return KeyLab.GearLootMapping.GetItem(id, specID or Guides.CurrentSpec())
end

local recipeByItem
function Guides.GetRecipe(itemID)
    if not recipeByItem then
        recipeByItem = {}
        for _, recipe in pairs(KeyLab.CraftedRecipeDatabase.recipes or {}) do
            recipeByItem[recipe.itemID] = recipeByItem[recipe.itemID] or recipe
        end
    end
    return recipeByItem[tonumber(itemID)]
end

function Guides.IsCrafted(row)
    return Guides.GetRecipe(row.itemID) ~= nil or row.source:lower():find("crafted",1,true) ~= nil
end

function Guides.GetTargetItem(row, specID)
    return Guides.GetItem(row.originalID or row.itemID, specID)
end

function Guides.ApplyProfile(record, profile, choices, approval)
    if not record or record.specID ~= Guides.CurrentSpec() then return false, "Your specialization changed. Review the current spec's list." end
    if InCombatLockdown and InCombatLockdown() then return false, "Wait until combat ends." end
    local bySlot, entries = {}, {}
    for index, row in ipairs(profile.items) do
        bySlot[row.slot] = bySlot[row.slot] or {}
        table.insert(bySlot[row.slot], {row=row,index=index})
    end
    for slot, rows in pairs(bySlot) do
        local selected = rows[1]
        if #rows > 1 then
            selected = nil
            for _, candidate in ipairs(rows) do if choices and choices[slot] == candidate.index then selected=candidate end end
            if not selected then return false, "Choose one item for " .. slot .. " before setting Targets." end
        end
        if not Guides.IsCrafted(selected.row) then
            local item = Guides.GetTargetItem(selected.row, record.specID)
            if not item then return false, "No verified database item for " .. selected.row.name .. ". No Targets were changed." end
            table.insert(entries, {item=item,slotInstance=slot})
        end
    end
    return KeyLab.LootTargetsDB.ReplaceGuideTargets(record.specID, entries, approval)
end
