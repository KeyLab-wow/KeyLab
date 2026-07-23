-- KeyLab_RaidTalentBuilds.lua
-- Raid talent build comparison using the same compact layout as M+ Talent Builds.

local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.UI = KeyLab.UI or {}
KeyLab.Tabs = KeyLab.Tabs or {}

local RaidTalentBuilds = {}
KeyLab.Tabs.RaidTalentBuilds = RaidTalentBuilds
local SPACING = KeyLab.UI and KeyLab.UI.Theme and KeyLab.UI.Theme.spacing or { compactCard = 8, section = 18 }
local HEADER = KeyLab.UI and KeyLab.UI.Theme and KeyLab.UI.Theme.tabHeader or { x = 18, titleY = -18, titleSize = 16, analysisControlsY = -86, analysisContentY = -172 }

local RaidAnalysis = KeyLab.RaidAnalysis or {}
local EncounterData = KeyLab.Analysis and KeyLab.Analysis.EncounterData or {}

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
        divider = { 0.440, 0.580, 0.780, 0.32 },
        barBg = { 0.012, 0.020, 0.044, 0.90 },
        barBorder = { 0.185, 0.300, 0.500, 0.50 },
        barFill = { 0.500, 0.680, 0.940, 0.95 },
        barFillSelected = { 0.820, 0.760, 0.580, 1.0 },
    },
    controls = {
        x = 12, y = HEADER.analysisControlsY, width = 928, height = 74,
        bossX = 18, bossWidth = 185,
        difficultyX = 255, difficultyWidth = 110,
        specX = 410, specWidth = 155,
        outcomeX = 610, outcomeWidth = 180,
        labelY = -12,
    },
    list = { x = 12, y = HEADER.analysisContentY, width = 928 },
    card = {
        width = 928, height = 44, gap = SPACING.compactCard,
        rankX = 12, titleX = 46, valueX = 430, valueWidth = 130,
        barX = 575, barY = -17, barWidth = 335, barHeight = 9,
    },
    details = {
        x = 12, width = 928, height = 300, gapAfterCards = SPACING.section, padding = 14, rowHeight = 15,
        colRunX = 16, colRunW = 170,
        colStatsX = 205, colStatsW = 200,
        colTalentX = 430, colTalentW = 190,
        colOutcomesX = 645, colOutcomesW = 245,
    },
}

local function ApplyColor(font, color)
    if font and color then font:SetTextColor(color[1], color[2], color[3], color[4] or 1) end
end

local function StylePanel(frame, background, border)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", tile = false, edgeSize = 1 })
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
    font:SetWordWrap(true)
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
    line:SetSize(1, height or 225)
    local color = CFG.colors.divider
    line:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
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

local function SetDropdownText(dropdown, value)
    UIDropDownMenu_SetText(dropdown, value or "Select")
end

local function ClearChildren(frame)
    if not frame then return end
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

local function CreateBar(parent, value, maxValue, minValue, lowerIsBetter)
    local background = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    background:SetPoint("TOPLEFT", parent, "TOPLEFT", CFG.card.barX, CFG.card.barY)
    background:SetSize(CFG.card.barWidth, CFG.card.barHeight)
    StylePanel(background, CFG.colors.barBg, CFG.colors.barBorder)

    local number = SafeNumber(value) or 0
    local maximum = SafeNumber(maxValue) or 0
    local minimum = SafeNumber(minValue) or 0
    local ratio = 0
    if maximum > 0 then
        if lowerIsBetter then
            ratio = maximum == minimum and 1 or 1 - ((number - minimum) / (maximum - minimum))
        else
            ratio = number / maximum
        end
    end
    ratio = math.max(0.06, math.min(1, ratio))
    local fill = background:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("LEFT", background, "LEFT", 0, 0)
    fill:SetSize(CFG.card.barWidth * ratio, CFG.card.barHeight - 2)
    local color = CFG.colors.barFill
    fill:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
end

local function Encounters()
    return RaidAnalysis.GetEncounters and RaidAnalysis.GetEncounters() or {}
end

local function Raid(encounter)
    return type(encounter) == "table" and type(encounter.raid) == "table" and encounter.raid or {}
end

local function Spec(encounter)
    if RaidAnalysis.GetSpecName then return RaidAnalysis.GetSpecName(encounter) end
    local player = encounter and encounter.player or {}
    return player.spec or player.specName or "Unknown Spec"
end

local function TalentString(encounter)
    return encounter and encounter.talents and encounter.talents.talentString or ""
end

local function MetricValue(encounter, metricKey)
    if EncounterData.GetMetricValue then return EncounterData.GetMetricValue(encounter, metricKey) end
    return SafeNumber(encounter and encounter.metrics and encounter.metrics[metricKey])
end

local function MetricInfo(metricKey)
    if EncounterData.GetMetricInfoByKey then return EncounterData.GetMetricInfoByKey(metricKey) end
    for _, info in pairs(KeyLab.Mapping and KeyLab.Mapping.Metrics or {}) do
        if info.keylabKey == metricKey and info.store == true then return info end
    end
end

local function MetricLabel(metricKey)
    local info = MetricInfo(metricKey)
    return info and info.label or metricKey or "Outcome"
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

local function BuildOptions(encounters, selectedBoss, selectedDifficulty)
    local bosses = { { value = nil, text = "All Bosses" } }
    local difficulties = { { value = nil, text = "All Difficulties" } }
    local specs = { { value = nil, text = "All Specs" } }
    local bossSeen, difficultySeen, specSeen = {}, {}, {}

    for _, encounter in ipairs(encounters or {}) do
        local raid = Raid(encounter)
        local bossID, difficultyID = SafeNumber(raid.encounterID), SafeNumber(raid.difficultyID)
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
                local spec = Spec(encounter)
                if spec ~= "Unknown Spec" and not specSeen[spec] then
                    specSeen[spec] = true
                    table.insert(specs, { value = spec, text = spec })
                end
            end
        end
    end

    local function Sort(options)
        table.sort(options, function(a, b)
            if a.value == nil then return true end
            if b.value == nil then return false end
            return tostring(a.text) < tostring(b.text)
        end)
    end
    Sort(bosses); Sort(difficulties); Sort(specs)
    return bosses, difficulties, specs
end

local function HasOption(options, value)
    for _, option in ipairs(options or {}) do if option.value == value then return true end end
    return false
end

local function OptionText(options, value, fallback)
    for _, option in ipairs(options or {}) do if option.value == value then return option.text end end
    return fallback
end

local function MatchesFilters(encounter)
    local raid = Raid(encounter)
    if RaidTalentBuilds.selectedEncounterID and SafeNumber(raid.encounterID) ~= RaidTalentBuilds.selectedEncounterID then return false end
    if RaidTalentBuilds.selectedDifficultyID and SafeNumber(raid.difficultyID) ~= RaidTalentBuilds.selectedDifficultyID then return false end
    if RaidTalentBuilds.selectedSpec and Spec(encounter) ~= RaidTalentBuilds.selectedSpec then return false end
    if TalentString(encounter) == "" then return false end
    return MetricValue(encounter, RaidTalentBuilds.selectedMetricKey) ~= nil
end

local function BuildCards()
    local info = MetricInfo(RaidTalentBuilds.selectedMetricKey)
    local higherIsBetter = not (info and info.higherIsBetter == false)
    local groups = {}
    for _, encounter in ipairs(RaidTalentBuilds.allEncounters or {}) do
        if MatchesFilters(encounter) then
            local talentString = TalentString(encounter)
            local group = groups[talentString]
            if not group then
                group = { talentString = talentString, encounters = {}, pullCount = 0, bestEncounter = nil, bestValue = nil, higherIsBetter = higherIsBetter, metricKey = RaidTalentBuilds.selectedMetricKey }
                groups[talentString] = group
            end
            table.insert(group.encounters, encounter)
            group.pullCount = group.pullCount + 1
            local value = MetricValue(encounter, RaidTalentBuilds.selectedMetricKey)
            if group.bestValue == nil or (higherIsBetter and value > group.bestValue) or (not higherIsBetter and value < group.bestValue) then
                group.bestValue, group.bestEncounter = value, encounter
            end
        end
    end

    local cards = {}
    for _, group in pairs(groups) do table.insert(cards, group) end
    table.sort(cards, function(a, b)
        if a.bestValue == b.bestValue then return a.pullCount > b.pullCount end
        if higherIsBetter then return a.bestValue > b.bestValue end
        return a.bestValue < b.bestValue
    end)
    local top = {}
    for index = 1, math.min(CFG.pageSize, #cards) do top[index] = cards[index] end
    return top
end

local function AddDetailRow(parent, label, value, x, y, width)
    local labelFont = AddFont(parent, label, "GameFontDisableSmall", x, y, width)
    ApplyColor(labelFont, CFG.colors.muted)
    local valueFont = AddFont(parent, value, "GameFontHighlightSmall", x, y - 13, width)
    ApplyColor(valueFont, CFG.colors.text)
    return y - 35
end

local function AddStatRows(parent, encounter, x, y, width)
    local stats = encounter and encounter.stats or {}
    local shown, hidden = 0, 0
    for _, statKey in ipairs(KeyLab.Mapping and KeyLab.Mapping.StatOrder or {}) do
        local info = KeyLab.Mapping and KeyLab.Mapping.Stats and KeyLab.Mapping.Stats[statKey]
        local value = SafeNumber(stats[statKey])
        if info and info.store == true and value and value > 0 then
            if shown < 13 then
                local row = AddFont(parent, (info.label or statKey) .. ": " .. FormatStat(statKey, value), "GameFontHighlightSmall", x, y, width)
                ApplyColor(row, CFG.colors.text)
                y, shown = y - CFG.details.rowHeight, shown + 1
            else
                hidden = hidden + 1
            end
        end
    end
    if hidden > 0 then
        local row = AddFont(parent, "+" .. hidden .. " more stats", "GameFontDisableSmall", x, y, width)
        ApplyColor(row, CFG.colors.muted)
    elseif shown == 0 then
        local row = AddFont(parent, "No stat snapshot available", "GameFontDisableSmall", x, y, width)
        ApplyColor(row, CFG.colors.muted)
    end
end

local function AddOutcomeRows(parent, encounter, x, y, width)
    local shown = 0
    for _, metricType in ipairs(KeyLab.Mapping and KeyLab.Mapping.MetricOrder or {}) do
        local info = EncounterData.GetMetricInfoByType and EncounterData.GetMetricInfoByType(metricType)
            or KeyLab.Mapping and KeyLab.Mapping.Metrics and KeyLab.Mapping.Metrics[metricType]
        if info and info.store == true then
            local value = MetricValue(encounter, info.keylabKey)
            if value ~= nil then
                local row = AddFont(parent, (info.label or info.keylabKey) .. ": " .. FormatMetric(info.keylabKey, value), "GameFontHighlightSmall", x, y, width)
                ApplyColor(row, CFG.colors.text)
                y, shown = y - CFG.details.rowHeight, shown + 1
            end
        end
    end
    if shown == 0 then
        local row = AddFont(parent, "No captured outcomes available", "GameFontDisableSmall", x, y, width)
        ApplyColor(row, CFG.colors.muted)
    end
end

local function VariantTitle(cardData, number)
    return "Raid " .. Spec(cardData and cardData.bestEncounter) .. " - Talent Variant " .. tostring(number or 1)
end

local function BuildDetails(panel, cardData, variantNumber)
    ClearChildren(panel)
    StylePanel(panel, CFG.colors.detailBg, CFG.colors.detailBorder)
    if not cardData then
        local title = AddFont(panel, "Talent Build Details", "GameFontNormalLarge", 14, -16, 900)
        ApplyColor(title, CFG.colors.gold)
        local body = AddFont(panel, "Select a build above to see its best saved pull, stats, talent string, and results.", "GameFontHighlightSmall", 14, -48, 900)
        ApplyColor(body, CFG.colors.muted)
        return
    end

    local encounter = cardData.bestEncounter or {}
    local raid = Raid(encounter)
    local header = AddFont(panel, VariantTitle(cardData, variantNumber), "GameFontNormalLarge", 14, -14, 900)
    ApplyColor(header, CFG.colors.gold)
    local subtitle = AddFont(panel, string.format("%s - %s - %s: %s", raid.encounterName or "Unknown Boss", raid.difficultyName or "Unknown Difficulty", MetricLabel(cardData.metricKey), FormatMetric(cardData.metricKey, cardData.bestValue)), "GameFontDisableSmall", 14, -38, 900)
    ApplyColor(subtitle, CFG.colors.muted)

    local sectionTop = -76
    AddVerticalDivider(panel, CFG.details.colStatsX - 12, sectionTop + 4, 205)
    AddVerticalDivider(panel, CFG.details.colTalentX - 12, sectionTop + 4, 205)
    AddVerticalDivider(panel, CFG.details.colOutcomesX - 12, sectionTop + 4, 205)

    AddSectionTitle(panel, "Pull Details", CFG.details.colRunX, sectionTop, CFG.details.colRunW)
    local pullY = sectionTop - 24
    pullY = AddDetailRow(panel, "Date", FormatDateTime(encounter.timestamp), CFG.details.colRunX, pullY, CFG.details.colRunW)
    pullY = AddDetailRow(panel, "Boss", raid.encounterName or "Unknown Boss", CFG.details.colRunX, pullY, CFG.details.colRunW)
    pullY = AddDetailRow(panel, "Pull", tostring(raid.pullNumber or "?"), CFG.details.colRunX, pullY, CFG.details.colRunW)
    pullY = AddDetailRow(panel, "Result", raid.killed and "Kill" or "Wipe", CFG.details.colRunX, pullY, CFG.details.colRunW)
    AddDetailRow(panel, "Duration", FormatDuration(raid.durationSeconds), CFG.details.colRunX, pullY, CFG.details.colRunW)

    AddSectionTitle(panel, "Stats (Before Pull)", CFG.details.colStatsX, sectionTop, CFG.details.colStatsW)
    AddStatRows(panel, encounter, CFG.details.colStatsX, sectionTop - 24, CFG.details.colStatsW)

    AddSectionTitle(panel, "Talent String", CFG.details.colTalentX, sectionTop, CFG.details.colTalentW)
    local talentString = TalentString(encounter)
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

local function CreateBuildCard(parent, cardData, displayIndex, maxValue, minValue)
    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    card:SetSize(CFG.card.width, CFG.card.height)
    StylePanel(card, CFG.colors.cardBg, CFG.colors.cardBorder)
    card.cardData, card.displayIndex = cardData, displayIndex

    local rank = AddFont(card, displayIndex .. ".", "GameFontNormal", CFG.card.rankX, -13, 28)
    ApplyColor(rank, CFG.colors.gold)
    local title = AddFont(card, VariantTitle(cardData, displayIndex), "GameFontNormal", CFG.card.titleX, -12, 370)
    ApplyColor(title, CFG.colors.text)
    local metric = AddFont(card, MetricLabel(RaidTalentBuilds.selectedMetricKey) .. ": " .. FormatMetric(RaidTalentBuilds.selectedMetricKey, cardData.bestValue), "GameFontNormal", CFG.card.valueX, -12, CFG.card.valueWidth)
    metric:SetJustifyH("RIGHT")
    ApplyColor(metric, CFG.colors.soft)
    CreateBar(card, cardData.bestValue, maxValue, minValue, cardData.higherIsBetter == false)

    card:SetScript("OnClick", function()
        RaidTalentBuilds.selectedCardData, RaidTalentBuilds.selectedIndex = cardData, displayIndex
        RaidTalentBuilds:RefreshSelection()
    end)
    card:SetScript("OnEnter", function(self)
        if self.cardData ~= RaidTalentBuilds.selectedCardData then SetBorder(self, CFG.colors.cardHoverBorder) end
    end)
    card:SetScript("OnLeave", function(self)
        if self.cardData ~= RaidTalentBuilds.selectedCardData then SetBorder(self, CFG.colors.cardBorder) end
    end)
    return card
end

function RaidTalentBuilds:ClearCards()
    for _, card in ipairs(self.cards or {}) do card:Hide(); card:SetParent(nil) end
    self.cards = {}
end

function RaidTalentBuilds:RefreshOptions()
    self.allEncounters = Encounters()
    self.bossOptions, self.difficultyOptions, self.specOptions = BuildOptions(self.allEncounters, self.selectedEncounterID, self.selectedDifficultyID)
    if not HasOption(self.bossOptions, self.selectedEncounterID) then
        self.selectedEncounterID, self.selectedDifficultyID, self.selectedSpec = nil, nil, nil
        self.bossOptions, self.difficultyOptions, self.specOptions = BuildOptions(self.allEncounters, nil, nil)
    elseif not HasOption(self.difficultyOptions, self.selectedDifficultyID) then
        self.selectedDifficultyID, self.selectedSpec = nil, nil
        self.bossOptions, self.difficultyOptions, self.specOptions = BuildOptions(self.allEncounters, self.selectedEncounterID, nil)
    elseif not HasOption(self.specOptions, self.selectedSpec) then
        self.selectedSpec = nil
    end

    self.metricOptions = MetricOptions()
    KeyLabDB = type(KeyLabDB) == "table" and KeyLabDB or {}
    KeyLabDB.settings = type(KeyLabDB.settings) == "table" and KeyLabDB.settings or {}
    local savedMetric = KeyLabDB.settings.raidTalentMetric
    if HasOption(self.metricOptions, savedMetric) then self.selectedMetricKey = savedMetric end
    if not HasOption(self.metricOptions, self.selectedMetricKey) then self.selectedMetricKey = HasOption(self.metricOptions, "dps") and "dps" or (self.metricOptions[1] and self.metricOptions[1].value) end
    KeyLabDB.settings.raidTalentMetric = self.selectedMetricKey

    SetDropdownText(self.bossDropdown, OptionText(self.bossOptions, self.selectedEncounterID, "All Bosses"))
    SetDropdownText(self.difficultyDropdown, OptionText(self.difficultyOptions, self.selectedDifficultyID, "All Difficulties"))
    SetDropdownText(self.specDropdown, OptionText(self.specOptions, self.selectedSpec, "All Specs"))
    SetDropdownText(self.outcomeDropdown, MetricLabel(self.selectedMetricKey))
end

function RaidTalentBuilds:RefreshSelection()
    for _, card in ipairs(self.cards or {}) do
        StylePanel(card, CFG.colors.cardBg, card.cardData == self.selectedCardData and CFG.colors.cardSelectedBorder or CFG.colors.cardBorder)
    end
    BuildDetails(self.detailPanel, self.selectedCardData, self.selectedIndex)
    self:LayoutCards()
end

function RaidTalentBuilds:LayoutCards()
    local y = CFG.list.y
    for _, card in ipairs(self.cards or {}) do
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", self.frame, "TOPLEFT", CFG.list.x, y)
        y = y - CFG.card.height - CFG.card.gap
    end
    self.detailPanel:ClearAllPoints()
    self.detailPanel:SetPoint("TOPLEFT", self.frame, "TOPLEFT", CFG.details.x, y - CFG.details.gapAfterCards)
end

function RaidTalentBuilds:Refresh()
    if not self.frame then return end
    self:ClearCards()
    self:RefreshOptions()
    local cards = BuildCards()
    self.buildCards = cards

    local info = MetricInfo(self.selectedMetricKey)
    local direction = info and info.higherIsBetter == false and "lowest" or "highest"
    if #cards == 0 then
        self.summaryText:SetText("No matching raid talent build data found.")
        self.emptyText:Show()
        self.emptyText:SetText("No saved talent builds match these raid filters yet.\n\nComplete more pulls with these filters to add results here.")
        self.selectedCardData, self.selectedIndex = nil, nil
        self:RefreshSelection()
        return
    end

    self.emptyText:Hide()
    self.summaryText:SetText("Top " .. #cards .. " different builds - ranked by " .. direction .. " observed " .. MetricLabel(self.selectedMetricKey))
    local maxValue, minValue = 0, nil
    for _, cardData in ipairs(cards) do
        local value = SafeNumber(cardData.bestValue) or 0
        maxValue = math.max(maxValue, value)
        minValue = minValue == nil and value or math.min(minValue, value)
    end
    for index, cardData in ipairs(cards) do table.insert(self.cards, CreateBuildCard(self.frame, cardData, index, maxValue, minValue or 0)) end

    local visible = false
    for index, cardData in ipairs(cards) do
        if self.selectedCardData and cardData.talentString == self.selectedCardData.talentString then
            self.selectedCardData, self.selectedIndex, visible = cardData, index, true
            break
        end
    end
    if not visible then self.selectedCardData, self.selectedIndex = cards[1], 1 end
    self:RefreshSelection()
end

function RaidTalentBuilds:Create(parent)
    if self.frame then return self.frame end
    local frame = CreateFrame("Frame", "KeyLabRaidTalentBuildsTab", parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    StylePanel(frame, CFG.colors.bg, { 0, 0, 0, 0 })
    self.frame, self.cards, self.selectedMetricKey = frame, {}, "dps"

    local title = AddFont(frame, "Raid Talent Builds", "GameFontNormalLarge", HEADER.x, HEADER.titleY, 500)
    title:SetFont(STANDARD_TEXT_FONT, HEADER.titleSize, "")
    ApplyColor(title, CFG.colors.gold)
    local subtitle = AddFont(frame, "Compare the talent builds you used for the selected raid boss.", "GameFontHighlightSmall", 18, -47, 900)
    ApplyColor(subtitle, CFG.colors.muted)
    self.summaryText = AddFont(frame, "Loading raid talent build data...", "GameFontDisableSmall", 18, -70, 900)
    ApplyColor(self.summaryText, CFG.colors.soft)

    local controls = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    controls:SetPoint("TOPLEFT", frame, "TOPLEFT", CFG.controls.x, CFG.controls.y)
    controls:SetSize(CFG.controls.width, CFG.controls.height)
    StylePanel(controls, CFG.colors.controlBg, CFG.colors.cardBorder)

    self.bossDropdown = MakeDropdown(controls, CFG.controls.bossWidth, CFG.controls.bossX, CFG.controls.labelY, "Boss", function(_, level)
        for _, option in ipairs(RaidTalentBuilds.bossOptions or {}) do
            local value = option.value
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.checked = option.text, value == RaidTalentBuilds.selectedEncounterID
            info.func = function()
                RaidTalentBuilds.selectedEncounterID, RaidTalentBuilds.selectedDifficultyID, RaidTalentBuilds.selectedSpec = value, nil, nil
                RaidTalentBuilds.selectedCardData, RaidTalentBuilds.selectedIndex = nil, nil
                RaidTalentBuilds:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    self.difficultyDropdown = MakeDropdown(controls, CFG.controls.difficultyWidth, CFG.controls.difficultyX, CFG.controls.labelY, "Difficulty", function(_, level)
        for _, option in ipairs(RaidTalentBuilds.difficultyOptions or {}) do
            local value = option.value
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.checked = option.text, value == RaidTalentBuilds.selectedDifficultyID
            info.func = function()
                RaidTalentBuilds.selectedDifficultyID, RaidTalentBuilds.selectedSpec = value, nil
                RaidTalentBuilds.selectedCardData, RaidTalentBuilds.selectedIndex = nil, nil
                RaidTalentBuilds:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    self.specDropdown = MakeDropdown(controls, CFG.controls.specWidth, CFG.controls.specX, CFG.controls.labelY, "Spec", function(_, level)
        for _, option in ipairs(RaidTalentBuilds.specOptions or {}) do
            local value = option.value
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.checked = option.text, value == RaidTalentBuilds.selectedSpec
            info.func = function()
                RaidTalentBuilds.selectedSpec, RaidTalentBuilds.selectedCardData, RaidTalentBuilds.selectedIndex = value, nil, nil
                RaidTalentBuilds:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    self.outcomeDropdown = MakeDropdown(controls, CFG.controls.outcomeWidth, CFG.controls.outcomeX, CFG.controls.labelY, "Outcome", function(_, level)
        for _, option in ipairs(RaidTalentBuilds.metricOptions or {}) do
            local value = option.value
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.checked = option.text, value == RaidTalentBuilds.selectedMetricKey
            info.func = function()
                RaidTalentBuilds.selectedMetricKey = value
                KeyLabDB.settings.raidTalentMetric = value
                RaidTalentBuilds.selectedCardData, RaidTalentBuilds.selectedIndex = nil, nil
                RaidTalentBuilds:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    self.emptyText = AddFont(frame, "No raid talent build data captured yet.", "GameFontHighlight", CFG.list.x, CFG.list.y, CFG.list.width)
    ApplyColor(self.emptyText, CFG.colors.text)
    self.emptyText:Hide()
    self.detailPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    self.detailPanel:SetSize(CFG.details.width, CFG.details.height)
    StylePanel(self.detailPanel, CFG.colors.detailBg, CFG.colors.detailBorder)

    frame.Refresh = function() RaidTalentBuilds:Refresh() end
    frame:SetScript("OnShow", function() RaidTalentBuilds:Refresh() end)
    return frame
end

if KeyLab.RegisterTab then
    KeyLab.RegisterTab("Raid Talent Builds", function(parent) return RaidTalentBuilds:Create(parent) end)
end

return RaidTalentBuilds
