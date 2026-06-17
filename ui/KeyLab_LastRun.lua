local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.UI = KeyLab.UI or {}
KeyLab.Tabs = KeyLab.Tabs or {}

local LastRun = {}
KeyLab.Tabs.LastRun = LastRun

local Theme = KeyLab.UI.Theme or {}

local COLORS = Theme.colors or {
    bg = {0.018, 0.026, 0.056, 0.96},
    card = {0.030, 0.052, 0.098, 0.84},
    border = {0.240, 0.380, 0.620, 0.62},
    text = {0.940, 0.960, 0.990, 1.0},
    muted = {0.680, 0.730, 0.820, 1.0},
    gold = {0.820, 0.760, 0.580, 1.0},
    green = {0.460, 0.780, 0.500, 0.95},
    yellow = {0.840, 0.720, 0.420, 0.95},
    orange = {0.860, 0.580, 0.340, 0.95},
    red = {0.840, 0.440, 0.420, 0.95},
    purple = {0.680, 0.560, 0.880, 0.95},
    blue = {0.500, 0.680, 0.940, 0.95},
    divider = {0.440, 0.580, 0.780, 0.32},
}

local function Analysis()
    return KeyLab.LastRunAnalysis or {}
end

local function Highlights()
    return KeyLab.RunHighlights or {}
end

local function SetBackdrop(frame, bg, border)
    if Theme.StylePanel then
        Theme.StylePanel(frame, bg or COLORS.card, border or COLORS.border)
        return
    end

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 7,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    frame:SetBackdropColor(unpack(bg or COLORS.card))
    frame:SetBackdropBorderColor(unpack(border or COLORS.border))
end

local function MakeText(parent, text, template, size, color, justify)
    if Theme.CreateText then
        return Theme.CreateText(parent, text, template, size, color or COLORS.text, justify)
    end

    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    if size then fs:SetFont(STANDARD_TEXT_FONT, size, "") end
    fs:SetTextColor(unpack(color or COLORS.text))
    fs:SetJustifyH(justify or "LEFT")
    fs:SetJustifyV("TOP")
    fs:SetWordWrap(true)
    fs:SetText(text or "")
    return fs
end

local function MakeCard(parent, x, y, width, height, title, accentColor)
    if Theme.CreateCard then
        return Theme.CreateCard(parent, x, y, width, height, title, accentColor, {
            bg = COLORS.cardBg or COLORS.card,
            border = COLORS.cardBorder or COLORS.border,
        })
    end

    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    card:SetSize(width, height)
    SetBackdrop(card, COLORS.card, COLORS.border)

    local accent = card:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
    accent:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 0, 0)
    accent:SetWidth(0)
    accent:SetColorTexture(0, 0, 0, 0)

    if title and title ~= "" then
        local t = MakeText(card, title, "GameFontNormal", nil, COLORS.gold)
        t:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -10)
        t:SetSize(width - 28, 18)
        card.title = t
    end

    return card
end

local function ClearChildren(frame)
    if not frame then return end
    for _, child in ipairs({ frame:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end
    for _, region in ipairs({ frame:GetRegions() }) do
        region:Hide()
    end
end

local function FormatNumber(value)
    if KeyLab.Formatters and KeyLab.Formatters.Number then
        return KeyLab.Formatters.Number(value)
    end
    value = tonumber(value)
    if not value then return "-" end
    if value >= 1000000 then return string.format("%.1fM", value / 1000000) end
    if value >= 1000 then return string.format("%.1fK", value / 1000) end
    return tostring(math.floor(value + 0.5))
end

local function FormatMetric(metricKey, value)
    if KeyLab.Formatters and KeyLab.Formatters.Metric then
        return KeyLab.Formatters.Metric(metricKey, value)
    end
    return FormatNumber(value)
end

local function FormatDateTime(value)
    if KeyLab.Formatters and KeyLab.Formatters.DateTime then
        return KeyLab.Formatters.DateTime(value)
    end
    value = tonumber(value)
    if not value then return "-" end
    return date("%b %d, %Y %I:%M %p", value)
end

local function FormatSummaryDateTime(value)
    value = tonumber(value)
    if not value then return "-" end
    return date("%b %d %I:%M %p", value)
end

local function FormatDuration(value)
    value = tonumber(value)
    if not value then return "-" end
    local seconds = math.max(0, math.floor(value + 0.5))
    local minutes = math.floor(seconds / 60)
    seconds = seconds % 60
    return string.format("%d:%02d", minutes, seconds)
end

local function FormatDelta(value)
    value = tonumber(value)
    if not value then return "-" end
    local prefix = value >= 0 and "+" or "-"
    return prefix .. FormatDuration(math.abs(value))
end

local function MetricColor(metricKey)
    if metricKey == "dps" or metricKey == "damageDone" then return COLORS.orange end
    if metricKey == "hps" or metricKey == "healingDone" then return COLORS.green end
    if metricKey == "interrupts" or metricKey == "dispels" then return COLORS.purple end
    if metricKey == "avoidableDamageTaken" or metricKey == "deaths" then return COLORS.red end
    return COLORS.blue
end

local function RankGroupSize(ranks)
    ranks = ranks or {}
    for _, key in ipairs({ "damageDone", "dps", "hps", "healingDone", "interrupts", "dispels" }) do
        local rank = ranks[key]
        if type(rank) == "table" and tonumber(rank.total) then
            return tonumber(rank.total)
        end
    end
    return 5
end

local function RankText(rank, metricKey, state)
    if type(rank) ~= "table" or not rank.rank then
        local metrics = state and state.metrics or {}
        if metricKey == "dispels" and (tonumber(metrics.dispels) or 0) <= 0 then
            return "0 / " .. tostring(RankGroupSize(state and state.ranks))
        end
        return "New run needed"
    end
    return tostring(rank.rank) .. " / " .. tostring(rank.total or "?")
end

local function AddValue(parent, label, value, x, y, width, color)
    local l = MakeText(parent, label, "GameFontDisableSmall", nil, COLORS.muted)
    l:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    l:SetSize(width, 14)

    local v = MakeText(parent, value, "GameFontNormalLarge", 16, color or COLORS.text)
    v:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 18)
    v:SetSize(width, 22)
    return v
end

local function AddLine(parent, text, x, y, width, color, template)
    local fs = MakeText(parent, text, template or "GameFontHighlightSmall", nil, color or COLORS.text)
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetSize(width, 18)
    return fs
end

local function AddVerticalDivider(parent, x, y, height)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    line:SetSize(1, height or 60)
    line:SetColorTexture(unpack(COLORS.divider or COLORS.border))
    return line
end

local function BuildSummary(parent, state)
    local card = MakeCard(parent, 0, 0, 908, 122, "Run Summary", COLORS.gold)
    local resultColor = state.timed == true and COLORS.green or (state.timed == false and COLORS.orange or COLORS.gold)
    local chestColor = COLORS.gold
    if tonumber(state.keystoneUpgradeLevels) == 3 then
        chestColor = COLORS.purple
    elseif tonumber(state.keystoneUpgradeLevels) == 2 then
        chestColor = COLORS.green
    elseif tonumber(state.keystoneUpgradeLevels) == 1 then
        chestColor = COLORS.gold
    elseif state.timed == false then
        chestColor = COLORS.orange
    end

    AddValue(card, "Dungeon", tostring(state.dungeonName or "Unknown"), 18, -40, 202, COLORS.text)
    AddVerticalDivider(card, 226, -36, 76)
    AddValue(card, "Key", "+" .. tostring(state.keyLevel or 0), 238, -40, 52, COLORS.purple)
    AddVerticalDivider(card, 300, -36, 76)
    AddValue(card, "Result", state.resultText or "Completed", 310, -40, 84, resultColor)
    AddVerticalDivider(card, 404, -36, 76)
    AddValue(card, "Chest", state.chestText or "-", 410, -40, 108, chestColor)
    AddVerticalDivider(card, 524, -36, 76)
    AddValue(card, "Duration", FormatDuration(state.durationSeconds), 534, -40, 88, COLORS.text)
    AddVerticalDivider(card, 630, -36, 76)

    local deltaLabel = state.timed == false and "Overtime" or "Remaining"
    local deltaColor = (tonumber(state.timeDeltaSeconds) or 0) >= 0 and COLORS.green or COLORS.orange
    AddValue(card, deltaLabel, FormatDelta(state.timeDeltaSeconds), 640, -40, 88, deltaColor)
    AddVerticalDivider(card, 738, -36, 76)
    AddValue(card, "Saved", state.timestamp and FormatSummaryDateTime(state.timestamp) or tostring(state.dateText or "-"), 746, -40, 144, COLORS.muted)

    return card
end

local function BuildRanks(parent, state)
    local card = MakeCard(parent, 0, -136, 444, 178, "Group Lineup", COLORS.purple)
    local ranks = state.ranks or {}
    AddVerticalDivider(card, 150, -40, 118)
    AddVerticalDivider(card, 288, -40, 118)
    local items = {
        { label = "DPS Rank", key = "dps" },
        { label = "Damage Rank", key = "damageDone" },
        { label = "HPS Rank", key = "hps" },
        { label = "Interrupt Rank", key = "interrupts" },
        { label = "Dispel Rank", key = "dispels" },
    }

    for index, item in ipairs(items) do
        local row = math.floor((index - 1) / 3)
        local col = (index - 1) % 3
        AddValue(card, item.label, RankText(ranks[item.key], item.key, state), 18 + (col * 138), -42 - (row * 62), 118, MetricColor(item.key))
    end

    return card
end

local function BuildTotals(parent, state)
    local card = MakeCard(parent, 464, -136, 444, 178, "Player Totals", COLORS.blue)
    local metrics = state.metrics or {}
    AddVerticalDivider(card, 150, -40, 118)
    AddVerticalDivider(card, 288, -40, 118)
    local items = {
        { label = "DPS", key = "dps" },
        { label = "HPS", key = "hps" },
        { label = "Damage", key = "damageDone" },
        { label = "Healing", key = "healingDone" },
        { label = "Avoidable", key = "avoidableDamageTaken" },
        { label = "Deaths", key = "deaths" },
    }

    for index, item in ipairs(items) do
        local row = math.floor((index - 1) / 3)
        local col = (index - 1) % 3
        AddValue(card, item.label, FormatMetric(item.key, metrics[item.key]), 18 + (col * 138), -42 - (row * 54), 120, MetricColor(item.key))
    end

    return card
end

local function HighlightContext(highlight)
    if not highlight then return "" end
    local parts = {}
    if highlight.sessionName then table.insert(parts, highlight.sessionName) end
    if highlight.durationSeconds then table.insert(parts, FormatDuration(highlight.durationSeconds)) end
    return table.concat(parts, "  |  ")
end

local function BuildHighlightCard(parent, x, y, highlight)
    local color = MetricColor(highlight and highlight.metricKey)
    local card = MakeCard(parent, x, y, 286, 66, "", color)

    if not highlight then
        AddLine(card, "No segment yet", 10, -12, 250, COLORS.muted)
        return card
    end

    AddLine(card, highlight.label or "Highlight", 10, -8, 170, COLORS.gold, "GameFontNormal")
    AddLine(card, FormatMetric(highlight.metricKey, highlight.value), 188, -8, 82, color, "GameFontNormal")
    AddLine(card, HighlightContext(highlight), 10, -34, 254, COLORS.text, "GameFontHighlightSmall")
    return card
end

local function BuildHighlights(parent, state)
    local card = MakeCard(parent, 0, -330, 908, 274, "Run Highlights", COLORS.purple)
    local data = state.highlights
    if not data or data.hasSessionData ~= true then
        AddLine(card, "New completed runs will show boss/trash segment highlights here.", 18, -48, 820, COLORS.muted, "GameFontNormal")
        return card
    end

    local shown = 0
    for _, highlight in ipairs(data.segmentList or {}) do
        shown = shown + 1
        if shown > 9 then break end
        local row = math.floor((shown - 1) / 3)
        local col = (shown - 1) % 3
        BuildHighlightCard(card, 14 + (col * 296), -42 - (row * 74), highlight)
    end

    return card
end

function LastRun:Refresh()
    if not self.content then return end
    ClearChildren(self.content)

    local state = Analysis().BuildState and Analysis().BuildState() or { hasRun = false }
    if not state.hasRun then
        local card = MakeCard(self.content, 0, 0, 908, 120, "Last Run", COLORS.gold)
        AddLine(card, "Complete a Mythic+ run and KeyLab will keep the newest recap here.", 18, -48, 820, COLORS.muted, "GameFontNormal")
        self.content:SetHeight(150)
        return
    end

    BuildSummary(self.content, state)
    BuildRanks(self.content, state)
    BuildTotals(self.content, state)
    BuildHighlights(self.content, state)
    self.content:SetHeight(640)
end

function LastRun:Create(parent)
    local frame = CreateFrame("Frame", "KeyLabLastRunTab", parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    SetBackdrop(frame, COLORS.bg, {0, 0, 0, 0})
    self.frame = frame

    local title = MakeText(frame, "Last Run", "GameFontNormalLarge", 18, COLORS.gold)
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -18)
    title:SetSize(900, 24)

    local subtitle = MakeText(frame, "Your newest Mythic+ recap: timer result, group lineup, run totals, and segment highlights.", "GameFontHighlightSmall", nil, COLORS.muted)
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetSize(900, 20)

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -72)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 18)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(908, 640)
    scrollFrame:SetScrollChild(content)

    self.scrollFrame = scrollFrame
    self.content = content

    frame.Refresh = function()
        LastRun:Refresh()
    end
    frame:SetScript("OnShow", function()
        LastRun:Refresh()
    end)

    return frame
end

function KeyLab_CreateLastRunTab(parent)
    return LastRun:Create(parent)
end

if KeyLab.RegisterTab then
    KeyLab.RegisterTab("Last Run", function(parent)
        return LastRun:Create(parent)
    end)
end

return LastRun
