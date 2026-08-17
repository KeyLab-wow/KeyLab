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
local Theme = KeyLab.UI and KeyLab.UI.Theme or {}
local SPACING = Theme.spacing or { compactCard = 8, section = 18 }
local HEADER = Theme.tabHeader or { x = 18, titleY = -18, titleSize = 16, analysisControlsY = -86, analysisContentY = -172 }
local LAYOUT = Theme.analysisLayout or { outerX = 12, width = 928, filterY = -86, filterHeight = 96, filterLabelY = -36, resultsY = -196, detailsY = -466, detailsHeight = 300 }

local CFG = {
    pageSize = 5,
    colors = Theme.analysisColors or {
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
        crit = { 0.840, 0.440, 0.420, 0.95 },
        haste = { 0.840, 0.720, 0.420, 0.95 },
        mastery = { 0.500, 0.680, 0.940, 0.95 },
        versatility = { 0.460, 0.780, 0.500, 0.95 },
    },
    controls = {
        x = LAYOUT.outerX, y = LAYOUT.filterY, width = LAYOUT.width, height = LAYOUT.filterHeight,
        bossX = 18, bossWidth = 150,
        difficultyX = 188, difficultyWidth = 100,
        currentSpecX = 308, currentSpecWidth = 110,
        dateX = 430, dateWidth = 105,
        metricX = 552, metricWidth = 145,
        sortX = 742, sortWidth = 130,
        labelY = LAYOUT.filterLabelY,
    },
    list = { x = LAYOUT.outerX, y = LAYOUT.resultsY, width = LAYOUT.width },
    card = {
        width = 928, height = 44, gap = SPACING.compactCard,
        numberX = 12, bossX = 50, resultX = 420, specX = 570, dateX = 720,
    },
    details = {
        x = LAYOUT.outerX, y = LAYOUT.detailsY, width = LAYOUT.width, height = LAYOUT.detailsHeight, gapAfterCards = SPACING.section, padding = 14,
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
    if Theme.ApplyColor then Theme.ApplyColor(font, color); return end
    if font and color then font:SetTextColor(color[1], color[2], color[3], color[4] or 1) end
end

local function StylePanel(frame, background, border)
    if Theme.StylePanel then Theme.StylePanel(frame, background, border); return end
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
    local font = Theme.CreateText and Theme.CreateText(parent, value, template or "GameFontNormal", nil, CFG.colors.text)
        or parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    font:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    font:SetWidth(width or 700)
    font:SetJustifyH("LEFT")
    font:SetJustifyV("TOP")
    font:SetWordWrap(false)
    if not Theme.CreateText then font:SetText(value or "") end
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
    local dropdown = KeyLab.UI.Theme.CreateLegacyDropdown(parent)
    KeyLab.UI.Theme.StyleAnalysisFilterDropdown(dropdown)
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

local function GetCurrentSpecName()
    local specIndex = GetSpecialization and GetSpecialization()
    if specIndex and GetSpecializationInfo then
        local _, specName = GetSpecializationInfo(specIndex)
        if specName and specName ~= "" then
            return specName
        end
    end
    return nil
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

local function MetricOptions()
    local options = {}
    for _, metricType in ipairs(KeyLab.Mapping and KeyLab.Mapping.MetricOrder or {}) do
        local info = EncounterData.GetMetricInfoByType and EncounterData.GetMetricInfoByType(metricType)
            or KeyLab.Mapping and KeyLab.Mapping.Metrics and KeyLab.Mapping.Metrics[metricType]
        if info and info.store == true and info.keylabKey then
            table.insert(options, { value = info.keylabKey, text = info.label or info.keylabKey })
        end
    end
    return options
end

local function MetricText(value)
    for _, option in ipairs(MetricOptions()) do if option.value == value then return option.text end end
    return "DPS"
end

local function Options(encounters, selectedBoss, selectedDifficulty)
    local bosses = { { value = nil, text = "All Bosses" } }
    local difficulties = { { value = nil, text = "All Difficulties" } }
    local bossSeen, difficultySeen = {}, {}

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
        end
    end

    local function Sort(list)
        table.sort(list, function(a, b)
            if a.value == nil then return true end
            if b.value == nil then return false end
            return tostring(a.text) < tostring(b.text)
        end)
    end
    Sort(bosses); Sort(difficulties)
    return bosses, difficulties
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
        if include and RaidEncounters.currentSpecName then include = GetSpec(encounter) == RaidEncounters.currentSpecName end
        if include then include = MatchesDate(encounter, RaidEncounters.selectedDateFilter) end
        if include then table.insert(filtered, encounter) end
    end
    table.sort(filtered, function(a, b)
        local av = SafeNumber(GetMetricValue(a, RaidEncounters.selectedMetricKey))
        local bv = SafeNumber(GetMetricValue(b, RaidEncounters.selectedMetricKey))
        if av == nil or bv == nil then
            if av == nil and bv == nil then return (SafeNumber(a.timestamp) or 0) > (SafeNumber(b.timestamp) or 0) end
            return av ~= nil
        end
        if av == bv then return (SafeNumber(a.timestamp) or 0) > (SafeNumber(b.timestamp) or 0) end
        if RaidEncounters.selectedSortDirection == "low" then return av < bv end
        return av > bv
    end)
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

local function GetStatColor(statKey)
    return CFG.colors[statKey] or CFG.colors.text
end

local function AddStatRows(parent, encounter, x, y, width)
    local stats = type(encounter.stats) == "table" and encounter.stats or {}
    local shown = 0
    for _, statKey in ipairs(KeyLab.Mapping and KeyLab.Mapping.StatOrder or {}) do
        local info = KeyLab.Mapping and KeyLab.Mapping.Stats and KeyLab.Mapping.Stats[statKey]
        local value = SafeNumber(stats[statKey])
        if info and info.store == true and value and value > 0 and shown < 13 then
            local row = AddFont(parent, (info.label or statKey) .. ": " .. FormatStat(statKey, value), "GameFontHighlightSmall", x, y, width)
            ApplyColor(row, GetStatColor(statKey))
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
    if Theme.StyleAnalysisDetails then Theme.StyleAnalysisDetails(panel) else StylePanel(panel, CFG.colors.detailBg, CFG.colors.detailBorder) end
    if not encounter then
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
    pullY = AddDetailRow(panel, "Raid-session Pull", tostring(raid.nightPullNumber or "-"), CFG.details.colPullX, pullY, CFG.details.colPullW)

    AddSectionTitle(panel, "Stats (Before Pull)", CFG.details.colStatsX, sectionTop, CFG.details.colStatsW)
    AddStatRows(panel, encounter, CFG.details.colStatsX, sectionTop - 24, CFG.details.colStatsW)

    AddSectionTitle(panel, "Talent String", CFG.details.colTalentX, sectionTop, CFG.details.colTalentW)
    local talentString = encounter.talents and encounter.talents.talentString or ""
    if talentString ~= "" then
        local editBox = Theme.CreateInput and Theme.CreateInput(panel, CFG.details.colTalentW - 8, 30)
            or CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
        editBox:SetPoint("TOPLEFT", panel, "TOPLEFT", CFG.details.colTalentX + 4, sectionTop - 26)
        editBox:SetSize(CFG.details.colTalentW - 8, 30)
        editBox:SetAutoFocus(false)
        editBox:SetFontObject("GameFontHighlightSmall")
        editBox:SetText(talentString)
        editBox:SetCursorPosition(0)
        editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        local copy = Theme.CreateButton and Theme.CreateButton(panel, "Copy", 72, 22)
            or CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
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
    if Theme.StyleAnalysisRow then Theme.StyleAnalysisRow(card, "normal") else StylePanel(card, CFG.colors.cardBg, CFG.colors.cardBorder) end
    card.encounter = encounter

    local number = AddFont(card, Theme.FormatRank and Theme.FormatRank(displayIndex) or tostring(displayIndex), "GameFontNormal", CFG.card.numberX, -13, 30)
    card.rankText = number
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
        if self.encounter ~= RaidEncounters.selectedEncounter then
            if Theme.StyleAnalysisRow then Theme.StyleAnalysisRow(self, "hover") else SetBorder(self, CFG.colors.cardHoverBorder) end
        end
    end)
    card:SetScript("OnLeave", function(self)
        if self.encounter ~= RaidEncounters.selectedEncounter then
            if Theme.StyleAnalysisRow then Theme.StyleAnalysisRow(self, "normal") else SetBorder(self, CFG.colors.cardBorder) end
        end
    end)
    return card
end

function RaidEncounters:ClearCards()
    for _, card in ipairs(self.cards or {}) do card:Hide(); card:SetParent(nil) end
    self.cards = {}
end

function RaidEncounters:RefreshSelection()
    for _, card in ipairs(self.cards or {}) do
        local selected = card.encounter == self.selectedEncounter
        if Theme.StyleAnalysisRow then
            Theme.StyleAnalysisRow(card, selected and "selected" or "normal")
        else
            SetBorder(card, selected and CFG.colors.cardSelectedBorder or CFG.colors.cardBorder)
        end
    end
    BuildDetails(self.detailPanel, self.selectedEncounter)
end

function RaidEncounters:RefreshOptions()
    self.allEncounters = AllEncounters()
    self.currentSpecName = GetCurrentSpecName()

    local currentSpecEncounters = {}
    for _, encounter in ipairs(self.allEncounters or {}) do
        if not self.currentSpecName or GetSpec(encounter) == self.currentSpecName then
            table.insert(currentSpecEncounters, encounter)
        end
    end

    self.bossOptions, self.difficultyOptions = Options(currentSpecEncounters, self.selectedEncounterID, self.selectedDifficultyID)
    if not HasOption(self.bossOptions, self.selectedEncounterID) then
        self.selectedEncounterID, self.selectedDifficultyID = nil, nil
        self.bossOptions, self.difficultyOptions = Options(currentSpecEncounters, nil, nil)
    elseif not HasOption(self.difficultyOptions, self.selectedDifficultyID) then
        self.selectedDifficultyID = nil
        self.bossOptions, self.difficultyOptions = Options(currentSpecEncounters, self.selectedEncounterID, nil)
    end
    SetDropdownText(self.bossDropdown, OptionText(self.bossOptions, self.selectedEncounterID, "All Bosses"))
    SetDropdownText(self.difficultyDropdown, OptionText(self.difficultyOptions, self.selectedDifficultyID, "All Difficulties"))
    self.specValue:SetText(self.currentSpecName or "No Specialization")
    SetDropdownText(self.dateDropdown, DateText(self.selectedDateFilter))
    self.selectedMetricKey = self.selectedMetricKey or "dps"
    self.selectedSortDirection = self.selectedSortDirection or "high"
    SetDropdownText(self.metricDropdown, MetricText(self.selectedMetricKey))
    SetDropdownText(self.sortDropdown, self.selectedSortDirection == "low" and "Low to High" or "High to Low")
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
        self.emptyText:Hide()
        self.summaryText:SetText("No raid boss pulls found for this specialization and these filters.")
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
    if Theme.StyleAnalysisPage then Theme.StyleAnalysisPage(frame) else StylePanel(frame, CFG.colors.bg, { 0, 0, 0, 0 }) end
    self.frame, self.cards, self.currentPage = frame, {}, 1

    local page = Theme.CreateAnalysisPage(
        frame,
        "Raid Encounters",
        "Review your saved raid boss pulls and select one to see its details.",
        { summaryText = "Loading raid pulls...", detailsHeight = CFG.details.height }
    )
    self.summaryText = page.summaryText
    local controls = page.filterHeaderCard
    local filterX = Theme.GetFilterPositions({
        CFG.controls.bossWidth, CFG.controls.difficultyWidth, CFG.controls.currentSpecWidth,
        CFG.controls.dateWidth, CFG.controls.metricWidth, CFG.controls.sortWidth,
    }, { cardWidth = CFG.controls.width })
    CFG.controls.bossX, CFG.controls.difficultyX, CFG.controls.currentSpecX,
        CFG.controls.dateX, CFG.controls.metricX, CFG.controls.sortX = unpack(filterX)

    self.bossDropdown = MakeDropdown(controls, CFG.controls.bossWidth, CFG.controls.bossX, CFG.controls.labelY, "Boss", function(_, level)
        for _, option in ipairs(RaidEncounters.bossOptions or {}) do
            local value = option.value
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.checked = option.text, value == RaidEncounters.selectedEncounterID
            info.func = function()
                RaidEncounters.selectedEncounterID, RaidEncounters.selectedDifficultyID = value, nil
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
                RaidEncounters.selectedDifficultyID = value
                RaidEncounters.currentPage, RaidEncounters.selectedEncounter = 1, nil
                RaidEncounters:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    local specLabel = AddFont(controls, "Current Spec", "GameFontDisableSmall", CFG.controls.currentSpecX, CFG.controls.labelY, CFG.controls.currentSpecWidth)
    ApplyColor(specLabel, CFG.colors.muted)
    self.specValue = AddFont(controls, "Loading...", "GameFontHighlightSmall", CFG.controls.currentSpecX, CFG.controls.labelY - 26, CFG.controls.currentSpecWidth)
    ApplyColor(self.specValue, CFG.colors.text)
    if Theme.CreateFieldUnderline then Theme.CreateFieldUnderline(controls, CFG.controls.currentSpecX, CFG.controls.labelY, CFG.controls.currentSpecWidth, CFG.colors.gold) end
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
    self.metricDropdown = MakeDropdown(controls, CFG.controls.metricWidth, CFG.controls.metricX, CFG.controls.labelY, "Performance Metric", function(_, level)
        for _, option in ipairs(MetricOptions()) do
            local value = option.value
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.checked = option.text, value == RaidEncounters.selectedMetricKey
            info.func = function()
                RaidEncounters.selectedMetricKey, RaidEncounters.currentPage, RaidEncounters.selectedEncounter = value, 1, nil
                RaidEncounters:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    self.sortDropdown = MakeDropdown(controls, CFG.controls.sortWidth, CFG.controls.sortX, CFG.controls.labelY, "Sort", function(_, level)
        for _, option in ipairs({
            { value = "high", text = "High to Low" },
            { value = "low", text = "Low to High" },
        }) do
            local value = option.value
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.checked = option.text, value == RaidEncounters.selectedSortDirection
            info.func = function()
                RaidEncounters.selectedSortDirection, RaidEncounters.currentPage, RaidEncounters.selectedEncounter = value, 1, nil
                RaidEncounters:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    self.emptyText = AddFont(page.encountersCards, "", "GameFontHighlight", 0, 0, CFG.list.width)
    self.emptyText:Hide()

    self.detailPanel = page.detailsCard

    local pager = Theme.CreatePager(frame)
    self.pageText, self.prevButton, self.nextButton = pager.pageText, pager.prevButton, pager.nextButton
    self.prevButton:SetScript("OnClick", function()
        RaidEncounters.currentPage = math.max(1, (RaidEncounters.currentPage or 1) - 1)
        RaidEncounters.selectedEncounter = nil
        RaidEncounters:Refresh()
    end)
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
