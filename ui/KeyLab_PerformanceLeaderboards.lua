local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

--[[
KeyLab_PerformanceLeaderboards.lua

Purpose:
- Displays the permanent Top 5 DPS and Top 5 HPS season leaderboards.
- Reads already-ranked records from the database layer.
- Does NOT capture, rank, prune, or migrate saved data.
]]

local GOLD = { 0.820, 0.760, 0.580, 1.0 }
local TEXT = { 0.940, 0.960, 0.990, 1.0 }
local MUTED = { 0.680, 0.730, 0.820, 1.0 }
local SOFT = { 0.780, 0.830, 0.900, 1.0 }
local BLUE = { 0.500, 0.680, 0.940, 1.0 }
local GREEN = { 0.460, 0.780, 0.500, 1.0 }
local BORDER = { 0.240, 0.380, 0.620, 0.62 }
local HOVER = { 0.300, 0.420, 0.600, 0.78 }
local SELECTED = { 0.620, 0.560, 0.410, 0.78 }
local CARD_BG = { 0.030, 0.052, 0.098, 0.94 }
local CONTROL_BG = { 0.026, 0.046, 0.088, 0.94 }
local Theme = KeyLab.UI and KeyLab.UI.Theme or {}
local HEADER = Theme.tabHeader or { summaryY = -72, analysisControlsY = -92, analysisContentY = -178 }
local SPACING = Theme.spacing or { compactCard = 8, section = 18 }

local STAT_COLORS = {
    crit = "ffff6b6b",
    haste = "ffffd166",
    mastery = "ff7ea8ff",
    versatility = "ff72d68f",
}

local STAT_LABELS = {
    crit = "Critical Strike",
    haste = "Haste",
    mastery = "Mastery",
    versatility = "Versatility",
}

local function Color(fontString, color)
    if fontString and color then fontString:SetTextColor(color[1], color[2], color[3], color[4] or 1) end
    return fontString
end

local function Panel(parent, x, y, width, height, borderColor, backgroundColor)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    frame:SetSize(width, height)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        edgeSize = 1,
    })
    local background = backgroundColor or CARD_BG
    frame:SetBackdropColor(background[1], background[2], background[3], background[4])
    local border = borderColor or BORDER
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
    return frame
end

local function Font(parent, text, x, y, width, object, color, justify)
    local font = parent:CreateFontString(nil, "OVERLAY", object or "GameFontHighlightSmall")
    font:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if width then font:SetWidth(width) end
    font:SetJustifyH(justify or "LEFT")
    font:SetText(text or "")
    return Color(font, color or TEXT)
end

local function ClearChildren(frame)
    if not frame then return end
    for _, child in ipairs({ frame:GetChildren() }) do child:Hide(); child:SetParent(nil) end
    for _, region in ipairs({ frame:GetRegions() }) do region:Hide() end
end

local function ShortNumber(value)
    value = tonumber(value) or 0
    if value >= 1000000000 then return string.format("%.2fB", value / 1000000000) end
    if value >= 1000000 then return string.format("%.1fM", value / 1000000) end
    if value >= 1000 then return string.format("%.1fK", value / 1000) end
    return string.format("%.0f", value)
end

local function GetCurrentSpec()
    if GetSpecialization and GetSpecializationInfo then
        local index = GetSpecialization()
        if index then
            local _, name = GetSpecializationInfo(index)
            if name and name ~= "" then return name end
        end
    end
    return "Current Specialization"
end

local function GetPlayer(encounter)
    return type(encounter) == "table" and type(encounter.player) == "table" and encounter.player or {}
end

local function GetStats(encounter)
    return type(encounter) == "table" and type(encounter.stats) == "table" and encounter.stats or {}
end

local function GetMetric(encounter, key)
    return tonumber(type(encounter) == "table" and type(encounter.metrics) == "table" and encounter.metrics[key])
end

local function GetTalentString(encounter)
    local talents = type(encounter) == "table" and type(encounter.talents) == "table" and encounter.talents or {}
    return talents.talentString or talents.importString or talents.loadoutString
        or (type(encounter) == "table" and (encounter.talentString or encounter.talentsString)) or ""
end

local function GetLoadoutName(encounter)
    local talents = type(encounter) == "table" and type(encounter.talents) == "table" and encounter.talents or {}
    local name = talents.loadoutName or talents.configName or talents.talentLoadoutName
    if name and name ~= "" then return name end
    local talentString = GetTalentString(encounter)
    local capture = KeyLab.Capture and KeyLab.Capture.Talents
    local names = capture and capture.GetLoadoutNameMap and capture.GetLoadoutNameMap() or {}
    return names[talentString]
end

local function GetStatPriority(encounter)
    local stats = GetStats(encounter)
    local values = {}
    local order = { crit = 1, haste = 2, mastery = 3, versatility = 4 }
    for key in pairs(order) do
        table.insert(values, { key = key, value = tonumber(stats[key]) or 0 })
    end
    table.sort(values, function(a, b)
        if a.value == b.value then return order[a.key] < order[b.key] end
        return a.value > b.value
    end)
    local labels = {}
    for _, stat in ipairs(values) do table.insert(labels, STAT_LABELS[stat.key]) end
    return table.concat(labels, " > ")
end

local function SourceText(mode, encounter)
    if mode == "raid" then
        local raid = type(encounter) == "table" and type(encounter.raid) == "table" and encounter.raid or {}
        local name = raid.encounterName or "Raid Boss"
        local difficulty = raid.difficultyName
        return difficulty and (name .. " • " .. difficulty) or name
    end
    local challenge = type(encounter) == "table" and type(encounter.challenge) == "table" and encounter.challenge or {}
    local name = challenge.dungeonName or "Mythic+"
    local level = tonumber(challenge.keyLevel)
    return level and (name .. " +" .. tostring(level)) or name
end

local function ResultText(mode, encounter)
    if mode == "raid" then
        local raid = type(encounter) == "table" and type(encounter.raid) == "table" and encounter.raid or {}
        return raid.killed and "Defeated" or "Pull"
    end
    local challenge = type(encounter) == "table" and type(encounter.challenge) == "table" and encounter.challenge or {}
    if challenge.onTime == true or challenge.timed == true then return "Timed" end
    if challenge.completed == true then return "Completed" end
    return "Run"
end

local function ProfileTitle(profileType, encounter)
    if profileType == "talent" then return GetLoadoutName(encounter) or "Talent Build" end
    if profileType == "stats" then return GetStatPriority(encounter) end
    return "Gear Profile"
end

local function ProfileSubtitle(profileType, encounter)
    if profileType == "gear" then
        local gear = type(encounter) == "table" and type(encounter.gear) == "table" and encounter.gear or {}
        local level = tonumber(gear.averageItemLevel)
        return level and string.format("Item Level %.1f", level) or "Item Level unavailable"
    end
    local player = GetPlayer(encounter)
    local spec = player.spec or player.specName or GetCurrentSpec()
    local class = player.className or player.class
    return class and (tostring(spec) .. " " .. tostring(class)) or spec
end

local function AddBar(card, value, maximum, x, width, color)
    x = x or 180
    width = width or 230
    color = color or BLUE
    local background = card:CreateTexture(nil, "BACKGROUND")
    background:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", x, 8)
    background:SetSize(width, 6)
    background:SetColorTexture(0.04, 0.08, 0.15, 1)
    local fill = card:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("LEFT", background, "LEFT")
    fill:SetSize(width * math.max(0.03, math.min(1, (tonumber(value) or 0) / math.max(1, maximum))), 6)
    fill:SetColorTexture(color[1], color[2], color[3], 0.95)
end

local function AddStatLine(parent, encounter, x, y)
    local stats = GetStats(encounter)
    local parts = {}
    for _, key in ipairs({ "crit", "haste", "mastery", "versatility" }) do
        table.insert(parts, "|c" .. STAT_COLORS[key] .. STAT_LABELS[key] .. " "
            .. string.format("%.1f%%", tonumber(stats[key]) or 0) .. "|r")
    end
    Font(parent, table.concat(parts, "  •  "), x, y, 720, "GameFontHighlightSmall", TEXT)
end

local function AddGearList(parent, encounter, x, y, width)
    local gear = type(encounter) == "table" and type(encounter.gear) == "table" and encounter.gear or {}
    local slots = type(gear.slots) == "table" and gear.slots or {}
    local names = {}
    for slotName in pairs(slots) do table.insert(names, tostring(slotName)) end
    table.sort(names)
    local lines = {}
    for _, slotName in ipairs(names) do
        local slot = slots[slotName]
        if type(slot) == "table" then
            local name = slot.itemName or slot.name or slot.itemLink or (slot.itemID and ("Item " .. tostring(slot.itemID))) or "Empty"
            table.insert(lines, slotName .. ": " .. tostring(name))
        end
    end
    Font(parent, #lines > 0 and table.concat(lines, "   •   ") or "No equipped-item details saved.",
        x, y, width, "GameFontDisableSmall", MUTED)
end

local function Divider(parent, x, y, width, height)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    line:SetSize(width, height)
    line:SetColorTexture(BORDER[1], BORDER[2], BORDER[3], 0.75)
end

local function FormatDuration(seconds)
    seconds = tonumber(seconds)
    if not seconds then return "Not captured" end
    seconds = math.max(0, math.floor(seconds + 0.5))
    return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function GetDuration(encounter)
    local challenge = type(encounter.challenge) == "table" and encounter.challenge or {}
    local raid = type(encounter.raid) == "table" and encounter.raid or {}
    return encounter.durationSeconds or challenge.durationSeconds or raid.durationSeconds
        or (challenge.durationMS and (challenge.durationMS / 1000))
        or (raid.durationMS and (raid.durationMS / 1000))
end

local function GetDateText(encounter)
    if encounter.dateText and encounter.dateText ~= "" then return encounter.dateText end
    if encounter.savedAtText and encounter.savedAtText ~= "" then return encounter.savedAtText end
    local timestamp = tonumber(encounter.timestamp or encounter.savedAt)
    if timestamp and date then return date("%b %d, %Y %I:%M %p", timestamp) end
    return "Not captured"
end

local function DetailRow(parent, label, value, x, y, width)
    Font(parent, label, x, y, width, "GameFontDisableSmall", MUTED)
    Font(parent, tostring(value or "Not captured"), x, y - 13, width, "GameFontHighlightSmall", TEXT)
    return y - 35
end

local function StatValue(key, value)
    value = tonumber(value)
    if not value then return "—" end
    if key == "crit" or key == "haste" or key == "mastery" or key == "versatility"
        or key == "leech" or key == "avoidance" or key == "speed" or key == "dodge" then
        return string.format("%.1f%%", value)
    end
    return ShortNumber(value)
end

local function AddStatsColumn(parent, encounter, x, y, width)
    local stats = GetStats(encounter)
    local order = KeyLab.Mapping and KeyLab.Mapping.StatOrder
        or { "strength", "agility", "stamina", "intellect", "crit", "haste", "mastery", "versatility", "leech", "avoidance", "speed", "dodge", "armor" }
    local mapping = KeyLab.Mapping and KeyLab.Mapping.Stats or {}
    local shown = 0
    for _, key in ipairs(order) do
        local value = tonumber(stats[key])
        if value and value > 0 and shown < 13 then
            local label = mapping[key] and mapping[key].label or STAT_LABELS[key] or key
            local color = key == "crit" and { 1.00, 0.42, 0.42, 1 }
                or key == "haste" and { 1.00, 0.82, 0.40, 1 }
                or key == "mastery" and { 0.49, 0.66, 1.00, 1 }
                or key == "versatility" and { 0.45, 0.84, 0.56, 1 }
                or TEXT
            Font(parent, tostring(label) .. ": " .. StatValue(key, value), x, y, width, "GameFontHighlightSmall", color)
            y = y - 16
            shown = shown + 1
        end
    end
    if shown == 0 then Font(parent, "No stat snapshot available.", x, y, width, "GameFontDisableSmall", MUTED) end
end

local OUTCOMES = {
    { "damageDone", "Damage Done" }, { "dps", "DPS" },
    { "healingDone", "Healing Done" }, { "hps", "HPS" },
    { "absorbs", "Absorbs" }, { "interrupts", "Interrupts" },
    { "dispels", "Dispels" }, { "damageTaken", "Damage Taken" },
    { "avoidableDamageTaken", "Avoidable Damage" }, { "deaths", "Deaths" },
}

local function AddOutcomesColumn(parent, encounter, x, y, width)
    local shown = 0
    for _, definition in ipairs(OUTCOMES) do
        local value = GetMetric(encounter, definition[1])
        if value ~= nil then
            Font(parent, definition[2] .. ": " .. ShortNumber(value), x, y, width, "GameFontHighlightSmall", TEXT)
            y = y - 16
            shown = shown + 1
        end
    end
    if shown == 0 then Font(parent, "No captured outcomes available.", x, y, width, "GameFontDisableSmall", MUTED) end
end

local GEAR_SLOTS = {
    "Head", "Neck", "Shoulders", "Back", "Chest", "Wrist", "Main Hand", "Off Hand",
    "Hands", "Waist", "Legs", "Feet", "Finger 1", "Finger 2", "Trinket 1", "Trinket 2",
}

local function GearSlot(encounter, slotName)
    local gear = type(encounter.gear) == "table" and encounter.gear or {}
    local slots = type(gear.slots) == "table" and gear.slots or {}
    return slots[slotName]
end

local function GearName(slot)
    if type(slot) ~= "table" then return "Empty" end
    return slot.itemName or slot.name or slot.itemLink or (slot.itemID and ("Item " .. tostring(slot.itemID))) or "Empty"
end

local function AddGearRow(parent, encounter, slotName, x, y)
    local slot = GearSlot(encounter, slotName)
    Font(parent, slotName, x, y, 82, "GameFontDisableSmall", MUTED)
    Font(parent, GearName(slot), x + 86, y, 290, "GameFontHighlightSmall", TEXT)
    Font(parent, slot and slot.itemLevel and tostring(math.floor(slot.itemLevel + 0.5)) or "—",
        x + 380, y, 42, "GameFontDisableSmall", BLUE, "RIGHT")
end

local function BuildDetails(tab, entry)
    local details = tab.detailsContent
    ClearChildren(details)
    if not entry then
        Font(details, tab.profileType == "gear" and "Gear Profile Details" or "Encounter Details",
            14, -16, 600, "GameFontNormalLarge", GOLD)
        Font(details, "Select a card above to see the saved setup and its full details.",
            14, -48, 900, "GameFontHighlightSmall", MUTED)
        return
    end

    local encounter = entry.encounter or {}
    local metricLabel = entry.metricKey == "hps" and "HPS" or "DPS"
    local player = GetPlayer(encounter)
    local spec = player.spec or player.specName or GetCurrentSpec()
    local prefix = tab.mode == "raid" and "Raid" or "Mythic+"

    if tab.profileType == "gear" then
        Font(details, "Selected Gear Profile", 14, -14, 420, "GameFontNormalLarge", GOLD)
        Font(details, metricLabel .. ": " .. ShortNumber(entry.value), 700, -14, 190, "GameFontNormalLarge",
            entry.metricKey == "hps" and GREEN or BLUE, "RIGHT")
        Font(details, SourceText(tab.mode, encounter) .. "  •  " .. ResultText(tab.mode, encounter),
            14, -38, 520, "GameFontDisableSmall", MUTED)
        local gear = type(encounter.gear) == "table" and encounter.gear or {}
        local itemLevel = tonumber(gear.averageItemLevel)
        Font(details, itemLevel and string.format("Average Item Level: %.1f", itemLevel) or "Average Item Level unavailable",
            620, -38, 270, "GameFontDisableSmall", MUTED, "RIGHT")
        AddStatLine(details, encounter, 14, -62)
        Divider(details, 14, -82, 900, 1)
        Font(details, "Equipped Items", 16, -90, 200, "GameFontNormal", GOLD)
        Divider(details, 464, -112, 1, 174)
        for index, slotName in ipairs(GEAR_SLOTS) do
            local column = index <= 8 and 0 or 1
            local row = column == 0 and index or index - 8
            AddGearRow(details, encounter, slotName, column == 0 and 16 or 476, -114 - ((row - 1) * 21))
        end
        return
    end

    Font(details, prefix .. " " .. tostring(spec) .. " - " .. ProfileTitle(tab.profileType, encounter),
        14, -14, 900, "GameFontNormalLarge", GOLD)
    Font(details, SourceText(tab.mode, encounter) .. "  •  " .. metricLabel .. ": " .. ShortNumber(entry.value),
        14, -38, 900, "GameFontDisableSmall", MUTED)

    local sectionY = -76
    local columns = { 16, 205, 430, 645 }
    local widths = { 170, 200, 190, 245 }
    Divider(details, 193, sectionY + 4, 1, 225)
    Divider(details, 418, sectionY + 4, 1, 225)
    Divider(details, 633, sectionY + 4, 1, 225)
    Font(details, "Run Details", columns[1], sectionY, widths[1], "GameFontNormal", GOLD)
    Font(details, "Stats (At Time of Run)", columns[2], sectionY, widths[2], "GameFontNormal", GOLD)
    Font(details, "Talent String", columns[3], sectionY, widths[3], "GameFontNormal", GOLD)
    Font(details, "Captured Outcomes", columns[4], sectionY, widths[4], "GameFontNormal", GOLD)

    local y = sectionY - 24
    y = DetailRow(details, "Date", GetDateText(encounter), columns[1], y, widths[1])
    y = DetailRow(details, tab.mode == "raid" and "Boss" or "Dungeon", SourceText(tab.mode, encounter), columns[1], y, widths[1])
    y = DetailRow(details, "Result", ResultText(tab.mode, encounter), columns[1], y, widths[1])
    DetailRow(details, "Duration", FormatDuration(GetDuration(encounter)), columns[1], y, widths[1])
    AddStatsColumn(details, encounter, columns[2], sectionY - 24, widths[2])

    local talentString = GetTalentString(encounter)
    local editBox = CreateFrame("EditBox", nil, details, "InputBoxTemplate")
    editBox:SetPoint("TOPLEFT", details, "TOPLEFT", columns[3] + 4, sectionY - 22)
    editBox:SetSize(widths[3] - 8, 30)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetText(talentString ~= "" and talentString or "Not captured")
    editBox:SetCursorPosition(0)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    local copy = CreateFrame("Button", nil, details, "UIPanelButtonTemplate")
    copy:SetPoint("TOPLEFT", details, "TOPLEFT", columns[3] + 4, sectionY - 58)
    copy:SetSize(72, 22)
    copy:SetText("Copy")
    copy:SetEnabled(talentString ~= "")
    copy:SetScript("OnClick", function()
        editBox:SetFocus()
        editBox:HighlightText()
    end)
    Font(details, "Click Copy, then Ctrl+C.", columns[3] + 4, sectionY - 88, widths[3] - 8, "GameFontDisableSmall", MUTED)
    AddOutcomesColumn(details, encounter, columns[4], sectionY - 24, widths[4])
end

local function BuildColumn(tab, metricKey, x, width)
    width = width or 452
    local journal = KeyLab.DB and KeyLab.DB.SeasonJournal
    local entries = journal and journal.GetLeaderboard
        and journal.GetLeaderboard(tab.mode, tab.profileType, metricKey) or {}

    if #entries == 0 then
        Font(tab.dynamic, "No saved " .. (metricKey == "hps" and "HPS" or "DPS") .. " results yet.",
            x + 4, -18, width - 8, "GameFontDisableSmall", MUTED)
        return
    end

    if not tab.selectedEntry then tab.selectedEntry = entries[1] end
    local maximum = tonumber(entries[1] and entries[1].value) or 1
    for index = 1, math.min(5, #entries) do
        local entry = entries[index]
        local encounter = entry.encounter or {}
        local isSelected = tab.selectedEntry == entry
        local card = Panel(tab.dynamic, x, -((index - 1) * 52), width, 44, isSelected and SELECTED or BORDER, CARD_BG)
        card:EnableMouse(true)
        card:SetScript("OnMouseUp", function()
            tab.selectedEntry = entry
            tab:Refresh()
        end)
        card:SetScript("OnEnter", function(self)
            if tab.selectedEntry ~= entry then
                self:SetBackdropBorderColor(HOVER[1], HOVER[2], HOVER[3], HOVER[4] or 1)
            end
        end)
        card:SetScript("OnLeave", function(self)
            if tab.selectedEntry ~= entry then
                self:SetBackdropBorderColor(BORDER[1], BORDER[2], BORDER[3], BORDER[4] or 1)
            end
        end)
        Font(card, tostring(index) .. ".", 12, -13, 28, "GameFontNormal", GOLD)
        Font(card, ProfileTitle(tab.profileType, encounter), 46, -12, 330, "GameFontNormal", TEXT)
        Font(card, ProfileSubtitle(tab.profileType, encounter), 390, -14, 240, "GameFontDisableSmall", MUTED)
        Font(card, (metricKey == "hps" and "HPS: " or "DPS: ") .. ShortNumber(entry.value),
            660, -8, 250, "GameFontDisableSmall", metricKey == "hps" and GREEN or BLUE, "RIGHT")
        AddBar(card, entry.value, maximum, 660, 250, metricKey == "hps" and GREEN or BLUE)
    end
end

local function NewTab(mode, profileType)
    local tab = { mode = mode, profileType = profileType, selectedMetricKey = "dps" }
    local contentLabel = mode == "raid" and "Raid" or "M+"
    local profileLabel = profileType == "talent" and "Talent Builds"
        or profileType == "stats" and "Stat Profiles" or "Gear Profiles"

    function tab:Refresh()
        if not self.frame then return end
        self.specValue:SetText(GetCurrentSpec())
        UIDropDownMenu_SetText(self.metricDropdown, self.selectedMetricKey == "hps" and "HPS" or "DPS")
        local journal = KeyLab.DB and KeyLab.DB.SeasonJournal
        local selectedEntries = journal and journal.GetLeaderboard
            and journal.GetLeaderboard(self.mode, self.profileType, self.selectedMetricKey) or {}
        self.summary:SetText(string.format(
            "%d saved %s result%s • showing the Top 5",
            #selectedEntries,
            self.selectedMetricKey == "hps" and "HPS" or "DPS",
            #selectedEntries == 1 and "" or "s"
        ))
        ClearChildren(self.dynamic)

        local selectedStillPresent = false
        if self.selectedEntry then
            for _, entry in ipairs(selectedEntries) do
                if entry == self.selectedEntry then selectedStillPresent = true break end
            end
        end
        if not selectedStillPresent then
            self.selectedEntry = selectedEntries[1]
        end
        BuildColumn(self, self.selectedMetricKey, 0, 928)
        BuildDetails(self, self.selectedEntry)
        local cardStride = 44 + (SPACING.compactCard or 8)
        local detailY = (HEADER.analysisContentY or -178) - (5 * cardStride) - (SPACING.section or 18)
        self.details:ClearAllPoints()
        self.details:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 12, detailY)
    end

    function tab:Create(parent)
        local frame = CreateFrame("Frame", nil, parent)
        frame:SetAllPoints(parent)
        self.frame = frame

        Theme.CreateTabHeader(
            frame,
            contentLabel .. " " .. profileLabel,
            "Your strongest saved setups for this specialization. A lower result never replaces a better one."
        )
        self.summary = Font(frame, "Loading saved results...", HEADER.x or 18, HEADER.summaryY or -72,
            HEADER.summaryWidth or 890, "GameFontDisableSmall", SOFT, "CENTER")
        self.summary:SetHeight(HEADER.summaryHeight or 14)

        local specPanel = Panel(frame, 12, HEADER.analysisControlsY or -92, 928, 74, BORDER, CONTROL_BG)
        Font(specPanel, "Current Spec", 18, -12, 180, "GameFontDisableSmall", MUTED)
        self.specValue = Font(specPanel, GetCurrentSpec(), 18, -38, 280, "GameFontHighlightSmall", GOLD)
        Font(specPanel, "Performance Metric", 338, -12, 220, "GameFontDisableSmall", MUTED)
        self.metricDropdown = KeyLab.UI.Theme.CreateLegacyDropdown(specPanel)
        self.metricDropdown:SetPoint("TOPLEFT", specPanel, "TOPLEFT", 314, -25)
        UIDropDownMenu_SetWidth(self.metricDropdown, 220)
        UIDropDownMenu_Initialize(self.metricDropdown, function(_, level)
            if level ~= 1 then return end
            for _, option in ipairs({
                { value = "dps", text = "DPS" },
                { value = "hps", text = "HPS" },
            }) do
                local value = option.value
                local info = UIDropDownMenu_CreateInfo()
                info.text = option.text
                info.checked = tab.selectedMetricKey == value
                info.func = function()
                    tab.selectedMetricKey = value
                    tab.selectedEntry = nil
                    CloseDropDownMenus()
                    tab:Refresh()
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end)

        self.dynamic = CreateFrame("Frame", nil, frame)
        self.dynamic:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, HEADER.analysisContentY or -178)
        self.dynamic:SetSize(928, 252)

        self.details = CreateFrame("Frame", nil, frame)
        self.details:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -448)
        self.details:SetSize(928, 300)
        self.detailsContent = CreateFrame("Frame", nil, self.details)
        self.detailsContent:SetAllPoints(self.details)
        frame.Refresh = function() tab:Refresh() end
        frame:SetScript("OnShow", function() tab:Refresh() end)
        return frame
    end

    return tab
end

local tabs = {
    { "M+ Talent Builds", NewTab("mplus", "talent") },
    { "Raid Talent Builds", NewTab("raid", "talent") },
    { "M+ Stat Profiles", NewTab("mplus", "stats") },
    { "Raid Stat Profiles", NewTab("raid", "stats") },
    { "M+ Gear Profiles", NewTab("mplus", "gear") },
    { "Raid Gear Profiles", NewTab("raid", "gear") },
}

if KeyLab.RegisterTab then
    for _, definition in ipairs(tabs) do
        local name, tab = definition[1], definition[2]
        KeyLab.RegisterTab(name, function(parent) return tab:Create(parent) end)
    end
end
