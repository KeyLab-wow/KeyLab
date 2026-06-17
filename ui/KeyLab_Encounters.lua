-- KeyLab_Encounters.lua
-- Encounters tab for KeyLab / M+ Journal
--
-- Purpose:
--   Show completed Mythic+ encounter history as paged selectable cards.
--
-- Current UI direction:
--   - No asset/logo/icon dependency.
--   - Uses KeyLab mapping + formatter files as source of truth.
--   - Newest runs first.
--   - 5 compact encounter cards per page.
--   - Selecting a card highlights it and shows details in the always-visible panel below.
--   - Cards stay short: dungeon, key level, spec/class, date/time only.

local ADDON_NAME, KeyLab = ...

KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.UI = KeyLab.UI or {}
KeyLab.Tabs = KeyLab.Tabs or {}

local Encounters = {}
KeyLab.Tabs.Encounters = Encounters

-- =========================================================
-- EASY EDIT SETTINGS
-- =========================================================

local CFG = {
    pageSize = 5,

    frame = {
        width = 960,
        height = 820,
    },

    colors = {
        bg = {0.018, 0.026, 0.056, 0.96},
        controlBg = {0.026, 0.046, 0.088, 0.94},

        cardBg = {0.030, 0.052, 0.098, 0.94},
        cardBorder = {0.240, 0.380, 0.620, 0.62},
        cardHoverBorder = {0.300, 0.420, 0.600, 0.78},
        cardSelectedBorder = {0.620, 0.560, 0.410, 0.78},

        detailBg = {0.024, 0.042, 0.082, 0.96},
        detailBorder = {0.220, 0.340, 0.560, 0.56},
        noteBg = {0.030, 0.052, 0.094, 0.92},

        text = {0.940, 0.960, 0.990, 1.0},
        muted = {0.680, 0.730, 0.820, 1.0},
        soft = {0.780, 0.830, 0.900, 1.0},
        gold = {0.820, 0.760, 0.580, 1.0},
        blue = {0.500, 0.680, 0.940, 1.0},
        warning = {0.840, 0.440, 0.420, 1.0},
        divider = {0.440, 0.580, 0.780, 0.32},
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
        height = 74,

        dungeonX = 18,
        keyX = 255,
        specX = 390,
        dateX = 610,
        labelY = -12,

        dungeonWidth = 185,
        keyWidth = 90,
        specWidth = 170,
        dateWidth = 150,
    },

    list = {
        x = 12,
        y = -172,
        width = 928,
    },

    card = {
        x = 0,
        firstY = 0,
        width = 928,
        height = 44,
        gap = 8,
        padding = 12,

        rankX = 12,
        dungeonX = 46,
        specX = 390,
        dateX = 660,
    },

    details = {
        x = 12,
        width = 928,
        minHeight = 300,
        maxHeight = 300,
        gapAfterCards = 18,
        padding = 14,
        rowHeight = 15,

        colRunX = 16,
        colStatsX = 205,
        colTalentX = 430,
        colOutcomesX = 645,

        colRunW = 170,
        colStatsW = 200,
        colTalentW = 190,
        colOutcomesW = 245,
    },

    pager = {
        y = 18,
        labelX = 18,
        labelWidth = 360,
        prevX = 680,
        nextX = 780,
        buttonWidth = 90,
        buttonHeight = 24,
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
    local edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border"
    local edgeSize = 7
    local insets = { left = 2, right = 2, top = 2, bottom = 2 }
    if frame.GetHeight and (frame:GetHeight() or 0) <= 20 then
        edgeFile = "Interface\\Buttons\\WHITE8x8"
        edgeSize = 1
        insets = nil
    end

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = edgeFile,
        tile = false,
        edgeSize = edgeSize,
        insets = insets,
    })
    frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
end

local function SetBorder(frame, border)
    if frame and border then
        frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
    end
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

local function AddSectionTitle(parent, text, x, y, width)
    local fs = AddFont(parent, text, "GameFontNormal", x, y, width or 200)
    ApplyColor(fs, CFG.colors.gold)
    return fs
end

local function AddVerticalDivider(parent, x, y, height)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    line:SetSize(1, height or 230)
    local c = CFG.colors.divider
    line:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
    return line
end

local function SafeText(value, fallback)
    if value == nil or value == "" then
        return fallback or "-"
    end
    return tostring(value)
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
    return tostring(math.floor(value + 0.5))
end

local function FormatDateTime(value)
    if Fmt().DateTime then return Fmt().DateTime(value) end
    if type(value) ~= "number" then return "-" end
    return date("%b %d, %Y %I:%M %p", value)
end

local function FormatDuration(value)
    if Fmt().Duration then return Fmt().Duration(value) end
    if type(value) ~= "number" then return "-" end
    local mins = math.floor(value / 60)
    local secs = math.floor(value % 60)
    return string.format("%d:%02d", mins, secs)
end

local function FormatStat(statKey, value)
    if Fmt().Stat then return Fmt().Stat(statKey, value) end
    return FormatNumber(value)
end

local function FormatMetric(metricKey, value)
    if Fmt().Metric then return Fmt().Metric(metricKey, value) end
    return FormatNumber(value)
end

local function SetDropdownText(dropdown, text)
    UIDropDownMenu_SetText(dropdown, text or "Select")
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

local function ClearChildren(frame)
    if not frame then return end

    -- Child frames are things like EditBoxes, Buttons, and note boxes.
    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        child:Hide()
        child:SetParent(nil)
    end

    -- FontStrings and divider textures are regions, not children.
    -- If we do not hide these, every refresh draws another copy on top.
    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        region:Hide()
    end
end

-- =========================================================
-- DATA HELPERS
-- =========================================================


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

    -- Strict current-character mode:
    -- if a run does not have character identity, do not show it in character-specific tabs.
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
local function FilterCurrentCharacterEncounters(encounters)
    local filtered = {}

    for _, encounter in ipairs(encounters or {}) do
        if EncounterMatchesCurrentCharacter(encounter) then
            table.insert(filtered, encounter)
        end
    end

    return filtered
end


local function GetEncounterList()
    if KeyLab.DB and KeyLab.DB.Encounters and KeyLab.DB.Encounters.GetFiltered then
        local list = KeyLab.DB.Encounters.GetFiltered({
            includeInterrupted = true,
            includeExcluded = true,
        })
        return FilterCurrentCharacterEncounters(list)
    end

    if KeyLabDB and type(KeyLabDB.encounters) == "table" then
        local copy = {}
        for _, encounter in ipairs(KeyLabDB.encounters) do
            if EncounterMatchesCurrentCharacter(encounter) then
                table.insert(copy, encounter)
            end
        end
        table.sort(copy, function(a, b)
            return (a.timestamp or 0) > (b.timestamp or 0)
        end)
        return copy
    end

    return {}
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

local function GetFlags(encounter)
    return encounter and encounter.flags or {}
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

local function GetClassName(encounter)
    return GetPlayer(encounter).class or encounter.class or encounter.className or "Unknown Class"
end

local function GetTalentString(encounter)
    return GetTalents(encounter).talentString or encounter.talentString or ""
end

local function IsInterrupted(encounter)
    local flags = GetFlags(encounter)
    return flags.interrupted == true or encounter.interrupted == true
end

local function GetResultText(encounter)
    if IsInterrupted(encounter) then
        return "Interrupted"
    end
    return encounter.result or "Completed"
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

local function GetMetricOptions()
    local list = {
        { text = "All Outcomes", value = nil },
    }

    local order = KeyLab.Mapping and KeyLab.Mapping.MetricOrder or {}
    for _, metricType in ipairs(order) do
        local info = GetMetricInfoByType(metricType)
        if info and info.store == true then
            table.insert(list, {
                text = info.label or info.keylabKey,
                value = info.keylabKey,
            })
        end
    end

    return list
end

local function GetMetricText(metricKey)
    if not metricKey then return "All Outcomes" end
    local info = GetMetricInfoByKey(metricKey)
    return info and info.label or tostring(metricKey)
end

local function GetDungeonOptions(encounters)
    local seen = {}
    local list = {
        { text = "All", value = nil },
    }

    for _, encounter in ipairs(encounters or {}) do
        local mapID = GetMapID(encounter)
        local name = GetDungeonName(encounter)

        local key = mapID or name
        if key and not seen[key] then
            seen[key] = true
            table.insert(list, {
                text = name,
                value = mapID,
            })
        end
    end

    table.sort(list, function(a, b)
        if a.text == "All" then return true end
        if b.text == "All" then return false end
        return tostring(a.text) < tostring(b.text)
    end)

    return list
end

local function GetKeyOptions(encounters, selectedMapID)
    local seen = {}
    local list = {
        { text = "All", value = nil },
    }

    for _, encounter in ipairs(encounters or {}) do
        if not selectedMapID or GetMapID(encounter) == selectedMapID then
            local keyLevel = GetKeyLevel(encounter)
            if keyLevel and not seen[keyLevel] then
                seen[keyLevel] = true
                table.insert(list, {
                    text = "+" .. tostring(keyLevel),
                    value = keyLevel,
                })
            end
        end
    end

    table.sort(list, function(a, b)
        if a.text == "All" then return true end
        if b.text == "All" then return false end
        return tonumber(a.value or 0) > tonumber(b.value or 0)
    end)

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

local function GetSpecText(value)
    return value or "All Specs"
end

local function GetStartOfToday()
    local now = time()
    local d = date("*t", now)
    d.hour = 0
    d.min = 0
    d.sec = 0
    return time(d)
end

local function GetDateOptions()
    return {
        { text = "All Dates", value = nil },
        { text = "Today", value = "today" },
        { text = "Last 7 Days", value = "7d" },
        { text = "Last 30 Days", value = "30d" },
    }
end

local function GetDateText(value)
    if value == "today" then return "Today" end
    if value == "7d" then return "Last 7 Days" end
    if value == "30d" then return "Last 30 Days" end
    return "All Dates"
end

local function MatchesDateFilter(encounter, dateFilter)
    if not dateFilter then
        return true
    end

    local ts = tonumber(encounter and encounter.timestamp or 0) or 0
    if ts <= 0 then
        return false
    end

    if dateFilter == "today" then
        return ts >= GetStartOfToday()
    elseif dateFilter == "7d" then
        return ts >= (time() - (7 * 24 * 60 * 60))
    elseif dateFilter == "30d" then
        return ts >= (time() - (30 * 24 * 60 * 60))
    end

    return true
end

local function MatchesFilters(encounter, selectedMapID, selectedKeyLevel, selectedSpec, dateFilter)
    if selectedMapID and GetMapID(encounter) ~= selectedMapID then
        return false
    end

    if selectedKeyLevel and tonumber(GetKeyLevel(encounter) or 0) ~= tonumber(selectedKeyLevel) then
        return false
    end

    if selectedSpec and GetSpecName(encounter) ~= selectedSpec then
        return false
    end

    if not MatchesDateFilter(encounter, dateFilter) then
        return false
    end

    return true
end

local function FilterEncounters(encounters, selectedMapID, selectedKeyLevel, selectedSpec, dateFilter)
    local results = {}

    for _, encounter in ipairs(encounters or {}) do
        if MatchesFilters(encounter, selectedMapID, selectedKeyLevel, selectedSpec, dateFilter) then
            table.insert(results, encounter)
        end
    end

    table.sort(results, function(a, b)
        return (a.timestamp or 0) > (b.timestamp or 0)
    end)

    return results
end

-- =========================================================
-- DETAIL PANEL
-- =========================================================

local function AddDetailRow(parent, label, value, x, y, width)
    local l = AddFont(parent, label, "GameFontDisableSmall", x, y, width or 130)
    ApplyColor(l, CFG.colors.muted)

    local v = AddFont(parent, value, "GameFontHighlightSmall", x, y - 13, width or 130)
    ApplyColor(v, CFG.colors.text)

    return y - 35
end

local function AddStatRows(parent, encounter, x, y, width)
    local stats = GetStats(encounter)
    local order = KeyLab.Mapping and KeyLab.Mapping.StatOrder or {}
    local mapping = KeyLab.Mapping and KeyLab.Mapping.Stats or {}
    local shown = 0

    local hidden = 0
    local maxShown = 13

    for _, statKey in ipairs(order) do
        local info = mapping[statKey]
        local value = SafeNumber(stats and stats[statKey])

        if info and info.store == true and value and value > 0 then
            if shown < maxShown then
                local label = info.label or statKey
                local text = label .. ": " .. FormatStat(statKey, value)
                local row = AddFont(parent, text, "GameFontHighlightSmall", x, y, width)
                ApplyColor(row, CFG.colors.text)
                y = y - CFG.details.rowHeight
                shown = shown + 1
            else
                hidden = hidden + 1
            end
        end
    end

    if hidden > 0 then
        local more = AddFont(parent, "+" .. tostring(hidden) .. " more stats", "GameFontDisableSmall", x, y, width)
        ApplyColor(more, CFG.colors.muted)
        y = y - CFG.details.rowHeight
    end

    if shown == 0 then
        local none = AddFont(parent, "No stat snapshot available", "GameFontDisableSmall", x, y, width)
        ApplyColor(none, CFG.colors.muted)
        y = y - CFG.details.rowHeight
    end

    return y
end

local function AddOutcomeRows(parent, encounter, x, y, width)
    local order = KeyLab.Mapping and KeyLab.Mapping.MetricOrder or {}
    local shown = 0

    for _, metricType in ipairs(order) do
        local info = GetMetricInfoByType(metricType)
        if info and info.store == true then
            local key = info.keylabKey
            local value = GetMetricValue(encounter, key)

            if value ~= nil then
                local label = info.label or key
                local text = label .. ": " .. FormatMetric(key, value)
                local row = AddFont(parent, text, "GameFontHighlightSmall", x, y, width)
                ApplyColor(row, CFG.colors.text)
                y = y - CFG.details.rowHeight
                shown = shown + 1
            end
        end
    end

    if shown == 0 then
        local none = AddFont(parent, "No captured outcomes available", "GameFontDisableSmall", x, y, width)
        ApplyColor(none, CFG.colors.muted)
        y = y - CFG.details.rowHeight
    end

    return y
end

local function BuildDetails(panel, encounter)
    ClearChildren(panel)
    StylePanel(panel, CFG.colors.detailBg, CFG.colors.detailBorder)

    local padding = CFG.details.padding

    if not encounter then
        local title = AddFont(panel, "Encounter Details", "GameFontNormalLarge", padding, -16, CFG.details.width - 28)
        ApplyColor(title, CFG.colors.gold)

        local body = AddFont(panel, "Select an encounter above to view run details, stat snapshot, talent string, and captured outcomes.", "GameFontHighlightSmall", padding, -48, CFG.details.width - 28)
        ApplyColor(body, CFG.colors.muted)

        panel:SetHeight(CFG.details.minHeight)
        return CFG.details.minHeight
    end

    local topY = -14
    local spec = GetSpecName(encounter)
    local headerText = "Mythic+ " .. spec .. " - Encounter Details"

    local header = AddFont(panel, headerText, "GameFontNormalLarge", padding, topY, CFG.details.width - 28)
    ApplyColor(header, CFG.colors.gold)

    local sub = AddFont(panel, GetDungeonName(encounter) .. " +" .. tostring(GetKeyLevel(encounter)) .. " • " .. FormatDateTime(encounter.timestamp), "GameFontDisableSmall", padding, topY - 24, CFG.details.width - 28)
    ApplyColor(sub, CFG.colors.muted)

    local sectionTop = topY - 62

    AddVerticalDivider(panel, CFG.details.colStatsX - 12, sectionTop + 4, 225)
    AddVerticalDivider(panel, CFG.details.colTalentX - 12, sectionTop + 4, 225)
    AddVerticalDivider(panel, CFG.details.colOutcomesX - 12, sectionTop + 4, 225)

    -- Run Details
    AddSectionTitle(panel, "Run Details", CFG.details.colRunX, sectionTop, CFG.details.colRunW)
    local yRun = sectionTop - 24
    yRun = AddDetailRow(panel, "Result", GetResultText(encounter), CFG.details.colRunX, yRun, CFG.details.colRunW)
    yRun = AddDetailRow(panel, "Dungeon", GetDungeonName(encounter), CFG.details.colRunX, yRun, CFG.details.colRunW)
    yRun = AddDetailRow(panel, "Key Level", "+" .. tostring(GetKeyLevel(encounter)), CFG.details.colRunX, yRun, CFG.details.colRunW)

    local challenge = GetChallenge(encounter)
    if challenge.durationSeconds then
        yRun = AddDetailRow(panel, "Duration", FormatDuration(challenge.durationSeconds), CFG.details.colRunX, yRun, CFG.details.colRunW)
    end

    -- Stats
    AddSectionTitle(panel, "Stats (At Time of Run)", CFG.details.colStatsX, sectionTop, CFG.details.colStatsW)
    local yStats = AddStatRows(panel, encounter, CFG.details.colStatsX, sectionTop - 24, CFG.details.colStatsW)

    -- Talent String
    AddSectionTitle(panel, "Talent String", CFG.details.colTalentX, sectionTop, CFG.details.colTalentW)
    local talentString = GetTalentString(encounter)

    if talentString ~= "" then
        local editBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
        editBox:SetPoint("TOPLEFT", panel, "TOPLEFT", CFG.details.colTalentX + 4, sectionTop - 26)
        editBox:SetSize(CFG.details.colTalentW - 8, 30)
        editBox:SetAutoFocus(false)
        editBox:SetFontObject("GameFontHighlightSmall")
        editBox:SetText(talentString)
        editBox:SetCursorPosition(0)
        editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

        local copyButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        copyButton:SetSize(72, 22)
        copyButton:SetPoint("TOPLEFT", panel, "TOPLEFT", CFG.details.colTalentX + 4, sectionTop - 62)
        copyButton:SetText("Copy")
        copyButton:SetScript("OnClick", function()
            editBox:SetFocus()
            editBox:HighlightText()
        end)

        local hint = AddFont(panel, "Click Copy, then Ctrl+C.", "GameFontDisableSmall", CFG.details.colTalentX + 4, sectionTop - 90, CFG.details.colTalentW - 8)
        ApplyColor(hint, CFG.colors.muted)
    else
        local none = AddFont(panel, "No talent string captured", "GameFontDisableSmall", CFG.details.colTalentX, sectionTop - 26, CFG.details.colTalentW)
        ApplyColor(none, CFG.colors.muted)
    end

    -- Outcomes
    AddSectionTitle(panel, "Captured Outcomes", CFG.details.colOutcomesX, sectionTop, CFG.details.colOutcomesW)
    local yOutcomes = AddOutcomeRows(panel, encounter, CFG.details.colOutcomesX, sectionTop - 24, CFG.details.colOutcomesW)

    local lowestY = math.min(yRun, yStats, yOutcomes, sectionTop - 130)

    -- Notes
    local note = encounter.note or encounter.notes
    if note and note ~= "" then
        local noteY = lowestY - 18
        local noteBox = CreateFrame("Frame", nil, panel, "BackdropTemplate")
        noteBox:SetPoint("TOPLEFT", panel, "TOPLEFT", padding, noteY)
        noteBox:SetSize(CFG.details.width - 28, 66)
        StylePanel(noteBox, CFG.colors.noteBg, CFG.colors.cardBorder)

        AddSectionTitle(noteBox, "Notes", 10, -10, 200)
        local noteText = AddFont(noteBox, tostring(note), "GameFontHighlightSmall", 10, -32, CFG.details.width - 52)
        ApplyColor(noteText, CFG.colors.text)

        lowestY = noteY - 78
    end

    local height = math.max(CFG.details.minHeight, math.abs(lowestY) + 24)
    height = math.min(height, CFG.details.maxHeight or height)
    panel:SetHeight(height)

    return height
end

-- =========================================================
-- CARD CREATION
-- =========================================================

local function CreateEncounterCard(parent, encounter, displayIndex)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetSize(CFG.card.width, CFG.card.height)
    StylePanel(card, CFG.colors.cardBg, CFG.colors.cardBorder)

    card.encounter = encounter

    local rank = AddFont(card, tostring(displayIndex) .. ".", "GameFontNormal", CFG.card.rankX, -13, 28)
    ApplyColor(rank, CFG.colors.gold)

    local dungeonLine = GetDungeonName(encounter) .. " +" .. tostring(GetKeyLevel(encounter))
    local dungeon = AddFont(card, dungeonLine, "GameFontNormal", CFG.card.dungeonX, -12, 320)
    ApplyColor(dungeon, CFG.colors.text)

    local specLine = GetSpecName(encounter) .. " " .. GetClassName(encounter)
    local spec = AddFont(card, specLine, "GameFontDisableSmall", CFG.card.specX, -14, 240)
    ApplyColor(spec, CFG.colors.muted)

    local dateLine = FormatDateTime(encounter.timestamp)
    local dateText = AddFont(card, dateLine, "GameFontDisableSmall", CFG.card.dateX, -14, 250)
    dateText:SetJustifyH("RIGHT")
    ApplyColor(dateText, CFG.colors.soft)

    local function Select()
        Encounters.selectedEncounter = encounter
        Encounters:RefreshSelection()
    end

    card:SetScript("OnMouseUp", function(_, mouseButton)
        if mouseButton == "LeftButton" then
            Select()
        end
    end)

    card:SetScript("OnEnter", function(self)
        if self.encounter ~= Encounters.selectedEncounter then
            SetBorder(self, CFG.colors.cardHoverBorder)
        end
    end)

    card:SetScript("OnLeave", function(self)
        if self.encounter ~= Encounters.selectedEncounter then
            SetBorder(self, CFG.colors.cardBorder)
        end
    end)

    return card
end

-- =========================================================
-- REFRESH
-- =========================================================

function Encounters:ClearCards()
    if self.cards then
        for _, card in ipairs(self.cards) do
            card:Hide()
            card:SetParent(nil)
        end
    end
    self.cards = {}
end

function Encounters:RefreshDropdowns()
    self.allEncounters = GetEncounterList()

    local dungeonOptions = GetDungeonOptions(self.allEncounters)
    local hasSelectedDungeon = false

    for _, option in ipairs(dungeonOptions) do
        if option.value == self.selectedMapID then
            hasSelectedDungeon = true
            break
        end
    end

    if not hasSelectedDungeon then
        self.selectedMapID = nil
    end

    local dungeonText = "All"
    for _, option in ipairs(dungeonOptions) do
        if option.value == self.selectedMapID then
            dungeonText = option.text
            break
        end
    end
    SetDropdownText(self.dungeonDropdown, dungeonText)

    local keyOptions = GetKeyOptions(self.allEncounters, self.selectedMapID)
    local hasSelectedKey = false

    for _, option in ipairs(keyOptions) do
        if option.value == self.selectedKeyLevel then
            hasSelectedKey = true
            break
        end
    end

    if not hasSelectedKey then
        self.selectedKeyLevel = nil
    end

    SetDropdownText(self.keyDropdown, self.selectedKeyLevel and ("+" .. tostring(self.selectedKeyLevel)) or "All")

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

    SetDropdownText(self.specDropdown, GetSpecText(self.selectedSpec))
    SetDropdownText(self.dateDropdown, GetDateText(self.selectedDateFilter))
end

function Encounters:RefreshSelection()
    for _, card in ipairs(self.cards or {}) do
        local selected = card.encounter == self.selectedEncounter

        if selected then
            SetBorder(card, CFG.colors.cardSelectedBorder)
        else
            SetBorder(card, CFG.colors.cardBorder)
        end
    end

    if self.detailPanel then
        self.detailPanel:Show()
        local height = BuildDetails(self.detailPanel, self.selectedEncounter)
        self.detailPanel:SetHeight(height)
    end

    if self.LayoutCards then
        self:LayoutCards()
    end
end

function Encounters:LayoutCards()
    local y = CFG.list.y

    for _, card in ipairs(self.cards or {}) do
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", self.frame, "TOPLEFT", CFG.list.x + CFG.card.x, y)
        y = y - CFG.card.height - CFG.card.gap
    end

    if self.detailPanel then
        self.detailPanel:ClearAllPoints()
        self.detailPanel:SetPoint("TOPLEFT", self.frame, "TOPLEFT", CFG.details.x, y - CFG.details.gapAfterCards)
    end
end

function Encounters:Refresh()
    self:ClearCards()

    if not self.frame then
        return
    end

    self:RefreshDropdowns()

    local filtered = FilterEncounters(self.allEncounters or {}, self.selectedMapID, self.selectedKeyLevel, self.selectedSpec, self.selectedDateFilter)
    self.filteredEncounters = filtered

    local total = #filtered
    local totalPages = math.max(1, math.ceil(total / CFG.pageSize))
    self.currentPage = math.max(1, math.min(self.currentPage or 1, totalPages))

    if total == 0 then
        self.emptyText:Show()
        self.summaryText:SetText("No encounters found for this filter.")
        self.pageText:SetText("Page 0 / 0")
        self.prevButton:Disable()
        self.nextButton:Disable()
        self.selectedEncounter = nil
        self:RefreshSelection()
        return
    end

    self.emptyText:Hide()

    local startIndex = ((self.currentPage - 1) * CFG.pageSize) + 1
    local endIndex = math.min(total, startIndex + CFG.pageSize - 1)

    self.summaryText:SetText(string.format(
        "%d encounter%s found • showing %d-%d",
        total,
        total == 1 and "" or "s",
        startIndex,
        endIndex
    ))

    self.pageText:SetText(string.format("Page %d / %d", self.currentPage, totalPages))

    if self.currentPage <= 1 then self.prevButton:Disable() else self.prevButton:Enable() end
    if self.currentPage >= totalPages then self.nextButton:Disable() else self.nextButton:Enable() end

    for i = startIndex, endIndex do
        local encounter = filtered[i]
        local displayIndex = i
        local card = CreateEncounterCard(self.frame, encounter, displayIndex)
        table.insert(self.cards, card)
    end

    if not self.selectedEncounter or not MatchesFilters(self.selectedEncounter, self.selectedMapID, self.selectedKeyLevel, self.selectedSpec, self.selectedDateFilter) then
        self.selectedEncounter = filtered[startIndex]
    end

    self:RefreshSelection()
end

-- =========================================================
-- CREATE
-- =========================================================

function Encounters:Create(parent)
    local frame = CreateFrame("Frame", "KeyLabEncountersTab", parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    StylePanel(frame, CFG.colors.bg, {0, 0, 0, 0})

    self.frame = frame
    self.cards = {}
    self.currentPage = 1

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", CFG.header.x, CFG.header.y)
    title:SetText("Encounters")
    ApplyColor(title, CFG.colors.gold)

    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetWidth(CFG.header.subtitleWidth)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetText("Review completed Mythic+ encounters. Select a run to view captured details below.")
    ApplyColor(subtitle, CFG.colors.muted)

    self.summaryText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.summaryText:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -10)
    self.summaryText:SetText("Loading encounters...")
    ApplyColor(self.summaryText, CFG.colors.soft)

    local controls = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    controls:SetPoint("TOPLEFT", frame, "TOPLEFT", CFG.controls.x, CFG.controls.y)
    controls:SetSize(CFG.controls.width, CFG.controls.height)
    StylePanel(controls, CFG.colors.controlBg, CFG.colors.cardBorder)

    self.dungeonDropdown = MakeDropdown(controls, CFG.controls.dungeonWidth, CFG.controls.dungeonX, CFG.controls.labelY, "Dungeon / Zone", function(_, level)
        local options = GetDungeonOptions(Encounters.allEncounters or GetEncounterList())

        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.func = function()
                Encounters.selectedMapID = option.value
                Encounters.selectedKeyLevel = nil
                Encounters.currentPage = 1
                Encounters.selectedEncounter = nil
                Encounters:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    self.keyDropdown = MakeDropdown(controls, CFG.controls.keyWidth, CFG.controls.keyX, CFG.controls.labelY, "Key Level", function(_, level)
        local options = GetKeyOptions(Encounters.allEncounters or GetEncounterList(), Encounters.selectedMapID)

        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.func = function()
                Encounters.selectedKeyLevel = option.value
                Encounters.currentPage = 1
                Encounters.selectedEncounter = nil
                Encounters:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    self.specDropdown = MakeDropdown(controls, CFG.controls.specWidth, CFG.controls.specX, CFG.controls.labelY, "Spec", function(_, level)
        local options = GetSpecOptions(Encounters.allEncounters or GetEncounterList())

        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.func = function()
                Encounters.selectedSpec = option.value
                Encounters.currentPage = 1
                Encounters.selectedEncounter = nil
                Encounters:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    self.dateDropdown = MakeDropdown(controls, CFG.controls.dateWidth, CFG.controls.dateX, CFG.controls.labelY, "Date", function(_, level)
        local options = GetDateOptions()

        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.func = function()
                Encounters.selectedDateFilter = option.value
                Encounters.currentPage = 1
                Encounters.selectedEncounter = nil
                Encounters:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    self.emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.emptyText:SetPoint("TOPLEFT", frame, "TOPLEFT", CFG.list.x, CFG.list.y)
    self.emptyText:SetWidth(CFG.list.width)
    self.emptyText:SetJustifyH("LEFT")
    self.emptyText:SetText("No completed Mythic+ encounters captured yet.")
    ApplyColor(self.emptyText, CFG.colors.text)
    self.emptyText:Hide()

    self.detailPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    self.detailPanel:SetSize(CFG.details.width, CFG.details.minHeight)
    StylePanel(self.detailPanel, CFG.colors.detailBg, CFG.colors.detailBorder)
    self.detailPanel:Show()

    self.pageText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.pageText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", CFG.pager.labelX, CFG.pager.y)
    self.pageText:SetWidth(CFG.pager.labelWidth)
    self.pageText:SetJustifyH("LEFT")
    self.pageText:SetText("Page 1 / 1")
    ApplyColor(self.pageText, CFG.colors.muted)

    self.prevButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    self.prevButton:SetSize(CFG.pager.buttonWidth, CFG.pager.buttonHeight)
    self.prevButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", CFG.pager.prevX, CFG.pager.y)
    self.prevButton:SetText("Back")
    self.prevButton:SetScript("OnClick", function()
        Encounters.currentPage = math.max(1, (Encounters.currentPage or 1) - 1)
        Encounters.selectedEncounter = nil
        Encounters:Refresh()
    end)

    self.nextButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    self.nextButton:SetSize(CFG.pager.buttonWidth, CFG.pager.buttonHeight)
    self.nextButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", CFG.pager.nextX, CFG.pager.y)
    self.nextButton:SetText("Next")
    self.nextButton:SetScript("OnClick", function()
        Encounters.currentPage = (Encounters.currentPage or 1) + 1
        Encounters.selectedEncounter = nil
        Encounters:Refresh()
    end)

    frame:SetScript("OnShow", function()
        Encounters:Refresh()
    end)

    return frame
end

if KeyLab.RegisterTab then
    KeyLab.RegisterTab("Encounters", function(parent)
        return Encounters:Create(parent)
    end)
end

return Encounters
