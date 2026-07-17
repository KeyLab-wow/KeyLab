local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Tabs = KeyLab.Tabs or {}
local RaidSummary = {}
KeyLab.Tabs.RaidSummary = RaidSummary

local Theme = KeyLab.UI and KeyLab.UI.Theme or {}
local COLORS = Theme.colors or {}
local SPACING = Theme.spacing or { card = 14, column = 12 }
local HEADER = Theme.tabHeader or { x = 18, titleY = -18, titleSize = 16 }
local EncounterData = KeyLab.Analysis and KeyLab.Analysis.EncounterData or {}

local FALLBACK_METRICS = {
    { keylabKey = "damageDone", label = "Damage Done", higherIsBetter = true },
    { keylabKey = "dps", label = "DPS", higherIsBetter = true },
    { keylabKey = "healingDone", label = "Healing Done", higherIsBetter = true },
    { keylabKey = "hps", label = "HPS", higherIsBetter = true },
    { keylabKey = "absorbs", label = "Absorbs", higherIsBetter = true },
    { keylabKey = "interrupts", label = "Interrupts", higherIsBetter = true },
    { keylabKey = "dispels", label = "Dispels", higherIsBetter = true },
    { keylabKey = "damageTaken", label = "Damage Taken", higherIsBetter = false },
    { keylabKey = "avoidableDamageTaken", label = "Avoidable Damage", higherIsBetter = false },
    { keylabKey = "deaths", label = "Deaths", higherIsBetter = false },
}

local TILE_SIZE = 24
local TILE_GAP = 4
local TILES_PER_ROW = 22
local BOSS_GRAPH_HEIGHT = 300
local PULLS_PER_GRAPH = 25
local NIGHT_RESULT_METRICS = {
    { key = "dps", label = "DPS" },
    { key = "hps", label = "HPS" },
    { key = "damageDone", label = "Damage" },
    { key = "healingDone", label = "Healing" },
    { key = "absorbs", label = "Absorbs" },
    { key = "interrupts", label = "Interrupts" },
    { key = "dispels", label = "Dispels" },
    { key = "damageTaken", label = "Damage Taken / Min" },
    { key = "avoidableDamageTaken", label = "Avoidable / Min" },
    { key = "deaths", label = "Deaths" },
}

local function Color(name, fallback)
    return COLORS[name] or fallback or { 1, 1, 1, 1 }
end

local function Text(parent, value, template, size, color, justify)
    if Theme.CreateText then return Theme.CreateText(parent, value, template, size, color, justify) end
    local font = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    font:SetText(value or "")
    font:SetJustifyH(justify or "LEFT")
    if size then font:SetFont(STANDARD_TEXT_FONT, size, "") end
    local c = color or Color("text")
    font:SetTextColor(c[1], c[2], c[3], c[4] or 1)
    return font
end

local function Style(frame, background, border)
    if Theme.StylePanel then
        Theme.StylePanel(frame, background or Color("cardBg"), border or Color("cardBorder"))
        return
    end
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        edgeSize = 1,
    })
    local bg = background or { 0.03, 0.052, 0.098, 0.94 }
    local edge = border or { 0.24, 0.38, 0.62, 0.62 }
    frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
    frame:SetBackdropBorderColor(edge[1], edge[2], edge[3], edge[4] or 1)
end

local function Panel(parent, x, y, width, height, background, border)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    frame:SetSize(width, height)
    Style(frame, background or Color("cardBg"), border or Color("cardBorder"))
    return frame
end

local function Place(parent, value, x, y, width, template, size, color, justify)
    local font = Text(parent, value, template, size, color, justify)
    font:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    font:SetSize(width, 22)
    return font
end

local function Divider(parent, x, y, height)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    line:SetSize(1, height)
    local c = Color("divider", { 0.44, 0.58, 0.78, 0.32 })
    line:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
end

local function ClearContent()
    if not RaidSummary.content then return end
    for _, child in ipairs({ RaidSummary.content:GetChildren() }) do child:Hide(); child:SetParent(nil) end
    for _, region in ipairs({ RaidSummary.content:GetRegions() }) do region:Hide() end
end

local function FormatNumber(value)
    if KeyLab.Formatters and KeyLab.Formatters.Number then return KeyLab.Formatters.Number(value) end
    value = tonumber(value)
    if value == nil then return "-" end
    local absolute = math.abs(value)
    if absolute >= 1000000000 then return string.format("%.2fB", value / 1000000000) end
    if absolute >= 1000000 then return string.format("%.2fM", value / 1000000) end
    if absolute >= 1000 then return string.format("%.1fK", value / 1000) end
    return string.format("%.0f", value)
end

local function FormatMetric(metricKey, value)
    if KeyLab.Formatters and KeyLab.Formatters.Metric then return KeyLab.Formatters.Metric(metricKey, value) end
    return FormatNumber(value)
end

local function FormatDuration(seconds)
    seconds = math.max(0, tonumber(seconds) or 0)
    if seconds >= 3600 then
        return string.format("%dh %02dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
    end
    return string.format("%d:%02d", math.floor(seconds / 60), math.floor(seconds % 60))
end

local function FormatNightRange(night)
    local startedAt = tonumber(night and night.startTime)
    local endedAt = tonumber(night and night.endTime)
    if not startedAt or not endedAt then return tostring(night and night.dateText or "") end
    return string.format("%s - %s", date("%b %d, %Y %I:%M %p", startedAt), date("%I:%M %p", endedAt))
end

local function MetricOptions()
    local options = EncounterData.GetMetricList and EncounterData.GetMetricList() or {}
    return #options > 0 and options or FALLBACK_METRICS
end

local function GetSelectedMetric()
    KeyLabDB = type(KeyLabDB) == "table" and KeyLabDB or {}
    KeyLabDB.settings = type(KeyLabDB.settings) == "table" and KeyLabDB.settings or {}
    local selected = KeyLabDB.settings.raidSelectedMetric or "dps"
    for _, metric in ipairs(MetricOptions()) do
        if metric.keylabKey == selected then return selected end
    end
    KeyLabDB.settings.raidSelectedMetric = "dps"
    return "dps"
end

local function MetricInfo(metricKey)
    if EncounterData.GetMetricInfoByKey then
        local info = EncounterData.GetMetricInfoByKey(metricKey)
        if info then return info end
    end
    for _, info in ipairs(MetricOptions()) do if info.keylabKey == metricKey then return info end end
    return { keylabKey = metricKey, label = metricKey or "Metric", higherIsBetter = true }
end

local function MetricLabel(metricKey)
    local info = MetricInfo(metricKey)
    return info.label or info.keylabKey or "Metric"
end

local function MetricValue(pull, metricKey)
    if EncounterData.GetMetricValue then return EncounterData.GetMetricValue(pull, metricKey) end
    return tonumber(pull and pull.metrics and pull.metrics[metricKey])
end

local function HigherIsBetter(metricKey)
    return MetricInfo(metricKey).higherIsBetter ~= false
end

local function Better(left, right, metricKey)
    local a, b = MetricValue(left, metricKey), MetricValue(right, metricKey)
    if a == nil then return false end
    if b == nil then return true end
    if a == b then return (tonumber(left.timestamp) or 0) > (tonumber(right.timestamp) or 0) end
    if HigherIsBetter(metricKey) then return a > b end
    return a < b
end

local function MetricColor(metricKey)
    if metricKey == "damageDone" or metricKey == "dps" then return Color("orange", { 0.86, 0.58, 0.34, 0.95 }) end
    if metricKey == "healingDone" or metricKey == "healingDoneWithAbsorbs"
        or metricKey == "hps" or metricKey == "hpsWithAbsorbs"
    then
        return Color("green", { 0.46, 0.78, 0.50, 0.95 })
    end
    if metricKey == "absorbs" then return Color("blue", { 0.50, 0.68, 0.94, 0.95 }) end
    if metricKey == "interrupts" or metricKey == "dispels" then return Color("purple", { 0.68, 0.56, 0.88, 0.95 }) end
    if metricKey == "damageTaken" or metricKey == "avoidableDamageTaken" or metricKey == "deaths" then return Color("red", { 0.84, 0.44, 0.42, 0.95 }) end
    return Color("blue", { 0.50, 0.68, 0.94, 0.95 })
end

local function DrawLine(parent, x1, y1, x2, y2, color, thickness)
    if math.abs(x1 - x2) < 1 or math.abs(y1 - y2) < 1 then
        local line = parent:CreateTexture(nil, "ARTWORK")
        line:SetPoint("TOPLEFT", parent, "TOPLEFT", math.min(x1, x2), math.max(y1, y2))
        line:SetSize(math.max(thickness or 1, math.abs(x2 - x1)), math.max(thickness or 1, math.abs(y2 - y1)))
        line:SetColorTexture(unpack(color or Color("blue")))
        return line
    end
    if parent.CreateLine then
        local line = parent:CreateLine(nil, "ARTWORK")
        if line.SetThickness then line:SetThickness(thickness or 2) end
        if line.SetColorTexture then line:SetColorTexture(unpack(color or Color("blue"))) end
        line:SetStartPoint("TOPLEFT", parent, x1, y1)
        line:SetEndPoint("TOPLEFT", parent, x2, y2)
        return line
    end
end

local function DrawDot(parent, x, y, color)
    local dot = parent:CreateTexture(nil, "OVERLAY")
    dot:SetPoint("CENTER", parent, "TOPLEFT", x, y)
    dot:SetSize(5, 5)
    dot:SetColorTexture(unpack(color or Color("blue")))
    return dot
end

local function RoleGraphProfile(player)
    player = type(player) == "table" and player or {}
    local mapper = KeyLab.Mapping and KeyLab.Mapping.ClassSpecs
    if mapper and mapper.GetGraphProfile then
        local profile = mapper.GetGraphProfile(player.specID, player.class or player.className, player.spec or player.specName)
        if profile then
            if profile.role == "Tank" or profile.role == "TANK" then
                profile.primaryRankKey = "damageTaken"
            elseif profile.role == "Healer" or profile.role == "HEALER" then
                profile.primaryRankKey = "hps"
            else
                profile.primaryRankKey = "dps"
            end
            return profile
        end
    end
    local role = player.role or player.blizzardRole
    if role == "Healer" or role == "HEALER" then
        return { title = "HPS by Pull", metrics = { "hpsWithAbsorbs" }, primaryRankKey = "hps" }
    end
    if role == "Tank" or role == "TANK" then
        return {
            title = "Tank Pressure by Pull",
            metrics = { "healingDone", "absorbs", "damageTaken" },
            metricLabels = { healingDone = "Healing Done", absorbs = "Absorbs", damageTaken = "Damage Taken" },
            scale = "perMetric",
            primaryRankKey = "damageTaken",
        }
    end
    return { title = "DPS by Pull", metrics = { "dps" }, primaryRankKey = "dps" }
end

local function GraphMetricLabel(profile, metricKey)
    return profile and profile.metricLabels and profile.metricLabels[metricKey] or MetricLabel(metricKey)
end

local function RankKey(metricKey)
    if metricKey == "hpsWithAbsorbs" then return "hps" end
    if metricKey == "healingDoneWithAbsorbs" then return "healingDone" end
    return metricKey
end

local function PullRank(pull, metricKey)
    local ranks = type(pull) == "table" and pull.metricRanks or nil
    return type(ranks) == "table" and ranks[RankKey(metricKey)] or nil
end

local function RankLabel(rank)
    if type(rank) ~= "table" or not tonumber(rank.rank) then return "No rank" end
    return tostring(math.floor(tonumber(rank.rank))) .. " / " .. tostring(math.floor(tonumber(rank.total) or tonumber(rank.rank)))
end

local function BestRank(pulls, metricKey)
    local best
    for _, pull in ipairs(pulls or {}) do
        local rank = PullRank(pull, metricKey)
        if type(rank) == "table" and tonumber(rank.rank)
            and (not best or tonumber(rank.rank) < tonumber(best.rank))
        then
            best = rank
        end
    end
    return best
end

local function KillRank(pulls, metricKey)
    for _, pull in ipairs(pulls or {}) do
        if pull.raid and pull.raid.killed == true then return PullRank(pull, metricKey) end
    end
    return nil
end

local function AverageRankLabel(pulls, metricKey)
    local rankTotal, sampleCount, commonGroupSize = 0, 0, nil
    local mixedGroupSizes = false
    for _, pull in ipairs(pulls or {}) do
        local rank = PullRank(pull, metricKey)
        if type(rank) == "table" and tonumber(rank.rank) then
            rankTotal = rankTotal + tonumber(rank.rank)
            sampleCount = sampleCount + 1
            local groupSize = tonumber(rank.total)
            if groupSize then
                if commonGroupSize == nil then commonGroupSize = groupSize
                elseif commonGroupSize ~= groupSize then mixedGroupSizes = true end
            end
        end
    end
    if sampleCount == 0 then return "No rank" end
    local average = rankTotal / sampleCount
    local averageText = math.abs(average - math.floor(average + 0.5)) < 0.05
        and tostring(math.floor(average + 0.5))
        or string.format("%.1f", average)
    if commonGroupSize and not mixedGroupSizes then
        return averageText .. " / " .. tostring(math.floor(commonGroupSize))
    end
    return averageText .. " avg"
end

local function GetLatest()
    local raids = KeyLab.DB and KeyLab.DB.Raids
    if not raids or not raids.GetLatestNight then return nil, {} end
    local night
    if raids.GetLatestNightForCurrentCharacter then
        night = raids.GetLatestNightForCurrentCharacter()
    else
        night = raids.GetLatestNight()
    end
    return night, night and raids.GetNightEncounters(night) or {}
end

local function BuildBossGroups(pulls, metricKey)
    local groups = {}
    for _, pull in ipairs(pulls or {}) do
        local raid = pull.raid or {}
        local key = tostring(raid.encounterID or raid.encounterName or "unknown")
        local group = groups[key]
        if not group then
            group = {
                encounterID = raid.encounterID,
                name = raid.encounterName or "Unknown Boss",
                pulls = {},
                killed = false,
                firstTimestamp = tonumber(pull.timestamp) or 0,
            }
            groups[key] = group
        end
        table.insert(group.pulls, pull)
        group.firstTimestamp = math.min(group.firstTimestamp, tonumber(pull.timestamp) or group.firstTimestamp)
        if raid.killed == true then group.killed = true end
        if not group.best or Better(pull, group.best, metricKey) then group.best = pull end
    end

    local result = {}
    for _, group in pairs(groups) do
        table.sort(group.pulls, function(a, b) return (tonumber(a.timestamp) or 0) < (tonumber(b.timestamp) or 0) end)
        table.insert(result, group)
    end
    table.sort(result, function(a, b)
        if a.firstTimestamp == b.firstTimestamp then return tostring(a.name) < tostring(b.name) end
        return a.firstTimestamp < b.firstTimestamp
    end)
    return result
end

local function AddSummaryValue(parent, label, value, x, width, color)
    Place(parent, label, x, -43, width, "GameFontDisableSmall", nil, Color("muted"))
    Place(parent, value, x, -65, width, "GameFontNormalLarge", 16, color or Color("text"))
end

local function CreateOverview(parent, night, pulls, groups)
    local card = Panel(parent, 18, -4, 852, 112, Color("cardBg"), Color("cardStrongBorder"))
    Place(card, "Raid Night Summary", 14, -11, 400, "GameFontNormal", 14, Color("gold"))

    AddSummaryValue(card, "Raid", tostring(night.instanceName or "Unknown Raid"), 14, 196, Color("text"))
    Divider(card, 218, -38, 60)
    AddSummaryValue(card, "Difficulty", tostring(night.difficultyName or night.difficultyID or "Unknown"), 230, 110, Color("purple"))
    Divider(card, 348, -38, 60)
    AddSummaryValue(card, "Duration", FormatDuration((tonumber(night.endTime) or 0) - (tonumber(night.startTime) or 0)), 360, 100, Color("text"))
    Divider(card, 468, -38, 60)
    AddSummaryValue(card, "Bosses Killed", tostring(night.bossesKilled or 0) .. " / " .. tostring(#groups), 480, 108, Color("green"))
    Divider(card, 596, -38, 60)
    AddSummaryValue(card, "Boss Pulls", tostring(night.totalPulls or #pulls), 608, 95, Color("blue"))
    Divider(card, 711, -38, 60)
    AddSummaryValue(card, "Wipes", tostring(night.wipes or 0), 723, 100, Color("red"))
end

local function CreateNightStory(parent, night, pulls, groups, y)
    local lastPull = pulls[#pulls]
    for _, pull in ipairs(pulls) do
        if not lastPull or (tonumber(pull.timestamp) or 0) > (tonumber(lastPull.timestamp) or 0) then lastPull = pull end
    end
    local killed = tonumber(night.bossesKilled) or 0
    local totalPulls = tonumber(night.totalPulls) or #pulls
    local story = string.format("%d boss%s defeated across %d pull%s.", killed, killed == 1 and "" or "es", totalPulls, totalPulls == 1 and "" or "s")
    if lastPull then
        local raid = lastPull.raid or {}
        story = story .. string.format(" Final pull: %s on %s (attempt %s).", raid.killed and "Kill" or "Wipe", raid.encounterName or "Unknown Boss", tostring(raid.pullNumber or "?"))
    end
    local line = Place(parent, story, 26, y, 828, "GameFontHighlightSmall", nil, Color("soft", Color("text")))
    line:SetWordWrap(true)
end

local function CreateNightResultCards(parent, night, y)
    local playerCard = Panel(parent, 18, y, 420, 224, Color("cardBg"), Color("blue"))
    local rankCard = Panel(parent, 450, y, 420, 224, Color("cardBg"), Color("purple", Color("cardStrongBorder")))
    Place(playerCard, "Raid Night Player Results", 14, -10, 392, "GameFontNormal", 14, Color("gold"))
    Place(playerCard, "Boss pulls only • raid trash excluded", 14, -31, 392, "GameFontDisableSmall", nil, Color("muted"))
    Place(rankCard, "Raid Night Group Rankings", 14, -10, 392, "GameFontNormal", 14, Color("gold"))
    Place(rankCard, "Overall placement across saved boss pulls", 14, -31, 392, "GameFontDisableSmall", nil, Color("muted"))

    local metrics = type(night.nightMetrics) == "table" and night.nightMetrics or {}
    local ranks = type(night.nightMetricRanks) == "table" and night.nightMetricRanks or {}
    for index, definition in ipairs(NIGHT_RESULT_METRICS) do
        local column = math.floor((index - 1) / 5)
        local row = (index - 1) % 5
        local x = 14 + (column * 198)
        local rowY = -56 - (row * 29)
        Place(playerCard, definition.label, x, rowY, 116, "GameFontDisableSmall", nil, Color("muted"))
        Place(playerCard, FormatMetric(definition.key, metrics[definition.key]), x + 116, rowY, 68, "GameFontNormalSmall", nil, MetricColor(definition.key), "RIGHT")
        Place(rankCard, definition.label, x, rowY, 116, "GameFontDisableSmall", nil, Color("muted"))
        Place(rankCard, RankLabel(ranks[definition.key]), x + 116, rowY, 68, "GameFontNormalSmall", nil, ranks[definition.key] and MetricColor(definition.key) or Color("muted"), "RIGHT")
    end
    if next(ranks) == nil then
        Place(rankCard, "Overall rankings begin with raid nights captured after this update.", 14, -200, 392, "GameFontDisableSmall", nil, Color("warning"), "CENTER")
    end
    return 224
end

local function CreateHighlightCard(parent, pull, rank, x, y, metricKey)
    local rankColors = {
        Color("gold", { 0.82, 0.76, 0.58, 1 }),
        Color("soft", { 0.78, 0.83, 0.90, 1 }),
        Color("orange", { 0.86, 0.58, 0.34, 1 }),
    }
    local card = Panel(parent, x, y, 276, 132, Color("cardBg"), rankColors[rank] or Color("cardBorder"))
    if not pull then
        Place(card, "#" .. tostring(rank), 14, -12, 42, "GameFontNormalLarge", 18, rankColors[rank])
        Place(card, "No qualifying pull", 14, -55, 248, "GameFontHighlightSmall", nil, Color("muted"), "CENTER")
        return
    end

    local raid = pull.raid or {}
    Place(card, "#" .. tostring(rank), 14, -10, 42, "GameFontNormalLarge", 18, rankColors[rank])
    Place(card, MetricLabel(metricKey), 70, -13, 188, "GameFontDisableSmall", nil, Color("muted"), "RIGHT")
    Place(card, FormatMetric(metricKey, MetricValue(pull, metricKey)), 14, -39, 244, "GameFontNormalLarge", 19, MetricColor(metricKey), "CENTER")
    Place(card, raid.encounterName or "Unknown Boss", 14, -72, 248, "GameFontNormal", 12, Color("text"), "CENTER")
    Place(card, string.format("Pull %s  |  %s  |  %s", tostring(raid.pullNumber or "?"), raid.killed and "Kill" or "Wipe", FormatDuration(raid.durationSeconds)), 14, -98, 248, "GameFontDisableSmall", nil, raid.killed and Color("green") or Color("red"), "CENTER")
end

local function AddLegend(parent, x, y, color, label)
    local box = parent:CreateTexture(nil, "ARTWORK")
    box:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    box:SetSize(11, 11)
    box:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
    Place(parent, label, x + 17, y + 3, 70, "GameFontDisableSmall", nil, Color("muted"))
end

local function CreatePullTile(parent, pull, index, x, y, metricKey)
    local raid = pull.raid or {}
    local killed = raid.killed == true
    local resultColor = killed and Color("green", { 0.46, 0.78, 0.50, 0.95 }) or Color("red", { 0.84, 0.44, 0.42, 0.95 })
    local tile = CreateFrame("Button", nil, parent, "BackdropTemplate")
    tile:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    tile:SetSize(TILE_SIZE, TILE_SIZE)
    Style(tile, { resultColor[1] * 0.34, resultColor[2] * 0.34, resultColor[3] * 0.34, 0.95 }, resultColor)
    local number = Text(tile, tostring(raid.pullNumber or index), "GameFontDisableSmall", 10, Color("text"), "CENTER")
    number:SetAllPoints(tile)
    number:SetJustifyV("MIDDLE")

    tile:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText((raid.encounterName or "Boss") .. " - Pull " .. tostring(raid.pullNumber or index))
        GameTooltip:AddLine((killed and "Kill" or "Wipe") .. " | " .. FormatDuration(raid.durationSeconds), 1, 1, 1)
        GameTooltip:AddLine(MetricLabel(metricKey) .. ": " .. FormatMetric(metricKey, MetricValue(pull, metricKey)), 0.72, 0.84, 1)
        GameTooltip:Show()
    end)
    tile:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
end

local function CreateBossProgressCard(parent, group, y, metricKey)
    local rows = math.max(1, math.ceil(#group.pulls / TILES_PER_ROW))
    local height = math.max(74, 18 + (rows * (TILE_SIZE + TILE_GAP)) + 12)
    local border = group.killed and Color("green") or Color("cardBorder")
    local card = Panel(parent, 18, y, 852, height, Color("cardBg"), border)

    Place(card, group.name, 14, -10, 190, "GameFontNormal", 13, Color("gold"))
    Place(card, group.killed and "KILLED" or "IN PROGRESS", 14, -32, 190, "GameFontDisableSmall", nil, group.killed and Color("green") or Color("yellow"))
    local bestValue = group.best and MetricValue(group.best, metricKey)
    Place(card, string.format("%d attempt%s | Best %s: %s", #group.pulls, #group.pulls == 1 and "" or "s", MetricLabel(metricKey), FormatMetric(metricKey, bestValue)), 14, -51, 190, "GameFontDisableSmall", nil, Color("muted"))

    for index, pull in ipairs(group.pulls) do
        local column = (index - 1) % TILES_PER_ROW
        local row = math.floor((index - 1) / TILES_PER_ROW)
        CreatePullTile(card, pull, index, 220 + (column * (TILE_SIZE + TILE_GAP)), -12 - (row * (TILE_SIZE + TILE_GAP)), metricKey)
    end
    return height
end

local function CreateGraphPageButton(parent, label, x, y, enabled, onClick)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetSize(72, 22)
    Style(button, Color("box", Color("cardBg")), enabled and Color("blue") or Color("border"))
    local text = Text(button, label, "GameFontNormalSmall", 9, enabled and Color("text") or Color("muted"), "CENTER")
    text:SetAllPoints(button)
    text:SetJustifyV("MIDDLE")
    if enabled then button:SetScript("OnClick", onClick) else button:Disable() end
    return button
end

local function CreateBossGraph(parent, group, y, profile)
    local card = Panel(parent, 18, y, 852, BOSS_GRAPH_HEIGHT, Color("cardBg"), group.killed and Color("green") or Color("cardStrongBorder"))
    local metrics = type(profile.metrics) == "table" and profile.metrics or { "dps" }
    local primaryRankKey = profile.primaryRankKey or RankKey(metrics[1])
    RaidSummary.graphPages = type(RaidSummary.graphPages) == "table" and RaidSummary.graphPages or {}
    local pageKey = tostring(group.encounterID or group.name)
    local pageCount = math.max(1, math.ceil(#group.pulls / PULLS_PER_GRAPH))
    local page = math.max(1, math.min(pageCount, tonumber(RaidSummary.graphPages[pageKey]) or 1))
    RaidSummary.graphPages[pageKey] = page
    local startIndex = ((page - 1) * PULLS_PER_GRAPH) + 1
    local endIndex = math.min(#group.pulls, startIndex + PULLS_PER_GRAPH - 1)
    local visiblePulls = {}
    for index = startIndex, endIndex do table.insert(visiblePulls, group.pulls[index]) end
    local latestPlayer = group.pulls[#group.pulls] and group.pulls[#group.pulls].player or {}
    local graphTitle = profile.title or "Performance by Pull"
    if latestPlayer.spec and latestPlayer.spec ~= "" then graphTitle = graphTitle .. "  |  " .. tostring(latestPlayer.spec) end
    local killPull
    for index, pull in ipairs(group.pulls) do
        if pull.raid and pull.raid.killed == true then killPull = pull.raid.pullNumber or index; break end
    end

    Place(card, group.name, 14, -10, 430, "GameFontNormal", 14, Color("gold"))
    Place(card, string.format("%d attempt%s  |  %s", #group.pulls, #group.pulls == 1 and "" or "s", killPull and ("Kill on Pull " .. tostring(killPull)) or "No kill"), 14, -32, 430, "GameFontDisableSmall", nil, killPull and Color("green") or Color("red"))
    Place(card, graphTitle, 470, -10, 360, "GameFontNormal", 13, MetricColor(metrics[1]), "RIGHT")
    Place(card, string.format("Showing pulls %d-%d of %d. Hover a pull number for details.", startIndex, endIndex, #group.pulls), 470, -32, 360, "GameFontDisableSmall", nil, Color("muted"), "RIGHT")

    local graphX, graphTopY = 52, -66
    local graphWidth, graphHeight = 620, 132
    local graphBottomY = graphTopY - graphHeight
    -- Divide the graph into whole-pixel pull slots.  Centering both the plotted
    -- points and the pull-number blocks in the same slots keeps every gap
    -- identical and reserves clear space after the "Pull #" axis label.
    local visibleCount = math.max(1, #visiblePulls)
    local pullSlotWidth = math.max(1, math.floor(graphWidth / visibleCount))
    local pullSlotsWidth = pullSlotWidth * visibleCount
    local pullSlotsX = graphX + math.floor((graphWidth - pullSlotsWidth) / 2)
    local function PullSlotCenter(index)
        return pullSlotsX + ((index - 0.5) * pullSlotWidth)
    end
    DrawLine(card, graphX, graphTopY, graphX, graphBottomY, Color("divider"), 1)
    DrawLine(card, graphX, graphBottomY, graphX + graphWidth, graphBottomY, Color("divider"), 1)
    DrawLine(card, graphX, graphTopY, graphX + graphWidth, graphTopY, Color("divider"), 1)
    DrawLine(card, graphX, graphBottomY + graphHeight / 2, graphX + graphWidth, graphBottomY + graphHeight / 2, Color("divider"), 1)

    local maxByMetric = {}
    for _, metricKey in ipairs(metrics) do
        for _, pull in ipairs(group.pulls) do
            local value = MetricValue(pull, metricKey)
            if value and value > (maxByMetric[metricKey] or 0) then maxByMetric[metricKey] = value end
        end
        if (maxByMetric[metricKey] or 0) <= 0 then maxByMetric[metricKey] = 1 end
    end

    if profile.scale == "perMetric" or #metrics > 1 then
        Place(card, "High", 8, graphTopY + 6, 38, "GameFontDisableSmall", nil, Color("muted"), "RIGHT")
        Place(card, "Mid", 8, graphBottomY + graphHeight / 2 + 6, 38, "GameFontDisableSmall", nil, Color("muted"), "RIGHT")
    else
        local maximum = maxByMetric[metrics[1]] or 1
        Place(card, FormatMetric(metrics[1], maximum), 2, graphTopY + 6, 44, "GameFontDisableSmall", nil, Color("muted"), "RIGHT")
        Place(card, FormatMetric(metrics[1], maximum / 2), 2, graphBottomY + graphHeight / 2 + 6, 44, "GameFontDisableSmall", nil, Color("muted"), "RIGHT")
    end
    Place(card, "0", 8, graphBottomY + 6, 38, "GameFontDisableSmall", nil, Color("muted"), "RIGHT")

    for _, metricKey in ipairs(metrics) do
        local lastX, lastY
        local metricColor = MetricColor(metricKey)
        for index, pull in ipairs(visiblePulls) do
            local value = MetricValue(pull, metricKey)
            if value ~= nil then
                local x = PullSlotCenter(index)
                local yValue = graphBottomY + ((value / maxByMetric[metricKey]) * graphHeight)
                if lastX and lastY then DrawLine(card, lastX, lastY, x, yValue, metricColor, 2) end
                DrawDot(card, x, yValue, metricColor)
                lastX, lastY = x, yValue
            end
        end
    end

    local blockWidth = math.max(9, math.min(24, pullSlotWidth - 4))
    local blockFont = blockWidth <= 11 and 7 or (blockWidth <= 15 and 8 or 9)
    for index, pull in ipairs(visiblePulls) do
        local pullRecord = pull
        local pullIndex = startIndex + index - 1
        local raid = pullRecord.raid or {}
        local pullNumber = raid.pullNumber or pullIndex
        local resultKilled = raid.killed == true
        local resultColor = resultKilled and Color("green") or Color("red")
        local x = PullSlotCenter(index)
        local block = CreateFrame("Button", nil, card, "BackdropTemplate")
        block:SetPoint("TOP", card, "TOPLEFT", x, graphBottomY - 14)
        block:SetSize(blockWidth, 22)
        Style(block, { resultColor[1] * 0.42, resultColor[2] * 0.42, resultColor[3] * 0.42, 1 }, resultColor)
        local number = Text(block, tostring(pullNumber), "GameFontNormalSmall", blockFont, Color("text"), "CENTER")
        number:SetAllPoints(block)
        number:SetJustifyV("MIDDLE")
        block:SetScript("OnEnter", function(self)
            if not GameTooltip then return end
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(group.name .. " - Pull " .. tostring(pullNumber))
            GameTooltip:AddLine((resultKilled and "Kill" or "Wipe") .. "  |  " .. FormatDuration(raid.durationSeconds), resultKilled and 0.45 or 0.95, resultKilled and 0.90 or 0.45, 0.50)
            for _, metricKey in ipairs(metrics) do
                local value = MetricValue(pullRecord, metricKey)
                local rank = PullRank(pullRecord, metricKey)
                local line = GraphMetricLabel(profile, metricKey) .. ": " .. FormatMetric(metricKey, value)
                if rank then line = line .. "  |  Rank " .. RankLabel(rank) end
                GameTooltip:AddLine(line, 0.76, 0.84, 1)
            end
            GameTooltip:Show()
        end)
        block:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    end

    local legendX = 700
    DrawLine(card, 690, graphTopY + 2, 690, graphBottomY - 40, Color("divider"), 1)
    for index, metricKey in ipairs(metrics) do
        local lineY = -72 - ((index - 1) * 45)
        DrawLine(card, legendX, lineY, legendX + 24, lineY, MetricColor(metricKey), 2)
        Place(card, GraphMetricLabel(profile, metricKey), legendX, lineY - 8, 132, "GameFontNormalSmall", nil, Color("gold"))
        Place(card, "High: " .. FormatMetric(metricKey, maxByMetric[metricKey]), legendX, lineY - 25, 132, "GameFontDisableSmall", nil, MetricColor(metricKey))
    end

    local rankCardY = #metrics >= 3 and -190 or -138
    local rankCardHeight = 104
    local rankCard = Panel(card, legendX - 6, rankCardY, 140, rankCardHeight, Color("box", Color("cardBg")), Color("purple", Color("cardStrongBorder")))
    Place(rankCard, "Raid Group Rank", 8, -7, 124, "GameFontNormalSmall", nil, Color("gold"), "CENTER")
    Place(rankCard, GraphMetricLabel(profile, primaryRankKey), 8, -25, 124, "GameFontDisableSmall", nil, MetricColor(primaryRankKey), "CENTER")
    Place(rankCard, "Average Pull", 8, -44, 70, "GameFontDisableSmall", nil, Color("muted"))
    Place(rankCard, AverageRankLabel(group.pulls, primaryRankKey), 78, -44, 54, "GameFontNormalSmall", nil, Color("text"), "RIGHT")
    Place(rankCard, "Best Pull", 8, -61, 70, "GameFontDisableSmall", nil, Color("muted"))
    Place(rankCard, RankLabel(BestRank(group.pulls, primaryRankKey)), 78, -61, 54, "GameFontNormalSmall", nil, Color("green"), "RIGHT")
    Place(rankCard, "Kill Pull", 8, -78, 70, "GameFontDisableSmall", nil, Color("muted"))
    Place(rankCard, RankLabel(KillRank(group.pulls, primaryRankKey)), 78, -78, 54, "GameFontNormalSmall", nil, group.killed and Color("green") or Color("muted"), "RIGHT")
    Place(card, string.format("Pulls %d-%d of %d  |  Page %d / %d", startIndex, endIndex, #group.pulls, page, pageCount), graphX, -255, 250, "GameFontDisableSmall", nil, Color("muted"))
    if pageCount > 1 then
        CreateGraphPageButton(card, "< Back", 510, -252, page > 1, function()
            RaidSummary.graphPages[pageKey] = page - 1
            RaidSummary.preserveScrollPosition = RaidSummary.scroll and RaidSummary.scroll:GetVerticalScroll() or 0
            RaidSummary.renderFingerprint = nil
            RaidSummary:Refresh()
        end)
        CreateGraphPageButton(card, "Next >", 594, -252, page < pageCount, function()
            RaidSummary.graphPages[pageKey] = page + 1
            RaidSummary.preserveScrollPosition = RaidSummary.scroll and RaidSummary.scroll:GetVerticalScroll() or 0
            RaidSummary.renderFingerprint = nil
            RaidSummary:Refresh()
        end)
    end
    Place(card, "Pull #", 8, graphBottomY - 17, 38, "GameFontDisableSmall", nil, Color("muted"), "RIGHT")
    return BOSS_GRAPH_HEIGHT
end

function RaidSummary:Refresh()
    if not self.frame then return end
    local night, pulls = GetLatest()
    local preservedScroll = self.preserveScrollPosition
    self.preserveScrollPosition = nil

    local fingerprint = table.concat({ tostring(night and night.id or "none"), tostring(night and night.endTime or 0), tostring(#pulls) }, ":")
    if self.renderFingerprint == fingerprint then return end
    self.renderFingerprint = fingerprint
    ClearContent()
    if preservedScroll == nil and self.scroll and self.scroll.SetVerticalScroll then self.scroll:SetVerticalScroll(0) end

    if not night then
        self.empty:Show()
        self.scroll:Hide()
        self.context:SetText("No completed raid night yet")
        return
    end

    self.empty:Hide()
    self.scroll:Show()
    self.context:SetText(string.format("%s  |  %s  |  %s", tostring(night.instanceName or "Unknown Raid"), tostring(night.difficultyName or night.difficultyID or "Unknown Difficulty"), FormatNightRange(night)))

    local groups = BuildBossGroups(pulls, "dps")
    CreateOverview(self.content, night, pulls, groups)
    CreateNightStory(self.content, night, pulls, groups, -126)
    CreateNightResultCards(self.content, night, -158)

    Place(self.content, "Boss Pull Performance", 18, -406, 500, "GameFontNormalLarge", 16, Color("gold"))
    Place(self.content, "Each boss has its own role-based graph. Pull numbers are red for wipes and green for kills.", 18, -430, 700, "GameFontDisableSmall", nil, Color("muted"))
    AddLegend(self.content, 724, -411, Color("red"), "Wipe")
    AddLegend(self.content, 796, -411, Color("green"), "Kill")

    local y = -458
    for _, group in ipairs(groups) do
        local latestPull = group.pulls[#group.pulls]
        local profile = RoleGraphProfile(latestPull and latestPull.player or night.player)
        local height = CreateBossGraph(self.content, group, y, profile)
        y = y - height - SPACING.card
    end
    if #groups == 0 then
        Place(self.content, "No boss pulls were saved for this raid night.", 32, y, 700, "GameFontHighlightSmall", nil, Color("muted"))
        y = y - 38
    end
    self.content:SetHeight(math.max(650, math.abs(y) + 20))
    if preservedScroll ~= nil and self.scroll and self.scroll.SetVerticalScroll then
        self.scroll:SetVerticalScroll(preservedScroll)
    end
end

function RaidSummary:Create(parent)
    if self.frame then return self.frame end
    local frame = CreateFrame("Frame", "KeyLabRaidSummaryTab", parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    Style(frame, Color("bg"), { 0, 0, 0, 0 })
    self.frame = frame

    local title = Text(frame, "Raid Summary", "GameFontNormalLarge", HEADER.titleSize, Color("gold"))
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", HEADER.x, HEADER.titleY)
    local subtitle = Text(frame, "Your latest saved raid night, with role-based performance and raid placement for every boss pull.", "GameFontHighlightSmall", nil, Color("muted"))
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -7)
    subtitle:SetSize(850, 20)
    self.context = Text(frame, "", "GameFontDisableSmall", nil, Color("muted"))
    self.context:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -68)
    self.context:SetSize(650, 18)

    self.scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    self.scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -94)
    self.scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 18)
    self.content = CreateFrame("Frame", nil, self.scroll)
    self.content:SetSize(888, 650)
    self.scroll:SetScrollChild(self.content)

    self.empty = Text(frame, "A Raid Summary will appear after you leave a raid with saved boss pulls.", "GameFontHighlight", 14, Color("muted"), "CENTER")
    self.empty:SetPoint("CENTER", frame, "CENTER", 0, 10)
    self.empty:SetSize(760, 30)

    frame.Refresh = function() RaidSummary:Refresh() end
    frame:SetScript("OnShow", function() RaidSummary:Refresh() end)
    return frame
end

if KeyLab.RegisterTab then
    KeyLab.RegisterTab("Raid Summary", function(parent) return RaidSummary:Create(parent) end)
end

return RaidSummary
