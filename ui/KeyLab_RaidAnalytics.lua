local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Tabs = KeyLab.Tabs or {}
local Analysis = KeyLab.RaidAnalysis or {}
local Theme = KeyLab.UI and KeyLab.UI.Theme or {}
local COLORS = Theme.colors or {}
local SPACING = Theme.spacing or { card = 14, column = 12 }
local HEADER = Theme.tabHeader or {
    x = 18, titleY = -18, titleSize = 16, titleWidth = 900,
    descriptionY = -43, descriptionWidth = 890, descriptionHeight = 16,
    summaryY = -66, summaryWidth = 890, summaryHeight = 14,
    analysisControlsY = -86,
}
local CONTENT_WIDTH = 906
local SIGNAL_CARD_WIDTH = (CONTENT_WIDTH - (SPACING.column * 4)) / 3
local SIGNAL_START_X = SPACING.column

local function Color(name, fallback)
    return COLORS[name] or fallback or { 1, 1, 1, 1 }
end

local function Style(frame, background, border)
    if Theme.StylePanel then
        Theme.StylePanel(frame, background or Color("cardBg"), border or Color("cardBorder"))
        return
    end
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    local bg = background or { 0.02, 0.03, 0.06, 0.9 }
    local edge = border or { 0.2, 0.3, 0.5, 0.6 }
    frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
    frame:SetBackdropBorderColor(edge[1], edge[2], edge[3], edge[4] or 1)
end

local function Text(parent, value, template, size, color, justify)
    if Theme.CreateText then return Theme.CreateText(parent, value, template, size, color, justify) end
    local font = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    font:SetText(value or "")
    font:SetJustifyH(justify or "LEFT")
    local c = color or Color("text")
    font:SetTextColor(c[1], c[2], c[3], c[4] or 1)
    return font
end

local function SetPixelPoint(region, ...)
    if PixelUtil and PixelUtil.SetPoint then
        PixelUtil.SetPoint(region, ...)
    else
        region:SetPoint(...)
    end
end

local function SetPixelSize(region, width, height)
    if PixelUtil and PixelUtil.SetSize then
        PixelUtil.SetSize(region, width, height)
    else
        region:SetSize(width, height)
    end
end

local function PlaceText(parent, value, x, y, width, template, size, color, justify)
    local font = Text(parent, value, template, size, color, justify)
    font:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    font:SetSize(width, 22)
    return font
end

local function Panel(parent, x, y, width, height, border)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    SetPixelPoint(frame, "TOPLEFT", parent, "TOPLEFT", x, y)
    SetPixelSize(frame, width, height)
    Style(frame, Color("cardBg"), border or Color("cardBorder"))
    return frame
end

local function Clear(parent)
    for _, child in ipairs({ parent:GetChildren() }) do child:Hide() end
    for _, region in ipairs({ parent:GetRegions() }) do region:Hide() end
end

local function FormatNumber(value)
    value = tonumber(value)
    if value == nil then return "—" end
    local absolute = math.abs(value)
    if absolute >= 1000000000 then return string.format("%.2fB", value / 1000000000) end
    if absolute >= 1000000 then return string.format("%.2fM", value / 1000000) end
    if absolute >= 1000 then return string.format("%.1fK", value / 1000) end
    return string.format("%.1f", value)
end

local function FormatDuration(value)
    value = math.max(0, tonumber(value) or 0)
    return string.format("%d:%02d", math.floor(value / 60), math.floor(value % 60))
end

local function MetricLabel(metricKey)
    local info = Analysis.GetMetricInfo and Analysis.GetMetricInfo(metricKey)
    return info and info.label or metricKey or "Metric"
end

local function CurrentSpecName()
    if not (GetSpecialization and GetSpecializationInfo) then return nil end
    local index = GetSpecialization()
    if not index then return nil end
    local _, name = GetSpecializationInfo(index)
    return name
end

local function TrendMetricInfo(metricKey)
    return Analysis.GetTrendMetricInfo and Analysis.GetTrendMetricInfo(metricKey) or {
        label = metricKey or "Metric",
        measurement = metricKey or "Metric",
    }
end

local function TrendMetricShortLabel(metricKey)
    return TrendMetricInfo(metricKey).label or metricKey or "Metric"
end

local function FormatTrendTotal(metricKey, value)
    if tonumber(value) == nil then return "—" end
    if metricKey == "interrupts" or metricKey == "dispels" or metricKey == "deaths" then
        return string.format("%.0f", value)
    end
    return FormatNumber(value)
end

local function FormatTrendRate(metricInfo, value)
    if tonumber(value) == nil then return "—" end
    if metricInfo.rateLabel == "DPS" or metricInfo.rateLabel == "HPS" then return FormatNumber(value) end
    if math.abs(value) >= 1000 then return FormatNumber(value) end
    return string.format("%.2f", value)
end

local function FormatPercentChange(value)
    if tonumber(value) == nil then return nil end
    return string.format("%+.1f%%", value)
end

local function FormatTotalChange(metricKey, delta, deltaPercent)
    local percent = FormatPercentChange(deltaPercent)
    if percent then return percent end
    if tonumber(delta) == nil then return nil end
    return (delta > 0 and "+" or "") .. FormatTrendTotal(metricKey, delta)
end

local function FormatRateChange(metricInfo, delta, deltaPercent)
    local percent = FormatPercentChange(deltaPercent)
    if percent then return percent end
    if tonumber(delta) == nil then return nil end
    return (delta > 0 and "+" or "") .. FormatTrendRate(metricInfo, delta)
end

local function FormatDurationDelta(value)
    value = tonumber(value)
    if value == nil then return nil end
    local rounded = math.floor(math.abs(value) + 0.5)
    if rounded == 0 then return "No duration change" end
    return string.format("%s%d sec duration", value > 0 and "+" or "-", rounded)
end

local function Shorten(value, limit)
    value = tostring(value or "")
    if string.len(value) <= limit then return value end
    return string.sub(value, 1, limit - 3) .. "..."
end

local function HasOption(options, selected)
    for _, option in ipairs(options or {}) do
        if option.value == selected then return true end
    end
    return false
end

local function OptionLabel(options, selected, fallback)
    for _, option in ipairs(options or {}) do
        if option.value == selected then return option.label end
    end
    return fallback or "None"
end

local function Dropdown(parent, label, x, width, optionsFunc, selectedFunc, changedFunc)
    local caption = PlaceText(parent, label, x, -10, width + 20, "GameFontDisableSmall", nil, Color("muted"))
    caption:SetHeight(16)
    local menu = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    menu:SetPoint("TOPLEFT", parent, "TOPLEFT", x - 16, -24)
    UIDropDownMenu_SetWidth(menu, width)
    UIDropDownMenu_Initialize(menu, function(_, level)
        for _, option in ipairs(optionsFunc() or {}) do
            local value, optionText = option.value, option.label
            local info = UIDropDownMenu_CreateInfo()
            info.text = optionText
            info.checked = value == selectedFunc()
            info.func = function() changedFunc(value) end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    menu.SetDisplay = function(self, value, fallback)
        UIDropDownMenu_SetText(self, OptionLabel(optionsFunc(), value, fallback))
    end
    return menu
end

local function AddEmpty(parent, message)
    local card = Panel(parent, 0, 0, 906, 116, Color("softBorder"))
    local text = PlaceText(card, message, 20, -36, 866, "GameFontHighlight", 14, Color("muted"), "CENTER")
    text:SetHeight(48)
    return 136
end

local function EncounterContext(encounter)
    local raid = Analysis.GetRaid(encounter)
    local result = raid.killed and "Kill" or "Wipe"
    return string.format(
        "%s • Pull %s • %s • %s",
        raid.difficultyName or ("Difficulty " .. tostring(raid.difficultyID or "?")),
        tostring(raid.pullNumber or "?"),
        result,
        FormatDuration(raid.durationSeconds)
    )
end

local function AddCopyField(parent, value, y)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, y)
    box:SetSize(820, 28)
    box:SetAutoFocus(false)
    box:SetText(value or "")
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnMouseUp", function(self) self:SetFocus(); self:HighlightText() end)
    return box
end

local function BuildTalentContent(tab, encounters)
    local groups = Analysis.BuildTalentGroups(encounters, tab.selectedMetricKey)
    local bossName = OptionLabel(tab.bossOptions, tab.selectedEncounterID, "Boss")
    tab.summary:SetText(string.format("%d boss pull%s • %d talent build%s for %s", #encounters, #encounters == 1 and "" or "s", #groups, #groups == 1 and "" or "s", bossName))
    if #groups == 0 then
        tab.content:SetHeight(AddEmpty(tab.content, "No matching raid talent builds yet. Complete boss pulls with a captured talent string and metric data."))
        return
    end

    local showCount = math.min(5, #groups)
    if not tab.selectedKey then tab.selectedKey = groups[1].spec .. "|" .. groups[1].talentString end
    local selected
    local y = 0
    for index = 1, showCount do
        local group = groups[index]
        local key = group.spec .. "|" .. group.talentString
        if key == tab.selectedKey then selected = group end
        local border = key == tab.selectedKey and Color("gold") or Color("cardBorder")
        local card = Panel(tab.content, 0, y, 906, 92, border)
        card:EnableMouse(true)
        card:SetScript("OnMouseUp", function()
            tab.selectedKey = key
            tab:Refresh()
        end)
        PlaceText(card, string.format("#%d  %s Talent Build", index, group.spec), 16, -10, 430, "GameFontNormal", 14, Color("gold"))
        PlaceText(card, string.format("Best %s: %s", MetricLabel(tab.selectedMetricKey), FormatNumber(group.bestValue)), 590, -10, 290, "GameFontNormal", 14, Color("blue"), "RIGHT")
        PlaceText(card, string.format("Used on %d boss pull%s", group.pullCount, group.pullCount == 1 and "" or "s"), 16, -36, 260, "GameFontHighlightSmall", nil, Color("muted"))
        PlaceText(card, EncounterContext(group.bestEncounter), 280, -36, 600, "GameFontHighlightSmall", nil, Color("muted"), "RIGHT")
        PlaceText(card, Shorten(group.talentString, 115), 16, -62, 864, "GameFontDisableSmall", nil, Color("text"))
        y = y - 102
    end

    if not selected then selected = groups[1]; tab.selectedKey = selected.spec .. "|" .. selected.talentString end
    local detail = Panel(tab.content, 0, y - 4, 906, 122, Color("cardStrongBorder"))
    PlaceText(detail, "Selected Build Details", 16, -10, 300, "GameFontNormal", 14, Color("gold"))
    PlaceText(detail, "Talent import string — click the field to select it for copying.", 16, -38, 700, "GameFontHighlightSmall", nil, Color("muted"))
    AddCopyField(detail, selected.talentString, -66)
    tab.content:SetHeight(math.abs(y) + 150)
end

local function StatValueText(priority)
    local parts = {}
    for _, stat in ipairs(priority or {}) do
        table.insert(parts, string.format("%s %.1f%%", Analysis.GetStatLabel(stat.key), stat.value))
    end
    return table.concat(parts, "   ")
end

local function BuildStatContent(tab, encounters)
    local groups = Analysis.BuildStatGroups(encounters, tab.selectedMetricKey)
    local bossName = OptionLabel(tab.bossOptions, tab.selectedEncounterID, "Boss")
    tab.summary:SetText(string.format("%d boss pull%s • %d stat profile%s for %s", #encounters, #encounters == 1 and "" or "s", #groups, #groups == 1 and "" or "s", bossName))
    if #groups == 0 then
        tab.content:SetHeight(AddEmpty(tab.content, "No matching raid stat profiles yet. Complete boss pulls with all four secondary-stat snapshots and metric data."))
        return
    end

    local showCount = math.min(5, #groups)
    if not tab.selectedKey then tab.selectedKey = groups[1].spec .. "|" .. groups[1].priorityText end
    local selected
    local y = 0
    for index = 1, showCount do
        local group = groups[index]
        local key = group.spec .. "|" .. group.priorityText
        if key == tab.selectedKey then selected = group end
        local card = Panel(tab.content, 0, y, 906, 98, key == tab.selectedKey and Color("gold") or Color("cardBorder"))
        card:EnableMouse(true)
        card:SetScript("OnMouseUp", function() tab.selectedKey = key; tab:Refresh() end)
        PlaceText(card, string.format("#%d  %s", index, group.priorityText), 16, -10, 560, "GameFontNormal", 14, Color("gold"))
        PlaceText(card, string.format("Avg %s: %s", MetricLabel(tab.selectedMetricKey), FormatNumber(group.metricAverage)), 590, -10, 290, "GameFontNormal", 14, Color("blue"), "RIGHT")
        PlaceText(card, string.format("%s • %d boss pull%s", group.spec, group.pullCount, group.pullCount == 1 and "" or "s"), 16, -38, 350, "GameFontHighlightSmall", nil, Color("muted"))
        PlaceText(card, "Best: " .. FormatNumber(group.bestValue) .. " • " .. EncounterContext(group.bestEncounter), 390, -38, 490, "GameFontHighlightSmall", nil, Color("muted"), "RIGHT")
        PlaceText(card, StatValueText(group.bestPriority or group.priority), 16, -68, 864, "GameFontDisableSmall", nil, Color("text"))
        y = y - 108
    end

    if not selected then selected = groups[1]; tab.selectedKey = selected.spec .. "|" .. selected.priorityText end
    local detail = Panel(tab.content, 0, y - 4, 906, 112, Color("cardStrongBorder"))
    PlaceText(detail, "Selected Profile Details", 16, -10, 300, "GameFontNormal", 14, Color("gold"))
    PlaceText(detail, selected.priorityText, 16, -40, 874, "GameFontNormalLarge", 16, Color("text"))
    PlaceText(detail, StatValueText(selected.bestPriority or selected.priority), 16, -72, 874, "GameFontHighlightSmall", nil, Color("muted"))
    tab.content:SetHeight(math.abs(y) + 140)
end

local function TrendTile(parent, x, title, value, detail, color)
    local card = Panel(parent, x, 0, 290, 110, color or Color("cardBorder"))
    PlaceText(card, title, 14, -12, 262, "GameFontDisableSmall", nil, Color("muted"), "CENTER")
    local valueText = PlaceText(card, value, 10, -39, 270, "GameFontNormalLarge", 15, color or Color("text"), "CENTER")
    valueText:SetHeight(30)
    local detailText = PlaceText(card, detail or "", 12, -76, 266, "GameFontHighlightSmall", nil, Color("muted"), "CENTER")
    detailText:SetHeight(30)
end

local function BuildLegacyTrendContent(tab, encounters)
    local trend = Analysis.BuildTrend(encounters, tab.selectedMetricKey)
    local bossName = OptionLabel(tab.bossOptions, tab.selectedEncounterID, "Boss")
    local metricInfo = TrendMetricInfo(tab.selectedMetricKey)
    local metricLabel = TrendMetricShortLabel(tab.selectedMetricKey)
    tab.summary:SetText(string.format("%d boss pull%s for %s  •  Each pull compares with the pull immediately before it", #encounters, #encounters == 1 and "" or "s", bossName))
    if #encounters == 0 then
        tab.content:SetHeight(AddEmpty(tab.content, "No matching raid pulls yet. Complete more pulls on this boss to begin building trends."))
        return
    end

    local latest = trend.latest
    local previous = trend.previous
    local attemptsDetail = string.format(
        "%d Wipe%s  •  %d Kill%s",
        trend.wipes or 0,
        trend.wipes == 1 and "" or "s",
        trend.kills or 0,
        trend.kills == 1 and "" or "s"
    )
    TrendTile(
        tab.content,
        0,
        "Boss Pulls",
        string.format("%d Pull%s", trend.totalPulls, trend.totalPulls == 1 and "" or "s"),
        attemptsDetail,
        Color("gold")
    )

    local latestValue = string.format("%s  •  %s", latest.result, latest.duration and FormatDuration(latest.duration) or "No Duration")
    local latestDetail = latest.totalValue ~= nil
        and (FormatTrendTotal(tab.selectedMetricKey, latest.totalValue) .. " " .. metricLabel)
        or (metricLabel .. " unavailable")
    TrendTile(tab.content, 308, "Latest Pull", latestValue, latestDetail, latest.killed and Color("green") or Color("blue"))

    local changeValue, changeDetail
    if not previous then
        changeValue = "Baseline Established"
        changeDetail = "The next pull will be compared"
    else
        local totalChange = FormatTotalChange(tab.selectedMetricKey, latest.totalDelta, latest.totalDeltaPercent)
        if totalChange then
            changeValue = totalChange .. " " .. metricLabel
        else
            changeValue = metricLabel .. " unavailable"
        end
        changeDetail = FormatDurationDelta(latest.durationDelta) or "Duration comparison unavailable"
    end
    local changeColor = not previous and Color("yellow")
        or latest.isImprovement == true and Color("green")
        or latest.isImprovement == false and Color("red")
        or Color("yellow")
    local totalChangeColor = Color("yellow")
    if previous and latest.totalDelta and latest.totalDelta ~= 0 then
        local totalImproved = metricInfo.higherIsBetter ~= false and latest.totalDelta > 0
            or metricInfo.higherIsBetter == false and latest.totalDelta < 0
        totalChangeColor = totalImproved and Color("green") or Color("red")
    end
    TrendTile(tab.content, 616, "Change From Previous Pull", changeValue, changeDetail, totalChangeColor)

    local comparisonLabel = metricInfo.rateLabel or metricLabel
    local headline
    if not previous then
        headline = "Baseline established. The next pull will be compared with this one."
    elseif latest.isFirstKill then
        if latest.direction == "Higher Than Previous Pull" then
            headline = "First Kill — " .. comparisonLabel .. " increased from the previous pull"
        elseif latest.direction == "Lower Than Previous Pull" then
            headline = "First Kill — " .. comparisonLabel .. " decreased from the previous pull"
        else
            headline = "First Kill — " .. comparisonLabel .. " remained about the same"
        end
    else
        headline = latest.direction
    end

    local comparison = Panel(tab.content, 0, -126, 906, 210, changeColor)
    PlaceText(comparison, "Latest Pull Comparison", 16, -12, 300, "GameFontNormal", 14, Color("gold"))
    PlaceText(comparison, latest.direction, 596, -12, 290, "GameFontNormal", 13, changeColor, "RIGHT")
    local headlineText = PlaceText(comparison, headline, 18, -40, 868, "GameFontNormalLarge", 16, Color("text"), "CENTER")
    headlineText:SetHeight(30)

    PlaceText(comparison, "Measurement", 18, -78, 210, "GameFontDisableSmall", nil, Color("muted"))
    PlaceText(comparison, "Latest Pull", 250, -78, 190, "GameFontDisableSmall", nil, Color("muted"), "CENTER")
    PlaceText(comparison, "Previous Pull", 462, -78, 190, "GameFontDisableSmall", nil, Color("muted"), "CENTER")
    PlaceText(comparison, "Change", 674, -78, 212, "GameFontDisableSmall", nil, Color("muted"), "CENTER")

    local function ComparisonRow(label, y, currentText, previousText, changeText, rowChangeColor)
        PlaceText(comparison, label, 18, y, 210, "GameFontHighlightSmall", nil, Color("text"))
        PlaceText(comparison, currentText or "—", 250, y, 190, "GameFontNormal", 13, Color("text"), "CENTER")
        PlaceText(comparison, previousText or "—", 462, y, 190, "GameFontNormal", 13, Color("muted"), "CENTER")
        PlaceText(comparison, changeText or (previous and "—" or "Baseline"), 674, y, 212, "GameFontNormal", 13, rowChangeColor or changeColor, "CENTER")
    end

    ComparisonRow(
        metricLabel,
        -102,
        FormatTrendTotal(tab.selectedMetricKey, latest.totalValue),
        previous and FormatTrendTotal(tab.selectedMetricKey, previous.totalValue) or nil,
        FormatTotalChange(tab.selectedMetricKey, latest.totalDelta, latest.totalDeltaPercent),
        totalChangeColor
    )
    local comparisonY = -128
    if metricInfo.rateLabel then
        ComparisonRow(
            metricInfo.rateLabel,
            comparisonY,
            FormatTrendRate(metricInfo, latest.rateValue),
            previous and FormatTrendRate(metricInfo, previous.rateValue) or nil,
            FormatRateChange(metricInfo, latest.rateDelta, latest.rateDeltaPercent),
            changeColor
        )
        comparisonY = comparisonY - 26
    end
    ComparisonRow(
        "Pull Duration",
        comparisonY,
        latest.duration and FormatDuration(latest.duration) or nil,
        previous and previous.duration and FormatDuration(previous.duration) or nil,
        FormatDurationDelta(latest.durationDelta),
        Color("blue")
    )
    PlaceText(comparison, "Outcome: " .. (latest.isFirstKill and "First Kill" or latest.result), 18, -184, 868, "GameFontHighlightSmall", nil, latest.killed and Color("green") or Color("muted"))

    PlaceText(tab.content, "Pull-to-Pull Progression", 4, -360, 360, "GameFontNormalLarge", 16, Color("gold"))
    local tableNote = metricInfo.rateLabel
        and ("Change uses " .. metricInfo.rateLabel .. " so pull length does not distort performance.")
        or "Each row compares only with the saved pull immediately above it."
    if tab.selectedMetricKey == "interrupts" or tab.selectedMetricKey == "dispels" then
        tableNote = tableNote .. " Compare similar mechanic opportunities."
    end
    PlaceText(tab.content, tableNote, 380, -360, 506, "GameFontDisableSmall", nil, Color("muted"), "RIGHT")

    local header = Panel(tab.content, 0, -390, 906, 34, Color("softBorder"))
    local hasRate = metricInfo.rateLabel ~= nil
    PlaceText(header, "Pull", 12, -7, 48, "GameFontDisableSmall", nil, Color("muted"), "CENTER")
    PlaceText(header, "Result", 68, -7, 70, "GameFontDisableSmall", nil, Color("muted"), "CENTER")
    PlaceText(header, "Duration", 146, -7, 82, "GameFontDisableSmall", nil, Color("muted"), "CENTER")
    PlaceText(header, metricLabel, 238, -7, hasRate and 180 or 260, "GameFontDisableSmall", nil, Color("muted"), "CENTER")
    if hasRate then
        PlaceText(header, metricInfo.rateLabel, 430, -7, 168, "GameFontDisableSmall", nil, Color("muted"), "CENTER")
        PlaceText(header, "Change in " .. metricInfo.rateLabel, 610, -7, 284, "GameFontDisableSmall", nil, Color("muted"), "CENTER")
    else
        PlaceText(header, "Change From Previous Pull", 520, -7, 374, "GameFontDisableSmall", nil, Color("muted"), "CENTER")
    end

    local y = -432
    for _, rowData in ipairs(trend.rows or {}) do
        local rowColor = rowData.killed and Color("green") or Color("cardBorder")
        local row = Panel(tab.content, 0, y, 906, 40, rowColor)
        local rowChangeColor = rowData.index == 1 and Color("yellow")
            or rowData.isImprovement == true and Color("green")
            or rowData.isImprovement == false and Color("red")
            or Color("yellow")
        local rowChange
        if hasRate then
            rowChange = FormatRateChange(metricInfo, rowData.comparisonDelta, rowData.comparisonDeltaPercent)
        else
            rowChange = FormatTotalChange(tab.selectedMetricKey, rowData.comparisonDelta, rowData.comparisonDeltaPercent)
        end
        rowChange = rowChange or (rowData.index == 1 and "Baseline" or "—")

        PlaceText(row, tostring(rowData.index), 12, -9, 48, "GameFontNormal", 13, Color("text"), "CENTER")
        PlaceText(row, rowData.result, 68, -9, 70, "GameFontNormal", 13, rowData.killed and Color("green") or Color("muted"), "CENTER")
        PlaceText(row, rowData.duration and FormatDuration(rowData.duration) or "—", 146, -9, 82, "GameFontHighlightSmall", nil, Color("muted"), "CENTER")
        PlaceText(row, FormatTrendTotal(tab.selectedMetricKey, rowData.totalValue), 238, -9, hasRate and 180 or 260, "GameFontNormal", 13, Color("text"), "CENTER")
        if hasRate then
            PlaceText(row, FormatTrendRate(metricInfo, rowData.rateValue), 430, -9, 168, "GameFontNormal", 13, Color("blue"), "CENTER")
            PlaceText(row, rowChange, 610, -9, 284, "GameFontNormal", 13, rowChangeColor, "CENTER")
        else
            PlaceText(row, rowChange, 520, -9, 374, "GameFontNormal", 13, rowChangeColor, "CENTER")
        end
        y = y - 46
    end

    tab.content:SetHeight(math.max(560, math.abs(y) + 12))
end

local function SignalMeasurement(signal)
    local info = signal and signal.metricInfo or {}
    return info.rateLabel or info.label or (signal and signal.metricKey) or "Metric"
end

local function SignalValue(signal, value)
    if not signal then return "-" end
    local info = signal.metricInfo or {}
    if info.rateLabel then return FormatTrendRate(info, value) end
    if signal.metricKey == "deaths" or signal.metricKey == "interrupts" or signal.metricKey == "dispels" then
        value = tonumber(value)
        if value == nil then return "-" end
        return value == math.floor(value) and string.format("%.0f", value) or string.format("%.1f", value)
    end
    return FormatTrendTotal(signal.metricKey, value)
end

local function SignalTitle(signal)
    if not signal then return "No Data" end
    if signal.state == "baseline" or signal.state == "unavailable" then return "Building Baseline" end
    if signal.activityOnly then
        if signal.state == "stable" then return "Steady Activity" end
        return signal.delta and signal.delta > 0 and "More Activity" or "Less Activity"
    end
    if signal.contextOnly then
        if signal.state == "stable" then return "No Change" end
        return signal.delta and signal.delta < 0 and "Fewer Recorded" or "More Recorded"
    end
    if signal.state == "improving" then return "Improving" end
    if signal.state == "declining" then return "Needs Attention" end
    return "Stable"
end

local function SignalColor(signal)
    if not signal or signal.state == "baseline" or signal.state == "unavailable" then return Color("yellow") end
    if signal.activityOnly or signal.contextOnly then return Color("blue") end
    if signal.state == "improving" then return Color("green") end
    if signal.state == "declining" then return Color("red") end
    return Color("yellow")
end

local function StatusColor(status)
    if status == "Improving" then return Color("green") end
    if status == "Needs Attention" then return Color("red") end
    if status == "Activity Snapshot" or status == "Pull Context" then return Color("blue") end
    return Color("yellow")
end

local function BuildSignalCard(parent, x, title, signal)
    local color = SignalColor(signal)
    local card = Panel(parent, x, -(104 + SPACING.card), SIGNAL_CARD_WIDTH, 130, color)
    PlaceText(card, title, 14, -10, SIGNAL_CARD_WIDTH - 28, "GameFontDisableSmall", nil, Color("muted"), "CENTER")
    PlaceText(card, SignalTitle(signal), 12, -34, SIGNAL_CARD_WIDTH - 24, "GameFontNormalLarge", 16, color, "CENTER")

    local measurement = SignalMeasurement(signal)
    local change = signal and FormatPercentChange(signal.deltaPercent)
    PlaceText(card, change and (change .. " " .. measurement) or measurement, 12, -64, SIGNAL_CARD_WIDTH - 24, "GameFontNormal", nil, Color("text"), "CENTER")

    local comparison
    if signal and signal.earlierValue ~= nil and signal.recentValue ~= nil then
        comparison = SignalValue(signal, signal.earlierValue) .. "  to  " .. SignalValue(signal, signal.recentValue)
    elseif signal and signal.recentValue ~= nil then
        comparison = "Current: " .. SignalValue(signal, signal.recentValue)
    else
        comparison = "No matching meter data"
    end
    PlaceText(card, comparison, 12, -91, SIGNAL_CARD_WIDTH - 24, "GameFontHighlightSmall", nil, Color("muted"), "CENTER")
    return card
end

local function SignalPhrase(signal)
    if not signal or signal.state == "unavailable" then return nil end
    local label = SignalMeasurement(signal)
    if signal.state == "baseline" then return label .. " has a baseline" end
    if signal.state == "stable" then return label .. " stayed steady" end
    local change = FormatPercentChange(signal.deltaPercent)
    local direction = signal.delta and signal.delta > 0 and "higher" or "lower"
    return label .. " was " .. (change and (string.gsub(change, "^[+-]", "") .. " ") or "") .. direction
end

local function BuildTrendContent(tab, encounters)
    local performance = Analysis.BuildBossPerformance and Analysis.BuildBossPerformance(encounters, tab.selectedMetricKey)
    if not performance then
        tab.content:SetHeight(AddEmpty(tab.content, "Raid trend analysis is unavailable."))
        return
    end

    local bossName = OptionLabel(tab.bossOptions, tab.selectedEncounterID, "Boss")
    if #encounters == 0 then
        tab.summary:SetText("No saved pulls for " .. bossName)
        tab.content:SetHeight(AddEmpty(tab.content, "No matching raid pulls yet. Complete more pulls on this boss to begin building trends."))
        return
    end

    local comparableCount = #(performance.comparablePulls or {})
    tab.summary:SetText(string.format(
        "%d saved pull%s  |  %d comparable  |  %s  |  %s",
        performance.totalPulls or #encounters,
        (performance.totalPulls or #encounters) == 1 and "" or "s",
        comparableCount,
        performance.difficultyName or "Unknown Difficulty",
        performance.spec or "Unknown Spec"
    ))

    local statusColor = StatusColor(performance.status)
    local overview = Panel(tab.content, 0, 0, 906, 104, statusColor)
    PlaceText(overview, "Boss Performance", 16, -12, 260, "GameFontNormal", nil, Color("gold"))
    PlaceText(overview, performance.confidence or "", 626, -12, 260, "GameFontDisableSmall", nil, Color("muted"), "RIGHT")
    PlaceText(overview, performance.status or "Building Baseline", 18, -38, 870, "GameFontNormalLarge", 21, statusColor, "CENTER")
    local comparisonText = comparableCount < 2
        and "The next comparable pull will start the trend."
        or string.format("Recent %d vs earlier %d comparable pull%s", #(performance.recentPulls or {}), #(performance.earlierPulls or {}), #(performance.earlierPulls or {}) == 1 and "" or "s")
    PlaceText(overview, comparisonText, 18, -72, 870, "GameFontHighlightSmall", nil, Color("muted"), "CENTER")

    local selectedCardTitle = performance.selectedSignal and performance.selectedSignal.activityOnly and "Activity"
        or performance.selectedSignal and performance.selectedSignal.contextOnly and "Pull Context"
        or "Performance"
    BuildSignalCard(tab.content, SIGNAL_START_X, selectedCardTitle, performance.selectedSignal)
    local executionTitle = performance.executionSignal and performance.executionSignal.metricKey == "damageTaken" and "Damage Intake" or "Execution"
    BuildSignalCard(tab.content, SIGNAL_START_X + SIGNAL_CARD_WIDTH + SPACING.column, executionTitle, performance.executionSignal)

    local consistency = performance.consistency or {}
    local consistencyColor = consistency.label == "Steady" and Color("green")
        or consistency.label == "Variable" and Color("red")
        or Color("yellow")
    local signalY = -(104 + SPACING.card)
    local consistencyX = SIGNAL_START_X + ((SIGNAL_CARD_WIDTH + SPACING.column) * 2)
    local consistencyCard = Panel(tab.content, consistencyX, signalY, SIGNAL_CARD_WIDTH, 130, consistencyColor)
    PlaceText(consistencyCard, "Consistency", 14, -10, SIGNAL_CARD_WIDTH - 28, "GameFontDisableSmall", nil, Color("muted"), "CENTER")
    PlaceText(consistencyCard, consistency.label or "Building Baseline", 12, -34, SIGNAL_CARD_WIDTH - 24, "GameFontNormalLarge", 16, consistencyColor, "CENTER")
    local spreadText = consistency.spreadPercent and string.format("+/- %.1f%% recent spread", consistency.spreadPercent) or "More pulls needed"
    PlaceText(consistencyCard, spreadText, 12, -64, SIGNAL_CARD_WIDTH - 24, "GameFontNormal", nil, Color("text"), "CENTER")
    PlaceText(consistencyCard, string.format("%d comparable value%s", consistency.sampleSize or 0, consistency.sampleSize == 1 and "" or "s"), 12, -91, SIGNAL_CARD_WIDTH - 24, "GameFontHighlightSmall", nil, Color("muted"), "CENTER")

    local takeawayY = signalY - 130 - SPACING.card
    local takeaway = Panel(tab.content, 0, takeawayY, 906, 108, Color("cardStrongBorder"))
    PlaceText(takeaway, "KeyLab Takeaway", 16, -12, 260, "GameFontNormal", nil, Color("gold"))
    local selectedPhrase = SignalPhrase(performance.selectedSignal)
    local executionPhrase = SignalPhrase(performance.executionSignal)
    local takeawayText
    if comparableCount < 2 then
        takeawayText = "One comparable pull is saved. The next similar attempt will begin the boss pattern."
    elseif performance.selectedSignal and performance.selectedSignal.activityOnly then
        takeawayText = (selectedPhrase or "Activity was captured") .. ". Activity is shown without grading it as better or worse."
    elseif performance.selectedSignal and performance.selectedSignal.contextOnly then
        takeawayText = (selectedPhrase or "Deaths were captured") .. ". Raid deaths are context and do not grade performance."
    else
        takeawayText = "Recent comparable pulls show " .. string.lower(selectedPhrase or "a stable selected metric")
            .. " and " .. string.lower(executionPhrase or "stable execution") .. "."
    end
    local takeawayLine = PlaceText(takeaway, takeawayText, 18, -38, 870, "GameFontNormal", 14, Color("text"), "CENTER")
    takeawayLine:SetHeight(32)

    local depthText = "Pull depth was similar."
    if performance.durationDelta and math.abs(performance.durationDelta) >= 5 then
        depthText = string.format("Recent comparable pulls lasted %d seconds %s.", math.floor(math.abs(performance.durationDelta) + 0.5), performance.durationDelta > 0 and "longer" or "shorter")
    end
    PlaceText(takeaway, depthText, 18, -78, 870, "GameFontHighlightSmall", nil, Color("muted"), "CENTER")
    tab.content:SetHeight(math.abs(takeawayY) + 108 + 20)
end

local function NewTab(key, title, subtitle, metricSetting, buildContent, metricOptionsFunc, lockCurrentSpec)
    local tab = {
        key = key,
        title = title,
        subtitle = subtitle,
        metricSetting = metricSetting,
        selectedMetricKey = "dps",
        buildContent = buildContent,
        metricOptionsFunc = metricOptionsFunc,
        lockCurrentSpec = lockCurrentSpec == true,
    }
    KeyLab.Tabs[key] = tab

    function tab:RefreshOptions()
        self.allEncounters = Analysis.GetEncounters and Analysis.GetEncounters() or {}
        self.bossOptions = Analysis.GetBossOptions(self.allEncounters)
        if not HasOption(self.bossOptions, self.selectedEncounterID) then
            self.selectedEncounterID = self.allEncounters[1] and Analysis.GetRaid(self.allEncounters[1]).encounterID or nil
            self.selectedDifficultyID = nil
            self.selectedSpec = self.lockCurrentSpec and CurrentSpecName() or nil
            self.selectedKey = nil
        end
        self.difficultyOptions = Analysis.GetDifficultyOptions(self.allEncounters, self.selectedEncounterID)
        if not HasOption(self.difficultyOptions, self.selectedDifficultyID) then self.selectedDifficultyID = nil end
        if self.lockCurrentSpec then
            self.selectedSpec = CurrentSpecName()
            self.specOptions = nil
        else
            self.specOptions = Analysis.GetSpecOptions(self.allEncounters, self.selectedEncounterID, self.selectedDifficultyID)
            if not HasOption(self.specOptions, self.selectedSpec) then self.selectedSpec = nil end
        end
        self.metricOptions = self.metricOptionsFunc and self.metricOptionsFunc() or Analysis.GetMetricOptions()
        KeyLabDB = type(KeyLabDB) == "table" and KeyLabDB or {}
        KeyLabDB.settings = type(KeyLabDB.settings) == "table" and KeyLabDB.settings or {}
        local savedMetric = KeyLabDB.settings[self.metricSetting]
        if HasOption(self.metricOptions, savedMetric) then self.selectedMetricKey = savedMetric end
        if not HasOption(self.metricOptions, self.selectedMetricKey) then self.selectedMetricKey = self.metricOptions[1] and self.metricOptions[1].value or "dps" end
        KeyLabDB.settings[self.metricSetting] = self.selectedMetricKey

        self.bossDropdown:SetDisplay(self.selectedEncounterID, "No Bosses Yet")
        self.difficultyDropdown:SetDisplay(self.selectedDifficultyID, "All Difficulties")
        if self.specDropdown then self.specDropdown:SetDisplay(self.selectedSpec, "All Specs") end
        self.metricDropdown:SetDisplay(self.selectedMetricKey, MetricLabel(self.selectedMetricKey))
    end

    function tab:Refresh()
        if not self.frame then return end
        self:RefreshOptions()
        Clear(self.content)
        local filtered = Analysis.Filter(self.allEncounters, self.selectedEncounterID, self.selectedDifficultyID, self.selectedSpec)
        self.buildContent(self, filtered)
    end

    function tab:Create(parent)
        if self.frame then return self.frame end
        local frame = CreateFrame("Frame", "KeyLab" .. key .. "Tab", parent, "BackdropTemplate")
        frame:SetAllPoints(parent)
        Style(frame, Color("bg"), { 0, 0, 0, 0 })
        self.frame = frame

        local heading = PlaceText(frame, title, HEADER.x, HEADER.titleY, HEADER.titleWidth, "GameFontNormalLarge", HEADER.titleSize, Color("gold"))
        heading:SetHeight(HEADER.titleHeight or 20)
        local sub = PlaceText(frame, subtitle, HEADER.x, HEADER.descriptionY, HEADER.descriptionWidth, "GameFontHighlightSmall", nil, Color("muted"))
        sub:SetHeight(HEADER.descriptionHeight)
        self.summary = PlaceText(frame, "Loading raid data...", HEADER.x, HEADER.summaryY, HEADER.summaryWidth, "GameFontDisableSmall", nil, Color("muted"))
        self.summary:SetHeight(HEADER.summaryHeight)

        local controls = Panel(frame, 18, HEADER.analysisControlsY, 906, 82, Color("softBorder"))
        self.bossDropdown = Dropdown(controls, "Boss", 16, 190, function() return tab.bossOptions or {} end, function() return tab.selectedEncounterID end, function(value)
            tab.selectedEncounterID = value; tab.selectedDifficultyID = nil; tab.selectedSpec = nil; tab.selectedKey = nil; tab:Refresh()
        end)
        self.difficultyDropdown = Dropdown(controls, "Difficulty", 252, 130, function() return tab.difficultyOptions or {} end, function() return tab.selectedDifficultyID end, function(value)
            tab.selectedDifficultyID = value; tab.selectedSpec = nil; tab.selectedKey = nil; tab:Refresh()
        end)
        if not self.lockCurrentSpec then
            self.specDropdown = Dropdown(controls, "Spec", 442, 130, function() return tab.specOptions or {} end, function() return tab.selectedSpec end, function(value)
                tab.selectedSpec = value; tab.selectedKey = nil; tab:Refresh()
            end)
        end
        local metricX = self.lockCurrentSpec and 442 or 632
        local metricFilterLabel = self.key == "RaidTrends" and "Performance Metric" or "Metric"
        self.metricDropdown = Dropdown(controls, metricFilterLabel, metricX, 170, function() return tab.metricOptions or {} end, function() return tab.selectedMetricKey end, function(value)
            tab.selectedMetricKey = value; KeyLabDB.settings[tab.metricSetting] = value; tab.selectedKey = nil; tab:Refresh()
        end)

        local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, HEADER.analysisControlsY - 96)
        scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 18)
        self.content = CreateFrame("Frame", nil, scroll)
        self.content:SetSize(906, 600)
        scroll:SetScrollChild(self.content)
        self.scroll = scroll

        frame.Refresh = function() tab:Refresh() end
        frame:SetScript("OnShow", function() tab:Refresh() end)
        return frame
    end

    return tab
end

local RaidTalentBuilds = NewTab(
    "RaidTalentBuilds",
    "Raid Talent Builds",
    "Compare the talent builds you used for one raid boss at a time.",
    "raidTalentMetric",
    BuildTalentContent
)

local RaidStatProfiles = NewTab(
    "RaidStatProfiles",
    "Raid Stat Profiles",
    "Compare the stat setups you used for one raid boss at a time.",
    "raidStatMetric",
    BuildStatContent
)

local RaidTrends = NewTab(
    "RaidTrends",
    "Raid Trends",
    "See how your results change from pull to pull for the selected boss.",
    "raidTrendMetric",
    BuildTrendContent,
    Analysis.GetTrendMetricOptions,
    true
)

if KeyLab.RegisterTab then
    KeyLab.RegisterTab("Raid Talent Builds", function(parent) return RaidTalentBuilds:Create(parent) end)
    KeyLab.RegisterTab("Raid Stat Profiles", function(parent) return RaidStatProfiles:Create(parent) end)
    KeyLab.RegisterTab("Raid Trends", function(parent) return RaidTrends:Create(parent) end)
end

return {
    RaidTalentBuilds = RaidTalentBuilds,
    RaidStatProfiles = RaidStatProfiles,
    RaidTrends = RaidTrends,
}
