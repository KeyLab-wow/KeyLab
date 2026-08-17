local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.UI = KeyLab.UI or {}
KeyLab.Tabs = KeyLab.Tabs or {}

local LastRun = {}
KeyLab.Tabs.LastRun = LastRun

local Theme = KeyLab.UI.Theme or {}
local EncounterData = KeyLab.Analysis and KeyLab.Analysis.EncounterData or {}
local SPACING = Theme.spacing or { card = 14, column = 12 }
local HEADER = Theme.tabHeader or { x = 18, titleY = -18, titleSize = 16 }
-- The shared tab surface reserves one pixel on each side for its outer line.
-- Keep Last Run's fixed cards inside the resulting scroll viewport.
local CONTENT_WIDTH = 906
local SECONDARY_WIDTH = 444
local SUMMARY_HEIGHT = 122
local SECONDARY_HEIGHT = 178
local GRAPH_HEIGHT = 306
local SECONDARY_Y = -(SUMMARY_HEIGHT + SPACING.card)
local FIRST_GRAPH_Y = SECONDARY_Y - SECONDARY_HEIGHT - SPACING.card
local SECOND_GRAPH_Y = FIRST_GRAPH_Y - GRAPH_HEIGHT - SPACING.card
local SECONDARY_ROW_WIDTH = (SECONDARY_WIDTH * 2) + SPACING.column
local SECONDARY_START_X = (CONTENT_WIDTH - SECONDARY_ROW_WIDTH) / 2
local SECONDARY_SECOND_X = SECONDARY_START_X + SECONDARY_WIDTH + SPACING.column

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

local GRAPH_COLORS = {
    avoidable = {0.930, 0.360, 0.420, 0.95},
    death = {1.000, 0.240, 0.260, 1.00},
}

local GRAPH_ICONS = {
    boss = "Interface\\Icons\\Ability_DualWield",
    death = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",
}

local MARKER_ICON_SIZE = 12

local function Analysis()
    return KeyLab.LastRunAnalysis or {}
end

local function SetBackdrop(frame, bg, border)
    if Theme.StylePanel then
        Theme.StylePanel(frame, bg or COLORS.card, border or COLORS.border)
        return
    end

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        edgeSize = 1,
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
    if metricKey == "hps" or metricKey == "hpsWithAbsorbs" or metricKey == "healingDone" or metricKey == "healingDoneWithAbsorbs" then return COLORS.green end
    if metricKey == "absorbs" then return COLORS.blue end
    if metricKey == "interrupts" or metricKey == "dispels" then return COLORS.purple end
    if metricKey == "avoidableDamageTaken" then return GRAPH_COLORS.avoidable end
    if metricKey == "deaths" or metricKey == "groupDeaths" then return GRAPH_COLORS.death end
    return COLORS.blue
end

local function RankGroupSize(ranks)
    ranks = ranks or {}
    local groupSize = 0
    for _, rank in pairs(ranks) do
        if type(rank) == "table" and tonumber(rank.total) then
            groupSize = math.max(groupSize, tonumber(rank.total))
        end
    end
    return groupSize > 0 and groupSize or 5
end

local function RankText(rank, metricKey, state)
    local groupSize = RankGroupSize(state and state.ranks)

    if type(rank) ~= "table" or not rank.rank then
        local metrics = state and state.metrics or {}
        local capturedValue = tonumber(metrics[metricKey])
        if (metricKey == "interrupts" or metricKey == "dispels") and capturedValue == 0 then
            return "0 / " .. tostring(groupSize)
        end
        return capturedValue == nil and "No data" or "No rank"
    end

    return tostring(rank.rank) .. " / " .. tostring(groupSize)
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
    local card = MakeCard(parent, 0, 0, CONTENT_WIDTH, SUMMARY_HEIGHT, "Run Summary", COLORS.gold)
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
    AddValue(card, "Result", state.resultText or "Completed", 310, -40, 112, resultColor)
    AddVerticalDivider(card, 430, -36, 76)
    AddValue(card, "Chest", state.chestText or "-", 438, -40, 80, chestColor)
    AddVerticalDivider(card, 524, -36, 76)
    local timeDelta = tonumber(state.timeDeltaSeconds)
    local overTimer = timeDelta and timeDelta < 0
    local durationColor = overTimer and COLORS.red or COLORS.text
    AddValue(card, "Duration", FormatDuration(state.durationSeconds), 534, -40, 88, durationColor)
    AddVerticalDivider(card, 630, -36, 76)

    local timerKnown = state.timed ~= nil or state.durationSeconds ~= nil or state.timeDeltaSeconds ~= nil
    local deltaLabel = not timerKnown and "Timer Data" or (state.timed == false and "Overtime" or "Remaining")
    local deltaColor = not timerKnown and COLORS.muted or ((state.timed == false or overTimer) and COLORS.red or COLORS.green)
    local deltaText = not timerKnown and "Unavailable" or FormatDelta(state.timeDeltaSeconds)
    AddValue(card, deltaLabel, deltaText, 640, -40, 88, deltaColor)
    AddVerticalDivider(card, 738, -36, 76)
    AddValue(card, "Saved", state.timestamp and FormatSummaryDateTime(state.timestamp) or tostring(state.dateText or "-"), 746, -40, 144, COLORS.muted)

    return card
end

local function BuildRanks(parent, state)
    local card = MakeCard(parent, SECONDARY_START_X, SECONDARY_Y, SECONDARY_WIDTH, SECONDARY_HEIGHT, "Group Lineup", COLORS.purple)
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
    local card = MakeCard(parent, SECONDARY_SECOND_X, SECONDARY_Y, SECONDARY_WIDTH, SECONDARY_HEIGHT, "Player Totals", COLORS.blue)
    local metrics = state.metrics or {}
    AddVerticalDivider(card, 150, -40, 118)
    AddVerticalDivider(card, 288, -40, 118)
    local items = {
        { label = "DPS", key = "dps" },
        { label = "HPS", key = "hps" },
        { label = "Damage", key = "damageDone" },
        { label = "Healing", key = "healingDoneWithAbsorbs" },
        { label = "Avoidable Damage", key = "avoidableDamageTaken" },
        { label = "Deaths", key = "deaths" },
    }

    for index, item in ipairs(items) do
        local row = math.floor((index - 1) / 3)
        local col = (index - 1) % 3
        AddValue(card, item.label, FormatMetric(item.key, metrics[item.key]), 18 + (col * 138), -42 - (row * 54), 120, MetricColor(item.key))
    end

    return card
end

local GRAPH_METRICS = {
    dps = { label = "DPS", color = COLORS.orange },
    hps = { label = "HPS", color = COLORS.green },
    hpsWithAbsorbs = { label = "HPS", color = COLORS.green },
    damageDone = { label = "Damage", color = COLORS.orange },
    healingDone = { label = "Healing Done", color = COLORS.green },
    healingDoneWithAbsorbs = { label = "Healing + Absorbs", color = COLORS.green },
    absorbs = { label = "Absorbs", color = COLORS.blue },
    damageTaken = { label = "Damage Taken", color = COLORS.orange },
    avoidableDamageTaken = { label = "Avoidable Damage", color = GRAPH_COLORS.avoidable },
    interrupts = { label = "Interrupts", color = COLORS.purple },
    dispels = { label = "Dispels", color = COLORS.purple },
    deaths = { label = "Deaths", color = GRAPH_COLORS.death },
    groupDeaths = { label = "Group Deaths", color = GRAPH_COLORS.death },
}

local TOOLTIP_METRICS = {
    "dps",
    "hpsWithAbsorbs",
    "damageDone",
    "healingDone",
    "absorbs",
    "damageTaken",
    "avoidableDamageTaken",
    "interrupts",
    "dispels",
    "deaths",
    "groupDeaths",
}

local function WithAlpha(color, alpha)
    local c = color or COLORS.divider or COLORS.blue
    return {c[1] or 1, c[2] or 1, c[3] or 1, alpha or c[4] or 1}
end

local function GetGraphProfile(state)
    local player = state and state.player or {}
    local mapper = KeyLab.Mapping and KeyLab.Mapping.ClassSpecs

    if mapper and mapper.GetGraphProfile then
        return mapper.GetGraphProfile(player.specID, player.class or player.className, player.spec or player.specName)
    end

    local role = player.role or player.blizzardRole
    if role == "Healer" or role == "HEALER" then
        return {
            role = "Healer",
            title = "HPS by Pull",
            subtitle = "Healing performance for each captured combat session in this run.",
            metrics = { "hpsWithAbsorbs" },
        }
    end
    if role == "Tank" or role == "TANK" then
        return {
            role = "Tank",
            title = "Tank Pressure by Pull",
            subtitle = "Damage taken, healing done, and absorbs for each captured combat session in this run.",
            metrics = { "healingDone", "absorbs", "damageTaken" },
            optionalMetrics = { absorbs = true },
            metricLabels = {
                healingDone = "Healing Done",
                absorbs = "Absorbs",
                damageTaken = "Damage Taken",
            },
            scale = "perMetric",
        }
    end

    return {
        role = "Damage",
        title = "DPS by Pull",
        subtitle = "Damage performance for each captured combat session in this run.",
        metrics = { "dps" },
    }
end

local function GetRoleFocusProfile(state)
    local player = state and state.player or {}
    local mapper = KeyLab.Mapping and KeyLab.Mapping.ClassSpecs

    if mapper and mapper.GetRoleFocusProfile then
        return mapper.GetRoleFocusProfile(player.specID, player.class or player.className, player.spec or player.specName)
    end

    local role = player.role or player.blizzardRole
    if role == "Healer" or role == "HEALER" then
        return {
            role = "Healer",
            title = "Group Survival by Pull",
            subtitle = "Healing done, absorbs, and group deaths for each captured combat session.",
            metrics = { "healingDone", "absorbs", "groupDeaths" },
            optionalMetrics = { absorbs = true },
            metricLabels = {
                healingDone = "Healing Done",
                absorbs = "Absorbs",
                groupDeaths = "Group Deaths",
            },
            scale = "perMetric",
        }
    end
    if role == "Tank" or role == "TANK" then
        return {
            role = "Tank",
            title = "Pull Stability by Pull",
            subtitle = "Damage taken, avoidable damage, and group deaths by pull.",
            metrics = { "damageTaken", "avoidableDamageTaken", "groupDeaths" },
            metricLabels = {
                damageTaken = "Damage Taken",
                avoidableDamageTaken = "Avoidable Damage",
                groupDeaths = "Group Deaths",
            },
            scale = "perMetric",
        }
    end

    return {
        role = "Damage",
        title = "Survival Pressure by Pull",
        subtitle = "Avoidable damage, player deaths, and healing done for each captured combat session.",
        metrics = { "avoidableDamageTaken", "deaths", "healingDoneWithAbsorbs" },
        scale = "perMetric",
    }
end

local function MetricKey(metric)
    if type(metric) == "table" then
        return metric.key
    end
    return metric
end

local function MetricLabel(profile, metricKey)
    local labels = profile and profile.metricLabels
    if type(labels) == "table" and labels[metricKey] then
        return labels[metricKey]
    end
    local metric = GRAPH_METRICS[metricKey]
    return metric and metric.label or metricKey
end

local function GraphLegendLabel(profile, metricKey)
    if metricKey == "avoidableDamageTaken" then
        return "Avoidable Dmg"
    end
    return MetricLabel(profile, metricKey)
end

local function MetricLowerIsBetter(metricKey)
    local info = EncounterData.GetMetricInfoByKey and EncounterData.GetMetricInfoByKey(metricKey)
    return info and info.higherIsBetter == false
end

local function LegendUsesLowest(metricKey)
    -- The Survival Pressure legend describes the pressure seen during the run,
    -- so Avoidable Damage should call out the highest pull even though lower is
    -- better when the same metric is used for performance comparisons.
    return metricKey ~= "avoidableDamageTaken" and MetricLowerIsBetter(metricKey)
end

local function MetricKeyList(metrics)
    local list = {}
    for _, metric in ipairs(metrics or {}) do
        local key = MetricKey(metric)
        if key then
            table.insert(list, key)
        end
    end
    return list
end

local function ListHasValue(list, value)
    for _, item in ipairs(list or {}) do
        if item == value then return true end
    end
    return false
end

local SessionMetric

local function IsMarkerMetric(metricKey)
    return metricKey == "deaths" or metricKey == "groupDeaths"
end

local function IsOptionalMetric(profile, metricKey)
    local optional = profile and profile.optionalMetrics
    if type(optional) ~= "table" then return false end
    if optional[metricKey] == true then return true end
    return ListHasValue(optional, metricKey)
end

local function MetricHasPositiveValue(sessions, metricKey)
    for _, session in ipairs(sessions or {}) do
        local value = SessionMetric(session, metricKey)
        if value and value > 0 then
            return true
        end
    end
    return false
end

local function GetGraphMetricLists(profile)
    local rawMetricKeys = MetricKeyList(profile and profile.metrics or { "dps" })
    local markerMetricKeys = MetricKeyList(profile and profile.markerMetrics or {})
    local plottedMetricKeys = {}
    local allMetricKeys = {}

    for _, metricKey in ipairs(rawMetricKeys) do
        if IsMarkerMetric(metricKey) then
            if not ListHasValue(markerMetricKeys, metricKey) then
                table.insert(markerMetricKeys, metricKey)
            end
        else
            table.insert(plottedMetricKeys, metricKey)
        end
    end

    for _, metricKey in ipairs(plottedMetricKeys) do
        if not ListHasValue(allMetricKeys, metricKey) then
            table.insert(allMetricKeys, metricKey)
        end
    end
    for _, metricKey in ipairs(markerMetricKeys) do
        if not ListHasValue(allMetricKeys, metricKey) then
            table.insert(allMetricKeys, metricKey)
        end
    end

    return plottedMetricKeys, markerMetricKeys, allMetricKeys
end

local function GetCombatSessions(encounter)
    if EncounterData.GetCombatSessions then
        return EncounterData.GetCombatSessions(encounter)
    end
    if type(encounter) ~= "table" then return {} end
    return encounter.combatSessions
        or encounter.damageMeterSessions
        or encounter.runCombatSessions
        or {}
end

SessionMetric = function(session, metricKey)
    return EncounterData.GetSessionMetric(session, metricKey)
end

local function GetGraphSessions(encounter)
    if EncounterData.GetPullSessions then
        return EncounterData.GetPullSessions(encounter)
    end

    local out = {}

    for _, session in ipairs(GetCombatSessions(encounter)) do
        if type(session) == "table"
            and session.isAggregateSession ~= true
            and (tonumber(session.durationSeconds) or 0) > 0
        then
            table.insert(out, session)
        end
    end

    return out
end

local function DrawLine(parent, x1, y1, x2, y2, color, thickness)
    if math.abs(x1 - x2) < 1 or math.abs(y1 - y2) < 1 then
        local line = parent:CreateTexture(nil, "ARTWORK")
        local width = math.abs(x2 - x1)
        local height = math.abs(y2 - y1)
        if width < 1 then
            width = thickness or 1
        end
        if height < 1 then
            height = thickness or 1
        end
        line:SetPoint("TOPLEFT", parent, "TOPLEFT", math.min(x1, x2), math.max(y1, y2))
        line:SetSize(width, height)
        line:SetColorTexture(unpack(color or COLORS.blue))
        return line
    end

    if parent.CreateLine then
        local line = parent:CreateLine(nil, "ARTWORK")
        if line.SetThickness then
            line:SetThickness(thickness or 2)
        end
        if line.SetColorTexture then
            line:SetColorTexture(unpack(color or COLORS.blue))
        elseif line.SetVertexColor then
            line:SetVertexColor(unpack(color or COLORS.blue))
        end
        line:SetStartPoint("TOPLEFT", parent, x1, y1)
        line:SetEndPoint("TOPLEFT", parent, x2, y2)
        return line
    end

    local line = parent:CreateTexture(nil, "ARTWORK")
    local width = math.abs(x2 - x1)
    local height = math.abs(y2 - y1)
    if width < 1 then
        width = thickness or 1
    end
    if height < 1 then
        height = thickness or 1
    end
    line:SetPoint("TOPLEFT", parent, "TOPLEFT", math.min(x1, x2), math.max(y1, y2))
    line:SetSize(width, height)
    line:SetColorTexture(unpack(color or COLORS.blue))
    return line
end

local function DrawDot(parent, x, y, color)
    local dot = parent:CreateTexture(nil, "OVERLAY")
    dot:SetPoint("CENTER", parent, "TOPLEFT", x, y)
    dot:SetSize(5, 5)
    dot:SetColorTexture(unpack(color or COLORS.blue))
    return dot
end

local function MakeIcon(parent, texturePath, x, y, size, color, anchor)
    local icon = parent:CreateTexture(nil, "OVERLAY")
    icon:SetPoint(anchor or "TOPLEFT", parent, "TOPLEFT", x, y)
    icon:SetSize(size or 16, size or 16)
    icon:SetTexture(texturePath)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    if color then
        icon:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
    end
    return icon
end

local function MakePullIconMarker(parent, kind, x, y, count)
    local color = kind == "death" and GRAPH_COLORS.death or COLORS.gold
    local width = count and 34 or MARKER_ICON_SIZE
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOP", parent, "TOPLEFT", x, y)
    frame:SetSize(width, 14)

    local icon = frame:CreateTexture(nil, "OVERLAY")
    icon:SetPoint(count and "LEFT" or "CENTER", frame, count and "LEFT" or "CENTER", 0, 0)
    icon:SetSize(MARKER_ICON_SIZE, MARKER_ICON_SIZE)
    icon:SetTexture(GRAPH_ICONS[kind])
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetVertexColor(color[1], color[2], color[3], color[4] or 1)

    if count then
        local label = MakeText(frame, "x" .. tostring(count), "GameFontNormalSmall", 9, color, "LEFT")
        label:SetPoint("LEFT", icon, "RIGHT", 2, 0)
        label:SetSize(20, 12)
        label:SetJustifyV("MIDDLE")
    end

    return frame
end

local function MakeLegendIconLine(parent, kind, labelText, count, x, y, color)
    MakeIcon(parent, GRAPH_ICONS[kind], x, y, MARKER_ICON_SIZE, color)
    AddLine(parent, labelText .. "  x " .. tostring(count or 0), x + 18, y - 3, 92, color, "GameFontNormal")
end

local function MarkerCountForSession(session, markerMetricKeys)
    local totalDeaths = 0

    for _, metricKey in ipairs(markerMetricKeys or {}) do
        local value = SessionMetric(session, metricKey)
        if value and value > 0 then
            totalDeaths = totalDeaths + math.floor(value + 0.5)
        end
    end

    return totalDeaths
end

local function IsBossSession(session)
    if type(session) ~= "table" then return false end
    if session.isBossSession ~= nil then return session.isBossSession == true end
    return string.find(tostring(session.sessionName or session.name or ""), "%(!%)") ~= nil
end

local function CleanSessionName(session)
    local name = tostring((session and (session.sessionName or session.name)) or "Unknown Pull")
    name = name:gsub("^%s*%(!%)%s*", "")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then
        return "Unknown Pull"
    end
    return name
end

local function AddTooltipDoubleLine(label, value, color)
    if not value then return end
    color = color or COLORS.text
    GameTooltip:AddDoubleLine(
        label,
        value,
        COLORS.muted[1], COLORS.muted[2], COLORS.muted[3],
        color[1] or 1, color[2] or 1, color[3] or 1
    )
end

local function ShowPullTooltip(owner, session, pullIndex)
    if not GameTooltip or type(session) ~= "table" then return end

    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("Pull " .. tostring(pullIndex), COLORS.gold[1], COLORS.gold[2], COLORS.gold[3])
    GameTooltip:AddLine(CleanSessionName(session), COLORS.text[1], COLORS.text[2], COLORS.text[3])
    if IsBossSession(session) then
        GameTooltip:AddLine("Boss pull", COLORS.gold[1], COLORS.gold[2], COLORS.gold[3])
    end
    GameTooltip:AddLine(" ")

    AddTooltipDoubleLine("Duration:", FormatDuration(session.durationSeconds), COLORS.text)

    for _, metricKey in ipairs(TOOLTIP_METRICS) do
        local value = SessionMetric(session, metricKey)
        if value ~= nil then
            local metric = GRAPH_METRICS[metricKey] or { label = metricKey, color = MetricColor(metricKey) }
            AddTooltipDoubleLine((metric.label or metricKey) .. ":", FormatMetric(metricKey, value), metric.color)
        end
    end

    GameTooltip:Show()
end

local function AddPullHoverTarget(card, x, graphTopY, graphBottomY, width, session, pullIndex)
    local hit = CreateFrame("Frame", nil, card)
    hit:SetFrameLevel((card:GetFrameLevel() or 0) + 8)
    hit:SetPoint("TOPLEFT", card, "TOPLEFT", x - (width / 2), graphTopY - 8)
    hit:SetSize(width, math.abs(graphTopY - graphBottomY) + 44)
    hit:EnableMouse(true)
    hit:SetScript("OnEnter", function(self)
        ShowPullTooltip(self, session, pullIndex)
    end)
    hit:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)
    return hit
end

local function LegendSessionForMetric(sessions, metricKey)
    local bestSession = nil
    local bestValue = nil
    local lowerIsBetter = LegendUsesLowest(metricKey)

    for _, session in ipairs(sessions or {}) do
        local value = SessionMetric(session, metricKey)
        if value ~= nil and (bestValue == nil or (lowerIsBetter and value < bestValue) or ((not lowerIsBetter) and value > bestValue)) then
            bestValue = value
            bestSession = session
        end
    end

    return bestSession, bestValue
end

local function BuildPullGraph(parent, state, profile, yOffset)
    profile = profile or GetGraphProfile(state)
    local card = MakeCard(parent, 0, yOffset or FIRST_GRAPH_Y, CONTENT_WIDTH, GRAPH_HEIGHT, profile.title or "Pull Timeline", COLORS.blue)
    local metricKeys, markerMetricKeys = GetGraphMetricLists(profile)
    local sessions = GetGraphSessions(state and state.encounter)
    local perMetricScale = profile.scale == "perMetric"
    local drawStems = profile.showStems ~= false and #metricKeys <= 1

    AddLine(card, profile.subtitle or "Performance for each captured combat session in this run.", 14, -34, 700, COLORS.muted, "GameFontDisableSmall")

    if #sessions == 0 then
        AddLine(card, "No pull timeline is available yet.", 18, -74, 820, COLORS.gold, "GameFontNormal")
        AddLine(card, "Complete a new Mythic+ run and KeyLab will draw the pull graph here.", 18, -100, 820, COLORS.muted, "GameFontNormal")
        return card
    end

    local visibleMetricKeys = {}
    for _, metricKey in ipairs(metricKeys) do
        if not IsOptionalMetric(profile, metricKey) or MetricHasPositiveValue(sessions, metricKey) then
            table.insert(visibleMetricKeys, metricKey)
        end
    end
    metricKeys = visibleMetricKeys

    local graphX = 56
    local graphTopY = -68
    local graphWidth = 708
    local graphHeight = 142
    local graphBottomY = graphTopY - graphHeight
    local bossMarkerY = graphBottomY - 30
    local deathMarkerY = graphBottomY - 46
    local footerY = graphBottomY - 74
    local maxValue = 0
    local maxByMetric = {}
    local bossPullCount = 0
    local totalMarkerDeaths = 0

    for _, session in ipairs(sessions) do
        if IsBossSession(session) then
            bossPullCount = bossPullCount + 1
        end
        totalMarkerDeaths = totalMarkerDeaths + MarkerCountForSession(session, markerMetricKeys)

        for _, metricKey in ipairs(metricKeys) do
            local value = SessionMetric(session, metricKey)
            if value and value > maxValue then
                maxValue = value
            end
            if value and value > (maxByMetric[metricKey] or 0) then
                maxByMetric[metricKey] = value
            end
        end
    end

    if maxValue <= 0 then
        maxValue = 1
    end

    DrawLine(card, graphX, graphTopY, graphX, graphBottomY, COLORS.divider, 1)
    DrawLine(card, graphX, graphBottomY, graphX + graphWidth, graphBottomY, COLORS.divider, 1)
    DrawLine(card, graphX, graphTopY, graphX + graphWidth, graphTopY, COLORS.divider, 1)
    DrawLine(card, graphX, graphBottomY + (graphHeight / 2), graphX + graphWidth, graphBottomY + (graphHeight / 2), COLORS.divider, 1)

    if perMetricScale then
        AddLine(card, "High", 10, graphTopY + 6, 42, COLORS.muted, "GameFontDisableSmall")
        AddLine(card, "Mid", 10, graphBottomY + (graphHeight / 2) + 6, 42, COLORS.muted, "GameFontDisableSmall")
    else
        AddLine(card, FormatNumber(maxValue), 10, graphTopY + 6, 42, COLORS.muted, "GameFontDisableSmall")
        AddLine(card, FormatNumber(maxValue / 2), 10, graphBottomY + (graphHeight / 2) + 6, 42, COLORS.muted, "GameFontDisableSmall")
    end
    AddLine(card, "0", 10, graphBottomY + 6, 42, COLORS.muted, "GameFontDisableSmall")

    local pullLabelSize = #sessions > 22 and 8 or 9
    local pullLabelWidth = #sessions > 22 and 18 or 22
    local pullHitWidth = #sessions <= 1 and 34 or math.max(18, math.min(54, (graphWidth / math.max(1, #sessions - 1)) * 0.58))

    for index, session in ipairs(sessions) do
        local x = graphX + (#sessions == 1 and graphWidth / 2 or ((index - 1) / (#sessions - 1)) * graphWidth)
        AddPullHoverTarget(card, x, graphTopY, graphBottomY, pullHitWidth, session, index)

        local label = MakeText(card, tostring(index), "GameFontDisableSmall", pullLabelSize, COLORS.muted, "CENTER")
        label:SetPoint("TOP", card, "TOPLEFT", x, graphBottomY - 10)
        label:SetSize(pullLabelWidth, 12)

        local hasMissingMetric = false
        for _, metricKey in ipairs(metricKeys) do
            if SessionMetric(session, metricKey) == nil then
                hasMissingMetric = true
                break
            end
        end
        if hasMissingMetric then
            local missingLabel = MakeText(card, "M", "GameFontDisableSmall", 9, COLORS.warning, "CENTER")
            missingLabel:SetPoint("TOP", card, "TOPLEFT", x, graphBottomY - 21)
            missingLabel:SetSize(12, 10)
        end

        local deathMarkerCount = MarkerCountForSession(session, markerMetricKeys)
        if IsBossSession(session) then
            MakePullIconMarker(card, "boss", x, bossMarkerY)
        end

        if deathMarkerCount > 0 then
            MakePullIconMarker(card, "death", x, IsBossSession(session) and deathMarkerY or bossMarkerY, deathMarkerCount)
        end
    end

    for metricIndex, metricKey in ipairs(metricKeys) do
        local metric = GRAPH_METRICS[metricKey] or { label = metricKey, color = MetricColor(metricKey) }
        local stemColor = WithAlpha(metric.color, 0.42)
        local lastX, lastY

        for index, session in ipairs(sessions) do
            local x = graphX + (#sessions == 1 and graphWidth / 2 or ((index - 1) / (#sessions - 1)) * graphWidth)
            local value = SessionMetric(session, metricKey)

            if value ~= nil then
                local scaleMax = perMetricScale and (maxByMetric[metricKey] or 0) or maxValue
                if scaleMax <= 0 then
                    scaleMax = 1
                end
                local y = graphBottomY + ((value / scaleMax) * graphHeight)
                if value == 0 then
                    -- Keep a real zero visible instead of drawing it directly over the graph border.
                    y = graphBottomY + 3
                end
                if metricIndex == 1 and drawStems then
                    DrawLine(card, x, graphBottomY, x, y, stemColor, 2)
                end
                if lastX and lastY then
                    DrawLine(card, lastX, lastY, x, y, metric.color, 2)
                end
                if #sessions <= 24 then
                    DrawDot(card, x, y, metric.color)
                end
                lastX, lastY = x, y
            else
                -- A missing Blizzard metric is a gap, not a zero or a bridge between pulls.
                lastX, lastY = nil, nil
            end
        end
    end

    local separatorX = 790
    local legendX = 800
    local legendSpacing = #metricKeys >= 3 and 52 or 58
    local legendLabelOffset = 10
    local legendValueOffset = 30
    DrawLine(card, separatorX, graphTopY + 2, separatorX, footerY + 20, COLORS.divider, 1)

    for index, metricKey in ipairs(metricKeys) do
        local metric = GRAPH_METRICS[metricKey] or { label = metricKey, color = MetricColor(metricKey) }
        local y = -72 - ((index - 1) * legendSpacing)
        local _, bestValue = LegendSessionForMetric(sessions, metricKey)
        local bestLabel
        if metricKey == "avoidableDamageTaken" then
            bestLabel = "Highest: "
        else
            bestLabel = LegendUsesLowest(metricKey) and "Lowest: " or "Best: "
        end

        DrawLine(card, legendX, y, legendX + 28, y, metric.color, 2)
        AddLine(card, GraphLegendLabel(profile, metricKey), legendX, y - legendLabelOffset, 104, COLORS.gold, "GameFontNormal")

        if bestValue then
            AddLine(card, bestLabel .. FormatMetric(metricKey, bestValue), legendX, y - legendValueOffset, 104, metric.color, "GameFontDisableSmall")
        end
    end

    local eventLegendY = -234
    if bossPullCount > 0 or totalMarkerDeaths > 0 then
        DrawLine(card, legendX, eventLegendY + 12, legendX + 84, eventLegendY + 12, COLORS.divider, 1)
    end
    if bossPullCount > 0 then
        MakeLegendIconLine(card, "boss", "Boss Pulls", bossPullCount, legendX, eventLegendY - 8, COLORS.gold)
    end
    if totalMarkerDeaths > 0 then
        local markerLabel = #markerMetricKeys == 1 and MetricLabel(profile, markerMetricKeys[1]) or "Deaths"
        MakeLegendIconLine(card, "death", markerLabel, totalMarkerDeaths, legendX, eventLegendY - 42, GRAPH_COLORS.death)
    end

    AddLine(card, "Pull #", graphX, footerY, 80, COLORS.muted, "GameFontDisableSmall")
    AddLine(card, "M = Metric unavailable for this pull", graphX + 256, footerY, 244, COLORS.warning, "GameFontDisableSmall")

    return card
end

local function FormatHistoryDate(timestamp)
    timestamp = tonumber(timestamp)
    if not timestamp then return "Unknown time" end
    if date then return date("%b %d %I:%M %p", timestamp) end
    return tostring(timestamp)
end

local function RunHistoryLabel(encounter, isLatest)
    local challenge = encounter and (encounter.challenge or {}) or {}
    local dungeon = challenge.dungeonName or (encounter and encounter.dungeonName) or "Unknown Dungeon"
    local keyLevel = tonumber(challenge.keyLevel or (encounter and encounter.keyLevel)) or 0
    local prefix = isLatest and "Latest - " or ""
    return string.format("%s%s +%d - %s", prefix, tostring(dungeon), keyLevel, FormatHistoryDate(encounter and encounter.timestamp))
end

local function MakeActionButton(parent, label, width, height)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 132, height or 24)
    SetBackdrop(button, COLORS.card, COLORS.border)
    button.label = MakeText(button, label, "GameFontNormal", nil, COLORS.text, "CENTER")
    button.label:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.label:SetSize((width or 132) - 12, (height or 24) - 4)
    button:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(unpack(COLORS.gold))
        self.label:SetTextColor(unpack(COLORS.gold))
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(unpack(COLORS.border))
        self.label:SetTextColor(unpack(COLORS.text))
    end)
    return button
end

function LastRun:GetSelectedEncounter()
    local analysis = Analysis()
    if self.selectedRunKey and analysis.FindRecentRunByKey then
        local selected = analysis.FindRecentRunByKey(self.selectedRunKey, 7)
        if selected then return selected end
        self.selectedRunKey = nil
    end
    return analysis.GetLatestRun and analysis.GetLatestRun() or nil
end

function LastRun:RefreshHistoryControls()
    if not self.historyDropdown then return end
    local analysis = Analysis()
    local selected = self:GetSelectedEncounter()
    local latest = analysis.GetLatestRun and analysis.GetLatestRun() or nil
    local selectedIsLatest = not self.selectedRunKey
    UIDropDownMenu_SetText(
        self.historyDropdown,
        selected and RunHistoryLabel(selected, selectedIsLatest) or "No saved runs for this specialization"
    )
    if self.returnLatestButton then
        self.returnLatestButton:SetShown(self.selectedRunKey ~= nil and latest ~= nil)
    end
end

function LastRun:Refresh()
    if not self.content then return end

    local selectedEncounter = self:GetSelectedEncounter()
    local analysis = Analysis()
    local runKey = selectedEncounter and analysis.GetRunKey and analysis.GetRunKey(selectedEncounter) or nil
    if self.renderedRunKey ~= runKey then
        self.resetScrollPosition = true
        self.renderedRunKey = runKey
    end
    if self.resetScrollPosition and self.scrollFrame and self.scrollFrame.SetVerticalScroll then
        self.scrollFrame:SetVerticalScroll(0)
        self.resetScrollPosition = nil
    end

    ClearChildren(self.content)
    self:RefreshHistoryControls()
    local state = Analysis().BuildState and Analysis().BuildState(selectedEncounter) or { hasRun = false }
    if not state.hasRun then
        local card = MakeCard(self.content, 0, 0, CONTENT_WIDTH, 120, "M+ Last Run", COLORS.gold)
        AddLine(card, "Complete a Mythic+ run and your newest summary will appear here.", 18, -48, 820, COLORS.muted, "GameFontNormal")
        self.content:SetHeight(150)
        return
    end

    BuildSummary(self.content, state)
    BuildRanks(self.content, state)
    BuildTotals(self.content, state)
    BuildPullGraph(self.content, state, GetGraphProfile(state), FIRST_GRAPH_Y)
    BuildPullGraph(self.content, state, GetRoleFocusProfile(state), SECOND_GRAPH_Y)
    self.content:SetHeight(math.abs(SECOND_GRAPH_Y) + GRAPH_HEIGHT + SPACING.card)
end

function LastRun:Create(parent)
    local frame = CreateFrame("Frame", "KeyLabLastRunTab", parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    SetBackdrop(frame, COLORS.bg, {0, 0, 0, 0})
    self.frame = frame
    if KeyLab.UI.SeasonFilter then KeyLab.UI.SeasonFilter.Attach(frame) end

    local title = MakeText(frame, "M+ Last Run", "GameFontNormalLarge", HEADER.titleSize, COLORS.gold)
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", HEADER.x, HEADER.titleY)
    title:SetSize(900, 24)

    local subtitle = MakeText(frame, "See your latest Mythic+ run, including the timer, group, totals, pulls, and role results.", "GameFontHighlightSmall", nil, COLORS.muted)
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetSize(900, 32)

    local historyLabel = MakeText(frame, "View one of your latest 10 runs", "GameFontDisableSmall", nil, COLORS.muted)
    historyLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -83)
    historyLabel:SetSize(260, 18)

    local historyDropdown = KeyLab.UI.Theme.CreateLegacyDropdown(frame, "KeyLabLastRunHistoryDropdown")
    historyDropdown:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -98)
    UIDropDownMenu_SetWidth(historyDropdown, 420)
    UIDropDownMenu_Initialize(historyDropdown, function(_, level)
        if level ~= 1 then return end
        local analysis = Analysis()
        local latest = analysis.GetLatestRun and analysis.GetLatestRun() or nil
        local latestKey = latest and analysis.GetRunKey and analysis.GetRunKey(latest) or nil

        local info = UIDropDownMenu_CreateInfo()
        info.text = latest and RunHistoryLabel(latest, true) or "No saved runs for this specialization"
        info.checked = LastRun.selectedRunKey == nil
        info.disabled = latest == nil
        info.func = function()
            LastRun.selectedRunKey = nil
            LastRun.resetScrollPosition = true
            LastRun:Refresh()
        end
        UIDropDownMenu_AddButton(info, level)

        for _, encounter in ipairs(analysis.GetRecentRuns and analysis.GetRecentRuns(7) or {}) do
            local key = analysis.GetRunKey and analysis.GetRunKey(encounter) or nil
            if key and key ~= latestKey then
                info = UIDropDownMenu_CreateInfo()
                info.text = RunHistoryLabel(encounter, false)
                info.checked = LastRun.selectedRunKey == key
                info.func = function()
                    LastRun.selectedRunKey = key
                    LastRun.resetScrollPosition = true
                    LastRun:Refresh()
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end)
    self.historyDropdown = historyDropdown

    local returnLatest = MakeActionButton(frame, "Return to Latest", 138, 26)
    returnLatest:SetPoint("TOPLEFT", frame, "TOPLEFT", 458, -102)
    returnLatest:SetScript("OnClick", function()
        LastRun.selectedRunKey = nil
        LastRun.resetScrollPosition = true
        LastRun:Refresh()
    end)
    returnLatest:Hide()
    self.returnLatestButton = returnLatest

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -144)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 18)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(CONTENT_WIDTH, 1010)
    scrollFrame:SetScrollChild(content)

    self.scrollFrame = scrollFrame
    self.content = content

    frame.Refresh = function()
        LastRun:Refresh()
    end
    frame:SetScript("OnShow", function()
        LastRun.resetScrollPosition = true
        LastRun:Refresh()
    end)

    return frame
end

function KeyLab_CreateLastRunTab(parent)
    return LastRun:Create(parent)
end

if KeyLab.RegisterTab then
    KeyLab.RegisterTab("M+ Last Run", function(parent)
        return LastRun:Create(parent)
    end)
end

return LastRun
