-- KeyLab_GearTargets.lua
-- Gear Targets tab for KeyLab / M+ Journal
--
-- Purpose:
--   Browse KeyLab's static Midnight Season 1 loot database, filter it, and mark
--   personal Gear Targets for the selected/current spec.
--
-- Notes:
--   - This tab does not scan or modify Blizzard's Adventure Guide.
--   - Master loot data lives in database/KeyLab_GearLootDatabase.lua.
--   - Filter/index helpers live in mapping/KeyLab_GearLootMapping.lua.

local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.UI = KeyLab.UI or {}
KeyLab.Tabs = KeyLab.Tabs or {}

local GearTargets = {}
KeyLab.Tabs.GearTargets = GearTargets

local CFG = {
    colors = {
        bg = {0.025, 0.035, 0.070, 0.96},
        panel = {0.035, 0.055, 0.105, 0.94},
        box = {0.030, 0.050, 0.095, 0.92},
        border = {0.35, 0.55, 0.95, 0.55},
        gold = {0.95, 0.76, 0.32, 1.0},
        text = {0.88, 0.90, 0.96, 1.0},
        muted = {0.62, 0.70, 0.82, 1.0},
        blue = {0.38, 0.68, 1.0, 1.0},
        green = {0.45, 0.95, 0.60, 1.0},
        warning = {1.0, 0.72, 0.35, 1.0},
    },
    rowHeight = 38,
}

local PRIMARY_OPTIONS = {
    { label = "Intellect", value = "Int" },
    { label = "Stamina", value = "Stam" },
    { label = "Agility", value = "Agi" },
    { label = "Strength", value = "Str" },
}

local SECONDARY_OPTIONS = {
    { label = "Critical Strike", value = "Crit" },
    { label = "Haste", value = "Haste" },
    { label = "Mastery", value = "Mastery" },
    { label = "Versatility", value = "Vers" },
}

local STAT_GOAL_STATS = {
    mastery = { label = "Mastery" },
    haste = { label = "Haste" },
    crit = { label = "Crit" },
    versatility = { label = "Versatility" },
}

local STATUS_CYCLE = { "wanted", "backup", "temporary", "ignore", "acquired" }

local STATUS_COLORS = {
    wanted = {0.45, 0.95, 0.60, 1.0},
    backup = {0.38, 0.68, 1.0, 1.0},
    temporary = {0.95, 0.76, 0.32, 1.0},
    ignore = {1.0, 0.72, 0.35, 1.0},
    acquired = {0.70, 0.85, 1.0, 1.0},
    unmarked = {0.62, 0.70, 0.82, 1.0},
}

local function SetBackdrop(frame, color, borderColor)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        edgeSize = 1,
    })
    frame:SetBackdropColor(unpack(color or CFG.colors.panel))
    frame:SetBackdropBorderColor(unpack(borderColor or CFG.colors.border))
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

    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", x - 18, y - 18)
    UIDropDownMenu_SetWidth(dropdown, width)
    UIDropDownMenu_Initialize(dropdown, initFunc)
    return dropdown
end

local function SetDropdownText(dropdown, text)
    UIDropDownMenu_SetText(dropdown, text or "All")
end

local function MakeSmallButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 46, height or 20)
    SetBackdrop(button, CFG.colors.box, CFG.colors.border)

    button.label = MakeText(button, text or "", "GameFontHighlightSmall", nil, CFG.colors.text, "CENTER")
    button.label:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.label:SetSize((width or 46) - 4, (height or 20) - 2)

    button:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(unpack(CFG.colors.blue))
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(unpack(CFG.colors.border))
    end)

    return button
end

local function MakeEditBox(parent, width, height)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(width or 48, height or 22)
    box:SetAutoFocus(false)
    box:SetJustifyH("CENTER")
    box:SetMaxLetters(5)
    box:SetNumeric(false)
    box:SetFontObject("GameFontHighlightSmall")
    return box
end

local function FormatPercent(value)
    value = tonumber(value) or 0
    return string.format("%.1f%%", value)
end

local function CurrentSpecID()
    if KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.GetCurrentSpecID then
        return KeyLab.LootTargetsDB.GetCurrentSpecID()
    end
    local specIndex = GetSpecialization and GetSpecialization()
    if specIndex and GetSpecializationInfo then
        return GetSpecializationInfo(specIndex)
    end
    return 0
end

local function CurrentClassID()
    if KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.GetCurrentClassID then
        return KeyLab.LootTargetsDB.GetCurrentClassID()
    end
    if UnitClass then
        local _, _, classID = UnitClass("player")
        return classID or 0
    end
    return 0
end

local function CurrentClassName()
    if UnitClass then
        local localized = UnitClass("player")
        return localized or "Current Class"
    end
    return "Current Class"
end

local function SpecName(specID)
    if not specID then return "All Specs" end
    if KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.GetSpecName then
        return KeyLab.LootTargetsDB.GetSpecName(specID)
    end
    return "Spec " .. tostring(specID)
end

local function TargetSpecID()
    -- Saved targets are always stored against one concrete spec.
    -- If the browsing filter is "All current-class specs", use the player's current spec for any check/uncheck action.
    return GearTargets.selectedSpecID or CurrentSpecID()
end

local function IsTracked(itemID)
    return KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.IsTracked and KeyLab.LootTargetsDB.IsTracked(TargetSpecID(), itemID)
end

local function SetTracked(itemID, checked)
    if KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.SetTracked then
        KeyLab.LootTargetsDB.SetTracked(TargetSpecID(), itemID, checked == true)
    end
end

local function GetItemStatus(itemID)
    if KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.GetStatus then
        return KeyLab.LootTargetsDB.GetStatus(TargetSpecID(), itemID)
    end
    return IsTracked(itemID) and "wanted" or nil
end

local function SetItemStatus(itemID, status)
    if KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.SetStatus then
        KeyLab.LootTargetsDB.SetStatus(TargetSpecID(), itemID, status)
    else
        SetTracked(itemID, status ~= nil and status ~= "ignore")
    end
end

local function StatusLabel(status)
    if KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.GetStatusLabel then
        return KeyLab.LootTargetsDB.GetStatusLabel(status)
    end
    if status == "wanted" then return "Wanted" end
    if status == "backup" then return "Backup" end
    if status == "temporary" then return "Temporary" end
    if status == "ignore" then return "Ignore" end
    if status == "acquired" then return "Acquired" end
    return "Unmarked"
end

local function NextStatus(status)
    if not status then return "wanted" end
    for index, value in ipairs(STATUS_CYCLE) do
        if value == status then
            if index == #STATUS_CYCLE then return nil end
            return STATUS_CYCLE[index + 1]
        end
    end
    return "wanted"
end

local function StatLabel(statKey)
    if KeyLab.StatGoalGuidance and KeyLab.StatGoalGuidance.GetStatLabel then
        return KeyLab.StatGoalGuidance.GetStatLabel(statKey)
    end
    return STAT_GOAL_STATS[statKey] and STAT_GOAL_STATS[statKey].label or tostring(statKey or "")
end

local function ItemDisplayName(item)
    local name = item and item.name or "Unknown Item"
    return tostring(name):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end

local function GetSpecOptions()
    local list = { { text = "All Specs", value = nil } }
    if KeyLab.GearLootMapping and KeyLab.GearLootMapping.GetSpecList then
        for _, spec in ipairs(KeyLab.GearLootMapping.GetSpecList(CurrentClassID()) or {}) do
            table.insert(list, { text = spec.specName or spec.name or ("Spec " .. tostring(spec.specID)), value = spec.specID })
        end
    end
    return list
end

local function GetDungeonOptions()
    local list = { { text = "All Dungeons", value = nil } }
    if KeyLab.GearLootMapping and KeyLab.GearLootMapping.GetDungeonList then
        for _, dungeon in ipairs(KeyLab.GearLootMapping.GetDungeonList() or {}) do
            table.insert(list, { text = dungeon.name or tostring(dungeon.mapID), value = dungeon.mapID })
        end
    end
    return list
end

local function GetSlotOptions()
    local list = { { text = "All Slots", value = nil } }
    if KeyLab.GearLootMapping and KeyLab.GearLootMapping.GetSlotList then
        for _, slot in ipairs(KeyLab.GearLootMapping.GetSlotList(GearTargets.selectedSpecID, (GearTargets.selectedSpecID and nil) or CurrentClassID()) or {}) do
            if slot and slot ~= "" then
                table.insert(list, { text = slot, value = slot })
            end
        end
    end
    return list
end

function GearTargets:GetFilteredItems()
    if not KeyLab.GearLootMapping or not KeyLab.GearLootMapping.GetFilteredItems then
        return {}
    end

    local filters = {
        specID = self.selectedSpecID,
        classID = (self.selectedSpecID and nil) or CurrentClassID(),
        mapID = self.selectedMapID,
        slot = self.selectedSlot,
        primaryStat = self.selectedPrimary,
        secondaryStats = self.selectedSecondaries,
        includeNonGear = false,
    }

    local items = KeyLab.GearLootMapping.GetFilteredItems(filters) or {}
    if self.selectedOnly then
        local tracked = KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.GetTrackedTable and KeyLab.LootTargetsDB.GetTrackedTable(TargetSpecID()) or {}
        local selected = {}
        for _, item in ipairs(items) do
            if tracked[item.itemID] then table.insert(selected, item) end
        end
        items = selected
    end
    return items
end

function GearTargets:RefreshDropdowns()
    SetDropdownText(self.specDropdown, SpecName(self.selectedSpecID))
    local dungeonName = "All Dungeons"
    if self.selectedMapID and KeyLab.GearLootDatabase and KeyLab.GearLootDatabase.dungeons and KeyLab.GearLootDatabase.dungeons[self.selectedMapID] then
        dungeonName = KeyLab.GearLootDatabase.dungeons[self.selectedMapID].name or dungeonName
    end
    SetDropdownText(self.dungeonDropdown, dungeonName)
    SetDropdownText(self.slotDropdown, self.selectedSlot or "All Slots")
end

function GearTargets:RefreshPrimaryChecks()
    for _, data in ipairs(self.primaryChecks or {}) do
        data.button:SetChecked(self.selectedPrimary == data.value)
    end
end

function GearTargets:SetGoalTargetFromBox(statKey, box)
    if not box or not KeyLab.StatGoalsDB or not KeyLab.StatGoalsDB.SetTarget then return end

    local text = tostring(box:GetText() or "")
    text = text:gsub("%%", ""):gsub(",", "."):gsub("^%s+", ""):gsub("%s+$", "")
    local value = tonumber(text)
    if not value then value = 0 end
    KeyLab.StatGoalsDB.SetTarget(TargetSpecID(), statKey, value)
    box:ClearFocus()
    self:RefreshGoalPanel()
    self:RefreshContent()
end

function GearTargets:RefreshGoalPanel()
    if not self.goalPanel then return end

    local context = KeyLab.StatGoalGuidance and KeyLab.StatGoalGuidance.BuildContext and KeyLab.StatGoalGuidance.BuildContext(TargetSpecID()) or nil
    local goals = context and context.goals or (KeyLab.StatGoalsDB and KeyLab.StatGoalsDB.GetGoals and KeyLab.StatGoalsDB.GetGoals(TargetSpecID())) or {}
    local priority = context and context.priority or goals.priority or {}
    local targets = goals.targets or {}
    local currentStats = context and context.currentStats or {}

    if self.goalSummary then
        local lines = KeyLab.StatGoalGuidance and KeyLab.StatGoalGuidance.GetSummaryLines and KeyLab.StatGoalGuidance.GetSummaryLines(context) or { "Stat goal guidance is unavailable." }
        local shown = {}
        for i = 1, math.min(4, #lines) do
            table.insert(shown, lines[i])
        end
        self.goalSummary:SetText(table.concat(shown, "\n"))
    end

    for rank, statKey in ipairs(priority or {}) do
        local row = self.goalRows and self.goalRows[statKey]
        if row then
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", self.goalPanel, "TOPLEFT", 420, -10 - ((rank - 1) * 31))
            row.rank:SetText("#" .. tostring(rank))
            row.label:SetText(StatLabel(statKey))
            row.targetBox:SetText(tostring(tonumber(targets[statKey]) or 0))
            row.current:SetText("Now " .. FormatPercent(currentStats[statKey]))

            local state = "Set target"
            local color = CFG.colors.muted
            local target = tonumber(targets[statKey]) or 0
            if target > 0 and context then
                if context.below and context.below[statKey] then
                    state = "Below"
                    color = CFG.colors.green
                elseif context.above and context.above[statKey] then
                    state = "Above"
                    color = CFG.colors.warning
                else
                    state = "Near"
                    color = CFG.colors.blue
                end
            end
            row.state:SetText(state)
            row.state:SetTextColor(unpack(color))
        end
    end
end

function GearTargets:MakeLootRow(parent, item, y)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
    row:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
    row:SetHeight(CFG.rowHeight - 4)
    SetBackdrop(row, CFG.colors.box, CFG.colors.border)

    local checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    checkbox:SetPoint("LEFT", row, "LEFT", 6, 0)
    checkbox:SetSize(24, 24)
    checkbox:SetChecked(IsTracked(item.itemID))
    checkbox:SetScript("OnClick", function(btn)
        SetTracked(item.itemID, btn:GetChecked() == true)
        GearTargets:RefreshContent()
        if KeyLab.GearTargetsWindow and KeyLab.GearTargetsWindow.RefreshVisible then
            KeyLab.GearTargetsWindow.RefreshVisible()
        end
    end)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("LEFT", row, "LEFT", 36, 0)
    icon:SetSize(26, 26)
    if item.icon then icon:SetTexture(item.icon) end

    local name = MakeText(row, item.link or ItemDisplayName(item), "GameFontNormal", nil, CFG.colors.text)
    name:SetPoint("LEFT", row, "LEFT", 70, 0)
    name:SetSize(230, 20)

    local slot = MakeText(row, item.slot or "-", "GameFontHighlightSmall", nil, CFG.colors.blue)
    slot:SetPoint("LEFT", row, "LEFT", 310, 0)
    slot:SetSize(78, 18)

    local dungeon = MakeText(row, item.dungeonName or "-", "GameFontHighlightSmall", nil, CFG.colors.muted)
    dungeon:SetPoint("LEFT", row, "LEFT", 390, 0)
    dungeon:SetSize(124, 18)

    local statText = (item.statText and item.statText ~= "" and item.statText) or (item.className or "-")
    local stats = MakeText(row, statText, "GameFontDisableSmall", nil, CFG.colors.muted)
    stats:SetPoint("LEFT", row, "LEFT", 522, 0)
    stats:SetSize(128, 18)

    local guidance = KeyLab.StatGoalGuidance and KeyLab.StatGoalGuidance.GetItemGuidance and KeyLab.StatGoalGuidance.GetItemGuidance(item, self.goalContext) or { label = "-", color = "muted" }
    local guidanceColor = CFG.colors[guidance.color or "muted"] or CFG.colors.muted
    local guidanceText = MakeText(row, guidance.label or "-", "GameFontHighlightSmall", nil, guidanceColor)
    guidanceText:SetPoint("LEFT", row, "LEFT", 660, 0)
    guidanceText:SetSize(106, 18)

    local status = GetItemStatus(item.itemID)
    local statusButton = MakeSmallButton(row, StatusLabel(status), 86, 20)
    statusButton:SetPoint("LEFT", row, "LEFT", 776, 0)
    statusButton.label:SetTextColor(unpack(STATUS_COLORS[status or "unmarked"] or CFG.colors.muted))
    statusButton:SetScript("OnClick", function()
        SetItemStatus(item.itemID, NextStatus(GetItemStatus(item.itemID)))
        GearTargets:RefreshContent()
        if KeyLab.GearTargetsWindow and KeyLab.GearTargetsWindow.RefreshVisible then
            KeyLab.GearTargetsWindow.RefreshVisible()
        end
    end)
    statusButton:SetScript("OnEnter", function(btn)
        btn:SetBackdropBorderColor(unpack(CFG.colors.blue))
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Gear Target Status")
        GameTooltip:AddLine("Click to cycle Wanted, Backup, Temporary, Ignore, Acquired.", 0.8, 0.85, 1.0, true)
        if guidance and guidance.reason then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(guidance.label or "Guidance", 1.0, 0.82, 0.35, true)
            GameTooltip:AddLine(guidance.reason, 0.8, 0.85, 1.0, true)
        end
        GameTooltip:Show()
    end)
    statusButton:SetScript("OnLeave", function(btn)
        btn:SetBackdropBorderColor(unpack(CFG.colors.border))
        GameTooltip:Hide()
    end)

    row:EnableMouse(true)
    row:SetScript("OnEnter", function()
        if item.link then
            GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(item.link)
            GameTooltip:Show()
        elseif item.itemID then
            GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("item:" .. tostring(item.itemID))
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return row
end

function GearTargets:UpdateSummary(items)
    if not self.summary then return end
    items = items or self:GetFilteredItems()
    local tracked = KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.GetTrackedTable and KeyLab.LootTargetsDB.GetTrackedTable(TargetSpecID()) or {}
    local selectedCount = 0
    for _, enabled in pairs(tracked) do if enabled then selectedCount = selectedCount + 1 end end

    local seasonText = ""
    if KeyLab.GearLootMapping and KeyLab.GearLootMapping.GetSeasonInfo then
        local info = KeyLab.GearLootMapping.GetSeasonInfo()
        if info then
            seasonText = "  |  " .. tostring(info.expansion or "") .. " " .. tostring(info.seasonName or "")
        end
    end

    self.summary:SetText(tostring(#items) .. " item(s) shown  |  " .. tostring(selectedCount) .. " target(s) for " .. SpecName(TargetSpecID()) .. seasonText)
end

function GearTargets:RefreshContent()
    if not self.content then return end
    for _, child in ipairs({ self.content:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    self.goalContext = KeyLab.StatGoalGuidance and KeyLab.StatGoalGuidance.BuildContext and KeyLab.StatGoalGuidance.BuildContext(TargetSpecID()) or nil
    local items = self:GetFilteredItems()
    self:UpdateSummary(items)

    local header = CreateFrame("Frame", nil, self.content, "BackdropTemplate")
    header:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, 0)
    header:SetPoint("RIGHT", self.content, "RIGHT", 0, 0)
    header:SetHeight(26)
    SetBackdrop(header, {0.02, 0.03, 0.06, 0.92}, CFG.colors.border)

    MakeText(header, "Item", "GameFontDisableSmall", nil, CFG.colors.gold):SetPoint("LEFT", header, "LEFT", 70, 0)
    MakeText(header, "Slot", "GameFontDisableSmall", nil, CFG.colors.gold):SetPoint("LEFT", header, "LEFT", 310, 0)
    MakeText(header, "Dungeon", "GameFontDisableSmall", nil, CFG.colors.gold):SetPoint("LEFT", header, "LEFT", 390, 0)
    MakeText(header, "Stats", "GameFontDisableSmall", nil, CFG.colors.gold):SetPoint("LEFT", header, "LEFT", 522, 0)
    MakeText(header, "Guidance", "GameFontDisableSmall", nil, CFG.colors.gold):SetPoint("LEFT", header, "LEFT", 660, 0)
    MakeText(header, "Status", "GameFontDisableSmall", nil, CFG.colors.gold):SetPoint("LEFT", header, "LEFT", 780, 0)

    if #items == 0 then
        local msg = "No loot matched these filters."
        if self.selectedOnly then
            msg = "No active Gear Targets matched these filters."
        end
        local text = MakeText(self.content, msg, "GameFontNormal", nil, CFG.colors.warning)
        text:SetPoint("TOPLEFT", self.content, "TOPLEFT", 10, -44)
        text:SetSize(820, 100)
        self.content:SetHeight(180)
        return
    end

    local y = -32
    for _, item in ipairs(items) do
        self:MakeLootRow(self.content, item, y)
        y = y - CFG.rowHeight
    end
    self.content:SetHeight(math.max(520, math.abs(y) + 20))
end

function GearTargets:Refresh()
    if not self.frame then return end
    self:RefreshDropdowns()
    self:RefreshPrimaryChecks()
    self:RefreshGoalPanel()
    self:RefreshContent()
end

function GearTargets:Create(parent)
    local frame = CreateFrame("Frame", "KeyLabGearTargetsTab", parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    SetBackdrop(frame, CFG.colors.bg, {0, 0, 0, 0})
    self.frame = frame
    self.selectedSpecID = nil
    self.selectedMapID = nil
    self.selectedSlot = nil
    self.selectedPrimary = nil
    self.selectedSecondaries = {}
    self.selectedOnly = false

    local title = MakeText(frame, "Gear Targets", "GameFontNormalLarge", nil, CFG.colors.gold)
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -18)
    title:SetSize(420, 28)

    local subtitle = MakeText(frame, "Browse KeyLab's local Midnight Season 1 loot list. The spec filter only shows your current class; All current-class specs saves checks to your current spec.", "GameFontHighlightSmall", nil, CFG.colors.muted)
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    subtitle:SetSize(880, 20)

    local controls = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    controls:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -74)
    controls:SetPoint("RIGHT", frame, "RIGHT", -14, 0)
    controls:SetHeight(136)
    SetBackdrop(controls, CFG.colors.panel, CFG.colors.border)

    self.specDropdown = MakeDropdown(controls, 165, 18, -12, "Loot Spec", function(_, level)
        for _, option in ipairs(GetSpecOptions()) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.func = function()
                GearTargets.selectedSpecID = option.value
                GearTargets:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    self.slotDropdown = MakeDropdown(controls, 145, 205, -12, "Slot", function(_, level)
        for _, option in ipairs(GetSlotOptions()) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.func = function()
                GearTargets.selectedSlot = option.value
                GearTargets:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    self.dungeonDropdown = MakeDropdown(controls, 205, 370, -12, "Dungeon", function(_, level)
        for _, option in ipairs(GetDungeonOptions()) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.func = function()
                GearTargets.selectedMapID = option.value
                GearTargets:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    local selectedOnly = CreateFrame("CheckButton", nil, controls, "UICheckButtonTemplate")
    selectedOnly:SetPoint("TOPLEFT", controls, "TOPLEFT", 605, -27)
    selectedOnly:SetSize(24, 24)
    selectedOnly:SetScript("OnClick", function(btn)
        GearTargets.selectedOnly = btn:GetChecked() == true
        GearTargets:RefreshContent()
    end)
    local selectedLabel = MakeText(controls, "Active targets only", "GameFontHighlightSmall", nil, CFG.colors.text)
    selectedLabel:SetPoint("LEFT", selectedOnly, "RIGHT", 4, 0)
    selectedLabel:SetSize(170, 18)

    local primaryLabel = MakeText(controls, "Primary / Stamina", "GameFontDisableSmall", nil, CFG.colors.muted)
    primaryLabel:SetPoint("TOPLEFT", controls, "TOPLEFT", 18, -76)
    primaryLabel:SetSize(160, 16)

    self.primaryChecks = {}
    local x = 18
    for _, opt in ipairs(PRIMARY_OPTIONS) do
        local cb = CreateFrame("CheckButton", nil, controls, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", controls, "TOPLEFT", x, -94)
        cb:SetSize(22, 22)
        cb:SetScript("OnClick", function(btn)
            if btn:GetChecked() then
                GearTargets.selectedPrimary = opt.value
            else
                GearTargets.selectedPrimary = nil
            end
            GearTargets:RefreshPrimaryChecks()
            GearTargets:RefreshContent()
        end)
        local label = MakeText(controls, opt.label, "GameFontHighlightSmall", nil, CFG.colors.text)
        label:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        label:SetSize(82, 18)
        table.insert(self.primaryChecks, { button = cb, value = opt.value })
        x = x + 103
    end

    local secondaryLabel = MakeText(controls, "Secondary Stats", "GameFontDisableSmall", nil, CFG.colors.muted)
    secondaryLabel:SetPoint("TOPLEFT", controls, "TOPLEFT", 460, -76)
    secondaryLabel:SetSize(160, 16)

    x = 460
    for _, opt in ipairs(SECONDARY_OPTIONS) do
        local cb = CreateFrame("CheckButton", nil, controls, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", controls, "TOPLEFT", x, -94)
        cb:SetSize(22, 22)
        cb:SetScript("OnClick", function(btn)
            if btn:GetChecked() then
                GearTargets.selectedSecondaries[opt.value] = true
            else
                GearTargets.selectedSecondaries[opt.value] = nil
            end
            GearTargets:RefreshContent()
        end)
        local label = MakeText(controls, opt.label, "GameFontHighlightSmall", nil, CFG.colors.text)
        label:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        label:SetSize(90, 18)
        x = x + 118
    end

    local goalPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    goalPanel:SetPoint("TOPLEFT", controls, "BOTTOMLEFT", 0, -24)
    goalPanel:SetPoint("RIGHT", controls, "RIGHT", 0, 0)
    goalPanel:SetHeight(144)
    SetBackdrop(goalPanel, CFG.colors.panel, CFG.colors.border)
    self.goalPanel = goalPanel

    local goalTitle = MakeText(goalPanel, "Stat Goal Guidance", "GameFontNormal", nil, CFG.colors.gold)
    goalTitle:SetPoint("TOPLEFT", goalPanel, "TOPLEFT", 14, -10)
    goalTitle:SetSize(360, 18)

    local goalNote = MakeText(goalPanel, "Personal target guidance for Heroic/Mythic-track gear. Set comfort goals; KeyLab labels items without trying to simulate BiS.", "GameFontDisableSmall", nil, CFG.colors.muted)
    goalNote:SetPoint("TOPLEFT", goalTitle, "BOTTOMLEFT", 0, -2)
    goalNote:SetSize(380, 32)
    goalNote:SetWordWrap(true)

    self.goalSummary = MakeText(goalPanel, "", "GameFontHighlightSmall", nil, CFG.colors.text)
    self.goalSummary:SetPoint("TOPLEFT", goalPanel, "TOPLEFT", 14, -62)
    self.goalSummary:SetSize(390, 78)
    self.goalSummary:SetWordWrap(true)

    self.goalRows = {}
    for statKey in pairs(STAT_GOAL_STATS) do
        local key = statKey
        local row = CreateFrame("Frame", nil, goalPanel)
        row:SetSize(520, 26)

        row.rank = MakeText(row, "", "GameFontDisableSmall", nil, CFG.colors.gold)
        row.rank:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.rank:SetSize(28, 18)

        row.label = MakeText(row, "", "GameFontHighlightSmall", nil, CFG.colors.text)
        row.label:SetPoint("LEFT", row, "LEFT", 36, 0)
        row.label:SetSize(88, 18)

        local goalLabel = MakeText(row, "Goal", "GameFontDisableSmall", nil, CFG.colors.muted)
        goalLabel:SetPoint("LEFT", row, "LEFT", 126, 0)
        goalLabel:SetSize(34, 18)

        row.targetBox = MakeEditBox(row, 46, 22)
        row.targetBox:SetPoint("LEFT", row, "LEFT", 164, 0)
        row.targetBox:SetScript("OnEnterPressed", function(box)
            GearTargets:SetGoalTargetFromBox(key, box)
        end)
        row.targetBox:SetScript("OnEditFocusLost", function(box)
            GearTargets:SetGoalTargetFromBox(key, box)
        end)

        row.current = MakeText(row, "", "GameFontDisableSmall", nil, CFG.colors.muted)
        row.current:SetPoint("LEFT", row, "LEFT", 224, 0)
        row.current:SetSize(86, 18)

        row.state = MakeText(row, "", "GameFontHighlightSmall", nil, CFG.colors.muted)
        row.state:SetPoint("LEFT", row, "LEFT", 318, 0)
        row.state:SetSize(54, 18)

        row.up = MakeSmallButton(row, "^", 24, 20)
        row.up:SetPoint("LEFT", row, "LEFT", 386, 0)
        row.up:SetScript("OnClick", function()
            if KeyLab.StatGoalsDB and KeyLab.StatGoalsDB.MovePriority then
                KeyLab.StatGoalsDB.MovePriority(TargetSpecID(), key, -1)
                GearTargets:RefreshGoalPanel()
                GearTargets:RefreshContent()
            end
        end)

        row.down = MakeSmallButton(row, "v", 24, 20)
        row.down:SetPoint("LEFT", row.up, "RIGHT", 4, 0)
        row.down:SetScript("OnClick", function()
            if KeyLab.StatGoalsDB and KeyLab.StatGoalsDB.MovePriority then
                KeyLab.StatGoalsDB.MovePriority(TargetSpecID(), key, 1)
                GearTargets:RefreshGoalPanel()
                GearTargets:RefreshContent()
            end
        end)

        self.goalRows[key] = row
    end

    self.summary = MakeText(frame, "Loading loot...", "GameFontDisableSmall", nil, CFG.colors.blue)
    self.summary:SetPoint("TOPLEFT", goalPanel, "BOTTOMLEFT", 4, -8)
    self.summary:SetSize(900, 18)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -410)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 18)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(880, 620)
    scroll:SetScrollChild(content)

    self.scroll = scroll
    self.content = content

    frame:SetScript("OnShow", function() GearTargets:Refresh() end)
    GearTargets:Refresh()
    return frame
end

function KeyLab_CreateGearTargetsTab(parent)
    return GearTargets:Create(parent)
end

if KeyLab.RegisterTab then
    KeyLab.RegisterTab("Gear Targets", function(parent)
        return GearTargets:Create(parent)
    end)
end

return GearTargets
