-- KeyLab_Trends.lua
-- Trends tab for KeyLab / M+ Journal
--
-- Purpose:
--   Show compact observed dashboard cards from saved completed Mythic+ runs.
--
-- Important:
--   Trends are observations from saved runs, not recommendations, simulations,
--   rankings, or proof that one build/stat is always better.
--
-- Data used:
--   - encounter.challenge
--   - encounter.player
--   - encounter.talents.talentString
--   - encounter.stats
--   - encounter.metrics
--   - encounter.flags

local ADDON_NAME, KeyLab = ...

KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.UI = KeyLab.UI or {}
KeyLab.Tabs = KeyLab.Tabs or {}

local Trends = {}
KeyLab.Tabs.Trends = Trends

-- =========================================================
-- EASY EDIT SETTINGS
-- =========================================================

local CFG = {
    colors = {
        bg = {0.035, 0.045, 0.075, 0.96},
        controlBg = {0.055, 0.070, 0.105, 0.94},

        cardBg = {0.045, 0.060, 0.105, 0.94},
        cardBorder = {0.18, 0.28, 0.50, 0.85},
        cardStrongBorder = {0.95, 0.78, 0.35, 0.95},

        text = {0.92, 0.92, 0.95, 1.0},
        muted = {0.72, 0.72, 0.78, 1.0},
        soft = {0.74, 0.80, 0.88, 1.0},
        gold = {0.95, 0.82, 0.42, 1.0},
        blue = {0.45, 0.72, 0.95, 1.0},
        green = {0.45, 0.95, 0.60, 1.0},
        red = {1.0, 0.42, 0.42, 1.0},
        orange = {1.0, 0.62, 0.32, 1.0},
        purple = {0.78, 0.58, 1.0, 1.0},
        warning = {1.0, 0.72, 0.35, 1.0},
        divider = {1, 1, 1, 0.13},

        crit = {1.00, 0.42, 0.42, 0.98},
        haste = {0.95, 0.82, 0.32, 0.98},
        mastery = {0.45, 0.72, 1.00, 0.98},
        versatility = {0.45, 0.95, 0.60, 0.98},
        fallback = {0.74, 0.80, 0.88, 0.98},
    },

    header = {
        x = 18,
        y = -18,
        subtitleWidth = 900,
    },

    controls = {
        x = 12,
        y = -86,
        width = 928,
        height = 62,

        specX = 18,
        dungeonX = 250,
        labelY = -12,
        specWidth = 190,
        dungeonWidth = 260,
    },

    content = {
        x = 12,
        y = -160,
        width = 928,
        gap = 12,
    },

    card = {
        width = 448,
        height = 132,
        pad = 14,
        colGap = 12,
        rowGap = 12,
        barHeight = 8,
    },

    metricCard = {
        width = 296,
        height = 78,
        colGap = 10,
        rowGap = 10,
    },
}

-- =========================================================
-- BASIC HELPERS
-- =========================================================

local function ApplyColor(fs, color)
    if fs and color then
        fs:SetTextColor(color[1], color[2], color[3], color[4] or 1)
    end
end

local function StylePanel(frame, bg, border)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        edgeSize = 1,
    })
    frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
end

local function AddFont(parent, text, template, x, y, width)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetWidth(width or 700)
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    fs:SetWordWrap(true)
    fs:SetText(text or "")
    return fs
end

local function ClearChildren(frame)
    if not frame then return end

    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        child:Hide()
        child:SetParent(nil)
    end

    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        region:Hide()
    end
end

local function MakeDropdown(parent, width, x, y, labelText, onInitialize)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetText(labelText)
    ApplyColor(label, CFG.colors.muted)

    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", x - 18, y - 18)
    UIDropDownMenu_SetWidth(dropdown, width or 160)
    UIDropDownMenu_Initialize(dropdown, onInitialize)

    return dropdown
end

local function SetDropdownText(dropdown, text)
    UIDropDownMenu_SetText(dropdown, text or "Select")
end

local function Fmt()
    return KeyLab.Formatters or {}
end

local function SafeNumber(value)
    if KeyLab.Utils and KeyLab.Utils.SafeNumber then
        return KeyLab.Utils.SafeNumber(value)
    end

    local ok, result = pcall(function()
        local n = tonumber(value)
        if type(n) ~= "number" then return nil end
        local copy = n + 0
        if copy ~= copy then return nil end
        if not (copy < math.huge and copy > -math.huge) then return nil end
        return copy
    end)

    if ok and type(result) == "number" then
        return result
    end

    return nil
end

local function FormatNumber(value)
    if Fmt().Number then return Fmt().Number(value) end
    value = SafeNumber(value)
    if value == nil then return "-" end
    if value >= 1000000 then return string.format("%.1fM", value / 1000000) end
    if value >= 1000 then return string.format("%.1fK", value / 1000) end
    return tostring(math.floor(value + 0.5))
end

local function FormatMetric(metricKey, value)
    if Fmt().Metric then return Fmt().Metric(metricKey, value) end
    return FormatNumber(value)
end

local function FormatDateTime(value)
    if Fmt().DateTime then return Fmt().DateTime(value) end
    value = SafeNumber(value)
    if value == nil then return "-" end
    return date("%b %d, %Y %I:%M %p", value)
end

-- =========================================================
-- SHARED DATA HELPERS
-- =========================================================

local STAT_KEYS = { "crit", "haste", "mastery", "versatility" }
local STAT_TIE_ORDER = { crit = 1, haste = 2, mastery = 3, versatility = 4 }

local function NormalizeKeyLabName(value)
    value = tostring(value or "")
    value = value:gsub("%s+", "")
    value = value:gsub("'", "")
    value = value:gsub("%-+", "-")
    return string.lower(value)
end

local function GetCurrentCharacterIdentity()
    local name, realm

    if UnitFullName then
        name, realm = UnitFullName("player")
    end

    if not name or name == "" then
        name = UnitName and UnitName("player") or nil
    end

    if (not realm or realm == "") and GetRealmName then
        realm = GetRealmName()
    end

    return name, realm
end

local function EncounterMatchesCurrentCharacter(encounter)
    if type(encounter) ~= "table" then
        return false
    end

    local currentName, currentRealm = GetCurrentCharacterIdentity()
    if not currentName or currentName == "" then
        return true
    end

    local player = encounter.player or {}
    local character = encounter.character or {}
    local context = encounter.context or {}
    local capture = encounter.capture or {}

    local encounterName =
        player.name
        or player.characterName
        or player.character
        or player.playerName
        or character.name
        or character.characterName
        or context.characterName
        or context.playerName
        or capture.characterName
        or capture.playerName
        or encounter.characterName
        or encounter.playerName
        or encounter.character
        or encounter.name

    local encounterRealm =
        player.realm
        or player.realmName
        or player.server
        or character.realm
        or character.realmName
        or context.realm
        or context.realmName
        or capture.realm
        or capture.realmName
        or encounter.realm
        or encounter.realmName
        or encounter.server

    local encounterFull =
        player.fullName
        or player.characterFullName
        or character.fullName
        or character.characterFullName
        or context.characterFullName
        or context.fullName
        or capture.characterFullName
        or capture.fullName
        or encounter.characterFullName
        or encounter.fullName

    local currentNameKey = NormalizeKeyLabName(currentName)
    local currentRealmKey = NormalizeKeyLabName(currentRealm)
    local currentFullKey = currentNameKey
    if currentRealmKey ~= "" then
        currentFullKey = currentFullKey .. "-" .. currentRealmKey
    end

    if encounterFull and encounterFull ~= "" then
        local fullKey = NormalizeKeyLabName(encounterFull)
        if fullKey == currentFullKey or fullKey == currentNameKey then
            return true
        end
    end

    if not encounterName or encounterName == "" then
        return false
    end

    if NormalizeKeyLabName(encounterName) ~= currentNameKey then
        return false
    end

    if encounterRealm and encounterRealm ~= "" and currentRealmKey ~= "" then
        return NormalizeKeyLabName(encounterRealm) == currentRealmKey
    end

    return true
end

local function GetEncounterList()
    local raw = {}

    if KeyLab.DB and KeyLab.DB.Encounters and KeyLab.DB.Encounters.GetFiltered then
        raw = KeyLab.DB.Encounters.GetFiltered({
            includeInterrupted = false,
            includeExcluded = false,
        })
    elseif KeyLabDB and type(KeyLabDB.encounters) == "table" then
        raw = KeyLabDB.encounters
    end

    local list = {}

    for _, encounter in ipairs(raw or {}) do
        local flags = encounter.flags or {}
        if flags.interrupted ~= true and flags.excludedFromComparisons ~= true and EncounterMatchesCurrentCharacter(encounter) then
            table.insert(list, encounter)
        end
    end

    table.sort(list, function(a, b)
        return (SafeNumber(a.timestamp) or 0) > (SafeNumber(b.timestamp) or 0)
    end)

    return list
end

local function GetChallenge(encounter)
    return encounter and encounter.challenge or {}
end

local function GetPlayer(encounter)
    return encounter and encounter.player or {}
end

local function GetStats(encounter)
    return encounter and encounter.stats or {}
end

local function GetMetrics(encounter)
    return encounter and encounter.metrics or {}
end

local function GetTalents(encounter)
    return encounter and encounter.talents or {}
end

local function GetMapID(encounter)
    return GetChallenge(encounter).mapID or encounter.mapID
end

local function GetDungeonName(encounter)
    local challenge = GetChallenge(encounter)
    return challenge.dungeonName
        or challenge.name
        or encounter.dungeonName
        or (Fmt().MapName and Fmt().MapName(challenge.mapID or encounter.mapID))
        or "Unknown Dungeon"
end

local function GetKeyLevel(encounter)
    return GetChallenge(encounter).keyLevel or encounter.keyLevel or 0
end

local function GetSpecName(encounter)
    return GetPlayer(encounter).spec or encounter.spec or encounter.specName or "Unknown Spec"
end

local function GetTalentString(encounter)
    return GetTalents(encounter).talentString or encounter.talentString or ""
end

local function GetMetricValue(encounter, metricKey)
    local metrics = GetMetrics(encounter)
    return metrics and metrics[metricKey]
end

local function GetMetricInfoByKey(metricKey)
    local metrics = KeyLab.Mapping and KeyLab.Mapping.Metrics
    if type(metrics) ~= "table" then return nil end

    for _, info in pairs(metrics) do
        if info.keylabKey == metricKey and info.store == true then
            return info
        end
    end

    return nil
end

local function GetMetricInfoByType(metricType)
    return KeyLab.Mapping
        and KeyLab.Mapping.Metrics
        and KeyLab.Mapping.Metrics[metricType]
end

local function GetMetricLabel(metricKey)
    local info = GetMetricInfoByKey(metricKey)
    return info and info.label or metricKey or "Metric"
end

local function GetMetricList()
    local list = {}
    local order = KeyLab.Mapping and KeyLab.Mapping.MetricOrder or {}

    for _, metricType in ipairs(order) do
        local info = GetMetricInfoByType(metricType)
        if info and info.store == true and info.keylabKey then
            table.insert(list, info)
        end
    end

    return list
end

local function GetSpecOptions(encounters)
    local seen = {}
    local list = {
        { text = "All Specs", value = nil },
    }

    for _, encounter in ipairs(encounters or {}) do
        local spec = GetSpecName(encounter)
        if spec and spec ~= "" and spec ~= "Unknown Spec" and not seen[spec] then
            seen[spec] = true
            table.insert(list, {
                text = spec,
                value = spec,
            })
        end
    end

    table.sort(list, function(a, b)
        if a.text == "All Specs" then return true end
        if b.text == "All Specs" then return false end
        return tostring(a.text) < tostring(b.text)
    end)

    return list
end

local function GetSpecText(spec)
    return spec or "All Specs"
end

local function MatchesSelectedSpec(encounter, selectedSpec)
    if not selectedSpec then return true end
    return GetSpecName(encounter) == selectedSpec
end

local function GetStatLabel(statKey)
    local info = KeyLab.Mapping and KeyLab.Mapping.Stats and KeyLab.Mapping.Stats[statKey]
    return info and info.label or statKey
end

local function GetStatColor(statKey)
    if statKey == "crit" then return CFG.colors.crit end
    if statKey == "haste" then return CFG.colors.haste end
    if statKey == "mastery" then return CFG.colors.mastery end
    if statKey == "versatility" then return CFG.colors.versatility end
    return CFG.colors.fallback
end

local function GetStatPriority(encounter)
    local stats = GetStats(encounter)
    local priority = {}

    for _, statKey in ipairs(STAT_KEYS) do
        local value = SafeNumber(stats and stats[statKey])
        if value and value > 0 then
            table.insert(priority, {
                key = statKey,
                value = value,
            })
        end
    end

    if #priority < #STAT_KEYS then
        return nil
    end

    table.sort(priority, function(a, b)
        if a.value == b.value then
            return (STAT_TIE_ORDER[a.key] or 99) < (STAT_TIE_ORDER[b.key] or 99)
        end
        return a.value > b.value
    end)

    return priority
end

local function GetPriorityKey(priority)
    if type(priority) ~= "table" then return nil end

    local parts = {}
    for _, stat in ipairs(priority) do
        table.insert(parts, stat.key)
    end

    return table.concat(parts, ">")
end

local function GetPriorityText(priority)
    if type(priority) ~= "table" then return "No stat priority" end

    local parts = {}
    for _, stat in ipairs(priority) do
        table.insert(parts, GetStatLabel(stat.key))
    end

    return table.concat(parts, " > ")
end

-- =========================================================
-- TREND MATH
-- =========================================================

local function NewCountGroup()
    return {
        runCount = 0,
        encounters = {},
    }
end

local function BuildMostUsedStatPriority(encounters, selectedSpec)
    local groups = {}

    for _, encounter in ipairs(encounters or {}) do
        if MatchesSelectedSpec(encounter, selectedSpec) then
            local priority = GetStatPriority(encounter)
            local key = GetPriorityKey(priority)

            if key then
                groups[key] = groups[key] or NewCountGroup()
                groups[key].priority = priority
                groups[key].priorityText = GetPriorityText(priority)
                groups[key].runCount = groups[key].runCount + 1
                table.insert(groups[key].encounters, encounter)
            end
        end
    end

    local best = nil
    for _, group in pairs(groups) do
        if not best or group.runCount > best.runCount then
            best = group
        end
    end

    return best
end

local function BuildMostUsedTalent(encounters, selectedSpec)
    local groups = {}

    for _, encounter in ipairs(encounters or {}) do
        if MatchesSelectedSpec(encounter, selectedSpec) then
            local talentString = GetTalentString(encounter)

            if talentString and talentString ~= "" then
                groups[talentString] = groups[talentString] or NewCountGroup()
                groups[talentString].talentString = talentString
                groups[talentString].runCount = groups[talentString].runCount + 1
                table.insert(groups[talentString].encounters, encounter)
            end
        end
    end

    local list = {}
    for _, group in pairs(groups) do
        table.insert(list, group)
    end

    table.sort(list, function(a, b)
        return (a.runCount or 0) > (b.runCount or 0)
    end)

    local best = list[1]
    if best then
        best.variantIndex = 1
    end

    return best
end

local function BuildMetricBest(encounters, selectedSpec, metricInfo)
    if not metricInfo or not metricInfo.keylabKey then return nil end

    local key = metricInfo.keylabKey
    local lowerIsBetter = metricInfo.higherIsBetter == false
    local bestEncounter = nil
    local bestValue = nil

    for _, encounter in ipairs(encounters or {}) do
        if MatchesSelectedSpec(encounter, selectedSpec) then
            local value = GetMetricValue(encounter, key)
            if type(value) == "number" then
                if type(bestValue) ~= "number" then
                    bestValue = value
                    bestEncounter = encounter
                elseif lowerIsBetter then
                    if value < bestValue then
                        bestValue = value
                        bestEncounter = encounter
                    end
                else
                    if value > bestValue then
                        bestValue = value
                        bestEncounter = encounter
                    end
                end
            end
        end
    end

    if not bestEncounter then
        return nil
    end

    return {
        metricInfo = metricInfo,
        metricKey = key,
        label = metricInfo.label or key,
        lowerIsBetter = lowerIsBetter,
        encounter = bestEncounter,
        value = bestValue,
    }
end

local function CountUsableRuns(encounters, selectedSpec)
    local count = 0

    for _, encounter in ipairs(encounters or {}) do
        if MatchesSelectedSpec(encounter, selectedSpec) then
            count = count + 1
        end
    end

    return count
end

-- =========================================================
-- VISUAL HELPERS
-- =========================================================

local function MetricColor(metricKey)
    if metricKey == "damageDone" or metricKey == "dps" then return CFG.colors.orange end
    if metricKey == "healingDone" or metricKey == "hps" then return CFG.colors.green end
    if metricKey == "absorbs" then return CFG.colors.blue end
    if metricKey == "interrupts" or metricKey == "dispels" then return CFG.colors.purple end
    if metricKey == "damageTaken" or metricKey == "avoidableDamageTaken" or metricKey == "deaths" then return CFG.colors.red end
    return CFG.colors.blue
end

local function AddLine(parent, text, x, y, width, color, template)
    local fs = AddFont(parent, text, template or "GameFontHighlightSmall", x, y, width)
    ApplyColor(fs, color or CFG.colors.text)
    return fs
end

local function MakePanel(parent, x, y, width, height, title, borderColor, accentColor)
    local panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    panel:SetSize(width, height)
    StylePanel(panel, CFG.colors.cardBg, borderColor or CFG.colors.cardBorder)

    local accent = panel:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    accent:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
    accent:SetWidth(4)
    local c = accentColor or borderColor or CFG.colors.blue
    accent:SetColorTexture(c[1], c[2], c[3], c[4] or 1)

    if title and title ~= "" then
        AddLine(panel, title, 14, -10, width - 28, CFG.colors.gold, "GameFontNormal")
    end

    return panel
end

local function AddPriorityLine(parent, priority, x, y, width)
    if type(priority) ~= "table" then
        AddLine(parent, "No stat priority", x, y, width, CFG.colors.muted)
        return
    end

    local cursorX = x
    for i, stat in ipairs(priority) do
        local label = GetStatLabel(stat.key)
        local statWidth = math.max(50, math.min(92, string.len(label) * 7))
        AddLine(parent, label, cursorX, y, statWidth, GetStatColor(stat.key), "GameFontNormal")
        cursorX = cursorX + statWidth

        if i < #priority then
            AddLine(parent, ">", cursorX, y, 18, CFG.colors.soft, "GameFontNormal")
            cursorX = cursorX + 18
        end
    end
end

local function MakeSmallValue(parent, label, value, x, y, width, color)
    AddLine(parent, label, x, y, width, CFG.colors.muted, "GameFontDisableSmall")
    AddLine(parent, value, x, y - 17, width, color or CFG.colors.text, "GameFontNormalLarge")
end

local function BuildMostUsedStatCard(parent, x, y, group, totalRuns)
    local firstStat = group and group.priority and group.priority[1] and group.priority[1].key
    local color = GetStatColor(firstStat)
    local card = MakePanel(parent, x, y, 448, 92, "Most Used Stat Priority", CFG.colors.cardStrongBorder, color)

    if not group then
        AddLine(card, "No stat priority data found.", 14, -42, 420, CFG.colors.muted)
        return card
    end

    AddPriorityLine(card, group.priority, 14, -38, 420)

    local pct = 0
    if totalRuns and totalRuns > 0 then
        pct = (group.runCount or 0) / totalRuns
    end

    AddLine(card, tostring(group.runCount or 0) .. " run(s)", 14, -68, 110, CFG.colors.text, "GameFontNormal")
    AddLine(card, string.format("%.0f%% of selected runs", pct * 100), 120, -69, 180, CFG.colors.muted, "GameFontDisableSmall")

    return card
end

local function BuildMostUsedTalentCard(parent, x, y, group, totalRuns)
    local card = MakePanel(parent, x, y, 448, 92, "Most Used Talent Build", CFG.colors.cardStrongBorder, CFG.colors.blue)

    if not group then
        AddLine(card, "No talent build data found.", 14, -42, 420, CFG.colors.muted)
        return card
    end

    AddLine(card, "Talent Variant 1", 14, -38, 220, CFG.colors.blue, "GameFontNormalLarge")

    local pct = 0
    if totalRuns and totalRuns > 0 then
        pct = (group.runCount or 0) / totalRuns
    end

    AddLine(card, tostring(group.runCount or 0) .. " run(s)", 14, -68, 110, CFG.colors.text, "GameFontNormal")
    AddLine(card, string.format("%.0f%% of selected runs", pct * 100), 120, -69, 180, CFG.colors.muted, "GameFontDisableSmall")
    AddLine(card, "Open Talent Builds to view/copy the full string.", 250, -69, 180, CFG.colors.muted, "GameFontDisableSmall")

    return card
end

local function Average(values)
    if type(values) ~= "table" or #values == 0 then return nil end
    local total = 0
    for _, value in ipairs(values) do
        total = total + (SafeNumber(value) or 0)
    end
    return total / #values
end


local function AddTrendIcon(parent, trend, x, y, size)
    local icon = parent:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPRIGHT", parent, "TOPRIGHT", x, y)
    icon:SetSize(50, 50)

    local key = trend and trend.trendKey or "stable"
    if key == "up" then
        icon:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
    elseif key == "down" then
        icon:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    else
        icon:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    end

    local color = trend and trend.color or CFG.colors.soft
    icon:SetVertexColor(color[1], color[2], color[3], color[4] or 1)

    return icon
end

local function BuildMetricDirection(encounters, selectedSpec, metricKey)
    local metricInfo = GetMetricInfoByKey(metricKey)
    if not metricInfo then return nil end

    local values = {}
    for _, encounter in ipairs(encounters or {}) do
        if MatchesSelectedSpec(encounter, selectedSpec) then
            local value = GetMetricValue(encounter, metricKey)
            if type(value) == "number" then
                table.insert(values, {
                    timestamp = encounter.timestamp or 0,
                    value = value,
                })
            end
        end
    end

    table.sort(values, function(a, b) return (a.timestamp or 0) < (b.timestamp or 0) end)

    if #values < 2 then
        return {
            metricKey = metricKey,
            label = metricInfo.label or metricKey,
            direction = "EVEN",
            trendKey = "stable",
            trendText = "Need more runs",
            recentAverage = values[1] and values[1].value or nil,
            priorAverage = nil,
            runCount = #values,
            color = CFG.colors.muted,
        }
    end

    local recent = {}
    local prior = {}
    local recentStart = math.max(1, #values - 2)

    for i, item in ipairs(values) do
        if i >= recentStart then
            table.insert(recent, item.value)
        else
            table.insert(prior, item.value)
        end
    end

    if #prior == 0 and #recent > 1 then
        table.insert(prior, recent[1])
        table.remove(recent, 1)
    end

    local recentAvg = Average(recent)
    local priorAvg = Average(prior)
    local lowerIsBetter = metricInfo.higherIsBetter == false
    local diff = (recentAvg or 0) - (priorAvg or 0)
    local pct = 0
    if priorAvg and math.abs(priorAvg) > 0 then
        pct = diff / priorAvg
    end

    local threshold = 0.03
    local direction = "EVEN"
    local trendKey = "stable"
    local trendText = "Stable"
    local color = CFG.colors.soft

    if math.abs(pct) >= threshold then
        if lowerIsBetter then
            if diff < 0 then
                direction = "DOWN"
                trendKey = "down"
                trendText = "Improving"
                color = CFG.colors.green
            else
                direction = "UP"
                trendKey = "up"
                trendText = "Increasing"
                color = CFG.colors.warning
            end
        else
            if diff > 0 then
                direction = "UP"
                trendKey = "up"
                trendText = "Improving"
                color = CFG.colors.green
            else
                direction = "DOWN"
                trendKey = "down"
                trendText = "Decreasing"
                color = CFG.colors.warning
            end
        end
    end

    return {
        metricKey = metricKey,
        label = metricInfo.label or metricKey,
        direction = direction,
        trendKey = trendKey,
        trendText = trendText,
        recentAverage = recentAvg,
        priorAverage = priorAvg,
        percent = pct,
        runCount = #values,
        color = color,
    }
end

local function BuildTrendTile(parent, x, y, trend)
    local color = trend and trend.color or CFG.colors.blue
    local panel = MakePanel(parent, x, y, 213, 78, "", CFG.colors.cardBorder, color)

    if not trend then
        AddLine(panel, "No trend", 12, -12, 190, CFG.colors.muted)
        return panel
    end

    AddLine(panel, trend.label, 12, -10, 154, CFG.colors.gold, "GameFontNormal")
    AddTrendIcon(panel, trend, -12, -8, 18)
    AddLine(panel, trend.trendText or "Stable", 12, -34, 150, color, "GameFontNormalLarge")

    if trend.recentAverage then
        AddLine(panel, "Recent avg: " .. FormatMetric(trend.metricKey, trend.recentAverage), 12, -58, 185, CFG.colors.muted, "GameFontDisableSmall")
    else
        AddLine(panel, "Need more runs", 12, -58, 185, CFG.colors.muted, "GameFontDisableSmall")
    end

    return panel
end

local function GetDungeonOptions(encounters, selectedSpec)
    local seen = {}
    local list = {
        { text = "All Dungeons", value = nil },
    }

    for _, encounter in ipairs(encounters or {}) do
        if MatchesSelectedSpec(encounter, selectedSpec) then
            local dungeonName = GetDungeonName(encounter)
            if dungeonName and dungeonName ~= "" and dungeonName ~= "Unknown Dungeon" and not seen[dungeonName] then
                seen[dungeonName] = true
                table.insert(list, {
                    text = dungeonName,
                    value = dungeonName,
                })
            end
        end
    end

    table.sort(list, function(a, b)
        if a.text == "All Dungeons" then return true end
        if b.text == "All Dungeons" then return false end
        return tostring(a.text) < tostring(b.text)
    end)

    return list
end

local function GetDungeonText(dungeonName)
    return dungeonName or "All Dungeons"
end

local function MatchesSelectedDungeon(encounter, selectedDungeon)
    if not selectedDungeon then return true end
    return GetDungeonName(encounter) == selectedDungeon
end

local function FilterTrendEncounters(encounters, selectedSpec, selectedDungeon)
    local list = {}

    for _, encounter in ipairs(encounters or {}) do
        if MatchesSelectedSpec(encounter, selectedSpec) and MatchesSelectedDungeon(encounter, selectedDungeon) then
            table.insert(list, encounter)
        end
    end

    table.sort(list, function(a, b)
        return (a.timestamp or 0) < (b.timestamp or 0)
    end)

    return list
end

local function CountTrendRuns(encounters, selectedSpec, selectedDungeon)
    local count = 0

    for _, encounter in ipairs(encounters or {}) do
        if MatchesSelectedSpec(encounter, selectedSpec) and MatchesSelectedDungeon(encounter, selectedDungeon) then
            count = count + 1
        end
    end

    return count
end

local function BuildMetricDirectionFromList(encounters, metricKey)
    local metricInfo = GetMetricInfoByKey(metricKey)
    if not metricInfo then return nil end

    local values = {}
    for _, encounter in ipairs(encounters or {}) do
        local value = GetMetricValue(encounter, metricKey)
        if type(value) == "number" then
            table.insert(values, {
                timestamp = encounter.timestamp or 0,
                value = value,
            })
        end
    end

    table.sort(values, function(a, b) return (a.timestamp or 0) < (b.timestamp or 0) end)

    if #values < 2 then
        return {
            metricKey = metricKey,
            label = metricInfo.label or metricKey,
            direction = "EVEN",
            trendKey = "stable",
            trendText = "Need more runs",
            recentAverage = values[1] and values[1].value or nil,
            priorAverage = nil,
            runCount = #values,
            color = CFG.colors.muted,
        }
    end

    local recent = {}
    local prior = {}
    local recentStart = math.max(1, #values - 2)

    for i, item in ipairs(values) do
        if i >= recentStart then
            table.insert(recent, item.value)
        else
            table.insert(prior, item.value)
        end
    end

    if #prior == 0 and #recent > 1 then
        table.insert(prior, recent[1])
        table.remove(recent, 1)
    end

    local recentAvg = Average(recent)
    local priorAvg = Average(prior)
    local lowerIsBetter = metricInfo.higherIsBetter == false
    local diff = (recentAvg or 0) - (priorAvg or 0)
    local pct = 0
    if priorAvg and math.abs(priorAvg) > 0 then
        pct = diff / priorAvg
    end

    local threshold = 0.03
    local direction = "EVEN"
    local trendKey = "stable"
    local trendText = "Stable"
    local color = CFG.colors.soft

    if math.abs(pct) >= threshold then
        if lowerIsBetter then
            if diff < 0 then
                direction = "DOWN"
                trendKey = "down"
                trendText = "Improving"
                color = CFG.colors.green
            else
                direction = "UP"
                trendKey = "up"
                trendText = "Increasing"
                color = CFG.colors.warning
            end
        else
            if diff > 0 then
                direction = "UP"
                trendKey = "up"
                trendText = "Improving"
                color = CFG.colors.green
            else
                direction = "DOWN"
                trendKey = "down"
                trendText = "Decreasing"
                color = CFG.colors.warning
            end
        end
    end

    return {
        metricKey = metricKey,
        label = metricInfo.label or metricKey,
        direction = direction,
        trendKey = trendKey,
        trendText = trendText,
        recentAverage = recentAvg,
        priorAverage = priorAvg,
        percent = pct,
        runCount = #values,
        color = color,
    }
end

local function AverageMetric(encounters, metricKey)
    local values = {}

    for _, encounter in ipairs(encounters or {}) do
        local value = GetMetricValue(encounter, metricKey)
        if type(value) == "number" then
            table.insert(values, value)
        end
    end

    return Average(values), #values
end

local function BuildMetricComparison(metricKey, baselineEncounters, progressionEncounters)
    local metricInfo = GetMetricInfoByKey(metricKey)
    if not metricInfo then return nil end

    local baselineAvg, baselineCount = AverageMetric(baselineEncounters, metricKey)
    local progressionAvg, progressionCount = AverageMetric(progressionEncounters, metricKey)

    if not baselineAvg or not progressionAvg or baselineCount == 0 or progressionCount == 0 then
        return {
            metricKey = metricKey,
            label = metricInfo.label or metricKey,
            direction = "EVEN",
            trendKey = "stable",
            trendText = "Need more runs",
            recentAverage = progressionAvg,
            priorAverage = baselineAvg,
            runCount = progressionCount + baselineCount,
            color = CFG.colors.muted,
        }
    end

    local lowerIsBetter = metricInfo.higherIsBetter == false
    local diff = progressionAvg - baselineAvg
    local pct = 0
    if math.abs(baselineAvg) > 0 then
        pct = diff / baselineAvg
    end

    local threshold = 0.03
    local direction = "EVEN"
    local trendKey = "stable"
    local trendText = "Stable"
    local color = CFG.colors.soft

    if math.abs(pct) >= threshold then
        if lowerIsBetter then
            if diff < 0 then
                direction = "DOWN"
                trendKey = "down"
                trendText = "Improving"
                color = CFG.colors.green
            else
                direction = "UP"
                trendKey = "up"
                trendText = "Increasing"
                color = CFG.colors.warning
            end
        else
            if diff > 0 then
                direction = "UP"
                trendKey = "up"
                trendText = "Improving"
                color = CFG.colors.green
            else
                direction = "DOWN"
                trendKey = "down"
                trendText = "Decreasing"
                color = CFG.colors.warning
            end
        end
    end

    return {
        metricKey = metricKey,
        label = metricInfo.label or metricKey,
        direction = direction,
        trendKey = trendKey,
        trendText = trendText,
        recentAverage = progressionAvg,
        priorAverage = baselineAvg,
        percent = pct,
        runCount = progressionCount + baselineCount,
        color = color,
    }
end

local TREND_METRICS = {
    "dps",
    "hps",
    "damageTaken",
    "avoidableDamageTaken",
    "interrupts",
    "dispels",
    "absorbs",
    "deaths",
}

local function BuildTrendTile(parent, x, y, trend, averageLabel)
    local color = trend and trend.color or CFG.colors.blue
    local panel = MakePanel(parent, x, y, 213, 78, "", CFG.colors.cardBorder, color)

    if not trend then
        AddLine(panel, "No trend", 12, -12, 190, CFG.colors.muted)
        return panel
    end

    AddLine(panel, trend.label, 12, -10, 154, CFG.colors.gold, "GameFontNormal")
    AddTrendIcon(panel, trend, -12, -8, 18)
    AddLine(panel, trend.trendText or "Stable", 12, -34, 150, color, "GameFontNormalLarge")

    if trend.recentAverage then
        AddLine(panel, (averageLabel or "Recent avg") .. ": " .. FormatMetric(trend.metricKey, trend.recentAverage), 12, -58, 185, CFG.colors.muted, "GameFontDisableSmall")
    else
        AddLine(panel, "Need more runs", 12, -58, 185, CFG.colors.muted, "GameFontDisableSmall")
    end

    return panel
end

local function BuildMessagePanel(parent, x, y, title, message, accentColor)
    local panel = MakePanel(parent, x, y, 908, 96, title, CFG.colors.cardBorder, accentColor or CFG.colors.warning)
    AddLine(panel, message, 14, -40, 860, CFG.colors.muted, "GameFontNormal")
    return panel
end

local function BuildPerformanceTrends(parent, x, y, encounters, title, subtitle, averageLabel)
    local panel = MakePanel(parent, x, y, 908, 210, title or "Performance Direction", CFG.colors.cardBorder, CFG.colors.green)
    if subtitle and subtitle ~= "" then
        AddLine(panel, subtitle, 14, -32, 720, CFG.colors.muted, "GameFontDisableSmall")
    end

    for i, key in ipairs(TREND_METRICS) do
        local row = math.floor((i - 1) / 4)
        local col = (i - 1) % 4
        local tx = 14 + (col * 221)
        local ty = -44 - (row * 88)
        BuildTrendTile(panel, tx, ty, BuildMetricDirectionFromList(encounters, key), averageLabel)
    end

    return panel
end

local function FindHighestKey(encounters)
    local highest = nil

    for _, encounter in ipairs(encounters or {}) do
        local keyLevel = tonumber(GetKeyLevel(encounter)) or 0
        if not highest or keyLevel > highest then
            highest = keyLevel
        end
    end

    return highest
end

local function SplitProgressionRuns(encounters, highestKey)
    local progression = {}
    local baseline = {}

    for _, encounter in ipairs(encounters or {}) do
        local keyLevel = tonumber(GetKeyLevel(encounter)) or 0
        if keyLevel == highestKey then
            table.insert(progression, encounter)
        elseif keyLevel < highestKey then
            table.insert(baseline, encounter)
        end
    end

    return progression, baseline
end

local function BuildProgressionSnapshot(parent, x, y, encounters, selectedDungeon)
    if not selectedDungeon then
        return BuildMessagePanel(parent, x, y, "Progression Snapshot", "Choose a dungeon above to view progression direction for that dungeon.", CFG.colors.blue)
    end

    if #encounters < 2 then
        return BuildMessagePanel(parent, x, y, "Progression Snapshot", "Run this dungeon more to unlock progression trends.", CFG.colors.warning)
    end

    local highestKey = FindHighestKey(encounters)
    if not highestKey then
        return BuildMessagePanel(parent, x, y, "Progression Snapshot", "Run this dungeon more to unlock progression trends.", CFG.colors.warning)
    end

    local progressionRuns, baselineRuns = SplitProgressionRuns(encounters, highestKey)
    if #baselineRuns == 0 then
        return BuildMessagePanel(parent, x, y, "Progression Snapshot", "Run this dungeon at another key level to unlock progression trends.", CFG.colors.warning)
    end

    local title = tostring(selectedDungeon) .. " Progression"
    local subtitle = "Highest captured: +" .. tostring(highestKey) .. " compared to lower saved runs."
    local panel = MakePanel(parent, x, y, 908, 210, title, CFG.colors.cardBorder, CFG.colors.gold)
    AddLine(panel, subtitle, 14, -32, 760, CFG.colors.muted, "GameFontDisableSmall")

    for i, key in ipairs(TREND_METRICS) do
        local row = math.floor((i - 1) / 4)
        local col = (i - 1) % 4
        local tx = 14 + (col * 221)
        local ty = -44 - (row * 88)
        BuildTrendTile(panel, tx, ty, BuildMetricComparison(key, baselineRuns, progressionRuns), "+" .. tostring(highestKey) .. " avg")
    end

    return panel
end

-- =========================================================
-- REFRESH
-- =========================================================

function Trends:RefreshDropdowns()
    self.allEncounters = GetEncounterList()

    local specOptions = GetSpecOptions(self.allEncounters)
    local hasSelectedSpec = false

    for _, option in ipairs(specOptions) do
        if option.value == self.selectedSpec then
            hasSelectedSpec = true
            break
        end
    end

    if not hasSelectedSpec then
        self.selectedSpec = nil
    end

    local dungeonOptions = GetDungeonOptions(self.allEncounters, self.selectedSpec)
    local hasSelectedDungeon = false

    for _, option in ipairs(dungeonOptions) do
        if option.value == self.selectedDungeon then
            hasSelectedDungeon = true
            break
        end
    end

    if not hasSelectedDungeon then
        self.selectedDungeon = nil
    end

    SetDropdownText(self.specDropdown, GetSpecText(self.selectedSpec))
    SetDropdownText(self.dungeonDropdown, GetDungeonText(self.selectedDungeon))
end

function Trends:RefreshContent()
    ClearChildren(self.content)

    local encounters = self.allEncounters or GetEncounterList()
    local filtered = FilterTrendEncounters(encounters, self.selectedSpec, self.selectedDungeon)
    local usableCount = #filtered

    if self.summaryText then
        local label = self.selectedDungeon and tostring(self.selectedDungeon) or "selected sample"
        self.summaryText:SetText(tostring(usableCount) .. " completed run(s) in " .. label)
    end

    if usableCount == 0 then
        BuildMessagePanel(self.content, 0, 0, "Performance Direction", "Run this dungeon more to unlock trends.", CFG.colors.warning)
        self.content:SetHeight(120)
        return
    end

    if self.selectedDungeon and usableCount < 2 then
        BuildMessagePanel(self.content, 0, 0, "Performance Direction", "Run this dungeon more to unlock trends.", CFG.colors.warning)
        self.content:SetHeight(120)
        return
    end

    if self.selectedDungeon then
        BuildProgressionSnapshot(self.content, 0, 0, filtered, self.selectedDungeon)
        self.content:SetHeight(240)
        return
    end

    BuildPerformanceTrends(
        self.content,
        0,
        0,
        filtered,
        "Performance Direction",
        "Recent runs compared against earlier saved runs.",
        "Recent avg"
    )

    self.content:SetHeight(240)
end

function Trends:Refresh()
    if not self.frame then return end
    self:RefreshDropdowns()
    self:RefreshContent()
end

-- =========================================================
-- CREATE
-- =========================================================

function Trends:Create(parent)
    local frame = CreateFrame("Frame", "KeyLabTrendsTab", parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    StylePanel(frame, CFG.colors.bg, {0, 0, 0, 0})

    self.frame = frame

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", CFG.header.x, CFG.header.y)
    title:SetText("Trends")
    ApplyColor(title, CFG.colors.gold)

    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetWidth(CFG.header.subtitleWidth)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetText("Shows visual performance direction by spec, dungeon, and captured progression runs.")
    ApplyColor(subtitle, CFG.colors.muted)

    self.summaryText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.summaryText:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -10)
    self.summaryText:SetText("Loading trends...")
    ApplyColor(self.summaryText, CFG.colors.soft)

    local controls = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    controls:SetPoint("TOPLEFT", frame, "TOPLEFT", CFG.controls.x, CFG.controls.y)
    controls:SetSize(CFG.controls.width, CFG.controls.height)
    StylePanel(controls, CFG.colors.controlBg, CFG.colors.cardBorder)

    self.specDropdown = MakeDropdown(controls, CFG.controls.specWidth, CFG.controls.specX, CFG.controls.labelY, "Spec", function(_, level)
        local options = GetSpecOptions(Trends.allEncounters or GetEncounterList())

        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.func = function()
                Trends.selectedSpec = option.value
                Trends.selectedDungeon = nil
                Trends:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    self.dungeonDropdown = MakeDropdown(controls, CFG.controls.dungeonWidth, CFG.controls.dungeonX, CFG.controls.labelY, "Dungeon", function(_, level)
        local options = GetDungeonOptions(Trends.allEncounters or GetEncounterList(), Trends.selectedSpec)

        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.func = function()
                Trends.selectedDungeon = option.value
                Trends:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", CFG.content.x, CFG.content.y)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 18)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(CFG.content.width, 700)
    scrollFrame:SetScrollChild(content)

    self.scrollFrame = scrollFrame
    self.content = content

    frame:SetScript("OnShow", function()
        Trends:Refresh()
    end)

    return frame
end

function KeyLab_CreateTrendsTab(parent)
    return Trends:Create(parent)
end

if KeyLab.RegisterTab then
    KeyLab.RegisterTab("Trends", function(parent)
        return Trends:Create(parent)
    end)
end

return Trends
