-- KeyLab_TalentStatBuild.lua
-- Talent Builds tab for KeyLab / M+ Journal
--
-- Purpose:
--   Show the top 5 observed talent build variants for the selected filters.
--
-- Current UI direction:
--   - Uses the Encounters tab layout as the foundation.
--   - No asset/logo/icon dependency.
--   - Uses KeyLab mapping + formatter files as source of truth.
--   - Top 5 only. No pagination.
--   - Selecting a build highlights it and shows details in the always-visible panel below.
--   - Cards stay compact, but keep a visual bar because this tab compares outcomes.
--
-- Data rule:
--   The DB stores raw approved values.
--   UI formats values through KeyLab.Formatters.
--   UI labels/order come from KeyLab.Mapping.
--   Build comparisons are grouped by exact talent string.

local ADDON_NAME, KeyLab = ...

KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.UI = KeyLab.UI or {}
KeyLab.Tabs = KeyLab.Tabs or {}

local TalentStatBuild = {}
KeyLab.Tabs.TalentStatBuild = TalentStatBuild
KeyLab.Tabs.TalentBuilds = TalentStatBuild

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
        bg = {0.035, 0.045, 0.075, 0.96},
        controlBg = {0.055, 0.070, 0.105, 0.94},

        cardBg = {0.045, 0.060, 0.105, 0.94},
        cardBorder = {0.18, 0.28, 0.50, 0.85},
        cardHoverBorder = {0.30, 0.52, 0.88, 0.95},
        cardSelectedBorder = {0.95, 0.78, 0.35, 1.00},

        detailBg = {0.040, 0.052, 0.088, 0.96},
        detailBorder = {0.42, 0.56, 0.88, 0.88},
        noteBg = {0.060, 0.080, 0.125, 0.92},

        text = {0.92, 0.92, 0.95, 1.0},
        muted = {0.72, 0.72, 0.78, 1.0},
        soft = {0.74, 0.80, 0.88, 1.0},
        gold = {0.95, 0.82, 0.42, 1.0},
        blue = {0.45, 0.72, 0.95, 1.0},
        warning = {1.0, 0.52, 0.40, 1.0},
        divider = {1, 1, 1, 0.13},

        barBg = {0.020, 0.030, 0.060, 0.90},
        barBorder = {0.12, 0.20, 0.34, 0.90},
        barFill = {0.45, 0.78, 1.00, 0.98},
        barFillSelected = {0.95, 0.76, 0.32, 1.0},
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
        outcomeX = 610,
        labelY = -12,

        dungeonWidth = 185,
        keyWidth = 90,
        specWidth = 170,
        outcomeWidth = 180,
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
        titleX = 46,
        valueX = 430,
        valueWidth = 130,
        barX = 575,
        barY = -17,
        barWidth = 335,
        barHeight = 9,
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

local function FormatNumber(value)
    if Fmt().Number then return Fmt().Number(value) end
    if type(value) ~= "number" then return "-" end
    if value >= 1000000 then return string.format("%.1fM", value / 1000000) end
    if value >= 1000 then return string.format("%.1fK", value / 1000) end
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

local function CreateBar(parent, x, y, width, height, value, maxValue, minValue, lowerIsBetter, selected)
    local bg = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    bg:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    bg:SetSize(width, height)
    StylePanel(bg, CFG.colors.barBg, CFG.colors.barBorder)

    local n = tonumber(value) or 0
    local max = tonumber(maxValue) or 0
    local min = tonumber(minValue) or 0
    local ratio = 0

    if max > 0 then
        if lowerIsBetter then
            if max == min then
                ratio = 1
            else
                ratio = 1 - ((n - min) / (max - min))
            end
        else
            ratio = n / max
        end
    end

    ratio = math.max(0.06, math.min(1, ratio))

    local fill = bg:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("LEFT", bg, "LEFT", 0, 0)
    fill:SetSize(width * ratio, height - 2)

    local c = selected and CFG.colors.barFillSelected or CFG.colors.barFill
    fill:SetColorTexture(c[1], c[2], c[3], c[4] or 1)

    bg.fill = fill
    return bg
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
            includeInterrupted = false,
            includeExcluded = false,
        })
        return FilterCurrentCharacterEncounters(list)
    end

    if KeyLabDB and type(KeyLabDB.encounters) == "table" then
        local copy = {}
        for _, encounter in ipairs(KeyLabDB.encounters) do
            local flags = encounter.flags or {}
            if flags.interrupted ~= true and flags.excludedFromComparisons ~= true and EncounterMatchesCurrentCharacter(encounter) then
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

local function GetResultText(encounter)
    local flags = encounter and encounter.flags or {}
    if flags.interrupted == true or (encounter and encounter.interrupted == true) then
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

local function GetMetricLabel(metricKey)
    local info = GetMetricInfoByKey(metricKey)
    return info and info.label or metricKey or "Outcome"
end

local function GetMetricOptions()
    local list = {}
    local order = KeyLab.Mapping and KeyLab.Mapping.MetricOrder or {}

    for _, metricType in ipairs(order) do
        local info = GetMetricInfoByType(metricType)
        if info and info.store == true and info.keylabKey then
            table.insert(list, {
                text = info.label or info.keylabKey,
                value = info.keylabKey,
            })
        end
    end

    return list
end

local function GetDungeonOptions(encounters)
    local seen = {}
    local list = {
        { text = "All Dungeons", value = nil },
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
        if a.text == "All Dungeons" then return true end
        if b.text == "All Dungeons" then return false end
        return tostring(a.text) < tostring(b.text)
    end)

    return list
end

local function GetKeyOptions(encounters, selectedMapID)
    local seen = {}
    local list = {
        { text = "All Keys", value = nil },
    }

    for _, encounter in ipairs(encounters or {}) do
        if (not selectedMapID) or GetMapID(encounter) == selectedMapID then
            local keyLevel = GetKeyLevel(encounter)
            if keyLevel and keyLevel > 0 and not seen[keyLevel] then
                seen[keyLevel] = true
                table.insert(list, {
                    text = "+" .. tostring(keyLevel),
                    value = keyLevel,
                })
            end
        end
    end

    table.sort(list, function(a, b)
        if a.text == "All Keys" then return true end
        if b.text == "All Keys" then return false end
        return tonumber(a.value or 0) > tonumber(b.value or 0)
    end)

    return list
end

local function GetSpecOptions(encounters, selectedMapID, selectedKeyLevel)
    local seen = {}
    local list = {
        { text = "All Specs", value = nil },
    }

    for _, encounter in ipairs(encounters or {}) do
        local mapOK = (not selectedMapID) or GetMapID(encounter) == selectedMapID
        local keyOK = (not selectedKeyLevel) or tonumber(GetKeyLevel(encounter) or 0) == tonumber(selectedKeyLevel)

        if mapOK and keyOK then
            local spec = GetSpecName(encounter)
            if spec and spec ~= "" and spec ~= "Unknown Spec" and not seen[spec] then
                seen[spec] = true
                table.insert(list, {
                    text = spec,
                    value = spec,
                })
            end
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

local function MatchesSpec(cardData, selectedSpec)
    if not selectedSpec then return true end

    local group = cardData and cardData.group
    if group and type(group.encounters) == "table" then
        for _, encounter in ipairs(group.encounters) do
            if GetSpecName(encounter) == selectedSpec then
                return true
            end
        end
    end

    local encounter = cardData and cardData.bestEncounter
    return GetSpecName(encounter) == selectedSpec
end

local function GetCardBestEncounterForSpec(cardData, metricKey, selectedSpec, higherIsBetter)
    if not cardData then return nil, nil end

    if not selectedSpec then
        return cardData.bestEncounter, cardData.bestValue
    end

    local group = cardData.group
    if not group or type(group.encounters) ~= "table" then
        local encounter = cardData.bestEncounter
        if encounter and GetSpecName(encounter) == selectedSpec then
            return encounter, cardData.bestValue
        end
        return nil, nil
    end

    local bestEncounter = nil
    local bestValue = nil

    for _, encounter in ipairs(group.encounters) do
        if GetSpecName(encounter) == selectedSpec then
            local value = GetMetricValue(encounter, metricKey)

            if type(value) == "number" then
                if type(bestValue) ~= "number" then
                    bestValue = value
                    bestEncounter = encounter
                elseif higherIsBetter == false then
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

    return bestEncounter, bestValue
end

local function MatchesBuildFilters(encounter, selectedMapID, selectedKeyLevel, selectedSpec, selectedMetricKey)
    if selectedMapID and GetMapID(encounter) ~= selectedMapID then
        return false
    end

    if selectedKeyLevel and tonumber(GetKeyLevel(encounter) or 0) ~= tonumber(selectedKeyLevel) then
        return false
    end

    if selectedSpec and GetSpecName(encounter) ~= selectedSpec then
        return false
    end

    if GetTalentString(encounter) == "" then
        return false
    end

    if selectedMetricKey and GetMetricValue(encounter, selectedMetricKey) == nil then
        return false
    end

    return true
end

local function GetBuildCards(self)
    if not self.selectedMetricKey then
        return {}
    end

    local metricInfo = GetMetricInfoByKey(self.selectedMetricKey)
    local higherIsBetter = not (metricInfo and metricInfo.higherIsBetter == false)

    local groups = {}

    for _, encounter in ipairs(self.allEncounters or GetEncounterList()) do
        if MatchesBuildFilters(encounter, self.selectedMapID, self.selectedKeyLevel, self.selectedSpec, self.selectedMetricKey) then
            local talentString = GetTalentString(encounter)
            local group = groups[talentString]

            if not group then
                group = {
                    talentString = talentString,
                    encounters = {},
                    runCount = 0,
                    bestEncounter = nil,
                    bestValue = nil,
                    higherIsBetter = higherIsBetter,
                    metricKey = self.selectedMetricKey,
                }
                groups[talentString] = group
            end

            table.insert(group.encounters, encounter)
            group.runCount = group.runCount + 1

            local value = GetMetricValue(encounter, self.selectedMetricKey)
            if type(value) == "number" then
                if type(group.bestValue) ~= "number" then
                    group.bestValue = value
                    group.bestEncounter = encounter
                elseif higherIsBetter then
                    if value > group.bestValue then
                        group.bestValue = value
                        group.bestEncounter = encounter
                    end
                else
                    if value < group.bestValue then
                        group.bestValue = value
                        group.bestEncounter = encounter
                    end
                end
            end
        end
    end

    local results = {}
    for _, group in pairs(groups) do
        if group.bestEncounter and group.bestValue ~= nil then
            table.insert(results, {
                talentString = group.talentString,
                runCount = group.runCount,
                bestEncounter = group.bestEncounter,
                bestValue = group.bestValue,
                higherIsBetter = group.higherIsBetter,
                metricKey = group.metricKey,
                group = group,
            })
        end
    end

    table.sort(results, function(a, b)
        local av = tonumber(a.bestValue)
        local bv = tonumber(b.bestValue)

        if not av and not bv then
            return (a.runCount or 0) > (b.runCount or 0)
        elseif not av then
            return false
        elseif not bv then
            return true
        end

        if a.higherIsBetter == false then
            return av < bv
        end

        return av > bv
    end)

    local top = {}
    for i = 1, math.min(CFG.pageSize, #results) do
        top[i] = results[i]
    end

    return top
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
        local value = stats and stats[statKey]

        if info and info.store == true and type(value) == "number" and value > 0 then
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

local function GetVariantTitle(cardData, variantNumber)
    local encounter = cardData and cardData.bestEncounter
    local spec = GetSpecName(encounter)
    return "Mythic+ " .. spec .. " - Talent Variant " .. tostring(variantNumber or 1)
end

local function BuildDetails(panel, cardData, variantNumber)
    ClearChildren(panel)
    StylePanel(panel, CFG.colors.detailBg, CFG.colors.detailBorder)

    local padding = CFG.details.padding

    if not cardData then
        local title = AddFont(panel, "Talent Build Details", "GameFontNormalLarge", padding, -16, CFG.details.width - 28)
        ApplyColor(title, CFG.colors.gold)

        local body = AddFont(panel, "Select a build above to view the run details, stat snapshot, talent string, and captured outcomes for its best observed run.", "GameFontHighlightSmall", padding, -48, CFG.details.width - 28)
        ApplyColor(body, CFG.colors.muted)

        panel:SetHeight(CFG.details.minHeight)
        return CFG.details.minHeight
    end

    local encounter = cardData.bestEncounter or {}
    local challenge = GetChallenge(encounter)
    local topY = -14

    local header = AddFont(panel, GetVariantTitle(cardData, variantNumber), "GameFontNormalLarge", padding, topY, CFG.details.width - 28)
    ApplyColor(header, CFG.colors.gold)

    local metricLabel = GetMetricLabel(cardData.metricKey or TalentStatBuild.selectedMetricKey)
    local bestLine = metricLabel .. ": " .. FormatMetric(cardData.metricKey or TalentStatBuild.selectedMetricKey, cardData.bestValue)

    local sub = AddFont(panel, GetDungeonName(encounter) .. " +" .. tostring(GetKeyLevel(encounter)) .. " • " .. bestLine, "GameFontDisableSmall", padding, topY - 24, CFG.details.width - 28)
    ApplyColor(sub, CFG.colors.muted)

    local sectionTop = topY - 62

    AddVerticalDivider(panel, CFG.details.colStatsX - 12, sectionTop + 4, 225)
    AddVerticalDivider(panel, CFG.details.colTalentX - 12, sectionTop + 4, 225)
    AddVerticalDivider(panel, CFG.details.colOutcomesX - 12, sectionTop + 4, 225)

    -- Run Details
    AddSectionTitle(panel, "Run Details", CFG.details.colRunX, sectionTop, CFG.details.colRunW)
    local yRun = sectionTop - 24
    yRun = AddDetailRow(panel, "Date", FormatDateTime(encounter.timestamp), CFG.details.colRunX, yRun, CFG.details.colRunW)
    yRun = AddDetailRow(panel, "Dungeon", GetDungeonName(encounter), CFG.details.colRunX, yRun, CFG.details.colRunW)
    yRun = AddDetailRow(panel, "Key Level", "+" .. tostring(GetKeyLevel(encounter)), CFG.details.colRunX, yRun, CFG.details.colRunW)
    yRun = AddDetailRow(panel, "Result", GetResultText(encounter), CFG.details.colRunX, yRun, CFG.details.colRunW)

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

local function CreateBuildCard(parent, cardData, displayIndex, maxValue, minValue)
    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    card:SetSize(CFG.card.width, CFG.card.height)
    StylePanel(card, CFG.colors.cardBg, CFG.colors.cardBorder)

    card.cardData = cardData
    card.displayIndex = displayIndex

    local metricKey = TalentStatBuild.selectedMetricKey
    local metricLabel = GetMetricLabel(metricKey)
    local value = cardData.bestValue

    local rank = AddFont(card, tostring(displayIndex) .. ".", "GameFontNormal", CFG.card.rankX, -13, 28)
    ApplyColor(rank, CFG.colors.gold)

    local titleText = GetVariantTitle(cardData, displayIndex)
    local title = AddFont(card, titleText, "GameFontNormal", CFG.card.titleX, -12, 480)
    ApplyColor(title, CFG.colors.text)

    local valueText = metricLabel .. ": " .. FormatMetric(metricKey, value)
    local metric = AddFont(card, valueText, "GameFontNormal", CFG.card.valueX, -12, CFG.card.valueWidth or 130)
    metric:SetJustifyH("RIGHT")
    ApplyColor(metric, CFG.colors.soft)

    CreateBar(card, CFG.card.barX, CFG.card.barY, CFG.card.barWidth, CFG.card.barHeight, value, maxValue, minValue, cardData.higherIsBetter == false, false)

    local function Select()
        TalentStatBuild.selectedCardData = cardData
        TalentStatBuild.selectedIndex = displayIndex
        TalentStatBuild:RefreshSelection()
    end

    card:SetScript("OnClick", Select)

    card:SetScript("OnEnter", function(self)
        if self.cardData ~= TalentStatBuild.selectedCardData then
            SetBorder(self, CFG.colors.cardHoverBorder)
        end
    end)

    card:SetScript("OnLeave", function(self)
        if self.cardData ~= TalentStatBuild.selectedCardData then
            SetBorder(self, CFG.colors.cardBorder)
        end
    end)

    return card
end

-- =========================================================
-- REFRESH
-- =========================================================

function TalentStatBuild:ClearCards()
    if self.cards then
        for _, card in ipairs(self.cards) do
            card:Hide()
            card:SetParent(nil)
        end
    end
    self.cards = {}
end

function TalentStatBuild:RefreshDropdowns()
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

    local dungeonText = "All Dungeons"
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

    SetDropdownText(self.keyDropdown, self.selectedKeyLevel and ("+" .. tostring(self.selectedKeyLevel)) or "All Keys")

    local specOptions = GetSpecOptions(self.allEncounters, self.selectedMapID, self.selectedKeyLevel)
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

    local metricOptions = GetMetricOptions()
    if (not self.selectedMetricKey) and #metricOptions > 0 then
        self.selectedMetricKey = "dps"
    end

    local hasMetric = false
    for _, option in ipairs(metricOptions) do
        if option.value == self.selectedMetricKey then
            hasMetric = true
            break
        end
    end

    if not hasMetric and #metricOptions > 0 then
        self.selectedMetricKey = metricOptions[1].value
    end

    SetDropdownText(self.outcomeDropdown, GetMetricLabel(self.selectedMetricKey))
end

function TalentStatBuild:RefreshSelection()
    for _, card in ipairs(self.cards or {}) do
        local selected = card.cardData == self.selectedCardData

        if selected then
            StylePanel(card, CFG.colors.cardBg, CFG.colors.cardSelectedBorder)
        else
            StylePanel(card, CFG.colors.cardBg, CFG.colors.cardBorder)
        end
    end

    if self.detailPanel then
        self.detailPanel:Show()
        local height = BuildDetails(self.detailPanel, self.selectedCardData, self.selectedIndex)
        self.detailPanel:SetHeight(height)
    end

    if self.LayoutCards then
        self:LayoutCards()
    end
end

function TalentStatBuild:LayoutCards()
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

function TalentStatBuild:Refresh()
    self:ClearCards()

    if not self.frame then
        return
    end

    self:RefreshDropdowns()

    local cards = GetBuildCards(self)
    self.buildCards = cards

    local metricInfo = GetMetricInfoByKey(self.selectedMetricKey)
    local direction = (metricInfo and metricInfo.higherIsBetter == false) and "lowest" or "highest"
    local metricLabel = GetMetricLabel(self.selectedMetricKey)

    if self.summaryText then
        if #cards == 0 then
            self.summaryText:SetText("No matching talent build data found.")
        else
            self.summaryText:SetText("Top " .. tostring(math.min(CFG.pageSize, #cards)) .. " different builds • ranked by " .. direction .. " observed " .. metricLabel)
        end
    end

    if #cards == 0 then
        self.emptyText:Show()
        self.emptyText:SetText("No matching talent build data yet.\n\nCapture completed Mythic+ runs with talent strings, stat snapshots, and mapped outcomes to populate this view.")
        self.selectedCardData = nil
        self.selectedIndex = nil
        self:RefreshSelection()
        return
    end

    self.emptyText:Hide()

    local maxValue = 0
    local minValue = nil

    for _, cardData in ipairs(cards) do
        local value = tonumber(cardData.bestValue) or 0
        if value > maxValue then maxValue = value end
        if minValue == nil or value < minValue then minValue = value end
    end

    for i, cardData in ipairs(cards) do
        local card = CreateBuildCard(self.frame, cardData, i, maxValue, minValue or 0)
        table.insert(self.cards, card)
    end

    if not self.selectedCardData then
        self.selectedCardData = cards[1]
        self.selectedIndex = 1
    else
        local stillVisible = false
        for i, cardData in ipairs(cards) do
            if cardData.talentString == self.selectedCardData.talentString then
                self.selectedCardData = cardData
                self.selectedIndex = i
                stillVisible = true
                break
            end
        end

        if not stillVisible then
            self.selectedCardData = cards[1]
            self.selectedIndex = 1
        end
    end

    self:RefreshSelection()
end

-- =========================================================
-- CREATE
-- =========================================================

function TalentStatBuild:Create(parent)
    local frame = CreateFrame("Frame", "KeyLabTalentStatBuildTab", parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    StylePanel(frame, CFG.colors.bg, {0, 0, 0, 0})

    self.frame = frame
    self.cards = {}

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", CFG.header.x, CFG.header.y)
    title:SetText("Talent Builds")
    ApplyColor(title, CFG.colors.gold)

    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetWidth(CFG.header.subtitleWidth)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetText("Shows the top 5 different talent builds for the selected filters. Use All to compare across broader context.")
    ApplyColor(subtitle, CFG.colors.muted)

    self.summaryText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.summaryText:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -10)
    self.summaryText:SetText("Loading talent build data...")
    ApplyColor(self.summaryText, CFG.colors.soft)

    local controls = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    controls:SetPoint("TOPLEFT", frame, "TOPLEFT", CFG.controls.x, CFG.controls.y)
    controls:SetSize(CFG.controls.width, CFG.controls.height)
    StylePanel(controls, CFG.colors.controlBg, CFG.colors.cardBorder)

    self.dungeonDropdown = MakeDropdown(controls, CFG.controls.dungeonWidth, CFG.controls.dungeonX, CFG.controls.labelY, "Dungeon / Zone", function(_, level)
        local options = GetDungeonOptions(TalentStatBuild.allEncounters or GetEncounterList())

        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.func = function()
                TalentStatBuild.selectedMapID = option.value
                TalentStatBuild.selectedKeyLevel = nil
                TalentStatBuild.selectedSpec = nil
                TalentStatBuild.selectedCardData = nil
                TalentStatBuild.selectedIndex = nil
                TalentStatBuild:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    self.keyDropdown = MakeDropdown(controls, CFG.controls.keyWidth, CFG.controls.keyX, CFG.controls.labelY, "Key Level", function(_, level)
        local options = GetKeyOptions(TalentStatBuild.allEncounters or GetEncounterList(), TalentStatBuild.selectedMapID)

        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.func = function()
                TalentStatBuild.selectedKeyLevel = option.value
                TalentStatBuild.selectedSpec = nil
                TalentStatBuild.selectedCardData = nil
                TalentStatBuild.selectedIndex = nil
                TalentStatBuild:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    self.specDropdown = MakeDropdown(controls, CFG.controls.specWidth, CFG.controls.specX, CFG.controls.labelY, "Spec", function(_, level)
        local options = GetSpecOptions(TalentStatBuild.allEncounters or GetEncounterList(), TalentStatBuild.selectedMapID, TalentStatBuild.selectedKeyLevel)

        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.func = function()
                TalentStatBuild.selectedSpec = option.value
                TalentStatBuild.selectedCardData = nil
                TalentStatBuild.selectedIndex = nil
                TalentStatBuild:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    self.outcomeDropdown = MakeDropdown(controls, CFG.controls.outcomeWidth, CFG.controls.outcomeX, CFG.controls.labelY, "Outcome", function(_, level)
        local options = GetMetricOptions()

        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.func = function()
                TalentStatBuild.selectedMetricKey = option.value
                TalentStatBuild.selectedCardData = nil
                TalentStatBuild.selectedIndex = nil
                TalentStatBuild:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    self.emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.emptyText:SetPoint("TOPLEFT", frame, "TOPLEFT", CFG.list.x, CFG.list.y)
    self.emptyText:SetWidth(CFG.list.width)
    self.emptyText:SetJustifyH("LEFT")
    self.emptyText:SetText("No talent build data captured yet.")
    ApplyColor(self.emptyText, CFG.colors.text)
    self.emptyText:Hide()

    self.detailPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    self.detailPanel:SetSize(CFG.details.width, CFG.details.minHeight)
    StylePanel(self.detailPanel, CFG.colors.detailBg, CFG.colors.detailBorder)
    self.detailPanel:Show()

    frame:SetScript("OnShow", function()
        TalentStatBuild:Refresh()
    end)

    TalentStatBuild:Refresh()

    return frame
end

function KeyLab_CreateTalentStatBuildTab(parent)
    return TalentStatBuild:Create(parent)
end

if KeyLab.RegisterTab then
    KeyLab.RegisterTab("Talent Builds", function(parent)
        return TalentStatBuild:Create(parent)
    end)
end

return TalentStatBuild
