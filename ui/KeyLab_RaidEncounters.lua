-- KeyLab_RaidEncounters.lua
-- Raid boss pull history using the same compact, paged layout as M+ Encounters.

local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Tabs = KeyLab.Tabs or {}
local RaidEncounters = {}
KeyLab.Tabs.RaidEncounters = RaidEncounters

local RaidAnalysis = KeyLab.RaidAnalysis or {}
local EncounterData = KeyLab.Analysis and KeyLab.Analysis.EncounterData or {}
local SPACING = KeyLab.UI and KeyLab.UI.Theme and KeyLab.UI.Theme.spacing or { compactCard = 8, section = 18 }
local HEADER = KeyLab.UI and KeyLab.UI.Theme and KeyLab.UI.Theme.tabHeader or { x = 18, titleY = -18, titleSize = 16, analysisControlsY = -86, analysisContentY = -172 }

local CFG = {
    pageSize = 5,
    colors = {
        bg = { 0.018, 0.026, 0.056, 0.96 },
        controlBg = { 0.026, 0.046, 0.088, 0.94 },
        cardBg = { 0.030, 0.052, 0.098, 0.94 },
        cardBorder = { 0.240, 0.380, 0.620, 0.62 },
        cardHoverBorder = { 0.300, 0.420, 0.600, 0.78 },
        cardSelectedBorder = { 0.620, 0.560, 0.410, 0.78 },
        detailBg = { 0.024, 0.042, 0.082, 0.96 },
        detailBorder = { 0.220, 0.340, 0.560, 0.56 },
        text = { 0.940, 0.960, 0.990, 1.0 },
        muted = { 0.680, 0.730, 0.820, 1.0 },
        soft = { 0.780, 0.830, 0.900, 1.0 },
        gold = { 0.820, 0.760, 0.580, 1.0 },
        green = { 0.430, 0.820, 0.520, 1.0 },
        red = { 0.900, 0.430, 0.430, 1.0 },
        divider = { 0.440, 0.580, 0.780, 0.32 },
    },
    controls = {
        x = 12, y = HEADER.analysisControlsY, width = 928, height = 74,
        bossX = 18, bossWidth = 210,
        difficultyX = 270, difficultyWidth = 130,
        specX = 460, specWidth = 150,
        dateX = 670, dateWidth = 150,
        labelY = -12,
    },
    list = { x = 12, y = HEADER.analysisContentY, width = 928 },
    card = {
        width = 928, height = 44, gap = SPACING.compactCard,
        numberX = 12, bossX = 50, resultX = 420, specX = 570, dateX = 720,
    },
    details = {
        x = 12, width = 928, height = 300, gapAfterCards = SPACING.section, padding = 14,
        colPullX = 16, colPullW = 175,
        colStatsX = 205, colStatsW = 200,
        colTalentX = 430, colTalentW = 190,
        colOutcomesX = 645, colOutcomesW = 245,
        rowHeight = 15,
    },
    pager = {
        y = 18, labelX = 18, labelWidth = 360,
        prevX = 680, nextX = 780, buttonWidth = 90, buttonHeight = 24,
    },
}

local function ApplyColor(font, color)
    if font and color then font:SetTextColor(color[1], color[2], color[3], color[4] or 1) end
end

local function StylePanel(frame, background, border)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        edgeSize = 1,
    })
    frame:SetBackdropColor(background[1], background[2], background[3], background[4] or 1)
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
end

local function SetBorder(frame, border)
    if frame and border then frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1) end
end

local function AddFont(parent, value, template, x, y, width)
    local font = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    font:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    font:SetWidth(width or 700)
    font:SetJustifyH("LEFT")
    font:SetJustifyV("TOP")
    font:SetWordWrap(false)
    font:SetText(value or "")
    return font
end

local function AddSectionTitle(parent, value, x, y, width)
    local font = AddFont(parent, value, "GameFontNormal", x, y, width)
    ApplyColor(font, CFG.colors.gold)
    return font
end

local function AddVerticalDivider(parent, x, y, height)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    line:SetSize(1, height)
    local color = CFG.colors.divider
    line:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
end

local function ClearChildren(frame)
    for _, child in ipairs({ frame:GetChildren() }) do child:Hide(); child:SetParent(nil) end
    for _, region in ipairs({ frame:GetRegions() }) do region:Hide() end
end

local function SafeNumber(value)
    local number = tonumber(value)
    if number == nil or number ~= number then return nil end
    return number
end

local function FormatDateTime(value)
    if KeyLab.Formatters and KeyLab.Formatters.DateTime then return KeyLab.Formatters.DateTime(value) end
    local timestamp = SafeNumber(value)
    return timestamp and date("%b %d, %Y %I:%M %p", timestamp) or "-"
end

local function FormatDuration(value)
    if KeyLab.Formatters and KeyLab.Formatters.Duration then return KeyLab.Formatters.Duration(value) end
    value = SafeNumber(value)
    if not value then return "-" end
    return string.format("%d:%02d", math.floor(value / 60), math.floor(value % 60))
end

local function FormatStat(statKey, value)
    if KeyLab.Formatters and KeyLab.Formatters.Stat then return KeyLab.Formatters.Stat(statKey, value) end
    return SafeNumber(value) and string.format("%.1f", value) or "-"
end

local function FormatMetric(metricKey, value)
    if KeyLab.Formatters and KeyLab.Formatters.Metric then return KeyLab.Formatters.Metric(metricKey, value) end
    value = SafeNumber(value)
    if not value then return "-" end
    local absolute = math.abs(value)
    if absolute >= 1000000000 then return string.format("%.2fB", value / 1000000000) end
    if absolute >= 1000000 then return string.format("%.2fM", value / 1000000) end
    if absolute >= 1000 then return string.format("%.1fK", value / 1000) end
    return string.format("%.0f", value)
end

local function SetDropdownText(dropdown, value)
    UIDropDownMenu_SetText(dropdown, value or "All")
end

local function MakeDropdown(parent, width, x, y, labelText, initialize)
    local label = AddFont(parent, labelText, "GameFontDisableSmall", x, y, width)
    ApplyColor(label, CFG.colors.muted)
    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", x - 18, y - 18)
    UIDropDownMenu_SetWidth(dropdown, width)
    UIDropDownMenu_Initialize(dropdown, initialize)
    return dropdown
end

local function AllEncounters()
    return RaidAnalysis.GetEncounters and RaidAnalysis.GetEncounters() or {}
end

local function GetRaid(encounter)
    return type(encounter) == "table" and type(encounter.raid) == "table" and encounter.raid or {}
end

local function GetSpec(encounter)
    if RaidAnalysis.GetSpecName then return RaidAnalysis.GetSpecName(encounter) end
    local player = type(encounter) == "table" and encounter.player or {}
    return player.spec or player.specName or "Unknown Spec"
end

local function GetClass(encounter)
    local player = type(encounter) == "table" and encounter.player or {}
    return player.class or player.className or ""
end

local function GetResult(encounter)
    return GetRaid(encounter).killed == true and "Kill" or "Wipe"
end

local function GetPullNumber(encounter)
    return GetRaid(encounter).pullNumber or "?"
end

local function GetMetricValue(encounter, metricKey)
    if EncounterData.GetMetricValue then return EncounterData.GetMetricValue(encounter, metricKey) end
    return SafeNumber(encounter and encounter.metrics and encounter.metrics[metricKey])
end

local function Options(encounters, selectedBoss, selectedDifficulty)
    local bosses = { { value = nil, text = "All Bosses" } }
    local difficulties = { { value = nil, text = "All Difficulties" } }
    local specs = { { value = nil, text = "All Specs" } }
    local bossSeen, difficultySeen, specSeen = {}, {}, {}

    for _, encounter in ipairs(encounters or {}) do
        local raid = GetRaid(encounter)
        local bossID = SafeNumber(raid.encounterID)
        local difficultyID = SafeNumber(raid.difficultyID)
        if bossID and not bossSeen[bossID] then
            bossSeen[bossID] = true
            table.insert(bosses, { value = bossID, text = raid.encounterName or ("Encounter " .. bossID) })
        end
        if not selectedBoss or bossID == selectedBoss then
            if difficultyID and not difficultySeen[difficultyID] then
                difficultySeen[difficultyID] = true
                table.insert(difficulties, { value = difficultyID, text = raid.difficultyName or ("Difficulty " .. difficultyID) })
            end
            if not selectedDifficulty or difficultyID == selectedDifficulty then
                local spec = GetSpec(encounter)
                if spec ~= "Unknown Spec" and not specSeen[spec] then
                    specSeen[spec] = true
                    table.insert(specs, { value = spec, text = spec })
                end
            end
        end
    end

    local function Sort(list)
        table.sort(list, function(a, b)
            if a.value == nil then return true end
            if b.value == nil then return false end
            return tostring(a.text) < tostring(b.text)
        end)
    end
    Sort(bosses); Sort(difficulties); Sort(specs)
    return bosses, difficulties, specs
end

local DATE_OPTIONS = {
    { value = nil, text = "All Dates" },
    { value = "today", text = "Today" },
    { value = "7d", text = "Last 7 Days" },
    { value = "30d", text = "Last 30 Days" },
}

local function DateText(value)
    for _, option in ipairs(DATE_OPTIONS) do if option.value == value then return option.text end end
    return "All Dates"
end

local function StartOfToday()
    local parts = date("*t", time())
    parts.hour, parts.min, parts.sec = 0, 0, 0
    return time(parts)
end

local function MatchesDate(encounter, dateFilter)
    if not dateFilter then return true end
    local timestamp = SafeNumber(encounter and encounter.timestamp)
    if not timestamp then return false end
    if dateFilter == "today" then return timestamp >= StartOfToday() end
    if dateFilter == "7d" then return timestamp >= time() - (7 * 86400) end
    if dateFilter == "30d" then return timestamp >= time() - (30 * 86400) end
    return true
end

local function FilterEncounters(encounters)
    local filtered = {}
    for _, encounter in ipairs(encounters or {}) do
        local raid = GetRaid(encounter)
        local include = not RaidEncounters.selectedEncounterID or SafeNumber(raid.encounterID) == RaidEncounters.selectedEncounterID
        if include and RaidEncounters.selectedDifficultyID then include = SafeNumber(raid.difficultyID) == RaidEncounters.selectedDifficultyID end
        if include and RaidEncounters.selectedSpec then include = GetSpec(encounter) == RaidEncounters.selectedSpec end
        if include then include = MatchesDate(encounter, RaidEncounters.selectedDateFilter) end
        if include then table.insert(filtered, encounter) end
    end
    table.sort(filtered, function(a, b) return (SafeNumber(a.timestamp) or 0) > (SafeNumber(b.timestamp) or 0) end)
    return filtered
end

local function HasOption(options, value)
    for _, option in ipairs(options or {}) do if option.value == value then return true end end
    return false
end

local function OptionText(options, value, fallback)
    for _, option in ipairs(options or {}) do if option.value == value then return option.text end end
    return fallback
end

local function AddDetailRow(parent, label, value, x, y, width)
    local labelFont = AddFont(parent, label, "GameFontDisableSmall", x, y, width)
    ApplyColor(labelFont, CFG.colors.muted)
    local valueFont = AddFont(parent, value, "GameFontHighlightSmall", x, y - 13, width)
    ApplyColor(valueFont, CFG.colors.text)
    return y - 35
end

local function AddStatRows(parent, encounter, x, y, width)
    local stats = type(encounter.stats) == "table" and encounter.stats or {}
    local shown = 0
    for _, statKey in ipairs(KeyLab.Mapping and KeyLab.Mapping.StatOrder or {}) do
        local info = KeyLab.Mapping and KeyLab.Mapping.Stats and KeyLab.Mapping.Stats[statKey]
        local value = SafeNumber(stats[statKey])
        if info and info.store == true and value and value > 0 and shown < 13 then
            local row = AddFont(parent, (info.label or statKey) .. ": " .. FormatStat(statKey, value), "GameFontHighlightSmall", x, y, width)
            ApplyColor(row, CFG.colors.text)
            y, shown = y - CFG.details.rowHeight, shown + 1
        end
    end
    if shown == 0 then
        local row = AddFont(parent, "No stat snapshot available", "GameFontDisableSmall", x, y, width)
        ApplyColor(row, CFG.colors.muted)
    end
end

local function AddOutcomeRows(parent, encounter, x, y, width)
    local shown = 0
    local metrics = EncounterData.GetMetricList and EncounterData.GetMetricList() or {}
    for _, info in ipairs(metrics) do
        local value = GetMetricValue(encounter, info.keylabKey)
        if value ~= nil and shown < 13 then
            local row = AddFont(parent, (info.label or info.keylabKey) .. ": " .. FormatMetric(info.keylabKey, value), "GameFontHighlightSmall", x, y, width)
            ApplyColor(row, CFG.colors.text)
            y, shown = y - CFG.details.rowHeight, shown + 1
        end
    end
    if shown == 0 then
        local row = AddFont(parent, "No captured outcomes available", "GameFontDisableSmall", x, y, width)
        ApplyColor(row, CFG.colors.muted)
    end
end

local function BuildDetails(panel, encounter)
    ClearChildren(panel)
    StylePanel(panel, CFG.colors.detailBg, CFG.colors.detailBorder)
    if not encounter then
        local title = AddFont(panel, "Raid Pull Details", "GameFontNormalLarge", 14, -16, 900)
        ApplyColor(title, CFG.colors.gold)
        local body = AddFont(panel, "Select a pull above to view its pull details, stat snapshot, talent string, and captured outcomes.", "GameFontHighlightSmall", 14, -48, 900)
        ApplyColor(body, CFG.colors.muted)
        return
    end

    local raid = GetRaid(encounter)
    local spec = GetSpec(encounter)
    local header = AddFont(panel, spec .. " - Raid Pull Details", "GameFontNormalLarge", 14, -14, 900)
    ApplyColor(header, CFG.colors.gold)
    local subtitle = AddFont(panel, string.format("%s - Pull %s - %s", raid.encounterName or "Boss", tostring(GetPullNumber(encounter)), FormatDateTime(encounter.timestamp)), "GameFontDisableSmall", 14, -38, 900)
    ApplyColor(subtitle, CFG.colors.muted)

    local sectionTop = -76
    AddVerticalDivider(panel, CFG.details.colStatsX - 12, sectionTop + 4, 205)
    AddVerticalDivider(panel, CFG.details.colTalentX - 12, sectionTop + 4, 205)
    AddVerticalDivider(panel, CFG.details.colOutcomesX - 12, sectionTop + 4, 205)

    AddSectionTitle(panel, "Pull Details", CFG.details.colPullX, sectionTop, CFG.details.colPullW)
    local pullY = sectionTop - 24
    pullY = AddDetailRow(panel, "Result", GetResult(encounter), CFG.details.colPullX, pullY, CFG.details.colPullW)
    pullY = AddDetailRow(panel, "Duration", FormatDuration(raid.durationSeconds), CFG.details.colPullX, pullY, CFG.details.colPullW)
    pullY = AddDetailRow(panel, "Difficulty", raid.difficultyName or tostring(raid.difficultyID or "-"), CFG.details.colPullX, pullY, CFG.details.colPullW)
    pullY = AddDetailRow(panel, "Raid-night Pull", tostring(raid.nightPullNumber or "-"), CFG.details.colPullX, pullY, CFG.details.colPullW)

    AddSectionTitle(panel, "Stats (Before Pull)", CFG.details.colStatsX, sectionTop, CFG.details.colStatsW)
    AddStatRows(panel, encounter, CFG.details.colStatsX, sectionTop - 24, CFG.details.colStatsW)

    AddSectionTitle(panel, "Talent String", CFG.details.colTalentX, sectionTop, CFG.details.colTalentW)
    local talentString = encounter.talents and encounter.talents.talentString or ""
    if talentString ~= "" then
        local editBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
        editBox:SetPoint("TOPLEFT", panel, "TOPLEFT", CFG.details.colTalentX + 4, sectionTop - 26)
        editBox:SetSize(CFG.details.colTalentW - 8, 30)
        editBox:SetAutoFocus(false)
        editBox:SetFontObject("GameFontHighlightSmall")
        editBox:SetText(talentString)
        editBox:SetCursorPosition(0)
        editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        local copy = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        copy:SetSize(72, 22)
        copy:SetPoint("TOPLEFT", panel, "TOPLEFT", CFG.details.colTalentX + 4, sectionTop - 62)
        copy:SetText("Copy")
        copy:SetScript("OnClick", function() editBox:SetFocus(); editBox:HighlightText() end)
        local hint = AddFont(panel, "Click Copy, then Ctrl+C.", "GameFontDisableSmall", CFG.details.colTalentX + 4, sectionTop - 90, CFG.details.colTalentW - 8)
        ApplyColor(hint, CFG.colors.muted)
    else
        local none = AddFont(panel, "No talent string captured", "GameFontDisableSmall", CFG.details.colTalentX, sectionTop - 26, CFG.details.colTalentW)
        ApplyColor(none, CFG.colors.muted)
    end

    AddSectionTitle(panel, "Captured Outcomes", CFG.details.colOutcomesX, sectionTop, CFG.details.colOutcomesW)
    AddOutcomeRows(panel, encounter, CFG.details.colOutcomesX, sectionTop - 24, CFG.details.colOutcomesW)
end

local function CreatePullCard(parent, encounter, displayIndex)
    local raid = GetRaid(encounter)
    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    card:SetSize(CFG.card.width, CFG.card.height)
    StylePanel(card, CFG.colors.cardBg, CFG.colors.cardBorder)
    card.encounter = encounter

    local number = AddFont(card, tostring(displayIndex) .. ".", "GameFontNormal", CFG.card.numberX, -13, 30)
    ApplyColor(number, CFG.colors.gold)
    local boss = AddFont(card, string.format("%s - Pull %s", raid.encounterName or "Boss", tostring(GetPullNumber(encounter))), "GameFontNormal", CFG.card.bossX, -12, 355)
    ApplyColor(boss, CFG.colors.text)
    local result = AddFont(card, string.format("%s - %s", GetResult(encounter), FormatDuration(raid.durationSeconds)), "GameFontHighlightSmall", CFG.card.resultX, -14, 130)
    ApplyColor(result, raid.killed == true and CFG.colors.green or CFG.colors.red)
    local spec = AddFont(card, GetSpec(encounter), "GameFontDisableSmall", CFG.card.specX, -14, 135)
    ApplyColor(spec, CFG.colors.muted)
    local dateFont = AddFont(card, FormatDateTime(encounter.timestamp), "GameFontDisableSmall", CFG.card.dateX, -14, 190)
    dateFont:SetJustifyH("RIGHT")
    ApplyColor(dateFont, CFG.colors.soft)

    card:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then RaidEncounters.selectedEncounter = encounter; RaidEncounters:RefreshSelection() end
    end)
    card:SetScript("OnEnter", function(self)
        if self.encounter ~= RaidEncounters.selectedEncounter then SetBorder(self, CFG.colors.cardHoverBorder) end
    end)
    card:SetScript("OnLeave", function(self)
        if self.encounter ~= RaidEncounters.selectedEncounter then SetBorder(self, CFG.colors.cardBorder) end
    end)
    return card
end

function RaidEncounters:ClearCards()
    for _, card in ipairs(self.cards or {}) do card:Hide(); card:SetParent(nil) end
    self.cards = {}
end

function RaidEncounters:RefreshSelection()
    for _, card in ipairs(self.cards or {}) do
        SetBorder(card, card.encounter == self.selectedEncounter and CFG.colors.cardSelectedBorder or CFG.colors.cardBorder)
    end
    BuildDetails(self.detailPanel, self.selectedEncounter)
end

function RaidEncounters:RefreshOptions()
    self.allEncounters = AllEncounters()
    self.bossOptions, self.difficultyOptions, self.specOptions = Options(self.allEncounters, self.selectedEncounterID, self.selectedDifficultyID)
    if not HasOption(self.bossOptions, self.selectedEncounterID) then
        self.selectedEncounterID, self.selectedDifficultyID, self.selectedSpec = nil, nil, nil
        self.bossOptions, self.difficultyOptions, self.specOptions = Options(self.allEncounters, nil, nil)
    elseif not HasOption(self.difficultyOptions, self.selectedDifficultyID) then
        self.selectedDifficultyID, self.selectedSpec = nil, nil
        self.bossOptions, self.difficultyOptions, self.specOptions = Options(self.allEncounters, self.selectedEncounterID, nil)
    elseif not HasOption(self.specOptions, self.selectedSpec) then
        self.selectedSpec = nil
    end
    SetDropdownText(self.bossDropdown, OptionText(self.bossOptions, self.selectedEncounterID, "All Bosses"))
    SetDropdownText(self.difficultyDropdown, OptionText(self.difficultyOptions, self.selectedDifficultyID, "All Difficulties"))
    SetDropdownText(self.specDropdown, OptionText(self.specOptions, self.selectedSpec, "All Specs"))
    SetDropdownText(self.dateDropdown, DateText(self.selectedDateFilter))
end

function RaidEncounters:Refresh()
    if not self.frame then return end
    self:ClearCards()
    self:RefreshOptions()
    self.filteredEncounters = FilterEncounters(self.allEncounters)
    local total = #self.filteredEncounters
    local totalPages = math.max(1, math.ceil(total / CFG.pageSize))
    self.currentPage = math.max(1, math.min(self.currentPage or 1, totalPages))

    if total == 0 then
        self.emptyText:Show()
        self.summaryText:SetText("No raid boss pulls found for these filters.")
        self.pageText:SetText("Page 0 / 0")
        self.prevButton:Disable(); self.nextButton:Disable()
        self.selectedEncounter = nil
        self:RefreshSelection()
        return
    end

    self.emptyText:Hide()
    local first = ((self.currentPage - 1) * CFG.pageSize) + 1
    local last = math.min(total, first + CFG.pageSize - 1)
    self.summaryText:SetText(string.format("%d boss pull%s found - showing %d-%d", total, total == 1 and "" or "s", first, last))
    self.pageText:SetText(string.format("Page %d / %d", self.currentPage, totalPages))
    if self.currentPage <= 1 then self.prevButton:Disable() else self.prevButton:Enable() end
    if self.currentPage >= totalPages then self.nextButton:Disable() else self.nextButton:Enable() end

    for index = first, last do
        local encounter = self.filteredEncounters[index]
        local card = CreatePullCard(self.frame, encounter, index)
        card:SetPoint("TOPLEFT", self.frame, "TOPLEFT", CFG.list.x, CFG.list.y - ((index - first) * (CFG.card.height + CFG.card.gap)))
        table.insert(self.cards, card)
    end

    local selectedVisible = false
    for _, card in ipairs(self.cards) do if card.encounter == self.selectedEncounter then selectedVisible = true end end
    if not selectedVisible then self.selectedEncounter = self.filteredEncounters[first] end
    self:RefreshSelection()
end

function RaidEncounters:Create(parent)
    if self.frame then return self.frame end
    local frame = CreateFrame("Frame", "KeyLabRaidEncountersTab", parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    StylePanel(frame, CFG.colors.bg, { 0, 0, 0, 0 })
    self.frame, self.cards, self.currentPage = frame, {}, 1

    local title = AddFont(frame, "Raid Encounters", "GameFontNormalLarge", HEADER.x, HEADER.titleY, 500)
    title:SetFont(STANDARD_TEXT_FONT, HEADER.titleSize, "")
    ApplyColor(title, CFG.colors.gold)
    local subtitle = AddFont(frame, "Review saved raid boss pulls. Select a pull to view its captured details below.", "GameFontHighlightSmall", 18, -47, 900)
    ApplyColor(subtitle, CFG.colors.muted)
    self.summaryText = AddFont(frame, "Loading raid pulls...", "GameFontDisableSmall", 18, -70, 900)
    ApplyColor(self.summaryText, CFG.colors.soft)

    local controls = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    controls:SetPoint("TOPLEFT", frame, "TOPLEFT", CFG.controls.x, CFG.controls.y)
    controls:SetSize(CFG.controls.width, CFG.controls.height)
    StylePanel(controls, CFG.colors.controlBg, CFG.colors.cardBorder)

    self.bossDropdown = MakeDropdown(controls, CFG.controls.bossWidth, CFG.controls.bossX, CFG.controls.labelY, "Boss", function(_, level)
        for _, option in ipairs(RaidEncounters.bossOptions or {}) do
            local value = option.value
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.checked = option.text, value == RaidEncounters.selectedEncounterID
            info.func = function()
                RaidEncounters.selectedEncounterID, RaidEncounters.selectedDifficultyID, RaidEncounters.selectedSpec = value, nil, nil
                RaidEncounters.currentPage, RaidEncounters.selectedEncounter = 1, nil
                RaidEncounters:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    self.difficultyDropdown = MakeDropdown(controls, CFG.controls.difficultyWidth, CFG.controls.difficultyX, CFG.controls.labelY, "Difficulty", function(_, level)
        for _, option in ipairs(RaidEncounters.difficultyOptions or {}) do
            local value = option.value
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.checked = option.text, value == RaidEncounters.selectedDifficultyID
            info.func = function()
                RaidEncounters.selectedDifficultyID, RaidEncounters.selectedSpec = value, nil
                RaidEncounters.currentPage, RaidEncounters.selectedEncounter = 1, nil
                RaidEncounters:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    self.specDropdown = MakeDropdown(controls, CFG.controls.specWidth, CFG.controls.specX, CFG.controls.labelY, "Spec", function(_, level)
        for _, option in ipairs(RaidEncounters.specOptions or {}) do
            local value = option.value
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.checked = option.text, value == RaidEncounters.selectedSpec
            info.func = function()
                RaidEncounters.selectedSpec, RaidEncounters.currentPage, RaidEncounters.selectedEncounter = value, 1, nil
                RaidEncounters:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    self.dateDropdown = MakeDropdown(controls, CFG.controls.dateWidth, CFG.controls.dateX, CFG.controls.labelY, "Date", function(_, level)
        for _, option in ipairs(DATE_OPTIONS) do
            local value = option.value
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.checked = option.text, value == RaidEncounters.selectedDateFilter
            info.func = function()
                RaidEncounters.selectedDateFilter, RaidEncounters.currentPage, RaidEncounters.selectedEncounter = value, 1, nil
                RaidEncounters:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    self.emptyText = AddFont(frame, "No raid boss pulls have been captured yet.", "GameFontHighlight", CFG.list.x, CFG.list.y, CFG.list.width)
    ApplyColor(self.emptyText, CFG.colors.text)
    self.emptyText:Hide()

    local reservedListHeight = (CFG.pageSize * CFG.card.height) + ((CFG.pageSize - 1) * CFG.card.gap)
    self.detailPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    self.detailPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", CFG.details.x, CFG.list.y - reservedListHeight - CFG.details.gapAfterCards)
    self.detailPanel:SetSize(CFG.details.width, CFG.details.height)
    StylePanel(self.detailPanel, CFG.colors.detailBg, CFG.colors.detailBorder)

    self.pageText = AddFont(frame, "Page 1 / 1", "GameFontDisableSmall", CFG.pager.labelX, -780, CFG.pager.labelWidth)
    self.pageText:ClearAllPoints()
    self.pageText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", CFG.pager.labelX, CFG.pager.y)
    ApplyColor(self.pageText, CFG.colors.muted)

    self.prevButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    self.prevButton:SetSize(CFG.pager.buttonWidth, CFG.pager.buttonHeight)
    self.prevButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", CFG.pager.prevX, CFG.pager.y)
    self.prevButton:SetText("Back")
    self.prevButton:SetScript("OnClick", function()
        RaidEncounters.currentPage = math.max(1, (RaidEncounters.currentPage or 1) - 1)
        RaidEncounters.selectedEncounter = nil
        RaidEncounters:Refresh()
    end)
    self.nextButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    self.nextButton:SetSize(CFG.pager.buttonWidth, CFG.pager.buttonHeight)
    self.nextButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", CFG.pager.nextX, CFG.pager.y)
    self.nextButton:SetText("Next")
    self.nextButton:SetScript("OnClick", function()
        RaidEncounters.currentPage = (RaidEncounters.currentPage or 1) + 1
        RaidEncounters.selectedEncounter = nil
        RaidEncounters:Refresh()
    end)

    frame.Refresh = function() RaidEncounters:Refresh() end
    frame:SetScript("OnShow", function() RaidEncounters:Refresh() end)
    return frame
end

if KeyLab.RegisterTab then
    KeyLab.RegisterTab("Raid Encounters", function(parent) return RaidEncounters:Create(parent) end)
end

return RaidEncounters
