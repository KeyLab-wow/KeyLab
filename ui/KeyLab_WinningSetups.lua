local _, KeyLab = ...

KeyLab.Tabs = KeyLab.Tabs or {}
local WinningSetups = {}
KeyLab.Tabs.WinningSetups = WinningSetups

local Theme = KeyLab.UI and KeyLab.UI.Theme or {}
local Colors = Theme.colors or {}
local EncounterData = KeyLab.Analysis and KeyLab.Analysis.EncounterData or {}
local RaidAnalysis = KeyLab.Analysis and KeyLab.Analysis.Raid or {}
local STAT_KEYS = { "crit", "haste", "mastery", "versatility" }
local STAT_TIE_ORDER = { crit = 1, haste = 2, mastery = 3, versatility = 4 }
local GEAR_SLOT_ORDER = {
    "Head", "Neck", "Shoulders", "Back", "Chest", "Wrist", "Main Hand", "Off Hand",
    "Hands", "Waist", "Legs", "Feet", "Finger 1", "Finger 2", "Trinket 1", "Trinket 2",
}

local function Color(name, fallback) return Colors[name] or fallback or { 1, 1, 1, 1 } end
local function Text(parent, value, size, color, justify)
    local fs = Theme.CreateText(parent, value or "", "GameFontHighlight", size or 12, color or Color("text"))
    fs:SetJustifyH(justify or "LEFT"); fs:SetJustifyV("TOP"); fs:SetWordWrap(true)
    return fs
end
local function Number(value) return tonumber(value) end
local function FormatNumber(value)
    value = Number(value)
    if not value then return "—" end
    if math.abs(value) >= 1000000 then return string.format("%.2fM", value / 1000000) end
    if math.abs(value) >= 1000 then return string.format("%.1fK", value / 1000) end
    return string.format("%.1f", value)
end

local function Player(encounter)
    return EncounterData.GetPlayer and EncounterData.GetPlayer(encounter) or encounter and encounter.player or {}
end
local function SpecID(encounter) return Number(Player(encounter).specID or encounter and encounter.specID) end
local function SpecName(encounter) return Player(encounter).spec or Player(encounter).specName or "Unknown Spec" end
local function CurrentSpec()
    local index = GetSpecialization and GetSpecialization()
    if index and GetSpecializationInfo then
        local id, name = GetSpecializationInfo(index)
        return Number(id), name
    end
end
local function MatchesCurrentSpec(encounter, id, name)
    local encounterID = SpecID(encounter)
    if id and encounterID then return id == encounterID end
    return not name or SpecName(encounter) == name
end
local function Mode()
    return KeyLab.UI and KeyLab.UI.contentMode == "raid" and "raid" or "mplus"
end
local function Encounters(mode)
    if mode == "raid" then return RaidAnalysis.GetEncounters and RaidAnalysis.GetEncounters() or {} end
    return EncounterData.GetEncounterList and EncounterData.GetEncounterList({
        includeInterrupted = false,
        includeExcluded = false,
        allowMissingIdentity = false,
    }) or {}
end
local function PrimaryValue(mode, encounter)
    if mode == "raid" then return Number(encounter and encounter.raid and encounter.raid.encounterID) end
    return Number(encounter and encounter.challenge and encounter.challenge.mapID)
end
local function SecondaryValue(mode, encounter)
    if mode == "raid" then return Number(encounter and encounter.raid and encounter.raid.difficultyID) end
    return Number(encounter and encounter.challenge and encounter.challenge.keyLevel)
end
local function PrimaryLabel(mode, encounter)
    if mode == "raid" then
        local raid = encounter and encounter.raid or {}
        return raid.encounterName or ("Encounter " .. tostring(raid.encounterID or "?"))
    end
    local challenge = encounter and encounter.challenge or {}
    return challenge.dungeonName or challenge.name or ("Map " .. tostring(challenge.mapID or "?"))
end
local function SecondaryLabel(mode, encounter)
    if mode == "raid" then
        local raid = encounter and encounter.raid or {}
        return raid.difficultyName or ("Difficulty " .. tostring(raid.difficultyID or "?"))
    end
    return "+" .. tostring(SecondaryValue(mode, encounter) or 0)
end
local function MetricValue(encounter, key)
    if EncounterData.GetMetricValue then return Number(EncounterData.GetMetricValue(encounter, key)) end
    return Number(encounter and encounter.metrics and encounter.metrics[key])
end
local function MetricInfo(key)
    if EncounterData.GetMetricInfoByKey then return EncounterData.GetMetricInfoByKey(key) end
    for _, info in pairs(KeyLab.Mapping and KeyLab.Mapping.Metrics or {}) do
        if info.keylabKey == key then return info end
    end
end
local function MetricOptions()
    local list = {}
    for _, key in ipairs(KeyLab.Mapping and KeyLab.Mapping.ProfileComparisonMetricKeys or { "dps", "hps" }) do
        local info = MetricInfo(key)
        if info and info.store == true then list[#list + 1] = { value = key, label = info.label or key } end
    end
    return list
end
local function TalentSignature(encounter)
    local talents = encounter and encounter.talents or {}
    local value = talents.talentString or encounter and encounter.talentString
    return type(value) == "string" and value ~= "" and value or nil
end
local function TalentName(encounter)
    local talents = encounter and encounter.talents or {}
    return type(talents.loadoutName) == "string" and talents.loadoutName ~= "" and talents.loadoutName or "Captured Talent Build"
end
local function StatSignature(encounter)
    local stats, ordered = encounter and encounter.stats or {}, {}
    for _, key in ipairs(STAT_KEYS) do
        local value = Number(stats[key])
        if value == nil then return nil end
        ordered[#ordered + 1] = { key = key, value = value }
    end
    table.sort(ordered, function(a, b)
        if a.value == b.value then return STAT_TIE_ORDER[a.key] < STAT_TIE_ORDER[b.key] end
        return a.value > b.value
    end)
    local keys, labels = {}, {}
    for _, stat in ipairs(ordered) do
        keys[#keys + 1] = stat.key
        local info = KeyLab.Mapping and KeyLab.Mapping.Stats and KeyLab.Mapping.Stats[stat.key]
        labels[#labels + 1] = info and info.label or stat.key
    end
    return table.concat(keys, ">"), table.concat(labels, " > ")
end
local function GearSignature(encounter)
    local gear = encounter and encounter.gear or {}
    if type(gear.slots) ~= "table" then return nil end
    if type(gear.signature) == "string" and gear.signature ~= "" then return gear.signature end
    local parts, found = {}, false
    for _, slotName in ipairs(GEAR_SLOT_ORDER) do
        local slot = gear.slots[slotName]
        local item = type(slot) == "table" and (slot.itemLink or slot.itemID)
        if item then found = true end
        parts[#parts + 1] = slotName .. ":" .. tostring(item or "empty")
    end
    return found and table.concat(parts, "|") or nil
end

local function GearItemName(slot)
    if type(slot) ~= "table" then return nil end
    if type(slot.itemName) == "string" and slot.itemName ~= "" then return slot.itemName end
    if type(slot.name) == "string" and slot.name ~= "" then return slot.name end
    if type(slot.itemLink) == "string" and slot.itemLink ~= "" then
        return slot.itemLink:match("|h%[([^%]]+)%]|h") or slot.itemLink:match("%[([^%]]+)%]")
    end
    return slot.itemID and ("Item " .. tostring(slot.itemID)) or nil
end

local function GearItemColumns(encounter)
    local slots = encounter and encounter.gear and encounter.gear.slots or {}
    local items = {}
    for _, slotName in ipairs(GEAR_SLOT_ORDER) do
        local itemName = GearItemName(slots[slotName])
        if itemName then items[#items + 1] = slotName .. " — " .. itemName end
    end
    if #items == 0 then return "No equipped items captured", "" end
    local split = math.ceil(#items / 2)
    local left, right = {}, {}
    for index, item in ipairs(items) do
        local column = index <= split and left or right
        column[#column + 1] = item
    end
    return table.concat(left, "\n"), table.concat(right, "\n")
end

local function Better(a, b, lower)
    if a == b then return false end
    if a == nil then return false end
    if b == nil then return true end
    return lower and a < b or (not lower and a > b)
end
local function BuildRanks(encounters, signatureFunction, metricKey, useAverage)
    local groups, result = {}, {}
    local info = MetricInfo(metricKey)
    local lower = info and info.higherIsBetter == false
    for _, encounter in ipairs(encounters) do
        local signature = signatureFunction(encounter)
        local value = MetricValue(encounter, metricKey)
        if signature and value ~= nil then
            local group = groups[signature]
            if not group then group = { signature = signature, total = 0, uses = 0, best = nil }; groups[signature] = group end
            group.total = group.total + value; group.uses = group.uses + 1
            group.average = group.total / group.uses
            if Better(value, group.best, lower) then group.best = value end
        end
    end
    for _, group in pairs(groups) do result[#result + 1] = group end
    table.sort(result, function(a, b)
        local av, bv = useAverage and a.average or a.best, useAverage and b.average or b.best
        if av == bv then return a.uses > b.uses end
        return Better(av, bv, lower)
    end)
    local ranks = {}
    for index = 1, math.min(5, #result) do ranks[result[index].signature] = index end
    return ranks
end

local function BuildSetups(tab, encounters)
    local talentRanks = BuildRanks(encounters, TalentSignature, tab.selectedMetric, false)
    local statRanks = BuildRanks(encounters, function(value) return StatSignature(value) end, tab.selectedMetric, true)
    local gearRanks = BuildRanks(encounters, GearSignature, tab.selectedMetric, true)
    local groups, results = {}, {}
    local info = MetricInfo(tab.selectedMetric)
    local lower = info and info.higherIsBetter == false
    for _, encounter in ipairs(encounters) do
        local talent = TalentSignature(encounter)
        local stats, statsText = StatSignature(encounter)
        local gear = GearSignature(encounter)
        local value = MetricValue(encounter, tab.selectedMetric)
        if talentRanks[talent] and statRanks[stats] and gearRanks[gear] and value ~= nil then
            local key = talent .. "|" .. stats .. "|" .. gear
            local group = groups[key]
            if not group then
                group = {
                    signature = key, talent = talent, stats = stats, gear = gear,
                    talentRank = talentRanks[talent], statRank = statRanks[stats], gearRank = gearRanks[gear],
                    statsText = statsText, total = 0, uses = 0, best = nil, bestEncounter = nil,
                }
                groups[key] = group
            end
            group.total = group.total + value; group.uses = group.uses + 1; group.average = group.total / group.uses
            if Better(value, group.best, lower) then group.best = value; group.bestEncounter = encounter end
        end
    end
    for _, group in pairs(groups) do results[#results + 1] = group end
    table.sort(results, function(a, b)
        if a.average == b.average then return a.uses > b.uses end
        return Better(a.average, b.average, lower)
    end)
    return results
end

local function Dropdown(parent, label, x, width, optionsFunction, valueFunction, changedFunction)
    local caption = Text(parent, label, 10, Color("muted")); caption:SetPoint("TOPLEFT", x, -74); caption:SetSize(width, 16)
    local menu = Theme.CreateLegacyDropdown(parent); Theme.StyleAnalysisFilterDropdown(menu)
    menu:SetPoint("TOPLEFT", parent, "TOPLEFT", x - 16, -86); UIDropDownMenu_SetWidth(menu, width)
    UIDropDownMenu_Initialize(menu, function(_, level)
        for _, option in ipairs(optionsFunction() or {}) do
            local value = option.value
            local info = UIDropDownMenu_CreateInfo(); info.text = option.label; info.checked = value == valueFunction()
            info.func = function() changedFunction(value) end; UIDropDownMenu_AddButton(info, level)
        end
    end)
    return menu, caption
end

function WinningSetups:FilteredEncounters()
    local filtered = {}
    for _, encounter in ipairs(self.allEncounters or {}) do
        if MatchesCurrentSpec(encounter, self.currentSpecID, self.currentSpecName)
            and (not self.selectedPrimary or PrimaryValue(self.mode, encounter) == self.selectedPrimary)
            and (not self.selectedSecondary or SecondaryValue(self.mode, encounter) == self.selectedSecondary)
        then filtered[#filtered + 1] = encounter end
    end
    return filtered
end

function WinningSetups:BuildOptions()
    local primary, secondary, seenPrimary, seenSecondary = {}, {}, {}, {}
    primary[1] = { value = nil, label = self.mode == "raid" and "All Bosses" or "All Dungeons" }
    secondary[1] = { value = nil, label = self.mode == "raid" and "All Difficulties" or "All Keys" }
    for _, encounter in ipairs(self.allEncounters or {}) do
        if MatchesCurrentSpec(encounter, self.currentSpecID, self.currentSpecName) then
            local p = PrimaryValue(self.mode, encounter)
            if p and not seenPrimary[p] then seenPrimary[p] = true; primary[#primary + 1] = { value = p, label = PrimaryLabel(self.mode, encounter) } end
            if not self.selectedPrimary or p == self.selectedPrimary then
                local s = SecondaryValue(self.mode, encounter)
                if s and not seenSecondary[s] then seenSecondary[s] = true; secondary[#secondary + 1] = { value = s, label = SecondaryLabel(self.mode, encounter) } end
            end
        end
    end
    table.sort(primary, function(a, b) if a.value == nil or b.value == nil then return a.value == nil end return a.label < b.label end)
    table.sort(secondary, function(a, b)
        if a.value == nil or b.value == nil then return a.value == nil end
        if self.mode == "mplus" then return a.value > b.value end
        return a.label < b.label
    end)
    self.primaryOptions, self.secondaryOptions = primary, secondary
end

function WinningSetups:Refresh()
    if not self.frame or not self.frame:IsShown() then return end
    self.mode = Mode(); self.currentSpecID, self.currentSpecName = CurrentSpec(); self.allEncounters = Encounters(self.mode)
    self.metricOptions = MetricOptions()
    if self.primaryCaption then self.primaryCaption:SetText(self.mode == "raid" and "Boss" or "Dungeon") end
    if self.secondaryCaption then self.secondaryCaption:SetText(self.mode == "raid" and "Difficulty" or "Key Level") end
    local metricFound = false
    for _, option in ipairs(self.metricOptions) do if option.value == self.selectedMetric then metricFound = true end end
    if not metricFound then self.selectedMetric = self.metricOptions[1] and self.metricOptions[1].value or "dps" end
    self:BuildOptions()
    local function has(options, value) for _, option in ipairs(options) do if option.value == value then return true end end end
    if self.selectedPrimary and not has(self.primaryOptions, self.selectedPrimary) then self.selectedPrimary = nil; self.selectedSecondary = nil; self:BuildOptions() end
    if self.selectedSecondary and not has(self.secondaryOptions, self.selectedSecondary) then self.selectedSecondary = nil end
    UIDropDownMenu_SetText(self.primaryDropdown, (function() for _, o in ipairs(self.primaryOptions) do if o.value == self.selectedPrimary then return o.label end end end)() or self.primaryOptions[1].label)
    UIDropDownMenu_SetText(self.secondaryDropdown, (function() for _, o in ipairs(self.secondaryOptions) do if o.value == self.selectedSecondary then return o.label end end end)() or self.secondaryOptions[1].label)
    UIDropDownMenu_SetText(self.metricDropdown, (function() for _, o in ipairs(self.metricOptions) do if o.value == self.selectedMetric then return o.label end end end)() or self.selectedMetric)

    for _, card in ipairs(self.cards or {}) do card:Hide() end
    local filtered = self:FilteredEncounters()
    local setups = BuildSetups(self, filtered)
    local info = MetricInfo(self.selectedMetric); local metricLabel = info and info.label or self.selectedMetric
    if #setups == 0 then
        self.empty:SetText("No Triple Top 5 setup found yet.\n\nKeep recording runs or boss pulls. KeyLab will show a match when the same Talent Build, Stat Profile, and Gear Profile all reach the Top 5 for the selected content and metric.")
        self.empty:Show(); self.scroll:SetContentHeight(260); return
    end
    self.empty:Hide(); self.cards = self.cards or {}
    local setup = setups[1]
    local card = self.cards[1]
    if not card then
        card = CreateFrame("Frame", nil, self.scroll.content, "BackdropTemplate")
        Theme.StylePanel(card, Color("panel"), Color("cardBorder", Color("border")))
        card.title = Text(card, "", 15, Color("gold")); card.title:SetPoint("TOPLEFT", 14, -12); card.title:SetSize(540, 22)
        card.badge = Theme.CreateBadge(card, "Triple Top 5", 132, 24); card.badge:SetPoint("TOPRIGHT", -14, -10)
        Theme.SetBadge(card.badge, "Triple Top 5", Color("badgeBg", Color("panel")), Color("transparent", {0,0,0,0}), Color("gold"))
        card.outcome = Text(card, "", 11, Color("blue")); card.outcome:SetPoint("TOPLEFT", 14, -43); card.outcome:SetPoint("TOPRIGHT", -14, -43); card.outcome:SetHeight(20)

        card.talentLabel = Text(card, "Talent String", 11, Color("gold")); card.talentLabel:SetPoint("TOPLEFT", 14, -72); card.talentLabel:SetSize(180, 18)
        card.talentBox = CreateFrame("EditBox", nil, card, "BackdropTemplate")
        Theme.StylePanel(card.talentBox, Color("bg"), Color("border"))
        card.talentBox:SetPoint("TOPLEFT", 14, -92); card.talentBox:SetPoint("TOPRIGHT", -14, -92); card.talentBox:SetHeight(58)
        card.talentBox:SetMultiLine(true); card.talentBox:SetAutoFocus(false); card.talentBox:SetFontObject("GameFontHighlightSmall")
        card.talentBox:SetTextInsets(8, 8, 7, 7); card.talentBox:SetTextColor(unpack(Color("text")))
        card.talentBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

        card.statLabel = Text(card, "Stat Priority", 11, Color("gold")); card.statLabel:SetPoint("TOPLEFT", 14, -162); card.statLabel:SetSize(180, 18)
        card.stats = Text(card, "", 11, Color("text")); card.stats:SetPoint("TOPLEFT", 14, -182); card.stats:SetPoint("TOPRIGHT", -14, -182); card.stats:SetHeight(20)

        card.gearLabel = Text(card, "Gear Items Worn", 11, Color("gold")); card.gearLabel:SetPoint("TOPLEFT", 14, -214); card.gearLabel:SetSize(180, 18)
        card.gearLeft = Text(card, "", 10, Color("text")); card.gearLeft:SetPoint("TOPLEFT", 14, -236); card.gearLeft:SetPoint("TOPRIGHT", card, "TOP", -10, -236); card.gearLeft:SetHeight(150)
        card.gearRight = Text(card, "", 10, Color("text")); card.gearRight:SetPoint("TOPLEFT", card, "TOP", 10, -236); card.gearRight:SetPoint("TOPRIGHT", -14, -236); card.gearRight:SetHeight(150)
        self.cards[1] = card
    end
    card:ClearAllPoints(); card:SetPoint("TOPLEFT", self.scroll.content, "TOPLEFT", 8, 0); card:SetPoint("TOPRIGHT", self.scroll.content, "TOPRIGHT", -8, 0); card:SetHeight(394); card:Show()
    local gearLeft, gearRight = GearItemColumns(setup.bestEncounter)
    card.title:SetText("Top Winning Setup")
    card.outcome:SetText(string.format("Average %s: %s  •  Best: %s  •  Used together %d time%s", metricLabel, FormatNumber(setup.average), FormatNumber(setup.best), setup.uses, setup.uses == 1 and "" or "s"))
    card.talentBox:SetText(setup.talent or "Talent string was not captured")
    card.talentBox:SetCursorPosition(0)
    card.stats:SetText(setup.statsText or "Captured Stat Profile")
    card.gearLeft:SetText(gearLeft)
    card.gearRight:SetText(gearRight)
    self.scroll:SetContentHeight(410)
end

function WinningSetups:Create(parent)
    local frame = CreateFrame("Frame", "KeyLabWinningSetupsTab", parent, "BackdropTemplate"); frame:SetAllPoints(parent)
    Theme.StylePanel(frame, Color("bg"), Color("transparent", {0,0,0,0}))
    Theme.CreateTabHeader(frame, "Winning Setups", "Find Talent Builds, Stat Profiles, and Gear Profiles that reached the Top 5 together.")
    self.frame, self.mode, self.selectedMetric = frame, Mode(), "dps"
    self.primaryDropdown, self.primaryCaption = Dropdown(frame, self.mode == "raid" and "Boss" or "Dungeon", 24, 248,
        function() return self.primaryOptions end, function() return self.selectedPrimary end,
        function(value) self.selectedPrimary = value; self.selectedSecondary = nil; self:Refresh() end)
    self.secondaryDropdown, self.secondaryCaption = Dropdown(frame, self.mode == "raid" and "Difficulty" or "Key Level", 302, 210,
        function() return self.secondaryOptions end, function() return self.selectedSecondary end,
        function(value) self.selectedSecondary = value; self:Refresh() end)
    self.metricDropdown = Dropdown(frame, "Performance Metric", 542, 250,
        function() return self.metricOptions end, function() return self.selectedMetric end,
        function(value) self.selectedMetric = value; self:Refresh() end)
    self.scroll = Theme.CreateScrollArea(frame, { step = 52 }); self.scroll:SetPoint("TOPLEFT", 18, -136); self.scroll:SetPoint("BOTTOMRIGHT", -18, 18)
    self.empty = Text(self.scroll.content, "", 14, Color("muted"), "CENTER"); self.empty:SetPoint("TOPLEFT", 80, -76); self.empty:SetPoint("TOPRIGHT", -80, -76); self.empty:SetHeight(140)
    frame.Refresh = function() WinningSetups:Refresh() end
    frame:SetScript("OnShow", function() WinningSetups:Refresh() end)
    return frame
end

if KeyLab.RegisterTab then KeyLab.RegisterTab("Winning Setups", function(parent) return WinningSetups:Create(parent) end) end

return WinningSetups
