local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Tabs = KeyLab.Tabs or {}

local EncounterData = (KeyLab.Analysis and KeyLab.Analysis.EncounterData) or KeyLab.EncounterData or {}
local RaidAnalysis = KeyLab.RaidAnalysis or {}
local Theme = KeyLab.UI and KeyLab.UI.Theme or {}
local COLORS = Theme.colors or {}
local SPACING = Theme.spacing or { compactCard = 8 }
local HEADER = Theme.tabHeader or {
    x = 18, titleY = -18, titleSize = 16, titleWidth = 900, titleHeight = 20,
    descriptionY = -43, descriptionWidth = 890, descriptionHeight = 16,
    summaryY = -66, summaryWidth = 890, summaryHeight = 14,
    analysisControlsY = -86, analysisContentY = -172,
}

local SLOT_ORDER = {
    "Head", "Neck", "Shoulders", "Back", "Chest", "Wrist", "Main Hand", "Off Hand",
    "Hands", "Waist", "Legs", "Feet", "Finger 1", "Finger 2", "Trinket 1", "Trinket 2",
}

local PROFILE_WIDTH = 928
local PROFILE_CARD_HEIGHT = 44
local PROFILE_CARD_GAP = SPACING.compactCard
local PROFILE_BAR_X = 798
local PROFILE_BAR_WIDTH = 96

local function Color(name, fallback)
    return COLORS[name] or fallback or { 1, 1, 1, 1 }
end

local function Style(frame, background, border)
    if Theme.StylePanel then Theme.StylePanel(frame, background or Color("cardBg"), border or Color("cardBorder")); return end
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    local bg, edge = background or { 0.02, 0.03, 0.06, 0.9 }, border or { 0.2, 0.3, 0.5, 0.6 }
    frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
    frame:SetBackdropBorderColor(edge[1], edge[2], edge[3], edge[4] or 1)
end

local function Text(parent, value, template, size, color, justify)
    local font = Theme.CreateText and Theme.CreateText(parent, value, template, size, color, justify)
        or parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    if not Theme.CreateText then
        font:SetText(value or "")
        local c = color or Color("text")
        font:SetTextColor(c[1], c[2], c[3], c[4] or 1)
    end
    font:SetJustifyH(justify or "LEFT")
    font:SetJustifyV("MIDDLE")
    return font
end

local function Place(parent, value, x, y, width, template, size, color, justify)
    local font = Text(parent, value, template, size, color, justify)
    font:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    font:SetSize(width, 22)
    return font
end

local function Panel(parent, x, y, width, height, border)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    frame:SetSize(width, height)
    Style(frame, Color("cardBg"), border or Color("cardBorder"))
    return frame
end

local function AddDivider(parent, x, y, width, height)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    line:SetSize(width or 1, height or 1)
    local color = Color("divider", { 0.440, 0.580, 0.780, 0.32 })
    line:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
    return line
end

local function Clear(frame)
    for _, child in ipairs({ frame:GetChildren() }) do child:Hide(); child:SetParent(nil) end
    for _, region in ipairs({ frame:GetRegions() }) do region:Hide() end
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

local function CreateComparisonBar(parent, value, maxValue, minValue, lowerIsBetter)
    local background = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    background:SetPoint("TOPLEFT", parent, "TOPLEFT", PROFILE_BAR_X, -17)
    background:SetSize(PROFILE_BAR_WIDTH, 9)
    Style(background, { 0.012, 0.020, 0.044, 0.90 }, { 0.185, 0.300, 0.500, 0.50 })

    local number = tonumber(value) or 0
    local maximum = tonumber(maxValue) or 0
    local minimum = tonumber(minValue) or 0
    local ratio = 0
    if maximum > 0 then
        if lowerIsBetter then
            ratio = maximum == minimum and 1 or 1 - ((number - minimum) / (maximum - minimum))
        else
            ratio = number / maximum
        end
    end
    ratio = math.max(0.06, math.min(1, ratio))

    local fill = background:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("LEFT", background, "LEFT", 0, 0)
    fill:SetSize(PROFILE_BAR_WIDTH * ratio, 7)
    local color = Color("blue", { 0.500, 0.680, 0.940, 0.95 })
    fill:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
end

local function Short(value, limit)
    value = tostring(value or "")
    return #value <= limit and value or (string.sub(value, 1, limit - 3) .. "...")
end

local function GetGear(encounter)
    return type(encounter) == "table" and type(encounter.gear) == "table" and encounter.gear or {}
end

local function GetPlayer(encounter)
    return EncounterData.GetPlayer and EncounterData.GetPlayer(encounter) or encounter.player or {}
end

local function GetMetricValue(encounter, metricKey)
    return EncounterData.GetMetricValue and EncounterData.GetMetricValue(encounter, metricKey)
        or tonumber(encounter and encounter.metrics and encounter.metrics[metricKey])
end

local function GetMetricInfo(metricKey)
    return EncounterData.GetMetricInfoByKey and EncounterData.GetMetricInfoByKey(metricKey) or nil
end

local function GetMetricOptions()
    local options = {}
    local keys = KeyLab.Mapping and KeyLab.Mapping.ProfileComparisonMetricKeys or { "dps", "hps" }
    for _, metricKey in ipairs(keys) do
        local info = GetMetricInfo(metricKey)
        if info and info.store == true then
            table.insert(options, { value = info.keylabKey, label = info.label or info.keylabKey })
        end
    end
    return options
end

local function GearSignature(gear)
    if type(gear.signature) == "string" and gear.signature ~= "" then return gear.signature end
    local parts = {}
    for _, slotName in ipairs(SLOT_ORDER) do
        local slot = gear.slots and gear.slots[slotName] or {}
        table.insert(parts, slotName .. ":" .. tostring(slot.itemLink or slot.itemID or "empty"))
    end
    return table.concat(parts, "|")
end

local function HasGear(encounter)
    local gear = GetGear(encounter)
    if type(gear.slots) ~= "table" then return false end
    for _, slot in pairs(gear.slots) do if type(slot) == "table" and (slot.itemID or slot.itemLink) then return true end end
    return false
end

local function MPlusEncounters()
    return EncounterData.GetEncounterList and EncounterData.GetEncounterList({
        completedOnly = true,
        currentCharacterOnly = true,
        allowMissingIdentity = false,
    }) or {}
end

local function RaidEncounters()
    return RaidAnalysis.GetEncounters and RaidAnalysis.GetEncounters() or {}
end

local function PrimaryValue(mode, encounter)
    if mode == "raid" then return tonumber(encounter and encounter.raid and encounter.raid.encounterID) end
    return tonumber(encounter and encounter.challenge and encounter.challenge.mapID)
end

local function SecondaryValue(mode, encounter)
    if mode == "raid" then return tonumber(encounter and encounter.raid and encounter.raid.difficultyID) end
    return tonumber(encounter and encounter.challenge and encounter.challenge.keyLevel)
end

local function PrimaryLabel(mode, encounter)
    if mode == "raid" then
        local raid = encounter.raid or {}
        return raid.encounterName or ("Encounter " .. tostring(raid.encounterID or "?"))
    end
    local challenge = encounter.challenge or {}
    return challenge.dungeonName or ("Map " .. tostring(challenge.mapID or "?"))
end

local function SecondaryLabel(mode, encounter)
    if mode == "raid" then
        local raid = encounter.raid or {}
        return raid.difficultyName or ("Difficulty " .. tostring(raid.difficultyID or "?"))
    end
    return "+" .. tostring(SecondaryValue(mode, encounter) or 0)
end

local function SpecName(encounter)
    local player = GetPlayer(encounter)
    return player.spec or player.specName or "Unknown Spec"
end

local function SpecID(encounter)
    local player = GetPlayer(encounter)
    return tonumber(player.specID or encounter and encounter.specID)
end

local function GetCurrentSpecIdentity()
    local specIndex = GetSpecialization and GetSpecialization()
    if specIndex and GetSpecializationInfo then
        local specID, specName = GetSpecializationInfo(specIndex)
        if specName and specName ~= "" then return tonumber(specID), specName end
    end
    return nil, nil
end

local function MatchesCurrentSpec(encounter, currentSpecID, currentSpecName)
    local encounterSpecID = SpecID(encounter)
    if currentSpecID and encounterSpecID then return encounterSpecID == currentSpecID end
    if currentSpecName then return SpecName(encounter) == currentSpecName end
    return true
end

local function OptionLabel(options, selected, fallback)
    for _, option in ipairs(options or {}) do if option.value == selected then return option.label end end
    return fallback
end

local function HasOption(options, selected)
    for _, option in ipairs(options or {}) do if option.value == selected then return true end end
    return false
end

local function BuildOptions(tab)
    local primary, secondary = {}, {}
    local primarySeen, secondarySeen = {}, {}
    table.insert(primary, { value = nil, label = tab.mode == "raid" and "All Bosses" or "All Dungeons" })
    table.insert(secondary, { value = nil, label = tab.mode == "raid" and "All Difficulties" or "All Keys" })

    for _, encounter in ipairs(tab.currentSpecEncounters or {}) do
        local primaryValue = PrimaryValue(tab.mode, encounter)
        if primaryValue and not primarySeen[primaryValue] then
            primarySeen[primaryValue] = true
            table.insert(primary, { value = primaryValue, label = PrimaryLabel(tab.mode, encounter) })
        end
        if (not tab.selectedPrimary) or primaryValue == tab.selectedPrimary then
            local secondaryValue = SecondaryValue(tab.mode, encounter)
            if secondaryValue and not secondarySeen[secondaryValue] then
                secondarySeen[secondaryValue] = true
                table.insert(secondary, { value = secondaryValue, label = SecondaryLabel(tab.mode, encounter) })
            end
        end
    end
    table.sort(primary, function(a, b)
        if a.value == nil or b.value == nil then return a.value == nil and b.value ~= nil end
        return tostring(a.label) < tostring(b.label)
    end)
    table.sort(secondary, function(a, b)
        if a.value == nil or b.value == nil then return a.value == nil and b.value ~= nil end
        if tab.mode == "mplus" then return tonumber(a.value) > tonumber(b.value) end
        return tostring(a.label) < tostring(b.label)
    end)
    return primary, secondary
end

local function Matches(tab, encounter)
    if not HasGear(encounter) then return false end
    if not MatchesCurrentSpec(encounter, tab.currentSpecID, tab.currentSpecName) then return false end
    if tab.selectedPrimary and PrimaryValue(tab.mode, encounter) ~= tab.selectedPrimary then return false end
    if tab.selectedSecondary and SecondaryValue(tab.mode, encounter) ~= tab.selectedSecondary then return false end
    return true
end

local function BuildProfiles(tab)
    local groups = {}
    local info = GetMetricInfo(tab.selectedMetricKey)
    local lowerIsBetter = info and info.higherIsBetter == false
    for _, encounter in ipairs(tab.allEncounters or {}) do
        if Matches(tab, encounter) then
            local gear = GetGear(encounter)
            local signature = GearSignature(gear)
            local key = SpecName(encounter) .. "|" .. signature
            local value = tonumber(GetMetricValue(encounter, tab.selectedMetricKey))
            local group = groups[key]
            if not group then
                group = { key = key, signature = signature, gear = gear, spec = SpecName(encounter), uses = 0, metricUses = 0, total = 0, bestValue = nil, bestEncounter = nil, latestEncounter = nil }
                groups[key] = group
            end
            group.uses = group.uses + 1
            if not group.latestEncounter or (tonumber(encounter.timestamp) or 0) > (tonumber(group.latestEncounter.timestamp) or 0) then
                group.latestEncounter = encounter
            end
            if value ~= nil then
                group.metricUses = group.metricUses + 1
                group.total = group.total + value
                group.average = group.total / group.metricUses
                if group.bestValue == nil or (lowerIsBetter and value < group.bestValue) or (not lowerIsBetter and value > group.bestValue) then
                    group.bestValue, group.bestEncounter, group.gear = value, encounter, gear
                end
            end
        end
    end
    local profiles = {}
    for _, profile in pairs(groups) do table.insert(profiles, profile) end
    table.sort(profiles, function(a, b)
        if a.average == nil or b.average == nil then
            if a.average == nil and b.average == nil then return a.uses > b.uses end
            return a.average ~= nil
        end
        if a.average == b.average then return a.uses > b.uses end
        return lowerIsBetter and a.average < b.average or (not lowerIsBetter and a.average > b.average)
    end)
    return profiles, lowerIsBetter
end

local function Dropdown(parent, label, x, width, optionsFunc, selectedFunc, changedFunc)
    Place(parent, label, x, -12, width, "GameFontDisableSmall", nil, Color("muted"))
    local menu = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    menu:SetPoint("TOPLEFT", parent, "TOPLEFT", x - 16, -30)
    UIDropDownMenu_SetWidth(menu, width)
    UIDropDownMenu_Initialize(menu, function(_, level)
        for _, option in ipairs(optionsFunc() or {}) do
            local value, optionText = option.value, option.label
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.checked = optionText, value == selectedFunc()
            info.func = function() changedFunc(value) end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    menu.SetDisplay = function(self, value, fallback) UIDropDownMenu_SetText(self, OptionLabel(optionsFunc(), value, fallback)) end
    return menu
end

local function ItemDisplayName(slot)
    if not slot or not (slot.itemID or slot.itemLink) then return "Empty" end
    local linkName = slot.itemLink and tostring(slot.itemLink):match("|h%[(.-)%]|h") or nil
    return slot.itemName or linkName or ("Item " .. tostring(slot.itemID))
end

local function AddGearItem(parent, slotName, slot, x, y, width)
    local button = CreateFrame("Button", nil, parent)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetSize(width, 23)
    local slotLabel = Place(button, slotName, 0, 0, 82, "GameFontDisableSmall", nil, Color("muted"))
    local item = Text(button, Short(ItemDisplayName(slot), 34), "GameFontHighlightSmall", nil, Color("text"))
    item:SetPoint("LEFT", button, "LEFT", 86, 0)
    item:SetWidth(width - 138)
    item:SetJustifyH("LEFT")
    local level = Text(button, slot and slot.itemLevel and tostring(math.floor(slot.itemLevel + 0.5)) or "—", "GameFontDisableSmall", nil, Color("blue"), "RIGHT")
    level:SetPoint("RIGHT", button, "RIGHT", -2, 0)
    level:SetWidth(45)
    if slot and slot.itemLink then
        button:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetHyperlink(slot.itemLink); GameTooltip:Show() end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
end

local function ContextText(tab, encounter)
    if tab.mode == "raid" then
        local raid = encounter.raid or {}
        return string.format("%s • %s • Pull %s • %s", raid.encounterName or "Boss", raid.difficultyName or "Unknown Difficulty", tostring(raid.pullNumber or "?"), raid.killed and "Kill" or "Wipe")
    end
    local challenge = encounter.challenge or {}
    local result = EncounterData.GetResultText and EncounterData.GetResultText(encounter) or encounter.result or "Completed"
    return string.format("%s +%s • %s", challenge.dungeonName or "Dungeon", tostring(challenge.keyLevel or "?"), result)
end

local function StatsText(encounter)
    local stats = encounter and encounter.stats or {}
    return string.format("Crit %.1f%%  •  Haste %.1f%%  •  Mastery %.1f%%  •  Versatility %.1f%%", tonumber(stats.crit) or 0, tonumber(stats.haste) or 0, tonumber(stats.mastery) or 0, tonumber(stats.versatility) or 0)
end

local function BuildDynamic(tab, profiles, lowerIsBetter)
    Clear(tab.dynamic)
    if #profiles == 0 then
        Place(tab.dynamic, "No matching gear profiles yet. New runs and boss pulls will save the equipped setup at their start.", 10, -30, PROFILE_WIDTH - 20, "GameFontHighlight", 14, Color("muted"), "CENTER"):SetHeight(50)
        tab.dynamic:SetHeight(560)
        return
    end

    local metricInfo = GetMetricInfo(tab.selectedMetricKey)
    local metricLabel = metricInfo and metricInfo.label or tab.selectedMetricKey
    local showCount = math.min(5, #profiles)
    local y = 0
    local selected
    for index = 1, showCount do
        local profile = profiles[index]
        if profile.signature == tab.selectedSignature and profile.spec == tab.selectedProfileSpec then selected = profile; break end
    end
    if not selected then selected = profiles[1]; tab.selectedSignature, tab.selectedProfileSpec = selected.signature, selected.spec end

    local maxValue, minValue = 0, nil
    for index = 1, showCount do
        local value = tonumber(profiles[index].average)
        if value ~= nil then
            maxValue = math.max(maxValue, value)
            minValue = minValue == nil and value or math.min(minValue, value)
        end
    end

    for index = 1, showCount do
        local profile = profiles[index]
        local profileSignature, profileSpec = profile.signature, profile.spec
        local card = Panel(tab.dynamic, 0, y, PROFILE_WIDTH, PROFILE_CARD_HEIGHT, profile.signature == tab.selectedSignature and profile.spec == tab.selectedProfileSpec and Color("gold") or Color("cardBorder"))
        card:EnableMouse(true)
        card:SetScript("OnMouseUp", function() tab.selectedSignature, tab.selectedProfileSpec = profileSignature, profileSpec; tab:Refresh() end)
        Place(card, "#" .. index, 12, -11, 34, "GameFontNormal", 13, Color("gold"), "CENTER")
        Place(card, "Gear Profile", 54, -11, 120, "GameFontNormal", nil, Color("text"))
        Place(card, profile.spec, 180, -11, 135, "GameFontHighlightSmall", nil, Color("muted"))
        local averageItemLevel = tonumber(profile.gear and profile.gear.averageItemLevel)
        local itemLevelText = averageItemLevel and string.format("Avg Item Level: %.1f", averageItemLevel) or "Avg Item Level unavailable"
        Place(card, itemLevelText, 320, -11, 280, "GameFontHighlightSmall", nil, averageItemLevel and Color("soft") or Color("muted"))
        Place(card, string.format("%d use%s", profile.uses, profile.uses == 1 and "" or "s"), 608, -11, 80, "GameFontDisableSmall", nil, Color("muted"), "CENTER")
        Place(card, profile.average ~= nil and ("Avg " .. FormatNumber(profile.average)) or "Outcome unavailable", 680, -11, 114, "GameFontNormal", nil, profile.average ~= nil and Color("blue") or Color("muted"), "RIGHT")
        if profile.average ~= nil then CreateComparisonBar(card, profile.average, maxValue, minValue or 0, lowerIsBetter) end
        y = y - PROFILE_CARD_HEIGHT - PROFILE_CARD_GAP
    end

    local detail = Panel(tab.dynamic, 0, y - 10, PROFILE_WIDTH, 300, Color("detailBorder"))
    Style(detail, Color("detailBg"), Color("detailBorder"))
    local detailEncounter = selected.bestEncounter or selected.latestEncounter or {}
    Place(detail, "Selected Gear Profile", 16, -10, 250, "GameFontNormal", 14, Color("gold"))
    local outcomeSummary = selected.average ~= nil
        and string.format("Average %s: %s  •  Best: %s  •  Used %d time%s", metricLabel, FormatNumber(selected.average), FormatNumber(selected.bestValue), selected.uses, selected.uses == 1 and "" or "s")
        or string.format("%s outcome unavailable  •  Gear saved from %d run%s", metricLabel, selected.uses, selected.uses == 1 and "" or "s")
    Place(detail, outcomeSummary, 280, -10, 608, "GameFontHighlightSmall", nil, selected.average ~= nil and Color("blue") or Color("muted"), "RIGHT")
    Place(detail, ContextText(tab, detailEncounter), 16, -34, 430, "GameFontHighlightSmall", nil, Color("text"))
    Place(detail, string.format("Average Item Level: %.1f", tonumber(selected.gear.averageItemLevel) or 0), 620, -34, 268, "GameFontHighlightSmall", nil, Color("text"), "RIGHT")
    Place(detail, StatsText(detailEncounter), 16, -56, 872, "GameFontDisableSmall", nil, Color("muted"))
    AddDivider(detail, 16, -78, PROFILE_WIDTH - 32, 1)
    Place(detail, "Equipped Items", 16, -82, 200, "GameFontNormal", 13, Color("gold"))
    AddDivider(detail, 464, -105, 1, 179)

    for index, slotName in ipairs(SLOT_ORDER) do
        local column = index <= 8 and 0 or 1
        local row = column == 0 and index or (index - 8)
        local x = column == 0 and 16 or 476
        AddGearItem(detail, slotName, selected.gear.slots and selected.gear.slots[slotName], x, -104 - ((row - 1) * 23), 436)
    end
    tab.dynamic:SetHeight(math.max(570, math.abs(y) + 320))
end

local function NewGearTab(mode)
    local tab = {
        mode = mode,
        key = mode == "raid" and "RaidGearProfiles" or "GearProfiles",
        title = mode == "raid" and "Raid Gear Profiles" or "M+ Gear Profiles",
        selectedMetricKey = "dps",
    }
    KeyLab.Tabs[tab.key] = tab

    function tab:RefreshOptions()
        self.allEncounters = mode == "raid" and RaidEncounters() or MPlusEncounters()
        self.currentSpecID, self.currentSpecName = GetCurrentSpecIdentity()
        self.currentSpecEncounters = {}
        for _, encounter in ipairs(self.allEncounters or {}) do
            if MatchesCurrentSpec(encounter, self.currentSpecID, self.currentSpecName) then
                table.insert(self.currentSpecEncounters, encounter)
            end
        end
        self.primaryOptions, self.secondaryOptions = BuildOptions(self)
        if not HasOption(self.primaryOptions, self.selectedPrimary) then
            self.selectedPrimary, self.selectedSecondary = nil, nil
            self.primaryOptions, self.secondaryOptions = BuildOptions(self)
        end
        if not HasOption(self.secondaryOptions, self.selectedSecondary) then self.selectedSecondary = nil end
        self.metricOptions = GetMetricOptions()
        if not HasOption(self.metricOptions, self.selectedMetricKey) then self.selectedMetricKey = self.metricOptions[1] and self.metricOptions[1].value or "dps" end
        self.primaryDropdown:SetDisplay(self.selectedPrimary, mode == "raid" and "All Bosses" or "All Dungeons")
        self.secondaryDropdown:SetDisplay(self.selectedSecondary, mode == "raid" and "All Difficulties" or "All Keys")
        self.specValue:SetText(self.currentSpecName or "No Specialization")
        self.metricDropdown:SetDisplay(self.selectedMetricKey, "Outcome")
    end

    function tab:Refresh()
        if not self.frame then return end
        self:RefreshOptions()
        local profiles, lowerIsBetter = BuildProfiles(self)
        local info = GetMetricInfo(self.selectedMetricKey)
        local direction = info and info.higherIsBetter == false and "lowest" or "highest"
        local observedProfiles = 0
        for _, profile in ipairs(profiles) do if profile.average ~= nil then observedProfiles = observedProfiles + 1 end end
        if #profiles > 0 and observedProfiles == 0 then
            self.summary:SetText(string.format("Showing top %d of %d equipped setup%s - selected outcome was unavailable for the saved run%s", math.min(5, #profiles), #profiles, #profiles == 1 and "" or "s", #profiles == 1 and "" or "s"))
        else
            self.summary:SetText(string.format("Showing top %d of %d equipped setup%s - ranked by average %s observed %s", math.min(5, #profiles), #profiles, #profiles == 1 and "" or "s", direction, info and info.label or self.selectedMetricKey))
        end
        BuildDynamic(self, profiles, lowerIsBetter)
    end

    function tab:Create(parent)
        if self.frame then return self.frame end
        local frame = CreateFrame("Frame", "KeyLab" .. self.key .. "Tab", parent, "BackdropTemplate")
        frame:SetAllPoints(parent)
        Style(frame, Color("bg"), { 0, 0, 0, 0 })
        self.frame = frame
        local titleText = Place(frame, self.title, HEADER.x, HEADER.titleY, HEADER.titleWidth, "GameFontNormalLarge", HEADER.titleSize, Color("gold"))
        titleText:SetHeight(HEADER.titleHeight)
        local description = Place(frame, "Compare complete gear setups you actually used and the results you recorded with them.", HEADER.x, HEADER.descriptionY, HEADER.descriptionWidth, "GameFontHighlightSmall", nil, Color("muted"))
        description:SetHeight(HEADER.descriptionHeight)
        self.summary = Place(frame, "Loading gear profiles...", HEADER.x, HEADER.summaryY, HEADER.summaryWidth, "GameFontDisableSmall", nil, Color("muted"))
        self.summary:SetHeight(HEADER.summaryHeight)

        local controls = Panel(frame, 12, HEADER.analysisControlsY, PROFILE_WIDTH, 74, Color("softBorder"))
        self.primaryDropdown = Dropdown(controls, mode == "raid" and "Boss" or "Dungeon", 16, 190, function() return tab.primaryOptions or {} end, function() return tab.selectedPrimary end, function(value)
            tab.selectedPrimary, tab.selectedSecondary, tab.selectedSignature = value, nil, nil; tab:Refresh()
        end)
        self.secondaryDropdown = Dropdown(controls, mode == "raid" and "Difficulty" or "Key", 252, 130, function() return tab.secondaryOptions or {} end, function() return tab.selectedSecondary end, function(value)
            tab.selectedSecondary, tab.selectedSignature = value, nil; tab:Refresh()
        end)
        Place(controls, "Current Spec", 442, -12, 150, "GameFontDisableSmall", nil, Color("muted"))
        self.specValue = Place(controls, "Loading...", 442, -38, 150, "GameFontHighlightSmall", nil, Color("gold"))
        self.metricDropdown = Dropdown(controls, "Performance Metric", 632, 170, function() return tab.metricOptions or {} end, function() return tab.selectedMetricKey end, function(value)
            tab.selectedMetricKey, tab.selectedSignature = value, nil; tab:Refresh()
        end)

        self.dynamic = CreateFrame("Frame", nil, frame)
        self.dynamic:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, HEADER.analysisContentY)
        self.dynamic:SetSize(PROFILE_WIDTH, 570)
        frame:SetScript("OnShow", function() tab:Refresh() end)
        return frame
    end
    return tab
end

local MPlusGearProfiles = NewGearTab("mplus")
local RaidGearProfiles = NewGearTab("raid")

if KeyLab.RegisterTab then
    KeyLab.RegisterTab("M+ Gear Profiles", function(parent) return MPlusGearProfiles:Create(parent) end)
    KeyLab.RegisterTab("Raid Gear Profiles", function(parent) return RaidGearProfiles:Create(parent) end)
end

return { MPlusGearProfiles = MPlusGearProfiles, RaidGearProfiles = RaidGearProfiles }
