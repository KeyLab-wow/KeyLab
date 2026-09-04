local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.GearTargetsWindow = KeyLab.GearTargetsWindow or {}
local GearWindow = KeyLab.GearTargetsWindow

--[[
KeyLab_GearTargetsWindow.lua

Purpose:
- Standalone KeyLab-styled saved gear shopping list.
- Opens manually or while browsing Premade Group dungeon and raid listings.
- Shows the current specialization's still-needed Targets and a few Alternatives.
- Groups saved items by their recorded dungeon or raid instead of trying to
  infer the activity underneath the mouse.
]]

local CFG = {
    width = 760,
    minWidth = 620,
    maxWidth = 1100,
    minHeight = 390,
    maxHeight = 760,
    lineHeight = 19,
    maxAlternativesShown = 8,
    colors = {
        bg = {0.018, 0.026, 0.056, 0.98},
        panel = {0.026, 0.046, 0.086, 0.96},
        border = {0.240, 0.380, 0.620, 0.62},
        gold = {0.820, 0.760, 0.580, 1.0},
        text = {0.940, 0.960, 0.990, 1.0},
        muted = {0.680, 0.730, 0.820, 1.0},
        blue = {0.500, 0.680, 0.940, 1.0},
        green = {0.470, 0.850, 0.550, 1.0},
        violet = {0.720, 0.560, 0.980, 1.0},
        activity = {1.000, 0.840, 0.300, 1.0},
    },
}

local frame
local completionFrame
local SLOT_SORT = {
    ["Head"] = 1, ["Neck"] = 2, ["Shoulders"] = 3, ["Back"] = 4,
    ["Chest"] = 5, ["Wrist"] = 6, ["Hands"] = 7, ["Waist"] = 8,
    ["Legs"] = 9, ["Feet"] = 10, ["Finger 1"] = 11, ["Finger 2"] = 12,
    ["Trinket 1"] = 13, ["Trinket 2"] = 14, ["Main Hand"] = 15, ["Off Hand"] = 16,
}

local function SetBackdrop(f, color, borderColor)
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        edgeSize = 1,
    })
    f:SetBackdropColor(unpack(color or CFG.colors.panel))
    f:SetBackdropBorderColor(unpack(borderColor or CFG.colors.border))
end

local function AddWindowArtwork(f)
    local art = f:CreateTexture(nil, "BACKGROUND", nil, 1)
    art:SetAllPoints(f)
    art:SetTexture("Interface\\AddOns\\KeyLab\\Assets\\KeyLabWindowBackground.tga")
    art:SetTexCoord(0, CFG.width / 2048, 0, CFG.maxHeight / 1024)
    art:SetAlpha(0.32)
    f.backgroundArtwork = art

    local icon = f:CreateTexture(nil, "ARTWORK", nil, 2)
    icon:SetTexture("Interface\\AddOns\\KeyLab\\Assets\\KeyLabKeyIcon.tga")
    icon:SetTexCoord(0, 1, 1, 0)
    icon:SetSize(42, 42)
    icon:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -10)
    f.keyLabIcon = icon
end

local function AddLine(f, text, color, indent)
    f.lineIndex = (f.lineIndex or 0) + 1
    local fs = f.lines[f.lineIndex]
    if not fs then
        fs = f.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetJustifyH("LEFT")
        fs:SetWordWrap(false)
        f.lines[f.lineIndex] = fs
    end
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", f.content, "TOPLEFT", 12 + (indent or 0),
        -((f.lineIndex - 1) * CFG.lineHeight))
    fs:SetPoint("RIGHT", f.content, "RIGHT", -10, 0)
    fs:SetTextColor(unpack(color or CFG.colors.text))
    fs:SetText(text or "")
    fs:Show()
    return fs
end

local function AddBlank(f)
    AddLine(f, " ", CFG.colors.muted)
end

local function HideUnusedLines(f)
    for index = (f.lineIndex or 0) + 1, #(f.lines or {}) do
        f.lines[index]:Hide()
    end
end

local function StripColorCodes(text)
    return tostring(text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end

local function NormalizeName(value)
    value = tostring(value or "")
    value = value:gsub("[%p%c%s]+", "")
    return string.lower(value)
end

local function CurrentSpecID()
    if KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.GetCurrentSpecID then
        return KeyLab.LootTargetsDB.GetCurrentSpecID()
    end
    return nil
end

local function SortItems(items)
    table.sort(items, function(a, b)
        local slotA = tostring(a.slotInstance or a.slot or "")
        local slotB = tostring(b.slotInstance or b.slot or "")
        local orderA = SLOT_SORT[slotA] or 99
        local orderB = SLOT_SORT[slotB] or 99
        if orderA ~= orderB then return orderA < orderB end
        if slotA ~= slotB then return slotA < slotB end
        return StripColorCodes(a.name or a.itemID) < StripColorCodes(b.name or b.itemID)
    end)
end

local function AddItem(f, item, bagItems, isAlternative)
    local slotName = item.slotInstance or item.slot or "Gear"
    local itemName = StripColorCodes(item.name or ("Item " .. tostring(item.itemID)))
    local suffix = isAlternative and " (Alternative)" or ""
    local bagRecord = bagItems and bagItems[tonumber(item.itemID)]
    local bagTrack = bagRecord and (bagRecord.track or item.upgradeTrack)
    if bagTrack == "Hero" or bagTrack == "Myth" then
        suffix = suffix .. " (In Bags - " .. bagTrack .. ")"
    end
    AddLine(f, tostring(slotName) .. " - " .. itemName .. suffix,
        isAlternative and CFG.colors.blue or CFG.colors.text, 22)
end

local function GetTargetSource(item)
    local mapping = KeyLab.GearLootMapping
    local source
    if item and item.sourceID and mapping and mapping.GetSource then
        source = mapping.GetSource(item.sourceID)
    end

    if (not source or (source.sourceType ~= "Dungeon" and source.sourceType ~= "Raid"))
        and item and mapping and mapping.GetItemSources then
        for _, candidate in ipairs(mapping.GetItemSources(item.itemID, CurrentSpecID()) or {}) do
            if candidate.sourceType == "Dungeon" or candidate.sourceType == "Raid" then
                source = candidate
                break
            end
        end
    end

    local sourceName = source and (source.name or source.sourceName)
        or item and item.sourceName
        or "Other Saved Gear"
    local sourceType = source and source.sourceType or item and item.sourceType
    if sourceType ~= "Dungeon" and sourceType ~= "Raid" then sourceType = "Other" end
    if sourceType == "Other" and (sourceName == "Bags" or tostring(sourceName):find("^Bags %- ")) then
        sourceName = "Other Saved Gear"
    end
    return {
        sourceID = source and tonumber(source.sourceID) or tonumber(item and item.sourceID),
        sourceName = sourceName,
        sourceType = sourceType,
    }
end

local function BuildTargetGroups(targets, alternatives)
    local groupsByKey, groups = {}, {}
    local function AddToGroup(item, isAlternative)
        local info = GetTargetSource(item)
        local key = info.sourceID and ("id:" .. tostring(info.sourceID))
            or (info.sourceType .. ":" .. NormalizeName(info.sourceName))
        local group = groupsByKey[key]
        if not group then
            group = {
                sourceID = info.sourceID,
                sourceName = info.sourceName,
                sourceType = info.sourceType,
                targets = {},
                alternatives = {},
            }
            groupsByKey[key] = group
            table.insert(groups, group)
        end
        table.insert(isAlternative and group.alternatives or group.targets, item)
    end

    for _, item in ipairs(targets or {}) do AddToGroup(item, false) end
    for _, item in ipairs(alternatives or {}) do AddToGroup(item, true) end

    local typeOrder = { Dungeon = 1, Raid = 2, Other = 3 }
    table.sort(groups, function(a, b)
        local orderA = typeOrder[a.sourceType] or 9
        local orderB = typeOrder[b.sourceType] or 9
        if orderA ~= orderB then return orderA < orderB end
        return tostring(a.sourceName or "") < tostring(b.sourceName or "")
    end)
    for _, group in ipairs(groups) do
        SortItems(group.targets)
        SortItems(group.alternatives)
    end
    return groups
end

local function FilterGroups(groups, sourceType)
    local out = {}
    for _, group in ipairs(groups or {}) do
        if group.sourceType == sourceType then table.insert(out, group) end
    end
    return out
end

local function AddGroupSection(f, title, groups, bagItems, alternativeBudget)
    if #(groups or {}) == 0 then return end
    local sectionStarted = false
    for _, group in ipairs(groups) do
        local canShowAlternative = alternativeBudget.value > 0 and #(group.alternatives or {}) > 0
        if #(group.targets or {}) > 0 or canShowAlternative then
            if not sectionStarted then
                AddBlank(f)
                AddLine(f, title, CFG.colors.blue)
                sectionStarted = true
            end
            AddLine(f, tostring(group.sourceName), CFG.colors.gold, 10)
            for _, item in ipairs(group.targets or {}) do
                AddItem(f, item, bagItems, false)
            end
            for _, item in ipairs(group.alternatives or {}) do
                if alternativeBudget.value > 0 then
                    AddItem(f, item, bagItems, true)
                    alternativeBudget.value = alternativeBudget.value - 1
                    alternativeBudget.shown = alternativeBudget.shown + 1
                end
            end
        end
    end
end

local function ResetCards(f)
    f.cardIndex = 0
    f.contentY = 0
    for _, card in ipairs(f.cards or {}) do
        card:Hide()
        for _, line in ipairs(card.lines or {}) do line:Hide() end
        for _, panel in ipairs(card.rollGroupPanels or {}) do panel:Hide() end
    end
end

local function NewCard(f, title, accentColor)
    f.cardIndex = (f.cardIndex or 0) + 1
    local card = f.cards[f.cardIndex]
    if not card then
        card = CreateFrame("Frame", nil, f.content, "BackdropTemplate")
        card.lines = {}
        f.cards[f.cardIndex] = card
    end
    card:ClearAllPoints()
    card:SetPoint("TOPLEFT", f.content, "TOPLEFT", 0, f.contentY or 0)
    card:SetWidth(f.contentWidth)
    SetBackdrop(card, CFG.colors.panel, accentColor or CFG.colors.border)
    card.lineIndex = 0
    card.rollGroupIndex = 0
    for _, panel in ipairs(card.rollGroupPanels or {}) do panel:Hide() end
    if card.columnDivider then card.columnDivider:Hide() end
    card.cursorY = -12
    card:Show()

    if title and title ~= "" then
        card.lineIndex = 1
        local fs = card.lines[1]
        if not fs then
            fs = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            fs:SetJustifyH("LEFT")
            fs:SetWordWrap(false)
            card.lines[1] = fs
        end
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", card, "TOPLEFT", 14, card.cursorY)
        fs:SetPoint("RIGHT", card, "RIGHT", -14, 0)
        fs:SetTextColor(unpack(accentColor or CFG.colors.gold))
        fs:SetText(title)
        fs:Show()
        card.cursorY = card.cursorY - 27
    end
    return card
end

local function AddCardLine(card, text, color, indent, template, wrap)
    card.lineIndex = (card.lineIndex or 0) + 1
    local fs = card.lines[card.lineIndex]
    if not fs then
        fs = card:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
        fs:SetJustifyH("LEFT")
        card.lines[card.lineIndex] = fs
    end
    local lineHeight = wrap and 30 or CFG.lineHeight
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", card, "TOPLEFT", 14 + (indent or 0), card.cursorY)
    fs:SetPoint("RIGHT", card, "RIGHT", -14, 0)
    fs:SetHeight(lineHeight)
    fs:SetJustifyV("TOP")
    fs:SetWordWrap(wrap == true)
    fs:SetTextColor(unpack(color or CFG.colors.text))
    fs:SetText(text or "")
    fs:Show()
    card.cursorY = card.cursorY - lineHeight
    return fs
end

local function AddColumnLine(card, column, text, color, indent, template, wrap)
    card.lineIndex = (card.lineIndex or 0) + 1
    local fs = card.lines[card.lineIndex]
    if not fs then
        fs = card:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
        fs:SetJustifyH("LEFT")
        card.lines[card.lineIndex] = fs
    end
    local lineHeight = wrap and 30 or CFG.lineHeight
    local gap = 18
    local columnWidth = math.floor(((card:GetWidth() or 600) - 28 - gap) / 2)
    local x = 14 + ((column - 1) * (columnWidth + gap))
    local y = card.columnY[column]
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", card, "TOPLEFT", x + (indent or 0), y)
    fs:SetSize(columnWidth - (indent or 0), lineHeight)
    fs:SetJustifyV("TOP")
    fs:SetWordWrap(wrap == true)
    fs:SetTextColor(unpack(color or CFG.colors.text))
    fs:SetText(text or "")
    fs:Show()
    card.columnY[column] = y - lineHeight
    return fs
end

local function AddRollGroupPanel(card, column, group, fullWidth)
    card.rollGroupIndex = (card.rollGroupIndex or 0) + 1
    card.rollGroupPanels = card.rollGroupPanels or {}
    local panel = card.rollGroupPanels[card.rollGroupIndex]
    if not panel then
        panel = CreateFrame("Frame", nil, card, "BackdropTemplate")
        panel.itemLines = {}
        panel.itemRows = {}
        panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        panel.title:SetJustifyH("LEFT")
        panel.kind = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        panel.kind:SetJustifyH("RIGHT")
        card.rollGroupPanels[card.rollGroupIndex] = panel
    end

    local gap = 18
    local cardWidth = card:GetWidth() or 600
    local columnWidth = math.floor((cardWidth - 28 - gap) / 2)
    local panelWidth = fullWidth and (cardWidth - 28) or columnWidth
    local x = fullWidth and 14 or (14 + ((column - 1) * (columnWidth + gap)))
    local y = fullWidth and card.cursorY or card.columnY[column]
    local itemCount = #(group.items or {})
    local rowCount = fullWidth and math.ceil(itemCount / 2) or itemCount
    local panelHeight = 42 + (math.max(1, rowCount) * CFG.lineHeight)
    local kindColor = group.sourceType == "Raid" and CFG.colors.violet or CFG.colors.blue

    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", card, "TOPLEFT", x, y)
    panel:SetSize(panelWidth, panelHeight)
    SetBackdrop(panel, {0.012, 0.025, 0.052, 0.98}, kindColor)

    panel.title:ClearAllPoints()
    panel.title:SetPoint("TOPLEFT", panel, "TOPLEFT", 11, -9)
    panel.title:SetSize(panelWidth - 96, 20)
    panel.title:SetTextColor(unpack(CFG.colors.activity))
    panel.title:SetText(tostring(group.sourceName or "Current Activity"))

    panel.kind:ClearAllPoints()
    panel.kind:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -11)
    panel.kind:SetSize(78, 16)
    panel.kind:SetTextColor(unpack(kindColor))
    panel.kind:SetText(group.sourceType == "Raid" and "RAID" or "DUNGEON")

    local itemColumnWidth = fullWidth and math.floor((panelWidth - 34) / 2) or (panelWidth - 22)
    for index, item in ipairs(group.items or {}) do
        local row = panel.itemRows[index]
        if not row then
            row = panel:CreateTexture(nil, "BACKGROUND")
            row:SetTexture("Interface\\Buttons\\WHITE8x8")
            panel.itemRows[index] = row
        end
        local line = panel.itemLines[index]
        if not line then
            line = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            line:SetJustifyH("LEFT")
            line:SetWordWrap(false)
            panel.itemLines[index] = line
        end
        local itemColumn = fullWidth and (((index - 1) % 2) + 1) or 1
        local itemRow = fullWidth and math.floor((index - 1) / 2) or (index - 1)
        local itemX = 11 + ((itemColumn - 1) * (itemColumnWidth + 12))
        local rowY = -31 - (itemRow * CFG.lineHeight)
        local label = tostring(item.displaySlot or item.slotName or "Gear")
            .. " - " .. tostring(item.itemName or "Myth Item")
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", panel, "TOPLEFT", itemX - 3, rowY)
        row:SetSize(itemColumnWidth + 6, CFG.lineHeight - 1)
        if itemRow % 2 == 0 then
            row:SetVertexColor(0.060, 0.100, 0.165, 0.72)
        else
            row:SetVertexColor(0.030, 0.060, 0.115, 0.72)
        end
        row:Show()
        line:ClearAllPoints()
        line:SetPoint("TOPLEFT", panel, "TOPLEFT", itemX, -32 - (itemRow * CFG.lineHeight))
        line:SetSize(itemColumnWidth, CFG.lineHeight)
        line:SetTextColor(unpack(item.isTier and CFG.colors.gold or CFG.colors.text))
        line:SetText(label)
        line:Show()
    end
    for index = itemCount + 1, #(panel.itemLines or {}) do
        panel.itemLines[index]:Hide()
        if panel.itemRows[index] then panel.itemRows[index]:Hide() end
    end
    panel:Show()

    if fullWidth then
        card.cursorY = y - panelHeight - 8
    else
        card.columnY[column] = y - panelHeight - 8
    end
end

local function AddDungeonRunPanel(card, column, dungeonName, badgeText, rows, accentColor, backgroundColor)
    card.rollGroupIndex = (card.rollGroupIndex or 0) + 1
    card.rollGroupPanels = card.rollGroupPanels or {}
    local panel = card.rollGroupPanels[card.rollGroupIndex]
    if not panel then
        panel = CreateFrame("Frame", nil, card, "BackdropTemplate")
        panel.itemLines = {}
        panel.itemRows = {}
        panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        panel.title:SetJustifyH("LEFT")
        panel.kind = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        panel.kind:SetJustifyH("RIGHT")
        card.rollGroupPanels[card.rollGroupIndex] = panel
    end

    local gap = 18
    local cardWidth = card:GetWidth() or 600
    local columnWidth = math.floor((cardWidth - 28 - gap) / 2)
    local x = 14 + ((column - 1) * (columnWidth + gap))
    local y = card.columnY[column]
    local rowHeight = 30
    local panelHeight = 43 + (math.max(1, #rows) * rowHeight)

    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", card, "TOPLEFT", x, y)
    panel:SetSize(columnWidth, panelHeight)
    SetBackdrop(panel, backgroundColor or {0.014, 0.030, 0.062, 0.98}, accentColor)

    panel.title:ClearAllPoints()
    panel.title:SetPoint("TOPLEFT", panel, "TOPLEFT", 11, -9)
    panel.title:SetSize(columnWidth - 108, 20)
    panel.title:SetWordWrap(false)
    panel.title:SetTextColor(unpack(CFG.colors.activity))
    panel.title:SetText(tostring(dungeonName or "Dungeon"))

    panel.kind:ClearAllPoints()
    panel.kind:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -11)
    panel.kind:SetSize(88, 16)
    panel.kind:SetTextColor(unpack(accentColor))
    panel.kind:SetText(tostring(badgeText or ""))

    for index, rowData in ipairs(rows) do
        local row = panel.itemRows[index]
        if not row then
            row = panel:CreateTexture(nil, "BACKGROUND")
            row:SetTexture("Interface\\Buttons\\WHITE8x8")
            panel.itemRows[index] = row
        end
        local line = panel.itemLines[index]
        if not line then
            line = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            line:SetJustifyH("LEFT")
            line:SetWordWrap(false)
            panel.itemLines[index] = line
        end

        local rowY = -32 - ((index - 1) * rowHeight)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, rowY)
        row:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, rowY)
        row:SetHeight(rowHeight - 2)
        if backgroundColor and index % 2 == 1 then
            row:SetVertexColor(0.130, 0.055, 0.180, 0.78)
        elseif backgroundColor then
            row:SetVertexColor(0.075, 0.035, 0.120, 0.78)
        elseif index % 2 == 1 then
            row:SetVertexColor(0.060, 0.100, 0.165, 0.74)
        else
            row:SetVertexColor(0.030, 0.060, 0.115, 0.74)
        end
        row:Show()

        line:ClearAllPoints()
        line:SetPoint("TOPLEFT", panel, "TOPLEFT", 13, rowY - 2)
        line:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -13, rowY - 2)
        line:SetHeight(rowHeight - 2)
        line:SetJustifyV("MIDDLE")
        line:SetWordWrap(true)
        line:SetTextColor(unpack(rowData.color or CFG.colors.text))
        line:SetText(tostring(rowData.text or ""))
        line:Show()
    end
    for index = #rows + 1, #(panel.itemLines or {}) do
        panel.itemLines[index]:Hide()
        if panel.itemRows[index] then panel.itemRows[index]:Hide() end
    end

    panel:Show()
    card.columnY[column] = y - panelHeight - 9
end

local function AddCardGap(card, height)
    card.cursorY = card.cursorY - (height or 8)
end

local function TargetTrackSuffix(item, bagItems)
    if item and item.ownedTargetCopy == true then
        local track = item.ownedTrack
        if track and track ~= "" then
            return " (Owned - " .. tostring(track) .. "; Myth still needed)"
        end
        return " (Owned; Myth still needed)"
    end
    local bagRecord = bagItems and bagItems[tonumber(item and item.itemID)]
    local bagTrack = bagRecord and (bagRecord.track or item.upgradeTrack)
    return (bagTrack == "Hero" or bagTrack == "Myth")
        and (" (In Bags - " .. bagTrack .. ")") or ""
end

local function FinishCard(f, card)
    for index = (card.lineIndex or 0) + 1, #(card.lines or {}) do card.lines[index]:Hide() end
    local height = math.max(54, math.abs(card.cursorY or -54) + 10)
    card:SetHeight(height)
    f.contentY = (f.contentY or 0) - height - 10
    return card
end

local function AddSavedGearCard(f, title, groups, bagItems, alternativeBudget)
    if #(groups or {}) == 0 then return end
    local targetCount, alternativeCount = 0, 0
    for _, group in ipairs(groups) do
        targetCount = targetCount + #(group.targets or {})
        alternativeCount = alternativeCount + #(group.alternatives or {})
    end
    local countText = tostring(targetCount) .. (targetCount == 1 and " Target" or " Targets")
    if alternativeCount > 0 then
        countText = countText .. "  •  " .. tostring(alternativeCount)
            .. (alternativeCount == 1 and " Alternative" or " Alternatives")
    end
    local card = NewCard(f, title .. "  •  " .. countText, CFG.colors.blue)
    AddCardLine(card, "Run the activity below for the saved item or a higher-track copy.",
        CFG.colors.muted, 0, "GameFontDisableSmall")
    AddCardGap(card, 3)
    local added = false
    for _, group in ipairs(groups) do
        local canShowAlternative = alternativeBudget.value > 0 and #(group.alternatives or {}) > 0
        if #(group.targets or {}) > 0 or canShowAlternative then
            if added then AddCardGap(card, 5) end
            AddCardLine(card, tostring(group.sourceName), CFG.colors.gold, 0, "GameFontNormal")
            for _, item in ipairs(group.targets or {}) do
                local slotName = item.slotInstance or item.slot or "Gear"
                local itemName = StripColorCodes(item.name or ("Item " .. tostring(item.itemID)))
                local suffix = TargetTrackSuffix(item, bagItems)
                AddCardLine(card, "•  " .. tostring(slotName) .. " - " .. itemName .. suffix,
                    CFG.colors.text, 16)
            end
            for _, item in ipairs(group.alternatives or {}) do
                if alternativeBudget.value > 0 then
                    local slotName = item.slotInstance or item.slot or "Gear"
                    local itemName = StripColorCodes(item.name or ("Item " .. tostring(item.itemID)))
                    local bagRecord = bagItems and bagItems[tonumber(item.itemID)]
                    local bagTrack = bagRecord and (bagRecord.track or item.upgradeTrack)
                    local suffix = " (Alternative)"
                    if bagTrack == "Hero" or bagTrack == "Myth" then
                        suffix = suffix .. " (In Bags - " .. bagTrack .. ")"
                    end
                    AddCardLine(card, "◇  " .. tostring(slotName) .. " - " .. itemName .. suffix,
                        CFG.colors.blue, 16)
                    alternativeBudget.value = alternativeBudget.value - 1
                    alternativeBudget.shown = alternativeBudget.shown + 1
                end
            end
            added = true
        end
    end
    if added then FinishCard(f, card) else card:Hide() end
end

local function AddDungeonRunCard(f, targetGroups, catalystGroups, bagItems, alternativeBudget)
    targetGroups = targetGroups or {}
    catalystGroups = catalystGroups or {}
    if #targetGroups == 0 and #catalystGroups == 0 then return end
    local tierSlots = {Head=true, Shoulders=true, Chest=true, Hands=true, Legs=true}
    local tierGroups, tierBySource, targetSlots = {}, {}, {}
    local function AddTierRow(group, slot, text)
        local key = group.sourceID and ("id:" .. group.sourceID) or ("name:" .. tostring(group.sourceName))
        local tier = tierBySource[key]
        if not tier then
            tier = {sourceName=group.sourceName, rows={}}
            tierBySource[key] = tier; tierGroups[#tierGroups+1] = tier
        end
        tier.rows[#tier.rows+1] = {slot=slot, text=text, color=CFG.colors.text}
    end

    local card = NewCard(f, "Dungeon Runs", CFG.colors.blue)
    AddCardLine(card,
        "Other saved items are on the left. Tier-slot Targets and Catalyst dungeons are on the right.",
        CFG.colors.muted, 0, "GameFontDisableSmall", true)
    AddCardGap(card, 4)
    card.columnYStart = card.cursorY
    card.columnY = { card.cursorY, card.cursorY }

    AddColumnLine(card, 1, "Saved Target Dungeons", CFG.colors.gold, 0, "GameFontNormal")
    AddColumnLine(card, 1, "Run these for your saved items or higher-track copies.",
        CFG.colors.muted, 0, "GameFontDisableSmall", true)
    local targetAdded = false
    for _, group in ipairs(targetGroups) do
        local canShowAlternative = alternativeBudget.value > 0 and #(group.alternatives or {}) > 0
        if #(group.targets or {}) > 0 or canShowAlternative then
            local rows = {}
            for _, item in ipairs(group.targets or {}) do
                local slotName = item.slotInstance or item.slot or "Gear"
                local itemName = StripColorCodes(item.name or ("Item " .. tostring(item.itemID)))
                local suffix = TargetTrackSuffix(item, bagItems)
                local text = "•  " .. tostring(slotName) .. " - " .. itemName .. suffix
                if tierSlots[slotName] then
                    targetSlots[slotName] = true
                    AddTierRow(group, slotName, text)
                else
                    table.insert(rows, {text=text, color=CFG.colors.text})
                end
            end
            for _, item in ipairs(group.alternatives or {}) do
                if alternativeBudget.value > 0 then
                    local slotName = item.slotInstance or item.slot or "Gear"
                    local itemName = StripColorCodes(item.name or ("Item " .. tostring(item.itemID)))
                    table.insert(rows, {
                        text = "◇  " .. tostring(slotName) .. " - " .. itemName .. " (Alternative)",
                        color = CFG.colors.blue,
                    })
                    alternativeBudget.value = alternativeBudget.value - 1
                    alternativeBudget.shown = alternativeBudget.shown + 1
                end
            end
            if #rows > 0 then
                AddDungeonRunPanel(card, 1, group.sourceName,
                    tostring(#rows) .. (#rows == 1 and " ITEM" or " ITEMS"),
                    rows, CFG.colors.blue)
                targetAdded = true
            end
        end
    end
    if not targetAdded then
        AddColumnLine(card, 1, "No other saved dungeon items are currently needed.", CFG.colors.muted, 0, nil, true)
    end

    for _, group in ipairs(catalystGroups) do
        for _, item in ipairs(group.items or {}) do
            local slot = item.slotName or item.displaySlot
            if not targetSlots[slot] then
                AddTierRow(group, slot, "•  " .. tostring(item.displaySlot or slot or "Tier") .. " - Season 2 Tier Slot Needed")
            end
        end
    end
    table.sort(tierGroups, function(a,b) return tostring(a.sourceName) < tostring(b.sourceName) end)
    AddColumnLine(card, 2, "Tier Slot Targets & Catalyst", CFG.colors.violet, 0, "GameFontNormal")
    AddColumnLine(card, 2, "Your saved Tier-slot Targets, plus dungeon options for Tier slots without a Target.",
        CFG.colors.muted, 0, "GameFontDisableSmall", true)
    if #tierGroups == 0 then
        AddColumnLine(card, 2, "No Season 2 Tier-slot dungeon armor is currently needed.", CFG.colors.muted, 0, nil, true)
    else
        for _, group in ipairs(tierGroups) do
            local rows = group.rows
            table.sort(rows, function(a,b) return (SLOT_SORT[a.slot] or 99) < (SLOT_SORT[b.slot] or 99) end)
            AddDungeonRunPanel(card, 2, group.sourceName,
                tostring(#rows) .. (#rows == 1 and " TIER SLOT" or " TIER SLOTS"),
                rows, CFG.colors.violet, {0.045, 0.025, 0.074, 0.98})
        end
    end

    card.cursorY = math.min(card.columnY[1], card.columnY[2])
    if not card.columnDivider then
        card.columnDivider = card:CreateTexture(nil, "ARTWORK")
        card.columnDivider:SetTexture("Interface\\Buttons\\WHITE8x8")
    end
    card.columnDivider:ClearAllPoints()
    card.columnDivider:SetPoint("TOP", card, "TOP", 0, card.columnYStart or -78)
    card.columnDivider:SetPoint("BOTTOM", card, "TOP", 0, card.cursorY + 5)
    card.columnDivider:SetWidth(1)
    card.columnDivider:SetVertexColor(unpack(CFG.colors.border))
    card.columnDivider:Show()
    FinishCard(f, card)
end

local function GetShoppingPlan(filters)
    if not (KeyLab.GearingAnalysis and KeyLab.GearingAnalysis.GetGearShoppingPlan) then return nil end
    local ok, plan = pcall(KeyLab.GearingAnalysis.GetGearShoppingPlan, filters)
    return ok and type(plan) == "table" and plan or nil
end

local function GetNebulousRollPlan(filters)
    local shoppingPlan = GetShoppingPlan(filters)
    return shoppingPlan and shoppingPlan.nebulousRollPlan or nil
end

local function GetVoidcoreCount(shoppingPlan)
    return math.max(0, tonumber(shoppingPlan and shoppingPlan.nebulousRollPlan
        and shoppingPlan.nebulousRollPlan.currencyCount) or 0)
end

local function ToRollItem(item)
    return {
        slotName = item.slotInstance or item.slot or "Gear",
        displaySlot = item.slotInstance or item.slot or "Gear",
        itemName = StripColorCodes(item.name or item.itemName or ("Item " .. tostring(item.itemID))),
        itemID = tonumber(item.itemID),
    }
end

local function ItemHasSource(item, sourceID, specID)
    sourceID = tonumber(sourceID)
    if not item or not sourceID then return false end
    if tonumber(item.sourceID) == sourceID then return true end
    if item.sources and item.sources[sourceID] then return true end
    for _, candidateSourceID in ipairs(item.sourceIDs or {}) do
        if tonumber(candidateSourceID) == sourceID then return true end
    end

    local mapping = KeyLab.GearLootMapping
    if mapping and mapping.GetItemSources then
        for _, source in ipairs(mapping.GetItemSources(item.itemID, specID) or {}) do
            if tonumber(source.sourceID or source.mapID or source.instanceID) == sourceID then return true end
        end
    end
    return false
end

local function CountDungeonAndRaidTargets(targets)
    local count = 0
    for _, item in ipairs(targets or {}) do
        local info = GetTargetSource(item)
        if info.sourceType == "Dungeon" or info.sourceType == "Raid" then count = count + 1 end
    end
    return count
end

local function MatchesActivity(item, sourceID, encounterID, specID)
    local mapping = KeyLab.GearLootMapping
    if encounterID then
        return mapping and mapping.ItemHasEncounter and mapping.ItemHasEncounter(item, sourceID, encounterID) == true
    end
    return ItemHasSource(item, sourceID, specID)
end

local function BuildRollGroup(items, sourceID, sourceName, sourceType, encounterID)
    local rows = {}
    for _, item in ipairs(items or {}) do table.insert(rows, ToRollItem(item)) end
    if #rows == 0 then return {} end
    return {
        {
            sourceName = tostring(sourceName or "Current Activity"),
            sourceType = sourceType,
            sourceID = sourceID,
            encounterID = encounterID,
            items = rows,
        },
    }
end

local function GetActivityTargetPlan(sourceID, sourceName, sourceType, encounterID)
    sourceID = tonumber(sourceID)
    encounterID = tonumber(encounterID)
    local shoppingPlan = GetShoppingPlan()
    if not shoppingPlan then return nil end

    local targets, alternatives = {}, {}
    for _, item in ipairs(shoppingPlan.targets or {}) do
        if MatchesActivity(item, sourceID, encounterID, shoppingPlan.specID) then table.insert(targets, item) end
    end
    for _, item in ipairs(shoppingPlan.alternatives or {}) do
        if MatchesActivity(item, sourceID, encounterID, shoppingPlan.specID) then
            table.insert(alternatives, item)
        end
    end
    SortItems(targets)
    SortItems(alternatives)

    return {
        specID = shoppingPlan.specID,
        specName = shoppingPlan.specName,
        currencyCount = GetVoidcoreCount(shoppingPlan),
        allTargetCount = CountDungeonAndRaidTargets(shoppingPlan.targets),
        allAlternativeCount = CountDungeonAndRaidTargets(shoppingPlan.alternatives),
        itemCount = #targets,
        alternativeCount = #alternatives,
        targetGroups = BuildRollGroup(targets, sourceID, sourceName, sourceType, encounterID),
        alternativeGroups = BuildRollGroup(alternatives, sourceID, sourceName, sourceType, encounterID),
    }
end

local function GetGreatVaultTargetPlan()
    local shoppingPlan = GetShoppingPlan()
    if not shoppingPlan then return nil end

    local targetGroups, alternativeGroups = {}, {}
    for _, group in ipairs(BuildTargetGroups(shoppingPlan.targets, shoppingPlan.alternatives)) do
        if group.sourceType == "Dungeon" or group.sourceType == "Raid" then
            local targetItems, alternativeItems = {}, {}
            for _, item in ipairs(group.targets or {}) do table.insert(targetItems, ToRollItem(item)) end
            for _, item in ipairs(group.alternatives or {}) do table.insert(alternativeItems, ToRollItem(item)) end
            if #targetItems > 0 then
                table.insert(targetGroups, {
                    sourceID = group.sourceID,
                    sourceName = group.sourceName,
                    sourceType = group.sourceType,
                    items = targetItems,
                })
            end
            if #alternativeItems > 0 then
                table.insert(alternativeGroups, {
                    sourceID = group.sourceID,
                    sourceName = group.sourceName,
                    sourceType = group.sourceType,
                    items = alternativeItems,
                })
            end
        end
    end

    local itemCount = CountDungeonAndRaidTargets(shoppingPlan.targets)
    local alternativeCount = CountDungeonAndRaidTargets(shoppingPlan.alternatives)
    return {
        specID = shoppingPlan.specID,
        specName = shoppingPlan.specName,
        currencyCount = GetVoidcoreCount(shoppingPlan),
        allTargetCount = itemCount,
        allAlternativeCount = alternativeCount,
        itemCount = itemCount,
        alternativeCount = alternativeCount,
        targetGroups = targetGroups,
        alternativeGroups = alternativeGroups,
    }
end

local function AddNebulousRollCard(f, plan, compact)
    if not plan or (tonumber(plan.itemCount) or 0) == 0 then return false end
    local title = compact and "Roll for These Myth Items" or "Nebulous Voidcore Rolls"
    local card = NewCard(f, title, CFG.colors.violet)
    if compact then
        AddCardLine(card,
            "Use a Nebulous Voidcore here for a chance at these needed Myth-track slots.",
            CFG.colors.muted, 0, "GameFontDisableSmall", true)
    else
        AddCardLine(card,
            "Run these dungeons or raids, then use a Nebulous Voidcore to roll for a Myth-track item.",
            CFG.colors.muted, 0, "GameFontDisableSmall", true)
    end
    AddCardLine(card, "Nebulous Voidcores Available: " .. tostring(plan.currencyCount or 0), CFG.colors.green)
    AddCardGap(card, 4)

    card.columnY = { card.cursorY, card.cursorY }
    if compact and #(plan.groups or {}) == 1 then
        AddRollGroupPanel(card, 1, plan.groups[1], true)
    else
        local columns, weights = { {}, {} }, { 0, 0 }
        for _, group in ipairs(plan.groups or {}) do
            local column = weights[1] <= weights[2] and 1 or 2
            table.insert(columns[column], group)
            weights[column] = weights[column] + 3 + #(group.items or {})
        end
        for column = 1, 2 do
            for _, group in ipairs(columns[column]) do
                AddRollGroupPanel(card, column, group, false)
            end
        end
        card.cursorY = math.min(card.columnY[1], card.columnY[2])
    end
    FinishCard(f, card)
    return true
end

local function AddRollGroupsToCard(card, groups)
    if #(groups or {}) == 1 then
        AddRollGroupPanel(card, 1, groups[1], true)
        return
    end

    card.columnY = { card.cursorY, card.cursorY }
    local columns, weights = { {}, {} }, { 0, 0 }
    for _, group in ipairs(groups or {}) do
        local column = weights[1] <= weights[2] and 1 or 2
        table.insert(columns[column], group)
        weights[column] = weights[column] + 3 + #(group.items or {})
    end
    for column = 1, 2 do
        for _, group in ipairs(columns[column]) do AddRollGroupPanel(card, column, group, false) end
    end
    card.cursorY = math.min(card.columnY[1], card.columnY[2])
end

local function AddTargetRollCard(f, plan, title, description, accentColor)
    if not plan or (tonumber(plan.itemCount) or 0) == 0 then return false end
    local card = NewCard(f, title or "Your Saved Targets", accentColor or CFG.colors.gold)
    AddCardLine(card,
        description or "These are the still-needed items you marked as Targets for this specialization.",
        CFG.colors.muted, 0, "GameFontDisableSmall", true)
    AddCardLine(card, "Nebulous Voidcores Available: " .. tostring(plan.currencyCount or 0), CFG.colors.green)
    AddCardLine(card,
        "Targets Here: " .. tostring(plan.itemCount or 0)
            .. "  |  All Saved Dungeon and Raid Targets: "
            .. tostring(plan.allTargetCount or plan.itemCount or 0),
        CFG.colors.blue)
    AddCardGap(card, 4)
    AddRollGroupsToCard(card, plan.targetGroups)
    FinishCard(f, card)
    return true
end

local function AddAlternativeRollCard(f, plan, title, description)
    if not plan or (tonumber(plan.alternativeCount) or 0) == 0 then return false end
    local card = NewCard(f, title or "Your Alternatives", CFG.colors.blue)
    AddCardLine(card,
        description or "These are the still-needed backup choices you saved for this specialization.",
        CFG.colors.muted, 0, "GameFontDisableSmall", true)
    AddCardLine(card,
        "Alternatives Here: " .. tostring(plan.alternativeCount or 0)
            .. "  |  All Saved Dungeon and Raid Alternatives: "
            .. tostring(plan.allAlternativeCount or plan.alternativeCount or 0),
        CFG.colors.blue)
    AddCardGap(card, 4)
    AddRollGroupsToCard(card, plan.alternativeGroups)
    FinishCard(f, card)
    return true
end

local function CreateCloseButton(parent)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(28, 28)
    SetBackdrop(button, {0.20, 0.025, 0.025, 0.98}, CFG.colors.gold)
    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    label:SetPoint("CENTER", button, "CENTER", 0, 1)
    label:SetText("X")
    label:SetTextColor(1.0, 0.82, 0.16, 1.0)
    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.48, 0.035, 0.025, 1.0)
        self:SetBackdropBorderColor(1.0, 0.82, 0.16, 1.0)
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.20, 0.025, 0.025, 0.98)
        self:SetBackdropBorderColor(unpack(CFG.colors.gold))
    end)
    return button
end

local function GetShoppingWindowPosition()
    if KeyLab.DB and KeyLab.DB.GetSettingTable then
        return KeyLab.DB.GetSettingTable("gearShoppingWindowPosition")
    end
    KeyLabDB = type(KeyLabDB) == "table" and KeyLabDB or {}
    KeyLabDB.settings = type(KeyLabDB.settings) == "table" and KeyLabDB.settings or {}
    KeyLabDB.settings.gearShoppingWindowPosition =
        type(KeyLabDB.settings.gearShoppingWindowPosition) == "table"
            and KeyLabDB.settings.gearShoppingWindowPosition or {}
    return KeyLabDB.settings.gearShoppingWindowPosition
end

local function Clamp(value, minimum, maximum)
    value = tonumber(value) or minimum
    return math.max(minimum, math.min(maximum, value))
end

local function UpdateShoppingWindowLayout(f, width, height)
    width = tonumber(width) or f:GetWidth() or CFG.width
    height = tonumber(height) or f:GetHeight() or CFG.minHeight
    if f.backgroundArtwork then
        f.backgroundArtwork:SetTexCoord(
            0, math.min(1, width / 2048),
            0, math.min(1, height / 1024)
        )
    end
    if f.content then
        f.contentWidth = math.max(520, width - 100)
        f.content:SetWidth(f.contentWidth)
    end
end

local function ApplyShoppingWindowPosition(f)
    local position = GetShoppingWindowPosition()
    local x = position.userPlaced and tonumber(position.x) or 180
    local y = position.userPlaced and tonumber(position.y) or 0
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "CENTER", x, y)
    f.positionApplied = true
end

local function ApplyShoppingWindowGeometry(f)
    local position = GetShoppingWindowPosition()
    local width = position.userSized
        and Clamp(position.width, CFG.minWidth, CFG.maxWidth) or CFG.width
    local height = position.userSized
        and Clamp(position.height, CFG.minHeight, CFG.maxHeight) or CFG.minHeight
    f:SetSize(width, height)
    ApplyShoppingWindowPosition(f)
    UpdateShoppingWindowLayout(f, width, height)
end

local function SaveShoppingWindowPosition(f)
    f:StopMovingOrSizing()
    local centerX, centerY = f:GetCenter()
    local parentX, parentY = UIParent and UIParent:GetCenter()
    if not centerX or not centerY or not parentX or not parentY then return end

    local position = GetShoppingWindowPosition()
    position.userPlaced = true
    position.x = centerX - parentX
    position.y = centerY - parentY
    ApplyShoppingWindowPosition(f)
end

local function SaveShoppingWindowSize(f)
    f:StopMovingOrSizing()
    local centerX, centerY = f:GetCenter()
    local parentX, parentY = UIParent and UIParent:GetCenter()
    local position = GetShoppingWindowPosition()
    position.userSized = true
    position.width = Clamp(f:GetWidth(), CFG.minWidth, CFG.maxWidth)
    position.height = Clamp(f:GetHeight(), CFG.minHeight, CFG.maxHeight)
    if centerX and centerY and parentX and parentY then
        position.userPlaced = true
        position.x = centerX - parentX
        position.y = centerY - parentY
    end
    ApplyShoppingWindowGeometry(f)
    if GearWindow.Refresh then GearWindow.Refresh() end
end

local function EnsureFrame()
    if frame then return frame end

    frame = CreateFrame("Frame", "KeyLabGearTargetsWindow", UIParent, "BackdropTemplate")
    frame:SetSize(CFG.width, CFG.minHeight)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(1100)
    if frame.SetToplevel then frame:SetToplevel(true) end
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    if frame.SetResizeBounds then
        frame:SetResizeBounds(CFG.minWidth, CFG.minHeight, CFG.maxWidth, CFG.maxHeight)
    else
        if frame.SetMinResize then frame:SetMinResize(CFG.minWidth, CFG.minHeight) end
        if frame.SetMaxResize then frame:SetMaxResize(CFG.maxWidth, CFG.maxHeight) end
    end
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", SaveShoppingWindowPosition)
    frame:SetScript("OnSizeChanged", UpdateShoppingWindowLayout)
    SetBackdrop(frame, CFG.colors.bg, CFG.colors.gold)
    AddWindowArtwork(frame)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 50, -17)
    frame.title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -50, -17)
    frame.title:SetHeight(28)
    frame.title:SetJustifyH("CENTER")
    frame.title:SetText("KeyLab Gear Targets")
    frame.title:SetTextColor(unpack(CFG.colors.gold))

    frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.subtitle:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -1)
    frame.subtitle:SetPoint("TOPRIGHT", frame.title, "BOTTOMRIGHT", 0, -1)
    frame.subtitle:SetHeight(20)
    frame.subtitle:SetJustifyH("CENTER")
    frame.subtitle:SetText("Your saved gear plan while browsing dungeons and raids")
    frame.subtitle:SetTextColor(unpack(CFG.colors.muted))

    local close = CreateCloseButton(frame)
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -10)
    close:SetScript("OnClick", function()
        if KeyLab.LFGTooltips and KeyLab.LFGTooltips.DismissForCurrentSession then
            KeyLab.LFGTooltips.DismissForCurrentSession()
        end
        frame.manualOpen = false
        frame.autoOpen = false
        frame:Hide()
    end)

    frame.scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    frame.scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -70)
    frame.scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 12)
    frame.scroll:EnableMouseWheel(true)
    frame.scroll:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll() or 0
        local maximum = math.max(0, (frame.content:GetHeight() or 0) - (self:GetHeight() or 0))
        self:SetVerticalScroll(math.max(0, math.min(maximum, current - (delta * 48))))
    end)

    frame.content = CreateFrame("Frame", nil, frame.scroll)
    frame.contentWidth = CFG.width - 100
    frame.content:SetWidth(frame.contentWidth)
    frame.content:SetHeight(1)
    frame.scroll:SetScrollChild(frame.content)
    frame.lines = {}
    frame.cards = {}

    local resizeGrip = CreateFrame("Button", nil, frame)
    resizeGrip:SetSize(18, 18)
    resizeGrip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeGrip:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then frame:StartSizing("BOTTOMRIGHT") end
    end)
    resizeGrip:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then SaveShoppingWindowSize(frame) end
    end)
    frame.resizeGrip = resizeGrip

    ApplyShoppingWindowGeometry(frame)
    frame:Hide()
    return frame
end

local function EnsureCompletionFrame()
    if completionFrame then return completionFrame end

    local f = CreateFrame("Frame", "KeyLabNebulousRollReminder", UIParent, "BackdropTemplate")
    f:SetSize(650, 390)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(1200)
    if f.SetToplevel then f:SetToplevel(true) end
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    SetBackdrop(f, CFG.colors.bg, CFG.colors.gold)
    AddWindowArtwork(f)

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", f, "TOP", 0, -17)
    f.title:SetSize(560, 28)
    f.title:SetJustifyH("CENTER")
    f.title:SetText("Nebulous Voidcore Roll Reminder")
    f.title:SetTextColor(unpack(CFG.colors.gold))

    f.subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.subtitle:SetPoint("TOP", f.title, "BOTTOM", 0, -1)
    f.subtitle:SetSize(560, 34)
    f.subtitle:SetJustifyH("CENTER")
    f.subtitle:SetJustifyV("TOP")
    f.subtitle:SetWordWrap(true)
    f.subtitle:SetTextColor(unpack(CFG.colors.muted))

    local close = CreateCloseButton(f)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -10)
    close:SetScript("OnClick", function() f:Hide() end)

    f.scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    f.scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -82)
    f.scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -34, 16)
    f.scroll:EnableMouseWheel(true)
    f.scroll:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll() or 0
        local maximum = math.max(0, (f.content:GetHeight() or 0) - (self:GetHeight() or 0))
        self:SetVerticalScroll(math.max(0, math.min(maximum, current - (delta * 48))))
    end)

    f.content = CreateFrame("Frame", nil, f.scroll)
    f.contentWidth = 550
    f.content:SetSize(f.contentWidth, 1)
    f.scroll:SetScrollChild(f.content)
    f.cards = {}
    f:Hide()
    completionFrame = f
    return f
end

local function ShowCompletionPlan(plan, title, subtitle, cardTitle, description, isRaid)
    if not plan or ((tonumber(plan.itemCount) or 0) == 0 and (tonumber(plan.alternativeCount) or 0) == 0) then
        return false
    end
    local f = EnsureCompletionFrame()
    ResetCards(f)
    f.raidReminder = isRaid == true
    f.title:SetText(title or "Nebulous Voidcore Roll Reminder")
    f.subtitle:SetText(subtitle or "This activity is complete. Check your saved Myth-item roll list.")
    AddTargetRollCard(f, plan, cardTitle, description, isRaid and CFG.colors.gold or CFG.colors.violet)
    AddAlternativeRollCard(f, plan,
        isRaid and "Your Alternatives from This Boss" or "Your Alternatives from This Dungeon",
        isRaid and "These are the still-needed backup choices you saved from this boss."
            or "These are the still-needed backup choices you saved from this dungeon.")

    if isRaid and (tonumber(plan.itemCount) or 0) == 0 then
        local balance = NewCard(f, "Nebulous Voidcore Rolls", CFG.colors.violet)
        AddCardLine(balance, "Nebulous Voidcores Available: " .. tostring(plan.currencyCount or 0), CFG.colors.green)
        FinishCard(f, balance)
    end

    local note = NewCard(f, "Before You Roll", CFG.colors.blue)
    AddCardLine(note,
        "This reminder only lists your saved Targets and Alternatives. It does not guarantee roll eligibility or press, move, or use any Blizzard loot controls.",
        CFG.colors.muted, 0, "GameFontDisableSmall", true)
    FinishCard(f, note)

    local contentHeight = math.max(1, math.abs(f.contentY or 0))
    f.content:SetHeight(contentHeight)
    f.scroll:SetVerticalScroll(0)
    local screenHeight = UIParent and UIParent.GetHeight and UIParent:GetHeight() or 760
    local maximumHeight = math.min(680, math.max(390, screenHeight - 80))
    f:SetHeight(math.max(390, math.min(maximumHeight, 108 + contentHeight)))
    f:Show()
    if f.Raise then f:Raise() end
    return true
end


local function ShowGreatVaultTargets(plan)
    if not plan or ((tonumber(plan.itemCount) or 0) == 0
        and (tonumber(plan.alternativeCount) or 0) == 0
        and (tonumber(plan.currencyCount) or 0) == 0) then
        return false
    end
    local f = EnsureCompletionFrame()
    ResetCards(f)
    f.raidReminder = false
    f.title:SetText("Great Vault Target Reminder")
    f.subtitle:SetText("Review your Voidcore balance and saved Dungeon and Raid Targets and Alternatives before making a broader roll.")

    if (tonumber(plan.itemCount) or 0) > 0 then
        AddTargetRollCard(f, plan, "Your Saved Dungeon and Raid Targets",
            "These are all still-needed Dungeon and Raid Targets for your current specialization.", CFG.colors.violet)
    end
    if (tonumber(plan.alternativeCount) or 0) > 0 then
        AddAlternativeRollCard(f, plan, "Your Saved Dungeon and Raid Alternatives",
            "These are all still-needed backup choices saved for your current specialization.")
    end
    if (tonumber(plan.itemCount) or 0) == 0 and (tonumber(plan.alternativeCount) or 0) == 0 then
        local balance = NewCard(f, "Nebulous Voidcores", CFG.colors.violet)
        AddCardLine(balance, "Nebulous Voidcores Available: " .. tostring(plan.currencyCount or 0), CFG.colors.green)
        AddCardLine(balance, "You do not currently have any saved Dungeon or Raid Targets or Alternatives for this specialization.",
            CFG.colors.muted, 0, "GameFontDisableSmall", true)
        FinishCard(f, balance)
    end

    local note = NewCard(f, "Great Vault Rolls", CFG.colors.blue)
    AddCardLine(note,
        "A Great Vault Voidcore roll is broader than one completed boss or dungeon. This list is a planning reminder, not a promise that a specific item can appear.",
        CFG.colors.muted, 0, "GameFontDisableSmall", true)
    FinishCard(f, note)

    local contentHeight = math.max(1, math.abs(f.contentY or 0))
    f.content:SetHeight(contentHeight)
    f.scroll:SetVerticalScroll(0)
    local screenHeight = UIParent and UIParent.GetHeight and UIParent:GetHeight() or 760
    local maximumHeight = math.min(680, math.max(390, screenHeight - 80))
    f:SetHeight(math.max(390, math.min(maximumHeight, 108 + contentHeight)))
    f:Show()
    if f.Raise then f:Raise() end
    return true
end

function GearWindow.Refresh()
    local f = EnsureFrame()
    local previousScroll = f.scroll and (f.scroll:GetVerticalScroll() or 0) or 0
    f.currentResultNames = nil
    ResetCards(f)

    local shoppingPlan = GetShoppingPlan() or {}
    local targets = shoppingPlan.targets or {}
    local alternatives = shoppingPlan.alternatives or {}
    local bagItems = shoppingPlan.bagItems or {}
    local groups = BuildTargetGroups(targets, alternatives)
    local alternativeBudget = { value = CFG.maxAlternativesShown, shown = 0 }

    local intro = NewCard(f, "Saved Gear Shopping List", CFG.colors.gold)
    AddCardLine(intro,
        "Still-needed Targets and saved Alternatives, grouped by where they drop.",
        CFG.colors.muted, 0, "GameFontDisableSmall")
    FinishCard(f, intro)

    if #targets == 0 and #alternatives == 0 then
        local empty = NewCard(f, "Saved Targets", CFG.colors.blue)
        AddCardLine(empty, "No gear is currently needed from your saved plan.", CFG.colors.muted)
        AddCardLine(empty, "Open Gear Targets to choose items you want to track.", CFG.colors.text)
        FinishCard(f, empty)
    else
        AddDungeonRunCard(f, FilterGroups(groups, "Dungeon"),
            shoppingPlan.catalystDungeonGroups, bagItems, alternativeBudget)
        AddSavedGearCard(f, "Raid Gear", FilterGroups(groups, "Raid"), bagItems, alternativeBudget)
        AddSavedGearCard(f, "Other Saved Gear", FilterGroups(groups, "Other"), bagItems, alternativeBudget)
    end

    if #targets == 0 and #alternatives == 0 then
        AddDungeonRunCard(f, {}, shoppingPlan.catalystDungeonGroups, bagItems, alternativeBudget)
    end

    AddNebulousRollCard(f, shoppingPlan.nebulousRollPlan, false)

    local summary = NewCard(f, "Plan Summary", CFG.colors.border)
    AddCardLine(summary, "Targets Still Needed: " .. tostring(#targets)
        .. "  |  Alternatives Shown: " .. tostring(alternativeBudget.shown)
        .. " of " .. tostring(#alternatives), CFG.colors.muted)
    local hiddenAlternatives = #alternatives - alternativeBudget.shown
    if hiddenAlternatives > 0 then
        AddCardLine(summary, "+ " .. tostring(hiddenAlternatives) .. " more Alternative"
            .. (hiddenAlternatives == 1 and "" or "s") .. " saved in Gear Targets.", CFG.colors.muted)
    end
    AddCardLine(summary,
        "Equipped Hero Targets with a Nebulous roll move to the roll list. Equipped Myth Targets stay saved and remain hidden.",
        CFG.colors.muted, 0, "GameFontDisableSmall", true)
    FinishCard(f, summary)

    local contentHeight = math.max(1, math.abs(f.contentY or 0))
    f.content:SetHeight(contentHeight)
    local screenHeight = UIParent and UIParent.GetHeight and UIParent:GetHeight() or CFG.maxHeight + 80
    local maximumHeight = math.min(CFG.maxHeight, math.max(CFG.minHeight, screenHeight - 80))
    local neededHeight = 94 + contentHeight
    local position = GetShoppingWindowPosition()
    if not position.userSized then
        f:SetHeight(math.max(CFG.minHeight, math.min(maximumHeight, neededHeight)))
    end
    local maximumScroll = math.max(0, contentHeight - (f.scroll:GetHeight() or 0))
    f.scroll:SetVerticalScroll(math.min(previousScroll, maximumScroll))
    f.lastShoppingRefreshAt = GetTime and GetTime() or 0
end

function GearWindow.AnchorDefaultForLFG()
    local f = EnsureFrame()
    if not f.positionApplied then ApplyShoppingWindowGeometry(f) end
end

function GearWindow.ShowManual()
    local f = EnsureFrame()
    if not f.positionApplied then ApplyShoppingWindowGeometry(f) end
    f.manualOpen = true
    GearWindow.Refresh()
    f:Show()
end

function GearWindow.ToggleManual()
    local f = EnsureFrame()
    if f:IsShown() and f.manualOpen then
        f.manualOpen = false
        f.autoOpen = false
        f:Hide()
    else
        GearWindow.ShowManual()
    end
end

function GearWindow.ShowForLFG()
    local f = EnsureFrame()
    local now = GetTime and GetTime() or 0
    local needsRefresh = not f:IsShown()
        or not f.autoOpen
        or now == 0
        or now - (tonumber(f.lastShoppingRefreshAt) or 0) >= 1
    f.autoOpen = true
    f.currentResultNames = nil
    if not f.positionApplied then ApplyShoppingWindowGeometry(f) end
    if needsRefresh then GearWindow.Refresh() end
    f:Show()
end

function GearWindow.HideAuto()
    local f = EnsureFrame()
    f.autoOpen = false
    f.currentResultNames = nil
    if not f.manualOpen then
        f:Hide()
    else
        GearWindow.Refresh()
    end
end

function GearWindow.RefreshVisible()
    local f = EnsureFrame()
    if f:IsShown() then GearWindow.Refresh() end
end

function GearWindow.ShowCompletionForDungeon(mapID, dungeonName)
    mapID = tonumber(mapID)
    if not mapID then return false end
    local source = KeyLab.GearLootMapping and KeyLab.GearLootMapping.GetSource
        and KeyLab.GearLootMapping.GetSource(mapID) or nil
    local name = dungeonName or source and (source.sourceName or source.name) or "Mythic+ dungeon"
    return ShowCompletionPlan(
        GetActivityTargetPlan(mapID, name, "Dungeon"),
        "Dungeon Target and Alternative Reminder",
        tostring(name) .. " is complete. Check your saved Targets and Alternatives and use any available Voidcore roll before you leave.",
        "Your Targets from This Dungeon",
        "These are the still-needed items you marked as Targets from this dungeon."
    )
end

local pendingRaidCompletion
local lastRaidCompletionID

local function FlushRaidCompletion()
    local pending = pendingRaidCompletion
    if not pending then return false end
    if InCombatLockdown and InCombatLockdown() then return false end

    -- Discard reminders after leaving this raid/difficulty. No loot lookup or
    -- equipment scan runs until the player is out of combat and still inside.
    local name, instanceType, difficultyID, _, _, _, _, mapID
    if GetInstanceInfo then
        name, instanceType, difficultyID, _, _, _, _, mapID = GetInstanceInfo()
    end
    local raids = KeyLab.Mapping and KeyLab.Mapping.Raids
    local sameRaid = tonumber(mapID) ~= nil and tonumber(mapID) == pending.instanceMapID
    if not sameRaid and raids and raids.GetInstanceByName then
        local instance = raids.GetInstanceByName(name)
        sameRaid = instance and instance.instanceID == pending.instanceID
    end
    pendingRaidCompletion = nil
    if instanceType ~= "raid" or not sameRaid
        or tonumber(difficultyID) ~= pending.difficultyID then return false end

    local lootEncounterID = raids and raids.GetLootEncounterByName
        and raids.GetLootEncounterByName(pending.instanceID, pending.encounterName)
    -- Never fall back to all raid loot or assume the runtime ID is a loot ID.
    if not lootEncounterID then return false end
    return ShowCompletionPlan(
        GetActivityTargetPlan(pending.instanceID, pending.encounterName, "Raid", lootEncounterID),
        "Raid Target and Alternative Reminder",
        pending.encounterName .. " is defeated. Check your saved Targets and Alternatives before you leave.",
        "Your Targets from This Boss",
        "These are the still-needed items you marked as Targets from this boss.",
        true
    )
end

function GearWindow.NotifyRaidEncounterSaved(encounter)
    local raid = type(encounter) == "table" and encounter.raid
    if not raid or encounter.contentType ~= "raid" or raid.killed ~= true
        or not encounter.id or encounter.id == lastRaidCompletionID then return false end
    if type(raid.encounterName) ~= "string" then return false end
    lastRaidCompletionID = encounter.id
    pendingRaidCompletion = {
        instanceID = tonumber(raid.instanceID),
        instanceMapID = tonumber(raid.instanceMapID),
        difficultyID = tonumber(raid.difficultyID),
        encounterName = raid.encounterName,
    }
    return FlushRaidCompletion()
end

function GearWindow.ShowForGreatVault()
    return ShowGreatVaultTargets(GetGreatVaultTargetPlan())
end

local activeChallengeMapID
local function ReadActiveChallengeMapID()
    if not (C_ChallengeMode and C_ChallengeMode.GetActiveChallengeMapID) then return nil end
    local ok, mapID = pcall(C_ChallengeMode.GetActiveChallengeMapID)
    return ok and tonumber(mapID) or nil
end

-- Build the reminder while the addon loads so a boss kill never needs to
-- create its buttons or frames during combat lockdown.
EnsureCompletionFrame()

local completionEvents = CreateFrame("Frame")
local vaultHooked = false
local function HookGreatVault()
    if vaultHooked then return end
    local vault = WeeklyRewardsFrame
    if not (vault and vault.HookScript) then return end
    vault:HookScript("OnShow", function() GearWindow.ShowForGreatVault() end)
    vaultHooked = true
    completionEvents:UnregisterEvent("ADDON_LOADED")
    if vault:IsShown() then GearWindow.ShowForGreatVault() end
end

completionEvents:RegisterEvent("CHALLENGE_MODE_START")
completionEvents:RegisterEvent("CHALLENGE_MODE_COMPLETED")
completionEvents:RegisterEvent("CHALLENGE_MODE_RESET")
completionEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
completionEvents:RegisterEvent("PLAYER_REGEN_DISABLED")
completionEvents:RegisterEvent("ZONE_CHANGED_NEW_AREA")
-- The Great Vault is load-on-demand and has no WEEKLY_REWARDS_SHOW event.
completionEvents:RegisterEvent("ADDON_LOADED")
completionEvents:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        HookGreatVault()
        return
    end
    if event == "CHALLENGE_MODE_START" then
        activeChallengeMapID = ReadActiveChallengeMapID()
        return
    end
    if event == "CHALLENGE_MODE_RESET" then
        activeChallengeMapID = nil
        return
    end
    if event == "CHALLENGE_MODE_COMPLETED" then
        local mapID = activeChallengeMapID or ReadActiveChallengeMapID()
        activeChallengeMapID = nil
        if mapID then GearWindow.ShowCompletionForDungeon(mapID) end
        return
    end
    if event == "PLAYER_REGEN_ENABLED" or event == "ZONE_CHANGED_NEW_AREA" then
        FlushRaidCompletion()
        return
    end
    if event == "PLAYER_REGEN_DISABLED" then
        if completionFrame and completionFrame.raidReminder then completionFrame:Hide() end
        return
    end
end)
HookGreatVault()

return GearWindow
