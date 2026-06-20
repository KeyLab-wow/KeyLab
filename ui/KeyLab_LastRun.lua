local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.UI = KeyLab.UI or {}
KeyLab.Tabs = KeyLab.Tabs or {}

local LastRun = {}
KeyLab.Tabs.LastRun = LastRun

local Theme = KeyLab.UI.Theme or {}
local EncounterData = KeyLab.Analysis and KeyLab.Analysis.EncounterData or {}

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
    if metricKey == "hps" or metricKey == "hpsWithAbsorbs" or metricKey == "healingDone" or metricKey == "healingDoneWithAbsorbs" then return COLORS.green end
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
        if (metricKey == "interrupts" or metricKey == "dispels")
            and (tonumber(metrics[metricKey]) or 0) <= 0
        then
            return "0 / " .. tostring(groupSize)
        end
        return "No rank"
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
    AddValue(card, "Result", state.resultText or "Completed", 310, -40, 112, resultColor)
    AddVerticalDivider(card, 430, -36, 76)
    AddValue(card, "Chest", state.chestText or "-", 438, -40, 80, chestColor)
    AddVerticalDivider(card, 524, -36, 76)
    local timeDelta = tonumber(state.timeDeltaSeconds)
    local overTimer = timeDelta and timeDelta < 0
    local durationColor = overTimer and COLORS.red or COLORS.text
    AddValue(card, "Duration", FormatDuration(state.durationSeconds), 534, -40, 88, durationColor)
    AddVerticalDivider(card, 630, -36, 76)

    local deltaLabel = state.timed == false and "Overtime" or "Remaining"
    local deltaColor = (state.timed == false or overTimer) and COLORS.red or COLORS.green
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
        { label = "HPS", key = "hpsWithAbsorbs" },
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
    healingDone = { label = "Healing", color = COLORS.green },
    healingDoneWithAbsorbs = { label = "Healing Done", color = COLORS.green },
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
    "healingDoneWithAbsorbs",
    "damageTaken",
    "avoidableDamageTaken",
    "interrupts",
    "dispels",
    "deaths",
    "groupDeaths",
}

local function ShortText(value, maxLength)
    value = tostring(value or "")
    maxLength = tonumber(maxLength) or 24
    if string.len(value) <= maxLength then return value end
    return string.sub(value, 1, math.max(1, maxLength - 3)) .. "..."
end

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
            title = "Damage Taken by Pull",
            subtitle = "Tank pressure for each captured combat session in this run.",
            metrics = { "damageTaken", "avoidableDamageTaken" },
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
            subtitle = "Healing done and group deaths for each captured combat session.",
            metrics = { "healingDoneWithAbsorbs", "groupDeaths" },
            scale = "perMetric",
        }
    end
    if role == "Tank" or role == "TANK" then
        return {
            role = "Tank",
            title = "Pull Stability by Pull",
            subtitle = "Damage taken, avoidable damage, and group deaths for each captured combat session.",
            metrics = { "damageTaken", "avoidableDamageTaken", "groupDeaths" },
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

local function IsMarkerMetric(metricKey)
    return metricKey == "deaths" or metricKey == "groupDeaths"
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

local function SessionMetric(session, metricKey)
    return EncounterData.GetSessionMetric(session, metricKey)
end

local function SessionHasGraphMetric(session, metricKeys)
    for _, metricKey in ipairs(metricKeys or {}) do
        if SessionMetric(session, metricKey) ~= nil then
            return true
        end
    end
    return false
end

local function GetGraphSessions(encounter, metricKeys)
    local out = {}

    for _, session in ipairs(GetCombatSessions(encounter)) do
        if type(session) == "table"
            and session.isAggregateSession ~= true
            and (tonumber(session.durationSeconds) or 0) > 0
            and SessionHasGraphMetric(session, metricKeys)
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

local function MarkerTextForSession(session, markerMetricKeys)
    local totalDeaths = 0

    for _, metricKey in ipairs(markerMetricKeys or {}) do
        local value = SessionMetric(session, metricKey)
        if value and value > 0 then
            totalDeaths = totalDeaths + math.floor(value + 0.5)
        end
    end

    if totalDeaths <= 0 then return nil end
    if totalDeaths == 1 then return "D" end
    return "D x" .. tostring(totalDeaths)
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

local function BestSessionForMetric(sessions, metricKey)
    local bestSession = nil
    local bestValue = nil
    local lowerIsBetter = MetricLowerIsBetter(metricKey)

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
    local card = MakeCard(parent, 0, yOffset or -330, 908, 306, profile.title or "Pull Timeline", COLORS.blue)
    local metricKeys, markerMetricKeys, allMetricKeys = GetGraphMetricLists(profile)
    local sessions = GetGraphSessions(state and state.encounter, allMetricKeys)
    local perMetricScale = profile.scale == "perMetric"
    local drawStems = profile.showStems ~= false and #metricKeys <= 1

    AddLine(card, profile.subtitle or "Performance for each captured combat session in this run.", 14, -34, 700, COLORS.muted, "GameFontDisableSmall")

    if #sessions == 0 then
        AddLine(card, "No pull timeline yet.", 18, -74, 820, COLORS.gold, "GameFontNormal")
        AddLine(card, "Complete a fresh Mythic+ run with combat sessions available and KeyLab will draw this graph here.", 18, -100, 820, COLORS.muted, "GameFontNormal")
        return card
    end

    local graphX = 56
    local graphTopY = -68
    local graphWidth = 708
    local graphHeight = 142
    local graphBottomY = graphTopY - graphHeight
    local markerY = graphBottomY - 30
    local footerY = graphBottomY - 62
    local maxValue = 0
    local maxByMetric = {}

    for _, session in ipairs(sessions) do
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

        local deathMarkerText = MarkerTextForSession(session, markerMetricKeys)
        if IsBossSession(session) then
            local bossMarker = MakeText(card, "B", "GameFontNormalSmall", 9, COLORS.gold, "CENTER")
            local bossX = deathMarkerText and (x - 12) or x
            bossMarker:SetPoint("TOP", card, "TOPLEFT", bossX, markerY)
            bossMarker:SetSize(18, 12)
        end

        if deathMarkerText then
            local deathMarker = MakeText(card, deathMarkerText, "GameFontNormalSmall", 9, GRAPH_COLORS.death, "CENTER")
            local deathX = IsBossSession(session) and (x + 14) or x
            deathMarker:SetPoint("TOP", card, "TOPLEFT", deathX, markerY)
            deathMarker:SetSize(38, 12)
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
            end
        end
    end

    local legendX = 776
    for index, metricKey in ipairs(metricKeys) do
        local metric = GRAPH_METRICS[metricKey] or { label = metricKey, color = MetricColor(metricKey) }
        local y = -72 - ((index - 1) * 70)
        local bestSession, bestValue = BestSessionForMetric(sessions, metricKey)
        local bestLabel = MetricLowerIsBetter(metricKey) and "Lowest: " or "Best: "

        DrawLine(card, legendX, y - 4, legendX + 22, y - 4, metric.color, 2)
        AddLine(card, GraphLegendLabel(profile, metricKey), legendX + 30, y - 12, 92, COLORS.gold, "GameFontNormal")

        if bestValue then
            AddLine(card, bestLabel .. FormatMetric(metricKey, bestValue), legendX, y - 34, 110, metric.color, "GameFontDisableSmall")
            AddLine(card, ShortText(bestSession and (bestSession.sessionName or bestSession.name), 18), legendX, y - 52, 110, COLORS.muted, "GameFontDisableSmall")
        end
    end
    for markerIndex, metricKey in ipairs(markerMetricKeys) do
        local y = -72 - ((#metricKeys + markerIndex - 1) * 70)
        local markerLabel = MetricLabel(profile, metricKey)
        AddLine(card, "D", legendX + 6, y - 12, 18, GRAPH_COLORS.death, "GameFontNormal")
        AddLine(card, markerLabel, legendX + 30, y - 12, 100, COLORS.gold, "GameFontNormal")
    end

    AddLine(card, "Pull #", graphX, footerY, 80, COLORS.muted, "GameFontDisableSmall")
    AddLine(card, "B = boss", graphX + 72, footerY, 90, COLORS.gold, "GameFontDisableSmall")
    if #markerMetricKeys > 0 then
        AddLine(card, "D = death", graphX + 150, footerY, 90, GRAPH_COLORS.death, "GameFontDisableSmall")
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
    BuildPullGraph(self.content, state, GetGraphProfile(state), -330)
    BuildPullGraph(self.content, state, GetRoleFocusProfile(state), -660)
    self.content:SetHeight(1010)
end

function LastRun:Create(parent)
    local frame = CreateFrame("Frame", "KeyLabLastRunTab", parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    SetBackdrop(frame, COLORS.bg, {0, 0, 0, 0})
    self.frame = frame

    local title = MakeText(frame, "Last Run", "GameFontNormalLarge", 18, COLORS.gold)
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -18)
    title:SetSize(900, 24)

    local subtitle = MakeText(frame, "Your newest Mythic+ recap: timer result, group lineup, run totals, pull timeline, and role focus.", "GameFontHighlightSmall", nil, COLORS.muted)
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetSize(900, 20)

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -72)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 18)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(908, 1010)
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
