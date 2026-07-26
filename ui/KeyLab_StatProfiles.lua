-- KeyLab_StatProfiles.lua
-- Stat Profiles tab for KeyLab / M+ Journal
--
-- Purpose:
--   Show the top observed stat-priority lineups from saved completed Mythic+ runs.
--
-- Current UI direction:
--   - Uses the Encounters / Talent Builds layout foundation.
--   - No asset/logo/icon dependency.
--   - Uses KeyLab mapping + formatter files as source of truth.
--   - Shows up to 5 stat-priority lineups.
--   - Groups by secondary stat order: highest percent to lowest percent.
--   - Selecting a lineup highlights it and shows the best source run in the details panel.
--
-- Data rule:
--   The DB stores raw approved values.
--   UI formats values through KeyLab.Formatters.
--   UI labels/order come from KeyLab.Mapping.

local ADDON_NAME, KeyLab = ...

KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.UI = KeyLab.UI or {}
KeyLab.Tabs = KeyLab.Tabs or {}

local StatProfiles = {}
KeyLab.Tabs.StatProfiles = StatProfiles
local EncounterData = KeyLab.Analysis and KeyLab.Analysis.EncounterData or {}
local SPACING = KeyLab.UI.Theme and KeyLab.UI.Theme.spacing or { compactCard = 8, section = 18 }
local HEADER = KeyLab.UI.Theme and KeyLab.UI.Theme.tabHeader or { x = 18, titleY = -18, titleSize = 16, analysisControlsY = -86, analysisContentY = -172 }

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

        barBg = {0.012, 0.020, 0.044, 0.90},
        barBorder = {0.185, 0.300, 0.500, 0.50},

        crit = {0.840, 0.440, 0.420, 0.95},
        haste = {0.840, 0.720, 0.420, 0.95},
        mastery = {0.500, 0.680, 0.940, 0.95},
        versatility = {0.460, 0.780, 0.500, 0.95},
        fallbackBar = {0.780, 0.830, 0.900, 0.90},
    },

    header = {
        x = HEADER.x,
        y = HEADER.titleY,
        subtitleWidth = 900,
    },

    controls = {
        x = 12,
        y = HEADER.analysisControlsY,
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
        y = HEADER.analysisContentY,
        width = 928,
    },

    card = {
        x = 0,
        width = 928,
        height = 44,
        gap = SPACING.compactCard,
        padding = 12,

        rankX = 12,
        titleX = 46,
        priorityX = 255,
        runsX = 610,
        valueX = 685,
        valueWidth = 100,
        barX = 805,
        barY = -17,
        barWidth = 105,
        barHeight = 9,
    },

    details = {
        x = 12,
        width = 928,
        minHeight = 300,
        maxHeight = 300,
        gapAfterCards = SPACING.section,
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

local function FormatDateTime(value)
    if Fmt().DateTime then return Fmt().DateTime(value) end
    value = SafeNumber(value)
    if value == nil then return "-" end
    return date("%b %d, %Y %I:%M %p", value)
end

local function FormatDuration(value)
    if Fmt().Duration then return Fmt().Duration(value) end
    value = SafeNumber(value)
    if value == nil then return "-" end
    local mins = math.floor(value / 60)
    local secs = math.floor(value % 60)
    return string.format("%d:%02d", mins, secs)
end

local function FormatStat(statKey, value)
    if Fmt().Stat then return Fmt().Stat(statKey, value) end
    value = SafeNumber(value)
    if value == nil then return "-" end

    local mapping = KeyLab.Mapping and KeyLab.Mapping.Stats and KeyLab.Mapping.Stats[statKey]
    if mapping and mapping.displayType == "percent" then
        return string.format("%.1f%%", value)
    end

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

local function GetStatColor(statKey)
    if statKey == "crit" then return CFG.colors.crit end
    if statKey == "haste" then return CFG.colors.haste end
    if statKey == "mastery" then return CFG.colors.mastery end
    if statKey == "versatility" then return CFG.colors.versatility end
    return CFG.colors.fallbackBar
end

local function CreateBar(parent, x, y, width, height, value, maxValue, minValue, lowerIsBetter, color)
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

    local c = color or CFG.colors.blue
    fill:SetColorTexture(c[1], c[2], c[3], c[4] or 1)

    bg.fill = fill
    return bg
end

-- =========================================================
-- DATA HELPERS
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
    if EncounterData.EncounterMatchesCurrentCharacter then
        return EncounterData.EncounterMatchesCurrentCharacter(encounter, { allowMissingIdentity = false })
    end

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
    if EncounterData.GetEncounterList then
        return EncounterData.GetEncounterList({
            includeInterrupted = false,
            includeExcluded = false,
            allowMissingIdentity = false,
        })
    end

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
            return (SafeNumber(a.timestamp) or 0) > (SafeNumber(b.timestamp) or 0)
        end)
        return copy
    end

    return {}
end

local function GetChallenge(encounter)
    if EncounterData.GetChallenge then return EncounterData.GetChallenge(encounter) end
    return encounter and encounter.challenge or {}
end

local function GetPlayer(encounter)
    if EncounterData.GetPlayer then return EncounterData.GetPlayer(encounter) end
    return encounter and encounter.player or {}
end

local function GetStats(encounter)
    if EncounterData.GetStats then return EncounterData.GetStats(encounter) end
    return encounter and encounter.stats or {}
end

local function GetMetrics(encounter)
    if EncounterData.GetMetrics then return EncounterData.GetMetrics(encounter) end
    return encounter and encounter.metrics or {}
end

local function GetTalents(encounter)
    if EncounterData.GetTalents then return EncounterData.GetTalents(encounter) end
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

local function GetSpecID(encounter)
    local player = GetPlayer(encounter)
    return tonumber(player.specID or encounter and encounter.specID)
end

local function GetCurrentSpecIdentity()
    local specIndex = GetSpecialization and GetSpecialization()
    if specIndex and GetSpecializationInfo then
        local specID, specName = GetSpecializationInfo(specIndex)
        if specName and specName ~= "" then
            return tonumber(specID), specName
        end
    end
    return nil, nil
end

local function MatchesCurrentSpec(encounter, currentSpecID, currentSpecName)
    local encounterSpecID = GetSpecID(encounter)
    if currentSpecID and encounterSpecID then
        return encounterSpecID == currentSpecID
    end
    if currentSpecName then
        return GetSpecName(encounter) == currentSpecName
    end
    return true
end

local function GetTalentString(encounter)
    return GetTalents(encounter).talentString or encounter.talentString or ""
end

local function GetResultText(encounter)
    return EncounterData.GetResultText(encounter)
end

local function GetDurationSeconds(encounter)
    if EncounterData.GetDurationSeconds then
        return EncounterData.GetDurationSeconds(encounter)
    end
    local challenge = GetChallenge(encounter)
    return challenge and challenge.durationSeconds
end

local function GetMetricValue(encounter, metricKey)
    if EncounterData.GetMetricValue then return EncounterData.GetMetricValue(encounter, metricKey) end
    local metrics = GetMetrics(encounter)
    return metrics and metrics[metricKey]
end

local function GetMetricInfoByKey(metricKey)
    if EncounterData.GetMetricInfoByKey then return EncounterData.GetMetricInfoByKey(metricKey) end
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
    if EncounterData.GetMetricInfoByType then return EncounterData.GetMetricInfoByType(metricType) end
    return KeyLab.Mapping
        and KeyLab.Mapping.Metrics
        and KeyLab.Mapping.Metrics[metricType]
end

local function GetMetricLabel(metricKey)
    if EncounterData.GetMetricLabel then return EncounterData.GetMetricLabel(metricKey) end
    local info = GetMetricInfoByKey(metricKey)
    return info and info.label or metricKey or "Outcome"
end

local function GetShortMetricLabel(metricKey)
    if metricKey == "damageDone" then return "Avg Damage" end
    if metricKey == "dps" then return "Avg DPS" end
    if metricKey == "healingDone" then return "Avg Healing" end
    if metricKey == "hps" then return "Avg HPS" end
    if metricKey == "absorbs" then return "Avg Absorbs" end
    if metricKey == "interrupts" then return "Avg Interrupts" end
    if metricKey == "dispels" then return "Avg Dispels" end
    if metricKey == "damageTaken" then return "Avg Dmg Taken" end
    if metricKey == "avoidableDamageTaken" then return "Avg Avoidable" end
    return "Avg " .. tostring(GetMetricLabel(metricKey))
end

local function GetMetricOptions()
    local list = {}

    local order = KeyLab.Mapping and KeyLab.Mapping.MetricOrder or {}
    for _, metricType in ipairs(order) do
        local info = GetMetricInfoByType(metricType)
        if info and info.store == true and info.keylabKey and info.keylabKey ~= "deaths" then
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
            local keyLevel = tonumber(GetKeyLevel(encounter))
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
        return tonumber(a.value) > tonumber(b.value)
    end)

    return list
end

local function GetStatLabel(statKey)
    local info = KeyLab.Mapping and KeyLab.Mapping.Stats and KeyLab.Mapping.Stats[statKey]
    return info and info.label or statKey
end

local function MatchesFilters(encounter, selectedSpecID, selectedSpec, selectedMapID, selectedKeyLevel)
    if not MatchesCurrentSpec(encounter, selectedSpecID, selectedSpec) then
        return false
    end
    if selectedMapID and GetMapID(encounter) ~= selectedMapID then
        return false
    end
    if selectedKeyLevel and tonumber(GetKeyLevel(encounter) or 0) ~= tonumber(selectedKeyLevel) then
        return false
    end
    return true
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

    return table.concat(parts, ">");
end

local function GetPriorityText(priority)
    if type(priority) ~= "table" then return "No stat priority" end
    local parts = {}

    for _, stat in ipairs(priority) do
        table.insert(parts, GetStatLabel(stat.key))
    end

    return table.concat(parts, " > ")
end

local function AddEncounterToPriorityGroup(groups, encounter, metricKey, metricValue, lowerIsBetter)
    local priority = GetStatPriority(encounter)
    if not priority then return end

    metricValue = SafeNumber(metricValue)
    if metricValue == nil then return end

    local priorityKey = GetPriorityKey(priority)
    if not priorityKey then return end

    -- Keep the specialization in the group key so old records remain distinct
    -- even though the view now follows the character's current specialization.
    local groupKey = tostring(GetSpecName(encounter) or "Unknown Spec") .. "|" .. priorityKey

    local group = groups[groupKey]
    if not group then
        group = {
            priority = priority,
            priorityKey = priorityKey,
            priorityText = GetPriorityText(priority),
            runCount = 0,
            metricTotal = 0,
            metricAverage = 0,
            bestMetric = nil,
            bestEncounter = nil,
            bestPriority = nil,
            encounters = {},
            metricKey = metricKey,
            lowerIsBetter = lowerIsBetter,
        }
        groups[groupKey] = group
    end

    table.insert(group.encounters, encounter)
    group.runCount = group.runCount + 1
    group.metricTotal = group.metricTotal + metricValue
    group.metricAverage = group.metricTotal / math.max(1, group.runCount)

    if type(group.bestMetric) ~= "number" then
        group.bestMetric = metricValue
        group.bestEncounter = encounter
        group.bestPriority = priority
    elseif lowerIsBetter then
        if metricValue < group.bestMetric then
            group.bestMetric = metricValue
            group.bestEncounter = encounter
            group.bestPriority = priority
        end
    else
        if metricValue > group.bestMetric then
            group.bestMetric = metricValue
            group.bestEncounter = encounter
            group.bestPriority = priority
        end
    end
end

local function GetProfileCards(self)
    local results = {}

    if not self.selectedMetricKey then
        return results
    end

    local metricInfo = GetMetricInfoByKey(self.selectedMetricKey)
    local lowerIsBetter = metricInfo and metricInfo.higherIsBetter == false
    local groups = {}

    for _, encounter in ipairs(self.allEncounters or {}) do
        if MatchesFilters(encounter, self.selectedSpecID, self.selectedSpec, self.selectedMapID, self.selectedKeyLevel) then
            local metricValue = SafeNumber(GetMetricValue(encounter, self.selectedMetricKey))
            if metricValue ~= nil then
                AddEncounterToPriorityGroup(groups, encounter, self.selectedMetricKey, metricValue, lowerIsBetter)
            end
        end
    end

    for _, group in pairs(groups) do
        if group.runCount > 0 and group.bestEncounter then
            table.insert(results, {
                encounter = group.bestEncounter,
                metricKey = group.metricKey,
                metricValue = group.metricAverage,
                metricAverage = group.metricAverage,
                bestMetric = group.bestMetric,
                priority = group.priority,
                bestPriority = group.bestPriority,
                priorityText = group.priorityText,
                runCount = group.runCount,
                group = group,
            })
        end
    end

    table.sort(results, function(a, b)
        local av = SafeNumber(a.metricAverage) or 0
        local bv = SafeNumber(b.metricAverage) or 0

        if av == bv then
            return (a.runCount or 0) > (b.runCount or 0)
        end

        if lowerIsBetter then
            return av < bv
        end

        return av > bv
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
                if statKey == "crit" or statKey == "haste" or statKey == "mastery" or statKey == "versatility" then
                    ApplyColor(row, GetStatColor(statKey))
                else
                    ApplyColor(row, CFG.colors.text)
                end
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

local function BuildDetails(panel, profile)
    ClearChildren(panel)
    StylePanel(panel, CFG.colors.detailBg, CFG.colors.detailBorder)

    local padding = CFG.details.padding

    if not profile then
        local title = AddFont(panel, "Stat Priority Details", "GameFontNormalLarge", padding, -16, CFG.details.width - 28)
        ApplyColor(title, CFG.colors.gold)

        local body = AddFont(panel, "Select a stat setup above to see its best saved run, talents, stats, and results.", "GameFontHighlightSmall", padding, -48, CFG.details.width - 28)
        ApplyColor(body, CFG.colors.muted)

        panel:SetHeight(CFG.details.minHeight)
        return CFG.details.minHeight
    end

    local encounter = profile.encounter or {}
    local challenge = GetChallenge(encounter)
    local topY = -14

    local header = AddFont(panel, "Mythic+ " .. GetSpecName(encounter) .. " - " .. tostring(profile.priorityText or "Stat Priority"), "GameFontNormalLarge", padding, topY, CFG.details.width - 28)
    ApplyColor(header, CFG.colors.gold)

    local avgLine = "Avg " .. GetMetricLabel(profile.metricKey) .. ": " .. FormatMetric(profile.metricKey, profile.metricAverage)
    local bestLine = "Best " .. GetMetricLabel(profile.metricKey) .. ": " .. FormatMetric(profile.metricKey, profile.bestMetric)
    local sub = AddFont(panel, tostring(profile.runCount or 0) .. " run(s) • " .. avgLine .. " • " .. bestLine, "GameFontDisableSmall", padding, topY - 24, CFG.details.width - 28)
    ApplyColor(sub, CFG.colors.muted)

    local sectionTop = topY - 62

    AddVerticalDivider(panel, CFG.details.colStatsX - 12, sectionTop + 4, 225)
    AddVerticalDivider(panel, CFG.details.colTalentX - 12, sectionTop + 4, 225)
    AddVerticalDivider(panel, CFG.details.colOutcomesX - 12, sectionTop + 4, 225)

    -- Run Details
    AddSectionTitle(panel, "Best Source Run", CFG.details.colRunX, sectionTop, CFG.details.colRunW)
    local yRun = sectionTop - 24
    yRun = AddDetailRow(panel, "Date", FormatDateTime(encounter.timestamp), CFG.details.colRunX, yRun, CFG.details.colRunW)
    yRun = AddDetailRow(panel, "Dungeon", GetDungeonName(encounter), CFG.details.colRunX, yRun, CFG.details.colRunW)
    yRun = AddDetailRow(panel, "Key Level", "+" .. tostring(GetKeyLevel(encounter)), CFG.details.colRunX, yRun, CFG.details.colRunW)
    yRun = AddDetailRow(panel, "Result", GetResultText(encounter), CFG.details.colRunX, yRun, CFG.details.colRunW)

    local durationSeconds = GetDurationSeconds(encounter)
    if durationSeconds then
        yRun = AddDetailRow(panel, "Duration", FormatDuration(durationSeconds), CFG.details.colRunX, yRun, CFG.details.colRunW)
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

local function AddPriorityLine(parent, priority, x, y, width)
    if type(priority) ~= "table" then
        local none = AddFont(parent, "No stat priority", "GameFontNormal", x, y, width)
        ApplyColor(none, CFG.colors.muted)
        return
    end

    local cursorX = x
    for i, stat in ipairs(priority) do
        local label = GetStatLabel(stat.key)
        local statWidth = math.max(52, math.min(92, string.len(label) * 7))
        local text = AddFont(parent, label, "GameFontNormal", cursorX, y, statWidth)
        ApplyColor(text, GetStatColor(stat.key))
        cursorX = cursorX + statWidth

        if i < #priority then
            local sep = AddFont(parent, ">", "GameFontNormal", cursorX, y, 18)
            ApplyColor(sep, CFG.colors.soft)
            cursorX = cursorX + 18
        end
    end
end

local function CreateProfileCard(parent, profile, displayIndex, maxValue, minValue)
    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    card:SetSize(CFG.card.width, CFG.card.height)
    StylePanel(card, CFG.colors.cardBg, CFG.colors.cardBorder)

    card.profile = profile
    card.displayIndex = displayIndex

    local encounter = profile.encounter or {}
    local metricLabel = GetMetricLabel(profile.metricKey)

    local rank = AddFont(card, tostring(displayIndex) .. ".", "GameFontNormal", CFG.card.rankX, -13, 28)
    ApplyColor(rank, CFG.colors.gold)

    local titleText = "Mythic+ " .. GetSpecName(encounter)
    local title = AddFont(card, titleText, "GameFontNormal", CFG.card.titleX, -12, 185)
    ApplyColor(title, CFG.colors.text)

    AddPriorityLine(card, profile.priority, CFG.card.priorityX, -12, 280)

    local runs = AddFont(card, tostring(profile.runCount or 0) .. " run(s)", "GameFontDisableSmall", CFG.card.runsX, -13, 80)
    ApplyColor(runs, CFG.colors.muted)

    local valueText = GetShortMetricLabel(profile.metricKey) .. ": " .. FormatMetric(profile.metricKey, profile.metricAverage)
    local metric = AddFont(card, valueText, "GameFontNormal", CFG.card.valueX, -12, CFG.card.valueWidth)
    metric:SetJustifyH("RIGHT")
    ApplyColor(metric, CFG.colors.soft)

    local metricInfo = GetMetricInfoByKey(profile.metricKey)
    local firstStat = profile.priority and profile.priority[1] and profile.priority[1].key
    CreateBar(card, CFG.card.barX, CFG.card.barY, CFG.card.barWidth, CFG.card.barHeight, profile.metricAverage, maxValue, minValue, metricInfo and metricInfo.higherIsBetter == false, GetStatColor(firstStat))

    local function Select()
        StatProfiles.selectedProfile = profile
        StatProfiles.selectedIndex = displayIndex
        StatProfiles:RefreshSelection()
    end

    card:SetScript("OnClick", Select)

    card:SetScript("OnEnter", function(self)
        if self.profile ~= StatProfiles.selectedProfile then
            SetBorder(self, CFG.colors.cardHoverBorder)
        end
    end)

    card:SetScript("OnLeave", function(self)
        if self.profile ~= StatProfiles.selectedProfile then
            SetBorder(self, CFG.colors.cardBorder)
        end
    end)

    return card
end

-- =========================================================
-- REFRESH
-- =========================================================

function StatProfiles:ClearCards()
    if self.cards then
        for _, card in ipairs(self.cards) do
            card:Hide()
            card:SetParent(nil)
        end
    end
    self.cards = {}
end

function StatProfiles:RefreshDropdowns()
    self.allEncounters = GetEncounterList()
    self.currentSpecID, self.currentSpecName = GetCurrentSpecIdentity()
    self.selectedSpecID = self.currentSpecID
    self.selectedSpec = self.currentSpecName
    self.currentSpecEncounters = {}
    for _, encounter in ipairs(self.allEncounters or {}) do
        if MatchesCurrentSpec(encounter, self.currentSpecID, self.currentSpecName) then
            table.insert(self.currentSpecEncounters, encounter)
        end
    end
    self.specValue:SetText(self.currentSpecName or "No Specialization")

    local dungeonOptions = GetDungeonOptions(self.currentSpecEncounters)
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

    local keyOptions = GetKeyOptions(self.currentSpecEncounters, self.selectedMapID)
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

function StatProfiles:RefreshSelection()
    for _, card in ipairs(self.cards or {}) do
        local selected = card.profile == self.selectedProfile

        if selected then
            StylePanel(card, CFG.colors.cardBg, CFG.colors.cardSelectedBorder)
        else
            StylePanel(card, CFG.colors.cardBg, CFG.colors.cardBorder)
        end
    end

    if self.detailPanel then
        self.detailPanel:Show()
        local height = BuildDetails(self.detailPanel, self.selectedProfile)
        self.detailPanel:SetHeight(height)
    end

    if self.LayoutCards then
        self:LayoutCards()
    end
end

function StatProfiles:LayoutCards()
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

function StatProfiles:Refresh()
    self:ClearCards()

    if not self.frame then
        return
    end

    self:RefreshDropdowns()

    local profiles = GetProfileCards(self)
    self.filteredProfiles = profiles

    local total = #profiles
    local metricInfo = GetMetricInfoByKey(self.selectedMetricKey)
    local direction = (metricInfo and metricInfo.higherIsBetter == false) and "lowest" or "highest"
    local metricLabel = GetMetricLabel(self.selectedMetricKey)

    if total == 0 then
        self.emptyText:Show()
        self.emptyText:SetText("No saved stat setups match these filters yet.")
        self.summaryText:SetText("No matching stat priority data found.")
        self.selectedProfile = nil
        self.selectedIndex = nil
        self:RefreshSelection()
        return
    end

    self.emptyText:Hide()

    local showCount = math.min(CFG.pageSize, total)
    self.summaryText:SetText("Showing top " .. tostring(showCount) .. " of " .. tostring(total) .. " stat priority lineups • ranked by average " .. direction .. " observed " .. metricLabel)

    local maxValue = 0
    local minValue = nil

    for i = 1, showCount do
        local profile = profiles[i]
        local value = SafeNumber(profile.metricAverage) or 0
        if value > maxValue then maxValue = value end
        if minValue == nil or value < minValue then minValue = value end
    end

    for i = 1, showCount do
        local profile = profiles[i]
        local card = CreateProfileCard(self.frame, profile, i, maxValue, minValue or 0)
        table.insert(self.cards, card)
    end

    if not self.selectedProfile then
        self.selectedProfile = profiles[1]
        self.selectedIndex = 1
    else
        local stillVisible = false
        for i = 1, showCount do
            if profiles[i] == self.selectedProfile then
                self.selectedIndex = i
                stillVisible = true
                break
            end
        end

        if not stillVisible then
            self.selectedProfile = profiles[1]
            self.selectedIndex = 1
        end
    end

    self:RefreshSelection()
end

-- =========================================================
-- CREATE
-- =========================================================

function StatProfiles:Create(parent)
    local frame = CreateFrame("Frame", "KeyLabStatProfilesTab", parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    StylePanel(frame, CFG.colors.bg, {0, 0, 0, 0})

    self.frame = frame
    self.cards = {}

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", CFG.header.x, CFG.header.y)
    title:SetFont(STANDARD_TEXT_FONT, HEADER.titleSize, "")
    title:SetText("M+ Stat Profiles")
    ApplyColor(title, CFG.colors.gold)

    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetWidth(CFG.header.subtitleWidth)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetText("Compare the stat setups you used in Mythic+ and see how they performed.")
    ApplyColor(subtitle, CFG.colors.muted)

    self.summaryText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.summaryText:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -10)
    self.summaryText:SetText("Loading stat priority data...")
    ApplyColor(self.summaryText, CFG.colors.soft)

    local controls = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    controls:SetPoint("TOPLEFT", frame, "TOPLEFT", CFG.controls.x, CFG.controls.y)
    controls:SetSize(CFG.controls.width, CFG.controls.height)
    StylePanel(controls, CFG.colors.controlBg, CFG.colors.cardBorder)

    self.dungeonDropdown = MakeDropdown(controls, CFG.controls.dungeonWidth, CFG.controls.dungeonX, CFG.controls.labelY, "Dungeon / Zone", function(_, level)
        local options = GetDungeonOptions(StatProfiles.currentSpecEncounters or {})

        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.checked = option.value == StatProfiles.selectedMapID
            info.func = function()
                StatProfiles.selectedMapID = option.value
                StatProfiles.selectedKeyLevel = nil
                StatProfiles.selectedProfile = nil
                StatProfiles.selectedIndex = nil
                StatProfiles:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    local specLabel = controls:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    specLabel:SetPoint("TOPLEFT", controls, "TOPLEFT", CFG.controls.specX, CFG.controls.labelY)
    specLabel:SetWidth(CFG.controls.specWidth)
    specLabel:SetJustifyH("LEFT")
    specLabel:SetText("Current Spec")
    ApplyColor(specLabel, CFG.colors.muted)

    self.specValue = controls:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.specValue:SetPoint("TOPLEFT", controls, "TOPLEFT", CFG.controls.specX, CFG.controls.labelY - 26)
    self.specValue:SetWidth(CFG.controls.specWidth)
    self.specValue:SetJustifyH("LEFT")
    self.specValue:SetText("Loading...")
    ApplyColor(self.specValue, CFG.colors.gold)

    self.keyDropdown = MakeDropdown(controls, CFG.controls.keyWidth, CFG.controls.keyX, CFG.controls.labelY, "Key Level", function(_, level)
        local options = GetKeyOptions(StatProfiles.currentSpecEncounters or {}, StatProfiles.selectedMapID)

        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.checked = option.value == StatProfiles.selectedKeyLevel
            info.func = function()
                StatProfiles.selectedKeyLevel = option.value
                StatProfiles.selectedProfile = nil
                StatProfiles.selectedIndex = nil
                StatProfiles:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    self.outcomeDropdown = MakeDropdown(controls, CFG.controls.outcomeWidth, CFG.controls.outcomeX, CFG.controls.labelY, "Performance Metric", function(_, level)
        local options = GetMetricOptions()

        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.func = function()
                StatProfiles.selectedMetricKey = option.value
                StatProfiles.selectedProfile = nil
                StatProfiles.selectedIndex = nil
                StatProfiles:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    self.emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.emptyText:SetPoint("TOPLEFT", frame, "TOPLEFT", CFG.list.x, CFG.list.y)
    self.emptyText:SetWidth(CFG.list.width)
    self.emptyText:SetJustifyH("LEFT")
    self.emptyText:SetText("No stat priority data captured yet.")
    ApplyColor(self.emptyText, CFG.colors.text)
    self.emptyText:Hide()

    self.detailPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    self.detailPanel:SetSize(CFG.details.width, CFG.details.minHeight)
    StylePanel(self.detailPanel, CFG.colors.detailBg, CFG.colors.detailBorder)
    self.detailPanel:Show()

    frame:SetScript("OnShow", function()
        StatProfiles:Refresh()
    end)

    return frame
end

function KeyLab_CreateStatProfilesTab(parent)
    return StatProfiles:Create(parent)
end

if KeyLab.RegisterTab then
    KeyLab.RegisterTab("M+ Stat Profiles", function(parent)
        return StatProfiles:Create(parent)
    end)
end

return StatProfiles
