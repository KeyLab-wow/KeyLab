-- KeyLab_GearTargets.lua
-- Fixed-size manual Gear Targets browser plus the player-initiated Stat Goal Matcher.

local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.UI = KeyLab.UI or {}
KeyLab.Tabs = KeyLab.Tabs or {}

local GearTargets = {}
KeyLab.Tabs.GearTargets = GearTargets
local Theme = KeyLab.UI.Theme or {}
local SPACING = Theme.spacing or { card = 14 }
local HEADER = Theme.tabHeader or { x = 18, titleY = -18, titleSize = 16 }

local CFG = {
    colors = {
        bg = {0.018, 0.026, 0.056, 0.96},
        panel = {0.026, 0.046, 0.086, 0.94},
        box = {0.030, 0.052, 0.098, 0.92},
        border = {0.240, 0.380, 0.620, 0.62},
        gold = {0.820, 0.760, 0.580, 1.0},
        text = {0.940, 0.960, 0.990, 1.0},
        muted = {0.680, 0.730, 0.820, 1.0},
        blue = {0.500, 0.680, 0.940, 1.0},
        green = {0.460, 0.780, 0.500, 1.0},
        warning = {0.840, 0.720, 0.420, 1.0},
        raid = {0.900, 0.680, 0.900, 1.0},
    },
    rowHeight = 54,
}

-- These dimensions deliberately match the previous Gear Targets tab.
local TABLE_WIDTH = 880
local FILTER_CARD_HEIGHT = 136
local MATCHER_CARD_HEIGHT = 144
local TABLE_COLUMNS = {
    item = { x = 38, width = 236, label = "Item" },
    slot = { x = 280, width = 76, label = "Slot" },
    source = { x = 362, width = 142, label = "Source" },
    stats = { x = 510, width = 154, label = "Stats" },
    match = { x = 670, width = 106, label = "Matcher" },
    status = { x = 782, width = 94, label = "Status" },
}

local PRIMARY_OPTIONS = {
    { label = "Stamina", value = "Stam", stamina = true },
    { label = "Intellect", value = "Int", primary = true },
    { label = "Strength", value = "Str", primary = true },
    { label = "Agility", value = "Agi", primary = true },
}

local SECONDARY_OPTIONS = {
    { label = "Critical Strike", shortLabel = "Crit", value = "Crit" },
    { label = "Haste", shortLabel = "Haste", value = "Haste" },
    { label = "Mastery", shortLabel = "Mastery", value = "Mastery" },
    { label = "Versatility", shortLabel = "Vers", value = "Vers" },
}

local GOAL_FIELDS = {
    { key = "crit", label = "Crit" },
    { key = "haste", label = "Haste" },
    { key = "mastery", label = "Mastery" },
    { key = "versatility", label = "Versatility" },
}

local ITEM_TYPE_OPTIONS = {
    { text = "Dungeon & Raid Items", value = nil },
    { text = "Dungeon Items Only", value = "Dungeon" },
    { text = "Raid Items Only", value = "Raid" },
}

local MATCHER_ITEM_SOURCE_OPTIONS = {
    { text = "Master Item Database", value = "master" },
    { text = "Equipped + Bags Only", value = "owned" },
}

local MATCHER_STYLE_OPTIONS = {
    { text = "Balanced", value = "balanced" },
    { text = "Favor Priority", value = "priority" },
}

local STATUS_FILTER_OPTIONS = {
    { text = "All Items", value = "all" },
    { text = "Goal Match Items", value = "goal_match" },
    { text = "Targets Only", value = "target" },
    { text = "Alternatives Only", value = "alternative" },
    { text = "Targets & Alternatives", value = "saved" },
}

local STATUS_COLORS = {
    target = {0.460, 0.780, 0.500, 1.0},
    alternative = {0.500, 0.680, 0.940, 1.0},
    unmarked = {0.680, 0.730, 0.820, 1.0},
}

local STATUS_SORT_RANK = { target = 1, alternative = 2, unmarked = 3 }
local CATALYST_NON_SET_ARMOR_SLOTS = { Back = true, Wrist = true, Waist = true, Feet = true }
local statusMenuFrame

local function SetBackdrop(frame, color, borderColor, edgeSizeOverride)
    local edgeSize = edgeSizeOverride or 1
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        edgeSize = edgeSize,
    })
    frame:SetBackdropColor(unpack(color or CFG.colors.panel))
    frame:SetBackdropBorderColor(unpack(borderColor or CFG.colors.border))
end

local function SetPixelPoint(region, ...)
    if PixelUtil and PixelUtil.SetPoint then
        PixelUtil.SetPoint(region, ...)
    else
        region:SetPoint(...)
    end
end

local function SetPixelHeight(region, height)
    if PixelUtil and PixelUtil.SetHeight then
        PixelUtil.SetHeight(region, height)
    else
        region:SetHeight(height)
    end
end

local function MakeText(parent, text, template, size, color, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    if size then fs:SetFont(STANDARD_TEXT_FONT, size, "") end
    fs:SetTextColor(unpack(color or CFG.colors.text))
    fs:SetJustifyH(justify or "LEFT")
    fs:SetJustifyV("TOP")
    fs:SetWordWrap(false)
    fs:SetText(text or "")
    return fs
end

local function MakeDropdown(parent, width, x, y, labelText, initFunc)
    local label = MakeText(parent, labelText, "GameFontDisableSmall", nil, CFG.colors.muted)
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetSize(width, 16)
    local dropdown = KeyLab.UI.Theme.CreateLegacyDropdown(parent)
    KeyLab.UI.Theme.StyleDropdownField(dropdown)
    dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", x - 18, y - 18)
    UIDropDownMenu_SetWidth(dropdown, width)
    UIDropDownMenu_Initialize(dropdown, initFunc)
    return dropdown, label
end

local function SetDropdownText(dropdown, text)
    if dropdown then UIDropDownMenu_SetText(dropdown, text or "All") end
end

local function MakeSmallButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 46, height or 20)
    SetBackdrop(button, CFG.colors.box, CFG.colors.border)
    button.label = MakeText(button, text or "", "GameFontHighlightSmall", nil, CFG.colors.text, "CENTER")
    button.label:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.label:SetSize((width or 46) - 4, (height or 20) - 2)
    button:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(CFG.colors.blue)) end)
    button:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(CFG.colors.border)) end)
    return button
end

local function StyleGearTargetControlButton(button)
    if not button then return end
    local normal = {0.055, 0.095, 0.170, 0.98}
    local hover = {0.095, 0.180, 0.310, 1.00}
    local pressed = {0.175, 0.145, 0.070, 1.00}

    if button.label then
        button.label:ClearAllPoints()
        button.label:SetPoint("CENTER", button, "CENTER", 0, -1)
        button.label:SetJustifyV("MIDDLE")
    end

    button:SetBackdropColor(unpack(normal))
    button:HookScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(hover))
    end)
    button:HookScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(normal))
    end)
    button:HookScript("OnMouseDown", function(self)
        self:SetBackdropColor(unpack(pressed))
    end)
    button:HookScript("OnMouseUp", function(self)
        self:SetBackdropColor(unpack(self:IsMouseOver() and hover or normal))
    end)
end

local function MakeActionButton(parent, text, width, height)
    if Theme.CreateButton then
        return Theme.CreateButton(parent, text or "", width or 164, height or 26)
    end
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 164, height or 26)
    SetBackdrop(button, CFG.colors.box, CFG.colors.border)
    button.label = MakeText(button, text or "", "GameFontHighlightSmall", nil, CFG.colors.text, "CENTER")
    button.label:SetAllPoints(button)
    button.label:SetJustifyV("MIDDLE")
    button.SetText = function(self, value) self.label:SetText(value or "") end
    return button
end

local function MakeEditBox(parent, width, height)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(width or 48, height or 22)
    box:SetAutoFocus(false)
    box:SetJustifyH("CENTER")
    box:SetMaxLetters(6)
    box:SetNumeric(false)
    box:SetFontObject("GameFontHighlightSmall")
    return box
end

local function MakeSearchBox(parent, width, height, placeholderText)
    local box = Theme.CreateInput and Theme.CreateInput(parent, width or 180, height or 26)
        or CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    box:SetSize(width or 180, height or 26)
    box:SetAutoFocus(false)
    box:SetJustifyH("LEFT")
    if box.SetJustifyV then box:SetJustifyV("MIDDLE") end
    box:SetMaxLetters(64)
    box:SetFontObject("GameFontHighlightSmall")
    if box.SetTextInsets then box:SetTextInsets(8, 8, 0, 0) end
    box.placeholder = MakeText(box, placeholderText or "", "GameFontDisableSmall", nil, CFG.colors.muted)
    box.placeholder:SetPoint("LEFT", box, "LEFT", 8, -1)
    box.placeholder:SetSize((width or 180) - 16, 18)
    box.placeholder:SetJustifyV("MIDDLE")
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return box
end

local function CurrentSpecID()
    return KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.GetCurrentSpecID and KeyLab.LootTargetsDB.GetCurrentSpecID() or 0
end

local function CurrentClassID()
    return KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.GetCurrentClassID and KeyLab.LootTargetsDB.GetCurrentClassID() or 0
end

local function SpecName(specID)
    return KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.GetSpecName and KeyLab.LootTargetsDB.GetSpecName(specID) or ("Spec " .. tostring(specID or 0))
end

local function TargetSpecID()
    return CurrentSpecID()
end

local function CleanText(text)
    local cleaned = tostring(text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    return cleaned
end

local function ItemDisplayName(item)
    return CleanText(item and item.name or "Unknown Item")
end

local function ItemDisplayStats(item)
    return item and item.displayStatText and item.displayStatText ~= "" and item.displayStatText
        or item and item.statText and item.statText ~= "" and item.statText
        or "-"
end

local function ItemDisplaySource(item)
    return item and item.displaySourceName and item.displaySourceName ~= "" and item.displaySourceName
        or item and item.sourceName and item.sourceName ~= "" and item.sourceName
        or "-"
end

local function GetItemStatus(itemID)
    return KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.GetStatus and KeyLab.LootTargetsDB.GetStatus(TargetSpecID(), itemID) or nil
end

local function StatusLabel(status)
    return KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.GetStatusLabel and KeyLab.LootTargetsDB.GetStatusLabel(status) or "Unmarked"
end

local function ItemTypeLabel(value)
    for _, option in ipairs(ITEM_TYPE_OPTIONS) do if option.value == value then return option.text end end
    return ITEM_TYPE_OPTIONS[1].text
end

local function MatcherItemSourceLabel(value)
    for _, option in ipairs(MATCHER_ITEM_SOURCE_OPTIONS) do if option.value == value then return option.text end end
    return MATCHER_ITEM_SOURCE_OPTIONS[1].text
end

local function MatcherStyleLabel(value)
    for _, option in ipairs(MATCHER_STYLE_OPTIONS) do if option.value == value then return option.text end end
    return MATCHER_STYLE_OPTIONS[1].text
end

local function MatcherPoolLabel(result)
    if result and result.itemSource == "owned" then return "Equipped + Bags (track-aware)" end
    return ItemTypeLabel(result and result.itemType)
end

local function StatusFilterLabel(value)
    for _, option in ipairs(STATUS_FILTER_OPTIONS) do if option.value == value then return option.text end end
    return STATUS_FILTER_OPTIONS[1].text
end

local function SourceLabel(sourceID)
    local source = KeyLab.GearLootMapping and KeyLab.GearLootMapping.GetSource and KeyLab.GearLootMapping.GetSource(sourceID)
    return source and (source.sourceName or source.name) or "All Sources"
end

local function LootLocationLabel()
    if GearTargets.selectedEncounterID and KeyLab.GearLootMapping and KeyLab.GearLootMapping.GetRaidBossListForClass then
        for _, boss in ipairs(KeyLab.GearLootMapping.GetRaidBossListForClass(CurrentClassID()) or {}) do
            if tonumber(boss.encounterID) == tonumber(GearTargets.selectedEncounterID)
                and tonumber(boss.sourceID) == tonumber(GearTargets.selectedSourceID) then
                return boss.text or ((boss.bossName or "Raid Boss") .. " - " .. (boss.raidName or "Raid"))
            end
        end
    end
    if GearTargets.selectedSourceID then return SourceLabel(GearTargets.selectedSourceID) end
    if GearTargets.selectedItemType == "Dungeon" then return "All Dungeons" end
    if GearTargets.selectedItemType == "Raid" then return "All Raids" end
    return "All Dungeons & Raids"
end

local function GetSlotOptions()
    local list = { { text = "All Slots", value = nil } }
    if KeyLab.GearLootMapping and KeyLab.GearLootMapping.GetSlotList then
        for _, slot in ipairs(KeyLab.GearLootMapping.GetSlotList(nil, CurrentClassID()) or {}) do
            if slot and slot ~= "" then table.insert(list, { text = slot, value = slot }) end
        end
    end
    return list
end

local function GetSourceOptions()
    local list = {
        { text = "All Dungeons & Raids", sourceType = nil },
        { text = "All Dungeons", sourceType = "Dungeon" },
        { text = "All Raids", sourceType = "Raid" },
    }
    if KeyLab.GearLootMapping and KeyLab.GearLootMapping.GetSourceListForClass then
        table.insert(list, { text = "Dungeons", title = true })
        for _, source in ipairs(KeyLab.GearLootMapping.GetSourceListForClass(CurrentClassID(), "Dungeon") or {}) do
            table.insert(list, {
                text = source.sourceName or source.name or tostring(source.sourceID),
                sourceType = "Dungeon",
                sourceID = source.sourceID,
            })
        end
    end
    if KeyLab.GearLootMapping and KeyLab.GearLootMapping.GetRaidBossListForClass then
        table.insert(list, { text = "Raid Bosses", title = true })
        for _, boss in ipairs(KeyLab.GearLootMapping.GetRaidBossListForClass(CurrentClassID()) or {}) do
            table.insert(list, {
                text = boss.text or ((boss.bossName or "Raid Boss") .. " - " .. (boss.raidName or "Raid")),
                sourceType = "Raid",
                sourceID = boss.sourceID,
                encounterID = boss.encounterID,
            })
        end
    end
    return list
end

local function SelectedSecondaryCount()
    local count = 0
    for _, enabled in pairs(GearTargets.selectedSecondaries or {}) do if enabled then count = count + 1 end end
    return count
end

local function RefreshExternalTargetViews()
    if KeyLab.GearTargetsWindow and KeyLab.GearTargetsWindow.RefreshVisible then KeyLab.GearTargetsWindow.RefreshVisible() end
    local dashboard = KeyLab.Tabs and KeyLab.Tabs.GearDashboard
    if dashboard and dashboard.Refresh then dashboard:Refresh() end
end

local function PrintAssignmentError(reason)
    local messages = {
        slot_required = "Choose the exact equipment slot for this item.",
        invalid_slot = "That item cannot be used in the selected slot for your current specialization.",
        target_required = "Select a Target or crafted plan for that slot before adding an Alternative.",
        already_target = "That item is already the Target for this slot.",
        already_targeted = "That item is already saved as a Target in another paired slot.",
        slot_has_target = "That slot already has a Target.",
        off_hand_closed = "Off Hand is closed by the selected Main Hand weapon.",
        main_hand_required = "Select a compatible one-handed Main Hand Target or crafted plan before saving this Off Hand item.",
        incompatible_main_hand = "This Off Hand item requires a one-handed Main Hand Target.",
        owned_catalyst_slot_only = "Owned Catalyst Targets are available for Back, Wrist, Waist, and Feet. Head, Shoulders, Chest, Hands, and Legs remain Tier Set slots.",
    }
    if KeyLab.Print then KeyLab.Print(messages[reason] or "That Gear Target choice could not be saved.") end
end

local function GetStatusMenuFrame()
    if not statusMenuFrame then
        statusMenuFrame = KeyLab.UI.Theme.CreateLegacyDropdown(UIParent, "KeyLabGearTargetsStatusMenu")
        statusMenuFrame:Hide()
    end
    return statusMenuFrame
end

local function ApplyStatus(item, status, slotInstance)
    local targets = KeyLab.LootTargetsDB
    if not targets then return end
    if status == "target" then
        local specID = TargetSpecID()
        KeyLab.UI.RunPlanChange(specID, function(approval)
            return targets.SetTargetForSlot(specID, item, slotInstance, item.sourceID, true, approval)
        end, function(ok, reason)
            if not ok then PrintAssignmentError(reason); return end
            GearTargets:RefreshContent()
            RefreshExternalTargetViews()
        end)
        return
    end
    local ok, reason
    if status == nil then
        ok, reason = targets.SetStatus(TargetSpecID(), item.itemID, nil)
    elseif status == "target" then
        ok, reason = targets.SetTargetForSlot(TargetSpecID(), item, slotInstance, item.sourceID, true)
    elseif status == "alternative" then
        ok, reason = targets.SetAlternativeForSlot(TargetSpecID(), item, slotInstance, item.sourceID)
    end
    if not ok then PrintAssignmentError(reason); return end
    GearTargets:RefreshContent()
    RefreshExternalTargetViews()
end

local function EligibleStatusSlots(item, status)
    local mapping = KeyLab.GearLootMapping
    local slots = mapping and mapping.GetTargetSlotInstances and mapping.GetTargetSlotInstances(item, TargetSpecID()) or {}
    if item and item.sourceType == "Owned" then
        local ownedSlot = mapping and mapping.NormalizeSlotName and mapping.NormalizeSlotName(item.slot) or tostring(item.slot or "")
        if not CATALYST_NON_SET_ARMOR_SLOTS[ownedSlot] then return {}, "owned_catalyst_slot_only" end
        slots = { ownedSlot }
    end
    if status ~= "alternative" then return slots, nil end
    local out = {}
    for _, slotInstance in ipairs(slots) do
        local crafts = KeyLab.CraftedPlansDB
        if KeyLab.LootTargetsDB.GetTargetForSlot(TargetSpecID(), slotInstance)
            or (crafts and #crafts.GetPlansForSlot(TargetSpecID(), slotInstance) > 0) then table.insert(out, slotInstance) end
    end
    return out, nil
end

local function OpenSlotChoice(anchor, item, status)
    local slots, restriction = EligibleStatusSlots(item, status)
    if #slots == 0 then
        PrintAssignmentError(restriction or (status == "alternative" and "target_required" or "invalid_slot"))
        return
    end
    if #slots == 1 then ApplyStatus(item, status, slots[1]); return end

    local menuFrame = GetStatusMenuFrame()
    UIDropDownMenu_Initialize(menuFrame, function(_, level)
        if level and level > 1 then return end
        local heading = UIDropDownMenu_CreateInfo()
        heading.text = status == "target" and "Choose Target Slot" or "Alternative For"
        heading.isTitle = true
        heading.notCheckable = true
        UIDropDownMenu_AddButton(heading, level)
        for _, slotInstance in ipairs(slots) do
            local slotName = slotInstance
            local current = KeyLab.LootTargetsDB.GetTargetForSlot(TargetSpecID(), slotName)
            local text = slotName
            if status == "target" and current and tonumber(current.itemID) ~= tonumber(item.itemID) then
                local currentItem = KeyLab.GearLootMapping.GetItem(current.itemID, TargetSpecID())
                text = text .. " (replace " .. CleanText(currentItem and currentItem.name or ("Item " .. tostring(current.itemID))) .. ")"
            end
            local info = UIDropDownMenu_CreateInfo()
            info.text = text
            info.notCheckable = true
            info.func = function()
                ApplyStatus(item, status, slotName)
                if CloseDropDownMenus then CloseDropDownMenus() end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end, "MENU")
    ToggleDropDownMenu(1, nil, menuFrame, anchor, 0, 0)
end

local function BeginStatusChoice(anchor, item, status)
    if status == nil then ApplyStatus(item, nil); return end
    local run = function() OpenSlotChoice(anchor, item, status) end
    if CloseDropDownMenus then CloseDropDownMenus() end
    if C_Timer and C_Timer.After then C_Timer.After(0, run) else run() end
end

local function OpenStatusMenu(anchor, item)
    if not anchor or not item or not ToggleDropDownMenu then return end
    GameTooltip:Hide()
    local currentStatus = GetItemStatus(item.itemID)
    local options = {
        { value = nil, label = "Unmarked" },
        { value = "target", label = "Target" },
        { value = "alternative", label = "Alternative" },
    }
    local menuFrame = GetStatusMenuFrame()
    UIDropDownMenu_Initialize(menuFrame, function(_, level)
        if level and level > 1 then return end
        for _, option in ipairs(options) do
            local value = option.value
            local info = UIDropDownMenu_CreateInfo()
            info.text = (currentStatus == value and "* " or "  ") .. option.label
            info.notCheckable = true
            info.func = function() BeginStatusChoice(anchor, item, value) end
            UIDropDownMenu_AddButton(info, level)
        end
    end, "MENU")
    ToggleDropDownMenu(1, nil, menuFrame, anchor, 0, 0)
end

local function CleanSortText(text)
    return CleanText(text):lower()
end

local function CompareSortValues(aValue, bValue, ascending)
    if aValue == bValue then return nil end
    if ascending then return aValue < bValue end
    return aValue > bValue
end

function GearTargets:GetSortValue(item, key)
    if key == "item" then return CleanSortText(ItemDisplayName(item)) end
    if key == "slot" then return CleanSortText(item and item.slot) end
    if key == "source" then return CleanSortText(ItemDisplaySource(item)) end
    if key == "stats" then return CleanSortText(ItemDisplayStats(item)) end
    if key == "match" then
        if KeyLab.StatGoalMatcher and KeyLab.StatGoalMatcher.IsGoalMatch(item.itemID, TargetSpecID()) then return 1 end
        if KeyLab.StatGoalMatcher and KeyLab.StatGoalMatcher.IsStatSupport(item.itemID, TargetSpecID()) then return 2 end
        return 3
    end
    if key == "status" then
        local status = GetItemStatus(item.itemID)
        return STATUS_SORT_RANK[status or "unmarked"] or 9, CleanSortText(StatusLabel(status))
    end
    return CleanSortText(ItemDisplaySource(item))
end

function GearTargets:SortItems(items)
    local key = self.sortKey or "source"
    local ascending = self.sortAscending ~= false
    table.sort(items, function(a, b)
        local aValue, aText = self:GetSortValue(a, key)
        local bValue, bText = self:GetSortValue(b, key)
        local first = CompareSortValues(aValue, bValue, ascending)
        if first ~= nil then return first end
        if aText or bText then
            local second = CompareSortValues(CleanSortText(aText), CleanSortText(bText), ascending)
            if second ~= nil then return second end
        end
        return tonumber(a.itemID or 0) < tonumber(b.itemID or 0)
    end)
end

function GearTargets:GetFilteredItems()
    local primaryStats = {}
    if self.selectedPrimary then primaryStats[self.selectedPrimary] = true end
    if self.selectedStamina then primaryStats.Stam = true end
    local filters = {
        specID = TargetSpecID(),
        browseClass = true,
        classID = CurrentClassID(),
        sourceID = self.selectedSourceID,
        sourceType = self.selectedItemType,
        encounterID = self.selectedEncounterID,
        slot = self.selectedSlot,
        primaryStats = primaryStats,
        secondaryStats = self.selectedSecondaries,
        searchText = self.searchText,
        includeNonGear = false,
    }
    local items = KeyLab.GearLootMapping and KeyLab.GearLootMapping.GetFilteredItems and KeyLab.GearLootMapping.GetFilteredItems(filters) or {}
    local result = KeyLab.StatGoalMatcher and KeyLab.StatGoalMatcher.GetResult and KeyLab.StatGoalMatcher.GetResult(TargetSpecID())
    if result and result.itemSource == "owned" and not self.selectedItemType and not self.selectedSourceID then
        local seen = {}
        for _, item in ipairs(items) do seen[tonumber(item.itemID)] = true end
        local matcherRecords = {}
        for _, item in ipairs(result.matchedItemRecords or {}) do table.insert(matcherRecords, item) end
        for _, item in ipairs(result.statSupportItemRecords or {}) do table.insert(matcherRecords, item) end
        for _, item in ipairs(matcherRecords) do
            local itemID = tonumber(item and item.itemID)
            local slotMatches = not self.selectedSlot or tostring(item and item.slot or "") == tostring(self.selectedSlot)
            local searchMatches = self.searchText == "" or CleanSortText((item and item.name or "") .. " " .. (item and item.link or "")):find(CleanSortText(self.searchText), 1, true)
            local statsMatch = not self.selectedPrimary and not self.selectedStamina
            if statsMatch then
                for statKey in pairs(self.selectedSecondaries or {}) do
                    if (tonumber(item and item.stats and item.stats[statKey]) or 0) <= 0 then statsMatch = false; break end
                end
            end
            if itemID and not seen[itemID] and slotMatches and searchMatches and statsMatch then
                seen[itemID] = true
                table.insert(items, item)
            end
        end
    end
    if self.selectedStatusFilter ~= "all" then
        local filtered = {}
        for _, item in ipairs(items) do
            local status = GetItemStatus(item.itemID)
            local include = self.selectedStatusFilter == "goal_match"
                    and KeyLab.StatGoalMatcher
                    and KeyLab.StatGoalMatcher.IsGoalMatch(item.itemID, TargetSpecID())
                or self.selectedStatusFilter == status
                or self.selectedStatusFilter == "saved" and (status == "target" or status == "alternative")
            if include then table.insert(filtered, item) end
        end
        items = filtered
    end
    self:SortItems(items)
    return items
end

function GearTargets:MakeHeaderButton(parent, key)
    local column = TABLE_COLUMNS[key]
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetPoint("LEFT", parent, "LEFT", column.x - 4, 0)
    button:SetSize(column.width, 22)
    SetBackdrop(button, CFG.colors.box, CFG.colors.border)
    local label = column.label .. " [Sort]"
    if self.sortKey == key then label = label .. (self.sortAscending == false and " v" or " ^") end
    button.label = MakeText(button, label, "GameFontDisableSmall", nil, CFG.colors.gold)
    button.label:SetPoint("LEFT", button, "LEFT", 4, -1)
    button.label:SetSize(column.width - 8, 18)
    button.label:SetJustifyV("MIDDLE")
    button:SetScript("OnClick", function()
        if GearTargets.sortKey == key then GearTargets.sortAscending = not GearTargets.sortAscending
        else GearTargets.sortKey = key; GearTargets.sortAscending = true end
        GearTargets:RefreshContent()
    end)
    if key == "match" then
        button:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(unpack(CFG.colors.blue))
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Sort by Matcher Result")
            GameTooltip:AddLine("Click to group Goal Match and Stat Support items at the top or bottom of the list.", 0.8, 0.85, 1.0, true)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(unpack(CFG.colors.border))
            GameTooltip:Hide()
        end)
    end
    return button
end

local function ItemLinkForSpec(item, specID)
    local link = item and item.link
    if not link or link == "" then
        return item and item.itemID and ("item:" .. tostring(item.itemID)) or nil
    end

    local payload = link:match("|Hitem:([^|]+)|h")
    specID = tonumber(specID)
    if not payload or not specID then return link end

    local fields = {}
    for field in (payload .. ":"):gmatch("(.-):") do table.insert(fields, field) end
    if #fields < 10 then return link end

    -- Preserve the captured item level, upgrade, difficulty, and bonus data.
    -- Only the hyperlink's specialization context changes for the current character.
    fields[10] = tostring(specID)
    local resolvedPayload = table.concat(fields, ":")
    return (link:gsub("|Hitem:[^|]+|h", function()
        return "|Hitem:" .. resolvedPayload .. "|h"
    end, 1))
end

local function AddLootSpecLines(guidance)
    if not GameTooltip or not guidance then return end
    local spec = KeyLab.GearLootDatabase and KeyLab.GearLootDatabase.specs and KeyLab.GearLootDatabase.specs[guidance.lootSpecID]
    local specName = spec and (spec.specName or spec.name) or "Unavailable"
    local colors = Theme.colors or CFG.colors
    GameTooltip:AddLine("Loot Spec: " .. (guidance.names or "Unavailable"), colors.gold[1], colors.gold[2], colors.gold[3], true)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Loot Spec Set: " .. specName, colors.blue[1], colors.blue[2], colors.blue[3], true)
end

local function AddItemTooltip(frame, item, itemLink)
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if itemLink then GameTooltip:SetHyperlink(itemLink)
        elseif item.itemID then GameTooltip:SetHyperlink("item:" .. tostring(item.itemID)) end
        local guidance = KeyLab.GearLootMapping.GetLootSpecGuidance(item, TargetSpecID())
        AddLootSpecLines(guidance)
        if item.statsNotCapturedForSpec then
            GameTooltip:AddLine("Stats were not captured for your current spec. This is not a claim that the item has no stats; review Blizzard's tooltip above.", 0.8, 0.85, 1, true)
        end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function GearTargets:MakeLootRow(parent, item, y)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    SetPixelPoint(row, "TOPLEFT", parent, "TOPLEFT", 0, y)
    SetPixelPoint(row, "TOPRIGHT", parent, "TOPRIGHT", 0, y)
    SetPixelHeight(row, CFG.rowHeight - 4)
    SetBackdrop(row, CFG.colors.box, CFG.colors.border, 1)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("LEFT", row, "LEFT", 7, 0)
    icon:SetSize(25, 25)
    if item.icon then icon:SetTexture(item.icon) end

    local itemLink = ItemLinkForSpec(item, TargetSpecID())
    local name = MakeText(row, itemLink or ItemDisplayName(item), "GameFontNormal", nil, CFG.colors.text)
    name:SetPoint("TOPLEFT", row, "TOPLEFT", TABLE_COLUMNS.item.x, -4)
    name:SetSize(TABLE_COLUMNS.item.width, 18)
    name:SetWordWrap(false)
    local guidance = KeyLab.GearLootMapping.GetLootSpecGuidance(item, TargetSpecID())
    local lootSpec = MakeText(row, "Loot Spec: " .. (guidance and guidance.names or "Not recorded"), "GameFontDisableSmall", 9, (Theme.colors or CFG.colors).gold)
    lootSpec:SetPoint("TOPLEFT", row, "TOPLEFT", TABLE_COLUMNS.item.x, -24)
    lootSpec:SetSize(TABLE_COLUMNS.item.width, 22)
    lootSpec:SetJustifyV("TOP")
    lootSpec:SetWordWrap(true)
    local itemHover = CreateFrame("Frame", nil, row)
    itemHover:SetPoint("LEFT", row, "LEFT", 5, 0)
    itemHover:SetSize(TABLE_COLUMNS.item.x + TABLE_COLUMNS.item.width - 5, CFG.rowHeight - 4)
    itemHover:SetFrameLevel(row:GetFrameLevel() + 3)
    AddItemTooltip(itemHover, item, itemLink)

    local slot = MakeText(row, item.slot or "-", "GameFontHighlightSmall", nil, CFG.colors.blue)
    slot:SetPoint("LEFT", row, "LEFT", TABLE_COLUMNS.slot.x, 0)
    slot:SetSize(TABLE_COLUMNS.slot.width, 18)

    local sourceColor = item.sourceType == "Raid" and CFG.colors.raid or CFG.colors.muted
    local source = MakeText(row, ItemDisplaySource(item), "GameFontHighlightSmall", nil, sourceColor)
    source:SetPoint("LEFT", row, "LEFT", TABLE_COLUMNS.source.x, 0)
    source:SetSize(TABLE_COLUMNS.source.width, 18)
    local sourceHover = CreateFrame("Frame", nil, row)
    sourceHover:SetPoint("LEFT", row, "LEFT", TABLE_COLUMNS.source.x, 0)
    sourceHover:SetSize(TABLE_COLUMNS.source.width, CFG.rowHeight - 4)
    sourceHover:EnableMouse(true)
    sourceHover:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(ItemDisplaySource(item))
        if item.sourceType == "Raid" then GameTooltip:AddLine("Raid source - weekly opportunity", 0.9, 0.68, 0.9, true)
        elseif item.sourceType == "Dungeon" then GameTooltip:AddLine("Dungeon source - repeatable", 0.5, 0.68, 0.94, true) end
        local guidance = KeyLab.GearLootMapping.GetLootSpecGuidance(item, TargetSpecID())
        AddLootSpecLines(guidance)
        GameTooltip:Show()
    end)
    sourceHover:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local stats = MakeText(row, ItemDisplayStats(item), "GameFontDisableSmall", nil, CFG.colors.muted)
    stats:SetPoint("LEFT", row, "LEFT", TABLE_COLUMNS.stats.x, 0)
    stats:SetSize(TABLE_COLUMNS.stats.width, 18)

    local matched = KeyLab.StatGoalMatcher and KeyLab.StatGoalMatcher.IsGoalMatch(item.itemID, TargetSpecID())
    local statSupport = KeyLab.StatGoalMatcher and KeyLab.StatGoalMatcher.IsStatSupport(item.itemID, TargetSpecID())
    local matchLabel = matched and "Goal Match" or statSupport and "Stat Support" or ""
    local matchColor = matched and CFG.colors.gold or statSupport and CFG.colors.blue or CFG.colors.muted
    local matchText = MakeText(row, matchLabel, "GameFontHighlightSmall", nil, matchColor)
    matchText:SetPoint("LEFT", row, "LEFT", TABLE_COLUMNS.match.x, 0)
    matchText:SetSize(TABLE_COLUMNS.match.width, 18)
    local matchHover = CreateFrame("Frame", nil, row)
    matchHover:SetPoint("LEFT", row, "LEFT", TABLE_COLUMNS.match.x, 0)
    matchHover:SetSize(TABLE_COLUMNS.match.width, CFG.rowHeight - 4)
    matchHover:EnableMouse(true)
    matchHover:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(matched and "Goal Match" or statSupport and "Stat Support" or "No current matcher result")
        if statSupport then
            GameTooltip:AddLine("This trinket provides a secondary stat that supports your selected goals. KeyLab does not evaluate its role, Use or Equip effect, tuning, or overall performance.", 0.8, 0.85, 1.0, true)
        else
            GameTooltip:AddLine("Goal Match shows the closest secondary-stat combination KeyLab found. It does not mean Best in Slot.", 0.8, 0.85, 1.0, true)
        end
        GameTooltip:Show()
    end)
    matchHover:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local status = GetItemStatus(item.itemID)
    local statusColor = STATUS_COLORS[status or "unmarked"]
    local statusButton = MakeSmallButton(row, StatusLabel(status) .. " v", TABLE_COLUMNS.status.width, 20)
    statusButton:SetPoint("LEFT", row, "LEFT", TABLE_COLUMNS.status.x, 0)
    statusButton:SetBackdropBorderColor(unpack(statusColor))
    statusButton.label:SetTextColor(unpack(statusColor))
    statusButton:SetScript("OnClick", function(btn) OpenStatusMenu(btn, item) end)
    statusButton:SetScript("OnEnter", function(btn)
        btn:SetBackdropBorderColor(unpack(CFG.colors.blue))
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Status: " .. StatusLabel(status))
        GameTooltip:AddLine("You choose Targets and Alternatives. Goal Match and Stat Support never change them for you.", 0.8, 0.85, 1.0, true)
        local assignments = KeyLab.LootTargetsDB.GetAssignmentsForItem(TargetSpecID(), item.itemID)
        for _, assignment in ipairs(assignments or {}) do
            if assignment.slotInstance then GameTooltip:AddLine((assignment.status == "target" and "Target: " or "Alternative: ") .. assignment.slotInstance, 0.9, 0.9, 0.7) end
        end
        GameTooltip:Show()
    end)
    statusButton:SetScript("OnLeave", function(btn)
        btn:SetBackdropBorderColor(unpack(statusColor))
        GameTooltip:Hide()
    end)
    return row
end

function GearTargets:UpdateSummary(items)
    local targetCount = #(KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.GetAllTargetsForSpec and KeyLab.LootTargetsDB.GetAllTargetsForSpec(TargetSpecID()) or {})
    local alternativeCount = #(KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.GetAllAlternativesForSpec and KeyLab.LootTargetsDB.GetAllAlternativesForSpec(TargetSpecID()) or {})
    local info = KeyLab.GearLootMapping and KeyLab.GearLootMapping.GetSeasonInfo and KeyLab.GearLootMapping.GetSeasonInfo() or {}
    self.summary:SetText(string.format("%d item(s) shown  |  %d Target(s)  |  %d Alternative(s)  |  %s %s",
        #items, targetCount, alternativeCount, tostring(info.expansion or ""), tostring(info.seasonName or "")))
end

function GearTargets:RefreshContent()
    if not self.content then return end
    for _, child in ipairs({ self.content:GetChildren() }) do child:Hide(); child:SetParent(nil) end
    local items = self:GetFilteredItems()
    self:UpdateSummary(items)
    local header = CreateFrame("Frame", nil, self.content, "BackdropTemplate")
    SetPixelPoint(header, "TOPLEFT", self.content, "TOPLEFT", 0, 0)
    SetPixelPoint(header, "TOPRIGHT", self.content, "TOPRIGHT", 0, 0)
    SetPixelHeight(header, 26)
    SetBackdrop(header, CFG.colors.box, CFG.colors.border, 1)
    for _, key in ipairs({ "item", "slot", "source", "stats", "match", "status" }) do self:MakeHeaderButton(header, key) end
    if #items == 0 then
        local text = MakeText(self.content, "No loot matched these filters.", "GameFontNormal", nil, CFG.colors.warning)
        text:SetPoint("TOPLEFT", self.content, "TOPLEFT", 10, -44)
        text:SetSize(820, 100)
        self.content:SetHeight(180)
        return
    end
    local y = -32
    for _, item in ipairs(items) do self:MakeLootRow(self.content, item, y); y = y - CFG.rowHeight end
    self.content:SetHeight(math.max(520, math.abs(y) + 20))
end

function GearTargets:SetGoalTargetFromBox(statKey, box)
    if self.committingGoalBoxes then return end
    local text = tostring(box:GetText() or ""):gsub("%%", ""):gsub(",", "."):gsub("^%s+", ""):gsub("%s+$", "")
    local value = tonumber(text)
    if value == nil or value < 0 then value = 0 end
    KeyLab.StatGoalsDB.SetTarget(TargetSpecID(), statKey, value)
    box:ClearFocus()
    self:RefreshMatcherCard()
    self:RefreshContent()
end

function GearTargets:CommitVisibleGoals()
    local targets = {}
    for _, definition in ipairs(GOAL_FIELDS) do
        local box = self.goalBoxes and self.goalBoxes[definition.key]
        local text = tostring(box and box:GetText() or "")
            :gsub("%%", "")
            :gsub(",", ".")
            :gsub("^%s+", "")
            :gsub("%s+$", "")
        local value = tonumber(text)
        if value == nil or value < 0 or value > 100 then
            return false, "Each stat goal must be from 0% to 100%."
        end
        targets[definition.key] = value
    end

    local saved, message = KeyLab.StatGoalsDB.SetTargets(TargetSpecID(), targets)
    if not saved then return false, message end

    -- Release keyboard focus only after all four values are safely applied.
    -- The guard prevents OnEditFocusLost from committing an individual box a
    -- second time while this batch update is in progress.
    self.committingGoalBoxes = true
    for _, definition in ipairs(GOAL_FIELDS) do
        local box = self.goalBoxes and self.goalBoxes[definition.key]
        if box and box:HasFocus() then box:ClearFocus() end
    end
    self.committingGoalBoxes = false
    self:RefreshMatcherCard()
    self:RefreshContent()
    return true, nil
end

function GearTargets:SetMatcherStatusStyle(kind)
    local card = self.matcherStatusCard
    if not card then return end

    if kind == "running" then
        SetBackdrop(card, {0.035, 0.075, 0.135, 0.98}, CFG.colors.blue)
    elseif kind == "success" then
        SetBackdrop(card, {0.030, 0.105, 0.070, 0.98}, CFG.colors.green)
    elseif kind == "warning" then
        SetBackdrop(card, {0.105, 0.080, 0.030, 0.98}, CFG.colors.warning)
    else
        SetBackdrop(card, CFG.colors.box, CFG.colors.border)
    end
end

function GearTargets:StopMatcherAnimation()
    if self.matcherAnimationTicker and self.matcherAnimationTicker.Cancel then
        self.matcherAnimationTicker:Cancel()
    end
    self.matcherAnimationTicker = nil
end

function GearTargets:StartMatcherAnimation()
    self:StopMatcherAnimation()
    self.matcherProgressDots = 1
    if not C_Timer or not C_Timer.NewTicker then return end
    self.matcherAnimationTicker = C_Timer.NewTicker(0.35, function()
        local matcher = KeyLab.StatGoalMatcher
        if not matcher or not matcher.IsRunning or not matcher.IsRunning() then
            GearTargets:StopMatcherAnimation()
            return
        end
        GearTargets.matcherProgressDots = (tonumber(GearTargets.matcherProgressDots) or 1) % 3 + 1
        GearTargets:RefreshMatcherCard()
    end)
end

function GearTargets:GetMatcherRunningText()
    if self.matcherCancelling then return "Cancelling" .. string.rep(".", tonumber(self.matcherProgressDots) or 1) end
    local progress = self.matcherProgressDetail
    local dots = string.rep(".", tonumber(self.matcherProgressDots) or 1)
    if progress and tonumber(progress.total) and tonumber(progress.total) > 0 then
        return string.format("Matching items%s %s %d / %d. Results appear when complete.",
            dots,
            tostring(progress.mode or ""),
            tonumber(progress.completed) or 0,
            tonumber(progress.total) or 0)
    end
    return "Stat Goal Matcher running" .. dots .. " Results will appear when complete."
end

function GearTargets:RefreshMatcherCard()
    if not self.matcherPanel then return end
    local goals = KeyLab.StatGoalsDB.GetGoals(TargetSpecID())
    for key, box in pairs(self.goalBoxes or {}) do
        if not box:HasFocus() then box:SetText(tostring(tonumber(goals.targets and goals.targets[key]) or 0)) end
    end
    local valid, validationMessage = KeyLab.StatGoalsDB.Validate(TargetSpecID())
    self.goalTotal:SetText("Character % goals  |  *Trinkets excluded")
    self.goalTotal:SetTextColor(unpack(valid and CFG.colors.green or CFG.colors.warning))

    local matcher = KeyLab.StatGoalMatcher
    local function ShowResultsButton(show)
        if self.matcherResultsButton then self.matcherResultsButton:SetShown(show == true) end
        if self.matcherState then self.matcherState:SetWidth(show and 282 or 372) end
    end
    ShowResultsButton(false)
    self.visibleMatcherResult = nil
    local characterPercentages = {}
    if matcher and matcher.GetCurrentCharacterPercentages then
        local percentages = self.matcherCurrentPercentages
        if type(percentages) ~= "table" then
            percentages = matcher.GetCurrentCharacterPercentages()
            self.matcherCurrentPercentages = percentages
        end
        characterPercentages = type(percentages) == "table" and percentages or {}
    end
    local displayOrder = KeyLab.StatGoalsDB.GetDisplayOrder and KeyLab.StatGoalsDB.GetDisplayOrder(TargetSpecID()) or { "crit", "mastery", "haste", "versatility" }
    for index, statKey in ipairs(displayOrder) do
        local row = self.goalRows and self.goalRows[statKey]
        if row then
            row.frame:ClearAllPoints()
            row.frame:SetPoint("TOPLEFT", self.matcherPanel, "TOPLEFT", 420, -8 - ((index - 1) * 31))
            row.rank:SetText("#" .. tostring(index))
            local current = tonumber(characterPercentages[statKey])
            local goal = tonumber(goals.targets and goals.targets[statKey]) or 0
            row.current:SetText(current and string.format("Now* %.1f%%", current) or "Now* —")
            if current == nil then
                row.status:SetText("No Data")
                row.status:SetTextColor(unpack(CFG.colors.muted))
            elseif math.abs(current - goal) <= 0.05 then
                row.status:SetText("At Goal")
                row.status:SetTextColor(unpack(CFG.colors.blue))
            elseif current < goal then
                row.status:SetText("Below")
                row.status:SetTextColor(unpack(CFG.colors.green))
            else
                row.status:SetText("Above")
                row.status:SetTextColor(unpack(CFG.colors.warning))
            end
            row.up:SetEnabled(index > 1)
            row.down:SetEnabled(index < #displayOrder)
            row.up.label:SetTextColor(unpack(index > 1 and CFG.colors.text or CFG.colors.muted))
            row.down.label:SetTextColor(unpack(index < #displayOrder and CFG.colors.text or CFG.colors.muted))
        end
    end

    if matcher and matcher.IsRunning() then
        self.matcherButton:SetText("Cancel Matcher")
        self.matcherButton:SetEnabled(true)
        self.matcherState:SetText(self:GetMatcherRunningText())
        self.matcherState:SetTextColor(unpack(CFG.colors.blue))
        self:SetMatcherStatusStyle("running")
        return
    end
    if self.matcherFinishing then
        self.matcherButton:SetText("Updating Results")
        self.matcherButton:SetEnabled(false)
        self.matcherState:SetText(self.matcherProgressText or "Matcher results found. Updating the list...")
        self.matcherState:SetTextColor(unpack(CFG.colors.blue))
        self:SetMatcherStatusStyle("running")
        return
    end
    self.matcherButton:SetText("Stat Goal Matcher")
    self.matcherButton:SetEnabled(true)
    if self.matcherProgressText and self.matcherProgressText ~= "" then
        self.matcherState:SetText(self.matcherProgressText)
        self.matcherState:SetTextColor(unpack(CFG.colors.warning))
        self:SetMatcherStatusStyle("warning")
        return
    end
    local result = matcher and matcher.GetResult(TargetSpecID())
    if result then
        self.visibleMatcherResult = result
        local unmatched = type(result.unmatchedOpenSlots) == "table" and #result.unmatchedOpenSlots or 0
        local matched = tonumber(result.matchedSlotCount) or tonumber(result.openPositionCount) or 0
        local supports = type(result.statSupportItems) == "table" and #result.statSupportItems or 0
        local message = string.format("Matcher ready: %d Goal Match slot(s), %d Stat Support trinket(s). %s.",
            matched, supports, tostring(result.resultStatus or "completed"))
        if unmatched > 0 then
            message = string.format("Matcher ready: %d Goal Match slot(s), %d Stat Support trinket(s). %d unequipped slot(s) had no distinct candidate.",
                matched, supports, unmatched)
        end
        ShowResultsButton(true)
        self.matcherState:SetText(message)
        self.matcherState:SetTextColor(unpack(CFG.colors.green))
        self:SetMatcherStatusStyle("success")
    elseif valid then
        self.matcherState:SetText("Your goals are ready. Unequip only the slots you want KeyLab to fill.")
        self.matcherState:SetTextColor(unpack(CFG.colors.text))
        self:SetMatcherStatusStyle("neutral")
    else
        self.matcherState:SetText(validationMessage or "Enter a value from 0% to 100% for each stat.")
        self.matcherState:SetTextColor(unpack(CFG.colors.warning))
        self:SetMatcherStatusStyle("warning")
    end
end

function GearTargets:RefreshCurrentStats(showConfirmation)
    if KeyLab.GearCapture and KeyLab.GearCapture.MarkAllSlotsChanged then
        KeyLab.GearCapture.MarkAllSlotsChanged()
    end
    self.matcherCurrentPercentages = nil
    self:RefreshMatcherCard()

    if showConfirmation and self.refreshStatsButton and self.refreshStatsButton.label then
        local button = self.refreshStatsButton
        button.label:SetText("Stats Updated")
        self.statsRefreshConfirmation = (tonumber(self.statsRefreshConfirmation) or 0) + 1
        local confirmation = self.statsRefreshConfirmation
        if C_Timer and C_Timer.After then
            C_Timer.After(1.5, function()
                if GearTargets.statsRefreshConfirmation == confirmation and button.label then
                    button.label:SetText("Refresh Current Stats")
                end
            end)
        end
    end
end

function GearTargets:ScheduleCurrentStatsRefresh()
    self.statsRefreshRequest = (tonumber(self.statsRefreshRequest) or 0) + 1
    local request = self.statsRefreshRequest
    local refresh = function()
        if GearTargets.statsRefreshRequest ~= request then return end
        if KeyLab.GearCapture and KeyLab.GearCapture.MarkAllSlotsChanged then
            KeyLab.GearCapture.MarkAllSlotsChanged()
        end
        GearTargets.matcherCurrentPercentages = nil
        if GearTargets.frame and GearTargets.frame:IsShown() then
            GearTargets:RefreshMatcherCard()
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0.5, refresh)
    else
        refresh()
    end
end

local RESULT_STATS = {
    { key = "Crit", label = "Critical Strike" },
    { key = "Haste", label = "Haste" },
    { key = "Mastery", label = "Mastery" },
    { key = "Vers", label = "Versatility" },
}

local function ResultNumber(value)
    return tonumber(value) and string.format("%.1f%%", tonumber(value)) or "--"
end

local function MatcherResultItemDetails(item)
    local details = {}
    if item.upgradeTrack then
        local rank = item.upgradeRank and item.upgradeMaxRank
            and (tostring(item.upgradeRank) .. "/" .. tostring(item.upgradeMaxRank)) or ""
        table.insert(details, item.upgradeTrack .. (rank ~= "" and (" " .. rank) or ""))
    end
    if item.itemLevel and item.itemLevel > 0 then
        local levelText = "Item Level " .. tostring(math.floor(item.itemLevel + 0.5))
        if item.requiresUpgrade and item.projectedItemLevel and item.projectedItemLevel > item.itemLevel then
            levelText = levelText .. " to " .. tostring(math.floor(item.projectedItemLevel + 0.5)) .. " projected"
        end
        table.insert(details, levelText)
    end
    if ItemDisplaySource(item) ~= "-" then table.insert(details, CleanText(ItemDisplaySource(item))) end
    return table.concat(details, "  |  ")
end

local function MatcherResultSupportText(item)
    local labels = { Crit = "Critical Strike", Haste = "Haste", Mastery = "Mastery", Vers = "Versatility" }
    local parts = {}
    for _, key in ipairs(item and item.supportStats or {}) do
        table.insert(parts, labels[key] or key)
    end
    return #parts > 0 and ("Supports " .. table.concat(parts, " / ")) or "Provides a needed secondary stat"
end

local function MatcherResultStatStatus(projected, goal)
    projected, goal = tonumber(projected), tonumber(goal)
    if not projected or not goal then return "No comparison", CFG.colors.muted end
    local difference = projected - goal
    if math.abs(difference) <= 0.5 then return "Near goal", CFG.colors.green end
    if difference > 0 then return string.format("Above by %.1f%%", difference), CFG.colors.warning end
    return string.format("Below by %.1f%%", math.abs(difference)), CFG.colors.warning
end

local function MatcherResultDRStatus(status)
    if status and status.enters then
        return "Projected to enter reduced efficiency", CFG.colors.warning
    elseif status and status.projected and status.current then
        return "Already in reduced efficiency", CFG.colors.warning
    elseif status and status.projected then
        return "Reduced efficiency projected", CFG.colors.warning
    end
    return "No reduced efficiency projected", CFG.colors.green
end

local function ResultCard(popup, height, title, borderColor)
    local card = CreateFrame("Frame", nil, popup.content, "BackdropTemplate")
    card:SetSize(popup.contentWidth, height)
    card:SetPoint("TOPLEFT", popup.content, "TOPLEFT", 0, popup.resultY)
    SetBackdrop(card, CFG.colors.panel, borderColor or CFG.colors.border)
    table.insert(popup.resultCards, card)
    popup.resultY = popup.resultY - height - 10

    local heading = MakeText(card, title, "GameFontNormal", 14, CFG.colors.gold)
    heading:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -11)
    heading:SetSize(popup.contentWidth - 28, 20)
    return card
end

local function ResultRow(parent, y, height, alternate)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, y)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, y)
    row:SetHeight(height)
    local color = alternate and CFG.colors.box or {0.022, 0.038, 0.074, 0.92}
    SetBackdrop(row, color, {CFG.colors.border[1], CFG.colors.border[2], CFG.colors.border[3], 0.32})
    return row
end

local function ClearMatcherResultCards(popup)
    for _, card in ipairs(popup.resultCards or {}) do card:Hide() end
    popup.resultCards = {}
    popup.resultY = 0
end

local function RenderMatcherResults(popup, result)
    ClearMatcherResultCards(popup)

    local summary = ResultCard(popup, 78, tostring(result.resultStatus or "Match Complete"), CFG.colors.gold)
    local style = MakeText(summary, MatcherStyleLabel(result.matchStyle) .. "  |  " .. tostring(result.mode or "") .. " search", "GameFontHighlightSmall", nil, CFG.colors.blue)
    style:SetPoint("TOPLEFT", summary, "TOPLEFT", 14, -35)
    style:SetSize(300, 18)
    local sourceLabel = MakeText(summary, "ITEM SOURCE", "GameFontDisableSmall", nil, CFG.colors.muted, "RIGHT")
    sourceLabel:SetPoint("TOPRIGHT", summary, "TOPRIGHT", -14, -11)
    sourceLabel:SetSize(390, 16)
    local source = MakeText(summary, MatcherPoolLabel(result), "GameFontHighlightSmall", nil, CFG.colors.text, "RIGHT")
    source:SetPoint("TOPRIGHT", summary, "TOPRIGHT", -14, -34)
    source:SetSize(390, 30)

    local trinketNotice = ResultCard(popup, 78, "About Trinkets", CFG.colors.blue)
    local trinketNoticeText = MakeText(trinketNotice,
        "KeyLab does not recommend which trinkets you should use. A trinket may appear as Stat Support when it has a helpful passive secondary stat, but trinket stats are not counted toward completing your goal percentages.",
        "GameFontHighlightSmall", nil, CFG.colors.text)
    trinketNoticeText:SetPoint("TOPLEFT", trinketNotice, "TOPLEFT", 14, -34)
    trinketNoticeText:SetSize(popup.contentWidth - 28, 36)
    trinketNoticeText:SetWordWrap(true)

    local statsCard = ResultCard(popup, 178, "Projected Stat Results", CFG.colors.blue)
    local headers = {
        { "STAT", 16, 168 }, { "CURRENT*", 184, 104 }, { "GOAL", 288, 92 },
        { "PROJECTED", 380, 116 }, { "RESULT", 496, popup.contentWidth - 512 },
    }
    for _, header in ipairs(headers) do
        local label = MakeText(statsCard, header[1], "GameFontDisableSmall", nil, CFG.colors.muted)
        label:SetPoint("TOPLEFT", statsCard, "TOPLEFT", header[2], -38)
        label:SetSize(header[3], 16)
    end
    for index, definition in ipairs(RESULT_STATS) do
        local key = definition.key
        local current = result.currentPercentages and result.currentPercentages[key]
        local goal = result.goals and result.goals[key]
        local projected = result.finalPercentages and result.finalPercentages[key]
        local statusText, statusColor = MatcherResultStatStatus(projected, goal)
        local row = ResultRow(statsCard, -56 - ((index - 1) * 27), 25, index % 2 == 0)
        local values = {
            { definition.label, 8, 160, CFG.colors.text },
            { ResultNumber(current), 176, 96, CFG.colors.blue },
            { ResultNumber(goal), 280, 84, CFG.colors.gold },
            { ResultNumber(projected), 372, 108, statusColor },
            { statusText, 488, popup.contentWidth - 516, statusColor },
        }
        for _, value in ipairs(values) do
            local label = MakeText(row, value[1], "GameFontHighlightSmall", nil, value[4])
            label:SetPoint("LEFT", row, "LEFT", value[2], 0)
            label:SetSize(value[3], 20)
            label:SetJustifyV("MIDDLE")
        end
    end

    local selected = type(result.selectedItems) == "table" and result.selectedItems or {}
    local itemCount = math.max(1, #selected)
    local itemsCard = ResultCard(popup, 44 + (itemCount * 44), "Chosen Items", CFG.colors.border)
    if #selected == 0 then
        local empty = MakeText(itemsCard, "No item assignments were recorded.", "GameFontHighlightSmall", nil, CFG.colors.muted)
        empty:SetPoint("TOPLEFT", itemsCard, "TOPLEFT", 14, -36)
        empty:SetSize(popup.contentWidth - 28, 24)
    else
        for index, item in ipairs(selected) do
            local row = ResultRow(itemsCard, -34 - ((index - 1) * 44), 40, index % 2 == 0)
            local slot = MakeText(row, tostring(item.slotInstance or "Slot"), "GameFontNormal", nil, CFG.colors.gold)
            slot:SetPoint("TOPLEFT", row, "TOPLEFT", 9, -6)
            slot:SetSize(108, 27)
            local name = MakeText(row, CleanText(item.name or ("Item " .. tostring(item.itemID or "?"))), "GameFontHighlightSmall", nil, CFG.colors.text)
            name:SetPoint("TOPLEFT", row, "TOPLEFT", 120, -4)
            name:SetSize(popup.contentWidth - 150, 18)
            local details = MakeText(row, MatcherResultItemDetails(item), "GameFontDisableSmall", nil, CFG.colors.muted)
            details:SetPoint("TOPLEFT", row, "TOPLEFT", 120, -21)
            details:SetSize(popup.contentWidth - 150, 16)
        end
    end

    local supports = type(result.statSupportItems) == "table" and result.statSupportItems or {}
    if (tonumber(result.openTrinketSlotCount) or 0) > 0 then
        local supportCount = math.max(1, #supports)
        local supportCard = ResultCard(popup, 88 + (supportCount * 44), "Trinket Stat Support", CFG.colors.blue)
        local supportExplanation = MakeText(supportCard,
            "This trinket provides a secondary stat that supports your selected goals. KeyLab does not evaluate its role, Use or Equip effect, tuning, or overall performance.",
            "GameFontDisableSmall", nil, CFG.colors.muted)
        supportExplanation:SetPoint("TOPLEFT", supportCard, "TOPLEFT", 14, -32)
        supportExplanation:SetSize(popup.contentWidth - 28, 36)
        supportExplanation:SetWordWrap(true)
        if #supports == 0 then
            local empty = MakeText(supportCard,
                "No eligible trinket with a needed passive stat passed the reduced-efficiency check.",
                "GameFontHighlightSmall", nil, CFG.colors.muted)
            empty:SetPoint("TOPLEFT", supportCard, "TOPLEFT", 14, -72)
            empty:SetSize(popup.contentWidth - 28, 24)
        else
            for index, item in ipairs(supports) do
                local row = ResultRow(supportCard, -72 - ((index - 1) * 44), 40, index % 2 == 0)
                local label = MakeText(row, "Stat Support", "GameFontNormal", nil, CFG.colors.blue)
                label:SetPoint("TOPLEFT", row, "TOPLEFT", 9, -6)
                label:SetSize(108, 27)
                local name = MakeText(row, CleanText(item.name or ("Item " .. tostring(item.itemID or "?"))), "GameFontHighlightSmall", nil, CFG.colors.text)
                name:SetPoint("TOPLEFT", row, "TOPLEFT", 120, -4)
                name:SetSize(popup.contentWidth - 150, 18)
                local detailText = MatcherResultSupportText(item)
                local itemDetails = MatcherResultItemDetails(item)
                if itemDetails ~= "" then detailText = detailText .. "  |  " .. itemDetails end
                local details = MakeText(row, detailText, "GameFontDisableSmall", nil, CFG.colors.muted)
                details:SetPoint("TOPLEFT", row, "TOPLEFT", 120, -21)
                details:SetSize(popup.contentWidth - 150, 16)
            end
        end
    end

    local drCard = ResultCard(popup, 166, "Diminishing Returns / Reduced Efficiency", CFG.colors.blue)
    local explanation = MakeText(drCard, "Based on the projected finished set and WoW's stat-rating rules.", "GameFontDisableSmall", nil, CFG.colors.muted)
    explanation:SetPoint("TOPLEFT", drCard, "TOPLEFT", 14, -32)
    explanation:SetSize(popup.contentWidth - 28, 18)
    for index, definition in ipairs(RESULT_STATS) do
        local status = result.diminishingReturns and result.diminishingReturns[definition.key]
        local statusText, statusColor = MatcherResultDRStatus(status)
        local row = ResultRow(drCard, -52 - ((index - 1) * 27), 25, index % 2 == 0)
        local stat = MakeText(row, definition.label, "GameFontHighlightSmall", nil, CFG.colors.text)
        stat:SetPoint("LEFT", row, "LEFT", 8, 0)
        stat:SetSize(170, 20)
        stat:SetJustifyV("MIDDLE")
        local indicator = MakeText(row, status and status.projected and "CHECK" or "OK", "GameFontNormal", nil, statusColor, "CENTER")
        indicator:SetPoint("LEFT", row, "LEFT", 184, 0)
        indicator:SetSize(58, 20)
        indicator:SetJustifyV("MIDDLE")
        local statusLabel = MakeText(row, statusText, "GameFontHighlightSmall", nil, statusColor)
        statusLabel:SetPoint("LEFT", row, "LEFT", 254, 0)
        statusLabel:SetSize(popup.contentWidth - 282, 20)
        statusLabel:SetJustifyV("MIDDLE")
    end

    local messages = type(result.resultMessages) == "table" and result.resultMessages or {}
    if #messages > 0 then
        local noteHeights, notesHeight = {}, 42
        for index, message in ipairs(messages) do
            local lines = math.max(1, math.ceil(#tostring(message or "") / 92))
            noteHeights[index] = 12 + (lines * 15)
            notesHeight = notesHeight + noteHeights[index] + 4
        end
        local notesCard = ResultCard(popup, notesHeight, "What You Should Know", CFG.colors.warning)
        local noteY = -34
        for index, message in ipairs(messages) do
            local rowHeight = noteHeights[index]
            local row = ResultRow(notesCard, noteY, rowHeight, index % 2 == 0)
            local marker = MakeText(row, tostring(index), "GameFontNormal", nil, CFG.colors.warning, "CENTER")
            marker:SetPoint("TOPLEFT", row, "TOPLEFT", 6, -6)
            marker:SetSize(24, 18)
            local note = MakeText(row, tostring(message), "GameFontHighlightSmall", nil, CFG.colors.text)
            note:SetPoint("TOPLEFT", row, "TOPLEFT", 35, -6)
            note:SetSize(popup.contentWidth - 63, rowHeight - 8)
            note:SetWordWrap(true)
            noteY = noteY - rowHeight - 4
        end
    end

    local footer = ResultCard(popup, 64, "How This Was Projected", CFG.colors.border)
    local footerText = MakeText(footer,
        "Current* and projected values exclude all trinket secondary stats. Projected values include your other locked gear, the matched set, and the highest known upgrade for owned items.",
        "GameFontDisableSmall", nil, CFG.colors.muted)
    footerText:SetPoint("TOPLEFT", footer, "TOPLEFT", 14, -32)
    footerText:SetSize(popup.contentWidth - 28, 28)
    footerText:SetWordWrap(true)

    local height = math.max(popup.minimumContentHeight, math.abs(popup.resultY) - 10)
    popup.content:SetHeight(height)
    popup.scroll:SetVerticalScroll(0)
end

function GearTargets:CreateMatcherResultsPopup()
    if self.matcherResultsPopup then return self.matcherResultsPopup end
    local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    popup:SetSize(840, 680)
    popup:SetPoint("CENTER")
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:SetFrameLevel(1100)
    if popup.SetToplevel then popup:SetToplevel(true) end
    popup:SetClampedToScreen(true)
    popup:EnableMouse(true)
    popup:SetMovable(true)
    SetBackdrop(popup, CFG.colors.bg, CFG.colors.gold)
    popup:Hide()

    local dragHandle = CreateFrame("Frame", nil, popup)
    dragHandle:SetPoint("TOPLEFT", popup, "TOPLEFT", 2, -2)
    dragHandle:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -2, -2)
    dragHandle:SetHeight(48)
    dragHandle:EnableMouse(true)
    dragHandle:RegisterForDrag("LeftButton")
    dragHandle:SetScript("OnDragStart", function() popup:StartMoving() end)
    dragHandle:SetScript("OnDragStop", function() popup:StopMovingOrSizing() end)

    local title = MakeText(popup, "Stat Goal Matcher Results", "GameFontNormalLarge", nil, CFG.colors.gold, "CENTER")
    Theme.AddPopupLogo(popup)
    title:SetPoint("TOP", popup, "TOP", 0, -18)
    title:SetSize(790, 28)
    local subtitle = MakeText(popup, "Review the matched items, projected stats, and important notes.", "GameFontDisableSmall", nil, CFG.colors.muted, "CENTER")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -2)
    subtitle:SetSize(790, 20)

    local scroll = CreateFrame("ScrollFrame", nil, popup, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", popup, "TOPLEFT", 24, -76)
    scroll:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -42, 60)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(756, 540)
    scroll:SetScrollChild(content)
    popup.scroll = scroll
    popup.content = content
    popup.contentWidth = 756
    popup.minimumContentHeight = 540
    popup.resultCards = {}
    popup.resultY = 0

    local close = MakeSmallButton(popup, "Close", 110, 26)
    close:SetPoint("BOTTOM", popup, "BOTTOM", 0, 20)
    close:SetScript("OnClick", function() popup:Hide() end)
    self.matcherResultsPopup = popup
    return popup
end

function GearTargets:ShowMatcherResults(result)
    if not result then
        if KeyLab.Print then KeyLab.Print("No completed Stat Goal Matcher result is available to display.") end
        return false
    end
    self.visibleMatcherResult = result
    local popup = self:CreateMatcherResultsPopup()
    if popup.renderedResult ~= result then
        RenderMatcherResults(popup, result)
        popup.renderedResult = result
    end
    popup:Show()
    if popup.Raise then popup:Raise() end
    return true
end

function GearTargets:OpenMatcherResults(result)
    result = result or self.visibleMatcherResult
        or KeyLab.StatGoalMatcher and KeyLab.StatGoalMatcher.GetResult and KeyLab.StatGoalMatcher.GetResult(TargetSpecID())
    local ok, openedOrError = pcall(function() return self:ShowMatcherResults(result) end)
    if not ok then
        if KeyLab.Print then KeyLab.Print("The Stat Goal Matcher Results window could not open: " .. tostring(openedOrError)) end
        return false
    end
    return openedOrError == true
end

function GearTargets:CreatePreparationPopup()
    if self.preparationPopup then return self.preparationPopup end
    local popup = CreateFrame("Frame", "KeyLabStatGoalMatcherPreparation", UIParent, "BackdropTemplate")
    popup:SetSize(570, 480)
    popup:SetPoint("CENTER")
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:SetFrameLevel(1000)
    if popup.SetToplevel then popup:SetToplevel(true) end
    popup:SetClampedToScreen(true)
    popup:EnableMouse(true)
    popup:SetMovable(true)
    SetBackdrop(popup, CFG.colors.bg, CFG.colors.gold)
    popup:Hide()

    local dragHandle = CreateFrame("Frame", nil, popup)
    dragHandle:SetPoint("TOPLEFT", popup, "TOPLEFT", 2, -2)
    dragHandle:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -2, -2)
    dragHandle:SetHeight(48)
    dragHandle:EnableMouse(true)
    dragHandle:RegisterForDrag("LeftButton")
    dragHandle:SetScript("OnDragStart", function() popup:StartMoving() end)
    dragHandle:SetScript("OnDragStop", function() popup:StopMovingOrSizing() end)

    local title = MakeText(popup, "Prepare Your Gear", "GameFontNormalLarge", nil, CFG.colors.gold, "CENTER")
    Theme.AddPopupLogo(popup)
    title:SetPoint("TOP", popup, "TOP", 0, -18)
    title:SetSize(530, 28)
    local body = MakeText(popup,
        "Equip every item you want to keep, including Tier, crafted, embellished, set, and other keeper items. Trinket secondary stats are always excluded from the goal projection.\n\n" ..
        "Unequip only the slots you want KeyLab to fill.\n\n" ..
        "Choose where KeyLab should search and how it should match your goals. An open trinket slot may receive advisory Stat Support suggestions. The matcher does not judge roles, bonuses, special effects, or Best in Slot.",
        "GameFontHighlightSmall", nil, CFG.colors.text)
    body:SetPoint("TOPLEFT", popup, "TOPLEFT", 24, -58)
    body:SetSize(522, 145)
    body:SetWordWrap(true)

    popup.sourceDropdown, popup.sourceLabel = MakeDropdown(popup, 232, 24, -216, "Item Source", function(_, level)
        for _, option in ipairs(MATCHER_ITEM_SOURCE_OPTIONS) do
            local value = option.value
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.checked = GearTargets.matcherItemSource == value
            info.func = function()
                GearTargets.matcherItemSource = value
                if popup.RefreshSourceChoice then popup:RefreshSourceChoice() end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    popup.scopeDropdown, popup.scopeLabel = MakeDropdown(popup, 232, 298, -216, "Database Items to Include", function(_, level)
        for _, option in ipairs(ITEM_TYPE_OPTIONS) do
            local value = option.value
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.checked = GearTargets.matcherItemType == value
            info.func = function()
                GearTargets.matcherItemType = value
                SetDropdownText(popup.scopeDropdown, ItemTypeLabel(value))
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    local scopeHelp = MakeText(popup, "This choice is only for this matcher run. It does not change the gear list above.", "GameFontDisableSmall", nil, CFG.colors.muted)
    scopeHelp:SetPoint("TOPLEFT", popup, "TOPLEFT", 24, -274)
    scopeHelp:SetSize(522, 46)
    scopeHelp:SetWordWrap(true)
    popup.styleDropdown = MakeDropdown(popup, 232, 24, -326, "Matching Style", function(_, level)
        for _, option in ipairs(MATCHER_STYLE_OPTIONS) do
            local value = option.value
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.checked = GearTargets.matcherMatchStyle == value
            info.func = function()
                GearTargets.matcherMatchStyle = value
                if KeyLab.StatGoalsDB and KeyLab.StatGoalsDB.SetMatchStyle then
                    KeyLab.StatGoalsDB.SetMatchStyle(TargetSpecID(), value)
                end
                SetDropdownText(popup.styleDropdown, MatcherStyleLabel(value))
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    local styleHelp = MakeText(popup, "Balanced looks for the smallest total gap. Favor Priority gives more weight to your #1 stat, then #2, #3, and #4.", "GameFontDisableSmall", nil, CFG.colors.muted)
    styleHelp:SetPoint("TOPLEFT", popup, "TOPLEFT", 298, -326)
    styleHelp:SetSize(248, 48)
    styleHelp:SetWordWrap(true)
    function popup:RefreshSourceChoice()
        local owned = GearTargets.matcherItemSource == "owned"
        SetDropdownText(self.sourceDropdown, MatcherItemSourceLabel(GearTargets.matcherItemSource))
        SetDropdownText(self.scopeDropdown, owned and "Not used for owned gear" or ItemTypeLabel(GearTargets.matcherItemType))
        if owned and UIDropDownMenu_DisableDropDown then UIDropDownMenu_DisableDropDown(self.scopeDropdown)
        elseif not owned and UIDropDownMenu_EnableDropDown then UIDropDownMenu_EnableDropDown(self.scopeDropdown) end
        self.scopeLabel:SetTextColor(unpack(owned and CFG.colors.muted or CFG.colors.text))
        SetDropdownText(self.styleDropdown, MatcherStyleLabel(GearTargets.matcherMatchStyle))
        scopeHelp:SetText(owned
            and "Equipped gear stays locked. Known upgrade tracks for worn and bag items are projected to their highest rank. Your stat goals come first; other item details break close ties."
            or "Choose Dungeon, Raid, or Dungeon and Raid items. KeyLab evens out recorded item levels so it can compare each item's stat pattern fairly.")
    end

    popup.countdown = MakeText(popup, "", "GameFontHighlightSmall", nil, CFG.colors.blue, "CENTER")
    popup.countdown:SetPoint("TOP", popup, "TOP", 0, -398)
    popup.countdown:SetSize(520, 36)
    popup.countdown:SetWordWrap(true)

    popup.cancel = MakeSmallButton(popup, "Cancel", 100, 24)
    popup.cancel:SetPoint("BOTTOMRIGHT", popup, "BOTTOM", -8, 20)
    popup.cancel:SetScript("OnClick", function() popup:Hide() end)
    popup.run = MakeSmallButton(popup, "Start Matcher", 130, 24)
    popup.run:SetPoint("BOTTOMLEFT", popup, "BOTTOM", 8, 20)
    popup.run:SetScript("OnClick", function()
        if popup.readyAt and GetTime and GetTime() < popup.readyAt then return end
        popup:Hide()
        GearTargets:StartMatcher()
    end)
    popup:SetScript("OnUpdate", function(self)
        if not self:IsShown() then return end
        local now = GetTime and GetTime() or 0
        local remaining = math.max(0, math.ceil((self.readyAt or now) - now))
        local ready = remaining <= 0
        self.run:SetEnabled(ready)
        self.run.label:SetText(ready and "Start Matcher" or ("Start in " .. tostring(remaining)))
        self.run.label:SetTextColor(unpack(ready and CFG.colors.text or CFG.colors.muted))
        self.countdown:SetText(ready
            and "Ready when you are. Nothing runs until you press Start Matcher."
            or "Unequip the slots you want filled. The matcher will be available in " .. tostring(remaining) .. " second(s).")
        self.countdown:SetTextColor(unpack(ready and CFG.colors.green or CFG.colors.blue))
    end)
    self.preparationPopup = popup
    return popup
end

function GearTargets:OpenPreparationPopup()
    local committed, commitMessage = self:CommitVisibleGoals()
    if not committed then
        self.matcherProgressText = commitMessage
        self:RefreshMatcherCard()
        if KeyLab.Print then KeyLab.Print(commitMessage) end
        return
    end
    local valid, message = KeyLab.StatGoalsDB.Validate(TargetSpecID())
    if not valid then
        self.matcherProgressText = message
        self:RefreshMatcherCard()
        if KeyLab.Print then KeyLab.Print(message) end
        return
    end
    self.matcherMatchStyle = KeyLab.StatGoalsDB and KeyLab.StatGoalsDB.GetMatchStyle and KeyLab.StatGoalsDB.GetMatchStyle(TargetSpecID()) or "balanced"
    local popup = self:CreatePreparationPopup()
    popup:RefreshSourceChoice()
    popup.readyAt = (GetTime and GetTime() or 0) + 5
    popup.run:SetEnabled(false)
    popup.run.label:SetText("Start in 5")
    popup.run.label:SetTextColor(unpack(CFG.colors.muted))
    popup:Show()
    popup:Raise()
end

function GearTargets:StartMatcher()
    local matcher = KeyLab.StatGoalMatcher
    if not matcher then return end
    local committed, commitMessage = self:CommitVisibleGoals()
    if not committed then
        self.matcherProgressText = commitMessage
        self:RefreshMatcherCard()
        if KeyLab.Print then KeyLab.Print(commitMessage) end
        return
    end
    self.matcherFinishing = false
    self.matcherCancelling = false
    self.matcherProgressDetail = nil
    self.matcherProgressText = "Stat Goal Matcher running... Results will appear when complete."
    self:RefreshMatcherCard()
    local started, message = matcher.Start({
        specID = TargetSpecID(),
        itemType = self.matcherItemType,
        itemSource = self.matcherItemSource,
        matchStyle = self.matcherMatchStyle,
    }, function(progress)
        local mode = progress.mode or ""
        local completed = tonumber(progress.completed) or 0
        local total = tonumber(progress.total)
        GearTargets.matcherProgressDetail = {
            mode = mode,
            completed = completed,
            total = total,
        }
        GearTargets.matcherProgressText = total and total > 0
            and string.format("Matching items... %s %d / %d. Results appear when complete.", mode, completed, total)
            or ("Matching items... " .. mode .. ". Results appear when complete.")
        GearTargets:RefreshMatcherCard()
    end, function(payload)
        GearTargets:StopMatcherAnimation()
        GearTargets.matcherCancelling = false
        GearTargets.matcherProgressDetail = nil
        if payload and payload.ok then
            GearTargets.sortKey = "match"
            GearTargets.sortAscending = true
            GearTargets.matcherFinishing = true
            GearTargets.matcherProgressText = "Matcher results found. Updating the list..."
        else
            GearTargets.matcherFinishing = false
            GearTargets.matcherProgressText = payload and payload.message or nil
            if payload and payload.message and KeyLab.Print then KeyLab.Print(payload.message) end
        end
        GearTargets:RefreshMatcherCard()
        GearTargets:RefreshContent()
        RefreshExternalTargetViews()
        if payload and payload.ok then
            local function ShowCompletedState()
                GearTargets.matcherFinishing = false
                GearTargets.matcherProgressText = nil
                GearTargets:RefreshMatcherCard()
                GearTargets:OpenMatcherResults(payload.result)
            end
            if C_Timer and C_Timer.After then
                C_Timer.After(0.75, ShowCompletedState)
            else
                ShowCompletedState()
            end
        end
    end)
    if not started then
        self:StopMatcherAnimation()
        self.matcherProgressText = message
        if KeyLab.Print then KeyLab.Print(message) end
        self:RefreshMatcherCard()
    elseif matcher.IsRunning and matcher.IsRunning() then
        self:StartMatcherAnimation()
        self:RefreshMatcherCard()
    end
end

function GearTargets:RefreshFilterControls()
    SetDropdownText(self.itemTypeDropdown, ItemTypeLabel(self.selectedItemType))
    SetDropdownText(self.slotDropdown, self.selectedSlot or "All Slots")
    SetDropdownText(self.sourceDropdown, LootLocationLabel())
    SetDropdownText(self.statusDropdown, StatusFilterLabel(self.selectedStatusFilter))
    self.specValue:SetText(SpecName(TargetSpecID()))
    for _, data in ipairs(self.primaryChecks or {}) do
        data.button:SetChecked(data.stamina and self.selectedStamina == true or data.primary and self.selectedPrimary == data.value)
    end
end

function GearTargets:Refresh()
    if not self.frame then return end
    self:RefreshFilterControls()
    self:RefreshMatcherCard()
    self:RefreshContent()
end

function GearTargets:ClearAllTargets()
    local db = KeyLab.LootTargetsDB
    local specID = TargetSpecID()
    local targets = db and db.GetAllTargetsForSpec and db.GetAllTargetsForSpec(specID) or {}
    if #targets == 0 then
        if KeyLab.Print then KeyLab.Print("There are no saved Targets to clear for this specialization.") end
        return
    end
    for _, item in ipairs(targets) do
        if item and item.itemID and db.SetStatus then db.SetStatus(specID, item.itemID, nil) end
    end
    self:Refresh()
    RefreshExternalTargetViews()
    if KeyLab.Print then KeyLab.Print(tostring(#targets) .. " saved Target" .. (#targets == 1 and " was" or "s were") .. " cleared.") end
end

local function ConfirmClearAllTargets()
    StaticPopupDialogs.KEYLAB_CLEAR_ALL_TARGETS = StaticPopupDialogs.KEYLAB_CLEAR_ALL_TARGETS or {
        text = "Clear every saved Target for your current specialization?\n\nThis works like unmarking each Target one at a time.",
        button1 = "Clear Targets",
        button2 = "Cancel",
        OnAccept = function() GearTargets:ClearAllTargets() end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    Theme.BrandConfirmationDialog(StaticPopupDialogs.KEYLAB_CLEAR_ALL_TARGETS)
    StaticPopup_Show("KEYLAB_CLEAR_ALL_TARGETS")
end

function GearTargets:Create(parent)
    local frame = CreateFrame("Frame", "KeyLabGearTargetsTab", parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    SetBackdrop(frame, CFG.colors.bg, {0, 0, 0, 0})
    self.frame = frame
    self.selectedItemType = nil
    self.matcherItemType = nil
    self.matcherItemSource = "master"
    self.matcherMatchStyle = KeyLab.StatGoalsDB and KeyLab.StatGoalsDB.GetMatchStyle and KeyLab.StatGoalsDB.GetMatchStyle(TargetSpecID()) or "balanced"
    self.selectedSourceID = nil
    self.selectedEncounterID = nil
    self.selectedSlot = nil
    self.selectedPrimary = nil
    self.selectedStamina = false
    self.selectedSecondaries = {}
    self.selectedStatusFilter = "all"
    self.searchText = ""
    self.sortKey = "source"
    self.sortAscending = true

    Theme.CreateTabHeader(
        frame,
        "Gear Targets",
        "Browse all loot specs of your class; save Targets for your current spec. Some items need another loot spec. Hover an item for details.",
        { descriptionWidth = 540, descriptionHeight = 32 }
    )

    self.statusDropdown = MakeDropdown(frame, 150, 580, -12, "Show", function(_, level)
        for _, option in ipairs(STATUS_FILTER_OPTIONS) do
            local value = option.value
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.func = function() GearTargets.selectedStatusFilter = value; GearTargets:Refresh() end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    self.matcherButton = MakeActionButton(frame, "Stat Goal Matcher", 176, 28)
    if Theme.StylePrimaryActionButton then Theme.StylePrimaryActionButton(self.matcherButton) end
    self.matcherButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -24)
    self.matcherButton:SetScript("OnClick", function()
        if KeyLab.StatGoalMatcher and KeyLab.StatGoalMatcher.IsRunning() then
            KeyLab.StatGoalMatcher.Cancel()
            GearTargets.matcherCancelling = true
            GearTargets.matcherProgressText = "Cancelling..."
            GearTargets:RefreshMatcherCard()
        else
            GearTargets:OpenPreparationPopup()
        end
    end)

    self.clearTargetsButton = MakeActionButton(frame, "Clear Targets", 118, 28)
    self.clearTargetsButton:SetScript("OnClick", ConfirmClearAllTargets)

    local controls = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    controls:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, HEADER.standardContentY)
    controls:SetPoint("RIGHT", frame, "RIGHT", -14, 0)
    controls:SetHeight(FILTER_CARD_HEIGHT)
    SetBackdrop(controls, CFG.colors.panel, CFG.colors.border)

    self.itemTypeDropdown = MakeDropdown(controls, 165, 18, -12, "Browse Items", function(_, level)
        for _, option in ipairs(ITEM_TYPE_OPTIONS) do
            local value = option.value
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.func = function()
                GearTargets.selectedItemType = value
                GearTargets.selectedSourceID = nil
                GearTargets.selectedEncounterID = nil
                GearTargets:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    self.slotDropdown = MakeDropdown(controls, 145, 205, -12, "Slot", function(_, level)
        for _, option in ipairs(GetSlotOptions()) do
            local value = option.value
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.func = function() GearTargets.selectedSlot = value; GearTargets:Refresh() end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    self.sourceDropdown = MakeDropdown(controls, 285, 350, -12, "Loot Location", function(_, level)
        for _, option in ipairs(GetSourceOptions()) do
            local selected = option
            local info = UIDropDownMenu_CreateInfo()
            info.text = selected.text
            if selected.title then
                info.isTitle = true
                info.disabled = true
                info.notCheckable = true
            else
                info.func = function()
                    GearTargets.selectedItemType = selected.sourceType
                    GearTargets.selectedSourceID = selected.sourceID
                    GearTargets.selectedEncounterID = selected.encounterID
                    GearTargets:Refresh()
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    local searchLabel = MakeText(controls, "Search Item", "GameFontDisableSmall", nil, CFG.colors.muted)
    searchLabel:SetPoint("TOPLEFT", controls, "TOPLEFT", 660, -12)
    searchLabel:SetSize(180, 16)
    self.searchBox = MakeSearchBox(controls, 180, 26, "Enter item name")
    self.searchBox:SetPoint("TOPLEFT", controls, "TOPLEFT", 660, -34)
    self.searchBox:SetScript("OnTextChanged", function(box)
        if box.placeholder then box.placeholder:SetShown(tostring(box:GetText() or "") == "") end
    end)
    self.searchBox:SetScript("OnEnterPressed", function(box)
        GearTargets.searchText = tostring(box:GetText() or "")
        box:ClearFocus()
        GearTargets:RefreshContent()
    end)
    self.searchBox:HookScript("OnEditFocusLost", function(box)
        local text = tostring(box:GetText() or "")
        if GearTargets.searchText ~= text then GearTargets.searchText = text; GearTargets:RefreshContent() end
    end)

    local specLabel = MakeText(controls, "Saving For Spec", "GameFontDisableSmall", nil, CFG.colors.muted)
    specLabel:SetPoint("TOPRIGHT", controls, "TOPRIGHT", -14, -12)
    specLabel:SetSize(120, 16)
    self.specValue = MakeText(controls, "", "GameFontHighlightSmall", nil, CFG.colors.gold)
    self.specValue:SetPoint("TOPLEFT", specLabel, "TOPLEFT", 0, -26)
    self.specValue:SetSize(120, 20)
    searchLabel:SetPoint("TOPRIGHT", specLabel, "TOPLEFT", -12, 0)
    self.searchBox:SetPoint("TOPRIGHT", specLabel, "TOPLEFT", -12, -22)
    self.searchBox.placeholder:SetPoint("RIGHT", self.searchBox, "RIGHT", -8, -1)

    local primaryLabel = MakeText(controls, "Primary Stats (Choose Stamina and one of Int / Str / Agi)", "GameFontDisableSmall", nil, CFG.colors.muted)
    primaryLabel:SetPoint("TOPLEFT", controls, "TOPLEFT", 18, -76)
    primaryLabel:SetSize(430, 16)
    self.primaryChecks = {}
    local x = 18
    for _, option in ipairs(PRIMARY_OPTIONS) do
        local opt = option
        local cb = CreateFrame("CheckButton", nil, controls, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", controls, "TOPLEFT", x, -94)
        cb:SetSize(22, 22)
        cb:SetScript("OnClick", function(btn)
            if opt.stamina then GearTargets.selectedStamina = btn:GetChecked() == true
            elseif btn:GetChecked() then GearTargets.selectedPrimary = opt.value
            elseif GearTargets.selectedPrimary == opt.value then GearTargets.selectedPrimary = nil end
            GearTargets:RefreshFilterControls()
            GearTargets:RefreshContent()
        end)
        local label = MakeText(controls, opt.label, "GameFontHighlightSmall", nil, CFG.colors.text)
        label:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        label:SetSize(78, 18)
        table.insert(self.primaryChecks, { button = cb, value = opt.value, primary = opt.primary, stamina = opt.stamina })
        x = x + 103
    end

    local secondaryLabel = MakeText(controls, "Secondary Stats (choose up to 2)", "GameFontDisableSmall", nil, CFG.colors.muted)
    secondaryLabel:SetPoint("TOPLEFT", controls, "TOPLEFT", 460, -76)
    secondaryLabel:SetSize(220, 16)
    self.secondaryChecks = {}
    x = 460
    for _, option in ipairs(SECONDARY_OPTIONS) do
        local opt = option
        local cb = CreateFrame("CheckButton", nil, controls, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", controls, "TOPLEFT", x, -94)
        cb:SetSize(22, 22)
        cb:SetScript("OnClick", function(btn)
            if btn:GetChecked() and not GearTargets.selectedSecondaries[opt.value] and SelectedSecondaryCount() >= 2 then
                btn:SetChecked(false)
                if KeyLab.Print then KeyLab.Print("Choose no more than two Secondary Stats filters.") end
                return
            end
            GearTargets.selectedSecondaries[opt.value] = btn:GetChecked() == true or nil
            GearTargets:RefreshContent()
        end)
        local label = MakeText(controls, opt.shortLabel, "GameFontHighlightSmall", nil, CFG.colors.text)
        label:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        label:SetSize(70, 18)
        table.insert(self.secondaryChecks, { button = cb, value = opt.value })
        x = x + 112
    end

    local matcherPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    matcherPanel:SetPoint("TOPLEFT", controls, "BOTTOMLEFT", 0, -SPACING.card)
    matcherPanel:SetPoint("RIGHT", controls, "RIGHT", 0, 0)
    matcherPanel:SetHeight(MATCHER_CARD_HEIGHT)
    SetBackdrop(matcherPanel, CFG.colors.panel, CFG.colors.border)
    self.matcherPanel = matcherPanel
    local matcherTitle = MakeText(matcherPanel, "Stat Goal Guidance", "GameFontNormal", nil, CFG.colors.gold)
    matcherTitle:SetPoint("TOPLEFT", matcherPanel, "TOPLEFT", 14, -10)
    matcherTitle:SetSize(230, 18)
    self.refreshStatsButton = MakeSmallButton(matcherPanel, "Refresh Current Stats", 134, 22)
    self.refreshStatsButton:SetPoint("TOPLEFT", matcherPanel, "TOPLEFT", 260, -7)
    StyleGearTargetControlButton(self.refreshStatsButton)
    self.refreshStatsButton:SetScript("OnClick", function()
        GearTargets:RefreshCurrentStats(true)
    end)
    local matcherNote = MakeText(matcherPanel, "Enter your stat goal percentages. KeyLab excludes trinket stats, fills the other unequipped slots, and projects the finished set.", "GameFontDisableSmall", nil, CFG.colors.muted)
    matcherNote:SetPoint("TOPLEFT", matcherTitle, "BOTTOMLEFT", 0, -4)
    matcherNote:SetSize(380, 28)
    matcherNote:SetWordWrap(true)
    local matcherStatusCard = CreateFrame("Frame", nil, matcherPanel, "BackdropTemplate")
    matcherStatusCard:SetPoint("TOPLEFT", matcherPanel, "TOPLEFT", 8, -66)
    matcherStatusCard:SetSize(392, 46)
    SetBackdrop(matcherStatusCard, CFG.colors.box, CFG.colors.border)
    matcherStatusCard:EnableMouse(true)
    matcherStatusCard:SetScript("OnMouseUp", function()
        GearTargets:OpenMatcherResults()
    end)
    self.matcherStatusCard = matcherStatusCard
    self.matcherState = MakeText(matcherStatusCard, "", "GameFontNormal", nil, CFG.colors.text)
    self.matcherState:SetPoint("TOPLEFT", matcherStatusCard, "TOPLEFT", 10, -8)
    self.matcherState:SetSize(372, 30)
    self.matcherState:SetWordWrap(true)
    self.matcherResultsButton = MakeSmallButton(matcherStatusCard, "Results", 78, 26)
    self.matcherResultsButton:SetPoint("RIGHT", matcherStatusCard, "RIGHT", -8, 0)
    StyleGearTargetControlButton(self.matcherResultsButton)
    self.matcherResultsButton:SetFrameLevel(matcherStatusCard:GetFrameLevel() + 5)
    self.matcherResultsButton:EnableMouse(true)
    self.matcherResultsButton:RegisterForClicks("LeftButtonUp")
    self.matcherResultsButton:SetScript("OnClick", function()
        GearTargets:OpenMatcherResults()
    end)
    self.matcherResultsButton:Hide()

    self.goalBoxes = {}
    self.goalRows = {}
    for _, definition in ipairs(GOAL_FIELDS) do
        local def = definition
        local row = CreateFrame("Frame", nil, matcherPanel)
        row:SetSize(478, 28)
        local rank = MakeText(row, "", "GameFontDisableSmall", nil, CFG.colors.gold)
        rank:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -5)
        rank:SetSize(28, 18)
        local label = MakeText(row, def.label, "GameFontHighlightSmall", nil, CFG.colors.text)
        label:SetPoint("TOPLEFT", row, "TOPLEFT", 34, -5)
        label:SetSize(84, 18)
        local goalLabel = MakeText(row, "Goal", "GameFontDisableSmall", nil, CFG.colors.muted)
        goalLabel:SetPoint("TOPLEFT", row, "TOPLEFT", 120, -5)
        goalLabel:SetSize(38, 18)
        local box = MakeEditBox(row, 52, 22)
        box:SetPoint("TOPLEFT", row, "TOPLEFT", 158, 0)
        box:SetScript("OnEnterPressed", function(edit) GearTargets:SetGoalTargetFromBox(def.key, edit) end)
        box:SetScript("OnEditFocusLost", function(edit) GearTargets:SetGoalTargetFromBox(def.key, edit) end)
        local percent = MakeText(row, "%", "GameFontDisableSmall", nil, CFG.colors.muted)
        percent:SetPoint("LEFT", box, "RIGHT", 3, 0)
        percent:SetSize(16, 18)
        local current = MakeText(row, "Now* —", "GameFontHighlightSmall", nil, CFG.colors.muted)
        current:SetPoint("TOPLEFT", row, "TOPLEFT", 232, -5)
        current:SetSize(94, 18)
        current:SetTextColor(unpack(CFG.colors.text))
        local status = MakeText(row, "", "GameFontHighlightSmall", nil, CFG.colors.muted)
        status:SetPoint("TOPLEFT", row, "TOPLEFT", 330, -5)
        status:SetSize(70, 18)
        local up = MakeSmallButton(row, "^", 28, 20)
        up:SetPoint("TOPLEFT", row, "TOPLEFT", 408, -1)
        up:SetScript("OnClick", function()
            if KeyLab.StatGoalsDB.MoveDisplayStat(TargetSpecID(), def.key, "up") then GearTargets:RefreshMatcherCard() end
        end)
        local down = MakeSmallButton(row, "v", 28, 20)
        down:SetPoint("TOPLEFT", row, "TOPLEFT", 442, -1)
        down:SetScript("OnClick", function()
            if KeyLab.StatGoalsDB.MoveDisplayStat(TargetSpecID(), def.key, "down") then GearTargets:RefreshMatcherCard() end
        end)
        self.goalBoxes[def.key] = box
        self.goalRows[def.key] = { frame = row, rank = rank, current = current, status = status, up = up, down = down }
    end
    self.goalTotal = MakeText(matcherPanel, "Character % goals  |  *Trinkets excluded", "GameFontHighlightSmall", nil, CFG.colors.green)
    self.goalTotal:SetPoint("TOPLEFT", matcherPanel, "TOPLEFT", 14, -116)
    self.goalTotal:SetSize(260, 18)
    local goalHint = MakeText(matcherPanel, "Each may be 0%–100%", "GameFontDisableSmall", nil, CFG.colors.muted)
    goalHint:SetPoint("TOPLEFT", matcherPanel, "TOPLEFT", 278, -116)
    goalHint:SetSize(180, 18)
    self.goalHint = goalHint

    self.summary = MakeText(frame, "Loading loot...", "GameFontDisableSmall", nil, CFG.colors.blue)
    self.summary:SetPoint("TOPLEFT", matcherPanel, "BOTTOMLEFT", 4, -8)
    self.summary:SetSize(760, 18)
    self.clearTargetsButton:SetSize(108, 22)
    self.clearTargetsButton:SetPoint("TOPRIGHT", matcherPanel, "BOTTOMRIGHT", -4, -4)
    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -410)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 18)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(TABLE_WIDTH, 620)
    scroll:SetScrollChild(content)
    self.scroll = scroll
    self.content = content

    local events = CreateFrame("Frame", nil, frame)
    events:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    events:SetScript("OnEvent", function(_, event, unitOrSlot)
        if event == "PLAYER_SPECIALIZATION_CHANGED" and unitOrSlot and unitOrSlot ~= "player" then return end
        if event == "PLAYER_SPECIALIZATION_CHANGED" then
            GearTargets.selectedSourceID = nil
            GearTargets.selectedEncounterID = nil
            GearTargets.selectedSlot = nil
            GearTargets.matcherProgressText = nil
            GearTargets.matcherCurrentPercentages = nil
            if KeyLab.StatGoalMatcher then
                KeyLab.StatGoalMatcher.Cancel()
            end
            if KeyLab.GearCapture and KeyLab.GearCapture.MarkAllSlotsChanged then KeyLab.GearCapture.MarkAllSlotsChanged() end
        elseif event == "PLAYER_EQUIPMENT_CHANGED" then
            if KeyLab.GearCapture and KeyLab.GearCapture.MarkSlotChanged then KeyLab.GearCapture.MarkSlotChanged(unitOrSlot) end
            if KeyLab.StatGoalMatcher then KeyLab.StatGoalMatcher.Cancel() end
            GearTargets:ScheduleCurrentStatsRefresh()
        end
        if GearTargets.frame and GearTargets.frame:IsShown() then GearTargets:Refresh() end
    end)
    self.events = events
    frame:SetScript("OnShow", function()
        if KeyLab.GearCapture and KeyLab.GearCapture.MarkAllSlotsChanged then KeyLab.GearCapture.MarkAllSlotsChanged() end
        GearTargets.matcherCurrentPercentages = nil
        GearTargets:Refresh()
    end)
    return frame
end

function KeyLab_CreateGearTargetsTab(parent)
    return GearTargets:Create(parent)
end

if KeyLab.RegisterTab then
    KeyLab.RegisterTab("Gear Targets", function(parent) return GearTargets:Create(parent) end)
end

return GearTargets
