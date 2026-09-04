-- KeyLab_GroupDashboard.lua
-- Themed Group Readiness and Group Composition views.

local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Tabs = KeyLab.Tabs or {}
local Dashboard = KeyLab.Tabs.GroupDashboard or {}
KeyLab.Tabs.GroupDashboard = Dashboard

local Theme = KeyLab.UI and KeyLab.UI.Theme or {}
local Colors = Theme.colors or {}
local Analysis = KeyLab.GroupDashboardAnalysis or {}
local UtilityDB = KeyLab.GroupUtilityDB or {}
local function SequencerLibrary() return KeyLab.SequencerLibrary or {} end
local function IsCurrentlyGrouped()
    if IsInGroup then
        return (IsInRaid and IsInRaid()) or IsInGroup()
    end
    return Analysis.IsInGroup and Analysis.IsInGroup()
end

local VIEW_TOP = -122
local OUTER_X = 18
local OUTER_RIGHT = 18
local ROW_HEIGHT = 70
local ROW_GAP = 6
local DEPENDENCY_ORDER = { "class_spec", "talent", "pet", "talent_pet" }
local DEPENDENCY_SHORT = {
    class_spec = "C/S",
    talent = "Tal",
    pet = "Pet",
    talent_pet = "T+P",
}
local DEPENDENCY_WIDTHS = { class_spec = 25, talent = 24, pet = 21, talent_pet = 28 }
local CAPABILITY_LABEL_WIDTH = 98
local DEPENDENCY_START_X = 104
local DEPENDENCY_LABEL = {}
for _, dependency in ipairs(UtilityDB.dependencies or {}) do
    DEPENDENCY_LABEL[dependency.id] = dependency.label
end

local function Text(parent, value, size, color, justify)
    return Theme.CreateText(parent, value or "", "GameFontHighlightSmall", size or 11, color or Colors.text, justify or "LEFT")
end

local function ApplyColor(region, color)
    if Theme.ApplyColor then Theme.ApplyColor(region, color) end
end

local function SetTooltip(frame, title, bodyBuilder)
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(title or "Group Dashboard", 0.82, 0.76, 0.58)
        if type(bodyBuilder) == "function" then bodyBuilder(GameTooltip, self) end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
end

local function FormatItemLevel(member)
    local value = tonumber(member and member.itemLevel)
    if value and value > 0 then
        if math.abs(value - math.floor(value + 0.5)) < 0.05 then return tostring(math.floor(value + 0.5)) end
        return string.format("%.1f", value)
    end
    return member and member.itemLevelState or "Unavailable"
end

local function SpecText(member)
    if member and member.specName then return member.specName end
    return member and member.specState or "Unavailable"
end

local function ClassSpecText(member)
    return tostring(member and member.className or "Unknown") .. " - " .. tostring(SpecText(member))
end

local function BuildRosterFirstLine(member)
    local labels = {}
    labels[#labels + 1] = (member.name or "Unknown") .. (member.isPlayer and " (You)" or "")
    labels[#labels + 1] = ClassSpecText(member)
    labels[#labels + 1] = "iLvl " .. FormatItemLevel(member)
    labels[#labels + 1] = member.roleLabel or "No Role"
    if member.isLeader then labels[#labels + 1] = "Leader" end
    if member.isAssistant then labels[#labels + 1] = "Assistant" end
    return table.concat(labels, "  •  ")
end

local function BuildAuraLine(member)
    local stateName = member and member.auraState or "Unchecked"
    if stateName == "Unchecked" then return "Status: Unchecked — press Check Group Status when the group is assembled." end
    if stateName == "Checking" then return "Status: Checking…" end
    if stateName ~= "Checked" then return "Status: " .. tostring(member.auraMessage or stateName or "Unavailable") end
    return ""
end

local function GetAuraTexture(aura)
    if aura and aura.icon then return aura.icon end
    local spellID = aura and (aura.spellID or (aura.spellIDs and aura.spellIDs[1]))
    if not spellID then return 134400 end
    if C_Spell and type(C_Spell.GetSpellTexture) == "function" then
        local ok, texture = pcall(C_Spell.GetSpellTexture, spellID)
        if ok and texture then return texture end
    end
    if type(GetSpellTexture) == "function" then
        local ok, texture = pcall(GetSpellTexture, spellID)
        if ok and texture then return texture end
    end
    return 134400
end

local function CreateAuraChip(parent)
    local chip = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    chip:SetSize(30, 30)
    Theme.StylePanel(chip, Colors.icon, Colors.green, 1)

    chip.icon = chip:CreateTexture(nil, "ARTWORK")
    chip.icon:SetPoint("TOPLEFT", chip, "TOPLEFT", 2, -2)
    chip.icon:SetPoint("BOTTOMRIGHT", chip, "BOTTOMRIGHT", -2, 2)
    chip.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    chip.stack = Text(chip, "", 9, Colors.text, "RIGHT")
    chip.stack:SetPoint("BOTTOMRIGHT", chip, "BOTTOMRIGHT", -3, 2)
    chip.stack:SetSize(15, 12)

    chip:EnableMouse(true)
    chip:SetScript("OnEnter", function(self)
        if not GameTooltip or not self.aura then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local shown = false
        if self.aura.inventorySlot and type(GameTooltip.SetInventoryItem) == "function" then
            shown = pcall(GameTooltip.SetInventoryItem, GameTooltip, self.aura.tooltipUnit or "player", self.aura.inventorySlot)
        elseif self.aura.spellID and type(GameTooltip.SetSpellByID) == "function" then
            shown = pcall(GameTooltip.SetSpellByID, GameTooltip, self.aura.spellID)
        end
        if not shown then GameTooltip:AddLine(self.aura.name or "Active Aura", 0.94, 0.96, 0.99) end
        if (self.aura.applications or 0) > 1 then
            GameTooltip:AddLine("Stacks: " .. tostring(self.aura.applications), 0.68, 0.73, 0.82)
        end
        GameTooltip:Show()
    end)
    chip:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    return chip
end

local function RefreshAuraChips(row, member)
    local checked = member and member.auraState == "Checked" and type(member.presentAuras) == "table"
    row.secondLine:SetShown(not checked)
    local displayed = 0
    if checked then
        for auraIndex, aura in ipairs(member.presentAuras) do
            if auraIndex > 24 then break end
            local chip = row.auraChips[auraIndex]
            if not chip then
                chip = CreateAuraChip(row)
                row.auraChips[auraIndex] = chip
            end
            displayed = auraIndex
            chip.aura = aura
            chip.icon:SetTexture(GetAuraTexture(aura))
            chip.stack:SetText((aura.applications or 0) > 1 and tostring(aura.applications) or "")
            chip:ClearAllPoints()
            chip:SetPoint("TOPLEFT", row, "TOPLEFT", 14 + ((auraIndex - 1) * 36), -36)
            chip:Show()
        end
    end
    for auraIndex = displayed + 1, #row.auraChips do row.auraChips[auraIndex]:Hide() end
end

local function CreateRosterRow(parent, index)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * (ROW_HEIGHT + ROW_GAP)))
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -((index - 1) * (ROW_HEIGHT + ROW_GAP)))
    row:SetHeight(ROW_HEIGHT)
    Theme.StylePanel(row, index % 2 == 0 and Colors.analysisRowBg or Colors.cardBg, Colors.softBorder, 1)
    row.accent = Theme.AddAccent(row, Colors.blue, 3)

    row.firstLine = Text(row, "", 12, Colors.text)
    row.firstLine:SetPoint("TOPLEFT", row, "TOPLEFT", 14, -10)
    row.firstLine:SetPoint("TOPRIGHT", row, "TOPRIGHT", -12, -10)
    row.firstLine:SetHeight(19)
    row.firstLine:SetWordWrap(false)

    row.secondLine = Text(row, "", 10, Colors.muted)
    row.secondLine:SetPoint("TOPLEFT", row.firstLine, "BOTTOMLEFT", 0, -7)
    row.secondLine:SetPoint("TOPRIGHT", row.firstLine, "BOTTOMRIGHT", 0, -7)
    row.secondLine:SetHeight(30)
    row.secondLine:SetWordWrap(true)

    row.auraChips = {}

    SetTooltip(row, "Group Member", function(tooltip, self)
        local member = self.member
        if not member then return end
        tooltip:AddLine(member.fullName or member.name or "Unknown", 0.94, 0.96, 0.99)
        tooltip:AddLine(ClassSpecText(member), 0.68, 0.73, 0.82)
        tooltip:AddLine("Item level: " .. FormatItemLevel(member), 0.68, 0.73, 0.82)
        tooltip:AddLine("Role: " .. tostring(member.roleLabel or "No Role"), 0.68, 0.73, 0.82)
        if member.isLeader then tooltip:AddLine("Group Leader", 0.82, 0.76, 0.58) end
        if member.isAssistant then tooltip:AddLine("Group Assistant", 0.50, 0.68, 0.94) end
    end)
    return row
end

function Dashboard:BuildReadiness(parent)
    local view = CreateFrame("Frame", nil, parent)
    view:SetAllPoints(parent)
    self.readinessView = view

    self.checkButton = Theme.CreateButton(view, "Check Group Status", 172, 30)
    self.checkButton:SetPoint("TOPLEFT", view, "TOPLEFT", 0, 0)
    if Theme.StylePrimaryActionButton then Theme.StylePrimaryActionButton(self.checkButton) end
    self.checkButton:SetScript("OnClick", function()
        if Analysis.StartAuraCheck then Analysis.StartAuraCheck() end
    end)

    self.stopButton = Theme.CreateButton(view, "Stop", 76, 30)
    self.stopButton:SetPoint("LEFT", self.checkButton, "RIGHT", 8, 0)
    self.stopButton:SetScript("OnClick", function()
        if Analysis.StopAuraCheck then Analysis.StopAuraCheck() end
    end)

    self.readinessProgress = Text(view, "Join or form a group to check status.", 11, Colors.muted)
    self.readinessProgress:SetPoint("TOPLEFT", self.stopButton, "TOPRIGHT", 14, 0)
    self.readinessProgress:SetPoint("TOPRIGHT", view, "TOPRIGHT", 0, 0)
    self.readinessProgress:SetHeight(30)
    self.readinessProgress:SetJustifyV("MIDDLE")

    self.readinessRule = Theme.CreateRule(view, "TOP", Colors.divider, 1)
    self.readinessRule:ClearAllPoints()
    self.readinessRule:SetPoint("TOPLEFT", view, "TOPLEFT", 0, -42)
    self.readinessRule:SetPoint("TOPRIGHT", view, "TOPRIGHT", 0, -42)
    self.readinessRule:SetHeight(1)

    self.readinessSolo = Text(view, "Form or join a party or raid and the current roster will appear here.", 13, Colors.muted, "CENTER")
    self.readinessSolo:SetPoint("TOPLEFT", view, "TOPLEFT", 40, -100)
    self.readinessSolo:SetPoint("TOPRIGHT", view, "TOPRIGHT", -40, -100)
    self.readinessSolo:SetHeight(50)

    self.rosterScroll = Theme.CreateScrollArea(view, { step = ROW_HEIGHT + ROW_GAP })
    self.rosterScroll:SetPoint("TOPLEFT", view, "TOPLEFT", 0, -54)
    self.rosterScroll:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", 0, 0)
    self.rosterRows = {}
end

local function DependencyCellText(count, choices)
    count = tonumber(count) or 0
    choices = tonumber(choices) or 0
    return tostring(count + choices)
end

local function AddProviderLines(tooltip, providers, limit)
    providers = providers or {}
    limit = limit or 14
    if #providers == 0 then
        tooltip:AddLine("No current providers.", 0.68, 0.73, 0.82)
        return
    end
    tooltip:AddLine(" ")
    tooltip:AddLine("Current capabilities", 0.50, 0.68, 0.94)
    for index, provider in ipairs(providers) do
        if index > limit then
            tooltip:AddLine("+" .. tostring(#providers - limit) .. " more", 0.68, 0.73, 0.82)
            break
        end
        local choice = provider.choice and " • Choice" or ""
        local classSpec = tostring(provider.className or "Unknown")
        if provider.specName and provider.specName ~= "" then
            classSpec = classSpec .. " — " .. tostring(provider.specName)
        end
        tooltip:AddLine(
            tostring(provider.name or "Unknown") .. " • " .. classSpec .. " • " .. tostring(provider.ability or "Ability")
                .. " • " .. tostring(provider.dependencyLabel or provider.dependency or "") .. choice,
            0.94, 0.96, 0.99
        )
        if provider.availability and provider.availability ~= "" then
            tooltip:AddLine("  " .. provider.availability, 0.68, 0.73, 0.82, true)
        end
    end
end

local function AddNamedCapabilityLines(tooltip, effectID)
    local capabilities = {}
    local seen = {}
    for _, record in ipairs(UtilityDB.records or {}) do
        if record.namedEffect == effectID then
            local specs = record.specs or {}
            local classSpec = record.className or record.classFile or "Unknown"
            if #specs > 0 and not (#specs == 1 and specs[1] == "All") then
                classSpec = classSpec .. " (" .. table.concat(specs, ", ") .. ")"
            end
            local dependency = record.choiceKey and "Talent Choice"
                or DEPENDENCY_LABEL[record.dependency] or record.dependency or "Unspecified"
            local line = tostring(record.ability or "Ability") .. " — " .. classSpec .. " — " .. dependency
            if not seen[line] then
                seen[line] = true
                capabilities[#capabilities + 1] = line
            end
        end
    end
    if #capabilities == 0 then return end
    tooltip:AddLine(" ")
    tooltip:AddLine("Capable providers", 0.50, 0.68, 0.94)
    for _, line in ipairs(capabilities) do
        tooltip:AddLine(line, 0.94, 0.96, 0.99, true)
    end
end

local function CreateCategoryRow(parent, definition, y, isNamed)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, y)
    row:SetHeight(32)
    Theme.StylePanel(row, Colors.analysisRowBg, Colors.transparent, 0)
    row.activeCardState = false
    row.definition = definition
    row.isNamed = isNamed == true

    row.labelBackground = CreateFrame("Frame", nil, row, "BackdropTemplate")
    row.labelBackground:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.labelBackground:SetSize(CAPABILITY_LABEL_WIDTH, 28)
    Theme.StylePanel(row.labelBackground, Colors.transparent, Colors.transparent, 0)

    row.label = Text(row.labelBackground, definition.label, 10, Colors.text)
    row.label:SetPoint("LEFT", row.labelBackground, "LEFT", 2, 0)
    row.label:SetSize(CAPABILITY_LABEL_WIDTH - 4, 28)
    row.label:SetJustifyV("MIDDLE")
    row.label:SetWordWrap(true)

    row.cells = {}
    local x = DEPENDENCY_START_X
    for _, dependency in ipairs(DEPENDENCY_ORDER) do
        local cell = CreateFrame("Frame", nil, row)
        cell:SetSize(DEPENDENCY_WIDTHS[dependency] - 2, 24)
        cell:SetPoint("LEFT", row, "LEFT", x, 0)
        cell.zero = Text(cell, "0", 10, Colors.muted, "CENTER")
        cell.zero:SetAllPoints(cell)
        cell.zero:SetJustifyH("CENTER")
        cell.zero:SetJustifyV("MIDDLE")
        cell.badge = Theme.CreateBadge(cell, "", DEPENDENCY_WIDTHS[dependency] - 2, 21, Colors.green, Colors.green)
        cell.badge:SetPoint("CENTER", cell, "CENTER", 0, 0)
        cell.badge:Hide()
        row.cells[dependency] = cell
        x = x + DEPENDENCY_WIDTHS[dependency]
    end

    SetTooltip(row, definition.label, function(tooltip, self)
        tooltip:AddLine(self.definition.definition or "", 0.94, 0.96, 0.99, true)
        if self.isNamed then
            AddNamedCapabilityLines(tooltip, self.definition.id)
            local providerCount = self.data and self.data.providerCount or 0
            tooltip:AddLine("Status: " .. (providerCount > 0 and "Covered" or "Not Covered"), providerCount > 0 and 0.46 or 0.68, providerCount > 0 and 0.78 or 0.73, providerCount > 0 and 0.50 or 0.82)
        end
        tooltip:AddLine("Green Class/Spec coverage is inherent. Yellow Talent, Pet, and Talent + Pet coverage is conditional.", 0.68, 0.73, 0.82, true)
        AddProviderLines(tooltip, self.data and self.data.providers or {}, 16)
    end)
    return row
end

local function CreateColumnCard(parent, title, sections, x, width, height, isNamed)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", x, 0)
    card:SetSize(width, height)
    Theme.StylePanel(card, Colors.cardBg, Colors.cardBorder, 1)
    Theme.CreateRule(card, "TOP", Colors.goldDim, 2)

    card.title = Text(card, title, 15, Colors.gold)
    card.title:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -10)
    card.title:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -10)
    card.title:SetHeight(18)

    local y = -36
    card.rows = {}
    for _, section in ipairs(sections) do
        local sectionLabel = Text(card, string.upper(section.label), 10, Colors.blue)
        sectionLabel:SetPoint("TOPLEFT", card, "TOPLEFT", 12, y)
        sectionLabel:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, y)
        sectionLabel:SetHeight(14)
        y = y - 17

        local header = CreateFrame("Frame", nil, card)
        header:SetPoint("TOPLEFT", card, "TOPLEFT", 8, y)
        header:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, y)
        header:SetHeight(17)
        local labelHeader = Text(header, "CAPABILITY", 9, Colors.muted)
        labelHeader:SetPoint("LEFT", header, "LEFT", 6, 0)
        labelHeader:SetSize(CAPABILITY_LABEL_WIDTH, 16)
        local headerX = DEPENDENCY_START_X
        for _, dependency in ipairs(DEPENDENCY_ORDER) do
            local cell = Text(header, DEPENDENCY_SHORT[dependency], 9, Colors.muted, "CENTER")
            cell:SetPoint("LEFT", header, "LEFT", headerX, 0)
            cell:SetSize(DEPENDENCY_WIDTHS[dependency] - 3, 16)
            cell:SetJustifyH("CENTER")
            headerX = headerX + DEPENDENCY_WIDTHS[dependency]
        end
        y = y - 18

        for _, definition in ipairs(section.definitions) do
            local row = CreateCategoryRow(card, definition, y, isNamed)
            card.rows[definition.id] = row
            y = y - 34
        end
        y = y - 5
    end
    return card
end

local function DefinitionsForGroups(groups)
    local result = {}
    for _, group in ipairs(groups) do
        local definitions = {}
        for _, definition in ipairs(UtilityDB.categories or {}) do
            if definition.group == group then table.insert(definitions, definition) end
        end
        result[#result + 1] = { label = group, definitions = definitions }
    end
    return result
end

local function DefinitionsForNamedEffects()
    return {
        {
            label = "Buffs & Debuffs",
            definitions = UtilityDB.namedEffects or {},
        },
    }
end

function Dashboard:BuildComposition(parent)
    local view = CreateFrame("Frame", nil, parent)
    view:SetAllPoints(parent)
    self.compositionView = view

    self.compositionSummary = Text(view, "Join or form a group to see available capabilities.", 11, Colors.muted)
    self.compositionSummary:SetPoint("TOPLEFT", view, "TOPLEFT", 0, 0)
    self.compositionSummary:SetPoint("TOPRIGHT", view, "TOPRIGHT", 0, 0)
    self.compositionSummary:SetHeight(22)

    self.compositionScroll = Theme.CreateScrollArea(view, { step = 48 })
    self.compositionScroll:SetPoint("TOPLEFT", view, "TOPLEFT", 0, -28)
    self.compositionScroll:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", 0, 0)
    local content = self.compositionScroll.content
    self.compositionContent = content

    local contentWidth = 910
    self.dependencyLegend = CreateFrame("Frame", nil, content, "BackdropTemplate")
    self.dependencyLegend:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    self.dependencyLegend:SetSize(contentWidth, 52)
    Theme.StylePanel(self.dependencyLegend, Colors.noteBg, Colors.softBorder, 1)
    local legendTitle = Text(self.dependencyLegend, "CAPABILITY SOURCES", 10, Colors.blue)
    legendTitle:SetPoint("TOPLEFT", self.dependencyLegend, "TOPLEFT", 12, -7)
    legendTitle:SetSize(150, 13)
    local legend = Text(
        self.dependencyLegend,
        "Green: Class/Spec = inherent  •  Yellow: Talent = talent or choice  •  Pet = pet required  •  Talent + Pet = both required",
        10,
        Colors.muted
    )
    legend:SetPoint("TOPLEFT", self.dependencyLegend, "TOPLEFT", 12, -23)
    legend:SetPoint("TOPRIGHT", self.dependencyLegend, "TOPRIGHT", -10, -23)
    legend:SetHeight(16)
    legend:SetWordWrap(false)
    SetTooltip(self.dependencyLegend, "Capability Sources", function(tooltip)
        for _, dependency in ipairs(UtilityDB.dependencies or {}) do
            tooltip:AddLine(dependency.label or dependency.id or "Dependency", 0.50, 0.68, 0.94)
            tooltip:AddLine(dependency.definition or "", 0.94, 0.96, 0.99, true)
        end
    end)

    local cardTop = -64
    local columnGap = 8
    local columnWidth = math.floor((contentWidth - (columnGap * 3)) / 4)
    local columnHeight = 560
    self.enhancementCard = CreateColumnCard(content, "Group Enhancements", DefinitionsForNamedEffects(), 0, columnWidth, columnHeight, true)
    self.enhancementCard:ClearAllPoints()
    self.enhancementCard:SetPoint("TOPLEFT", content, "TOPLEFT", 0, cardTop)
    self.removalCard = CreateColumnCard(content, "Removals", DefinitionsForGroups({ "Friendly Removal", "Enemy Removal" }), columnWidth + columnGap, columnWidth, columnHeight)
    self.removalCard:ClearAllPoints()
    self.removalCard:SetPoint("TOPLEFT", content, "TOPLEFT", columnWidth + columnGap, cardTop)
    self.controlCard = CreateColumnCard(content, "Cast Stops & Control", DefinitionsForGroups({ "Cast Stops and Crowd Control" }), (columnWidth + columnGap) * 2, columnWidth, columnHeight)
    self.controlCard:ClearAllPoints()
    self.controlCard:SetPoint("TOPLEFT", content, "TOPLEFT", (columnWidth + columnGap) * 2, cardTop)
    self.supportCard = CreateColumnCard(content, "Group Support", DefinitionsForGroups({ "Group Support" }), (columnWidth + columnGap) * 3, columnWidth, columnHeight)
    self.supportCard:ClearAllPoints()
    self.supportCard:SetPoint("TOPLEFT", content, "TOPLEFT", (columnWidth + columnGap) * 3, cardTop)

    self.namedRows = self.enhancementCard.rows or {}
    self.categoryRows = {}
    for _, card in ipairs({ self.removalCard, self.controlCard, self.supportCard }) do
        for id, row in pairs(card.rows or {}) do self.categoryRows[id] = row end
    end
    self.compositionScroll:SetContentHeight(64 + columnHeight)
end

local function CreateTargetSelectionRow(parent, width, height)
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    row:SetSize(width, height)
    Theme.StylePanel(row, Colors.analysisRowBg, Colors.softBorder, 1)
    row.title = Text(row, "", 11, Colors.text)
    row.title:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -8)
    row.title:SetPoint("TOPRIGHT", row, "TOPRIGHT", -10, -8)
    row.title:SetHeight(18)
    row.detail = Text(row, "", 9, Colors.muted)
    row.detail:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -3)
    row.detail:SetPoint("TOPRIGHT", row.title, "BOTTOMRIGHT", 0, -3)
    row.detail:SetHeight(height - 29)
    row:SetScript("OnEnter", function(self)
        if self.SetBackdropBorderColor then self:SetBackdropBorderColor(unpack(Colors.gold)) end
    end)
    row:SetScript("OnLeave", function(self)
        local border = self.selected and Colors.gold or Colors.softBorder
        if self.SetBackdropBorderColor then self:SetBackdropBorderColor(unpack(border)) end
    end)
    return row
end

function Dashboard:BuildMacroTargets(parent)
    local view = CreateFrame("Frame", nil, parent)
    view:SetAllPoints(parent)
    self.targetsView = view

    local note = CreateFrame("Frame", nil, view, "BackdropTemplate")
    note:SetPoint("TOPLEFT", view, "TOPLEFT", 0, 0)
    note:SetPoint("TOPRIGHT", view, "TOPRIGHT", 0, 0)
    note:SetHeight(56)
    Theme.StylePanel(note, Colors.noteBg, Colors.softBorder, 1)
    local noteText = Text(note, "Temporarily assign a party or raid member to selected friendly-support macro blocks. Change or remove assignments while out of combat; original targets return when you leave the group. Useful for external defensives, targeted healing, Power Infusion, Blessing of Freedom, and Misdirection.", 10, Colors.text)
    noteText:SetPoint("TOPLEFT", note, "TOPLEFT", 12, -9)
    noteText:SetPoint("TOPRIGHT", note, "TOPRIGHT", -12, -9)
    noteText:SetHeight(36)

    local left = CreateFrame("Frame", nil, view, "BackdropTemplate")
    left:SetPoint("TOPLEFT", view, "TOPLEFT", 0, -66)
    left:SetPoint("BOTTOMLEFT", view, "BOTTOMLEFT", 0, 54)
    left:SetWidth(326)
    Theme.StylePanel(left, Colors.panel, Colors.softBorder, 1)
    local leftTitle = Text(left, "GROUP MEMBER", 10, Colors.blue)
    leftTitle:SetPoint("TOPLEFT", left, "TOPLEFT", 12, -10)
    self.targetRosterScroll = Theme.CreateScrollArea(left, { step = 58 })
    self.targetRosterScroll:SetPoint("TOPLEFT", left, "TOPLEFT", 10, -34)
    self.targetRosterScroll:SetPoint("BOTTOMRIGHT", left, "BOTTOMRIGHT", -10, 10)
    self.targetRosterRows = {}

    local right = CreateFrame("Frame", nil, view, "BackdropTemplate")
    right:SetPoint("TOPLEFT", left, "TOPRIGHT", 10, 0)
    right:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", 0, 54)
    Theme.StylePanel(right, Colors.panel, Colors.softBorder, 1)
    local rightTitle = Text(right, "MARKED MACROS", 10, Colors.blue)
    rightTitle:SetPoint("TOPLEFT", right, "TOPLEFT", 12, -10)
    self.targetMacroScroll = Theme.CreateScrollArea(right, { step = 68 })
    self.targetMacroScroll:SetPoint("TOPLEFT", right, "TOPLEFT", 10, -34)
    self.targetMacroScroll:SetPoint("BOTTOMRIGHT", right, "BOTTOMRIGHT", -10, 64)
    self.targetMacroRows = {}
    self.targetEmpty = Text(right, "Mark a macro block in Macro Sequencer to make it available here.", 11, Colors.muted, "CENTER")
    self.targetEmpty:SetPoint("CENTER", right, "CENTER", 0, 12)
    self.targetEmpty:SetSize(500, 42)

    self.targetStatus = Text(view, "Join a group to assign temporary macro targets.", 10, Colors.muted)
    self.targetStatus:SetPoint("BOTTOMLEFT", view, "BOTTOMLEFT", 0, 10)
    self.targetStatus:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", -320, 10)
    self.targetStatus:SetHeight(30)
    self.targetStatus:SetJustifyV("MIDDLE")
    self.restoreTargetButton = Theme.CreateButton(view, "Restore Original", 132, 30)
    self.restoreTargetButton:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", -150, 10)
    self.restoreTargetButton:SetScript("OnClick", function()
        local lib = SequencerLibrary()
        local okay, message = lib.ClearGroupTarget and lib.ClearGroupTarget(Dashboard.selectedTargetMarkerID)
        Dashboard.targetStatus:SetText(message or "Unable to restore that macro.")
        ApplyColor(Dashboard.targetStatus, okay and Colors.green or Colors.red)
        Dashboard:RefreshMacroTargets()
    end)
    self.applyTargetButton = Theme.CreateButton(view, "Save Target", 140, 30)
    self.applyTargetButton:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", 0, 10)
    if Theme.StylePrimaryActionButton then Theme.StylePrimaryActionButton(self.applyTargetButton) end
    self.applyTargetButton:SetScript("OnClick", function()
        local lib = SequencerLibrary()
        local okay, message = lib.AssignGroupTargetUnit and lib.AssignGroupTargetUnit(Dashboard.selectedTargetMarkerID, Dashboard.selectedTargetMemberUnit)
        Dashboard.targetStatus:SetText(message or "Unable to apply that target.")
        ApplyColor(Dashboard.targetStatus, okay and Colors.green or Colors.red)
        Dashboard:RefreshMacroTargets()
    end)
end

function Dashboard:RefreshMacroTargets()
    if not self.targetsView then return end
    local lib = SequencerLibrary()
    local roster = lib.GetGroupTargetRoster and lib.GetGroupTargetRoster() or {}
    local readinessByUnit = {}
    for _, readinessMember in ipairs(Analysis.GetRoster and Analysis.GetRoster() or {}) do
        if readinessMember.unit then readinessByUnit[readinessMember.unit] = readinessMember end
    end
    local markers = lib.GetGroupTargetMarkers and lib.GetGroupTargetMarkers() or {}
    local grouped = lib.IsGrouped and lib.IsGrouped()
    local combat = InCombatLockdown and InCombatLockdown()

    local memberStillPresent = false
    for _, member in ipairs(roster) do if member.unit == self.selectedTargetMemberUnit then memberStillPresent = true; break end end
    if not memberStillPresent then self.selectedTargetMemberUnit = roster[1] and roster[1].unit or nil end
    local markerStillPresent = false
    for _, marker in ipairs(markers) do if marker.id == self.selectedTargetMarkerID then markerStillPresent = true; break end end
    if not markerStillPresent then self.selectedTargetMarkerID = markers[1] and markers[1].id or nil end

    for index, member in ipairs(roster) do
        local row = self.targetRosterRows[index]
        if not row then
            row = CreateTargetSelectionRow(self.targetRosterScroll.content, 286, 50)
            self.targetRosterRows[index] = row
            row:SetScript("OnClick", function()
                Dashboard.selectedTargetMemberUnit = row.member and row.member.unit
                Dashboard:RefreshMacroTargets()
            end)
        end
        row.member = member
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", self.targetRosterScroll.content, "TOPLEFT", 0, -((index - 1) * 56))
        row.title:SetText(tostring(member.name or "Unknown") .. (member.isPlayer and " (You)" or ""))
        local readinessMember = readinessByUnit[member.unit]
        local displayMember = readinessMember or member
        local role = readinessMember and readinessMember.roleLabel or member.role or "No Role"
        row.detail:SetText(ClassSpecText(displayMember) .. "  •  " .. tostring(role) .. "  •  " .. tostring(member.selector or ""))
        row.selected = member.unit == self.selectedTargetMemberUnit
        Theme.StylePanel(row, row.selected and Colors.noteBg or Colors.analysisRowBg, row.selected and Colors.gold or Colors.softBorder, 1)
        row:Show()
    end
    for index = #roster + 1, #self.targetRosterRows do self.targetRosterRows[index]:Hide() end
    self.targetRosterScroll:SetContentHeight(math.max(1, #roster * 56))

    for index, marker in ipairs(markers) do
        local row = self.targetMacroRows[index]
        if not row then
            row = CreateTargetSelectionRow(self.targetMacroScroll.content, 522, 60)
            self.targetMacroRows[index] = row
            row:SetScript("OnClick", function()
                Dashboard.selectedTargetMarkerID = row.marker and row.marker.id
                Dashboard:RefreshMacroTargets()
            end)
        end
        local assignment = lib.GetGroupTargetAssignment and lib.GetGroupTargetAssignment(marker.id)
        local status
        if not assignment then
            status = "Original " .. tostring(marker.sourceTarget)
        elseif assignment.needsUpdate then
            status = "Needs Update: " .. tostring(assignment.targetName or "Player") .. " moved " .. tostring(assignment.appliedUnit) .. " -> " .. tostring(assignment.currentUnit or "left group")
        else
            status = "Active: " .. tostring(assignment.targetName or "Player") .. " " .. tostring(assignment.appliedUnit)
        end
        row.marker = marker
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", self.targetMacroScroll.content, "TOPLEFT", 0, -((index - 1) * 66))
        row.title:SetText(tostring(marker.name))
        row.detail:SetText(tostring(marker.sequenceName) .. "  •  " .. tostring(marker.versionName) .. "  •  " .. status)
        row.selected = marker.id == self.selectedTargetMarkerID
        Theme.StylePanel(row, row.selected and Colors.noteBg or Colors.analysisRowBg, row.selected and Colors.gold or (assignment and Colors.green or Colors.softBorder), 1)
        row:Show()
    end
    for index = #markers + 1, #self.targetMacroRows do self.targetMacroRows[index]:Hide() end
    self.targetMacroScroll:SetContentHeight(math.max(1, #markers * 66))
    self.targetEmpty:SetShown(#markers == 0)

    self.applyTargetButton:SetEnabled(grouped and not combat and self.selectedTargetMemberUnit ~= nil and self.selectedTargetMarkerID ~= nil)
    local selectedAssignment = self.selectedTargetMarkerID and lib.GetGroupTargetAssignment and lib.GetGroupTargetAssignment(self.selectedTargetMarkerID)
    self.restoreTargetButton:SetEnabled(not combat and selectedAssignment ~= nil)
    if combat then
        self.targetStatus:SetText("Macro Targets are locked during combat.")
        ApplyColor(self.targetStatus, Colors.red)
    elseif not grouped then
        self.targetStatus:SetText("Join a party or raid to choose a temporary macro target.")
        ApplyColor(self.targetStatus, Colors.muted)
    elseif #markers == 0 then
        self.targetStatus:SetText("Mark a block in Macro Sequencer first.")
        ApplyColor(self.targetStatus, Colors.muted)
    else
        self.targetStatus:SetText("Choose a group member and a marked macro, then save the target.")
        ApplyColor(self.targetStatus, Colors.blue)
    end
end

local function CreateCompactDropdown(parent, width)
    local dropdown = Theme.CreateButton(parent, "Choose Player", width or 220, 26)
    dropdown.menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    dropdown.menu:SetFrameStrata("FULLSCREEN_DIALOG")
    dropdown.menu:SetFrameLevel(9800)
    dropdown.menu:SetWidth(width or 220)
    dropdown.menu:Hide()
    Theme.StylePanel(dropdown.menu, Colors.bg, Colors.gold, 1)
    dropdown.menu.rows = {}
    dropdown.menu.offset = 1
    local function populate()
        local options = dropdown.options or {}
        local visible = math.min(10, math.max(1, #options))
        dropdown.menu:SetHeight((visible * 25) + 4)
        local maxOffset = math.max(1, #options - visible + 1)
        dropdown.menu.offset = math.max(1, math.min(dropdown.menu.offset or 1, maxOffset))
        for index = 1, 10 do
            local row = dropdown.menu.rows[index]
            if not row then
                row = Theme.CreateButton(dropdown.menu, "", (width or 220) - 4, 23)
                dropdown.menu.rows[index] = row
                row:SetScript("OnClick", function()
                    local option = row.option
                    if not option then return end
                    dropdown.value = option.value
                    dropdown:SetText(option.label)
                    dropdown.menu:Hide()
                    if dropdown.onSelect then dropdown.onSelect(option.value, option) end
                end)
            end
            local option = options[dropdown.menu.offset + index - 1]
            row.option = option
            row:SetShown(option ~= nil)
            if option then
                row:ClearAllPoints(); row:SetPoint("TOPLEFT", dropdown.menu, "TOPLEFT", 2, -2 - ((index - 1) * 25))
                row:SetText(option.label)
            end
        end
    end
    dropdown.menu:EnableMouseWheel(true)
    dropdown.menu:SetScript("OnMouseWheel", function(_, delta)
        dropdown.menu.offset = math.max(1, (dropdown.menu.offset or 1) - delta)
        populate()
    end)
    dropdown:SetScript("OnClick", function()
        if dropdown.menu:IsShown() then dropdown.menu:Hide(); return end
        dropdown.menu.offset = 1
        dropdown.menu:ClearAllPoints(); dropdown.menu:SetPoint("TOPRIGHT", dropdown, "BOTTOMRIGHT", 0, -2)
        populate(); dropdown.menu:Show()
    end)
    function dropdown:SetChoices(options, selected, onSelect)
        self.options = options or {}; self.value = selected; self.onSelect = onSelect
        local label = "Choose Player"
        for _, option in ipairs(self.options) do if option.value == selected then label = option.label; break end end
        self:SetText(label)
    end
    return dropdown
end

local function ActiveCapabilityList()
    local composition = Analysis.GetComposition and Analysis.GetComposition() or {}
    local list = {}
    local function total(data)
        return tonumber(data and data.counts and data.counts.class_spec) or 0
    end
    for _, definition in ipairs(UtilityDB.namedEffects or {}) do
        local count = total(composition.named and composition.named[definition.id])
        if count > 0 then table.insert(list, { label = definition.label or definition.id, count = count }) end
    end
    for _, definition in ipairs(UtilityDB.categories or {}) do
        local count = total(composition.categories and composition.categories[definition.id])
        if count > 0 then table.insert(list, { label = definition.label or definition.id, count = count }) end
    end
    return list
end

local function FloatingPositionStore()
    KeyLabDB = type(KeyLabDB) == "table" and KeyLabDB or {}
    KeyLabDB.groupDashboardUI = type(KeyLabDB.groupDashboardUI) == "table" and KeyLabDB.groupDashboardUI or {}
    KeyLabDB.groupDashboardUI.floatingPositions = type(KeyLabDB.groupDashboardUI.floatingPositions) == "table"
        and KeyLabDB.groupDashboardUI.floatingPositions or {}
    return KeyLabDB.groupDashboardUI.floatingPositions
end

local function RestoreFloatingPosition(frame, key, defaultPoint, defaultRelativePoint, defaultX, defaultY)
    local position = FloatingPositionStore()[key]
    frame:ClearAllPoints()
    if type(position) == "table" and type(position.point) == "string" and type(position.relativePoint) == "string" then
        frame:SetPoint(position.point, UIParent, position.relativePoint, tonumber(position.x) or 0, tonumber(position.y) or 0)
    else
        frame:SetPoint(defaultPoint, UIParent, defaultRelativePoint, defaultX or 0, defaultY or 0)
    end
end

local function SaveFloatingPosition(frame, key)
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    if not point then return end
    FloatingPositionStore()[key] = {
        point = point,
        relativePoint = relativePoint or point,
        x = tonumber(x) or 0,
        y = tonumber(y) or 0,
    }
end

function Dashboard:EnsureGroupSnapshot()
    if self.snapshot then return self.snapshot end
    local frame = CreateFrame("Frame", "KeyLabGroupSnapshot", UIParent, "BackdropTemplate")
    frame:SetSize(374, math.min(780, math.max(650, UIParent:GetHeight()-60))); RestoreFloatingPosition(frame, "snapshot", "RIGHT", "RIGHT", -24, 0)
    frame:SetFrameStrata("DIALOG"); frame:SetFrameLevel(8200); frame:Hide(); frame:EnableMouse(true)
    frame:SetMovable(true); frame:SetClampedToScreen(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if InCombatLockdown and InCombatLockdown() then return end
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing(); SaveFloatingPosition(self, "snapshot")
    end)
    Theme.StylePanel(frame, Colors.bg, Colors.gold, 1)
    Theme.AddPopupLogo(frame)
    local title = Text(frame, "Group Snapshot", 16, Colors.gold)
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 66, -14)
    local subtitle = Text(frame, "Class/Spec capabilities only. Drag to move; open the full dashboard for details.", 9, Colors.muted)
    subtitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 66, -36); subtitle:SetSize(258, 30)
    local minimize = Theme.CreateButton(frame, "—", 30, 24)
    minimize:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -10)
    minimize:SetScript("OnClick", function()
        frame:Hide(); Dashboard.snapshotCollapsed = true
        if Dashboard.snapshotHandle and not (InCombatLockdown and InCombatLockdown()) then Dashboard.snapshotHandle:Show() end
    end)
    frame.talentName=Text(frame,"",12,Colors.gold)
    frame.talentName:SetPoint("TOPLEFT",16,-72); frame.talentName:SetSize(340,40)
    frame.talentDropdown=CreateCompactDropdown(frame,244)
    frame.talentDropdown:SetPoint("TOPLEFT",14,-117)
    frame.talentSwitch=Theme.CreateButton(frame,"Switch",86,26)
    frame.talentSwitch:SetPoint("LEFT",frame.talentDropdown,"RIGHT",8,0)
    frame.talentSwitch:SetScript("OnClick",function()
        if KeyLab.GuideTalents then KeyLab.GuideTalents.Switch(frame.selectedTalentID) end
    end)
    frame.talentNote=Text(frame,"",10,Colors.muted)
    frame.talentNote:SetPoint("TOPLEFT",16,-148); frame.talentNote:SetSize(340,42)
    frame:HookScript("OnHide",function() frame.talentDropdown.menu:Hide() end)
    local rosterTitle = Text(frame, "GROUP MEMBERS", 10, Colors.blue)
    rosterTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -202)
    frame.rosterScroll = Theme.CreateScrollArea(frame, { step = 44 })
    frame.rosterScroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -224)
    frame.rosterScroll:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -224)
    frame.rosterScroll:SetHeight(214); frame.rosterRows = {}
    local capabilityTitle = Text(frame, "CLASS/SPEC CAPABILITIES", 10, Colors.blue)
    capabilityTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -450)
    frame.capabilityScroll = Theme.CreateScrollArea(frame, { step = 30 })
    frame.capabilityScroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -472)
    frame.capabilityScroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 88)
    frame.capabilityRows = {}
    frame.checkButton = Theme.CreateButton(frame, "Check Group Status", 156, 30)
    frame.checkButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 44)
    frame.checkButton:SetScript("OnClick", function() if Analysis.StartAuraCheck then Analysis.StartAuraCheck() end end)
    frame.openButton = Theme.CreateButton(frame, "Open Full Dashboard", 174, 30)
    frame.openButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 44)
    if Theme.StylePrimaryActionButton then Theme.StylePrimaryActionButton(frame.openButton) end
    frame.openButton:SetScript("OnClick", function()
        frame:Hide(); Dashboard.snapshotCollapsed = true
        if KeyLab.UI and KeyLab.UI.Show then KeyLab.UI:Show() end
        if KeyLab.UI and KeyLab.UI.SelectTab then KeyLab.UI:SelectTab("Group Dashboard") end
    end)
    frame.note = Text(frame, "", 9, Colors.muted)
    frame.note:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 12); frame.note:SetSize(340, 22)

    local handle = Theme.CreateButton(UIParent, "GROUP\nSNAPSHOT", 76, 112)
    local savedHandlePosition = FloatingPositionStore().snapshotHandle
    if type(savedHandlePosition) == "table"
        and savedHandlePosition.point == "RIGHT"
        and savedHandlePosition.relativePoint == "RIGHT"
        and (tonumber(savedHandlePosition.x) or 0) > -20
    then
        savedHandlePosition.x = -20
    end
    RestoreFloatingPosition(handle, "snapshotHandle", "RIGHT", "RIGHT", -20, 0)
    handle:SetFrameStrata("DIALOG"); handle:SetFrameLevel(8100); handle:Hide()
    handle.logo = handle:CreateTexture(nil, "ARTWORK")
    handle.logo:SetTexture("Interface\\AddOns\\KeyLab\\Assets\\KeyLabKeyIcon.tga")
    handle.logo:SetTexCoord(0, 1, 1, 0)
    handle.logo:SetSize(30, 30)
    handle.logo:SetPoint("TOP", handle, "TOP", 0, -8)
    handle.label:ClearAllPoints()
    handle.label:SetPoint("TOPLEFT", handle, "TOPLEFT", 5, -42)
    handle.label:SetPoint("BOTTOMRIGHT", handle, "BOTTOMRIGHT", -5, 8)
    handle:SetMovable(true); handle:SetClampedToScreen(true); handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart", function(self)
        if InCombatLockdown and InCombatLockdown() then return end
        self.wasDragged = true; self:StartMoving()
    end)
    handle:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing(); SaveFloatingPosition(self, "snapshotHandle")
        local function clearDrag() self.wasDragged = false end
        if C_Timer and C_Timer.After then C_Timer.After(0.10, clearDrag) else clearDrag() end
    end)
    handle:SetScript("OnClick", function()
        if handle.wasDragged then return end
        if not IsCurrentlyGrouped() or (InCombatLockdown and InCombatLockdown()) then
            Dashboard:HandleFloatingRefresh("snapshot-click")
            return
        end
        handle:Hide(); Dashboard.snapshotCollapsed = false; Dashboard:RefreshGroupSnapshot(); frame:Show()
    end)
    handle:HookScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:AddLine("Group Snapshot", 0.82, 0.76, 0.58)
        GameTooltip:AddLine("Drag to move. Click to open.", 0.94, 0.96, 0.99); GameTooltip:Show()
    end)
    handle:HookScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    self.snapshot = frame; self.snapshotHandle = handle
    return frame
end

function Dashboard:RefreshGroupSnapshot()
    local frame = self:EnsureGroupSnapshot()
    self:RefreshSnapshotTalents()
    local roster = Analysis.GetRoster and Analysis.GetRoster() or {}
    local shownMembers, npcCount = {}, 0
    for _, member in ipairs(roster) do
        if member.isNPC then npcCount = npcCount + 1 else table.insert(shownMembers, member) end
    end
    for index, member in ipairs(shownMembers) do
        local row = frame.rosterRows[index]
        if not row then
            row = CreateFrame("Frame", nil, frame.rosterScroll.content, "BackdropTemplate")
            row:SetSize(330, 38); Theme.StylePanel(row, Colors.analysisRowBg, Colors.softBorder, 1)
            row.name = Text(row, "", 10, Colors.text); row.name:SetPoint("LEFT", row, "LEFT", 8, 0); row.name:SetSize(132, 32); row.name:SetJustifyV("MIDDLE")
            row.auraChips = {}; frame.rosterRows[index] = row
        end
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", frame.rosterScroll.content, "TOPLEFT", 0, -((index - 1) * 42))
        row.name:SetText(tostring(member.name or "Unknown") .. "\n" .. tostring(member.roleLabel or "No Role"))
        local displayed = 0
        if member.auraState == "Checked" then
            for auraIndex, aura in ipairs(member.presentAuras or {}) do
                if auraIndex > 7 then break end
                local chip = row.auraChips[auraIndex]
                if not chip then chip = CreateAuraChip(row); chip:SetSize(24, 24); row.auraChips[auraIndex] = chip end
                displayed = auraIndex; chip.aura = aura; chip.icon:SetTexture(GetAuraTexture(aura)); chip.stack:SetText((aura.applications or 0) > 1 and tostring(aura.applications) or "")
                chip:ClearAllPoints(); chip:SetPoint("LEFT", row, "LEFT", 142 + ((auraIndex - 1) * 26), 0); chip:Show()
            end
        end
        for auraIndex = displayed + 1, #row.auraChips do row.auraChips[auraIndex]:Hide() end
        row:Show()
    end
    for index = #shownMembers + 1, #frame.rosterRows do frame.rosterRows[index]:Hide() end
    frame.rosterScroll:SetContentHeight(math.max(1, #shownMembers * 42))
    local capabilities = ActiveCapabilityList()
    for index, capability in ipairs(capabilities) do
        local row = frame.capabilityRows[index]
        if not row then
            row = CreateFrame("Frame", nil, frame.capabilityScroll.content, "BackdropTemplate")
            row:SetSize(330, 26); Theme.StylePanel(row, Colors.noteBg, Colors.green, 1)
            row.label = Text(row, "", 10, Colors.green); row.label:SetPoint("LEFT", row, "LEFT", 8, 0); row.label:SetSize(270, 24); row.label:SetJustifyV("MIDDLE")
            row.badge = Theme.CreateBadge(row, "0", 30, 20); row.badge:SetPoint("RIGHT", row, "RIGHT", -5, 0)
            frame.capabilityRows[index] = row
        end
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", frame.capabilityScroll.content, "TOPLEFT", 0, -((index - 1) * 29))
        row.label:SetText(capability.label); Theme.SetBadge(row.badge, tostring(capability.count), Colors.badgeBg, Colors.green, Colors.green); row:Show()
    end
    for index = #capabilities + 1, #frame.capabilityRows do frame.capabilityRows[index]:Hide() end
    frame.capabilityScroll:SetContentHeight(math.max(1, #capabilities * 29))
    frame.note:SetText((npcCount > 0 and (tostring(npcCount) .. " follower companion" .. (npcCount == 1 and "" or "s") .. " omitted.  •  ") or "") .. tostring(#capabilities) .. " Class/Spec capabilities")
    local scan = Analysis.GetScanState and Analysis.GetScanState() or {}
    frame.checkButton:SetEnabled(not scan.active)
    frame.checkButton:SetText(scan.complete and "Check Again" or "Check Group Status")
end

function Dashboard:RefreshSnapshotTalents()
    local frame=self.snapshot
    local talents=KeyLab.GuideTalents
    if not frame or not talents or (InCombatLockdown and InCombatLockdown()) then return end
    frame.talentName:SetText("CURRENT BUILD\n"..talents.GetActiveName())
    local choices,found={},false
    for _,config in ipairs(talents.GetLoadouts()) do
        choices[#choices+1]={value=config.id,label=config.name}
        if config.id==frame.selectedTalentID then found=true end
    end
    if not found then frame.selectedTalentID=nil end
    frame.talentDropdown:SetChoices(choices,frame.selectedTalentID,function(id)
        frame.selectedTalentID=id
        Dashboard:RefreshSnapshotTalents()
    end)
    if not frame.selectedTalentID then frame.talentDropdown:SetText("Choose Talent Build") end
    local locked=talents.IsKeyActive()
    frame.talentDropdown:SetShown(not locked); frame.talentSwitch:SetShown(not locked)
    if locked then frame.talentDropdown.menu:Hide() end
    local can,reason=talents.CanAct()
    frame.talentDropdown:SetEnabled(can); frame.talentSwitch:SetEnabled(can and frame.selectedTalentID~=nil)
    frame.talentNote:SetText(locked and "Mythic+ in progress - talent switching is locked."
        or not can and reason or talents.message~="" and talents.message or "Choose any saved build. Switch before the key starts or between raid pulls.")
end

function Dashboard:EnsureTargetChangePopup()
    if self.targetChangePopup then return self.targetChangePopup end
    local popup = CreateFrame("Frame", "KeyLabGroupTargetChangePopup", UIParent, "BackdropTemplate")
    popup:SetSize(590, 260); popup:SetPoint("CENTER", UIParent, "CENTER", 0, 110)
    popup:SetFrameStrata("FULLSCREEN_DIALOG"); popup:SetFrameLevel(9700); popup:Hide(); popup:EnableMouse(true)
    Theme.StylePanel(popup, Colors.bg, Colors.gold, 1)
    Theme.AddPopupLogo(popup)
    popup.title = Text(popup, "Keep or Change Macro Target", 16, Colors.gold)
    popup.title:SetPoint("TOPLEFT", popup, "TOPLEFT", 66, -14)
    popup.help = Text(popup, "A selected player moved to a different group position. Choose Change to follow that player, or Keep to leave the macro on its current position.", 10, Colors.text)
    popup.help:SetPoint("TOPLEFT", popup.title, "BOTTOMLEFT", 0, -5); popup.help:SetSize(504, 34)
    popup.rows = {}
    popup.changeButton = Theme.CreateButton(popup, "Change", 112, 30)
    popup.changeButton:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -16, 14)
    if Theme.StylePrimaryActionButton then Theme.StylePrimaryActionButton(popup.changeButton) end
    popup.leaveButton = Theme.CreateButton(popup, "Keep", 112, 30)
    popup.leaveButton:SetPoint("RIGHT", popup.changeButton, "LEFT", -8, 0)
    popup.changeButton:SetScript("OnClick", function()
        local lib = SequencerLibrary(); local allOkay = true
        for _, row in ipairs(popup.rows) do
            if row:IsShown() and row.change then
                if row.dropdown.value then
                    local okay = lib.AssignGroupTargetUnit and lib.AssignGroupTargetUnit(row.change.markerID, row.dropdown.value)
                    if not okay then allOkay = false end
                else
                    allOkay = false
                end
            end
        end
        if allOkay then popup:Hide() end
        Dashboard:HandleFloatingRefresh("targets changed")
    end)
    popup.leaveButton:SetScript("OnClick", function()
        local lib = SequencerLibrary()
        for _, row in ipairs(popup.rows) do if row:IsShown() and row.change and lib.AcknowledgeGroupTargetChange then lib.AcknowledgeGroupTargetChange(row.change.markerID) end end
        popup:Hide()
    end)
    popup:SetScript("OnHide", function()
        for _, row in ipairs(popup.rows or {}) do if row.dropdown and row.dropdown.menu then row.dropdown.menu:Hide() end end
    end)
    self.targetChangePopup = popup
    return popup
end

function Dashboard:RefreshTargetChangePopup()
    local lib = SequencerLibrary()
    local changes = lib.GetPendingGroupTargetChanges and lib.GetPendingGroupTargetChanges() or {}
    local popup = self:EnsureTargetChangePopup()
    if #changes == 0 or (InCombatLockdown and InCombatLockdown()) then popup:Hide(); return end
    local roster = lib.GetGroupTargetRoster and lib.GetGroupTargetRoster() or {}
    local options = {}
    for _, member in ipairs(roster) do table.insert(options, { value = member.unit, label = tostring(member.name) .. "  " .. tostring(member.selector) }) end
    local maxRows = math.min(6, #changes)
    popup:SetHeight(160 + (maxRows * 46))
    for index = 1, maxRows do
        local change = changes[index]
        local row = popup.rows[index]
        if not row then
            row = CreateFrame("Frame", nil, popup, "BackdropTemplate"); row:SetSize(558, 40); Theme.StylePanel(row, Colors.analysisRowBg, Colors.softBorder, 1)
            row.label = Text(row, "", 10, Colors.text); row.label:SetPoint("LEFT", row, "LEFT", 8, 0); row.label:SetSize(292, 36); row.label:SetJustifyV("MIDDLE")
            row.dropdown = CreateCompactDropdown(row, 242); row.dropdown:SetPoint("RIGHT", row, "RIGHT", -6, 0)
            popup.rows[index] = row
        end
        row.change = change; row:ClearAllPoints(); row:SetPoint("TOPLEFT", popup, "TOPLEFT", 16, -84 - ((index - 1) * 46))
        row.label:SetText(tostring(change.markerName or "Macro") .. "\n" .. tostring(change.targetName or "Player") .. ": " .. tostring(change.appliedUnit) .. " -> " .. tostring(change.currentUnit or "left group"))
        local selected = tostring(change.currentUnit or ""):gsub("^@", "")
        local selectedStillPresent = false
        for _, option in ipairs(options) do if option.value == selected then selectedStillPresent = true; break end end
        if not selectedStillPresent then selected = nil end
        row.dropdown:SetChoices(options, selected, function(value) row.dropdown.value = value end)
        row:Show()
    end
    for index = maxRows + 1, #popup.rows do popup.rows[index]:Hide() end
    popup.leaveButton:SetText("Keep")
    popup:Show()
end

function Dashboard:HideFloatingForCombat()
    if (self.snapshot and self.snapshot:IsShown()) or (self.snapshotHandle and self.snapshotHandle:IsShown()) then
        self.snapshotHiddenForCombat = true
    end
    if self.snapshot then self.snapshot:Hide() end
    if self.snapshotHandle then self.snapshotHandle:Hide() end
    if self.targetChangePopup then
        self.targetChangePopup:Hide()
        for _, row in ipairs(self.targetChangePopup.rows or {}) do if row.dropdown and row.dropdown.menu then row.dropdown.menu:Hide() end end
    end
    if KeyLab.Tabs and KeyLab.Tabs.Sequencer and KeyLab.Tabs.Sequencer.groupTargetDialog then
        KeyLab.Tabs.Sequencer.groupTargetDialog:Hide()
    end
end

function Dashboard:HandleFloatingRefresh(reason)
    local grouped = IsCurrentlyGrouped()
    local combat = InCombatLockdown and InCombatLockdown()
    if not grouped then
        if self.snapshot then self.snapshot:Hide() end
        if self.snapshot and self.snapshot.talentDropdown and self.snapshot.talentDropdown.menu then
            self.snapshot.talentDropdown.menu:Hide()
        end
        if self.snapshotHandle then self.snapshotHandle:Hide() end
        if self.targetChangePopup then
            self.targetChangePopup:Hide()
            for _, row in ipairs(self.targetChangePopup.rows or {}) do
                if row.dropdown and row.dropdown.menu then row.dropdown.menu:Hide() end
            end
        end
        self.snapshotSessionActive = false; self.snapshotCollapsed = false
        self.snapshotHiddenForCombat = false
        if Analysis.SetActive then Analysis.SetActive(false, "snapshot") end
        return
    end
    if combat then self:HideFloatingForCombat(); return end
    if not self.snapshotSessionActive then
        self.snapshotSessionActive = true; self.snapshotCollapsed = false
        self.snapshotHiddenForCombat = false
        if Analysis.SetActive then Analysis.SetActive(true, "snapshot") end
        self:RefreshGroupSnapshot(); self.snapshot:Show()
    else
        self:RefreshGroupSnapshot()
        if self.snapshotHiddenForCombat then
            self.snapshotHiddenForCombat = false
            self.snapshotCollapsed = true
            if self.snapshot then self.snapshot:Hide() end
            if self.snapshotHandle then self.snapshotHandle:Show() end
        elseif self.snapshotCollapsed then
            self.snapshotHandle:Show()
        end
    end
    self:RefreshTargetChangePopup()
end

function Dashboard:RefreshReadiness()
    local roster = Analysis.GetRoster and Analysis.GetRoster() or {}
    local scan = Analysis.GetScanState and Analysis.GetScanState() or { active = false, complete = false, message = "Unavailable" }
    local inGroup = Analysis.IsInGroup and Analysis.IsInGroup()
    self.readinessSolo:SetShown(not inGroup)
    self.rosterScroll:SetShown(inGroup)
    self.checkButton:SetEnabled(inGroup and not scan.active)
    self.stopButton:SetEnabled(scan.active)
    self.checkButton:SetText(scan.complete and "Check Again" or "Check Group Status")
    self.readinessProgress:SetText(scan.message or "")
    ApplyColor(self.readinessProgress, scan.active and Colors.blue or (scan.complete and Colors.green or Colors.muted))

    for index, member in ipairs(roster) do
        local row = self.rosterRows[index]
        if not row then
            row = CreateRosterRow(self.rosterScroll.content, index)
            self.rosterRows[index] = row
        end
        row.member = member
        row.firstLine:SetText(BuildRosterFirstLine(member))
        row.secondLine:SetText(BuildAuraLine(member))
        RefreshAuraChips(row, member)
        ApplyColor(row.firstLine, member.isLeader and Colors.gold or Colors.text)
        ApplyColor(row.secondLine, member.auraState == "Checked" and Colors.text or Colors.muted)
        row.accent:SetColorTexture(unpack(member.isLeader and Colors.gold or (member.isAssistant and Colors.blue or Colors.softBorder)))
        row:Show()
    end
    for index = #roster + 1, #self.rosterRows do self.rosterRows[index]:Hide() end
    self.rosterScroll:SetContentHeight(math.max(1, #roster * (ROW_HEIGHT + ROW_GAP)))
end

local function RefreshCapabilityBadges(row, data)
    row.data = data
    local rowHasCount = false
    for _, dependency in ipairs(DEPENDENCY_ORDER) do
        local count = data and data.counts and data.counts[dependency] or 0
        local choices = data and data.choices and data.choices[dependency] or 0
        local cell = row.cells[dependency]
        local hasCount = count > 0 or choices > 0
        if hasCount then rowHasCount = true end
        cell.zero:SetShown(not hasCount)
        cell.badge:SetShown(hasCount)
        if hasCount then
            local color = dependency == "class_spec" and Colors.green or (Colors.yellow or Colors.warning or Colors.gold)
            local background = Theme.WithAlpha and Theme.WithAlpha(color, 0.18) or Colors.badgeBg
            Theme.SetBadge(cell.badge, DependencyCellText(count, choices), background, color, color)
        end
    end
    return rowHasCount
end

local function SetCapabilityRowActive(row, active)
    active = active == true
    if row.activeCardState ~= active then
        local activeBackground = Theme.WithAlpha and Theme.WithAlpha(Colors.green, 0.10) or Colors.analysisRowHoverBg
        local activeBorder = Theme.WithAlpha and Theme.WithAlpha(Colors.green, 0.78) or Colors.green
        Theme.StylePanel(row, Colors.analysisRowBg, Colors.transparent, 0)
        Theme.StylePanel(row.labelBackground,
            active and activeBackground or Colors.transparent,
            active and activeBorder or Colors.transparent,
            active and 1 or 0)
        row.activeCardState = active
    end
    ApplyColor(row.label, active and Colors.green or Colors.text)
end

function Dashboard:RefreshComposition()
    local composition = Analysis.GetComposition and Analysis.GetComposition() or { inGroup = false, totalMembers = 0, knownMembers = 0, named = {}, categories = {} }
    if not composition.inGroup then
        self.compositionSummary:SetText("Form or join a party or raid. All capabilities remain visible at zero until a roster is available.")
        ApplyColor(self.compositionSummary, Colors.muted)
    else
        self.compositionSummary:SetText(
            tostring(composition.knownMembers or 0) .. " of " .. tostring(composition.totalMembers or 0)
                .. " specializations available • Green is inherent; yellow requires the shown talent or pet source."
        )
        ApplyColor(self.compositionSummary, (composition.knownMembers or 0) == (composition.totalMembers or 0) and Colors.green or Colors.blue)
    end

    for id, row in pairs(self.namedRows or {}) do
        local data = composition.named and composition.named[id]
        local active = RefreshCapabilityBadges(row, data) or (data and data.providerCount or 0) > 0
        SetCapabilityRowActive(row, active)
    end

    for id, row in pairs(self.categoryRows or {}) do
        local data = composition.categories and composition.categories[id]
        SetCapabilityRowActive(row, RefreshCapabilityBadges(row, data))
    end
    self.compositionScroll:Refresh()
end

function Dashboard:Refresh()
    if not self.frame or not self.frame:IsShown() then return end
    self:RefreshReadiness()
    self:RefreshComposition()
    self:RefreshMacroTargets()
end

function Dashboard:QueueRefresh()
    if self.refreshQueued then return end
    self.refreshQueued = true
    if C_Timer and C_Timer.After then
        C_Timer.After(0.05, function()
            Dashboard.refreshQueued = false
            Dashboard:Refresh()
        end)
    else
        self.refreshQueued = false
        self:Refresh()
    end
end

function Dashboard:SetView(viewID)
    viewID = (viewID == "composition" or viewID == "targets") and viewID or "readiness"
    self.selectedView = viewID
    self.readinessView:SetShown(viewID == "readiness")
    self.compositionView:SetShown(viewID == "composition")
    self.targetsView:SetShown(viewID == "targets")
    self.readinessTab:SetSelected(viewID == "readiness")
    self.compositionTab:SetSelected(viewID == "composition")
    self.targetsTab:SetSelected(viewID == "targets")
    self:Refresh()
end

function Dashboard:Create(parent)
    local frame = CreateFrame("Frame", "KeyLabGroupDashboardTab", parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    Theme.StylePanel(frame, Colors.bg, Colors.transparent, 0)
    self.frame = frame
    Theme.CreateTabHeader(
        frame,
        "Group Dashboard",
        "Review the current roster, manually check group buffs, and see available group capabilities."
    )

    self.readinessTab = Theme.CreateTextTabButton(frame, "GROUP READINESS", 158, 32, { fontSize = 10 })
    self.readinessTab:SetPoint("TOPLEFT", frame, "TOPLEFT", OUTER_X, -80)
    self.compositionTab = Theme.CreateTextTabButton(frame, "GROUP COMPOSITION", 176, 32, { fontSize = 10 })
    self.compositionTab:SetPoint("LEFT", self.readinessTab, "RIGHT", 8, 0)
    self.targetsTab = Theme.CreateTextTabButton(frame, "MACRO TARGETS", 150, 32, { fontSize = 10 })
    self.targetsTab:SetPoint("LEFT", self.compositionTab, "RIGHT", 8, 0)
    self.readinessTab:SetScript("OnClick", function() Dashboard:SetView("readiness") end)
    self.compositionTab:SetScript("OnClick", function() Dashboard:SetView("composition") end)
    self.targetsTab:SetScript("OnClick", function() Dashboard:SetView("targets") end)

    self.viewHost = CreateFrame("Frame", nil, frame)
    self.viewHost:SetPoint("TOPLEFT", frame, "TOPLEFT", OUTER_X, VIEW_TOP)
    self.viewHost:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -OUTER_RIGHT, 16)
    self:BuildReadiness(self.viewHost)
    self:BuildComposition(self.viewHost)
    self:BuildMacroTargets(self.viewHost)
    self:SetView("readiness")

    self.listener = self.listener or function() Dashboard:QueueRefresh() end
    frame:SetScript("OnShow", function()
        if Analysis.AddListener then Analysis.AddListener(Dashboard.listener) end
        local lib = SequencerLibrary()
        if lib.AddGroupTargetListener then lib.AddGroupTargetListener(Dashboard.listener) end
        if Analysis.SetActive then Analysis.SetActive(true, "dashboard") end
        Dashboard:Refresh()
    end)
    frame:SetScript("OnHide", function()
        if Analysis.RemoveListener then Analysis.RemoveListener(Dashboard.listener) end
        local lib = SequencerLibrary()
        if lib.RemoveGroupTargetListener then lib.RemoveGroupTargetListener(Dashboard.listener) end
        if Analysis.SetActive then Analysis.SetActive(false, "dashboard") end
    end)
    return frame
end

function Dashboard:OpenMacroTargets(markerID)
    if InCombatLockdown and InCombatLockdown() then return false end
    if markerID then self.selectedTargetMarkerID = markerID end
    if KeyLab.UI and KeyLab.UI.Show then KeyLab.UI:Show() end
    if KeyLab.UI and KeyLab.UI.SelectTab then KeyLab.UI:SelectTab("Group Dashboard") end
    if self.frame then self:SetView("targets") end
    return true
end

function KeyLab_CreateGroupDashboardTab(parent)
    return Dashboard:Create(parent)
end

if KeyLab.RegisterTab then
    KeyLab.RegisterTab("Group Dashboard", function(parent) return Dashboard:Create(parent) end)
end

Dashboard.floatingListener = Dashboard.floatingListener or function(reason)
    if Dashboard.floatingRefreshQueued then return end
    Dashboard.floatingRefreshQueued = true
    local function refresh()
        Dashboard.floatingRefreshQueued = false
        Dashboard:HandleFloatingRefresh(reason)
    end
    if C_Timer and C_Timer.After then C_Timer.After(0.10, refresh) else refresh() end
end
if Analysis.AddListener then Analysis.AddListener(Dashboard.floatingListener) end
local sequencer = SequencerLibrary()
if sequencer.AddGroupTargetListener then sequencer.AddGroupTargetListener(Dashboard.floatingListener) end
if KeyLab.GuideTalents then
    KeyLab.GuideTalents.Listen(function() Dashboard:RefreshSnapshotTalents() end)
end

local floatingEvents = CreateFrame("Frame")
floatingEvents:RegisterEvent("PLAYER_LOGIN")
floatingEvents:RegisterEvent("GROUP_ROSTER_UPDATE")
floatingEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
floatingEvents:RegisterEvent("PLAYER_REGEN_DISABLED")
floatingEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
floatingEvents:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then Dashboard:HideFloatingForCombat() else Dashboard:HandleFloatingRefresh(event) end
end)

KeyLab.GroupQuickUI = Dashboard

return Dashboard
